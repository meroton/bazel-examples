"""Generate header files for parameters given as `.json`."""

def _impl(ctx):
    out = ctx.actions.declare_file(ctx.attr.name + ".h")

    args = ctx.actions.args()
    args.add("--output", out.path)
    args.add_all(ctx.files.srcs)

    ctx.actions.run(
        executable = ctx.executable._tool,
        arguments = [args],
        inputs = ctx.files.srcs,
        mnemonic = "GenerateParameters",
        outputs = [out],
    )

    return [
        # NB: For code generation the file(s) shall be sent as `DefaultInfo::executable`,
        # they will then be sent through the `FilesToRunProvider` provider
        # and can be used as `srcs` in `cc_library`.
        DefaultInfo(
            executable = out,
        )
    ]

codegen = rule(
    implementation = _impl,
    attrs = {
        "srcs": attr.label_list(allow_files=[".json"]),
        "_tool": attr.label(
            executable=True,
            cfg="exec",
            default=":Generate",
        ),
    },
)
