{
  inputs.nixpkgs.url = "nixpkgs/nixos-unstable";
  inputs.self.submodules = true;

  outputs =
    { nixpkgs, ... }:
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
      };
      forAllSystems = f: lib.genAttrs systems (system: f (argsFor system));
    in
    {
      packages = forAllSystems (
        { pkgs, ... }:
        {
          default = pkgs.stdenv.mkDerivation {
            name = "lpk-website";
            src = ./.;
            nativeBuildInputs = [ pkgs.hugo ];
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
        { pkgs, ... }:
        {
          default = pkgs.mkShell {
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
