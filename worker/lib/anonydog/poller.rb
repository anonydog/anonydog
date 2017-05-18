require 'octokit'

require 'anonydog/data/comments_repo'
require 'anonydog/data/pull_request_repo'

module Anonydog
  class Poller
    def github_api
      @github_api ||= Octokit::Client.new(access_token: ENV['GITHUB_API_ACCESS_TOKEN'])
    end

    def pr_repo
      @pr_repo ||= Data::PullRequestRepo.new
    end

    def comments_repo
      @comments_repo ||= Data::CommentsRepo.new
    end

    def my_login
      @my_login ||= github_api.user.login
    end

    def poll_for_pr_comments
      poll_interval = 60
      last_modified_tag = ''
      while true do
        threads = github_api.notifications(
          :headers => {
            'If-Modified-Since' => last_modified_tag
          }
        )
        threads = (threads.instance_of? Array) ? threads : []
        puts "Checked for notifications at #{Time.now}. Got #{threads.size} results"

        http_response = github_api.last_response

        poll_interval = (http_response.headers['X-Poll-Interval'] || poll_interval).to_i
        last_modified_tag = http_response.headers['Last-Modified'] || last_modified_tag

        threads.each do |thread|
          if do_process_thread(thread) then
            puts "Processed thread #{thread[:url]}"
            github_api.mark_thread_as_read(thread[:id])
          end
        end

        sleep poll_interval
      end
    end

    def do_process_thread(thread)
      # the pull request the bot authored (on the upstream repo)
      bot_pull_request_url = thread[:subject][:url]

      botpr = pr_repo.contributor_pull_request(bot_pull_request_url)
      bot_repo = botpr['bot_repo']
      bot_issue = botpr['bot_repo_issue']

      already_relayed = comments_repo.comments_already_relayed(bot_pull_request_url)

      if [bot_pull_request_url, botpr, bot_repo, bot_issue].any?(&:nil?) then
        puts "cannot process #{thread[:url]}. something is missing."
        puts "bot_pull_request_url: #{bot_pull_request_url}"
        puts "botpr: #{botpr}"
        puts "bot_repo: #{bot_repo}"
        puts "bot_issue: #{bot_issue}"
        return false
      end

      # TODO:
      # ^^^^^^^^^^^^^
      # clerical work
      # -------------
      # real stuff
      # vvvvvvvvvvvvv

      bot_pull_request = github_api.get(bot_pull_request_url)

      original_comments_url = bot_pull_request[:comments_url]
      original_review_comments_url = bot_pull_request[:review_comments_url]

      original_comments = github_api.get(original_comments_url)
      original_review_comments = github_api.get(original_review_comments_url)

      original_comments.concat(original_review_comments).
        select do |comment|
          opaque_id = comment[:url]
          !already_relayed.include? opaque_id
        end.
        select do |comment|
          # comment is not from the bot itself
          comment[:user][:login] != my_login
        end.
        each do |comment|
          username = comment[:user][:login]
          body = comment[:body]
          original_url = comment[:html_url]
          opaque_id = comment[:url]

          # ^^^^^^^^^^^^^^^^^^^^
          #       common
          # --------------------
          # review comments only
          # vvvvvvvvvvvvvvvvvvvv
          commit_id = 'b3097adc80abdfe0398017d9d631a286ee8d9895' #FIXME: hardcoded
          path = comment[:path]
          position = comment[:position]
          # ^^^^^^^^^^^^^^^^^^^^
          # review comments only
          # --------------------
          #       common
          # vvvvvvvvvvvvvvvvvvvv

          msg = "[#{username} said](#{original_url}):\n\n#{body}"
          if !position.nil? then # we're dealing with a review comment here
            github_api.create_pull_request_comment(bot_repo, bot_issue, msg, commit_id, path, position)
          else
            github_api.add_comment(bot_repo, bot_issue, msg)
          end
          already_relayed.push(opaque_id)
          comments_repo.mark_comment_as_relayed(bot_pull_request_url, opaque_id)
        end

      return true
    end
  end
end

if __FILE__==$0 then
  Anonydog::Poller.new.poll_for_pr_comments
end