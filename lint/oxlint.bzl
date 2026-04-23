"""API for declaring an Oxlint lint aspect for JavaScript and TypeScript targets.

Typical usage:

Oxlint is provided as a built-in tool by rules_lint. To use the built-in version,
create the linter aspect, typically in `tools/lint/linters.bzl`:

```starlark
load("@aspect_rules_lint//lint:oxlint.bzl", "lint_oxlint_aspect")

oxlint = lint_oxlint_aspect(
    binary = Label("@aspect_rules_lint//lint:oxlint_bin"),
    configs = [Label("//:.oxlintrc.json")],
)
```

The configuration file follows Oxlint's ESLint-compatible JSON format. Oxlint
automatically discovers the appropriate `tsconfig.json` for each source file.
"""

load("@aspect_rules_js//js:libs.bzl", "js_lib_helpers")
load("@bazel_lib//lib:copy_to_bin.bzl", "COPY_FILE_TO_BIN_TOOLCHAINS")
load("//lint/private:lint_aspect.bzl", "LintOptionsInfo", "OPTIONAL_SARIF_PARSER_TOOLCHAIN", "OUTFILE_FORMAT", "filter_srcs", "noop_lint_action", "output_files", "parse_to_sarif_action", "patch_and_output_files", "should_visit")
load("//lint/private:patcher_action.bzl", "patcher_attrs", "run_patcher")

_MNEMONIC = "AspectRulesLintOxlint"

def _gather_inputs(ctx, srcs, files):
    inputs = list(srcs)
    inputs.extend(ctx.files._config_files)

    js_inputs = getattr(ctx.rule.attr, "deps", []) + files

    if hasattr(ctx.rule.attr, "tsconfig"):
        js_inputs.append(ctx.rule.attr.tsconfig)
        inputs.extend(ctx.rule.files.tsconfig)

    if "gather_files_from_js_providers" in dir(js_lib_helpers):
        js_inputs = js_lib_helpers.gather_files_from_js_providers(
            js_inputs,
            include_transitive_sources = True,
            include_declarations = True,
            include_npm_linked_packages = True,
        )
    else:
        js_inputs = js_lib_helpers.gather_files_from_js_infos(
            js_inputs,
            include_sources = True,
            include_transitive_sources = True,
            include_types = True,
            include_transitive_types = True,
            include_npm_sources = True,
        )

    return depset(inputs, transitive = [js_inputs])

def _config_file(ctx):
    return ctx.files._config_files[0]

def _tsconfig_file(ctx):
    if hasattr(ctx.rule.files, "tsconfig") and len(ctx.rule.files.tsconfig) > 0:
        return ctx.rule.files.tsconfig[0]
    return None

def _args_list(ctx, srcs, format, fix = False):
    args = [
        "--config",
        _config_file(ctx).path,
        "--format",
        format,
        "--no-error-on-unmatched-pattern",
    ]
    tsconfig = _tsconfig_file(ctx)
    if tsconfig:
        args.extend([
            "--tsconfig",
            tsconfig.path,
        ])
    if fix:
        args.append("--fix")
    args.extend([s.path for s in srcs])
    return args

def oxlint_action(ctx, executable, srcs, stdout, exit_code = None, format = "default", env = {}, patch = None):
    """Spawn oxlint as a Bazel action."""
    file_inputs = []
    if patch != None:
        run_patcher(
            ctx,
            ctx.executable,
            inputs = _gather_inputs(ctx, srcs, file_inputs),
            args = _args_list(ctx, srcs, format, fix = True),
            files_to_diff = [s.path for s in srcs],
            patch_out = patch,
            tools = [executable],
            patch_cfg_env = env,
            stdout = stdout,
            exit_code = exit_code,
            env = env,
            mnemonic = _MNEMONIC,
            progress_message = "Linting %{label} with Oxlint",
        )
        return

    outputs = [stdout]
    args = ctx.actions.args()
    args.add_all(_args_list(ctx, srcs, format))

    if exit_code:
        command = "{oxlint} $@ >{stdout}; echo $? >" + exit_code.path
        outputs.append(exit_code)
    else:
        command = "{oxlint} $@ && touch {stdout}"

    ctx.actions.run_shell(
        inputs = _gather_inputs(ctx, srcs, file_inputs),
        outputs = outputs,
        command = command.format(oxlint = executable.path, stdout = stdout.path),
        arguments = [args],
        env = env,
        mnemonic = _MNEMONIC,
        progress_message = "Linting %{label} with Oxlint",
        tools = [executable],
    )

# buildifier: disable=function-docstring
def _oxlint_aspect_impl(target, ctx):
    if not should_visit(ctx.rule, ctx.attr._rule_kinds):
        return []

    files_to_lint = filter_srcs(ctx.rule)
    if ctx.attr._options[LintOptionsInfo].fix:
        outputs, info = patch_and_output_files(_MNEMONIC, target, ctx)
    else:
        outputs, info = output_files(_MNEMONIC, target, ctx)

    if len(files_to_lint) == 0:
        noop_lint_action(ctx, outputs)
        return [info]

    color_env = {"FORCE_COLOR": "1"} if ctx.attr._options[LintOptionsInfo].color else {}

    oxlint_action(
        ctx,
        ctx.executable._oxlint,
        files_to_lint,
        outputs.human.out,
        outputs.human.exit_code,
        env = color_env,
        patch = getattr(outputs, "patch", None),
    )

    raw_machine_report = ctx.actions.declare_file(OUTFILE_FORMAT.format(label = target.label.name, mnemonic = _MNEMONIC, suffix = "raw_machine_report"))
    oxlint_action(
        ctx,
        ctx.executable._oxlint,
        files_to_lint,
        raw_machine_report,
        outputs.machine.exit_code,
        format = "unix",
    )
    parse_to_sarif_action(ctx, _MNEMONIC, raw_machine_report, outputs.machine.out)

    return [info]

def lint_oxlint_aspect(binary, configs, rule_kinds = ["js_library", "ts_project", "ts_project_rule"]):
    """A factory function to create an oxlint aspect.

    Args:
        binary: an oxlint executable, typically `@aspect_rules_lint//lint:oxlint_bin`
        configs: oxlint config file(s); the first entry is passed as `--config`
        rule_kinds: which [kinds](https://bazel.build/query/language#kind) of rules should be visited by the aspect
    """
    if type(configs) == "string":
        configs = [configs]
    if len(configs) == 0:
        fail("configs must contain at least one oxlint config label")

    return aspect(
        implementation = _oxlint_aspect_impl,
        attrs = patcher_attrs | {
            "_options": attr.label(
                default = "//lint:options",
                providers = [LintOptionsInfo],
            ),
            "_oxlint": attr.label(
                default = binary,
                allow_files = True,
                executable = True,
                cfg = "exec",
            ),
            "_config_files": attr.label_list(
                default = configs,
                allow_files = True,
            ),
            "_rule_kinds": attr.string_list(
                default = rule_kinds,
            ),
        },
        toolchains = COPY_FILE_TO_BIN_TOOLCHAINS + [OPTIONAL_SARIF_PARSER_TOOLCHAIN],
    )
