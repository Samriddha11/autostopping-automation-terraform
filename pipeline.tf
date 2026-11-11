resource "harness_platform_pipeline" "scheduler_pipeline" {

  identifier = "finops_scheduler"
  name       = "FinOps Scheduler"

  org_id     = var.org_id
  project_id = var.project_id

  yaml = <<YAML
pipeline:
  name: FinOps Scheduler
  identifier: finops_scheduler
  projectIdentifier: ${var.project_id}
  orgIdentifier: ${var.org_id}
  allowStageExecutions: true

  stages:
    - stage:
        name: ValidateScheduler
        identifier: ValidateScheduler
        type: Custom

        spec:
          execution:
            steps:
              - step:
                  type: ShellScript
                  name: PrintSchedulerConfig
                  identifier: PrintSchedulerConfig

                  spec:
                    shell: Bash

                    source:
                      type: Inline
                      spec:
                        script: |
                          echo "FinOps Scheduler Deployment"
                          echo "Config: $SCHEDULER_CONFIG"

                          curl -s -i -X POST "https://app.harness.io/gateway/lw/api/accounts/${var.account_id}/autostopping/onboarding/configs" \
                            -H "x-api-key: $API_TOKEN" \
                            -H "Content-Type: application/json" \
                            -d "$SCHEDULER_CONFIG" > response.txt

                          cat response.txt
                          head -1 response.txt | grep -q " 20"

                    environmentVariables:
                      - name: SCHEDULER_CONFIG
                        type: String
                        value: <+secrets.getValue("finops_scheduler_config")>
                      - name: API_TOKEN
                        type: String
                        value: <+secrets.getValue("finops_scheduler_api_key")>

                    outputVariables: []

        tags: {}

    - stage:
        name: CreateSchedulerRule
        identifier: CreateSchedulerRule
        type: Custom

        spec:
          execution:
            steps:
              - step:
                  type: ShellScript
                  name: CreateAutoStoppingRule
                  identifier: CreateAutoStoppingRule

                  spec:
                    shell: Bash

                    source:
                      type: Inline
                      spec:
                        script: |
                          set -e
                          BASE="https://app.harness.io/gateway/lw/api/accounts/${var.account_id}"
                          command -v jq >/dev/null || { curl -sSL -o /tmp/jq https://github.com/jqlang/jq/releases/download/jq-1.7.1/jq-linux-amd64; chmod +x /tmp/jq; export PATH=/tmp:$PATH; }

                          echo "Creating AutoStopping rule ${local.rule_config.name}"
                          cat > rule.json <<EOF
                          {
                            "service": {
                              "name": "${local.rule_config.name}",
                              "account_identifier": "${var.account_id}",
                              "fulfilment": "ondemand",
                              "kind": "instance",
                              "cloud_account_id": "${var.connector_id}",
                              "idle_time_mins": ${local.scheduler_config.options.idle_time},
                              "custom_domains": [],
                              "match_all_subdomains": false,
                              "disabled": false,
                              "routing": {"instance": {"filter": {"tags": ${jsonencode(local.scheduler_config.objects_filter.tags)}, "regions": ["${var.region}"]}}},
                              "opts": {"preserve_private_ip": false, "delete_cloud_resources": false, "always_use_private_ip": false, "hide_progress_page": false, "dry_run": ${var.dry_run}},
                              "metadata": {"cloud_provider_details": {"name": "${var.connector_name}"}}
                            },
                            "apply_now": true
                          }
                          EOF

                          curl -s -D rule_headers.txt -o rule_response.json -X POST "$BASE/autostopping/v2/rules?accountIdentifier=${var.account_id}" \
                            -H "x-api-key: $API_TOKEN" \
                            -H "Content-Type: application/json" \
                            -d @rule.json

                          cat rule_response.json
                          head -1 rule_headers.txt | grep -q " 20"
                          RULE_ID=$(jq -r '.response.id' rule_response.json)
                          echo "Created rule $RULE_ID"

                          echo "Attaching schedule ${local.rule_config.schedule_name}"
                          cat > schedule.json <<EOF
                          {
                            "schedule": {
                              "name": "${local.rule_config.schedule_name}",
                              "account": "${var.account_id}",
                              "description": "Uptime window for ${local.rule_config.name}",
                              "resources": [{"id": "$RULE_ID", "type": "autostop_rule"}],
                              "details": {
                                "uptime": {
                                  "period": {"start": "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"},
                                  "days": {"days": ${jsonencode(local.rule_config.days)}, "all_day": false, "start_time": {"hour": ${local.rule_config.start_hour}, "min": 0}, "end_time": {"hour": ${local.rule_config.end_hour}, "min": 0}}
                                },
                                "timezone": "${local.scheduler_config.time_zone}"
                              }
                            }
                          }
                          EOF

                          curl -s -D schedule_headers.txt -o schedule_response.json -X POST "$BASE/schedules?cloud_account_id=${var.connector_id}&accountIdentifier=${var.account_id}" \
                            -H "x-api-key: $API_TOKEN" \
                            -H "Content-Type: application/json" \
                            -d @schedule.json

                          cat schedule_response.json
                          head -1 schedule_headers.txt | grep -q " 20"
                          echo "Attached schedule to rule $RULE_ID"

                    environmentVariables:
                      - name: API_TOKEN
                        type: String
                        value: <+secrets.getValue("finops_scheduler_api_key")>

                    outputVariables: []

        tags: {}

YAML
}
