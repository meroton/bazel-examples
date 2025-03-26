load("@rules_python//python:py_binary.bzl", defer = "py_binary")


def _impl(**kwargs):
    defer(**kwargs)


py_binary = macro(
    implementation = _impl,
    # NB: Seems that we can't take the attributes from the public macro
    # we must find the (private) real rule.
    # inherit_attrs = defer,
    attrs = {
        "srcs": attr.label_list(),
        "data": attr.label_list(),
        "main": attr.label(),
        "target_compatible_with": attr.label_list(),
        "deps": attr.label_list(),
    },
)
