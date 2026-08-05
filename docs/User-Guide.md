# LedgerPoint Secure Cloud File Storage

## User Guide

### Overview

LedgerPoint Secure Cloud File Storage provides a simple command-line interface for securely managing confidential financial documents stored in Amazon S3.

The system allows authorized staff to:

- Upload files
- Download files
- View stored files
- Delete files
- Generate secure temporary share links
- Revoke shared links
- View audit logs

All documents remain private by default and are only accessible through time-limited pre-signed URLs.

---

## Before You Begin

Ensure the following are installed and configured:

- AWS CLI
- Bash
- AWS credentials
- Project configuration files

---

## Available Commands

### Upload a File

```bash
./ledgerpoint.sh upload financial-statement.pdf
```

Uploads the specified file to the secure document bucket.

---

### List Stored Files

```bash
./ledgerpoint.sh list
```

Displays all files currently stored in the secure document bucket.

---

### Download a File

```bash
./ledgerpoint.sh download financial-statement.pdf
```

Downloads the specified file into the current directory.

---

### Delete a File

```bash
./ledgerpoint.sh delete financial-statement.pdf
```

Permanently removes the file from secure storage.

---

### Share a File

```bash
./ledgerpoint.sh share financial-statement.pdf
```

Generates a temporary pre-signed URL that can be sent to an external auditor.

The link automatically expires after the configured time period.

---

### Revoke Access

```bash
./ledgerpoint.sh revoke financial-statement.pdf
```

Immediately invalidates previously generated share links by replacing the original object with a new timestamped copy.

If the document needs to be shared again, generate a new pre-signed URL.

---

### View Audit Log

```bash
./ledgerpoint.sh logs
```

Displays a history of all operations including:

- Timestamp
- AWS identity
- Action performed
- Filename
- Status

---

## Security Notes

- The S3 bucket is private.
- Files cannot be discovered through public URLs.
- Share links expire automatically.
- Existing links can be revoked immediately.
- All operations are logged locally.
- AWS CloudTrail records AWS API activity.

---

## Troubleshooting

### File Not Found

Verify the filename and confirm that the file exists locally before uploading.

---

### Access Denied

Check that AWS credentials are configured correctly and that the IAM user has the required permissions.

---

### Share Link Expired

Generate a new pre-signed URL using the share command.

---

## Best Practices

- Delete documents that are no longer required.
- Never distribute expired links.
- Review the audit log regularly.
- Revoke links immediately if they are sent to the wrong recipient.