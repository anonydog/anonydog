function saveOptions(e) {
  e.preventDefault();
  browser.storage.local.set({
    env: {
      bot_user: document.querySelector("#bot_user").value,
      webapp_url: document.querySelector("#webapp_url").value
    }
  });
}

function restoreOptions() {

  function setCurrentChoice(result) {
    document.querySelector("#bot_user").value = result.bot_user || "anonydog";
    document.querySelector("#webapp_url").value = result.webapp_url || "http://anonydog.org";
  }

  function onError(error) {
    console.log(`Error: ${error}`);
  }

  var getting = browser.storage.local.get("env");
  getting.then(setCurrentChoice, onError);
}

document.addEventListener("DOMContentLoaded", restoreOptions);
document.querySelector("form").addEventListener("submit", saveOptions);