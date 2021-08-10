variable "resource_group" {
  description = ""
}

variable "scale_set_id" {
}

variable "managed_ids" {
}

variable "prefix" {
  default = "rswaf"
}

variable "autoscaler_min_size" {
  default = 0
}
variable "autoscaler_max_size" {
  default = 0
}

variable "target" {
  default = 70
}

variable "scale_out_cooldown" {
  default = "PT5M"
}

variable "scale_in_cooldown" {
  default = "PT30M"
}

resource "azurerm_monitor_autoscale_setting" "test" {
  name                = "myAutoscaleSetting"
  resource_group_name = var.resource_group.name
  location            = var.resource_group.location
  target_resource_id  = var.scale_set_id

  profile {
    name = "defaultProfile"

    capacity {
      default = 0
      minimum = var.autoscaler_min_size
      maximum = var.autoscaler_max_size
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = var.scale_set_id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = var.target
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = var.scale_out_cooldown
      }
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = var.scale_set_id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT30M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = var.target / 4
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = var.scale_in_cooldown
      }
    }

    dynamic "rule" {
      for_each = var.managed_ids
      content {
        metric_trigger {
          metric_name        = "Percentage CPU"
          metric_resource_id = rule.value
          time_grain         = "PT1M"
          statistic          = "Average"
          time_window        = "PT5M"
          time_aggregation   = "Average"
          operator           = "GreaterThan"
          threshold          = var.target
        }

        scale_action {
          direction = "Increase"
          type      = "ChangeCount"
          value     = "1"
          cooldown  = "PT1H"
        }
      }
    }
  }
}
