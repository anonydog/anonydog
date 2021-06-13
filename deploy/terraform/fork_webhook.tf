resource "wercel_project" "fork_webhook" {
  name = "fork-webhook"
  repo {
    type        = "github"
    project_url = "https://github.com/anonydog/fork-webhook"
  }
}

resource "wercel_environment_variable" "fork_webhook_github_token" {
  project_id = wercel_project.fork_webhook.id

  key = "GITHUB_API_ACCESS_TOKEN"
  value = local.github_api_access_token
}

resource "wercel_environment_variable" "fork_webhook_github_webhook_endpoint" {
  project_id = wercel_project.fork_webhook.id

  key = "GITHUB_WEBHOOK_ENDPOINT"
  value = local.github_webhook_url
}

resource "wercel_environment_variable" "fork_webhook_github_secret" {
  project_id = wercel_project.fork_webhook.id

  key = "GITHUB_WEBHOOK_SECRET"
  value = local.github_webhook_secret
}

resource "wercel_environment_variable" "fork_webhook_role_arn" {
  project_id = wercel_project.fork_webhook.id

  key = "STATE_MACHINE_ROLE_ARN"
  value = aws_iam_role.sns_role.arn
}

resource "wercel_environment_variable" "fork_webhook_aws_access_key" {
  project_id = wercel_project.fork_webhook.id

  key = "STATE_MACHINE_ACCESS_KEY"
  value = aws_iam_access_key.sns_access_key.id
}

resource "wercel_environment_variable" "fork_webhook_aws_secret_key" {
  project_id = wercel_project.fork_webhook.id

  key = "STATE_MACHINE_SECRET_KEY"
  value = aws_iam_access_key.sns_access_key.secret
}

resource "wercel_environment_variable" "fork_webhook_state_machine_arn" {
  project_id = wercel_project.fork_webhook.id

  key = "STATE_MACHINE_ARN"
  value = aws_sfn_state_machine.retry_webhook_state_machine.arn
}
