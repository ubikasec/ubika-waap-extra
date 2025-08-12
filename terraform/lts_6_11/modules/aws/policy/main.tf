variable "autoscaling_group_name" {
}

variable "managed_ids" {
}

variable "prefix" {
  default = "ubikawaap"
}

variable "target" {
  default = 70
}

variable "estimated_instance_warmup" {
  default = 300
}

variable "disable_scale_in" {
  default = false
}


resource "aws_autoscaling_policy" "asg_cpu_usage_policy" {
  name                   = "asg_cpu_usage_policy"
  autoscaling_group_name = var.autoscaling_group_name
  policy_type            = "TargetTrackingScaling"

  estimated_instance_warmup = var.estimated_instance_warmup

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value     = var.target
    disable_scale_in = var.disable_scale_in
  }
}

resource "aws_autoscaling_policy" "persistent_managed_scale_out_policy" {
  name                   = "persistent_managed_cpu_usage_policy"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = var.estimated_instance_warmup * 2
  autoscaling_group_name = var.autoscaling_group_name
}

resource "aws_autoscaling_policy" "persistent_managed_scale_in_policy" {
  name                   = "persistent_managed_scale_in_policy"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = var.estimated_instance_warmup * 2
  autoscaling_group_name = var.autoscaling_group_name
}

resource "aws_cloudwatch_metric_alarm" "persistent_managed_scale_in_alarm" {
  alarm_name          = "${var.prefix}-persistent_managed_scale_in_alarm"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 16
  datapoints_to_alarm = 15
  threshold           = var.target * 0.8

  metric_query {
    id          = "e1"
    expression  = "AVG(METRICS(\"cpu\"))"
    label       = "Average CPUUtilization"
    return_data = true
  }

  dynamic "metric_query" {
    for_each = var.managed_ids
    content {
      id = "cpu${index(var.managed_ids, metric_query.value)}"
      metric {
        metric_name = "CPUUtilization"
        namespace   = "AWS/EC2"
        period      = 60
        stat        = "Average"
        dimensions = {
          InstanceId = metric_query.value
        }
      }
    }
  }

  alarm_description = "CPU Usage has exceeded ${var.target}%"
  alarm_actions     = [aws_autoscaling_policy.persistent_managed_scale_in_policy.arn]
}
resource "aws_cloudwatch_metric_alarm" "persistent_managed_scale_out_alarm" {
  alarm_name          = "${var.prefix}-persistent_managed_scale_out_alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 4
  datapoints_to_alarm = 3
  threshold           = var.target

  metric_query {
    id          = "e1"
    expression  = "SUM(METRICS(\"cpu\")) / (METRIC_COUNT(METRICS(\"cpu\")) + asg0)"
    label       = "Average CPUUtilization"
    return_data = true
  }

  metric_query {
    id = "asg0"
    metric {
      metric_name = "GroupTotalInstances"
      namespace   = "AWS/AutoScaling"
      period      = 60
      stat        = "Average"
      dimensions = {
        AutoScalingGroupName = var.autoscaling_group_name
      }
    }
  }

  dynamic "metric_query" {
    for_each = var.managed_ids
    content {
      id = "cpu${index(var.managed_ids, metric_query.value)}"
      metric {
        metric_name = "CPUUtilization"
        namespace   = "AWS/EC2"
        period      = 60
        stat        = "Average"
        dimensions = {
          InstanceId = metric_query.value
        }
      }
    }
  }

  alarm_description = "CPU Usage has exceeded ${var.target}%"
  alarm_actions     = [aws_autoscaling_policy.persistent_managed_scale_out_policy.arn]
}
