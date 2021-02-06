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
  value = "https://github-webhook.anonydog.vercel.app/api/hook"
}

resource "wercel_environment_variable" "fork_webhook_github_secret" {
  project_id = wercel_project.fork_webhook.id

  key = "GITHUB_WEBHOOK_SECRET"
  value = local.github_webhook_secret
}