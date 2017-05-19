require 'redis'

module Anonydog
  module Data
    class PullRequestRepo
      def store_mapping(data)
        contributor_pr = data[:contributorpr]
        botpr = data[:botpr]

        redis.hmset(
          "botpr:#{botpr[:url]}",
            "url", contributor_pr[:url],
            "repo", contributor_pr[:repo],
            "issue", contributor_pr[:issue]
        )

        #TODO: uniform
        redis.hmset(
          "contributorpr:#{contributor_pr[:url]}",
            "upstream_repo", botpr[:repo],
            "upstream_issue", botpr[:issue]
        )
      end

      # fetch the contributor's pull request data corresponding to a bot PR url
      def contributor_pull_request(botpr_url)
        h = redis.hgetall("botpr:#{botpr_url}")
        h.inject({}) { |acc, entry| acc[entry[0].to_sym] = entry[1]; acc }
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