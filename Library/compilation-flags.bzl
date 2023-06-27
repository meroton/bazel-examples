"""Summarize the compile flags for all source files in a target."""

load(":actions.bzl", "prettyAction")

def _impl(ctx):
    out = ctx.actions.declare_file(ctx.attr.name)
    dep = ctx.attr.dep
    actions = getattr(dep, "actions", [])
    if len(actions) == 0:
        fail("No actions found for dep" + dep)

    content = ""
    for action in actions:
        if action.mnemonic == "CppCompile":
            content += prettyAction(action)

    ctx.actions.write(out, content)

    return [
        OutputGroupInfo(default = depset([out])),
    ]

compileflags = rule(
    implementation = _impl,
    attrs = {
        "dep": attr.label(providers = [CcInfo])
    }
)
