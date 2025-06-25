"""Ruff aspect for Python targets."""

load("@rules_python//python:defs.bzl", "PyInfo")
load("//lint:lint.bzl", "LintInfo")

def _impl(_target, ctx):
    lint_info = None
    for target in getattr(ctx.rule.attr, "aspect_hints", []):
        if LintInfo in target:
            if lint_info != None:
                # TODO: List the targets.
                fail("Multiple 'LintInfo' providers among the aspect hints.")
            lint_info = target[LintInfo]

    if lint_info and not lint_info.should_lint:
        return []

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
