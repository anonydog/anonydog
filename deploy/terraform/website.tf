resource "vercel_project" "website" {
  name = "anonydog-website"
  # TODO: terraform github repo
  git_repository {
    type  = "github"
    repo  = "anonydog/website"
  }
  alias = [
    "anonydog-website.vercel.app",
    "www.anonydog.org",
    "anonydog.org",
  ]
}

resource "vercel_env" "website_role_arn" {
  project_id  = vercel_project.website.id
  target      = [ "production" ]

  type  = "plain"
  key   = "SNS_TOPIC_ROLE_ARN"
  value = aws_iam_role.sns_role.arn
}

resource "vercel_env" "website_access_key" {
  project_id  = vercel_project.website.id
  target      = [ "production" ]

  type  = "plain"
  key   = "SNS_TOPIC_ACCESS_KEY"
  value = aws_iam_access_key.sns_access_key.id
}

resource "vercel_env" "website_secret_key" {
  project_id  = vercel_project.website.id
  target      = [ "production" ]

  type  = "secret"
  key   = "SNS_TOPIC_SECRET_KEY"
  value = vercel_secret.sns_secret_key.id
}

resource "vercel_secret" "sns_secret_key" {
  name  = "2639e0cc-aaaf-4cf0-a60c-0aa9fa2bd507"
  value = aws_iam_access_key.sns_access_key.secret
}

resource "vercel_env" "website_fork_topic_arn" {
  project_id  = vercel_project.website.id
  target      = [ "production" ]

  type  = "plain"
  key   = "SNS_TOPIC_ARN"
  value = aws_sns_topic.fork_topic.arn
}
