Documentation
~~~~~~~~~~~~~

Building
========

This project shows an example of a cc program that depends on generated code,
through a cc_library, that can optionally be statically linked.
And this has a rudimentary rule for that code generation.

There is also a linter aspect for the python code, that is configured with a toolchain.

::

    $ bazel query //... --output=maxrank
    0 //:Runner
    0 //:test
    0 //toolchain:ruff_toolchain
    0 //:Touch
    0 //config:ConfiguredBinary
    0 //toolchain:ruff
    0 //config:Runner
    0 //Parameters:filter
    1 //Library:Static
    1 //config:debug_build
    1 //toolchain:toolchain_type
    1 //:capture
    1 //config:opt_build
    2 //:Program
    3 //Library:Library
    4 //Parameters:Parameters
    5 //Parameters:Generate
    5 //config:config_file

The main points to build and run are `//:Runner` and `//:Program`.
This compiles all the code and generated defines that are printed below::

    $ bazel run //:Program
    Target //:Program up-to-date:
      bazel-bin/Program
    Hello: Meroton 105%

    # There is also a python runner to execute the program
    bazel run //:Runner
    Target //:Runner up-to-date:
      bazel-bin/Runner
    Hello: Meroton 105%
    1: from
    2: python

The generated code is available here::

    $ bazel build //Parameters
    Target //Parameters:Parameters up-to-date:
      bazel-bin/Parameters/Parameters.h

    # This code generator is handled by a bazel rule
    $ bazel run //Parameters:Generate -- --help
    Target //Parameters:Generate up-to-date:
      bazel-bin/Parameters/Generate
    usage: Generate.py [-h] --output OUTPUT --base BASE inputs [inputs ...]
    ...

Query
=====

The basic use for query is to show what targets are available
and what kinds they are::

    $ bazel query //...
    $ bazel query --output=label_kind //...

And advanced use can show dependencies between targets
and limit scopes::

    # all dependencies within //Library/...
    $ bazel query 'deps(//:Runner) intersect //Library/...'
    $ bazel query --output=label_kind 'allpaths(//:Runner, //Parameters)'
    cc_binary rule //:Program
    py_binary rule //:Runner
    cc_library rule //Library:Library
    codegen rule //Parameters:Parameters

    # We also depend on the python code generation tool
    $ bazel query --output=label_kind 'allpaths(//:Runner, //Parameters:all)'
    ...
    py_binary rule //Parameters:Generate

    # But not if we disable implicit and tool dependencies (--notool_deps)
    # This is the same as the allpaths query.
    $ bazel query --output=label_kind --noimplicit_deps 'allpaths(//:Runner, //Parameters:all)'
    cc_binary rule //:Program
    py_binary rule //:Runner
    cc_library rule //Library:Library
    codegen rule //Parameters:Parameters


We can find targets expanded by macros, and filter based on the macro name
"generator_function" is the old name for "macro", some such old names leak through the Bazel abstractions.

If we had a "write_source_file" target and macro, this would show both a write and a test target.
You could add that for the reference output of `//:Program`!
https://github.com/bazelbuild/bazel-skylib/blob/main/docs/write_file_doc.md

::

    $ bazel query 'attr(generator_function, diff_test, //:all)'
    _diff_test rule //:test

Macros can be expanded to see all the attributes,
compare this to what you see in the BUILD file.
There is also a stack trace with filepaths to open all relevant BUILD and .bzl files.::

    $ bazel query --output=build //:test
    # /home/nils/task/meroton/basic-codegen/BUILD.bazel:48:10
    _diff_test(
      name = "test",
      generator_name = "test",
      generator_function = "diff_test",
      generator_location = "/home/nils/task/meroton/basic-codegen/BUILD.bazel:48:10",
      file1 = "//:reference.txt",
      file2 = "//:capture",
      is_windows = select({"@bazel_tools//src/conditions:host_windows": True, "//conditions:default": False}),
    )
    # Rule test instantiated at (most recent call last):
    #   /home/nils/task/meroton/basic-codegen/BUILD.bazel:48:10                                                               in <toplevel>
    #   /home/nils/.cache/bazel/_bazel_nils/38ee34394b564c6d0289781c6b6bf0c1/external/bazel_skylib/rules/diff_test.bzl:169:15 in diff_test
    # Rule _diff_test defined at (most recent call last):
    #   /home/nils/.cache/bazel/_bazel_nils/38ee34394b564c6d0289781c6b6bf0c1/external/bazel_skylib/rules/diff_test.bzl:140:18 in <toplevel>

    $ bazel query --output=build //:capture
    # /home/nils/task/meroton/basic-codegen/BUILD.bazel:39:8
    genrule(
      name = "capture",
      tools = ["//:Program"],
      outs = ["//:XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"],
      cmd = "\n        ./$(location Program) > \"$@\"\n    ",
    )

