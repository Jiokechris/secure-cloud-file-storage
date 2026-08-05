#!/bin/bash

# ==========================================================
# LedgerPoint Secure Cloud File Storage
# Deployment Script
# ==========================================================

set -e

# Load configuration
source ./config.sh

# --------------------------------------------------------
# Create Local Project Directories
# --------------------------------------------------------

echo "Creating local project directories..."

mkdir -p deployment
mkdir -p logs
mkdir -p screenshots

echo "Directories created successfully."

# Generate unique timestamp
TIMESTAMP=$(date +%Y%m%d%H%M%S)

# Resource Names
DOCUMENT_BUCKET="${PROJECT_NAME}-documents-${TIMESTAMP}"
LOG_BUCKET="${PROJECT_NAME}-cloudtrail-logs-${TIMESTAMP}"
IAM_USER="${PROJECT_NAME}-office-manager-${TIMESTAMP}"
IAM_POLICY="${PROJECT_NAME}-policy-${TIMESTAMP}"
CLOUDTRAIL_NAME="${PROJECT_NAME}-trail-${TIMESTAMP}"

echo "=============================================="
echo " LedgerPoint Secure Cloud File Storage"
echo " Deployment Started..."
echo "=============================================="

check_prerequisites() {

    echo "Checking AWS CLI..."

    if ! command -v aws &> /dev/null; then
        echo "AWS CLI is not installed."
        exit 1
    fi

    echo "AWS CLI found."

    echo "Checking AWS credentials..."

    if ! aws sts get-caller-identity > /dev/null 2>&1; then
        echo "AWS credentials are not configured."
        exit 1
    fi

    echo "AWS authentication successful."
}

# Create the CloudTrail Log Bucket
create_log_bucket() {

    echo "Creating CloudTrail log bucket..."

    aws s3api create-bucket \
        --bucket "$LOG_BUCKET" \
        --region "$AWS_REGION" \
        --create-bucket-configuration LocationConstraint="$AWS_REGION"

    echo "CloudTrail log bucket created."
}

