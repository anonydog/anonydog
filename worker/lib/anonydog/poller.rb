require 'octokit'

module Anonydog
  class Poller
    def poll_for_pr_comments
      github_api = Octokit::Client.new(access_token: ENV['GITHUB_API_ACCESS_TOKEN'])

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

        poll_interval = http_response.headers['X-Poll-Interval'].to_i
        last_modified_tag = http_response.headers['Last-Modified'] || last_modified_tag

        threads.each do |thread|
          puts "Processed thread #{thread[:url]}"
          github_api.mark_thread_as_read(thread[:id])
        end

        sleep poll_interval
      end
    end
  end
end

if __FILE__==$0 then
  Anonydog::Poller.new.poll_for_pr_comments
end