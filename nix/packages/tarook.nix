{
  lib,
  rustPlatform,
  versionCheckHook,
  nix-update-script,
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "tarook";
  version = "0.1.0";

  src = ../../cli;

  cargoHash = "sha256-XyGx6uqeCdXrzpvTF/nGv9Ud/4/CkUbaETacyZwTvaI=";

  doInstallCheck = true;
  versionCheckProgramArg = "--version";
  nativeInstallCheckInputs = [versionCheckHook];

  passthru.updateScript = nix-update-script {};

  meta = {
    description = "CLI tool to manage Tarook Kubernetes Clusters";
    homepage = "https://tarook.cloud/";
    changelog = "https://docs.tarook.cloud/release/vv${lib.versions.majorMinor finalAttrs.version}/releasenotes.html";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [lykos153];
    mainProgram = "tarook";
  };
})
