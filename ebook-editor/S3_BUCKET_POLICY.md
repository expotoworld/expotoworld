# S3 Bucket Policy for CloudFront Origin Access Control

## Overview

This document explains the S3 bucket policy required for the ebook editor to work with CloudFront Origin Access Control (OAC).

## Current Bucket Policy

**Bucket**: `expotoworld-ebook-website`  
**CloudFront Distribution**: `E25UL5QH3I1VIU`  
**OAC ID**: `E305BF2ASOHOAY`  
**Domain**: `huashangdao.expotoworld.com`

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
      "Resource": "arn:aws:s3:::expotoworld-ebook-website/*",
      "Condition": {
        "StringEquals": {
          "AWS:SourceArn": "arn:aws:cloudfront::834076182408:distribution/E25UL5QH3I1VIU"
        }
      }
    }
  ]
}
```

## How It Works

1. **Principal**: Grants access to the CloudFront service (`cloudfront.amazonaws.com`)
2. **Action**: Allows `s3:GetObject` to read files from the bucket
3. **Resource**: Applies to all objects in the bucket (`expotoworld-ebook-website/*`)
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
cat > /tmp/s3-ebook-bucket-policy.json << 'EOF'
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
      "Resource": "arn:aws:s3:::expotoworld-ebook-website/*",
      "Condition": {
        "StringEquals": {
          "AWS:SourceArn": "arn:aws:cloudfront::834076182408:distribution/E25UL5QH3I1VIU"
        }
      }
    }
  ]
}
EOF

# Apply the policy
aws s3api put-bucket-policy \
  --bucket expotoworld-ebook-website \
  --policy file:///tmp/s3-ebook-bucket-policy.json \
  --region eu-central-1
```

### Using AWS Console

1. Go to S3 Console
2. Select bucket `expotoworld-ebook-website`
3. Go to "Permissions" tab
4. Click "Bucket Policy"
5. Paste the JSON policy above
6. Click "Save changes"

## Verification

### Check Bucket Policy

```bash
aws s3api get-bucket-policy \
  --bucket expotoworld-ebook-website \
  --region eu-central-1 \
  --query 'Policy' \
  --output text | jq .
```

### Test Ebook Editor Access

```bash
# Should return HTTP 200
curl -I https://huashangdao.expotoworld.com

# Should return HTML content
curl -s https://huashangdao.expotoworld.com | head -20
```

## Troubleshooting

### "Access Denied" Error

**Symptoms**: XML error message with `<Code>AccessDenied</Code>`

**Causes**:
1. Bucket policy is missing
2. Bucket policy has incorrect CloudFront distribution ARN
3. CloudFront OAC is not configured on the distribution

**Solution**:
1. Verify bucket policy exists: `aws s3api get-bucket-policy --bucket expotoworld-ebook-website`
2. Check CloudFront distribution ARN matches the policy
3. Verify OAC ID in CloudFront distribution settings

### CloudFront Cache Issues

If changes don't appear immediately, invalidate the CloudFront cache:

```bash
aws cloudfront create-invalidation \
  --distribution-id E25UL5QH3I1VIU \
  --paths "/*" \
  --region us-east-1
```

## Comparison with Admin Panel

Both the admin panel and ebook editor use the same security pattern:

| Component | Admin Panel | Ebook Editor |
|-----------|-------------|--------------|
| S3 Bucket | expotoworld-admin-website | expotoworld-ebook-website |
| CloudFront Distribution | E2JL3VLX19R2ZH | E25UL5QH3I1VIU |
| OAC ID | E375DB02YFHQUF | E305BF2ASOHOAY |
| Domain | admin.expotoworld.com | huashangdao.expotoworld.com |
| Bucket Policy | Same pattern | Same pattern |

## Related Resources

- [CloudFront Origin Access Control Documentation](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/private-content-restricting-access-to-s3.html)
- [S3 Bucket Policies](https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucket-policies.html)
- Ebook Editor Architecture: `ebook-editor/ARCHITECTURE.md`
- Admin Panel S3 Policy: `admin-panel/S3_BUCKET_POLICY.md`

## Change Log

- **2025-10-15**: Initial bucket policy created for `expotoworld-ebook-website`
  - Applied CloudFront OAC policy during migration
  - Verified ebook editor access
  - Documented security configuration

