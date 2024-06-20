{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
  };

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      env = pkgs.ruby.withPackages (
        ps: with ps; [
          jekyll
          jekyll-paginate
          kramdown
          kramdown-parser-gfm
          webrick
        ]
      );
    in
    {
      devShell."${system}" = pkgs.mkShell { buildInputs = [ env ]; };
    };
}
