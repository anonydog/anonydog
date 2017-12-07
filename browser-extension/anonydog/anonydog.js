var pr_button_html = `<div class="js-merge-pr js-pull-merging merge-pr is-merging" data-url="/bogus" style="block-size: 0px; border-top: 0px none; height: 0px; margin-top: 0px; padding-top: 0px;">
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
              <span class="description">Pull request will be sent via anonydog. It may not be elected for anonymization.</span>
            </div>
          </div>

          <div class="select-menu-item js-navigation-item" role="menuitem" data-input-title-value="testing pr anonymization (#52)" data-input-message-value="" id="anonydog-traditional-pr-option">
            <svg aria-hidden="true" class="octicon octicon-check select-menu-item-icon" height="16" version="1.1" viewBox="0 0 12 16" width="12"><path fill-rule="evenodd" d="M12 5l-8 8-4-4 1.5-1.5L4 10l6.5-6.5z"></path></svg>
            <input class="js-merge-method" name="do" type="radio" value="squash" id="github-pr-check">
            <div class="select-menu-item-text">
              <span class="select-menu-item-heading js-select-button-text">Create traditional pull request</span>
              <span class="description">
                    Pull request will be sent using you usual GitHub handle. For sure.
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</div>`;

var createElement = function(html) {
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

var augmentPullRequestPage = function(github_pr_button, env) {
  var pr_button_elem = createElement(pr_button_html);

  github_pr_button.replaceWith(pr_button_elem);

  var deflect_pr = function() {
    // TODO: we're assuming this meta tag contains repo_user/repo_name. Test for that
    var repo_full_name = document.head.querySelector('meta[name="octolytics-dimension-repository_nwo"]').content,
        parts = repo_full_name.split('/'),
        repo_user = parts[0],
        repo_name = parts[1];

    request_fork(repo_user, repo_name, function() {
      open_pr(env.bot_user, repo_name);
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

  var request_fork = function(user, repo, callback) {
    var request_fork_request = new XMLHttpRequest();

    request_fork_request.onload = function() {
      callback();
    };

    request_fork_request.open("POST", env.webapp_url + "/fork");

    var post_data = new FormData();
    post_data.append("user", user);
    post_data.append("repo", repo);

    request_fork_request.send(post_data);
  };

  var open_pr = function(dest_user, dest_repo_name) {
    var compare_page_request = new XMLHttpRequest(),
        compare_page_notfound = function() {
          //the bot probably didn't create the anonymizing repo yet. wait a second and retry
          //TODO: this isn't very clean. what should we do here? can we avoid getting to this state?
          setTimeout(function() { open_pr(dest_user, dest_repo_name); }, 1000);
        },
        compare_page_ok = function() {
          // reference to document assumes we're on the original pull request page
          var orig_form = document.body.querySelector("#new_pull_request");
          var dest_form = compare_page_request.responseXML.querySelector("#new_pull_request");

          dest_form.elements.namedItem("pull_request[title]").value = orig_form.elements.namedItem("pull_request[title]").value;
          dest_form.elements.namedItem("pull_request[body]").value = orig_form.elements.namedItem("pull_request[body]").value;

          var form_data = new FormData(dest_form);

          var create_pr_request = new XMLHttpRequest();

          create_pr_request.onload = function() {
            window.location.replace(create_pr_request.responseURL);
          };

          create_pr_request.open("POST", dest_form.action);
          create_pr_request.send(form_data);
        };

    compare_page_request.onreadystatechange = function() {
      if (compare_page_request.readyState === XMLHttpRequest.DONE && compare_page_request.status === 200) {
        compare_page_ok();
      } else if (compare_page_request.readyState === XMLHttpRequest.DONE && compare_page_request.status === 404) {
        compare_page_notfound();
      }
    };

    var orig_branch = headBranchNameFrom(document.body.querySelector("#new_pull_request").action),
        compare_page_url = `https://github.com/${dest_user}/${dest_repo_name}/compare/master...${orig_branch}`;

    compare_page_request.open("GET", compare_page_url);
    compare_page_request.responseType = "document";

    compare_page_request.send();
  };

  //document.querySelector("#anonydog-pr").addEventListener("click", deflect_pr);
};

waitFor(
  "form#new_pull_request div.form-actions button[type=submit]",
  function(github_pr_button) {
    browser.storage.local.get(
      {
        "env": {
          bot_user: "anonydog",
          webapp_url: "http://anonydog.org"
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
