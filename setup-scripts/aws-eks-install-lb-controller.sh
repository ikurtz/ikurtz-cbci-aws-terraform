#!/usr/bin/env bash
## aws-oidc-check first!

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
LIB_DIR="$(realpath "$SCRIPT_DIR/../lib")"
OUTDIR="$(realpath "$SCRIPT_DIR/../logs")"

AWS_ACCOUNT_ID=""
CLUSTER_NAME=""
SERVICE_ACCOUNT_NAME="aws-load-balancer-controller"
CREATE_NEW_POLICY=0
EXISTING_AWS_LB_POLICY_NAME=""
AWS_LB_CONTROLLER_VERSION="2.6.0"

source "$LIB_DIR/general-helper-functions.sh"

function usage () {
    echo "$0 -c cluster-name -a aws-account-id [ -p existingAWSPolicyName | -C ] [ -h ]"
    echo "
    If you have an LB existing policy, specify it here with -p.
    If you do not (if this is all new then you likely do NOT have one yet), then use -C to have it created.

    Both options cannot be used together.
    "
}

while getopts "c:a:p:Ch" OPT; do
    case "${OPT}" in
        c) CLUSTER_NAME="${OPTARG}" ;;
        a) AWS_ACCOUNT_ID="${OPTARG}" ;;
        p) EXISTING_AWS_LB_POLICY_NAME="${OPTARG}" ;;
        C) CREATE_NEW_POLICY=1 ;;
        h) usage && exit 0 ;;
        *) usage >&2 && exit 1 ;;
    esac
done

## run thru some conditions to be sure it's ok to proceed...
[[ -z "$CLUSTER_NAME" ]] || [[ -z "$AWS_ACCOUNT_ID" ]] && usage >&2 && exit 1
[[ -n "$EXISTING_AWS_LB_POLICY_NAME" ]] && [[ "$CREATE_NEW_POLICY" -eq 1 ]] && usage >&2 && exit 1
[[ -z "$EXISTING_AWS_LB_POLICY_NAME" ]] && [[ "$CREATE_NEW_POLICY" -eq 0 ]] && usage >&2 && exit 1
check_cmds aws eksctl kubectl helm || exit 1

[[ "$CREATE_NEW_POLICY" -eq 1 ]] && {
    EXISTING_AWS_LB_POLICY_NAME="${CLUSTER_NAME}-lb-controller"

    ## https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.5/deploy/installation/

    info "Pulling iam-policy.json @v${AWS_LB_CONTROLLER_VERSION} from raw.githubusercontent.com/..."
    _policy_file="$OUTDIR/iam-policy.json"
    [[ -f "$_policy_file" ]] && rm $_policy_file >/dev/null 2>&1

    curl -s -o $_policy_file \
        "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v${AWS_LB_CONTROLLER_VERSION}/docs/install/iam_policy.json"

    info "Creating policy: $EXISTING_AWS_LB_POLICY_NAME"
    aws iam create-policy \
        --policy-name $EXISTING_AWS_LB_POLICY_NAME \
        --policy-document file://$_policy_file || \
            warning "If you see a duplicate warning/error, that's probably ok"
}

info "Creating $SERVICE_ACCOUNT_NAME service account for cluster $CLUSTER_NAME"
eksctl create iamserviceaccount \
    --cluster $CLUSTER_NAME \
    --namespace kube-system \
    --name $SERVICE_ACCOUNT_NAME \
    --attach-policy-arn arn:aws:iam::$AWS_ACCOUNT_ID:policy/$EXISTING_AWS_LB_POLICY_NAME \
    --override-existing-serviceaccounts \
    --region us-east-1 \
    --approve

info "Getting eks-charts via helm..."
helm repo list | grep eks | awk '$1 !~/^eks$/ {exit 1}' && \
    helm repo add eks https://aws.github.io/eks-charts
helm repo update eks

info "Applying AWS LB Controller CRD's (Custom Resource Definitions)"
echo
kubectl apply -f https://raw.githubusercontent.com/aws/eks-charts/master/stable/aws-load-balancer-controller/crds/crds.yaml
echo

# NOTE: The clusterName value must be set either via the values.yaml or the Helm command line. The <k8s-cluster-name> in the command
# below should be replaced with name of your k8s cluster before running it.
info "Installing the aws-load-balancer-controller"
helm upgrade -i aws-load-balancer-controller \
    eks/aws-load-balancer-controller \
    -n kube-system \
    --set clusterName=$CLUSTER_NAME \
    --set serviceAccount.create=false \
    --set serviceAccount.name=$SERVICE_ACCOUNT_NAME

exit $?
