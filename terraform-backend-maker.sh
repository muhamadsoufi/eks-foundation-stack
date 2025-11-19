#!/usr/bin/env bash
set -e

##########################################
# Variables (EDIT THESE)
##########################################

AWS_REGION="us-east-1"
BUCKET_NAME="terraform-on-aws-eks-xxxxxxxxxxx123123123"
DYNAMODB_TABLE="terraform-on-aws-eks-xxxxxxxxxxx123123123"
TF_FILE="./Deploy-EKS-TF/c1-01-provider.tf"
TF_FILE2="./Deploy-EKS-TF/c6-0-0-terraform-remote-state-needed-for-data.tf"
TF_KEY="dev/${BUCKET_NAME}/terraform.tfstate"

##########################################
# Detect if bucket exists & its region
##########################################

echo "==> Checking S3 Bucket: $BUCKET_NAME"

BUCKET_REGION=$(aws s3api get-bucket-location \
  --bucket "$BUCKET_NAME" \
  --query LocationConstraint \
  --output text 2>/dev/null || echo "NOT_FOUND")

# AWS returns "None" for us-east-1 buckets
if [ "$BUCKET_REGION" = "None" ]; then
  BUCKET_REGION="us-east-1"
fi

##########################################
# Create S3 Bucket
##########################################

if [ "$BUCKET_REGION" = "NOT_FOUND" ]; then
  echo "Bucket does NOT exist — creating in $AWS_REGION..."

  if [ "$AWS_REGION" = "us-east-1" ]; then
    # us-east-1 does NOT accept LocationConstraint
    aws s3api create-bucket \
      --bucket "$BUCKET_NAME" \
      --region "$AWS_REGION"
  else
    aws s3api create-bucket \
      --bucket "$BUCKET_NAME" \
      --region "$AWS_REGION" \
      --create-bucket-configuration LocationConstraint="$AWS_REGION"
  fi

else
  echo "Bucket already exists in region: $BUCKET_REGION"

  if [ "$BUCKET_REGION" != "$AWS_REGION" ]; then
    echo "❌ ERROR: Bucket exists but NOT in $AWS_REGION"
    exit 1
  fi
fi

echo "Enabling versioning..."
aws s3api put-bucket-versioning \
  --bucket "$BUCKET_NAME" \
  --versioning-configuration Status=Enabled

echo "✓ S3 bucket ready"

##########################################
# Create DynamoDB table
##########################################

echo "==> Checking DynamoDB Table: $DYNAMODB_TABLE"

TABLE_EXISTS=$(aws dynamodb describe-table \
  --table-name "$DYNAMODB_TABLE" \
  --region "$AWS_REGION" \
  >/dev/null 2>&1 && echo "YES" || echo "NO")

if [ "$TABLE_EXISTS" = "NO" ]; then
  echo "Creating DynamoDB table..."
  aws dynamodb create-table \
    --table-name "$DYNAMODB_TABLE" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region "$AWS_REGION"
else
  echo "DynamoDB table already exists."
fi

echo "✓ DynamoDB lock table ready"

##########################################
# Patch Terraform Backend Block
##########################################

echo "==> Updating backend configuration in: $TF_FILE"

ESCAPED_BUCKET=$(printf '%s\n' "$BUCKET_NAME" | sed 's/[\/&]/\\&/g')
ESCAPED_TABLE=$(printf '%s\n' "$DYNAMODB_TABLE" | sed 's/[\/&]/\\&/g')
ESCAPED_KEY=$(printf '%s\n' "$TF_KEY" | sed 's/[\/&]/\\&/g')
ESCAPED_REGION=$(printf '%s\n' "$AWS_REGION" | sed 's/[\/&]/\\&/g')

sed -i.bak \
  -e "s/^[[:space:]]*bucket[[:space:]]*=.*/    bucket = \"${ESCAPED_BUCKET}\"/" \
  -e "s/^[[:space:]]*key[[:space:]]*=.*/    key    = \"${ESCAPED_KEY}\"/" \
  -e "s/^[[:space:]]*region[[:space:]]*=.*/    region = \"${AWS_REGION}\"/" \
  -e "s/^[[:space:]]*dynamodb_table[[:space:]]*=.*/    dynamodb_table = \"${ESCAPED_TABLE}\"/" \
  "$TF_FILE"

echo "✓ Backend block updated"
echo "Backup saved to: ${TF_FILE}.bak"

##########################################

echo "==> Updating backend configuration in: $TF_FILE2"

ESCAPED_BUCKET=$(printf '%s\n' "$BUCKET_NAME" | sed 's/[\/&]/\\&/g')
ESCAPED_TABLE=$(printf '%s\n' "$DYNAMODB_TABLE" | sed 's/[\/&]/\\&/g')
ESCAPED_KEY=$(printf '%s\n' "$TF_KEY" | sed 's/[\/&]/\\&/g')
ESCAPED_REGION=$(printf '%s\n' "$AWS_REGION" | sed 's/[\/&]/\\&/g')

sed -i.bak \
  -e "s/^[[:space:]]*bucket[[:space:]]*=.*/    bucket = \"${ESCAPED_BUCKET}\"/" \
  -e "s/^[[:space:]]*key[[:space:]]*=.*/    key    = \"${ESCAPED_KEY}\"/" \
  -e "s/^[[:space:]]*region[[:space:]]*=.*/    region = \"${AWS_REGION}\"/" \
  -e "s/^[[:space:]]*dynamodb_table[[:space:]]*=.*/    dynamodb_table = \"${ESCAPED_TABLE}\"/" \
  "$TF_FILE2"

echo "✓ Backend block updated"
echo "Backup saved to: ${TF_FILE2}.bak"

##########################################
# Finished
##########################################

echo ""
echo "🎉 Terraform backend setup completed successfully!"
echo ""
echo "Next steps:"
echo "  1. cd Deploy-EKS-TF"
echo "  2. terraform init -reconfigure"
echo ""
