## 2.1 Access Mechanism Decision

The system needs to allow external auditors to access shared financial documents without requiring an AWS account or login. At the same time, the documents must remain private, must not be publicly discoverable, and must not remain accessible indefinitely.

Two approaches were evaluated:

| Option | Advantages | Disadvantages |
|---------|------------|---------------|
| Public S3 Bucket | Easy to share files through a direct URL. | Anyone with the URL can access the file indefinitely. Files may be accidentally exposed, making this unsuitable for sensitive financial documents. |
| Amazon S3 Pre-Signed URL | Provides temporary access to a private object without requiring authentication. The URL automatically expires after a configurable period and does not require the bucket to be public. | A new pre-signed URL must be generated if access is required after expiration. |

### Selected Approach

Amazon S3 Pre-Signed URLs were selected because they satisfy all client requirements.

The S3 bucket remains private at all times, preventing public discovery of files. Access is granted only through a cryptographically signed URL that expires automatically after a defined period. This approach minimizes security risk while allowing external auditors to download documents without creating AWS accounts.

## 2.2 Expiry and Revocation Policy

### Default Expiration

Shared links expire after **1 hour (3600 seconds)** by default.

This provides sufficient time for an external auditor to download the document while reducing the risk of long-term exposure.

### Early Revocation

If a document is shared with the wrong recipient, access can be revoked immediately using the CLI revoke command.

The revocation process:

1. Copies the file to a new object with a timestamp-based filename.
2. Deletes the original object from Amazon S3.
3. Invalidates all existing pre-signed URLs because they reference the deleted object.
4. Generates a new share link only for authorized recipients when required.

This approach provides immediate revocation without making the storage bucket public or modifying bucket permissions.

## 2.3 Logging Plan

| Action | Information Logged | Storage Location | Who Can Read the Log |
|---------|--------------------|------------------|----------------------|
| Upload | Timestamp, AWS IAM identity, filename, status | Local audit.log and AWS CloudTrail | System Administrator |
| Download | Timestamp, AWS IAM identity, filename, status | Local audit.log and AWS CloudTrail | System Administrator |
| Share | Timestamp, AWS IAM identity, filename, status | Local audit.log and AWS CloudTrail | System Administrator |
| Delete | Timestamp, AWS IAM identity, filename, status | Local audit.log and AWS CloudTrail | System Administrator |