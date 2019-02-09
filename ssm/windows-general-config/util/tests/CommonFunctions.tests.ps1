Import-Module .\CommonFunctions.psm1;

# Tests the get instance ID function
Describe "Get Instance ID Tests" {
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

# Tests the get instance ID function
Describe "Bomb Function Tests" {
    InModuleScope CommonFunctions {
        It "Sets the error code passed in" {
            Mock Test-Bomb {}  -Verifiable -modulename CommonFunctions;
            Invoke-Bomb "Something went wrong" 9;
            $global:exitCode | Should Be 9;
            Assert-VerifiableMocks;
        }
    }
}

# Remove-module CitrixCommonFunctions;
Remove-Module CommonFunctions;