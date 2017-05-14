require "sinatra/base"
require "json"
require "octokit"
require "redis"

require "anonydog/local"
require "anonydog/webhook/messages"

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
      
      puts event["action"]

      return "ignored" if !is_interested_in(event)

      if is_open_pull_request(event) then
        # TODO: all this translating isn't very useful. get rid of it.
        # the schema coincides with the schema from octokit anyway. by adding
        # our own translation layer, we're only introducing complexity
        pull_request = {}
        pull_request[:url] = event["pull_request"]["html_url"]
        pull_request[:title] = event["pull_request"]["title"]
        pull_request[:body] = event["pull_request"]["body"]
        pull_request[:number] = event["pull_request"]["number"]
        pull_request[:comments_url] = event["pull_request"]["comments_url"]
  
        pull_request[:base] = {}
        pull_request[:base][:clone_url] = event["pull_request"]["base"]["repo"]["clone_url"]
        pull_request[:base][:ref] = event["pull_request"]["base"]["ref"]
        pull_request[:base][:commit_sha] = event["pull_request"]["base"]["sha"]
        pull_request[:base][:ssh_url] = event["pull_request"]["base"]["repo"]["ssh_url"]
        pull_request[:base][:owner_login] = event["pull_request"]["base"]["repo"]["owner"]["login"]
        pull_request[:base][:repo_full_name] = event["pull_request"]["base"]["repo"]["full_name"]
  
        pull_request[:head] = {}
        pull_request[:head][:clone_url] = event["pull_request"]["head"]["repo"]["clone_url"]
        pull_request[:head][:commit_sha] = event["pull_request"]["head"]["sha"]
  
        do_anonymize(pull_request)
      elsif is_synchronize_pull_request(event) then
        pull_request = {}
        pull_request[:url] = event["pull_request"]["html_url"]
        pull_request[:comments_url] = event["pull_request"]["comments_url"]

        pull_request[:base] = {}
        pull_request[:base][:clone_url] = event["pull_request"]["base"]["repo"]["clone_url"]
        pull_request[:base][:ref] = event["pull_request"]["base"]["ref"]
        pull_request[:base][:commit_sha] = event["pull_request"]["base"]["sha"]
        pull_request[:base][:ssh_url] = event["pull_request"]["base"]["repo"]["ssh_url"]
        pull_request[:base][:repo_full_name] = event["pull_request"]["base"]["repo"]["full_name"]

        pull_request[:head] = {}
        pull_request[:head][:clone_url] = event["pull_request"]["head"]["repo"]["clone_url"]
        pull_request[:head][:commit_sha] = event["pull_request"]["head"]["sha"]

        do_synchronize(pull_request)
      end
    end

    def verify_signature(payload_body)
      signature = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), ENV['GITHUB_WEBHOOK_SECRET'], payload_body)
      return halt 400, "Signature doesn't check. Are you Github?" unless Rack::Utils.secure_compare(signature, request.env['HTTP_X_HUB_SIGNATURE'])
    end

    def is_interested_in(event)
      is_open_pull_request(event) ||
      is_synchronize_pull_request(event)
    end

    def is_open_pull_request(event)
      "opened" == event["action"] && !event["pull_request"].nil?
    end

    def is_synchronize_pull_request(event)
      "synchronize" == event["action"] && !event["pull_request"].nil?
    end
    
    def github_api
      @github_api ||= Octokit::Client.new(access_token: ENV['GITHUB_API_ACCESS_TOKEN'])
    end

    def do_anonymize(pull_request)
      received_pr_url = pull_request[:url]
      branch_suffix = Digest::SHA256.hexdigest(received_pr_url).slice(0..8)
      anonref = "pullrequest-#{branch_suffix}"

      bot_repo = github_api.repository(pull_request[:base][:repo_full_name])
      original_repo = github_api.repository(bot_repo.parent["full_name"])

      Anonydog::Local.publish_anonymized(
        original_repo["clone_url"], pull_request[:base][:ref],
        pull_request[:head][:clone_url], pull_request[:head][:commit_sha],
        pull_request[:base][:ssh_url],
        anonref
      )

      pr_created = github_api.create_pull_request(
        original_repo["full_name"],
        "master",
        "#{pull_request[:base][:owner_login]}:#{anonref}",
        pull_request[:title],
        pull_request[:body]
      )

      redis.hmset(
        "botpr:#{pr_created.url}",
          "bot_repo", bot_repo.full_name,
          "bot_repo_issue", pull_request[:number]
      )

      msg_template = "successful_pr.md"
      msg_context = {
        pr_number: pr_created["number"],
        orig_repo_owner: pr_created["base"]["repo"]["owner"]["login"],
        orig_repo_name: pr_created["base"]["repo"]["name"],
        orig_repo_url: pr_created["base"]["repo"]["html_url"]
      }

      msg = Messages.render_file(msg_template, msg_context)

      github_api.post(pull_request[:comments_url], body: msg)

      msg
    end
    
    def do_synchronize(pull_request)
      received_pr_url = pull_request[:url]
      branch_suffix = Digest::SHA256.hexdigest(received_pr_url).slice(0..8)
      anonref = "pullrequest-#{branch_suffix}"

      bot_repo = github_api.repository(pull_request[:base][:repo_full_name])
      original_repo = github_api.repository(bot_repo.parent["full_name"])

      Anonydog::Local.publish_anonymized_sync(
        original_repo["clone_url"], pull_request[:base][:ref],
        pull_request[:head][:clone_url], pull_request[:head][:commit_sha],
        pull_request[:base][:ssh_url],
        anonref
      )

      "ok"
    end

    def redis
      @redis ||= Redis.new(url: ENV['REDIS_DATABASE_URL'])
    end
  end
end