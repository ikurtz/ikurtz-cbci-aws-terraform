#!/usr/bin/env bash

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
LIB_DIR="$(realpath "$SCRIPT_DIR/../lib")"

source "$LIB_DIR/general-helper-functions.sh"

cluster_name="$1"; shift

[[ -z "$cluster_name" ]] && echo "usage: $0 <cluster-name>" >&2 && exit 1

check_cmds aws eksctl || exit 1

info "Looking for an existing OIDC Provider for cluster $cluster_name"
url="$(aws eks describe-cluster --name $cluster_name --query "cluster.identity.oidc.issuer" --output text)"
id="${url##*/}"

aws iam list-open-id-connect-providers | grep $id && {
    info "An OIDC provider exists for this cluster: $cluster_name"
} || {
    info "No IAM OIDC Provider was found for your cluster"
    read -p "Would you like to add it now? (y/n) [y]: "
    [[ -z "$REPLY" ]] && REPLY="y"
    if echo "$REPLY" | egrep -i "^y(es)?$" > /dev/null; then
        info "Hang tight, this takes a couple seconds..."
        eksctl utils associate-iam-oidc-provider --cluster $cluster_name --approve
    else
        info "See: https://docs.aws.amazon.com/eks/latest/userguide/enable-iam-roles-for-service-accounts.html"
    fi
}

exit $?
