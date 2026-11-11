resource "harness_platform_secret_text" "scheduler_config" {
  identifier = "finops_scheduler_config"
  name = "finops_scheduler_config"
  org_id = var.org_id
  project_id = var.project_id
  secret_manager_identifier = "harnessSecretManager"
  value_type = "Inline"
  value = jsonencode(local.scheduler_config)
}

resource "harness_platform_secret_text" "scheduler_api_key" {
  identifier = "finops_scheduler_api_key"
  name = "finops_scheduler_api_key"
  org_id = var.org_id
  project_id = var.project_id
  secret_manager_identifier = "harnessSecretManager"
  value_type = "Inline"
  value = var.platform_api_key
}
