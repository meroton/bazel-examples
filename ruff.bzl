"""Ruff aspect for Python targets."""

def _impl(_, ctx):
    out = ctx.actions.declare_file(ctx.rule.attr.name + ".ruff")
    srcs = ctx.rule.files.srcs

    touchargs = ctx.actions.args()
    touchargs.add(out)
    touchargs.add(ctx.executable._tool)
    ruffargs = ctx.actions.args()
    ruffargs.add("check")
    ruffargs.add_all(srcs)

    ctx.actions.run(
        executable = ctx.executable._touch,
        tools = [ctx.executable._tool],
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
    attrs = {
        "_tool": attr.label(
            executable = True,
            cfg = "exec",
            default = "@bin//:Ruff",
        ),
        "_touch": attr.label(
            executable = True,
            cfg = "exec",
            doc = "Wrapper to touch a file on successful execution.",
            default = "//:Touch",
        ),
    },
)
