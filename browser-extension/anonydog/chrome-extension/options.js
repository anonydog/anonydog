function saveOptions(e) {
  e.preventDefault();
  const env = {
    bot_user: document.querySelector("#bot_user").value,
    webapp_url: document.querySelector("#webapp_url").value
  };
  browser.storage.local.set({env});
}

function restoreOptions() {

  function setCurrentChoice(result) {
    document.querySelector("#bot_user").value = result.env.bot_user || "anonydog";
    document.querySelector("#webapp_url").value = result.env.webapp_url || "https://anonydog.org";
  }

  function onError(error) {
    console.log(`Error: ${error}`);
  }

  var getting = browser.storage.local.get("env");
  getting.then(setCurrentChoice, onError);
}

document.addEventListener("DOMContentLoaded", restoreOptions);
document.querySelector("form").addEventListener("submit", saveOptions);
