"""Ruff aspect for Python targets."""

def _impl(target, ctx):
    out = ctx.actions.declare_file(ctx.rule.attr.name + ".ruff")
    srcs = ctx.rule.files.srcs
    tool = ctx.toolchains["//toolchain:toolchain_type"].info.tool

    if "NoLint" in ctx.rule.tags:
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
    # Only apply to targets from the `py_*` family, by requiring this provider.
    # TODO(NiWi): Change to a provider check `PyInfo in target`
    # after https://github.com/bazelbuild/bazel/pull/20436
    # has been merged.
    #
    # NB: The alternative and customary `kind` check has two drawbacks:
    # 1) Otherwise, the aspect is built for _all_ targets, simply leaving (no status)
    #    for all unrelated targets.
    # 2) If we create auxiliary rules that generate and build python code
    #    those source files will not be analyzed by this aspect,
    #    even though they should. Subject to a secondary filter on (generate)
    #    source file names.
    # required_providers = [[PyInfo]],
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
