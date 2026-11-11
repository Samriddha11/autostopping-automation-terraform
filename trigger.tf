resource "harness_platform_triggers" "scheduler_trigger" {

  identifier = "finops_scheduler_trigger"
  name       = "finops_scheduler_trigger"

  org_id     = var.org_id
  project_id = var.project_id

  target_id  = harness_platform_pipeline.scheduler_pipeline.identifier

  yaml = <<YAML
trigger:
  name: FinOps Scheduler Trigger
  identifier: finops_scheduler_trigger
  enabled: false

  pipelineIdentifier: finops_scheduler

  source:
    type: Scheduled
    spec:
      type: Cron
      spec:
        expression: "*/15 * * * *"
YAML
}
