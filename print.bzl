"""Print the target name - the simplest aspect."""


PrintInfo = provider(
    "PrintInfo",
    fields = ["name"],
)

def _print_impl(_, ctx):
    out = ctx.actions.declare_file(ctx.rule.attr.name + ".name")
    ctx.actions.write(
        output = out,
        content = ctx.rule.attr.name,
    )

    outs = depset([out])
    return [
        PrintInfo(
            name = outs
        ),
        OutputGroupInfo(
            default = outs,
        ),
    ]

print = aspect(
    implementation = _print_impl,
    # Only apply to targets from the `py_*` family, by requiring this provider.
    # required_providers = [[PyInfo]],
)

def _rule_impl(ctx):
    return OutputGroupInfo(
        default = ctx.attr.dep[PrintInfo].name
    )


print_r = rule(
    implementation = _rule_impl,
    attrs = {
        'dep' : attr.label(aspects = [print]),
    },
)
