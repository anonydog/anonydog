chrome.runtime.onMessage.addListener(
  function(message, sender, sendResponse) {
    browser.storage.local.get(
      {
        "env": {
          bot_user: "anonydog",
          webapp_url: "https://anonydog.org"
        }
      }
    ).
    then(function(stored_values) {
      var env = stored_values.env;
      var request_fork_request = new XMLHttpRequest();

      request_fork_request.onload = sendResponse;

      request_fork_request.open("POST", env.webapp_url + "/fork");

      var post_data = new FormData();
      post_data.append("user", message.user);
      post_data.append("repo", message.repo);

      request_fork_request.send(post_data);
    });
    return true;
  }
);
