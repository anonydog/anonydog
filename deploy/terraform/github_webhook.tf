resource "wercel_project" "github-webhook" {
  name = "anonydog-github-webhook"
  repo {
    type        = "github"
    project_url = "https://github.com/anonydog/github-webhook"
  }
}
