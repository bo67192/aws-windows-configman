set-awscredentials -profilename ADFS-PHI;
set-defaultawsregion us-east-1;

$script:widget_width = 6;
$script:widget_height = 4;
$script:widgets_per_row = 3;
<#
$dashboard_body = @{"widgets" = @(@{
                                    "type"="metric";
                                    "x"= 0;
                                    "y"= 0;
                                    "width"= 12;
                                    "height"= 6;
                                    "properties"= @{
                                        "metrics" = @(
                                            @(
                                                "AWS/EC2",
                                                "CPUUtilization",
                                                "InstanceId",
                                                "i-0f38eb2a6a2cae037"
                                            )
                                        );
                                        "period"=300;
                                        "stat"="Average";
                                        "region"="us-east-1";
                                        "title"= "BuildNodeCPU"
                                    }
                                })}
#>

$dashboard_body = @{"widgets" = @()};
$script:x_pos = 8;
$script:y_pos = 0;
function Increment-Coordinates {
    write-host "In increment coords: ypos: $($script:y_pos)";
    if($script:x_pos -eq $script:widget_width * $script:widgets_per_row) {
        $script:x_pos = 0;
        # If we are back at the beginning of a column, move y pos down
        $script:y_pos += $script:widget_height;        
    } else {
        $script:x_pos += $script:widget_width;
    }
    write-host "After increment coords: ypos: $($script:y_pos)";
    # if($script:x_pos -eq $script:widget_width*2) {
    #     $script:x_pos = 0;
    #     # If we are back at the beginning of a column, move y pos down
    #     $script:y_pos += $script:widget_height;
    # } elseif($script:x_pos -eq 0) {
    #     $script:x_pos = $script:widget_width;
    # } elseif($script:x_pos -eq $script:widget_width`) {
    #     $script:x_pos = $script:widget_width;
    # }
}

function Assemble-Widget($namespace, $metric, $dimension, $resources, $stat, $horizontal, $math, $detailVisible) {
    write-host "In assemble widget coords: ypos: $($script:y_pos)";
    write-host "Assembling widget for $namespace - $metric - $dimension - $stat";
    $resource_metrics = @();
    foreach($resource in $resources) {
        if(!$detailVisible) {
            $resource_metrics += ,@($namespace, $metric, $dimension, $resource, @{"visible" = $false})
        } else {
            $resource_metrics += ,@($namespace, $metric, $dimension, $resource, @{"visible" = $true})
        }
    }
    if($math) {
        foreach ($expression in $math) {
            $resource_metrics += ,@($expression)
        }
    }
    $widget = @{
        "type"="metric";
        "x"= $script:x_pos;
        "y"= $script:y_pos;
        "width"= $script:widget_width;
        "height"= $script:widget_height;
        "properties"= @{
            "metrics" = $resource_metrics;
            "period"=300;
            "stat"=$stat;
            "region"="us-east-1";
            "title"= "$metric"
        }
    }

    if($horizontal) {
        write-host "Inserting horizontal annotation";
        $widget["properties"]["annotations"] = @{"horizontal" = $horizontal};
    }

    write-host "Before increment coords: ypos: $($script:y_pos)";
    Increment-Coordinates;
    write-host "After increment coords call: ypos: $($script:y_pos)";
    return $widget;
}

function Insert-Header($name) {
    write-host "Before inserting header coords: ypos: $($script:y_pos)";
    $script:y_pos += 2;    
    $widget = @{
        "type"="text";
        "x"= 0;
        "y"= $script:y_pos;
        "width"= 24;
        "height"= 2;
        "properties"= @{
            "markdown"= "# $name"
        }
    }
    $script:y_pos += 2;
    $script:x_pos = 0;
    write-host "After inserting header coords: ypos: $($script:y_pos)";
    return $widget;
}

