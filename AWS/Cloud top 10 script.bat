@echo off
:: Set the AWS region to use for the AWS CLI commands
set AWS_REGION=us-east-1

:: Directory to save the output files
set OUTPUT_DIR=aws_vapt_outputs

:: Create the output directory if it doesn't exist
if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"

:: --- Broken Access Control ---
:: Check for IAM roles with excessive permissions
echo "Checking for IAM roles with excessive permissions (Broken Access Control)" > "%OUTPUT_DIR%\broken_access_control.txt"
aws iam list-roles --region %AWS_REGION% >> "%OUTPUT_DIR%\broken_access_control.txt"

:: --- Sensitive Data Exposure ---
:: Check for unencrypted S3 buckets
echo "Checking for unencrypted S3 buckets (Sensitive Data Exposure)" > "%OUTPUT_DIR%\sensitive_data_exposure.txt"
aws s3api list-buckets --query "Buckets[].Name" --region %AWS_REGION% > temp_buckets.txt
for /f "delims=" %%b in (temp_buckets.txt) do (
    echo Checking encryption for bucket %%b >> "%OUTPUT_DIR%\sensitive_data_exposure.txt"
    aws s3api get-bucket-encryption --bucket %%b --region %AWS_REGION% >> "%OUTPUT_DIR%\sensitive_data_exposure.txt" 2>&1
)
del temp_buckets.txt

:: Check for public S3 buckets
echo "Checking for public S3 buckets (Sensitive Data Exposure)" >> "%OUTPUT_DIR%\sensitive_data_exposure.txt"
for /f "delims=" %%b in (temp_buckets.txt) do (
    aws s3api get-bucket-acl --bucket %%b --region %AWS_REGION% >> "%OUTPUT_DIR%\sensitive_data_exposure.txt" 2>&1
)

:: --- Lack of Security Logging and Monitoring ---
:: Check if CloudTrail is enabled
echo "Checking if CloudTrail is enabled (Logging and Monitoring)" > "%OUTPUT_DIR%\lack_of_security_logging.txt"
aws cloudtrail describe-trails --region %AWS_REGION% >> "%OUTPUT_DIR%\lack_of_security_logging.txt"

:: Check if CloudWatch logs are configured
echo "Checking if CloudWatch logs are configured (Logging and Monitoring)" >> "%OUTPUT_DIR%\lack_of_security_logging.txt"
aws logs describe-log-groups --region %AWS_REGION% >> "%OUTPUT_DIR%\lack_of_security_logging.txt"

:: --- Insecure APIs ---
:: Check if API Gateway has no authentication configured
echo "Checking if API Gateway has no authentication (Insecure APIs)" > "%OUTPUT_DIR%\insecure_apis.txt"
aws apigateway get-rest-apis --region %AWS_REGION% > temp_apis.txt
for /f "delims=" %%a in (temp_apis.txt) do (
    echo Checking authentication for API %%a >> "%OUTPUT_DIR%\insecure_apis.txt"
    aws apigateway get-method --rest-api-id %%a --resource-id %%a --http-method GET --region %AWS_REGION% >> "%OUTPUT_DIR%\insecure_apis.txt" 2>&1
)
del temp_apis.txt

:: --- Overly Permissive SecurityGroups ---
:: Check for EC2 security groups with open ports
echo "Checking for EC2 security groups with open inbound ports (Overly_Permissive_SecurityGroups)" > "%OUTPUT_DIR%\Overly_Permissive_SecurityGroups.txt"
aws ec2 describe-security-groups --query "SecurityGroups[*].{ID:GroupId,Name:GroupName,Inbound:IpPermissions}" --output table --region %AWS_REGION% >> "%OUTPUT_DIR%\Overly_Permissive_SecurityGroups.txt"

:: --- Serverless Security Risks ---
:: Check if Lambda functions have excessive permissions
echo "Checking for excessive permissions in Lambda functions (Serverless Security)" > "%OUTPUT_DIR%\serverless_security_risks.txt"
aws lambda list-functions --region %AWS_REGION% > temp_lambda.txt
for /f "delims=" %%l in (temp_lambda.txt) do (
    echo Checking permissions for Lambda function %%l >> "%OUTPUT_DIR%\serverless_security_risks.txt"
    aws lambda get-policy --function-name %%l --region %AWS_REGION% >> "%OUTPUT_DIR%\serverless_security_risks.txt" 2>&1
)
del temp_lambda.txt

:: --- Container and Orchestration Security ---
:: Check for unscanned Docker images in ECR
echo "Checking for unscanned Docker images in ECR (Container Security)" > "%OUTPUT_DIR%\container_security.txt"
aws ecr describe-repositories --region %AWS_REGION% >> "%OUTPUT_DIR%\container_security.txt"

:: --- Cross-Site Scripting and Injection Attacks ---
:: Check if AWS WAF is configured
echo "Checking if AWS WAF is configured (XSS and Injection Risks)" > "%OUTPUT_DIR%\xss_injection_attacks.txt"
aws wafv2 list-web-acls --region %AWS_REGION% >> "%OUTPUT_DIR%\xss_injection_attacks.txt"

:: --- Insufficient Identity and Credential Management ---
:: Check for unrotated access keys for IAM users
echo "Checking for unrotated access keys (Credential Management)" > "%OUTPUT_DIR%\identity_and_credential_management.txt"
aws iam list-access-keys --user-name <IAM-USER-NAME> --region %AWS_REGION% >> "%OUTPUT_DIR%\identity_and_credential_management.txt"

:: --- Supply Chain Vulnerabilities ---
:: Check for unverified Lambda layers
echo "Checking for unverified Lambda layers (Supply Chain Vulnerabilities)" > "%OUTPUT_DIR%\supply_chain_vulnerabilities.txt"
aws lambda list-layers --region %AWS_REGION% >> "%OUTPUT_DIR%\supply_chain_vulnerabilities.txt"

:: Clean up temporary files
echo "Clean up" >> "%OUTPUT_DIR%\vulnerability_scan_report.txt"
del temp_apis.txt
del temp_buckets.txt
del temp_lambda.txt

:: End of the script
echo "Vulnerability scan completed. Check the output files in the %OUTPUT_DIR% directory."
pause
