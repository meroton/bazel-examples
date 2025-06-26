""" Linting scope. """

LintInfo = provider(
    fields = ["should_lint", "supressions", "ignore_files"]
)

def impl(ctx):
    return [
        LintInfo(
            should_lint = ctx.attr.should_lint,
            # suppressions = ctx.attr.suppressions
            # ignore_files = ctx.attr.ignore_files
        ),
    ]

lint = rule(
    impl,
    attrs = {
        "should_lint": attr.bool(),
        # suppressions: attr.string_list(),
        # ignore_files: attr.label_list(),
    },
)
