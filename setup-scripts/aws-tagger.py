#!/usr/bin/env python

import os, sys
import boto3
import argparse

ENVIRONMENTS = ('development', 'testing', 'production')

def parse_args() -> object:
    parser = argparse.ArgumentParser(description='Tag mah stuff (ec2 instances, volumes, load balancers)',
        formatter_class=argparse.ArgumentDefaultsHelpFormatter)

    parser.add_argument('-t', '--resource-type', dest='resource_type', choices=('ec2', 'lb'), required=True, default='ec2',
        help="Type of resource")
    parser.add_argument('-r', '--resources', dest='resources', nargs='+', required=True, 
        help='One to many resource IDs to tag (space delimited)')
    parser.add_argument('-u', '--username', dest='local_username', type=str, default=os.getlogin(), required=True, 
        help='Your username to include with the tags')
    parser.add_argument('-e', '--environment', dest='environment_tag', choices=ENVIRONMENTS, required=True, default='development',
        help='The envionment to tag these resources for')
    parser.add_argument('-o', '--owner', dest='owner_tag', type=str, required=True, default='professional-services',
        help='Used to note the owner tag')
    
    return parser.parse_args()

def do_ec2_tags(resources: list, tags: list) -> bool:
    ec2 = boto3.client('ec2')

    return ec2.create_tags(Resources=resources, Tags=tags)

def do_lb_tags(resources: list, tags: list) -> bool:
    elb = boto3.client('elb')

    # LoadBalancerNames (list) --
    # [REQUIRED]
    # 
    # The name of the load balancer. You can specify one load balancer only.
    errors = 0
    for lb in resources:
        if not elb.add_tags(LoadBalancerNames=[lb], Tags=tags):
            errors += 1

    return (errors == 0)

def main():
    args = parse_args()

    tags = [
        {
            'Key': 'cb:owner',
            'Value': args.owner_tag
        },{
            'Key': 'cb:user',
            'Value': args.local_username
        },{
            'Key': 'cb:environment',
            'Value': args.environment_tag
        }
    ]

    if args.resource_type == 'ec2':
        return do_ec2_tags(args.resources, tags)
    elif args.resource_type == 'lb':
        return do_lb_tags(args.resources, tags)

if __name__ == '__main__':
    if not main():
        sys.exit(1)

    sys.exit(0)
