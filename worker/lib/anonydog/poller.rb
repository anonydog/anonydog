require 'octokit'

module Anonydog
  class Poller
    def github_api
      @github_api ||= Octokit::Client.new(access_token: ENV['GITHUB_API_ACCESS_TOKEN'])
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
          do_process_thread(thread)
          puts "Processed thread #{thread[:url]}"
          github_api.mark_thread_as_read(thread[:id])
        end

        sleep poll_interval
      end
    end

    #FIXME: need a proper database
    def already_relayed
      @already_relayed ||= %w{
      }
    end

    def do_process_thread(thread)
      # the pull request the bot authored (on the upstream repo)
      bot_pull_request_url = thread[:subject][:url]

      #FIXME: hardcoded
      bot_repo = "arraisbot/personal-toolbox"
      bot_issue = 2

      bot_pull_request = github_api.get(bot_pull_request_url)

      original_comments_url = bot_pull_request[:comments_url]

      original_comments = github_api.get(original_comments_url)
      original_comments.each do |comment|
        username = comment[:user][:login]
        body = comment[:body]
        original_url = comment[:html_url]
        opaque_id = comment[:url]
        if !already_relayed.include?(opaque_id) then
          msg = "[#{username} said](#{original_url}):\n\n#{body}"
          github_api.add_comment(bot_repo, bot_issue, msg)
          already_relayed.push(opaque_id)
        end
      end
    end
  end
end

if __FILE__==$0 then
  Anonydog::Poller.new.poll_for_pr_comments
end