{ pkgs, inputs }:

let
  disabledPlugins = [
    # That one is not technically a plugin, but by putting it in this list, we
    # get it removed from the top level list of requirement and it is not pull
    # in the nix shell.
    "shake-bench"
  ];

  hpkgsOverride = hself: hsuper:
    with pkgs.haskell.lib;
    {
      hlsDisabledPlugins = disabledPlugins;
    } // (builtins.mapAttrs (_: drv: disableLibraryProfiling drv) {
      apply-refact = hsuper.apply-refact_0_13_0_0;

      stylish-haskell = appendConfigureFlag  hsuper.stylish-haskell "-fghc-lib";

      lsp = hself.callCabal2nix "lsp" inputs.lsp {};
      lsp-types = hself.callCabal2nix "lsp-types" inputs.lsp-types {};
      lsp-test = hself.callCabal2nix "lsp-test" inputs.lsp-test {};
      # For building using our nixpkgs
      strict = hself.callHackage "strict" "0.4.0.1" {};
      these = hself.callHackage "these" "1.1.1.1" {};
      assoc = hself.callHackage "assoc" "1.0.2" {};
      semialign = hself.callHackage "semialign" "1.2.0.1" {};

      # Re-generate HLS drv excluding some plugins
      haskell-language-server =
        hself.callCabal2nixWithOptions "haskell-language-server" ./.
        # Pedantic cannot be used due to -Werror=unused-top-binds
        # Check must be disabled due to some missing required files
        (pkgs.lib.concatStringsSep " " [ "--no-check" "-f-pedantic" "-f-hlint" ]) { };
    });
in {
  inherit disabledPlugins;
  tweakHpkgs = hpkgs: hpkgs.extend hpkgsOverride;
}
