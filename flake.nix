{
  inputs.nixpkgs.url = "nixpkgs/nixos-unstable";
  inputs.papermod = {
    url = "github:adityatelange/hugo-PaperMod";
    flake = false;
  };

  outputs =
    { nixpkgs, papermod, ... }:
    let
      lib = nixpkgs.lib;
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];
      argsFor = system: {
        pkgs = nixpkgs.legacyPackages.${system};
        themesDir = nixpkgs.legacyPackages.${system}.linkFarm "hugo-themes" [
          {
            name = "papermod";
            path = papermod;
          }
        ];
      };
      forAllSystems = f: lib.genAttrs systems (system: f (argsFor system));
    in
    {
      packages = forAllSystems (
        { pkgs, themesDir, ... }:
        {
          default = pkgs.stdenv.mkDerivation {
            name = "lpk-website";
            src = ./.;
            nativeBuildInputs = [ pkgs.hugo ];
            HUGO_THEMESDIR = themesDir;
            buildPhase = ''
              runHook preBuild
              hugo --minify --gc --destination $out
              runHook postBuild
            '';
            dontInstall = true;
          };
        }
      );

      devShells = forAllSystems (
        { pkgs, themesDir, ... }:
        {
          default = pkgs.mkShell {
            HUGO_THEMESDIR = themesDir;
            packages = with pkgs; [
              hugo
              (pkgs.writeShellScriptBin "dev" ''
                hugo serve
              '')
            ];
          };
        }
      );

      formatter = forAllSystems (
        { pkgs, ... }:
        pkgs.treefmt.withConfig {
          settings = {
            on-unmatched = "info";
            formatter.nixfmt = {
              command = lib.getExe pkgs.nixfmt-rfc-style;
              includes = [ "*.nix" ];
            };
          };
        }
      );
    };
}
