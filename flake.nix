{
  description = "asciidoctor-csl";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, devshell, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; overlays = [ devshell.overlays.default ]; };
        ruby_version = pkgs.ruby_4_0;
      in
      {
        devShells = rec {
          default = asciidoctor-csl;
          asciidoctor-csl = pkgs.devshell.mkShell {
            name = "asciidoctor-csl";
            imports = [ "${devshell}/extra/language/c.nix" ];
            packages = with pkgs; [
              ruby_version
              libyaml
              libyaml.dev
            ];
            env = [
              {
                name = "GEM_HOME";
                eval = "$PRJ_DATA_DIR/bundle/$(ruby -e 'puts RUBY_VERSION')";
              }
              {
                name = "PATH";
                prefix = "$GEM_HOME/bin";
              }
            ];
            commands = [
              {
                name = "check";
                help = "run the tests and RuboCop, like CI";
                command = "bundle exec rake test && bundle exec rubocop --cache false";
              }
            ];
            language.c = {
              compiler = pkgs.gcc;
              includes = [ pkgs.zlib pkgs.gnumake ];
              libraries = [ pkgs.zlib ];
            };
          };
        };
      }
    );
}
