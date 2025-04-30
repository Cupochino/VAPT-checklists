@echo off
setlocal enabledelayedexpansion

:: Create timestamped output folder
for /f %%i in ('powershell -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set "timestamp=%%i"
set "output_dir=aws_vapt_results_!timestamp!"
mkdir "!output_dir!"
echo [*] Results will be saved in: !output_dir!
echo.

:: Function to run and save AWS CLI output
:RunCheck
set "name=%~1"
set "cmd=%~2"
set "file=%~3"

<nul set /p="[*] Checking !name!... "
%cmd% > "!output_dir!\!file!" 2>&1
if %errorlevel%==0 (
    echo ✅ Done
) else (
    echo ❌ Error (see !file!)
)
exit /b

:: Begin Checks

call :RunCheck "IAM Users" "aws iam list-users" "iam_list_users.json"
call :RunCheck "IAM Access Keys" "aws iam list-access-keys" "iam_access_keys.json"
call :RunCheck "IAM MFA Devices" "aws iam list-mfa-devices" "iam_mfa_devices.json"
call :RunCheck "IAM Policies (Local)" "aws iam list-policies --scope Local" "iam_policies_local.json"
call :RunCheck "IAM Summary" "aws iam get-account-summary" "iam_account_summary.json"

call :RunCheck "CloudTrail Trails" "aws cloudtrail describe-trails" "cloudtrail_trails.json"
call :RunCheck "CloudTrail Logging Status" "aws cloudtrail get-trail-status --name default" "cloudtrail_status.json"

call :RunCheck "EC2 Instances" "aws ec2 describe-instances" "ec2_instances.json"
call :RunCheck "Security Groups" "aws ec2 describe-security-groups" "ec2_security_groups.json"

call :RunCheck "RDS Instances" "aws rds describe-db-instances" "rds_instances.json"

call :RunCheck "Lambda Functions" "aws lambda list-functions" "lambda_functions.json"

:: Lambda Function Policies
for /f "tokens=*" %%f in ('aws lambda list-functions --query "Functions[*].FunctionName" --output text') do (
    call :RunCheck "Lambda Policy (%%f)" "aws lambda get-policy --function-name %%f" "lambda_policy_%%f.json"
)

call :RunCheck "GuardDuty Detectors" "aws guardduty list-detectors" "guardduty_detectors.json"
call :RunCheck "AWS Config Recorders" "aws configservice describe-configuration-recorders" "config_recorders.json"
call :RunCheck "Security Hub Products" "aws securityhub get-enabled-products-for-import" "securityhub_products.json"

:: S3 Bucket Checks
for /f %%b in ('aws s3api list-buckets --query "Buckets[*].Name" --output text') do (
    call :RunCheck "S3 ACL (%%b)" "aws s3api get-bucket-acl --bucket %%b" "s3_acl_%%b.json"
    call :RunCheck "S3 Policy (%%b)" "aws s3api get-bucket-policy --bucket %%b" "s3_policy_%%b.json"
    call :RunCheck "S3 Access Block (%%b)" "aws s3api get-bucket-public-access-block --bucket %%b" "s3_access_block_%%b.json"
)

echo.
echo ✅ All checks completed.
echo 📁 Results saved in folder: !output_dir!
