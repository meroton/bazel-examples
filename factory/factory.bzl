"""Rule factory that creates a rule for someone to use."""

def make(defaultvalue):
    """Make a codegen rule.

    Args:
        defaultvalue: The default file for a private attribute
    """
    therule = rule(
        implementation = _impl,
        attrs = {
            "srcs": attr.label_list(allow_files=[".json"]),
            # This is now exported
            "base": attr.label(
                executable=False,
                allow_single_file=["json"],
            ),
            "_tool": attr.label(
                executable = True,
                cfg = "exec",
                default = "//Parameters:Generate",
            ),
        }
    )

    # This example is a little too contrived, as we do not actually achieve data hiding.
    # The rule itself could be called bypassing the macro,
    # but for lack of a better example that is the way it is.
    # As we want to block `base` we add (some of) the default attributes here,
    # that is a little ugly and brittle, but can be macro'd away.
    return therule, lambda name, srcs, visibility = ["//visibility:private"], tags = []: therule(
            name = name,
            srcs = srcs,
            tags = tags,
            visibility = visibility,
            base = defaultvalue,
        )

def _impl(ctx):
    out = ctx.actions.declare_file(ctx.attr.name + ".h")

    args = ctx.actions.args()
    args.add("--base", ctx.files.base[0])
    args.add("--output", out.path)
    args.add_all(ctx.files.srcs)

    ctx.actions.run(
        executable = ctx.executable._tool,
        arguments = [args],
        inputs = ctx.files.srcs + ctx.files.base,
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

# NB: The rule must be bound to a name,
# and that will show up in error messages and query --output={build,label_kind}
_codegen, codegen = make(defaultvalue = "//factory:base.json")
