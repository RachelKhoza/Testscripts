#!/bin/bash

# Step 1: Create the IAM Role for DLM
aws iam create-role \
    --role-name AWSDataLifecycleManagerDefaultRole \
    --assume-role-policy-document '{
        "Version": "2012-10-17",
        "Statement": [{
            "Effect": "Allow",
            "Principal": {
                "Service": "dlm.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }]
    }' \
    --description "Role for DLM to manage EBS snapshots"

# Step 2: Attach the Policy to the Role to Allow DLM to Manage Snapshots
aws iam put-role-policy \
    --role-name AWSDataLifecycleManagerDefaultRole \
    --policy-name DLM-Policy \
    --policy-document '{
        "Version": "2012-10-17",
        "Statement": [{
            "Effect": "Allow",
            "Action": [
                "ec2:CreateSnapshot",
                "ec2:DeleteSnapshot",
                "ec2:DescribeVolumes",
                "ec2:DescribeSnapshots",
                "ec2:CreateTags"
            ],
            "Resource": "*"
        }]
    }'

# Step 3: Create the EBS Lifecycle Policy to Automate Backups at 01:00 UTC
aws dlm create-lifecycle-policy \
    --execution-role-arn arn:aws:iam::123456789012:role/AWSDataLifecycleManagerDefaultRole \
    --description "Daily EBS backup lifecycle policy at 01:00 UTC" \
    --state ENABLED \
    --policy-details '{
        "ResourceTypes": ["VOLUME"],
        "TargetTags": [{"Key": "Role", "Value": "Jump"}],
        "Schedules": [{
            "Name": "DailyBackup",
            "CreateRule": {
                "Interval": 24,
                "IntervalUnit": "HOURS",
                "Times": ["01:00"]
            },
            "RetainRule": {"Count": 7},
            "TagsToAdd": [{"Key": "Snapshot", "Value": "DailyBackup"}]
        }]
    }'