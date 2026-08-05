#!/bin/bash

# ==========================================================
# LedgerPoint Secure Cloud File Storage
# Destroy Script
# ==========================================================

set -e

# Load configuration
source ./config.sh
source ./deployment/deployment-info.env

echo "========================================"
echo " LedgerPoint Resource Cleanup"
echo "========================================"

# --------------------------------------------------------
# Delete Document Bucket Objects
# --------------------------------------------------------
delete_document_objects() {

    echo "Deleting document bucket objects..."

    aws s3 rm "s3://$DOCUMENT_BUCKET" \
        --recursive

    echo "Document bucket emptied."

}

# --------------------------------------------------------
# Delete CloudTrail Log Bucket Objects
# --------------------------------------------------------
delete_log_objects() {

    echo "Deleting CloudTrail log bucket objects..."

    aws s3 rm "s3://$LOG_BUCKET" \
        --recursive

    echo "CloudTrail log bucket emptied."

}

# --------------------------------------------------------
# Delete Document Bucket
# --------------------------------------------------------
delete_document_bucket() {

    echo "Deleting document bucket..."

    aws s3api delete-bucket \
        --bucket "$DOCUMENT_BUCKET" \
        --region "$AWS_REGION"

    echo "Document bucket deleted."

}

# --------------------------------------------------------
# Delete CloudTrail Log Bucket
# --------------------------------------------------------
delete_log_bucket() {

    echo "Deleting CloudTrail log bucket..."

    aws s3api delete-bucket \
        --bucket "$LOG_BUCKET" \
        --region "$AWS_REGION"

    echo "CloudTrail log bucket deleted."

}

# --------------------------------------------------------
# Stop CloudTrail Logging
# --------------------------------------------------------
stop_cloudtrail() {

    echo "Checking CloudTrail..."

    TRAIL_EXISTS=$(aws cloudtrail list-trails \
        --query "Trails[?Name=='$CLOUDTRAIL_NAME'].Name" \
        --output text)

    if [ -z "$TRAIL_EXISTS" ]; then

        echo "CloudTrail not found. Skipping."

        return

    fi

    echo "Stopping CloudTrail logging..."

    aws cloudtrail stop-logging \
        --name "$CLOUDTRAIL_NAME"

    echo "CloudTrail logging stopped."

}

# --------------------------------------------------------
# Delete CloudTrail
# --------------------------------------------------------
delete_cloudtrail() {

    echo "Checking CloudTrail..."

    TRAIL_EXISTS=$(aws cloudtrail list-trails \
        --query "Trails[?Name=='$CLOUDTRAIL_NAME'].Name" \
        --output text)

    if [ -z "$TRAIL_EXISTS" ]; then

        echo "CloudTrail already deleted. Skipping."

        return

    fi

    echo "Deleting CloudTrail..."

    aws cloudtrail delete-trail \
        --name "$CLOUDTRAIL_NAME"

    echo "CloudTrail deleted."

}
# --------------------------------------------------------
# Delete IAM Access Keys
# --------------------------------------------------------
delete_access_keys() {

    echo "Deleting IAM access keys..."

    ACCESS_KEYS=$(aws iam list-access-keys \
        --user-name "$IAM_USER" \
        --query 'AccessKeyMetadata[].AccessKeyId' \
        --output text)

    for KEY in $ACCESS_KEYS
    do
        aws iam delete-access-key \
            --user-name "$IAM_USER" \
            --access-key-id "$KEY"
    done

    echo "IAM access keys deleted."

}

# --------------------------------------------------------
# Detach IAM Policy
# --------------------------------------------------------
detach_iam_policy() {

    echo "Checking IAM policy..."

    if [ -z "$IAM_POLICY_ARN" ]; then

        echo "IAM policy ARN not found. Skipping."

        return

    fi

    echo "Detaching IAM policy..."

    if aws iam detach-user-policy \
        --user-name "$IAM_USER" \
        --policy-arn "$IAM_POLICY_ARN"; then

        echo "IAM policy detached."

    else

        echo "Failed to detach IAM policy. Skipping."

    fi

}

# --------------------------------------------------------
# Delete IAM Policy
# --------------------------------------------------------
delete_iam_policy() {

    echo "Checking IAM policy..."

    if [ -z "$IAM_POLICY_ARN" ]; then

        echo "IAM policy ARN not found. Skipping."

        return

    fi

    echo "Deleting IAM policy..."

    if aws iam delete-policy \
        --policy-arn "$IAM_POLICY_ARN"; then

        echo "IAM policy deleted."

    else

        echo "Failed to delete IAM policy. Skipping."

    fi

}

# --------------------------------------------------------
# Delete IAM User
# --------------------------------------------------------
delete_iam_user() {

    echo "Deleting IAM user..."

    if aws iam delete-user \
        --user-name "$IAM_USER"; then

        echo "IAM user deleted."

    else

        echo "Failed to delete IAM user."
        exit 1

    fi

}

# --------------------------------------------------------
# Delete Document Bucket
# --------------------------------------------------------
delete_document_bucket() {

    echo "Deleting document bucket..."

    aws s3 rm "s3://$DOCUMENT_BUCKET" \
        --recursive

    aws s3api delete-bucket \
        --bucket "$DOCUMENT_BUCKET" \
        --region "$AWS_REGION"

    echo "Document bucket deleted."

}

# --------------------------------------------------------
# Delete Log Bucket
# --------------------------------------------------------
delete_log_bucket() {

    echo "Deleting log bucket..."

    aws s3 rm "s3://$LOG_BUCKET" \
        --recursive

    aws s3api delete-bucket \
        --bucket "$LOG_BUCKET" \
        --region "$AWS_REGION"

    echo "Log bucket deleted."

}

# --------------------------------------------------------
# Remove Local Deployment Files
# --------------------------------------------------------
cleanup_local_files() {

    echo "Cleaning local deployment files..."

    rm -f deployment/access-key.json
    rm -f deployment/policy.json
    rm -f deployment/cloudtrail-policy.json
    rm -f deployment/deployment-info.env

    echo "Local files cleaned."

}

stop_cloudtrail

delete_cloudtrail

delete_access_keys

detach_iam_policy

delete_iam_policy

delete_iam_user

delete_document_objects

delete_log_objects

delete_document_bucket

delete_log_bucket

cleanup_local_files

echo "========================================"
echo " LedgerPoint Cleanup Completed"
echo "========================================"