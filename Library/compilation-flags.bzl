"""Summarize the compile flags for all source files in a target."""

load(":actions.bzl", "prettyAction")

def _rule_impl(ctx):
    return base(ctx.attr.name, ctx.attr.dep, ctx.actions)

def base(name, dep, actions):
    """Shared implementation for the rule and the aspect.

    Args:
        name: for error messages
        dep: the target we depend on: a `CcInfo` carrier, we access its `actions` field.
        actions: `ctx.actions`
    Returns:
        providers: (list)
    """
    out = actions.declare_file(name + ".flags")
    targetactions = getattr(dep, "actions", [])
    if len(targetactions) == 0:
        fail("No actions found for dep: '{}'".format(name))

    content = ""
    for action in targetactions:
        if action.mnemonic == "CppCompile":
            content += prettyAction(action)

    actions.write(out, content)

    # TODO: collect transitive files.
    return [
        OutputGroupInfo(
            default = depset([out]),
            flags = depset([out]),
        ),
    ]

def _aspect_impl(target, ctx):
    # NB: `ctx.rule.attr.actions` does not exist. It is available under `target`.
    return base(ctx.rule.attr.name, target, ctx.actions)

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
