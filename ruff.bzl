"""Ruff aspect for Python targets."""

def _impl(_, ctx):
    out = ctx.actions.declare_file(ctx.rule.attr.name + ".ruff")
    srcs = ctx.rule.files.srcs
    tool = ctx.toolchains["//toolchain:toolchain_type"].info.tool

    touchargs = ctx.actions.args()
    touchargs.add(out)
    touchargs.add(tool)
    ruffargs = ctx.actions.args()
    ruffargs.add("check")
    ruffargs.add_all(srcs)

    ctx.actions.run(
        executable = ctx.executable._touch,
        tools = [tool],
        arguments = [touchargs, ruffargs],
        inputs = srcs,
        mnemonic = "Ruff",
        outputs = [out],
    )

    return [
        OutputGroupInfo(
            default = depset([out])
        )
    ]

ruff = aspect(
    implementation = _impl,
    # Only apply to targets from the `py_*` family, by requiring this provider.
    required_providers = [[PyInfo]],
    attrs = {
        "_touch": attr.label(
            executable = True,
            cfg = "exec",
            doc = "Wrapper to touch a file on successful execution.",
            default = "//:Touch",
        ),
    },
    toolchains = [
        "//toolchain:toolchain_type",
    ],
)
