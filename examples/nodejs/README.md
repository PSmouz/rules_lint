# Node.js Formatting and Linting Example

This example demonstrates how to set up formatting and linting for Node.js ecosystem files (JavaScript, TypeScript, Vue, CSS, LESS, SCSS, HTML, Markdown) using `rules_lint`.

## Supported Tools

This example deliberately shows both choices available to JavaScript and TypeScript projects:

- Use Prettier and ESLint when you want the broadest plugin ecosystem and established project compatibility.
- Use npm-backed Oxfmt and Oxlint when you want Oxc's speed and native `oxfmt.config.ts` / `oxlint.config.ts` support.
- Use the built-in `@aspect_rules_lint//format:oxfmt` and `@aspect_rules_lint//lint:oxlint_bin` labels when JSON/JSONC Oxc configuration is enough and you prefer the standalone Rust binaries.

### Formatters

- **Oxfmt** - npm-backed formatter used for the JavaScript formatter bundle so `oxfmt.config.ts` works the same inside and outside Bazel
- **Prettier** - Formatter used in this example for CSS, LESS, SCSS, HTML, and Markdown

### Linters

- **ESLint** - JavaScript and TypeScript linter
- **Oxlint** - npm-backed JavaScript and TypeScript linter so `oxlint.config.ts` is loaded by the Node runtime
- **Stylelint** - CSS linter
- **Vale** - Markdown linter

## Setup

1. Configure MODULE.bazel with required dependencies
2. Create the MODULE.aspect file to register CLI tasks
3. Set up npm dependencies (run `pnpm install` to generate `pnpm-lock.yaml`)
4. Configure Formatters and Linters

- See `tools/format/BUILD.bazel` for how to set up the formatter
- See `tools/lint/linters.bzl` for how to set up each linter aspect

5. Perform formatting and linting using `aspect format` and `aspect lint`

## JavaScript and TypeScript Oxc setup

Install Oxc from npm when you need native JavaScript or TypeScript config files:

```json
{
  "devDependencies": {
    "oxfmt": "^0.46.0",
    "oxlint": "^1.61.0"
  }
}
```

Declare the npm-backed binaries just like ESLint or Prettier:

```starlark
load("@npm//:oxfmt/package_json.bzl", oxfmt = "bin")
load("@npm//:oxlint/package_json.bzl", oxlint = "bin")

oxfmt.oxfmt_binary(
    name = "oxfmt",
    data = ["//:oxfmt_config"],
    env = {"BAZEL_BINDIR": "."},
    fixed_args = [
        "--config=\"$$JS_BINARY__RUNFILES\"/$(rlocationpath //:oxfmt_config)",
    ],
)

oxlint.oxlint_binary(
    name = "oxlint",
    env = {"BAZEL_BINDIR": "."},
)
```

Then pass those labels to `rules_lint`:

```starlark
format_multirun(
    name = "format",
    javascript = "//tools/format:oxfmt",
)

oxlint = lint_oxlint_aspect(
    binary = Label("//tools/lint:oxlint"),
    configs = [Label("//:oxlint_config")],
)
```

The built-in labels remain useful for simpler Oxc setups:

```starlark
format_multirun(
    name = "format",
    javascript = "@aspect_rules_lint//format:oxfmt",
)

oxlint = lint_oxlint_aspect(
    binary = Label("@aspect_rules_lint//lint:oxlint_bin"),
    configs = [Label("//:.oxlintrc.json")],
)
```

Choose the npm-backed path for `oxfmt.config.ts` or `oxlint.config.ts`. Choose the built-in path when JSON/JSONC config files are enough.

## Example Code

The `src/` directory contains example files with intentional violations:

- `hello.js` - Simple JavaScript file
- `file.ts`, `file-dep.ts` - TypeScript files with ESLint violations
- `oxlint.ts` - TypeScript file with an Oxlint violation configured in `oxlint.config.ts`
- `hello.tsx` - React TypeScript file
- `hello.vue` - Vue component
- `hello.css`, `clean.css` - CSS files (one with violations, one clean)
- `hello.less` - LESS file (CSS preprocessor)
- `hello.scss` - SCSS file (SASS CSS preprocessor)
- `index.html` - HTML file
- `README.md` - Markdown file with Vale violations

## Configuration Files

- `eslint.config.mjs` - ESLint configuration
- `oxlint.config.ts` - Oxlint configuration loaded through the npm `oxlint` runtime
- `oxfmt.config.ts` - Oxfmt configuration passed explicitly to the npm `oxfmt` runtime
- `stylelint.config.mjs` - Stylelint configuration
- `.vale.ini` - Vale configuration for Markdown
- `prettier.config.cjs` - Prettier configuration
- `tsconfig.json` - TypeScript configuration
- `.swcrc` - JSONC formatter fixture used to exercise the JavaScript formatter bundle
