# workflows

Reusable GitHub Actions workflows, shared by the Runeword repositories. It is
public because a public repository can only call workflows from public ones.

## `dependabot-merge.yml`

Merges a Dependabot pull request, unless it is a major version or edits
`flake.nix`: those wait for a person. A repository calls it from a workflow of
its own, pinned by commit to a release of this one:

```yaml
name: dependabot-auto-merge
on: pull_request
jobs:
  auto-merge:
    permissions:
      contents: write
      pull-requests: write
    uses: Runeword/workflows/.github/workflows/dependabot-merge.yml@<commit> # vX.Y.Z
```

The calling job grants the token its permissions; the workflow can only lower
them.

By default it turns on auto-merge, so the pull request merges once the checks
that branch protection requires pass: both are set in `Runeword/admin`, and on
GitHub Free a repository needs to be public for them. A private repository
calls it with `auto-merge: false` from a job that `needs` its checks, and it
merges right away, only the commit those checks tested:

```yaml
  dependabot-merge:
    needs: check
    permissions:
      contents: write
      pull-requests: write
    uses: Runeword/workflows/.github/workflows/dependabot-merge.yml@<commit> # vX.Y.Z
    with:
      auto-merge: false
```

Merging right away, it deletes the pull request's branch too: GitHub's
"Automatically delete head branches" (set in `Runeword/admin`) doesn't reliably
act on a merge made with the workflow's token. With auto-merge, GitHub merges
and deletes the branch itself.

## Releasing

A change reaches the callers only through a release. Lint it
(`nix run nixpkgs#actionlint`), then tag the commit `vX.Y.Z` and push the tag.
Each caller's Dependabot proposes the new pin once the release is 7 days old
(their `cooldown`), and that pull request runs the new release to merge
itself. A major version waits for a person: release a change that should be
looked at in each repository as a new major version.

This repository's own Dependabot pull requests are merged by hand: nothing
here merges itself.

## Development

`direnv allow` (or `nix develop`) enters the dev shell, which installs the
pre-commit hooks of [Runeword/lefthook](https://github.com/Runeword/lefthook).
A commit formats, lints and scans for secrets what is staged, then splits it
into one commit per file, so `git commit` reports a failure even when it
worked. `LEFTHOOK_EXCLUDE=auto-commit git commit` makes one commit with your
own message.

`nix flake check`, run by hand (there is no CI here), fails when
`lefthook-generated.yml` is not what `devshells/lefthook.nix` renders: after a
change to that file or a bump of the `lefthook` input, run `lefthook-regen` in
the shell and commit the result.
