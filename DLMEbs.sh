
aws iam create-role \
    --role-name AWSDataLifecycleManagerDefaultRole \
    --assume-role-policy-document file://trust-policy.json



aws dlm create-lifecycle-policy \
    --execution-role-arn arn:aws:iam::123456789012:role/AWSDataLifecycleManagerDefaultRole \
    --description "Daily EBS backup lifecycle policy at 01:00 UTC" \
    --state ENABLED \
    --policy-details '{
        "ResourceTypes": ["VOLUME"],
        "TargetTags": [{"Key": "Backup", "Value": "True"}],
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