We can also look for certain kinds of rules with the `kind` function: `kind(<regexp>, <pattern>)`.::

    $ bazel query 'kind(config_setting, //...)'
    config_setting rule //config:debug_build
    config_setting rule //config:opt_build

Source files are also available, though they are not themselves part of the wildcard for `//...`::

    $ bazel query --output=label 'kind("source file", deps(//...))' | grep '^//'
    //:Main.c
    //:reference.txt
    //:run.py
    //:touch.sh
    //Library:Library.c
    //Library:Library.h
    //Parameters:Generate.py
    //Parameters:Parameters.json
    //config:main.c
    //config:run.py

Without the `grep` we see source files from external repositories too!

External repositories
---------------------

Can be shown::

    bazel query //external:'*'

There are probably more than you thought, most of them are built in to Bazel,
and not actually used in this repository.
However, the real name `@<repo>//...` must be used to query for dependency paths.::

    $ bazel query 'allpaths(//..., //external:*)'
    INFO: Empty results

Cquery
======

Cquery is used to query the configured graph, where selects are followed.
So we only see dependencies for desired options and operating systems.
You can always query for a different operating system than your own,
just disable the auto-platform-configuration (if it is enabled),
it will automatically add --config=linux and so on.

    --noenable_platform_specific_config

Follow selects
--------------

We have a configured dependency in `//config:ConfiguredBinary`.
With just query we see that it depends of both the regular and the statically linked library.::

    bazel query 'deps(//config:ConfiguredBinary, 1) intersect //Library:all'
    cc_library rule //Library:Library
    cc_static_library rule //Library:Static

But the `config_setting` are mutually exclusive, based on the `--compilation_mode={fastbuild,opt,debug}` value.
The flag is customarily used in its short form `-c=<value>`, and `fastbuild` is the default.

bash ::

    $ diff \
        <(bazel cquery $TERSE -c fastbuild 'deps(//config:ConfiguredBinary, 1) intersect //Library:all') \
        <(bazel cquery -c opt 'deps(//config:ConfiguredBinary, 1) intersect //Library:all')
    1c1
    < //Library:Library (ca63adb)
    ---
    > //Library:Static (bfe6c4d)

This switch will also show up visually in the `graph` output format.

Graph
-----

