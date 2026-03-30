#!/usr/bin/env bash

set -euo pipefail
actions_dir="$(dirname "$0")/../actions"

# shellcheck source=actions/lib.sh
. "$actions_dir/lib.sh"

# Bring the wireguard interface up if configured so
if [ "${wg_usage:-true}" == "true" ]; then
    "$actions_dir/wg-up.sh"
fi

set_kubeconfig

# Function
test_k8s_certificate_signing_is_functional() {

    echo "Testing Kubernetes certificate signing is functional"

    # Generate a new private key and CSR
    csr="$(
        openssl req -new -subj '/CN=managed-k8s-test-csr' \
            -newkey rsa:4096 -noenc -keyout /dev/null
    )"

    # Create and apply the CertificateSigningRequest in Kubernetes
    cat <<EOF | kubectl apply -f -
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: managed-k8s-test-csr
spec:
  request: $(base64 <<<"$csr" | tr -d "\n")
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 600
  usages:
  - client auth
EOF

    # Approve CertificateSigningRequest
    kubectl certificate approve managed-k8s-test-csr

    # Check if the CSR is issued and approved
    retries=20;delay=3;rc_get_cert=-1;
    for i in $(seq 1 $retries);
    do
      echo "Retry: $i"
      (
          kubectl get csr managed-k8s-test-csr \
          -o jsonpath='{.status.certificate}' | base64 -d \
          | openssl x509 -in /dev/stdin -text
      ); rc_get_cert=$?
      if [ $rc_get_cert -eq 0 ]; then
        break
      else
        sleep $delay
      fi
    done

    # Remove the CSR from Kubernetes
    kubectl delete csr managed-k8s-test-csr

    # Verify return code
    if [ $rc_get_cert -eq 0 ]; then
      echo "Certificate retrieved."
    else
      echo "No certificate retrieved."
      exit 1
    fi

}

# Execute test cases
set +o errexit
test_k8s_certificate_signing_is_functional
set -o errexit
