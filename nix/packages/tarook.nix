{
  lib,
  python3,
}:
python3.pkgs.buildPythonApplication (finalAttrs: {
  pname = "tarook";
  version = "0.1.0";

  src = ../../cli;

  pyproject = true;
  build-system = with python3.pkgs; [
    setuptools
    wheel
  ];

  dependencies = with python3.pkgs; [
    click
  ];

  meta = {
    description = "CLI tool to manage Tarook Kubernetes Clusters";
    homepage = "https://tarook.cloud/";
    changelog = "https://docs.tarook.cloud/release/v${lib.versions.majorMinor finalAttrs.version}/releasenotes.html";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [lykos153];
    mainProgram = "tarook";
  };
})
