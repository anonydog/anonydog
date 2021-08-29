resource "vercel_project" "poller" {
  name = "poller"
  alias = [
    "poller-omega.vercel.app",
  ]
  git_repository {
    type  = "github"
    repo  = "anonydog/poller"
  }
}

resource "vercel_env" "poller_redis_database_url" {
  project_id = vercel_project.poller.id
  target     = [ "production" ]

  key    = "REDIS_DATABASE_URL"
  type   = "secret"
  value  = vercel_secret.poller_redis_database_url.id
}

resource "vercel_secret" "poller_redis_database_url" {
  name   = "57f8d555-8971-45fe-a621-25c4b65902ba"
  value  = local.redis_database_url
}

resource "vercel_env" "poller_github_api_access_token" {
  project_id = vercel_project.poller.id
  target     = [ "production" ]

  key    = "GITHUB_API_ACCESS_TOKEN"
  type   = "secret"
  value  = vercel_secret.poller_redis_database_url.id
}

resource "vercel_secret" "poller_github_api_access_token" {
  name   = "3ee99711-4f4c-41e5-84cc-d70fb9b1f187"
  value  = local.github_api_access_token
}

resource "vercel_env" "poller_mongo_database_url" {
  project_id = vercel_project.poller.id
  target     = [ "production" ]

  key    = "MONGO_DATABASE_URL"
  type   = "secret"
  value  = vercel_secret.poller_mongo_database_url.id
}

resource "vercel_secret" "poller_mongo_database_url" {
  name  = "06ac9a89-dbfe-4f9e-9013-f9585e01e3d6"
  value = local.mongo_database_url
}

resource "vercel_env" "poller_secret" {
  project_id = vercel_project.poller.id
  target     = [ "production" ]

  key     = "ANONYDOG_SECRET"
  type    = "secret"
  value   = vercel_secret.poller_secret.id
}

resource "vercel_secret" "poller_secret" {
  name   = "e8d977f1-bd7e-4d97-a601-a83348fc0256"
  value  = local.anonydog_secret
}

