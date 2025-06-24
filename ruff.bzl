"""Ruff aspect for Python targets."""

load("@rules_python//python/private:py_info.bzl", "PyInfo")

def _impl(_target, ctx):
    out = ctx.actions.declare_file(ctx.rule.attr.name + ".ruff")
    srcs = ctx.rule.files.srcs
    tool = ctx.toolchains["//toolchain:toolchain_type"].info.tool

    if "NoLint" in ctx.rule.attr.tags:
        return []

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
