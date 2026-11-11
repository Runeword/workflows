{ pkgs, lefthook }:
lefthook.lib.${pkgs.stdenv.hostPlatform.system}.mkShell {
  hooks = {
    format-nix.enable = true;
    lint-nix.enable = true;
    format-yaml.enable = true;
    security-gitleaks.enable = true;
    auto-commit.enable = true;
  };
}
