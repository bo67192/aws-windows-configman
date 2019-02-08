$global:exitMessage = "";
$global:exitCode = 0;
$global:logDir = "";
function write-log([string]$message, [string]$level = "INFO", [string]$category = "general", [string]$item = "NA") {
    $logLine = "$((get-date).ToUniversalTime().toString("yyyy-MM-dd HH:mm:ss")) {`"computername`": `"$($env:computername)`", `"level`": `"$($level)`", `"category`": `"$($category)`", `"item`": `"$($item)`", `"message`": `"$($message)`"}"
  
    # Dump the log message into std out
    write-host $logLine
  
    $logFile = "$($global:logDir)\$((get-date).toString("yyyyMM")).log"
  
    $logLine | out-file -encoding 'UTF8' -append -filepath $logFile
}

# Common variables

$global:instanceid = $null;

function Get-MyInstanceId {
    if($global:instanceid -eq $null) {
        $global:instanceID = Invoke-RestMethod "http://169.254.169.254/latest/meta-data/instance-id"
    }
    write-host $global:instanceid;
    return $global:instanceid;
}

function Test-HostnameMatchesNameTag {
    # Set windows machine name to match name tag
    write-log -message "Testing if machine name matches ec2 Name Tag" -level "INFO" -category "Windows" -item "hostname";
    # the instance ID is grabbed by common config
    $tags = Get-EC2Tag -Filter @{Name = "resource-id"; Value = Get-MyInstanceId}
    $serverName = ($tags | Where-object {$_.Key -eq "Name"}).value
    if ($serverName -ne $env:computername) {
        write-log -message "Computer name does not match host name! Renaming to match, this will trigger a reboot!" -level "WARNING" -category "Windows" -item "hostname";
        rename-computer -newname "$serverName" -force -restart
    } else {
        write-log -message "Computer name matches hostname, skipping config!" -level "INFO" -category "Windows" -item "hostname";
    }
}

# Safely creates a directory if one does not exist
function New-Directory([string]$directory) {
    if (!(test-path $directory)) {
      New-Item -ItemType Directory -path $directory
    } else {
      write-log "$directory already exists";
    }
}

# Update the Logging directory for this script
function set-logdir([string]$logDir) {
    $global:logDir = $logDir;
    write-host "setting $logdir";
    New-Directory $global:logDir;
  }

# Set the default log directory
set-logdir "C:\docutap\ssmlogs";

# Run location: Each customer VDA
# Goal: Configure a customer VDA to accept customer connections, setting file permissions, and connecting to production citrix controller

# This function bombs immediately. Use this when you've encountered an error you can't recover from
# This function sets the exitMessage and exitCode, and then calls test-bomb
# In general an error code of 51 to 99 is an emergency, and a good candidate for bombing now

function invoke-bomb ([string]$message, [int]$code) {
    $global:exitMessage += "\n$message";
    if($code -gt $global:exitCode) {
        $global:exitCode = $code;
    }
    
    test-bomb;
}

# This function allows you to bomb later. Use this when you've encountered a warning, but don't need to exit yet.
# It will set an exit code to be returned from the script
# and append an error message to the exit message
# you MUST call test-bomb to use this exit code
# In general an error code from 1 to 50 is a warning and a good candidate for bombing later

function set-bomb ([string]$message, [int]$code) {
    write-log "Message: $message"
    write-log "Code: $code"
    $global:exitMessage += "\n$message";
    if($code -gt $global:exitCode) {
        $global:exitCode = $code;
    }
}

# This function writes the the error messages stored in $exitMessage and returns the value stored in $exitCode 
# this should be the last function you call in your SSM script

function test-bomb {
    write-log "$(get-date) - EXIT - $global:exitCode - $global:exitMessage"
    exit $global:exitCode
}


# Function to test the most recently applied DSC result
function Test-LastDSCSResult {
    $config_name = (Get-DscConfiguration).ConfigurationName;
    $config_result = get-dscconfigurationstatus;
    if($config_result.status -eq "Success") {
        write-log -message "$($config_name) status $($config_result.Status) and configured $($config_result.NumberOfResources) items" -level "INFO" -category "DSC" -item $config_name;
    } else {
        set-bomb "$($config_name) had status $($config_result.Status)" 153;
    }
}
