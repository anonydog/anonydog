require "sinatra/base"
require "octokit"

module Anonydog
  class Webapp < Sinatra::Base
    post "/fork" do
      # FIXME params injection?
      user = params[:user]
      repo = params[:repo]

# ^^^ webapp  (queue producer) ^^^
# --------------------------------
# vvv worker  (queue consumer) vvv

      # FIXME push message to queue
      github_api = Octokit::Client.new(access_token: ENV['GITHUB_API_ACCESS_TOKEN'])
      forked_repo = github_api.fork("#{user}/#{repo}")

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
      github_api.edit(forked_repo.full_name, name: "#{params[:user]}-#{params[:repo]}")

      "ok"
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