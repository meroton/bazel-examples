"""Rule factory that creates a rule for someone to use."""

def make(base):
    """Make a codegen rule.

    Args:
        base: The default file for a private attribute
    """
    return rule(
        implementation = _impl,
        attrs = {
            "srcs": attr.label_list(allow_files=[".json"]),
            "_tool": attr.label(
                executable = True,
                cfg = "exec",
                default = "//Parameters:Generate",
            ),
            "_base": attr.label(
                executable=False,
                allow_single_file=["json"],
                default=base,
            ),
        }
    )

def _impl(ctx):
    out = ctx.actions.declare_file(ctx.attr.name + ".h")

    args = ctx.actions.args()
    args.add("--base", ctx.files._base[0])
    args.add("--output", out.path)
    args.add_all(ctx.files.srcs)

    ctx.actions.run(
        executable = ctx.executable._tool,
        arguments = [args],
        inputs = ctx.files.srcs + ctx.files._base,
        mnemonic = "GenerateParameters",
        outputs = [out],
    )

    return [
        DefaultInfo(
            files = depset([out]),
        ),
        OutputGroupInfo(
            default = depset([out])
        ),
    ]

codegen = make(base = "//factory:base.json")
