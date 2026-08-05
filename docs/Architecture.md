## Architecture Diagram


                        LedgerPoint Secure Cloud File Storage

 ![diagram](screenshots/11-architectural-diagram.png)

## Solution Architecture

The solution uses Amazon S3 as the secure storage service for confidential financial documents. The document bucket remains private at all times and cannot be accessed directly from the internet.

Internal staff interact with the system through a Bash-based command-line interface that communicates with AWS using the AWS CLI. Authentication is performed using a dedicated IAM user with a least-privilege policy that permits only the required S3 operations.

When a document needs to be shared with an external auditor, the system generates a temporary Amazon S3 pre-signed URL. The auditor does not require an AWS account and can access only the specific document until the URL expires.

To support auditing and compliance, AWS CloudTrail records API activity while the application also maintains a local audit log containing the timestamp, AWS identity, action performed, filename, and operation status.

If a document is shared with the wrong recipient, the revoke function immediately invalidates existing pre-signed URLs by copying the object to a new timestamped filename and deleting the original object. Since pre-signed URLs are tied to the original object, they become unusable immediately after revocation.


## Features

- Private Amazon S3 storage bucket
- Temporary pre-signed URL sharing
- File upload
- File download
- File listing
- File deletion
- Share link revocation
- Local audit logging
- AWS CloudTrail integration
- Automated deployment
- Automated cleanup
- Least-privilege IAM policy

