chrome.webNavigation.onHistoryStateUpdated.addListener(function(details) {
    chrome.tabs.executeScript(null,{file:"content-script.js"});
});

browser.runtime.onMessage.addListener(
  function(message, sender) {
    return browser.storage.local.get(
      {
        "env": {
          bot_user: "anonydog",
          webapp_url: "https://anonydog.org"
        }
      }
    )
    .then(function(stored_values) {
      var env = stored_values.env;

      if (message.type === "deflect_pr") {
        const { repo_full_name, title, body, branch } = message;

        return deflectPR(env, repo_full_name, title, body, branch)
          .catch(() => Promise.reject({error: "unknown"}));
      } else {
        return Promise.reject({error: "could not understand message"});
      }
    })
    .then((url) => ({success: "ok", url}));
  }
);


const openPR = (destUser, destRepoName, title, body, branch) => (accessToken) => {
  const requestURL = `https://api.github.com/repos/${destUser}/${destRepoName}/pulls`;
  const requestHeaders = new Headers();
  requestHeaders.append('Authorization', 'token ' + accessToken);
  requestHeaders.append('Content-Type', 'application/json');

  const requestBody = {
    title,
    body,
    head: branch,
    base: "master"
  };

  const prApiRequest = new Request(requestURL, {
    method: "POST",
    headers: requestHeaders,
    body: JSON.stringify(requestBody)
  });

  return fetch(prApiRequest)
    .then((response) => response.json())
    .then((ghJson) => ghJson.html_url)
};

var deflectPR = function(env, repo_full_name, title, body, branch) {
  const parts = repo_full_name.split('/');
  const [repo_user, repo_name] = parts;

  return request_fork(env, repo_user, repo_name)
    .then(() => open_pr(env.bot_user, repo_name, title, body, branch))
};

var request_fork = function(env, user, repo) {
  var post_data = new FormData();
  post_data.append("user", user);
  post_data.append("repo", repo);

  const opts = {
    method: "POST",
    body: post_data
  };

  return fetch(env.webapp_url + "/fork", opts);
};

var open_pr = function(dest_user, dest_repo_name, title, body, branch) {
  return getAccessToken()
    .then(openPR(dest_user, dest_repo_name, title, body, branch))
};
