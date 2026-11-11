locals {
  scheduler_config = {
    name = "finops_scheduler"
    kind = "instance"
    enabled = true
    connector_name_regex = "^.*nyl-ctfinops-(test|dev)-harness-connector$"
    allowed_providers = "aws"
    time_zone = "America/New_York"
    dry_run = false
    rule_limit = 10
    objects_filter = {
      tags = { "harness:autoStop" = "true" }
    }
    options = {
      idle_time = 15
      default_schedule = "05-23"
      schedule_tag_key = "harness:scheduler"
      connector_name_exclude = "-harness-connector"
      patch_schedule = {
        key = "patchschedule"
        values = [
          { value = "Day1", schedule = "Wed:23-6" },
          { value = "Day2", schedule = "Thu:23-6" }
        ]
      }
    }
  }

  rule_config = {
    name = "finops-scheduler-rule"
    schedule_name = "finops_scheduler_uptime"
    days = [0, 1, 2, 3, 4, 5, 6]
    start_hour = 5
    end_hour = 23
  }
}
