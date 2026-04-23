load("@aspect_rules_lint//format:defs.bzl", "format_multirun")
load("@npm//:oxfmt/package_json.bzl", oxfmt = "bin")
load("@npm//:prettier/package_json.bzl", prettier = "bin")

package(default_visibility = ["//:__subpackages__"])

prettier.prettier_binary(
    name = "prettier",
    data = ["//:prettierrc"],
    env = {"BAZEL_BINDIR": "."},
    fixed_args = [
        "--config=\"$$JS_BINARY__RUNFILES\"/$(rlocationpath //:prettierrc)",
        "--loglevel=warn",
    ],
)

oxfmt.oxfmt_binary(
    name = "oxfmt",
    data = ["//:oxfmt_config"],
    env = {"BAZEL_BINDIR": "."},
    fixed_args = [
        "--config=\"$$JS_BINARY__RUNFILES\"/$(rlocationpath //:oxfmt_config)",
    ],
)

format_multirun(
    name = "format",
    css = ":prettier",  # css includes Less and SCSS
    html = ":prettier",
    javascript = ":oxfmt",
    markdown = ":prettier",
    visibility = ["//:__subpackages__"],
)