function Get-CloudwatchDimension($type, $resources) {
    switch($type) {
        "AWS::EC2::Instance" {
            return $resources.PhysicalResourceId;
        }
        "AWS::AutoScaling::AutoScalingGroup" {
            return $resources.PhysicalResourceId;
        }
        "AWS::ElasticLoadBalancingV2::LoadBalancer" {
            $result = $resources.PhysicalResourceId -match "arn:aws:elasticloadbalancing:us-east-1:452452845121:loadbalancer/(?<elb_dimension>.*)"
            return $matches['elb_dimension'];
        }
    }
}

function Build-PoolWidgets($instances) {
    foreach ($instance_metric in $instance_metrics) {
        $instanceIds = $instances.instanceid;
        foreach($widget in $instance_metric['widgets']) {
            $namespace = $widget['namespace'];
            write-host "Building widgets for $namespace namespace";
            foreach($metric in $widget['metrics']) {
                write-host "Building widgets for $metric";
                $dashboard_body["widgets"] += Assemble-Widget $namespace $metric $instance_metric['dimension'] $instanceIds $instance_metric['stat'] $widget['horizontal'] $widget['math'] $widget['detailVisible'];
            }
        }
        foreach ($related_metric in $instance_metric['related_metrics']) {
            write-host "Building related metric $($related_metric['resource_type'])"
            switch($related_metric['resource_type']) {
                "volume" {
                    $physical_ids = (Get-EC2Volume -filter @(@{Name="attachment.instance-id";Values=$instanceIds})).VolumeId;
                    foreach($widget in $related_metric['widgets']) {
                        $namespace = $widget['namespace'];
                        foreach($metric in $widget['metrics']) {
                            $dashboard_body["widgets"] += Assemble-Widget $namespace $metric $related_metric['dimension'] $physical_ids $instance_metric['stat'];
                        }
                    }
                }
            }
        }
    }
}

$instance_metrics = @(
    @{"dimension" = "InstanceId";
      "stat" = "Average";
      "widgets" = @(
                    @{"namespace"="AWS/EC2";"horizontal" = $null; "math" = $null; "detailVisible" = $true; "metrics"=@("CPUUtilization")},
                    @{"namespace"="Windows/Default";
                      "horizontal" = @(@{"label" = "Max Users";"value" = 27});
                      "metrics"=@("ActiveSessions");
                      "detailVisible" = $false;
                      "math" = @(@{
                                    "expression" = "MAX(METRICS())";
                                    "label" = "MaxSessions"
                                  }, 
                                  @{
                                      "expression" = "MIN(METRICS())"; 
                                      "label" = "MinSessions"
                                    },
                                    @{
                                        "expression" = "AVG(METRICS())";
                                        "label" = "AvgSessions"
                                    })},
                    @{"namespace"="Windows/Default";"horizontal" = $null; "math" = $null; "detailVisible" = $true; "metrics" = @("AvailableMemory", "C_Drive_Free_Percent", "D_Drive_Free_Percent")}
                    );
    #   "related_metrics"= @(
    #                             @{
    #                                 "resource_type" = "volume";
    #                                 "dimension"= "VolumeId";
    #                                 "stat" = "Average";
    #                                 "widgets" = @(
    #                                     @{"namespace" = "AWS/EBS";"metrics"=@("VolumeQueueLength", "VolumeIdleTime", "VolumeReadOps", "VolumeWriteOps")}
    #                                 )
    #                             }
    #                         )
    }
)

$tags = @(@{Key="Name";Value="CMB0*"});

$instances = $tags | % {(get-ec2instance -filter @(@{Name="tag:$($_.Key)";Value=$_.value})).Instances};

$dashboard_body["widgets"] += Insert-Header "us-east-1c pool metrics";

Build-PoolWidgets $instances;

$tags = @(@{Key="Name";Value="CMC0*"});

$instances = $tags | % {(get-ec2instance -filter @(@{Name="tag:$($_.Key)";Value=$_.value})).Instances};

$dashboard_body["widgets"] += Insert-Header "us-east-1c pool metrics";

Build-PoolWidgets $instances;

$jsonified_dashboard_body = $dashboard_body | convertto-json -depth 15;

$jsonified_dashboard_body;

Write-CWDashboard -DashboardName "cmt-dashboard-prod" -DashboardBody $jsonified_dashboard_body;