def _copy_files_impl(ctx):
    all_outputs = []
    for f in ctx.files.srcs:
        out = ctx.actions.declare_file("{}.{}".format(f.path, ctx.attr.suffix))
        all_outputs.append(out)
        ctx.actions.run_shell(
            outputs = [out],
            inputs = depset([f]),
            arguments = [f.path, out.path],
            command = "cp $1 $2",
            mnemonic = "CopyFiles",
        )

    # Small sanity check
    if len(ctx.files.srcs) != len(all_outputs):
        fail("Output count should be 1-to-1 with input count.")

    return [
        DefaultInfo(
            files = depset(all_outputs),
            runfiles = ctx.runfiles(files = all_outputs),
        ),
    ]

copy_files = rule(
    # This is a simple rule that copy files by adding a suffix to each source file
    # and storing the destination file in the same path. This can be handy to avoid
    # conflicting files within a Bazel sandbox.
    implementation = _copy_files_impl,
    attrs = {
        "srcs": attr.label_list(
            allow_files = True,
            mandatory = True,
        ),
        "suffix": attr.string(
            doc = "Suffix that will be added to each srcs file",
            default = "generated",
        ),
    },
)

