#!/bin/bash

# ==========================================================
# LedgerPoint Secure Cloud File Storage
# CLI Tool
# ==========================================================

set -e

# Load configuration
source ./config.sh
source ./deployment/deployment-info.env

get_current_user() {

    aws sts get-caller-identity \
        --query Arn \
        --output text

}

# --------------------------------------------------------
# Help Menu
# --------------------------------------------------------
show_help() {

    echo ""
    echo "======================================"
    echo " LedgerPoint CLI"
    echo "======================================"
    echo ""
    echo "Usage:"
    echo "  ./ledgerpoint.sh upload <file>"
    echo "  ./ledgerpoint.sh download <file>"
    echo "  ./ledgerpoint.sh list"
    echo "  ./ledgerpoint.sh delete <file>"
    echo "  ./ledgerpoint.sh share <file>"
    echo "  ./ledgerpoint.sh revoke <file>"
    echo "  ./ledgerpoint.sh logs"
    echo ""

}

# --------------------------------------------------------
# Upload File
# --------------------------------------------------------
upload_file() {

    FILE=$1

    if [ ! -f "$FILE" ]; then
        echo "File not found."
        exit 1
    fi

    echo "Uploading $FILE..."

    if aws s3 cp "$FILE" "s3://$DOCUMENT_BUCKET/"; then

        echo "File uploaded successfully."

        USER_NAME=$(aws sts get-caller-identity \
            --query Arn \
            --output text)

        echo "$(date) | $USER_NAME | Upload | $FILE | SUCCESS" >> "$AUDIT_LOG"

    else

        echo "Upload failed."

        USER_NAME=$(aws sts get-caller-identity \
            --query Arn \
            --output text)

        echo "$(date) | $USER_NAME | Upload | $FILE | FAILED" >> "$AUDIT_LOG"

        exit 1

    fi

}
# --------------------------------------------------------
# List Files
# --------------------------------------------------------
list_files() {

    echo "Listing files..."

    if aws s3 ls "s3://$DOCUMENT_BUCKET"; then

        USER_NAME=$(aws sts get-caller-identity --query Arn --output text)

        echo "$(date) | $USER_NAME | List Files | SUCCESS" >> "$AUDIT_LOG"

    else

        echo "Failed to list files."

        USER_NAME=$(aws sts get-caller-identity --query Arn --output text)

        echo "$(date) | $USER_NAME | List Files | FAILED" >> "$AUDIT_LOG"

        exit 1

    fi

}

# --------------------------------------------------------
# Download File
# --------------------------------------------------------
download_file() {

    FILE=$1

    echo "Downloading $FILE..."

    if aws s3 cp "s3://$DOCUMENT_BUCKET/$FILE" .; then

        echo "File downloaded successfully."

        USER_NAME=$(aws sts get-caller-identity --query Arn --output text)

        echo "$(date) | $USER_NAME | Download | $FILE | SUCCESS" >> "$AUDIT_LOG"

    else

        echo "Download failed."

        USER_NAME=$(aws sts get-caller-identity --query Arn --output text)

        echo "$(date) | $USER_NAME | Download | $FILE | FAILED" >> "$AUDIT_LOG"

        exit 1

    fi

}

# --------------------------------------------------------
# Delete File
# --------------------------------------------------------
delete_file() {

    FILE=$1

    echo "Deleting $FILE..."

    if aws s3 rm "s3://$DOCUMENT_BUCKET/$FILE"; then

        echo "File deleted successfully."

        USER_NAME=$(aws sts get-caller-identity --query Arn --output text)

        echo "$(date) | $USER_NAME | Delete | $FILE | SUCCESS" >> "$AUDIT_LOG"

    else

        echo "Delete failed."

        USER_NAME=$(aws sts get-caller-identity --query Arn --output text)

        echo "$(date) | $USER_NAME | Delete | $FILE | FAILED" >> "$AUDIT_LOG"

        exit 1

    fi

}

# --------------------------------------------------------
# Generate Share Link
# --------------------------------------------------------
share_file() {

    FILE=$1

    echo "Generating secure share link..."

    LINK=$(aws s3 presign "s3://$DOCUMENT_BUCKET/$FILE" \
        --expires-in "$URL_EXPIRY" \
        --region "$AWS_REGION")

    if [ $? -eq 0 ]; then

        echo ""
        echo "Share Link"
        echo "----------------------------------------"
        echo "$LINK"
        echo "----------------------------------------"
        echo "This link expires in $URL_EXPIRY seconds."
        echo ""

        USER_NAME=$(aws sts get-caller-identity --query Arn --output text)

        echo "$(date) | $USER_NAME | Share | $FILE | SUCCESS" >> "$AUDIT_LOG"

    else

        echo "Failed to generate share link."

        USER_NAME=$(aws sts get-caller-identity --query Arn --output text)

        echo "$(date) | $USER_NAME | Share | $FILE | FAILED" >> "$AUDIT_LOG"

        exit 1

    fi

}

# --------------------------------------------------------
# Revoke Shared File Access
# --------------------------------------------------------
revoke_file() {

    FILE=$1

    if [ -z "$FILE" ]; then
        echo "Usage: ./ledgerpoint.sh revoke <file>"
        exit 1
    fi

    TIMESTAMP=$(date +%Y%m%d%H%M%S)

    NEW_FILE="${TIMESTAMP}-${FILE}"

    echo "Revoking access to $FILE..."

    # Copy the object to a new name
    if aws s3 cp \
        "s3://$DOCUMENT_BUCKET/$FILE" \
        "s3://$DOCUMENT_BUCKET/$NEW_FILE"; then

        echo "File copied successfully."

    else

        echo "Failed to copy file."
        exit 1

    fi

    # Delete the original object
    if aws s3 rm "s3://$DOCUMENT_BUCKET/$FILE"; then

        echo "Original file removed."

    else

        echo "Failed to delete original file."
        exit 1

    fi

    USER_NAME=$(aws sts get-caller-identity \
        --query Arn \
        --output text)

    echo "$(date) | $USER_NAME | Revoke | $FILE | SUCCESS" >> "$AUDIT_LOG"

    echo ""
    echo "Access revoked successfully."
    echo ""
    echo "New file name:"
    echo "$NEW_FILE"
    echo ""
    echo "Generate a new share link if required."

}

# --------------------------------------------------------
# View Audit Logs
# --------------------------------------------------------
view_logs() {

    echo "Audit Log"
    echo "----------------------------------------"

    if [ -f "$AUDIT_LOG" ]; then

        cat "$AUDIT_LOG"

    else

        echo "No audit log found."

    fi

}

# --------------------------------------------------------
# Command Dispatcher
# --------------------------------------------------------

USER_NAME=$(get_current_user)

case "$1" in

    upload)
        upload_file "$2"
        ;;

    download)
        download_file "$2"
        ;;

    list)
        list_files
        ;;

    delete)
        delete_file "$2"
        ;;

    share)
        share_file "$2"
        ;;

    revoke)
        revoke_file "$2"
        ;;

    logs)
        view_logs
        ;;

    help)
        show_help
        ;;

    "")
        show_help
        ;;

    *)
        echo "Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;

esac