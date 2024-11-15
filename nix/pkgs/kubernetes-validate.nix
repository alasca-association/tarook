{
  lib,
  buildPythonPackage,
  fetchPypi,
  setuptools,
  pyyaml,
  jsonschema,
  typing-extensions,
  importlib-resources,
  packaging,
  referencing,
}:
buildPythonPackage rec {
  pname = "kubernetes_validate";
  version = "1.31.0";

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-36wQEeTZPhs2Mycrf7Hsv6ZyHJOTZihZzMJSp8TYxVU=";
  };

  pyproject = true;

  buildInputs = [
    setuptools
  ];

  propagatedBuildInputs = [
    pyyaml
    jsonschema
    typing-extensions
    importlib-resources
    packaging
    referencing
  ];

  meta = with lib; {
    description = "kubernetes-validate validates Kubernetes resource definitions against the declared Kubernetes schemas.";
    homepage = "https://github.com/willthames/kubernetes-validate";
    license = licenses.asl20;
  };
}
