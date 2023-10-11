#!/usr/bin/env bash

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
LIB_DIR="$(realpath "$SCRIPT_DIR/../lib")"

source "$LIB_DIR/general-helper-functions.sh"

vpc=""
region=""
in_realtime=0

function usage() {
    echo "
    Usage: $(basename "${BASH_SOURCE[0]}") -v <vpc-id> [ -r <region> -e -h ]

    -v <id>      The VPC ID to look for resources in
    -e           A normal run without this flag uses AWS's 'configservice'. With this flag, we'll
                 use AWS's 'ec2' service to find resources which may not be as accurate.
    -r <region>  In the event that we're not able to obtain the AWS region from your environment,
                 you'll need to provide the region to look in. This can also be used to override any
                 _REGION env variable set.

    By default (without -e) we'll query AWS's configservice using the region configured in your environment.
    "
}

while getopts "v:r:eh" OPT; do

    case "${OPT}" in
        v) vpc="${OPTARG}" ;;
        r) region="${OPTARG}" ;;
        e) in_realtime=1 ;;
        h) usage && exit 0 ;;
        *) usage >&2 && exit 1 ;;
    esac
done

[[ -z "$vpc" ]] && usage >&2 && exit 1

[[ "$in_realtime" -eq 0 ]] && {
    AWS_CONFIG_SQL="
    SELECT resourceId, resourceName, resourceType WHERE relationships.resourceId = '$vpc'
    "

    aws configservice select-resource-config \
        --expression "$AWS_CONFIG_SQL" | jq -r '
                (["ID", "Resource Type", "Resource Name"] | (., map(length*"-"))), 
                (.Results[] | fromjson | [.resourceId, .resourceType, .resourceName]) | @tsv'
} || {

    [[ -z "$region" ]] && {
        region="$(find_env_aws_region)"
        [[ "$?" -ne 0 ]] && {
            error "Unable to obtain the AWS REGION"
            usage
            exit 1
        }
    }

    aws ec2 describe-internet-gateways --region $region --filters 'Name=attachment.vpc-id,Values='$vpc | grep InternetGatewayId
    aws ec2 describe-subnets --region $region --filters 'Name=vpc-id,Values='$vpc | grep SubnetId
    aws ec2 describe-route-tables --region $region --filters 'Name=vpc-id,Values='$vpc | grep RouteTableId
    aws ec2 describe-network-acls --region $region --filters 'Name=vpc-id,Values='$vpc | grep NetworkAclId
    aws ec2 describe-vpc-peering-connections --region $region --filters 'Name=requester-vpc-info.vpc-id,Values='$vpc | grep VpcPeeringConnectionId
    aws ec2 describe-vpc-endpoints --region $region --filters 'Name=vpc-id,Values='$vpc | grep VpcEndpointId
    aws ec2 describe-nat-gateways --region $region --filter 'Name=vpc-id,Values='$vpc | grep NatGatewayId
    aws ec2 describe-security-groups --region $region --filters 'Name=vpc-id,Values='$vpc | grep GroupId
    aws ec2 describe-instances --region $region --filters 'Name=vpc-id,Values='$vpc | grep InstanceId
    aws ec2 describe-vpn-connections --region $region --filters 'Name=vpc-id,Values='$vpc | grep VpnConnectionId
    aws ec2 describe-vpn-gateways --region $region --filters 'Name=attachment.vpc-id,Values='$vpc | grep VpnGatewayId
    aws ec2 describe-network-interfaces --region $region --filters 'Name=vpc-id,Values='$vpc | grep NetworkInterfaceId
    aws ec2 describe-carrier-gateways --region $region --filters Name=vpc-id,Values=$vpc | grep CarrierGatewayId
    aws ec2 describe-local-gateway-route-table-vpc-associations --region $region --filters Name=vpc-id,Values=$vpc | grep LocalGatewayRouteTableVpcAssociationId
}

exit $?
