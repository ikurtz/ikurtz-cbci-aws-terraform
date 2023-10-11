#!/usr/bin/env bash

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
LIB_DIR="$(realpath "$SCRIPT_DIR/../lib")"

EFS_POLICY_ARN="arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"
SERVICE_ACCOUNT_NAME="efs-csi-controller-sa"

source "$LIB_DIR/general-helper-functions.sh"

function usage () {
    echo "$0 -c cluster-name -r roleName-related-to-the-cluster -a aws-account-id [ -h ]"
}   

while getopts "c:a:r:h" OPT; do
    case "${OPT}" in
        c) CLUSTER_NAME="${OPTARG}" ;;
        a) AWS_ACCOUNT_ID="${OPTARG}" ;;
        r) ROLE_NAME="${OPTARG}" ;;
        h) usage && exit 0 ;;
        *) usage >&2 && exit 1 ;;
    esac
done

[[ -z "$CLUSTER_NAME" ]] || [[ -z "$AWS_ACCOUNT_ID" ]] || [[ -z "$ROLE_NAME" ]] && \
    usage >&2 && exit 1
    
ROLE_NAME="${ROLE_NAME}-eksctl"

check_cmds aws eksctl helm || exit 1

info "Creating service account (ROLE) via eksctl..."

eksctl create iamserviceaccount \
    --override-existing-serviceaccounts \
    --name $SERVICE_ACCOUNT_NAME \
    --namespace kube-system \
    --cluster $CLUSTER_NAME \
    --role-name $ROLE_NAME \
    --attach-policy-arn $EFS_POLICY_ARN \
    --approve

[[ "$?" -ne 0 ]] && exit 1

info "Getting the trust policy for $ROLE_NAME"
trust_policy="$(aws iam get-role --role-name $ROLE_NAME --query 'Role.AssumeRolePolicyDocument' | \
    sed -e 's/'$SERVICE_ACCOUNT_NAME'/efs-csi-*/' -e 's/StringEquals/StringLike/')"

info "Updating the trust policy for the EFS CSI Driver..."
aws iam update-assume-role-policy --role-name $ROLE_NAME --policy-document "$trust_policy"

info "Installing the aws-efs-csi-driver via helm..."
helm repo list | grep ^aws-efs >/dev/null 2>&1 || \
    helm repo add aws-efs-csi-driver https://kubernetes-sigs.github.io/aws-efs-csi-driver/
helm repo update aws-efs-csi-driver
helm upgrade \
    --install aws-efs-csi-driver \
    --namespace kube-system \
    --set controller.serviceAccount.create=false \
    --set controller.serviceAccount.name=$SERVICE_ACCOUNT_NAME \
    aws-efs-csi-driver/aws-efs-csi-driver

exit $?
