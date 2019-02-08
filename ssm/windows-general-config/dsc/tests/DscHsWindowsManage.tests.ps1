Import-Module .\DscHsWindowsManage.psm1;

# Test all of the citrix common functions
Describe "Citrix Management" {
    Context "Correct Cosmos User" {
        It "Returns the correct cosmos user" {
            Get-CosmosUser | Should be "DOCUTAP\sv.cos-deploy.prod";
        }
    }
}
# Remove-module CitrixCommonFunctions;
Remove-Module DscHsWindowsManage;