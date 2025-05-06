import os
import subprocess
import time
from datetime import datetime

# Function to run AWS CLI command and save output to a file
def run_command(name, command, output_file):
    print(f"[*] Checking {name}... ", end="")
    try:
        result = subprocess.check_output(command, shell=True, stderr=subprocess.STDOUT)
        with open(output_file, 'wb') as f:
            f.write(result)
        print("✅ Done")
    except subprocess.CalledProcessError as e:
        with open(output_file, 'wb') as f:
            f.write(e.output)
        print(f"❌ Error (see {output_file})")

# Create output directory with timestamp
timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
output_dir = f"aws_vapt_results_{timestamp}"
os.makedirs(output_dir)
print(f"[*] Results will be saved in: {output_dir}\n")

# List of checks to perform: (vulnerability name, AWS CLI command, output filename)
checks = [
    ("IAM Users", "aws iam list-users", "iam_list_users.json"),
    ("IAM Access Keys", "aws iam list-access-keys", "iam_access_keys.json"),
    ("IAM MFA Devices", "aws iam list-mfa-devices", "iam_mfa_devices.json"),
    ("IAM Policies (Local)", "aws iam list-policies --scope Local", "iam_policies_local.json"),
    ("IAM Summary", "aws iam get-account-summary", "iam_account_summary.json"),
    
    ("CloudTrail Trails", "aws cloudtrail describe-trails", "cloudtrail_trails.json"),
    ("CloudTrail Logging Status", "aws cloudtrail get-trail-status --name default", "cloudtrail_status.json"),
    
    ("EC2 Instances", "aws ec2 describe-instances", "ec2_instances.json"),
    ("Security Groups", "aws ec2 describe-security-groups --group-ids --output table", "ec2_security_groups.json"),
    
    ("RDS Instances", "aws rds describe-db-instances", "rds_instances.json"),
    
    ("Lambda Functions", "aws lambda list-functions", "lambda_functions.json"),
    
    ("GuardDuty Detectors", "aws guardduty list-detectors", "guardduty_detectors.json"),
    ("AWS Config Recorders", "aws configservice describe-configuration-recorders", "config_recorders.json"),
    ("Security Hub Products", "aws securityhub get-enabled-products-for-import", "securityhub_products.json")
]

# Run the basic checks
for name, command, file in checks:
    run_command(name, command, os.path.join(output_dir, file))

# S3 Bucket Checks (loop over all S3 buckets)
buckets_command = "aws s3api list-buckets --query 'Buckets[*].Name' --output text"
try:
    buckets = subprocess.check_output(buckets_command, shell=True, stderr=subprocess.STDOUT).decode().split()
    for bucket in buckets:
        print(f"\n[*] Checking S3 bucket: {bucket}...")
        run_command(f"S3 ACL ({bucket})", f"aws s3api get-bucket-acl --bucket {bucket}", os.path.join(output_dir, f"s3_acl_{bucket}.json"))
        run_command(f"S3 Policy ({bucket})", f"aws s3api get-bucket-policy --bucket {bucket}", os.path.join(output_dir, f"s3_policy_{bucket}.json"))
        run_command(f"S3 Access Block ({bucket})", f"aws s3api get-bucket-public-access-block --bucket {bucket}", os.path.join(output_dir, f"s3_access_block_{bucket}.json"))
except subprocess.CalledProcessError as e:
    print(f"❌ Error retrieving S3 buckets: {e.output.decode()}")

print(f"\n✅ All checks completed.")
print(f"📁 Results saved in: {output_dir}")
