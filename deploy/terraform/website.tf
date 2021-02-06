resource "wercel_project" "website" {
  name = "anonydog-website"
  repo {
    type        = "github"
    project_url = "https://github.com/anonydog/website"
  }
}

resource "wercel_environment_variable" "website_access_key" {
  project_id = wercel_project.website.id
  key = "SNS_TOPIC_ACCESS_KEY"
  value = aws_iam_access_key.sns_access_key.id
}

resource "wercel_environment_variable" "website_secret_key" {
  project_id = wercel_project.website.id
  key = "SNS_TOPIC_SECRET_KEY"
  value = aws_iam_access_key.sns_access_key.secret
}

resource "wercel_environment_variable" "website_fork_topic_arn" {
  project_id = wercel_project.website.id
  key = "SNS_TOPIC_ARN"
  value = aws_sns_topic.fork_topic.arn
}