""" Linting scope. """

LintInfo = provider(
    fields = ["should_lint", "supressions"]
)

def impl(ctx):
    return [
        LintInfo(
            should_lint = ctx.attr.should_lint,
        ),
    ]

lint = rule(
    impl,
    attrs = {
        "should_lint": attr.bool(),
    },
)
