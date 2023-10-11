#!/usr/bin/env python

import boto3
import pprint
import sys

CLUSTER_REGIONS = ('us-east-1', 'us-east-2', 'us-west-1', 'us-west-2')

pp = pprint.PrettyPrinter(indent=4)

def get_clusters() -> list:
    clusters = []
    for r in CLUSTER_REGIONS:
        eks = boto3.client('eks', region_name=r)
        _clusters = eks.list_clusters()
        for c in _clusters['clusters']:
            clusters.append({
                'name': c,
                'region': r
            })

    return clusters

def get_cluster_oidc_list(clusters: list) -> list:
    oidc_ids = []
    for c in clusters:
        eks = boto3.client('eks', region_name=c['region'])
        cluster = eks.describe_cluster(name=c['name'])
        url = cluster['cluster']['identity']['oidc']['issuer']
        oidc_ids.append(url.split('/')[-1])

    return oidc_ids

def get_oidc_providers() -> list:
    iam = boto3.client('iam')
    providers = iam.list_open_id_connect_providers()

    return providers['OpenIDConnectProviderList']

def main():
    clusters = get_clusters()
    print(f' ---- Located {len(clusters)} clusters across regions: {", ".join(CLUSTER_REGIONS)} ----')

    oidc_ids = get_cluster_oidc_list(clusters)
    providers = get_oidc_providers()
    not_associated_with_eks = []

    for p in providers:
        arn = p['Arn']
        arn_id = arn.split('/')[-1]

        if arn_id not in oidc_ids:
            not_associated_with_eks.append(arn)

    print(f' ---- {len(not_associated_with_eks)} OIDC Providers NOT associated with EKS clusters ----')
    print(*not_associated_with_eks, sep='\n')

    return True

if __name__ == '__main__':
    _argv = sys.argv
    _argv.pop(0)

    if len(_argv):
        print('[WARN] No flags or arguments required, just run it! ...')

    if main():
        sys.exit(0)

    sys.exit(1)
    