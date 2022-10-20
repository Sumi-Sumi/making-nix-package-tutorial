{
  description = "Making package using nvfetcher";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nvfetcher = {
      url = "github:berberman/nvfetcher";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, nvfetcher } @ inputs:
    let
      lib = nixpkgs.lib;
      genPkg = func: name: {      # 別ファイルに記されたビルド定義とバッケージ情報などをまとめる
        inherit name;
        value = func name;
      };
      genApp = pkgs: name: {
        inherit name;
        value = flake-utils.lib.mkApp { drv = pkgs.${name}; };
        };
      # default.nixの属性にpassthru = { runnable = true }を追記するとnix runで実行できるように自動でappsに追加する
      isRunableApp = pkgs: name: if pkgs.${name}.passthru.runnable or false then name else null;
      runnableApps = pkgs: lib.remove null (map (isRunableApp pkgs) names);

      pkgDir = ./packages;        # ビルと手順が記されたパッケージディレクトリ
      sources = import ./_sources/generated.nix;  # パッケージ情報が記されたディレクトリ
      broken = import ./packages/broken.nix;  # ビルドできないパッケージを列挙

      ls = builtins.readDir pkgDir;
      isDir = ts: t: if ts.${t} == "directory" then t else null; # ディレクトリのみを列挙
      names = with builtins; lib.subtractLists broken (lib.remove null (map (isDir ls) (attrNames ls)));
      withContents = func: with builtins; listToAttrs (map (genPkg func) names);

      mkApps = pkgs: appNames: with builtins; listToAttrs (map (genApp pkgs) appNames);
    in
      { # Overlaysの定義
        overlays.default = final: prev:      # final: prev:はpythonでいうself, super
        let
          sources' = sources { inherit (final) fetchgit fetchurl fetchFromGitHub ; };
        in withContents (name:
          let
            pkgs = import (pkgDir + "/${name}");
            override = builtins.intersectAttrs (builtins.functionArgs pkgs) ({
              pythonPackages = final.python3.pkgs;
              mySource = sources'.${name};
            });
          in final.callPackage pkgs override
          ) // { sources = sources'; };
      } # ここから先はnix buildやnix runで使うための設定（このリポジトリ単体でも使えるようにする）
      // flake-utils.lib.eachSystem ["x86_64-linux" "aarch64-linux"] (system:
        let
          pkgs = import nixpkgs {
            system = "${system}";
            overlays = [ self.overlays.default nvfetcher.overlay];  # nvfetcherもoverlayする
            config.allowUnfree = true;
          };
        in with pkgs.legacyPackages.${system}; rec {
          packages =  withContents (name: pkgs.${name});
          apps = mkApps pkgs (runnableApps pkgs);
          checks = packages;  # For `nix flake check`
          devShells.default = nvfetcher.packages.${system}.ghcWithNvfetcher;  # For `nix develop`
        }
      );
}
