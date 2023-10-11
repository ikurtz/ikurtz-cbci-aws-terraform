#!/usr/bin/env python

import os, sys
import boto3
import pprint
import argparse
import yaml

pp = pprint.PrettyPrinter(indent=4)

ALLOWABLE_ACTIONS = ('stop', 'start')
CLUSTER_STATE_DIR = os.path.join(os.path.expanduser('~'), '.cluster-state')
if not os.path.isdir(CLUSTER_STATE_DIR):
    os.mkdir(CLUSTER_STATE_DIR)

def parse_args() -> object:
    _user_home = os.path.expanduser('~')
    parser = argparse.ArgumentParser(description='Start and Stop instances and EKS cluster nodegroups',
        formatter_class=argparse.ArgumentDefaultsHelpFormatter)

    parser.add_argument('-a', '--action', dest='action', type=str, required=True, 
        default=None, choices=ALLOWABLE_ACTIONS, 
        help='Action to take [{a}]'.format(a='|'.join(ALLOWABLE_ACTIONS)))
    parser.add_argument('-i', '--instance-file', dest='instance_file', type=str, required=False, 
        default=None, help=f'Filename (in {_user_home}) containing the instance ids to manage')
    parser.add_argument('-c', '--cluster-file', dest='cluster_file', type=str, required=False,
        default=None, help=f'Filename (in {_user_home}) containing a list of cluster names. The nodegroups in each cluster will be scaled accordingly.')
    parser.add_argument('-C', '--cluster-name', dest='cluster_name', type=str, required=False,
        default=None, help='If provided, will act upon the cluster specified overriding the cluster file.')
    parser.add_argument('--dry-run', dest='dry_run', action='store_true',
        help='Just print out what we would do, but don\'t actually do it...')
    
    return parser.parse_args()


def _get_data(filename: str) -> list:
    results = []
    results_cleaned = []
    with open(filename, 'r') as f:
        results = [i.strip() for i in f.readlines()]

    ## For right now, anything after the ':' in the file is thrown away in here
    try:
        results_cleaned = [line.split(':')[0] for line in results if line != '']
    except Exception as e:
        print(e)
        pass
    return results_cleaned

def get_clusters_from_file(cluster_file: str) -> list:
    return _get_data(cluster_file)

def get_instances_from_file(res_file: str) -> list:
    return _get_data(res_file)

def get_nodegroups(cluster_name: str) -> list:
    eks = boto3.client('eks')
    _nodegroups = eks.list_nodegroups(clusterName=cluster_name)
    nodegroups = []

    for ng in _nodegroups['nodegroups']:
        ngroup = eks.describe_nodegroup(
            clusterName=cluster_name,
            nodegroupName=ng
        )

        nodegroups.append(ngroup['nodegroup'])

    return nodegroups

def remove_cluster_state(cluster_name: str):
    filename = os.path.join(CLUSTER_STATE_DIR, f'{cluster_name}.yaml')
    if os.path.isfile(filename):
        return os.remove(filename)
    return True

def save_cluster_state(cluster_name: str, data: dict):
    filename = os.path.join(CLUSTER_STATE_DIR, f'{cluster_name}.yaml')
    if not data: return
    with open(filename, 'w') as f:
        doc = yaml.dump(data, f)

def get_cluster_state_from_file(cluster_name: str) -> dict:
    yaml_data_file = os.path.join(CLUSTER_STATE_DIR, f'{cluster_name}.yaml')
    if os.path.isfile(yaml_data_file):
        print(f'Loading previous cluster state: {yaml_data_file}')
        doc = {}
        with open(yaml_data_file, 'r') as f:
            doc = yaml.full_load(f)
        return doc
    else:
        return {}

def scale_nodegroups_up(cluster_name: str, nodegroups: list, dry_run: bool) -> bool:
    eks = boto3.client('eks')
    yaml_data = get_cluster_state_from_file(cluster_name)
    status = []

    for ng in nodegroups:
        prev_state = yaml_data.get(ng['nodegroupName'])
        if prev_state:
            scaling_config = {
                'minSize': prev_state['minSize'],
                'desiredSize': prev_state['desiredSize']
            }
            print(f'\tPrevious state found. Returning {ng["nodegroupName"]} to minSize: {prev_state["minSize"]}, desiredSize: {prev_state["desiredSize"]}')
        else:
            # To account for the random case where you may have a new nodegroup not previously saved
            print('Previous state not found. Defaulting to scaling the nodegroup to 1')
            scaling_config = {
                'minSize': 1,
                'desiredSize': 1
            }

        msg = ''
        if dry_run:
            msg = f'[DRY RUN] Scaling cluster: {ng["clusterName"]}, nodegroup: {ng["nodegroupName"]} to {scaling_config}'
        else:
            scale = eks.update_nodegroup_config(
                clusterName=ng['clusterName'],
                nodegroupName=ng['nodegroupName'],
                scalingConfig=scaling_config
            )
            msg = f'{ng["nodegroupName"]}: {scale["update"]["status"]}'
            status.append({
                'cluster/nodegroup': f"{ng['clusterName']}/{ng['nodegroupName']}",
                'status': scale['update']['status']
            })
        print(msg)
    
    #if not dry_run:
    #    remove_cluster_state(cluster_name)

    return status

