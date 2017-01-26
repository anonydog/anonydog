require "sinatra/base"
require "json"

module Anonydog
  class Webhook < Sinatra::Base
    get '/' do
      content_type :txt
      "Are you Github?"
    end

    post '/_github/webhook' do
      puts "received webhook event"

      event = JSON.parse(request.body.read)

      puts "opened? => #{event["action"]}"

      puts %{base_clone_url: #{event["pull_request"]["base"]["repo"]["clone_url"]}}
      puts %{base_commit: #{event["pull_request"]["base"]["sha"]}}
      puts %{head_clone_url: #{event["pull_request"]["head"]["repo"]["clone_url"]}}
      puts %{head_commit: #{event["pull_request"]["head"]["sha"]}}
      puts %{publish_url: #{event["pull_request"]["base"]["repo"]["ssh_url"]}}

    end
  end
end