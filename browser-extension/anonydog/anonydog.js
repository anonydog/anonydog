//need to:
// * actually send the PR to anonydog

//known issues:
// * does not render well in chrome
// * sometimes the querySelector returns null
// * adds a permanent marker in chrome (shows in every tab. even outside github)

var github_pr_button = document.querySelector("form#new_pull_request div.form-actions button[type=submit]");

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

  console.log(`Detected PR to ${repo_full_name}`);
  console.log(`Will ask for a fork of user ${repo_user}'s repo ${repo_name}`);
  console.log(`Will deflect PR to anonydog/${repo_name}`);
  
  //FIXME: "arraisbot" is hardcoded. need someway to switch between dev/staging/prod
  open_pr("arraisbot", repo_name);
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
  var orig_branch = "thiagoarrais:patch-1", //FIXME: need to read this from somewhere
      compare_page_url = `https://github.com/${dest_user}/${dest_repo_name}/compare/master...${orig_branch}`;

  compare_page_request.open("GET", compare_page_url);
  compare_page_request.responseType = "document";
  
  compare_page_request.send();
}

document.querySelector("#anonydog-pr").addEventListener("click", deflect_pr);