Here is an example that shows the configuration of all targets in a graph.
We do some `sed` to make it look nicer.::

    $ bazel cquery                             \
        --notool_deps --noimplicit_deps        \
        'deps(//:Runner)' --output=graph       \
        | sed                                  \
            -e 's/(ca63adb)/(Generated)/g'     \
            -e 's/(null)/(Source)/g'           \
            -e '{/->/b; s/(Source)"/& [style=filled, fillcolor='lightgreen']/}'
    digraph mygraph {
      node [shape=box];
      "//:Runner (Generated)"
      "//:Runner (Generated)" -> "//:Program (Generated)"
      "//:Runner (Generated)" -> "//:run.py (Source)"
      "//:Runner (Generated)" -> "@rules_python//python/runfiles:runfiles (Generated)"
    ...

This can be rendered to an svg with `graphviz` and the `dot` program.

   $ bazel cquery ... | dot -Tsvg -o graph.svg

Config hash
-----------

In this example the config hash is "ca63adb", it may differ for you,
update the `sed` command accordingly.

    $ bazel cquery //:Runner
    //:Runner (ca63adb)

You can inspect this with `bazel config` to show platforms and many, many, more options.::

    $ bazel config ca63adb | head
    INFO: Displaying config with id ca63adb
    BuildConfigurationValue ca63adb307a1bd0f693440015ddae19ec8302707b6d51da41eab328714b1af2a:
    Skyframe Key: BuildConfigurationKey[ca63adb307a1bd0f693440015ddae19ec8302707b6d51da41eab328714b1af2a]
    ...

ST hash
-------

This example does not have any ST hashes, they stick out from config hashes, in that they have `ST_` in the middle.
Those are created by transitions that change the config of a target,
and cannot be printed directly with `bazel config <ST hash>`.
You need their config hash, which can be found by calling `bazel config` without any arguments.::

    $ bazel config | grep <ST hash>

This will give you the config hash.

Providers and output groups
---------------------------

There is a cquery Starlark file in the project root `output_groups.cquery`
that can be used to list all providers and output groups of a target.
And pretty-print some of them, you would typically create such pretty printers for all internal providers.
It helps a lot during rule development to inspect the rule outputs,
and keep that code out of the implementation.
To select the prints interactively rather than coding in print-statements.

It also servers as a basis for powerful shell completion tools.
This was used to develop the Codegen code,
see block comments in `Parameters/BUILD.bazel` and `Parameters/Codegen.bzl`.

::

    $ bazel cquery --output=starlark --starlark:file=output_groups.cquery //:Program
    providers:
       - CcInfo
       - InstrumentedFilesInfo
       - DebugPackageInfo
       - CcLauncherInfo
       - RunEnvironmentInfo
       - FileProvider
       - FilesToRunProvider
       - OutputGroupInfo

    output_groups:
       - _hidden_top_level_INTERNAL_
       - _validation
       - compilation_outputs
       - compilation_prerequisites_INTERNAL_
       - temp_files_INTERNAL_
       - to_json
       - to_proto

    FileProvider:
       - bazel-out/k8-fastbuild/bin/Program

    FilesToRunProvider:
       - bazel-out/k8-fastbuild/bin/Program
       - bazel-out/k8-fastbuild/bin/Program.runfiles/MANIFEST

    $ bazel cquery --output=starlark --starlark:file=output_groups.cquery //:Runner
    INFO: Analyzed target //:Runner (1 packages loaded, 12 targets configured).
    INFO: Found 1 target...
    providers:
       - PyInfo
       - PyRuntimeInfo
       - InstrumentedFilesInfo
       - PyCcLinkParamsProvider
       - FileProvider
       - FilesToRunProvider
       - OutputGroupInfo

    output_groups:
       - _hidden_top_level_INTERNAL_
       - compilation_outputs
       - compilation_prerequisites_INTERNAL_
       - python_zip_file
       - to_json
       - to_proto

    FileProvider:
       - run.py
       - bazel-out/k8-fastbuild/bin/Runner

    FilesToRunProvider:
       - bazel-out/k8-fastbuild/bin/Runner
       - bazel-out/k8-fastbuild/bin/Runner.runfiles/MANIFEST

Here is a side-by-side that may be useful::

    providers:                                                   ┃  providers:
       - *Py*Info                                                ┃     - *Cc*Info
       - PyRuntimeInfo                                           ┃  ------------------------------------------------------------
       - InstrumentedFilesInfo                                   ┃     - InstrumentedFilesInfo
       - *PyCcLinkParamsProvider*                                ┃     - *DebugPackageInfo*
    -------------------------------------------------------------┃     - CcLauncherInfo
    -------------------------------------------------------------┃     - RunEnvironmentInfo
       - FileProvider                                            ┃     - FileProvider
       - FilesToRunProvider                                      ┃     - FilesToRunProvider
       - OutputGroupInfo                                         ┃     - OutputGroupInfo
                                                                 ┃
    output_groups:                                               ┃  output_groups:
       - _hidden_top_level_INTERNAL_                             ┃     - _hidden_top_level_INTERNAL_
    -------------------------------------------------------------┃     - _validation
       - compilation_outputs                                     ┃     - compilation_outputs
       - compilation_prerequisites_INTERNAL_                     ┃     - compilation_prerequisites_INTERNAL_
       - *python_zip_file*                                       ┃     - *temp_files_INTERNAL_*
       - to_json                                                 ┃     - to_json
       - to_proto                                                ┃     - to_proto
                                                                 ┃
    FileProvider:                                                ┃  FileProvider:
       - *run.py*                                                ┃     - *bazel-out/k8-fastbuild/bin/Program*
       - bazel-out/k8-fastbuild/bin/Runner                       ┃  ------------------------------------------------------------
                                                                 ┃
    FilesToRunProvider:                                          ┃  FilesToRunProvider:
       - bazel-out/k8-fastbuild/bin/*Runner*                     ┃     - bazel-out/k8-fastbuild/bin/*Program*
       - bazel-out/k8-fastbuild/bin/*Runner*.runfiles/MANIFEST   ┃     - bazel-out/k8-fastbuild/bin/*Program*.runfiles/MANIFEST


Pretty-print providers
++++++++++++++++++++++

This pretty-prints the custom `ToolchainInfo` providers from `//toolchain:toolchain.bzl`::

    $ bazel cquery --output=starlark --starlark:file=output_groups.cquery //toolchain:ruff
    providers:
       - ToolchainInfo
       - FileProvider
       - FilesToRunProvider
       - OutputGroupInfo

    ...

    ToolchainInfo:
       - info.tool: bazel-out/k8-opt-exec-2B5CBBC6/bin/external/bin/ruff

Any provider can be printed.
One tip is to check for struct-members with `dir(<some struct>)`, so you know what can be dereferenced,
when writing the pretty-printing code.


Aquery
======

To show actions and their command lines use `aquery`.
You can see a summary of what will be done::

    $ bazel aquery --output=summary //...
    47 total actions.

    Mnemonics:
      CcStrip: 1
      TestRunner: 1
      SolibSymlink: 1
      ArMerge: 1
      CppArchive: 1
      Genrule: 1
      ExecutableSymlink: 1
      GenerateParameters: 1
      CppLink: 2
      CppCompile: 2
      PythonZipper: 3
      FileWrite: 6
      TemplateExpand: 6
      SymlinkTree: 6
      SourceSymlinkManifest: 6
      Middleman: 8

    Configurations:
      k8-fastbuild: 47

    Execution Platforms:
      @local_config_platform//:host: 47


And dig into a specific target::

    $ bazel aquery //Parameters:Parameters
    action 'GenerateParameters Parameters/Parameters.h'
      Mnemonic: GenerateParameters
      Target: //Parameters:Parameters
      Configuration: k8-fastbuild
      Execution platform: @local_config_platform//:host
      ActionKey: 1a618927f613610aaa53e7e0d055f716011b7552e900ac3a8e20058108276ef0
      Inputs: [Parameters/Generate.py, Parameters/Parameters.json, bazel-out/k8-opt-exec-2B5CBBC6/bin/Parameters/Generate, bazel-out/k8-opt-exec-2B5CBBC6/internal/_middlemen/Parameters_SGenerate-runfiles, config/config.json]
      Outputs: [bazel-out/k8-fastbuild/bin/Parameters/Parameters.h]
      Command Line: (exec bazel-out/k8-opt-exec-2B5CBBC6/bin/Parameters/Generate \
        --base \
        config/config.json \
        --output \
        bazel-out/k8-fastbuild/bin/Parameters/Parameters.h \
        Parameters/Parameters.json)
    # Configuration: ca63adb307a1bd0f693440015ddae19ec8302707b6d51da41eab328714b1af2a
    # Execution platform: @local_config_platform//:host

Configuration Examples
======================

Select
------

There is an example `cc_binary` with a `select` statement,
used to illustrate how `cquery` can help understanding dependencies,
see `Follow selects`_.

Label Flag
----------

A contrived example is written, and developed through the commit history
to show how a `label_flag` can be used to add configuration to a rule.
It will be used by the tool, but belongs to the rule as we will see below.
This is good for ad-hoc selection, that does not belong to any well defined `config_settings`.
Config files for tools that do not encode platform information is a good example.
But there is a big area where `select` and `label_flags` can be used to solve the same problem.

Runfile to a binary
+++++++++++++++++++

We see that it does not work well for a `py_binary` to use it as a data dependency,
as we do not know what *file* to look for within the runfiles.
This is done in the config directory, there is a Runner but it does not work.
Try it for yourself with `bazel run //config:Runner`.
::

    $ bazel query --output=build //config:Runner
    # .../config/BUILD.bazel:27:10
    py_binary(
      name = "Runner",
      deps = ["@rules_python//python/runfiles:runfiles"],
      data = ["//config:config_file"],
      main = "//config:run.py",
      srcs = ["//config:run.py"],
      args = [":config_file"],
    )

The `args` here cannot tell the program which file to look for,
it just gets the label for the flag,
not of the real target we attempt to use.

Next, we attempt to implement it into the rule, where we can access the `File` object
and find its path, even if it is changed on the command line.
But we still cannot find it as a runfile::

    $ bazel build //Parameters  # Output is redacted slightly
    ERROR: /home/nils/task/meroton/basic-codegen/Parameters/BUILD.bazel:10:8: GenerateParameters Parameters/Parameters.h failed: (Exit 1): Generate failed: error executing command (from target //Parameters:Parameters) bazel-out/k8-opt-exec-2B5CBBC6/bin/Parameters/Generate --base config/config.json --output bazel-out/k8-fastbuild/bin/Parameters/Parameters.h Parameters/Parameters.json
    Use --sandbox_debug to see verbose messages from the sandbox and retain the sandbox build root for debugging

    lookup: config/config.json
    found: /home/nils/.cache/bazel/_bazel_nils/38ee34394b564c6d0289781c6b6bf0c1/sandbox/linux-sandbox/20/execroot/example/bazel-out/k8-opt-exec-2B5CBBC6/bin/Parameters/Generate.runfiles/config/config.json

    Traceback (most recent call last):
      File "/home/nils/.cache/bazel/_bazel_nils/38ee34394b564c6d0289781c6b6bf0c1/sandbox/linux-sandbox/20/execroot/example/bazel-out/k8-opt-exec-2B5CBBC6/bin/Parameters/Generate.runfiles/example/Parameters/Generate.py", line 59, in <module>
        main(sys.argv[0], sys.argv[1:])
      File "/home/nils/.cache/bazel/_bazel_nils/38ee34394b564c6d0289781c6b6bf0c1/sandbox/linux-sandbox/20/execroot/example/bazel-out/k8-opt-exec-2B5CBBC6/bin/Parameters/Generate.runfiles/example/Parameters/Generate.py", line 37, in main
        with open(input, 'r') as f:
    FileNotFoundError: [Errno 2] No such file or directory: '/home/nils/.cache/bazel/_bazel_nils/38ee34394b564c6d0289781c6b6bf0c1/sandbox/linux-sandbox/20/execroot/example/bazel-out/k8-opt-exec-2B5CBBC6/bin/Parameters/Generate.runfiles/config/config.json'

Runfiles
++++++++

This illustrates some points, we did "find" the runfile, with the library.
But that file could not be opened, and the action failed.
That is because this is not actually a runfile to the program
//Generate:Generate does not have a data attribute,
we depend on it through the rule.
So we do not need the runfile library at all.
This is just a matter for the Starlark implementation and the action to resolve.

But we see that the runfile library does not know whether a file exists or not,
and its construction of the path is purely mechanical.
Runfiles do not work so well if the files are expected to change,
but static file names can be given as args, as we saw in //Config:Runner.

Just a regular input to the action
++++++++++++++++++++++++++++++++++

We just keep it simple, we do not need the runfiles library here.
As the config does not belong to the tool,
it could do so, and then not be an attribute of the rule,
but only the rule has the capability to look at the File object and its path.

Note, the base config file is de facto an input like all the others,
and could potentially be sent as a positional argument for the same effect.
But this shows the structure better.

::

    $ bazel build //Parameters  # Output is redacted slightly
    Target //Parameters:Parameters up-to-date:
      bazel-bin/Parameters/Parameters.h
    $ cat bazel-bin/Parameters/Parameters.h
    /* Generated by /home/nils/.cache/bazel/_bazel_nils/38ee34394b564c6d0289781c6b6bf0c1/sandbox/linux-sandbox/25/execroot/example/bazel-out/k8-opt-exec-2B5CBBC6/bin/Parameters/Generate.runfiles/example/Parameters/Generate.py */
    #define MER_PERCENT 105
    #define key value

Change the program dependency to the statically linked program
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

You can add another label flag to switch between `//Library:Library` and `//Library:Static`
on the command line rather than changing BUILD files::

    diff --git a/BUILD.bazel b/BUILD.bazel
    index 539518a..16faf0d 100644
    --- a/BUILD.bazel
    +++ b/BUILD.bazel
    @@ -6,7 +6,7 @@ cc_binary(
             "Main.c"
         ],
         deps = [
    -        "//Library:Library"
    +        "//Library:Static"
         ],
     )

