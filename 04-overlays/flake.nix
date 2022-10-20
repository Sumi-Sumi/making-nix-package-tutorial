{
  description = "Making overlays package";
  # Nixpkgs / NixOS version to use.
  inputs.nixpkgs.url = "nixpkgs/nixos-unstable";
  # Using flake-utils
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils } @ inputs:
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
      sources = import ./sources/sources.nix;  # パッケージ情報が記されたディレクトリ

      ls = builtins.readDir pkgDir;
      names = with builtins; lib.remove null (map ((ts: t: if ts.${t} == "directory" then t else null) ls) (attrNames ls));  # ディレクトリのみを列挙
      withContents = func: with builtins; listToAttrs (map (genPkg func) names);

      mkApps = pkgs: appNames: with builtins; listToAttrs (map (genApp pkgs) appNames);
    in
      { # Overlaysの定義
        overlays.default = final: prev:      # final: prev:はpythonでいうself, super
        let
          sources' = sources {};
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
            overlays = [ self.overlays.default ];
            config.allowUnfree = true;
          };
        in with pkgs.legacyPackages.${system}; rec {
          packages =  withContents (name: pkgs.${name});
          apps = mkApps pkgs (runnableApps pkgs);
        }
      );
}
