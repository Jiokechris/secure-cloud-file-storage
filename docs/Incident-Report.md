# Incident Report

## Incident Title

CloudTrail Creation Failed Due to Missing S3 Bucket Policy

---

## Symptom

During deployment, the CloudTrail creation step failed with the following error:

An error occurred (InsufficientS3BucketPolicyException) when calling the CreateTrail operation:
Incorrect S3 bucket policy is detected for bucket:
ledgerpoint-cloudtrail-logs-xxxxxxxx



The deployment stopped before CloudTrail could be configured.

---

## Investigation Trail

The following troubleshooting steps were performed:

1. Verified that the CloudTrail log bucket had been created successfully.
2. Confirmed that the bucket name referenced by the deployment script matched the bucket created in Amazon S3.
3. Reviewed the deployment script responsible for CloudTrail configuration.
4. Checked whether a bucket policy had been generated and applied.
5. Identified that the deployment created the log bucket but did not apply the required CloudTrail bucket policy before attempting to create the trail.

This ruled out bucket naming issues and AWS CLI authentication problems, narrowing the issue to bucket permissions.

---

## Root Cause

CloudTrail requires permission to write log files into the designated S3 bucket.

Although the bucket existed, the required bucket policy had not been applied before the CloudTrail creation command was executed.

---

## Resolution

The deployment script was updated to:

- Generate the CloudTrail bucket policy automatically.
- Apply the bucket policy to the log bucket before creating CloudTrail.
- Verify the deployment order so CloudTrail was configured only after the bucket policy had been successfully applied.

After these changes, CloudTrail was created successfully.

---

## Verification

Verification was performed by:

- Successfully deploying the infrastructure.
- Confirming CloudTrail creation without errors.
- Verifying that AWS API activity was logged successfully.
- Confirming that subsequent deployments completed successfully.

---

## Design Reflection

This incident reinforced the importance of deployment sequencing in cloud automation.

Although the overall architecture was correct, the deployment order allowed CloudTrail creation to occur before the required bucket permissions were in place. The deployment process was improved by explicitly generating and applying the CloudTrail bucket policy before attempting to create the trail.

If this project were expanded further, additional validation checks would be introduced before each deployment stage to verify prerequisites automatically. This would improve reliability, simplify troubleshooting, and make the deployment process more resilient.

