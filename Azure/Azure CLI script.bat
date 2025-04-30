@echo off
setlocal enabledelayedexpansion

REM Create output directory
set OUTPUT_DIR=azure_vapt_outputs
if not exist %OUTPUT_DIR% mkdir %OUTPUT_DIR%

REM Define check list
set COUNT=0

call :RunCheck "Overly Permissive Roles" "az role assignment list --output json"
call :RunCheck "Inactive Users with Access" "az ad user list --output json"
call :RunCheck "Open SSH or RDP to the World" "az network nsg rule list --nsg-name myNSG --output json"
call :RunCheck "Exposed Public IPs" "az vm list-ip-addresses --output json"
call :RunCheck "Public Storage Buckets" "az storage account list --output json"
call :RunCheck "Unpatched VMs" "az vm get-instance-view --name myVM --resource-group myRG --output json"
call :RunCheck "No Activity Logs Enabled" "az monitor diagnostic-settings list --resource /subscriptions/xxxx/resourceGroups/myRG/providers/Microsoft.Compute/virtualMachines/myVM --output json"
call :RunCheck "HTTP Instead of HTTPS" "az webapp list --output json"

echo All checks completed.
goto :eof

:RunCheck
set "VULN_NAME=%~1"
set "COMMAND=%~2"
set /a COUNT+=1

set "FILENAME=%OUTPUT_DIR%\%VULN_NAME: =_%!.json"

echo [!COUNT!] Running: %VULN_NAME%
%COMMAND% > "!FILENAME!" 2>nul

if exist "!FILENAME!" (
    echo [✔] Completed: %VULN_NAME%
) else (
    echo [✖] Failed: %VULN_NAME%
)
echo.
goto :eof
