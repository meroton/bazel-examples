"""Summarize the compile flags for all source files in a target."""

load(":actions.bzl", "prettyAction")

ActionCollectorInfo = provider("Files that are compiled", fields = {"files": "files"})

def _rule_impl(ctx):
    return base(ctx.attr.name, ctx.attr.dep, [], ctx.actions)

def base(name, target, deps, actions):
    """Shared implementation for the rule and the aspect.

    Args:
        name: for error messages
        target: the target we depend on: a `CcInfo` carrier, we access its `actions` field.
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
    files = []
    for action in target.actions:
        if action.mnemonic == "CppCompile":
            content += prettyAction(action)
            files.append(action.argv[-3])  # HACK

    allfiles = depset(files, transitive=[dep[ActionCollectorInfo].files for dep in deps])
    actions.write(out, content)
    res = depset([out], transitive=[dep[OutputGroupInfo].flags for dep in deps])

    index = actions.declare_file(name + ".index")
    actions.write(index, "\n".join(allfiles.to_list()))

    # TODO: collect transitive files.
    return [
        ActionCollectorInfo(
            files = allfiles,
        ),
        OutputGroupInfo(
            default = res,
            flags = res,
            index = [index],
        ),
    ]

def _aspect_impl(target, ctx):
    # NB: `ctx.rule.attr.actions` does not exist. It is available under `target`.
    return base(ctx.rule.attr.name, target, ctx.rule.attr.deps, ctx.actions)

compileflags = rule(
    implementation = _rule_impl,
    attrs = {
        "dep": attr.label(providers = [CcInfo])
    }
)

compile_flags = aspect(
    implementation = _aspect_impl,
    attr_aspects = ["deps"],
)
