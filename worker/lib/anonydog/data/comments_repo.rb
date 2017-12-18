require 'redis'

module Anonydog
  module Data
    class CommentsRepo
      def comments_already_relayed(botpr_url)
        redis.smembers("botpr:comments_already_relayed:#{botpr_url}")
      end

      def mark_comment_as_relayed(botpr_url, comment_id)
        redis.sadd("botpr:comments_already_relayed:#{botpr_url}", comment_id)
      end

    private

      def redis
        @redis ||= Redis.new(url: ENV['REDIS_DATABASE_URL'])
      end
    end
  end
end