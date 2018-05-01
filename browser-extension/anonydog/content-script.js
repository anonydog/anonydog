var createPullRequestButtonElement = function() {
  const html = `<div class="js-merge-pr js-pull-merging merge-pr is-merging" data-url="/bogus" style="block-size: 0px; border-top: 0px none; height: 0px; margin-top: 0px; padding-top: 0px;">
    <div class="select-menu d-inline-block js-menu-container js-select-menu js-transitionable" style="float: right; box-sizing: content-box; display: block; visibility: visible;" id="anonydog-select-menu">
      <div style="display: none">
        <input type="text" class="js-merge-title" />
        <textarea class="js-merge-message" >
        </textarea>
      </div>

      <div class="BtnGroup btn-group-merge">
        <button type="button" class="btn btn-primary BtnGroup-item js-details-target" aria-expanded="false" data-details-container=".js-merge-pr" style="float: none" id="anonydog-pr-button">
          Create anonymous pull request
        </button><button class="btn btn-primary select-menu-button BtnGroup-item js-menu-target" style="float: none" type="button" aria-label="Select merge method" aria-haspopup="true" aria-expanded="false"></button>
      </div>
      <div class="BtnGroup btn-group-squash">
        <button type="submit" class="btn btn-primary BtnGroup-item js-details-target" aria-expanded="false" data-details-container=".js-merge-pr" style="float: none" id="github-pr-button">
          Create pull request
        </button><button class="btn btn-primary select-menu-button BtnGroup-item js-menu-target" style="float: none" type="button" aria-label="Select merge method" aria-haspopup="true" aria-expanded="false"></button>
      </div>

      <div class="select-menu-modal-holder">
        <div class="select-menu-modal select-menu-merge-method js-menu-content" aria-expanded="false">
          <div class="select-menu-list js-navigation-container js-merge-method-menu js-active-navigation-container" role="menu">
            <div class="select-menu-item js-navigation-item selected" role="menuitem" data-input-title-value="Merge pull request #52 from arraisbot/pullrequest-8fc7c3fd3" data-input-message-value="testing pr anonymization" id="anonydog-anonymous-pr-option">
              <svg aria-hidden="true" class="octicon octicon-check select-menu-item-icon" height="16" version="1.1" viewBox="0 0 12 16" width="12"><path fill-rule="evenodd" d="M12 5l-8 8-4-4 1.5-1.5L4 10l6.5-6.5z"></path></svg>
              <input checked="checked" class="js-merge-method" name="do" type="radio" value="merge" id="anonydog-pr-check">
              <div class="select-menu-item-text">
                <span class="select-menu-item-heading js-select-button-text">Create anonymous pull request</span>
                <span class="description">
                  Pull request will be anonymized and sent via <strong>anonydog</strong>.
                </span>
              </div>
            </div>

            <div class="select-menu-item js-navigation-item" role="menuitem" data-input-title-value="testing pr anonymization (#52)" data-input-message-value="" id="anonydog-traditional-pr-option">
              <svg aria-hidden="true" class="octicon octicon-check select-menu-item-icon" height="16" version="1.1" viewBox="0 0 12 16" width="12"><path fill-rule="evenodd" d="M12 5l-8 8-4-4 1.5-1.5L4 10l6.5-6.5z"></path></svg>
              <input class="js-merge-method" name="do" type="radio" value="squash" id="github-pr-check">
              <div class="select-menu-item-text">
                <span class="select-menu-item-heading js-select-button-text">Create traditional pull request</span>
                <span class="description">
                      Pull request will be sent using your normal GitHub handle.
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>`;

  var el = document.createElement('div');
  el.innerHTML = html;
  return el.childNodes[0];
};

var waitFor = function(selector, operation) {
  if (null != document.body.querySelector(selector)) {
    operation(document.body.querySelector(selector));
    return;
  }

  var observer = new MutationObserver(function(mutations) {
    mutations.forEach(function(mutation) {
      mutation.addedNodes.forEach(function(node) {
        //TODO: there is a pontential bug here because the base element is not returned
        //see https://developer.mozilla.org/en-US/docs/Web/API/Element/querySelectorAll
        if (node.querySelector && null != node.querySelector(selector)) {
          observer.disconnect();
          operation(node.querySelector(selector));
        }
      });
    });
  });

  //TODO: this is straight from SO. I guess it can use some optmizing...
  observer.observe(document.body, {
      childList: true
    , subtree: true
    , attributes: false
    , characterData: false
  });

};

var headBranchNameFrom = function(url) {
  //TODO: maybe use https://www.npmjs.com/package/query-string
  var query = url.split("?")[1];
  var entries = query.split("&").
    map(function(pair_str) {
      return pair_str.split("=").map(decodeURIComponent);
    }).
    map(function(entry_arr) {
      return {
        key: entry_arr[0],
        value: entry_arr[1]
      };
    });

  var head_entry_arr = entries.filter(function(entry) {
    return entry.key == "head";
  });

  var head_entry = head_entry_arr[0];

  return head_entry.value;
};

const deflectPR = () => {
  const orig_form = document.body.querySelector("#new_pull_request");

  const params = {
    // TODO: we're assuming this meta tag contains repo_user/repo_name. Test for that
    repo_full_name: document.head.querySelector('meta[name="octolytics-dimension-repository_nwo"]').content,
    title: orig_form.elements.namedItem("pull_request[title]").value,
    body: orig_form.elements.namedItem("pull_request[body]").value,
    branch: headBranchNameFrom(orig_form.action)
  };

  const anonydog_pr_button = document.querySelector("#anonydog-pr-button");
  const body_cursor = document.body.style.cursor;
  const pr_button_cursor = anonydog_pr_button.style.cursor;
  //visual cue that we're working
  document.body.style.cursor = "wait";
  anonydog_pr_button.style.cursor = "wait";

  //pokes background script to do the work
  chrome.runtime.sendMessage({
    type: "deflect_pr",
    ...params
  },
  function(response) {
    if (response.success) {
      window.location.replace(response.url);
    } else {
      document.body.style.cursor = body_cursor;
      anonydog_pr_button.style.cursor = pr_button_cursor;
      alert("We're experiencing some connectivity problems. Please try again later.");
    }
  });
};

var augmentPullRequestPage = function(github_pr_button, env) {
  if (document.querySelector("#anonydog-pr-button")) {
    //code already run sometime in the past. abort.
    return;
  }

  var pr_button_elem = createPullRequestButtonElement();

  github_pr_button.replaceWith(pr_button_elem);

  var anonydog_pr_button = document.querySelector("#anonydog-pr-button");
  var github_pr_button = document.querySelector("#github-pr-button");

  var traditional_pr = () => document.querySelector("form#new_pull_request").submit();

  anonydog_pr_button.addEventListener("click", deflectPR);
  github_pr_button.addEventListener("click", traditional_pr);
};

waitFor(
  "form#new_pull_request div.form-actions button[type=submit]",
  function(github_pr_button) {
    browser.storage.local.get(
      {
        "env": {
          bot_user: "anonydog",
          webapp_url: "https://anonydog.org"
        }
      }
    ).
    then(function(stored_values) {
      augmentPullRequestPage(github_pr_button, stored_values.env);
    },
    function () {
      console.log("anonydog could not retrieve env. panicking.")
    });
  }
);
