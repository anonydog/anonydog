resource "vercel_project" "fork_webhook" {
  name = "fork-webhook"
  # TODO: terraform github repo
  git_repository {
    type  = "github"
    repo  = "anonydog/fork-webhook"
  }
}

resource "vercel_env" "fork_webhook_github_token" {
  project_id  = vercel_project.fork_webhook.id
  target      = [ "production" ]

  type  = "secret"
  key   = "GITHUB_API_ACCESS_TOKEN"
  value = vercel_secret.fork_webhook_github_token.id
}

resource "vercel_secret" "fork_webhook_github_token" {
  name  = "143daa0e-ab40-49df-a553-e2103c1d0788"
  value = local.github_api_access_token
}

resource "vercel_env" "fork_webhook_github_webhook_endpoint" {
  project_id  = vercel_project.fork_webhook.id
  target      = [ "production" ]

  type  = "plain"
  key   = "GITHUB_WEBHOOK_ENDPOINT"
  value = local.github_webhook_url
}

resource "vercel_env" "fork_webhook_github_secret" {
  project_id  = vercel_project.fork_webhook.id
  target      = [ "production" ]

  type  = "secret"
  key   = "GITHUB_WEBHOOK_SECRET"
  value = vercel_secret.fork_webhook_github_secret.id
}

resource "vercel_secret" "fork_webhook_github_secret" {
  name  = "88796f49-e545-4f2e-94be-394ee849c2ac"
  value = local.github_webhook_secret
}

resource "vercel_env" "fork_webhook_role_arn" {
  project_id  = vercel_project.fork_webhook.id
  target      = [ "production" ]

  type  = "plain"
  key   = "STATE_MACHINE_ROLE_ARN"
  value = aws_iam_role.sns_role.arn
}

resource "vercel_env" "fork_webhook_aws_access_key" {
  project_id  = vercel_project.fork_webhook.id
  target      = [ "production" ]

  type  = "plain"
  key   = "STATE_MACHINE_ACCESS_KEY"
  value = aws_iam_access_key.sns_access_key.id
}

resource "vercel_env" "fork_webhook_aws_secret_key" {
  project_id  = vercel_project.fork_webhook.id
  target      = [ "production" ]

  type  = "secret"
  key   = "STATE_MACHINE_SECRET_KEY"
  value = vercel_secret.sns_secret_key.id
}

resource "vercel_env" "fork_webhook_state_machine_arn" {
  project_id  = vercel_project.fork_webhook.id
  target      = [ "production" ]

  type  = "plain"
  key   = "STATE_MACHINE_ARN"
  value = aws_sfn_state_machine.retry_webhook_state_machine.arn
}