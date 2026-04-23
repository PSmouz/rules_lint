# Node.js Formatting and Linting Example

This example demonstrates how to set up formatting and linting for Node.js ecosystem files (JavaScript, TypeScript, Vue, CSS, LESS, SCSS, HTML, Markdown) using `rules_lint`.

## Supported Tools

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
