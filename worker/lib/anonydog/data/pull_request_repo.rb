require 'mongo'

module Anonydog
  module Data
    class PullRequestRepo
      def store_mapping(data)
        pull_requests.insert_one(data)
      end

      # fetch the contributor's pull request data corresponding to a bot PR url
      def contributor_pull_request(botpr_url)
        pr = pull_requests.find("botpr.url" => botpr_url).first
        pr[:contributorpr]
      end

      # fetch the bot's pull request data corresponding to a contributor PR url
      def bot_pull_request(contributorpr_url)
        pr = pull_requests.find("contributorpr.url" => contributorpr_url).first
        pr[:botpr]
      end

    private

      def pull_requests
        return @pull_requests unless @pull_requests.nil?
        client = Mongo::Client.new(ENV['MONGO_DATABASE_URL'])
        @pull_requests = client[:pull_requests]
      end
    end
  end
end