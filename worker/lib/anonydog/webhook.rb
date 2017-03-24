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
      payload_body = request.body.read

      # TODO move verification to middleware
      verify_signature(payload_body)

      event = JSON.parse(payload_body)

      return "ignored" if !is_open_pull_request(event)

      pull_request = {}
      pull_request[:url] = event["pull_request"]["url"]
      pull_request[:title] = event["pull_request"]["title"]
      pull_request[:body] = event["pull_request"]["body"]
      pull_request[:comments_url] = event["pull_request"]["comments_url"]

      pull_request[:base] = {}
      pull_request[:base][:clone_url] = event["pull_request"]["base"]["repo"]["clone_url"]
      pull_request[:base][:commit_sha] = event["pull_request"]["base"]["sha"]
      pull_request[:base][:ssh_url] = event["pull_request"]["base"]["repo"]["ssh_url"]
      pull_request[:base][:owner_login] = event["pull_request"]["base"]["repo"]["owner"]["login"]
      pull_request[:base][:repo_full_name] = event["pull_request"]["base"]["repo"]["full_name"]

      pull_request[:head] = {}
      pull_request[:head][:clone_url] = event["pull_request"]["head"]["repo"]["clone_url"]
      pull_request[:head][:commit_sha] = event["pull_request"]["head"]["sha"]

      #FIXME: push message to queue
      do_anonymize(pull_request)
    end

    def verify_signature(payload_body)
      signature = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), ENV['GITHUB_WEBHOOK_SECRET'], payload_body)
      return halt 400, "Signature doesn't check. Are you Github?" unless Rack::Utils.secure_compare(signature, request.env['HTTP_X_HUB_SIGNATURE'])
    end

    def is_open_pull_request(event)
      "opened" == event["action"] && !event["pull_request"].nil?
    end

    def do_anonymize(pull_request)
      anonref = Anonydog::Local.publish_anonymized(
        pull_request[:base][:clone_url], pull_request[:base][:commit_sha],
        pull_request[:head][:clone_url], pull_request[:head][:commit_sha],
        pull_request[:base][:ssh_url]
      )

      msg = "anonymized commits for #{pull_request[:url]} are at #{anonref}"

      github_api = Octokit::Client.new(access_token: ENV['GITHUB_API_ACCESS_TOKEN'])
      github_api.post(pull_request[:comments_url], body: msg)

      bot_repo = github_api.repository(pull_request[:base][:repo_full_name])
      original_repo_name = bot_repo.parent["full_name"]

      github_api.create_pull_request(
        original_repo_name,
        "master",
        "#{pull_request[:base][:owner_login]}:#{anonref}",
        pull_request[:title],
        pull_request[:body]
      )

      puts msg
      msg
    end
  end
end