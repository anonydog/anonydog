resource "wercel_project" "poller" {
  name = "poller"
  domains = [
    "poller-omega.vercel.app",
  ]
  repo {
    type        = "github"
    project_url = "https://github.com/anonydog/poller"
  }
}

resource "wercel_environment_variable" "poller_redis_database_url" {
  project_id = wercel_project.poller.id

  key = "REDIS_DATABASE_URL"
  value = local.redis_database_url
}

resource "wercel_environment_variable" "poller_github_api_access_token" {
  project_id = wercel_project.poller.id

  key = "GITHUB_API_ACCESS_TOKEN"
  value = local.github_api_access_token
}

resource "wercel_environment_variable" "poller_mongo_database_url" {
  project_id = wercel_project.poller.id

  key = "MONGO_DATABASE_URL"
  value = local.mongo_database_url
}
