#!/usr/bin/env nu

export def main (sections: list) {
  for sec in $sections {
    let subtypes = (nix eval
      --impure
      --json
      --expr $"
        let
          lib = \(import <nixpkgs> {}).lib;
          types = import ./nix/yk8s/lib/types {inherit lib;};
        in builtins.attrNames types.yk8s.($sec)") | from json
    _replace_types $sec $subtypes
  }
}

export def _replace_types (prefix: string, types: list) {
  for t in $types {
    print $t
    let files = (rg -l $t | lines)
    let new = $t | str replace $prefix "" | str camel-case
    let new = $new | str replace ($prefix | str capitalize) "" | str camel-case
    let new = $"types.($prefix).($new)"
    print $new
    let files = $files | filter {|f| not ( $f | str starts-with "nix/yk8s/lib/types/")} | sort --reverse
    print $files
    if $files != [] {
      sd $t $new ...$files
    }
  }
}
