{lib}: {
  # Values that are compatible with JSON, YAML and TOML
  jsonValue = let
    valueType = with lib.types;
      nullOr (oneOf [
        bool
        int
        float
        str
        (attrsOf valueType)
        (listOf valueType)
      ])
      // {
        description = "JSON value";
      };
  in
    valueType;
}
