if(test-path "c:\docutap\util") {
    $windowsModuleRoot = "c:\docutap\util\windows\";
} else {
    write-host -ForegroundColor "Yellow" "Did not find absolute path - using relative paths. This is a little risky";
    $windowsModuleRoot = "..\..\windows-general-config\util";
}

#import module/functions from other files
Import-Module "$windowsModuleRoot\CommonFunctions.psm1";

