{
  lib,
  yk8s-lib,
  ...
}: {
  config.yk8s = lib.mkForce (
    yk8s-lib.importTOML ./overrides.toml
  );
}
