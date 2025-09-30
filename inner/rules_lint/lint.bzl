load("@aspect_rules_lint//lint:clang_tidy.bzl", "lint_clang_tidy_aspect")

clang_tidy = lint_clang_tidy_aspect(
    binary = Label("@clang//:clang-tidy"),
    configs = [
        Label("global.clang-tidy"),
    ],
    lint_target_headers = True,
    angle_includes_are_system = False,
    verbose = False,
)
