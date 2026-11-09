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

## Releasing

A change reaches the callers only through a release. Lint it
(`nix run nixpkgs#actionlint`), then tag the commit `vX.Y.Z` and push the tag.
Each caller's Dependabot proposes the new pin once the release is 7 days old
(their `cooldown`), and that pull request runs the new release to merge
itself. A major version waits for a person: release a change that should be
looked at in each repository as a new major version.

This repository's own Dependabot pull requests are merged by hand: nothing
here merges itself.
