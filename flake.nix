{
  description = "Reusable GitHub Actions workflows, shared by Runeword's repositories";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    # Renders the pre-commit hook config for the dev shell, and the check that
    # the tracked copy still matches it.
    lefthook.url = "github:Runeword/lefthook";
    lefthook.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    { nixpkgs, lefthook, ... }:
    let
      # nixpkgs-unstable no longer evaluates for x86_64-darwin.
      forAllSystems =
        f:
        nixpkgs.lib.genAttrs [
          "x86_64-linux"
          "aarch64-linux"
          "aarch64-darwin"
        ] (system: f nixpkgs.legacyPackages.${system});
      mkLefthookShell = pkgs: import ./devshells/lefthook.nix { inherit pkgs lefthook; };
    in
    {
      # Entering the shell (via direnv) renders lefthook-generated.yml into the
      # repository and installs the git hooks. It holds the hooks' tools alone.
      devShells = forAllSystems (pkgs: {
        default = mkLefthookShell pkgs;
      });

      checks = forAllSystems (
        pkgs:
        let
          lefthookStub = pkgs.writeText "lefthook-stub" ''
            extends:
              - lefthook-generated.yml
          '';
        in
        {
          # Both lefthook files run their jobs as the committer on every commit:
          # lefthook.yml must stay the stub, and the generated file must match
          # what devshells/lefthook.nix renders.
          lefthook-config = pkgs.runCommand "lefthook-config" { } ''
            cmp ${lefthookStub} ${./lefthook.yml}
            cmp ${(mkLefthookShell pkgs).lefthookConfig} ${./lefthook-generated.yml}
            touch $out
          '';
        }
      );
    };
}
