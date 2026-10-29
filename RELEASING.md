# Releasing

Releases are cut by pushing a version tag; the
[`release`](.github/workflows/release.yml) workflow does the rest.

The gem version lives in `lib/active_graph/version.rb` and is the single source
of truth: the workflow refuses a tag that disagrees with it. Use RubyGems' dot
form for pre-releases — `12.1.0.beta.1`, not the hyphenated `12.1.0-beta.1`
(RubyGems rewrites the hyphen to `.pre.`).

The top of `CHANGELOG.md` is generated from conventional commits with
[git-cliff](https://git-cliff.org); only `feat`, `fix` and `perf` commits appear
(see `cliff.toml` and `CLAUDE.md`). Everything below the generated section is
hand-written history from before conventional commits were adopted and is never
touched. Install git-cliff once (`brew install git-cliff`, or see its docs).

## Cutting a release

One command does the whole thing — finalize the changelog, land it on the
default branch, and (after a confirmation) tag and trigger the publish:

```bash
rake release            # release the version currently in version.rb
rake "release[12.0.2]"  # bump version.rb to 12.0.2 first, then release
```

It needs an authenticated `gh` and `git-cliff` installed, and a clean checkout
of the default branch in sync with `origin`. It then:

1. Bumps `version.rb` if you passed a version (otherwise uses what's there).
2. Finalizes `CHANGELOG.md`, replacing `[Unreleased]` with a `[<version>]`
   section generated from the commits since the previous tag.
3. Commits both and pushes **straight to the default branch**. Pushing to the
   protected branch is sanctioned by the admin `always` bypass on the branch
   ruleset — a changelog/version commit is paths-ignored by CI and the
   changelog is machine-generated, so a PR would add process without
   protection.
4. Prompts `Continue? [y/N]` (the next step publishes to RubyGems and can't be
   undone), then tags `v<version>` and pushes just that tag, firing
   [`release.yml`](.github/workflows/release.yml).

A version already tagged on `origin` is refused: a released number can never be
reused on RubyGems, so bump to a new one. Set `RELEASE_YES=1` to skip the
prompt (e.g. from an automated caller). Every check runs before anything is
written, so a refused release leaves the tree clean.

Between releases, `rake changelog` on its own refreshes the `[Unreleased]`
section from merged PRs — no tag argument.

## What the workflow does

On any `v*` tag:

- Verifies the tag matches `ActiveGraph::VERSION`, builds the gem and pushes it
  to RubyGems, authenticating via
  [RubyGems Trusted Publishing](https://guides.rubygems.org/trusted-publishing/)
  (OIDC) — no API key is stored. The push is retry-safe: an already-published
  version is treated as success.
- Then creates a **GitHub Release** with notes generated from the pull requests
  merged since the previous tag. Tags carrying a pre-release token
  (`.alpha`/`.beta`/`.rc`/…) are marked **pre-release**.

The gem is published before the GitHub Release so a failed build can never
leave a Release with no matching RubyGems artifact.

## Rolling back a release

Run these **manually** — there is no tag or workflow trigger for a rollback.
Yanking is permanent, so it stays a deliberate, hands-on step. You need RubyGems
owner credentials and an authenticated `gh`.

A yanked version number **can never be reused** on RubyGems, so a rollback is
really "pull the bad release, then ship a *new* version".

1. **Yank the gem**:

   ```bash
   gem yank activegraph -v <version>
   ```

   `yank` removes the version from the index so no new install picks it up; it
   does not uninstall it for anyone who already fetched it.

2. **Delete the GitHub Release and its tag**:

   ```bash
   gh release delete "v<version>" --yes --cleanup-tag
   ```

3. **Fix, then release a new version** with `rake "release[<next version>]"`.
   You cannot reuse the yanked number.

> Only need to re-run a *failed publish* (not a version change)? Re-run the
> failed workflow run — pushing an unchanged tag is a no-op and fires nothing:
>
> ```bash
> gh run list --workflow release.yml --status failure --limit 10   # pick the run for your tag
> gh run rerun <run-id> --failed
> ```
>
> Both workflow jobs are idempotent, so a rerun is safe at any point.
