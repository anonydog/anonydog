require "sinatra/base"
require 'bunny'
require "msgpack"

module Anonydog
  class Webapp < Sinatra::Base
    post "/fork" do
      user = params[:user]
      repo = params[:repo]

      queue.publish(
        {'user': user, 'repo': repo}.to_msgpack,
        :routing_key => queue.name
      )

      redirect to('/instructions')
    end

    def queue
      @queue ||= channel.queue("anonydog.fork", :auto_delete => true)
    end

    def channel
      @channel ||= connection.create_channel
    end

    def connection
      if @conn.nil? then
        @conn = Bunny.new(ENV['MESSAGE_QUEUE_URL'])
        @conn.start
      end
      @conn
    end

    get "/fork" do
      #TODO: can this be done by some middleware or something?
      send_file File.expand_path('fork.html', settings.public_folder)
    end

    get "/instructions" do
      #TODO: can this be done by some middleware or something?
      send_file File.expand_path('instructions.html', settings.public_folder)
    end

    get "/" do
      #TODO: can this be done by some middleware or something?
      send_file File.expand_path('index.html', settings.public_folder)
    end
  end
end