//need to:
// * actually send the PR to anonydog

//known issues:
// * does not render well in chrome
// * sometimes the querySelector returns null
// * adds a permanent marker in chrome (shows in every tab. even outside github)

var waitFor = function(selector, operation) {
  if (null != document.body.querySelector(selector)) {
    operation(document.body.querySelector(selector));
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

waitFor(
  "form#new_pull_request div.form-actions button[type=submit]",
  function(github_pr_button) {
    github_pr_button.classList.remove("btn-primary");

    var our_button_html = `
      <button id="anonydog-pr" class="btn btn-primary" type="button">
        Create anonymous pull request
        <img
          src="https://avatars3.githubusercontent.com/u/24738062?v=3&s=16"
          style="margin-left: 3px"
          width="16"
          height="16" />
      </button>
    `;
    github_pr_button.insertAdjacentHTML("beforebegin", our_button_html);

    var deflect_pr = function() {
      // TODO: we're assuming this meta tag contains repo_user/repo_name. Test for that
      var repo_full_name = document.head.querySelector('meta[name="octolytics-dimension-repository_nwo"]').content,
          parts = repo_full_name.split('/'),
          repo_user = parts[0],
          repo_name = parts[1];

      console.log(`Will deflect PR to anonydog/${repo_name}`);

      request_fork(repo_user, repo_name, function() {
        //FIXME: repo creation is async. open_pr may have no URL to post to
        //FIXME: "arraisbot" is hardcoded. need someway to switch between dev/staging/prod
        open_pr("arraisbot", repo_name);
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

      request_fork_request.open("POST", "http://webapp.dev.anonydog.org/fork"); //FIXME: hardcoded
      
      var post_data = new FormData();
      post_data.append("user", user);
      post_data.append("repo", repo);
      
      //request_fork_request.setRequestHeader('Content-type', 'application/x-www-form-urlencoded');

      request_fork_request.send(post_data);
    };

    var open_pr = function(dest_user, dest_repo_name) {
      var compare_page_request = new XMLHttpRequest();
      compare_page_request.onload = function() {
        // reference to document assumes we're on the original pull request page
        var orig_form = document.body.querySelector("#new_pull_request");
        var dest_form = this.responseXML.querySelector("#new_pull_request");

        dest_form.elements.namedItem("pull_request[title]").value = orig_form.elements.namedItem("pull_request[title]").value;
        dest_form.elements.namedItem("pull_request[body]").value = orig_form.elements.namedItem("pull_request[body]").value;

        var form_data = new FormData(dest_form);

        var create_pr_request = new XMLHttpRequest();

        create_pr_request.onload = function() {
          window.location.replace(create_pr_request.responseURL);
        };

        create_pr_request.open("POST", dest_form.action);
        create_pr_request.send(form_data);
      }
      var orig_branch = headBranchNameFrom(document.body.querySelector("#new_pull_request").action),
          compare_page_url = `https://github.com/${dest_user}/${dest_repo_name}/compare/master...${orig_branch}`;

      compare_page_request.open("GET", compare_page_url);
      compare_page_request.responseType = "document";

      compare_page_request.send();
    };

    document.querySelector("#anonydog-pr").addEventListener("click", deflect_pr);
  }
);