workspace(name = "example")

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "bin",
    url = "https://github.com/astral-sh/ruff/releases/download/v0.0.272/ruff-x86_64-unknown-linux-gnu.tar.gz",
    build_file_content = """
load("@bazel_skylib//rules:native_binary.bzl", "native_binary")

native_binary(
    name = "Ruff",
    src = "ruff",
    out = "ruff",
    visibility = ["//visibility:public"],
)
    """,
)

register_toolchains(
    "//toolchain:ruff_toolchain"
)

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "rules_python",
    sha256 = "94750828b18044533e98a129003b6a68001204038dc4749f40b195b24c38f49f",
    strip_prefix = "rules_python-0.21.0",
    url = "https://github.com/bazelbuild/rules_python/releases/download/0.21.0/rules_python-0.21.0.tar.gz",
)

load("@rules_python//python:repositories.bzl", "py_repositories")

py_repositories()



load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "bazel_skylib",
    sha256 = "66ffd9315665bfaafc96b52278f57c7e2dd09f5ede279ea6d39b2be471e7e3aa",
    urls = [
        "https://mirror.bazel.build/github.com/bazelbuild/bazel-skylib/releases/download/1.4.2/bazel-skylib-1.4.2.tar.gz",
        "https://github.com/bazelbuild/bazel-skylib/releases/download/1.4.2/bazel-skylib-1.4.2.tar.gz",
    ],
)

load("@bazel_skylib//:workspace.bzl", "bazel_skylib_workspace")

bazel_skylib_workspace()


# load("@rules_python//python:pip.bzl", "pip_parse")

# # Create a central repo that knows about the dependencies needed from
# # requirements_lock.txt.
# pip_parse(
#    name = "my_deps",
#    requirements_lock = "//path/to:requirements_lock.txt",
# )
# # Load the starlark macro which will define your dependencies.
# load("@my_deps//:requirements.bzl", "install_deps")
# # Call it to define repos for your requirements.
# install_deps()






