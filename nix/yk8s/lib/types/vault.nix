{lib}: let
  common = (import ./_common.nix) {inherit lib;};
  inherit
    (common)
    mkRegexStrOptionType
    ;
in {
  # TODO: Vault namespace names are part of URL paths in Vault's REST API.
  #       Because there are almost no character constraints for namespaces
  #       names, code that makes API calls has to carefully handle non-URL
  #       characters in them.
  #       Tests revealed that names with characters, such as *@+?# and even
  #       emojis work just fine with the Vault CLI client but are handled
  #       differently by the `hashi_vault` Ansible module.
  #       In https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/1731#note_2385728506
  #       it was decided that we do not want to reject what Vault accepts,
  #       hence further investigation is needed.
  namespaceName = mkRegexStrOptionType {
    name = "vaultNamespaceName";
    description = "Name of a Hashicorp Vault namespace";
    # as per https://developer.hashicorp.com/vault/docs/enterprise/namespaces#namespace-naming-restrictions
    matchAgainstAllOf = [
      "^[^ ]+$" # no spaces, non-empty
    ];
    matchAgainstNoneOf = [
      "^.*[/]$" # trailing slash
      "^(root|sys|audit|auth|cubbyhole|identity)([/].*)?$" # reserved namespaces

      # reserved by policy path syntax
      # see https://developer.hashicorp.com/vault/docs/concepts/policies#policy-syntax
      "^[+]$" # single '+'
      "^.*?(\\{\\{.*}}).*?$" # template string within
    ];
  };
  childNamespaceNameSegment = mkRegexStrOptionType {
    name = "vaultChildNamespaceNameSegment";
    description = "Segment of a Hashicorp Vault namespace";
    # as per https://developer.hashicorp.com/vault/docs/enterprise/namespaces#namespace-naming-restrictions
    # see also https://developer.hashicorp.com/vault/docs/enterprise/namespaces#child-namespaces
    matchAgainstAllOf = [
      "^[^ /]+$" # no spaces, no slashes, non-empty
    ];
    matchAgainstNoneOf = [
      # NOTE: there are no reserved child namespaces

      # reserved by policy path syntax
      # see https://developer.hashicorp.com/vault/docs/concepts/policies#policy-syntax
      "^[+]$" # single '+'
      "^.*?(\\{\\{.*}}).*?$" # template string within
    ];
  };
}
