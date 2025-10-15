# S3 Bucket Policy for CloudFront Origin Access Control

## Overview

This document explains the S3 bucket policy required for the admin panel to work with CloudFront Origin Access Control (OAC).

## Problem

After migrating from `expotoworld-editor-site` to `expotoworld-admin-website`, the admin panel showed an "Access Denied" error because the new bucket was created without a bucket policy.

## Solution

The S3 bucket requires a policy that grants CloudFront permission to read objects using Origin Access Control (OAC).

## Current Bucket Policy

**Bucket**: `expotoworld-admin-website`  
**CloudFront Distribution**: `E2JL3VLX19R2ZH`  
**OAC ID**: `E375DB02YFHQUF`  
**OAC Name**: `expotoworld-admin-oac`

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowCloudFrontServicePrincipal",
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudfront.amazonaws.com"
      },
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::expotoworld-admin-website/*",
      "Condition": {
        "StringEquals": {
          "AWS:SourceArn": "arn:aws:cloudfront::834076182408:distribution/E2JL3VLX19R2ZH"
        }
      }
    }
  ]
}
```

## How It Works

1. **Principal**: Grants access to the CloudFront service (`cloudfront.amazonaws.com`)
2. **Action**: Allows `s3:GetObject` to read files from the bucket
3. **Resource**: Applies to all objects in the bucket (`expotoworld-admin-website/*`)
4. **Condition**: Restricts access to only the specific CloudFront distribution using its ARN

## Security Benefits

- **No Public Access**: The bucket is NOT publicly accessible
- **CloudFront Only**: Only the specific CloudFront distribution can access the bucket
- **OAC Authentication**: Uses AWS Signature Version 4 for secure authentication
- **Least Privilege**: Only grants read access, no write or delete permissions

## Applying the Policy

### Using AWS CLI

```bash
# Create policy file
cat > /tmp/s3-bucket-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowCloudFrontServicePrincipal",
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudfront.amazonaws.com"
      },
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::expotoworld-admin-website/*",
      "Condition": {
        "StringEquals": {
          "AWS:SourceArn": "arn:aws:cloudfront::834076182408:distribution/E2JL3VLX19R2ZH"
        }
      }
    }
  ]
}
EOF

# Apply the policy
aws s3api put-bucket-policy \
  --bucket expotoworld-admin-website \
  --policy file:///tmp/s3-bucket-policy.json \
  --region eu-central-1
```

### Using AWS Console

1. Go to S3 Console
2. Select bucket `expotoworld-admin-website`
3. Go to "Permissions" tab
4. Click "Bucket Policy"
5. Paste the JSON policy above
6. Click "Save changes"

## Verification

### Check Bucket Policy

```bash
aws s3api get-bucket-policy \
  --bucket expotoworld-admin-website \
  --region eu-central-1 \
  --query 'Policy' \
  --output text | jq .
```

### Test Admin Panel Access

```bash
# Should return HTTP 200
curl -I https://admin.expotoworld.com

# Should return HTML content
curl -s https://admin.expotoworld.com | head -20
```

## Troubleshooting

### "Access Denied" Error

**Symptoms**: XML error message with `<Code>AccessDenied</Code>`

**Causes**:
1. Bucket policy is missing
2. Bucket policy has incorrect CloudFront distribution ARN
3. CloudFront OAC is not configured on the distribution

**Solution**:
1. Verify bucket policy exists: `aws s3api get-bucket-policy --bucket expotoworld-admin-website`
2. Check CloudFront distribution ARN matches the policy
3. Verify OAC ID in CloudFront distribution settings

### CloudFront Cache Issues

If changes don't appear immediately, invalidate the CloudFront cache:

```bash
aws cloudfront create-invalidation \
  --distribution-id E2JL3VLX19R2ZH \
  --paths "/*" \
  --region us-east-1
```

## For Future Bucket Migrations

When creating a new S3 bucket for CloudFront:

1. **Create the bucket** in the desired region
2. **Apply the bucket policy** immediately (update the bucket name and distribution ARN)
3. **Configure CloudFront** to use the new bucket as origin
4. **Verify OAC** is configured on the CloudFront distribution
5. **Test access** before deleting the old bucket

## Related Resources

- [CloudFront Origin Access Control Documentation](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/private-content-restricting-access-to-s3.html)
- [S3 Bucket Policies](https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucket-policies.html)
- Admin Panel Architecture: `admin-panel/ARCHITECTURE.md`

## Change Log

- **2025-10-15**: Initial bucket policy created for `expotoworld-admin-website`
  - Fixed "Access Denied" error after S3 bucket migration
  - Applied CloudFront OAC policy
  - Verified admin panel access restored

