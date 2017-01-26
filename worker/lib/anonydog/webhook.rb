require "sinatra/base"
require "json"

module Anonydog
  class Webhook < Sinatra::Base
    get '/' do
      content_type :txt
      "Are you Github?"
    end

    post '/_github/webhook' do
      content_type :txt

      puts "received webhook event"

      event = JSON.parse(request.body.read)

      puts "opened? => #{event["action"]}"
      
      return "ignored" if !is_open_pull_request(event)
      
      base_clone_url = event["pull_request"]["base"]["repo"]["clone_url"]
      base_commit = event["pull_request"]["base"]["sha"]
      head_clone_url = event["pull_request"]["head"]["repo"]["clone_url"]
      head_commit = event["pull_request"]["head"]["sha"]
      publish_url = event["pull_request"]["base"]["repo"]["ssh_url"]

      anonref = Anonydog::Local.publish_anonymized(
        base_clone_url, base_commit,
        head_clone_url, head_commit,
        publish_url,
      )

      msg = "anonymized commits are at #{anonref}"
      puts msg
      msg
    end
    
    def is_open_pull_request(event)
      "opened" == event["action"] && !event["pull_request"].nil?
    end
  end
end