Import-Module .\CommonFunctions.psm1;

# Test all of the citrix common functions
Describe "Get Instance ID" {
    InModuleScope CommonFunctions {
        It "Calls meta data to get instance id" {
            Mock Invoke-RestMethod {return "instance_name"} -parameterfilter {$Uri -eq "http://169.254.169.254/latest/meta-data/instance-id"} -Verifiable -modulename CommonFunctions;
            Get-MyInstanceId;
            Assert-VerifiableMocks;
        }

        It "Returns the meta data result for the instance name" {
            Mock Invoke-RestMethod {return "instance_name"} -modulename CommonFunctions -Verifiable;
            Get-MyInstanceId | Should Be "instance_name"
        }
    }
}

# Remove-module CitrixCommonFunctions;
Remove-Module CommonFunctions;