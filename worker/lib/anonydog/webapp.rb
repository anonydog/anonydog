require "sinatra/base"
require "octokit"

module Anonydog
  class Webapp < Sinatra::Base
    post "/fork" do
      # FIXME params injection?
      user = params[:user]
      repo = params[:repo]

      github_api = Octokit::Client.new(access_token: ENV['GITHUB_API_ACCESS_TOKEN'])
      forked_repo = github_api.fork("#{user}/#{repo}")
      do_create_hook(forked_repo.full_name, 100)

      "ok"
    end

    def do_create_hook(repo_name, wait)
      begin
        github_api.create_hook(forked_repo.full_name,
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
        do_create_hook(forked_repo.full_name, wait * 2)
      end
    end

    get "/fork" do
      <<-END
<html>
  <body>
    <form action="/fork" method="post">
      <p>
        <label for="user">User:</label>
        <input type="text" name="user" value="thiagoarrais" />
      </p>
      <p>
        <label for="repo">Repo:</label>
        <input type="text" name="repo" />
      </p>
      <p>
        <input type="submit" />
      </p>
    </form>
  </body>
</html>
END
    end

    get "/" do
      <<-END
<html>
  <body>We're under construction. Go to <a href="/fork">/fork</a></body>
</html>
END
    end

  end
end