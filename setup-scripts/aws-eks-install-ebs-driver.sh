#!/usr/bin/env bash

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
LIB_DIR="$(realpath "$SCRIPT_DIR/../lib")"

SERVICE_ACCOUNT_NAME="ebs-csi-controller-sa"
CLUSTER_NAME=""

source "$LIB_DIR/general-helper-functions.sh"

function usage () {
    echo "$0 -c cluster-name [ -h ]"
}   

while getopts "c:h" OPT; do
    case "${OPT}" in
        c) CLUSTER_NAME="${OPTARG}" ;;
        h) usage && exit 0 ;;
        *) usage >&2 && exit 1 ;;
    esac
done

[[ -z "$CLUSTER_NAME" ]] && usage >&2 && exit 1

check_cmds eksctl helm || exit 1

new_role_name="${CLUSTER_NAME}-AmazonEKS_EBS_CSI_DriverRole"
aws_service_role="arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"

info "Installing the $SERVICE_ACCOUNT_NAME service account in $CLUSTER_NAME"
eksctl create iamserviceaccount \
    --name $SERVICE_ACCOUNT_NAME \
    --namespace kube-system \
    --cluster $CLUSTER_NAME \
    --role-name $new_role_name \
    --role-only \
    --attach-policy-arn $aws_service_role \
    --approve

helm repo list | grep ^aws-ebs >/dev/null 2>&1 || \
    helm repo add aws-ebs-csi-driver https://kubernetes-sigs.github.io/aws-ebs-csi-driver
helm repo update

info "Installing the aws-ebs-csi-driver"
## See https://github.com/kubernetes-sigs/aws-ebs-csi-driver/blob/master/docs/install.md#set-up-driver-permissions
helm upgrade --install aws-ebs-csi-driver \
    --namespace kube-system \
    --set controller.serviceAccount.autoMountServiceAccountToken=true \
    aws-ebs-csi-driver/aws-ebs-csi-driver

exit $?