Build a la carte
================

Some notes on build target selection.

`--build_manual_tests` seems to actually add "manual" targets back into the build.
Even for build actions, so the flag does not have the best name.

By default they are not built::

    $ bazel build --show_result=1000 //:all 2>&1 | grep Touch
    $ bazel build --show_result=1000 --build_manual_tests //:all 2>&1 | grep Touch
    Target //:Touch up-to-date:
      bazel-bin/Touch

But they show up with `--build_manual_tests`.

Manual tag
----------

Some test may be expensive to execute, so we tag it as manual to avoid execution.
Something, something about cloud billing.
But we want to lint the source code to avoid mistakes.
That is typically not possible with "manual" tags.

These targets are tagged "manual"::

    bazel query --output=label_kind 'attr(tags, manual, //...)'
    sh_binary rule //:Touch
    py_binary rule //Parameters:Generate
    toolchain rule //toolchain:ruff_toolchain

The linter example
++++++++++++++++++

If we make `//Parameters:Generate` manual it can not be linted through a wildcard,
even though its docstring is too long, we really want the first build to fail::

    $ bazel build --aspects //:ruff.bzl%ruff //Parameters:all
    INFO: Analyzed 2 targets (0 packages loaded, 0 targets configured).
    INFO: Found 2 targets...
    INFO: Elapsed time: 0.036s, Critical Path: 0.00s
    INFO: 1 process: 1 internal.
    INFO: Build completed successfully, 1 total action

    $ bazel build --aspects //:ruff.bzl%ruff //Parameters:Generate
    INFO: Analyzed target //Parameters:Generate (0 packages loaded, 0 targets configured).
    INFO: Found 1 target...
    ERROR: /home/nils/task/meroton/basic-codegen/Parameters/BUILD.bazel:3:10: Ruff Parameters/Generate.ruff failed: (Exit 1): Touch failed: error executing command (from target //Parameters:Generate) bazel-out/k8-opt-exec-2B5CBBC6/bin/Touch bazel-out/k8-fastbuild/bin/Parameters/Generate.ruff bazel-out/k8-opt-exec-2B5CBBC6/bin/external/bin/ruff check Parameters/Generate.py

    Use --sandbox_debug to see verbose messages from the sandbox and retain the sandbox build root for debugging
    Parameters/Generate.py:3:89: E501 Line too long (94 > 88 characters)
    Found 1 error.
    Aspect //:ruff.bzl%ruff of //Parameters:Generate failed to build
    Use --verbose_failures to see the command lines of failed build steps.
    INFO: Elapsed time: 0.047s, Critical Path: 0.01s
    INFO: 2 processes: 2 internal.
    FAILED: Build did NOT complete successfully

But with `--build_manual_tests` it does work.::

    $ bazel build --aspects //:ruff.bzl%ruff --build_manual_tests //Parameters:Generate
    INFO: Analyzed target //Parameters:Generate (0 packages loaded, 0 targets configured).
    INFO: Found 1 target...
    ERROR: /home/nils/task/meroton/basic-codegen/Parameters/BUILD.bazel:3:10: Ruff Parameters/Generate.ruff failed: (Exit 1): Touch failed: error executing command (from target //Parameters:Generate) bazel-out/k8-opt-exec-2B5CBBC6/bin/Touch bazel-out/k8-fastbuild/bin/Parameters/Generate.ruff bazel-out/k8-opt-exec-2B5CBBC6/bin/external/bin/ruff check Parameters/Generate.py

    Use --sandbox_debug to see verbose messages from the sandbox and retain the sandbox build root for debugging
    Parameters/Generate.py:3:89: E501 Line too long (94 > 88 characters)
    Found 1 error.
    Aspect //:ruff.bzl%ruff of //Parameters:Generate failed to build
    Use --verbose_failures to see the command lines of failed build steps.
    INFO: Elapsed time: 0.040s, Critical Path: 0.01s
    INFO: 2 processes: 2 internal.
    FAILED: Build did NOT complete successfully

So we can allow more use of "manual", and not be wary of them sink-holing all the targets.
But as we do enable them again in the BUILD phase, the reason why they should not still needs to be handled.
And that may well be a platform compatibility issue that should be handled in the rule or with execution platforms.
So if your code based can use this flag it is okay to use "manual",
and then it only applies to *test* execution.
But if you need to remove targets from the build phase you need to express that differently.

Before this flag nothing could be done
++++++++++++++++++++++++++++++++++++++

Before `--build_manual_tests` was introduce there was no way to build manual targets through wildcards.
There is (still) a flag to filter and remove based on tags, and it can also add stuff back.
But anything tagged as manual can not be retrieved through `--build_tag_filters`.
Neither of the following does anything::

    $ bazel build --aspects //:ruff.bzl%ruff --build_tag_filters=enable_again //Parameters:all
    $ bazel build --aspects //:ruff.bzl%ruff --build_tag_filters=+enable_again //Parameters:all
    $ bazel build --aspects //:ruff.bzl%ruff --build_tag_filters=manual //Parameters:all
    $ bazel build --aspects //:ruff.bzl%ruff --build_tag_filters=+manual //Parameters:all

The workaround then was to use a query, and xargs that to `bazel build`.::

    bazel query //... | xargs bazel build

The targets are then all named will be built.

Rule Factory
============

Can be used to set default values for some attributes.
In `//factory:factory.bzl` we recreate the codegen rule.
But set its default value for base, this is a common pattern.

::

    bazel build //factory:test
    Target //factory:test up-to-date:
      bazel-bin/factory/test.h
    cat bazel-bin/factory/test.h
    /* Generated by /home/nils/.cache/bazel/_bazel_nils/38ee34394b564c6d0289781c6b6bf0c1/sandbox/linux-sandbox/2/execroot/example/bazel-out/k8-opt-exec-2B5CBBC6/bin/Parameters/Generate.runfiles/example/Parameters/Generate.py */
    #define a a
    #define base json

There are some things to note for introspection::

    bazel query --output=build //factory:test
    # /home/nils/task/meroton/basic-codegen/factory/BUILD.bazel:3:8
    codegen(
      name = "test",
      srcs = ["//factory:a.json"],
    )
    # Rule test instantiated at (most recent call last):
    #   /home/nils/task/meroton/basic-codegen/factory/BUILD.bazel:3:8 in <toplevel>
    # Rule codegen defined at (most recent call last):
    #   /home/nils/task/meroton/basic-codegen/factory/factory.bzl:51:15 in <toplevel>
    #   /home/nils/task/meroton/basic-codegen/factory/factory.bzl:9:16  in make

We see that there is an additional call to `make` in the stacktrace, good!
But the attribute for the base is completely hidden.

We can see it with special flags
--------------------------------

But that is annoying::

    $ bazel query --output=xml //factory:test | grep base.json
        <rule-input name="//factory:base.json"/>

... and with aquery of course.

We would prefer to show it
--------------------------

Let the users know what happens.
We would prefer to show it, but make it immutable.
But the classic default argument through a macro is not good,
because then it could be changed.

Can we make a macro factory?
