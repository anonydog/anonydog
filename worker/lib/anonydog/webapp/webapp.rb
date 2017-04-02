require "sinatra/base"
require "octokit"

module Anonydog
  class Webapp < Sinatra::Base
    post "/fork" do
      user = params[:user]
      repo = params[:repo]

      github_api = Octokit::Client.new(access_token: ENV['GITHUB_API_ACCESS_TOKEN'])
      forked_repo = github_api.fork(:owner => user, :repo => repo)
      do_create_hook(github_api, forked_repo.full_name, 100)

      redirect to('/instructions')
    end

    def do_create_hook(github_api, repo_name, wait)
      begin
        github_api.create_hook(repo_name,
          "web",
          {
            url: ENV['GITHUB_WEBHOOK_ENDPOINT'],
            secret: ENV['GITHUB_WEBHOOK_SECRET'],
            content_type: 'json'
          },
          {
            events: ['pull_request'],
            active: true
          }
        )
      rescue Octokit::NotFound
        if wait > 60000 then # we waited for more than a minute (60000 < 100 + 200 + 400 + 800 + 1600 + 3200 + 6400 + 12800 + 25600 + 51200)
          puts "after waiting for more than a minute, we still do not have a working repo. panic!"
          return
        end
        puts "Github did not create the fork yet. Trying again in #{wait}ms..."
        sleep wait
        do_create_hook(github_api, repo_name, wait * 2)
      end
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