#!/bin/bash
export operation="[apply|destroy]"
export wg_private_key_file="<path/to/wg.key>"
export wg_conf="<path/to/wg0.conf>"
export wg_conf_name="<wg0>"
export wg_user="<wg_user>"
export cluster_name="<cluster-name>"
export cluster_url="<gitlab.cluster_url/>" # please do not forget the last /
export submodule_managed_k8s_git=git@gitlab.cloudandheat.com:lcm/managed-k8s.git
export submodule_wg_user_git=git@gitlab.cloudandheat.com:lcm/wg_user.git
export TF_VAR_keypair="<keypair>"
