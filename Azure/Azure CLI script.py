import os
import json
import subprocess
from datetime import datetime

# Directory to store output files
output_dir = "azure_vapt_outputs"
os.makedirs(output_dir, exist_ok=True)

# Define the checks with vulnerability name, description, and CLI command
azure_checks = [
    {
        "vuln_name": "Overly Permissive Roles",
        "description": "List users or service principals with Owner or Contributor role",
        "command": "az role assignment list --output json"
    },
    {
        "vuln_name": "Inactive Users with Access",
        "description": "List Azure AD users to check for inactive accounts",
        "command": "az ad user list --output json"
    },
    {
        "vuln_name": "Open SSH/RDP to the World",
        "description": "List NSG rules with open ports",
        "command": "az network nsg rule list --nsg-name myNSG --output json"
    },
    {
        "vuln_name": "Exposed Public IPs",
        "description": "Check for VMs with public IPs",
        "command": "az vm list-ip-addresses --output json"
    },
    {
        "vuln_name": "Public Storage Buckets",
        "description": "Check for storage accounts with public blob access",
        "command": "az storage account list --output json"
    },
    {
        "vuln_name": "Unpatched VMs",
        "description": "Check for VM patch status",
        "command": "az vm get-instance-view --name myVM --resource-group myRG --output json"
    },
    {
        "vuln_name": "No Activity Logs Enabled",
        "description": "Check for diagnostic settings on resources",
        "command": "az monitor diagnostic-settings list --resource /subscriptions/xxxx/resourceGroups/myRG/providers/Microsoft.Compute/virtualMachines/myVM --output json"
    },
    {
        "vuln_name": "HTTP Instead of HTTPS",
        "description": "List web apps not enforcing HTTPS",
        "command": "az webapp list --output json"
    }
]

# Function to run CLI command and write output
def run_check(check):
    print(f"Running check: {check['vuln_name']}")
    output_file = os.path.join(output_dir, f"{check['vuln_name'].replace(' ', '_')}.json")

    try:
        result = subprocess.run(check["command"], shell=True, capture_output=True, text=True, timeout=60)
        if result.returncode == 0:
            with open(output_file, "w") as f:
                json.dump(json.loads(result.stdout), f, indent=2)
            print(f"[✔] {check['vuln_name']} check completed.")
        else:
            print(f"[✖] Failed: {check['vuln_name']} - {result.stderr.strip()}")
    except Exception as e:
        print(f"[!] Error running {check['vuln_name']}: {str(e)}")

# Run all checks
for check in azure_checks:
    run_check(check)
