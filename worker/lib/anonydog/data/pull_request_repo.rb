require 'redis'

module Anonydog
  module Data
    class PullRequestRepo
      def store_mapping(data)
        contributor_pr = data[:contributorpr]
        botpr = data[:botpr]

        redis.hmset(
          "botpr:#{data[:botpr_url]}",
            "bot_repo", contributor_pr[:repo],
            "bot_repo_issue", contributor_pr[:issue]
        )

        redis.hmset(
          "contributorpr:#{data[:contributorpr_url]}",
            "upstream_repo", botpr[:repo],
            "upstream_issue", botpr[:issue]
        )
      end

      # fetch the contributor's pull request data corresponding to a bot PR url
      def contributor_pull_request(botpr_url)
        redis.hgetall("botpr:#{botpr_url}")
      end

      # fetch the bot's pull request data corresponding to a contributor PR url
      def bot_pull_request(contributorpr_url)
        redis.hgetall("contributorpr:#{contributorpr_url}")
      end

    private

      def redis
        @redis ||= Redis.new(url: ENV['REDIS_DATABASE_URL'])
      end
    end
  end
end