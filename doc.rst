Documentation
~~~~~~~~~~~~~

Label Flag
==========

A contrived example is written, and developed through the commit history
to show how a `label_flag` can be used to add configuration to a rule.

We see that it does not work well for a `py_binary` to use it as a data dependency,
as we do not know what *file* to look for within the runfiles.

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
--------

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
