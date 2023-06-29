"""Summarize the compile flags for all source files in a target."""

load(":actions.bzl", "prettyAction")

ActionCollectorInfo = provider("Files that are compiled", fields = {
    "compiledFiles": "[String] files found in compilation actions",
    "expectedFiles": "[String] source files",
})

def _rule_impl(ctx):
    return [
        ctx.attr.dep[OutputGroupInfo],
        ctx.attr.dep[ActionCollectorInfo],
    ]

def sort(actions, *, infile, outfile):
    actions.run_shell(
        command = "sort {} > {}".format(infile.path, outfile.path),
        mnemonic = "sort",
        inputs = [infile],
        outputs = [outfile],
    )

def base(name, target, srcs, deps, actions):
    """Shared implementation for the rule and the aspect.

    Args:
        name: for error messages
        target: the target we depend on: a `CcInfo` carrier, we access its `actions` field.
        srcs: dependencies for the target.
        deps: dependencies for the target.
        actions: `ctx.actions`
    Returns:
        providers: (list)
    """
    out = actions.declare_file(name + ".flags")

    targetactions = getattr(target, "actions", [])
    if len(targetactions) == 0:
        fail("No actions found for target: '{}'".format(name))

    content = ""
    compiled = []
    for action in target.actions:
        if action.mnemonic == "CppCompile":
            content += prettyAction(action)
            compiled.append(action.argv[-3])  # HACK

    allfiles = depset(compiled, transitive=[dep[ActionCollectorInfo].compiledFiles for dep in deps])
    actions.write(out, content)
    res = depset([out], transitive=[dep[OutputGroupInfo].flags for dep in deps])

    index = actions.declare_file(name + ".index")
    dumpindex = actions.declare_file(name + ".index-topological")
    actions.write(dumpindex, "\n".join(allfiles.to_list()) + "\n")
    sort(actions, infile = dumpindex, outfile = index)

    sourcefiles = [
        f.path
            for s in srcs
            for f in s.files.to_list()  # The input files are `source file Target` objects, with a depset of a single file.
            if f.path.endswith(".c")
    ]
    # TODO: We cannot send these strings as a depset for some reason
    #   Error in depset: depset elements must not be mutable values
    allexpected = sourcefiles
    for dep in deps:
        allexpected.extend(dep[ActionCollectorInfo].expectedFiles)

    sources = actions.declare_file(name + ".source")
    dumpsources = actions.declare_file(name + ".source-topological")
    actions.write(dumpsources, "\n".join(allexpected) + "\n")
    sort(actions, infile = dumpsources, outfile = sources)

    # TODO: collect transitive files.
    return [
        ActionCollectorInfo(
            compiledFiles = allfiles,
            expectedFiles = allexpected,
        ),
        OutputGroupInfo(
            default = res,
            flags = res,
            index = [index],
            sources = [sources],
        ),
    ]

def _aspect_impl(target, ctx):
    # NB: `ctx.rule.attr.actions` does not exist. It is available under `target`.
    return base(
        ctx.rule.attr.name,
        target,
        srcs = ctx.rule.attr.srcs,
        deps = ctx.rule.attr.deps,
        actions = ctx.actions
    )

compile_flags = aspect(
    implementation = _aspect_impl,
    attr_aspects = ["deps"],
)

compileflags = rule(
    implementation = _rule_impl,
    attrs = {
        "dep": attr.label(aspects = [compile_flags], providers = [CcInfo]),
    },
)

