"""Toolchain Example"""

ToolchainInfo = provider(
    doc = "Example toolchain",
    fields = ["tool"],
)

def toolchain_impl(ctx):
    toolchain_info = platform_common.ToolchainInfo(
        info = ToolchainInfo(
            tool = ctx.executable.tool,
        ),
    )
    return [toolchain_info]

pep8_toolchain = rule(
    implementation = toolchain_impl,
    attrs = {
        "tool": attr.label(
            cfg = "exec",
            executable = True,
            mandatory = True,
        ),
    },
)

