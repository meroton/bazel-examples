"""Print the target name - the simplest aspect."""

def _print_impl(_, ctx):
    out = ctx.actions.declare_file(ctx.rule.attr.name + ".name")
    ctx.actions.write(
        output = out,
        content = ctx.rule.attr.name,
    )

    return [
        OutputGroupInfo(
            default = depset([out]),
        ),
    ]

print = aspect(
    implementation = _print_impl,
    # Only apply to targets from the `py_*` family, by requiring this provider.
    # required_providers = [[PyInfo]],
)
