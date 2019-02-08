# Import the VDA common functions
$vdaCommonFunctionsPath = "C:\docutap\util\vda\VdaCommonFunctions.psm1";
if(test-path $vdaCommonFunctionsPath) {
    Import-Module "C:\docutap\util\vda\VdaCommonFunctions.psm1";
} else {
    invoke-bomb "Could not find the citrix common functions!" 151;
}

# Execute the HsCtxCntManage DSC configuration
Start-DSCConfiguration c:\docutap\dsc\windows\DscHsWindowsManage\ -wait -force;
Test-LastDSCSResult;

# Run the generic VDA config
C:\docutap\util\windows\WindowsStandardConfig.ps1

test-bomb;
