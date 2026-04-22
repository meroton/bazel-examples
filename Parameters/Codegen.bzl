"""Generate header files for parameters given as `.json`."""

def _impl(ctx):
    out = ctx.actions.declare_file(ctx.attr.name + ".h")

    workspace_name = ctx.workspace_name
    print(workspace_name)

    args = ctx.actions.args()
    args.add("--base", ctx.files._base[0])
    args.add("--output", out.path)
    args.add("--literal", "Workspace: " + workspace_name)
    args.add_all(ctx.files.srcs)

    ctx.actions.run(
        executable = ctx.executable._tool,
        arguments = [args],
        inputs = ctx.files.srcs + ctx.files._base,
        mnemonic = "GenerateParameters",
        outputs = [out],
    )

    return [
        # NB: For code generation the file(s) shall be sent as `DefaultInfo::files`,
        # they will then be sent through the `FilesProvider` provider
        # and can be used as `srcs` in a `cc_library`.
        # (`FilesToRunProvider` can also be used, but the files are not executable.)
        #
        #     providers:
        #       - FileProvider
        #       - FilesToRunProvider
        #       - OutputGroupInfo

        #     output_groups:
        #       - _hidden_top_level_INTERNAL_
        #       - to_json
        #       - to_proto

        #     FileProvider:
        #       - bazel-out/k8-fastbuild/bin/Parameters/Parameters.h

        #     FilesToRunProvider:
        #       - None
        #       - None
        DefaultInfo(
            files = depset([out]),
        ),
        OutputGroupInfo(
            default = depset([out])
        ),
    ]

codegen = rule(
    implementation = _impl,
    attrs = {
        "srcs": attr.label_list(allow_files=[".json"]),
        "_tool": attr.label(
            executable = True,
            cfg = "exec",
            default = ":Generate",
        ),
        "_base": attr.label(
            executable=False,
            allow_single_file=["json"],
            default="//config:config_file"
        ),
    },
)
    # # Label flags are good to add extra arguments that can be switched by the user,
    # for the whole build.
    # An exported attribute works well if it should vary for individual targets,
    # a macro can be used to set a default value.
    # But for switches to all targets using BUILD files is not so good,
    # we then use a private attribute that cannot be set in the BUILD file
    # and let the `build_setting`, in this case `label_flag`,
    # handle the value and its default.
