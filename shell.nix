with (import <nixpkgs> {});
mkShell {
    shellHook = ''
    curl -L https://foundry.paradigm.xyz | bash
    foundryup
'';
}