# Working conventions for activegraph

## Commit messages — Conventional Commits (required going forward)

All new commits **and PR titles** must follow [Conventional Commits](https://www.conventionalcommits.org/):

```
type(optional-scope): short imperative subject
```

PRs are **squash-merged**, so the PR title becomes the single commit on the
default branch — write the PR title as a conventional commit.

Types that appear in the generated changelog (see `cliff.toml`):

| type   | Changelog section |
|--------|-------------------|
| `feat` | Added             |
| `fix`  | Fixed             |
| `perf` | Performance       |

Other valid types are fine but are **excluded** from the changelog:
`chore`, `ci`, `docs`, `refactor`, `test`, `style`, `build`, `revert`.

Examples:
- `feat(node): support composite id_property constraints`
- `fix(query): escape backticks in relationship type names`
- `perf: batch index lookups in schema inspection`
- `ci: skip the matrix on docs-only changes`

Reference a PR/issue in the subject as `(#1234)` — `cliff.toml` turns it into a link.

## CHANGELOG.md

- The `[Unreleased]` section is generated from conventional commits:
  `rake changelog` (refresh) / `rake "changelog[v12.0.0.beta.8]"` (finalize a
  version at release).
- The task is **non-destructive**: it only rewrites the top `[Unreleased]`/version
  section and inserts it under the preamble. Everything below is **hand-written
  history from before conventional commits were adopted — never regenerate or
  overwrite it** (git-cliff can't reproduce those non-conventional commits).
