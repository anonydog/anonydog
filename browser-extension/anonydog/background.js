chrome.webNavigation.onHistoryStateUpdated.addListener(function(details) {
    chrome.tabs.executeScript(null,{file:"content-script.js"});
});

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

      var post_data = new FormData();
      post_data.append("user", message.user);
      post_data.append("repo", message.repo);

      const opts = {
        method: "POST",
        body: post_data
      };
      fetch(env.webapp_url + "/fork", opts).
      then(
        function(e) {
          sendResponse({"success": "ok"});
        }
      ).catch(
        function(e) {
          sendResponse({"error": e.message});
        }
      );
    });
    return true;
  }
);
