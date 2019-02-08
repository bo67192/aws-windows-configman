Param([string]$instanceName, [string]$logtype="man")
#set-awscredentials -profilename ADFS-PHI;
set-awscredentials -profilename PHI;
set-defaultawsregion us-east-1;

if(!($instanceName)) {
    write-host "Instance name is required";
    exit(9);
}

if($instanceName -eq "web-prod") {
    write-host -foregroundcolor "Yellow" "WARNING: This script will pull logs from a single arbitrary web node";
    $instanceName = "bi-adm-w-sisense-inst-prod-sisense-web-prod";
} elseif($instanceName -eq "web-staging") {
    write-host -foregroundcolor "Yellow" "WARNING: This script will pull logs from a single arbitrary web node";
    $instanceName = "bi-adm-w-sisense-inst-staging-sisense-web-staging"
}

write-host "Getting logs for $instanceName";

if($instanceName -like "*50*" -or $instanceName -like "*staging*") {
    $environment = "staging";
} else {
    $environment = "prod";
}

switch($logtype) {
    "man" {
        $log_group_name = "ssm/sisense/$environment";
    }
    "build" {
        $log_group_name = "/bi/si/$environment/buildlogs";
    }
    "export" {
        $log_group_name = "/bi/si/$environment/data_export_logs";
    }
    "import" {
        $log_group_name = "/bi/si/$environment/data_import_logs";
    }
}

$instance_id = (get-ec2instance -filter @(@{Name="tag:Name";Value="$instanceName"};@{Name="instance-state-name";Value="running"})).Instances.InstanceId;

if($instance_id.gettype() -notlike "string") {
    $instance_id = $instance_id[2];
}

write-host "Instanceid: $instance_id - loggroup: $log_group_name";

$log_events = Get-CWLLogEvent -LogGroupName $log_group_name -LogStreamName $instance_id -StartTime (get-date).addminutes(-30);
#$log_events = Get-CWLLogEvent -LogGroupName $log_group_name -LogStreamName $instance_id -StartTime (get-date).addhours(-12);

while($true){
    $next_forward_token = $log_events.NextForwardToken;
    $log_events.events | %{write-host "$($_.Timestamp) - $($_.message)"}
    start-sleep -s 5;
    $log_events = Get-CWLLogEvent -LogGroupName $log_group_name -LogStreamName $instance_id -NextToken $next_forward_token;
}