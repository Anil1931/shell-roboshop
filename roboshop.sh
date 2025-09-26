#!/bin/bash

AMI_ID="ami-09c813fb71547fc4f"
SG_ID="sg-0261a8d4c3a51567e"   #we have to replace with our Security group ID
ZONE_ID="Z0061673127ECQ2F5XQ3Q" #replace with our hosted zone ID in Route 53 
DOMAIN_NAME="hansh123.online"

for instance in $@
do 
    INSTANCE_ID=$(aws ec2 run-instances  --image-id $AMI_ID  --instance-type t3.micro  --security-group-ids $SG_ID  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]"  --query 'Instances[0].InstanceId'  --output text)

    # get private IP
    if [ $instance != "frontend" ]; then
        IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text)
        RECORD_NAME="$instance.$DOMAIN_NAME"  # mongodb.hansh123.online
    else
        IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
        RECORD_NAME="$DOMAIN_NAME" #hansh123.online (front end URL)

    fi

    echo "$instance: $IP"

    aws route53 change-resource-record-sets \
    --hosted-zone-id $ZONE_ID \
    --change-batch '
    {
        "Comment": "Updating record set"
        ,"Changes": [{
        "Action"              : "CREATE"
        ,"ResourceRecordSet"  : {
            "Name"              : "'$RECORD_NAME'"
            ,"Type"             : "A"
            ,"TTL"              : 1
            ,"ResourceRecords"  : [{
                "Value"         : "'$IP'"
            }]
        }
        }]
    }
    '
done