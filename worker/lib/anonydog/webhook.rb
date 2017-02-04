require "sinatra/base"
require "json"
require "octokit"

module Anonydog
  class Webhook < Sinatra::Base
    get '/' do
      content_type :txt
      "Are you Github?"
    end

    post '/_github/webhook' do
      content_type :txt
      # FIXME: check secret

      event = JSON.parse(request.body.read)

      return "ignored" if !is_open_pull_request(event)

      pull_request_url = event["pull_request"]["url"]
      comments_url = event["pull_request"]["comments_url"]
      base_clone_url = event["pull_request"]["base"]["repo"]["clone_url"]
      base_commit = event["pull_request"]["base"]["sha"]
      head_clone_url = event["pull_request"]["head"]["repo"]["clone_url"]
      head_commit = event["pull_request"]["head"]["sha"]
      publish_url = event["pull_request"]["base"]["repo"]["ssh_url"]
      bot_user_name = event["pull_request"]["base"]["repo"]["owner"]["login"]
      bot_repo_full_name = event["pull_request"]["base"]["repo"]["full_name"]

      anonref = Anonydog::Local.publish_anonymized(
        base_clone_url, base_commit,
        head_clone_url, head_commit,
        publish_url,
      )

      msg = "anonymized commits for #{pull_request_url} are at #{anonref}"

      github_api = Octokit::Client.new(access_token: ENV['GITHUB_API_ACCESS_TOKEN'])
      github_api.post(comments_url, body: msg)

      bot_repo = github_api.repository(bot_repo_full_name)
      original_repo_name = bot_repo.parent["full_name"]

      github_api.create_pull_request(original_repo_name, "master", "#{bot_user_name}:#{anonref}", "hardcoded title (fixme!)", "hardcoded description (fixme!)")

      puts msg
      msg
    end

    def is_open_pull_request(event)
      "opened" == event["action"] && !event["pull_request"].nil?
    end
  end
end