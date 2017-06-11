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

var send_pr = function() {
  // TODO: we're assuming this meta tag contains repo_user/repo_name. Test for that
  var repo_full_name = document.head.querySelector('meta[name="octolytics-dimension-repository_nwo"]').content,
      parts = repo_full_name.split('/'),
      repo_user = parts[0],
      repo_name = parts[1];

  console.log(`Detected PR to ${repo_full_name}`);
  console.log(`Will ask for a fork of user ${repo_user}'s repo ${repo_name}`);
  console.log(`Will deflect PR to anonydog/${repo_name}`);
};

document.querySelector("#anonydog-pr").addEventListener("click", send_pr);