# --------------------------------------------------------
# Configure CloudTrail Log Bucket Policy
# --------------------------------------------------------
configure_log_bucket_policy() {

    echo "Configuring CloudTrail log bucket policy..."

    cat > deployment/cloudtrail-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AWSCloudTrailAclCheck",
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudtrail.amazonaws.com"
      },
      "Action": "s3:GetBucketAcl",
      "Resource": "arn:aws:s3:::${LOG_BUCKET}"
    },
    {
      "Sid": "AWSCloudTrailWrite",
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudtrail.amazonaws.com"
      },
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::${LOG_BUCKET}/AWSLogs/*",
      "Condition": {
        "StringEquals": {
          "s3:x-amz-acl": "bucket-owner-full-control"
        }
      }
    }
  ]
}
EOF

    if aws s3api put-bucket-policy \
        --bucket "$LOG_BUCKET" \
        --policy file://deployment/cloudtrail-policy.json; then

        echo "CloudTrail bucket policy configured successfully."

    else

        echo "Failed to configure CloudTrail bucket policy."
        exit 1

    fi

}

# Create the Document Bucket
create_document_bucket() {

    echo "Creating document bucket..."

    if aws s3api create-bucket \
        --bucket "$DOCUMENT_BUCKET" \
        --region "$AWS_REGION" \
        --create-bucket-configuration LocationConstraint="$AWS_REGION"; then

        echo "✓ Document bucket created successfully."

    else
        echo "✗ Failed to create document bucket."
        exit 1
    fi
}

# Block public access on the Document Bucket
block_public_access() {

    echo "Blocking public access on document bucket..."

    aws s3api put-public-access-block \
        --bucket "$DOCUMENT_BUCKET" \
        --public-access-block-configuration \
        BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

    echo "✓ Public access blocked."
}

# Enable server-side encryption on the Document Bucket
enable_bucket_encryption() {

    echo "Enabling server-side encryption..."

    aws s3api put-bucket-encryption \
        --bucket "$DOCUMENT_BUCKET" \
        --server-side-encryption-configuration '{
            "Rules":[
                {
                    "ApplyServerSideEncryptionByDefault":{
                        "SSEAlgorithm":"AES256"
                    }
                }
            ]
        }'

    echo "✓ Server-side encryption enabled."
}

# --------------------------------------------------------
# Create IAM User
# --------------------------------------------------------
create_iam_user() {

    echo "Creating IAM user..."

    if aws iam create-user \
        --user-name "$IAM_USER"; then

        echo "IAM user created successfully."

    else

        echo "Failed to create IAM user."
        exit 1

    fi

}

# --------------------------------------------------------
# Generate IAM Policy
# --------------------------------------------------------
generate_iam_policy() {

echo "Generating IAM policy..."

cat > deployment/policy.json <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect":"Allow",
            "Action":[
                "s3:ListBucket"
            ],
            "Resource":"arn:aws:s3:::${DOCUMENT_BUCKET}"
        },
        {
            "Effect":"Allow",
            "Action":[
                "s3:GetObject",
                "s3:PutObject",
                "s3:DeleteObject"
            ],
            "Resource":"arn:aws:s3:::${DOCUMENT_BUCKET}/*"
        }
    ]
}
EOF

echo "IAM policy generated."

}

# --------------------------------------------------------
# Create IAM Policy
# --------------------------------------------------------
create_iam_policy() {

    echo "Creating IAM policy..."

    IAM_POLICY_ARN=$(aws iam create-policy \
        --policy-name "$IAM_POLICY" \
        --policy-document file://deployment/policy.json \
        --query 'Policy.Arn' \
        --output text)

    if [ $? -eq 0 ]; then
        echo "IAM policy created successfully."
    else
        echo "Failed to create IAM policy."
        exit 1
    fi

}

# --------------------------------------------------------
# Attach IAM Policy to IAM User
# --------------------------------------------------------
attach_iam_policy() {

    echo "Attaching IAM policy to IAM user..."

    if aws iam attach-user-policy \
        --user-name "$IAM_USER" \
        --policy-arn "$IAM_POLICY_ARN"; then

        echo "IAM policy attached successfully."

    else

        echo "Failed to attach IAM policy."
        exit 1

    fi

}

# --------------------------------------------------------
# Create Access Keys
# --------------------------------------------------------
create_access_key() {

    echo "Creating access keys..."

    aws iam create-access-key \
        --user-name "$IAM_USER" \
        --output json > deployment/access-key.json

    if [ $? -eq 0 ]; then
        echo "Access keys created successfully."
    else
        echo "Failed to create access keys."
        exit 1
    fi

}

generate_cloudtrail_policy() {

    echo "Generating CloudTrail bucket policy..."

    cat > deployment/cloudtrail-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AWSCloudTrailAclCheck",
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudtrail.amazonaws.com"
      },
      "Action": "s3:GetBucketAcl",
      "Resource": "arn:aws:s3:::${LOG_BUCKET}"
    },
    {
      "Sid": "AWSCloudTrailWrite",
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudtrail.amazonaws.com"
      },
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::${LOG_BUCKET}/AWSLogs/*",
      "Condition": {
        "StringEquals": {
          "s3:x-amz-acl": "bucket-owner-full-control"
        }
      }
    }
  ]
}
EOF

    echo "CloudTrail bucket policy generated."

}

apply_cloudtrail_policy() {

    echo "Applying CloudTrail bucket policy..."

    aws s3api put-bucket-policy \
        --bucket "$LOG_BUCKET" \
        --policy file://deployment/cloudtrail-policy.json

    echo "CloudTrail bucket policy applied."

}

# --------------------------------------------------------
# Create CloudTrail
# --------------------------------------------------------
create_cloudtrail() {

    echo "Creating CloudTrail..."

    if aws cloudtrail create-trail \
        --name "$CLOUDTRAIL_NAME" \
        --s3-bucket-name "$LOG_BUCKET"; then

        echo "CloudTrail created successfully."

    else

        echo "Failed to create CloudTrail."
        exit 1

    fi

}

# --------------------------------------------------------
# Start CloudTrail Logging
# --------------------------------------------------------
start_cloudtrail() {

    echo "Starting CloudTrail logging..."

    if aws cloudtrail start-logging \
        --name "$CLOUDTRAIL_NAME"; then

        echo "CloudTrail logging started."

    else

        echo "Failed to start CloudTrail logging."
        exit 1

    fi

}

# --------------------------------------------------------
# Enable S3 Data Events
# --------------------------------------------------------
enable_s3_data_events() {

    echo "Enabling S3 data event logging..."

    aws cloudtrail put-event-selectors \
        --trail-name "$CLOUDTRAIL_NAME" \
        --event-selectors '[
            {
                "ReadWriteType":"All",
                "IncludeManagementEvents":true,
                "DataResources":[
                    {
                        "Type":"AWS::S3::Object",
                        "Values":[
                            "arn:aws:s3:::'"$DOCUMENT_BUCKET"'/"
                        ]
                    }
                ]
            }
        ]'

    if [ $? -eq 0 ]; then
        echo "S3 data event logging enabled."
    else
        echo "Failed to enable S3 data events."
        exit 1
    fi

}

# --------------------------------------------------------
# Save Deployment Information
# --------------------------------------------------------
save_deployment_info() {

    echo "Saving deployment information..."

    cat > "$DEPLOYMENT_INFO" <<EOF
TIMESTAMP=$TIMESTAMP
AWS_REGION=$AWS_REGION
DOCUMENT_BUCKET=$DOCUMENT_BUCKET
LOG_BUCKET=$LOG_BUCKET
IAM_USER=$IAM_USER
IAM_POLICY=$IAM_POLICY
IAM_POLICY_ARN=$IAM_POLICY_ARN
CLOUDTRAIL_NAME=$CLOUDTRAIL_NAME
EOF

    echo "Deployment information saved."

}

# --------------------------------------------------------
# Deployment Summary
# --------------------------------------------------------
deployment_summary() {

    echo ""
    echo "========================================"
    echo " Deployment Completed Successfully"
    echo "========================================"
    echo ""
    echo "AWS Region        : $AWS_REGION"
    echo "Document Bucket   : $DOCUMENT_BUCKET"
    echo "Log Bucket        : $LOG_BUCKET"
    echo "IAM User          : $IAM_USER"
    echo "IAM Policy        : $IAM_POLICY"
    echo "CloudTrail        : $CLOUDTRAIL_NAME"
    echo ""
    echo "Deployment details saved to:"
    echo "$DEPLOYMENT_INFO"
    echo ""

}

check_prerequisites

create_log_bucket

create_document_bucket

block_public_access

enable_bucket_encryption

create_iam_user

generate_iam_policy

create_iam_policy

attach_iam_policy

create_access_key

generate_cloudtrail_policy

apply_cloudtrail_policy

create_cloudtrail

start_cloudtrail

enable_s3_data_events

save_deployment_info

deployment_summary