def scale_nodegroups_down(nodegroups: list, dry_run: bool) -> bool:
    eks = boto3.client('eks')
    status = []
    scaling_config = {
        'minSize': 0,
        'desiredSize': 0
    }
    yaml_data = {}
    _cluster_name = ''

    for ng in nodegroups:
        _cluster_name = ng['clusterName']
        # capture the current state so we can save it
        yaml_data.update({
            ng['nodegroupName']: ng['scalingConfig']
        })
        msg = ''
        if dry_run:
            msg = f'[DRY RUN] Scaling cluster: {ng["clusterName"]}, nodegroup: {ng["nodegroupName"]} to {scaling_config}'
        else:
            scale = eks.update_nodegroup_config(
                clusterName=ng['clusterName'],
                nodegroupName=ng['nodegroupName'],
                scalingConfig=scaling_config
            )
            msg = f'{ng["nodegroupName"]}: {scale["update"]["status"]}'
            status.append({
                'cluster/nodegroup': f"{ng['clusterName']}/{ng['nodegroupName']}",
                'status': scale['update']['status']
            })
        print(msg)

    if not dry_run:
        print(f'Saving nodegroup state for cluster: {_cluster_name}')
        save_cluster_state(_cluster_name, yaml_data)

    return status


def scale_nodegroups(cluster_name: str, nodegroups: list, action: str, dry_run: bool) -> list:

    if action == 'start':
        status = scale_nodegroups_up(cluster_name, nodegroups, dry_run)
        
    if action == 'stop':
        status = scale_nodegroups_down(nodegroups, dry_run)

    return status

def get_instance(instance_id: str) -> object:
    ec2 = boto3.resource('ec2')
    return ec2.Instance(instance_id)

def get_instance_state(instance: object) -> str:
    return instance.state['Name']

def get_instance_name(instance: object) -> str:
    name = 'unknown'

    for tag in instance.tags:
        if tag['Key'] == 'Name':
            name = tag['Value']
        elif tag['Key'] == 'eks:nodegroup-name':
            name = tag['Value']
        elif tag['Key'] == 'eks:cluster-name':
            name = tag['Value']
    return name

def manage_instance_state(instance_ids: list, target_state: str, dry_run: bool) -> bool:
    ec2 = boto3.client('ec2')
    instance_objs = []
    id_list = []

    for i in instance_ids:
        instance_objs.append(get_instance(i))

    for i in instance_objs:
        if get_instance_state(i) == target_state:
            print(f'{get_instance_name(i)} is already {target_state}')
        else:
            id_list.append(i.id)

    if not id_list:
        print('All instances appear to be in the target state')
        return True

    if not dry_run:
        if target_state == 'stopped':
            print('Stopping instances:')
            list(print(f'\t{i.id}: {get_instance_name(i)}') for i in instance_objs)
            ec2.stop_instances(InstanceIds=id_list)
        elif target_state == 'running':
            print('Starting instances:')
            list(print(f'\t{i.id}: {get_instance_name(i)}') for i in instance_objs)
            ec2.start_instances(InstanceIds=id_list)
        else:
            print(f'uh-oh, {target_state} not handled!')
            return False

        waiter = ec2.get_waiter(f'instance_{target_state}')

        waiter.wait(
            InstanceIds=id_list,
            WaiterConfig = {
                'Delay': 5,
                'MaxAttempts': 30
            }
        )
    else:
        print(f'[DRY RUN] target_state: {target_state}, instances {id_list}')

    success = True

    for i in instance_objs:
        i.reload()
        msg = f'{get_instance_name(i)} ({i.id}) is {get_instance_state(i)}'
        if dry_run:
            msg = f'[DRY RUN] {msg} [would be {target_state}]'
        print(msg)
        if get_instance_state(i) != target_state and not dry_run:
            success = False

    return success

def main() -> bool:
    args = parse_args()

    if not args.instance_file and not args.cluster_file:
        print('See help (-h|--help): at least one instance file or cluster file is required')
        return False

    if args.dry_run:
        print('-------------- [DRY RUN] --------------')
    elif args.action == 'stop':
        answer = input('Are you sure you want to STOP resources? (y/n) [n]: ')
        if not answer or answer not in ('y', 'Y', 'yes', 'Yes', 'YES'):
            return False

    cluster_file = os.path.join(os.path.expanduser('~'), args.cluster_file) if args.cluster_file else None
    instance_file = os.path.join(os.path.expanduser('~'), args.instance_file) if args.instance_file else None

    have_instances = False
    have_clusters = False
    have_nodegroups = False

    if cluster_file and os.path.isfile(cluster_file):
        clusters = get_clusters_from_file(cluster_file)
        if clusters:
            have_clusters = True
            for cluster_name in clusters:
                nodegroups = get_nodegroups(cluster_name)
                if nodegroups:
                    have_nodegroups = True
                    status = scale_nodegroups(cluster_name, nodegroups, args.action, args.dry_run)

                    if status:
                        list(print(f'{s["cluster/nodegroup"]}: {s["status"]}') for s in status)

            if not have_nodegroups:
                print('No nodegroups were found for these clusters')
    else:
        if cluster_file:
            print(f'Cluster file {cluster_file} not found')

    if instance_file and os.path.isfile(instance_file):
        instances = get_instances_from_file(instance_file)
        if instances:
            have_instances = True
            if args.action == 'stop':
                print('Attempting to stop instances...')
                if manage_instance_state(instances, 'stopped', args.dry_run):
                    return True
                else:
                    print('One or more instances failed to stop.')

            if args.action == 'start':
                print('Attempting to start instances...')
                if manage_instance_state(instances, 'running', args.dry_run):
                    return True
                else:
                    print('One or more instances failed to start')
    else:
        if instance_file:
            print(f'Instance file {instance_file} not found')

    if not have_instances and not have_clusters:
        print('There doesn\'t appear to be anything to do!')
        return False

    return True # for now

if __name__ == '__main__':
    if main():
        sys.exit(0)

    sys.exit(1)
 