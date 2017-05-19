require "sinatra/base"
require "json"
require "octokit"

require "anonydog/local"
require "anonydog/data/pull_request_repo"
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
        pull_request[:url] = event["pull_request"]["url"]
        pull_request[:html_url] = event["pull_request"]["html_url"]
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
        pull_request[:url] = event["pull_request"]["url"]
        pull_request[:html_url] = event["pull_request"]["html_url"]
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
      elsif is_create_comment(event) then
        comment = {}
        comment[:author] = event["comment"]["user"]["login"]
        comment[:body] = event["comment"]["body"]
        if !event["issue"].nil? then
          comment[:pull_request_url] = event["issue"]["pull_request"]["url"]
          comment[:pull_request_author] = event["issue"]["user"]["login"]
        else
          comment[:pull_request_url] = event["pull_request"]["url"]
          comment[:pull_request_author] = event["pull_request"]["user"]["login"]
          comment[:path] = event["comment"]["path"]
          comment[:position] = event["comment"]["position"]
        end
        do_relay(comment)
      end
    end

    def verify_signature(payload_body)
      signature = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), ENV['GITHUB_WEBHOOK_SECRET'], payload_body)
      return halt 400, "Signature doesn't check. Are you Github?" unless Rack::Utils.secure_compare(signature, request.env['HTTP_X_HUB_SIGNATURE'])
    end

    def is_interested_in(event)
      is_open_pull_request(event) ||
      is_synchronize_pull_request(event) ||
      is_create_comment(event)
    end

    def is_open_pull_request(event)
      "opened" == event["action"] && !event["pull_request"].nil?
    end

    def is_synchronize_pull_request(event)
      "synchronize" == event["action"] && !event["pull_request"].nil?
    end
    
    def is_create_comment(event)
      "created" == event["action"] && !event["comment"].nil? &&
      (!event["issue"].nil? || !event["pull_request"].nil?)
    end

    def github_api
      @github_api ||= Octokit::Client.new(access_token: ENV['GITHUB_API_ACCESS_TOKEN'])
    end

    def do_anonymize(pull_request)
      received_pr_url = pull_request[:html_url]
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

      pr_repo.store_mapping(
        :contributorpr => {
          :url => pull_request[:url],
          :repo => bot_repo.full_name,
          :issue => pull_request[:number]
        },
        :botpr => {
          :url => pr_created.url,
          :repo => pr_created["base"]["repo"]["full_name"],
          :issue => pr_created["number"]
        }
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
      received_pr_url = pull_request[:html_url]
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

    def do_relay(comment)
      #gate check: is this a comment from the original author of the PR?
      return "not a comment from author. won't relay." if comment[:author] != comment[:pull_request_author]

      botpr = pr_repo.bot_pull_request(comment[:pull_request_url])

      botpr_url = botpr[:url]
      botpr_repo = botpr[:repo]
      botpr_issue = botpr[:issue]

      if comment[:path].nil? then
        github_api.add_comment(botpr_repo, botpr_issue, comment[:body])
      else
        bot_pull_request = github_api.get(botpr_url)

        commit_id = bot_pull_request[:head][:sha]

        # TODO: can we assume that the PRs are synced? (C110F795)
        github_api.create_pull_request_comment(
          botpr_repo,
          botpr_issue,
          comment[:body],
          commit_id,
          comment[:path],
          comment[:position]
        )
      end

      "ok"
    end

    def pr_repo
      @pr_repo ||= Data::PullRequestRepo.new
    end
  end
end