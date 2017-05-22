//need to:
// * actually send the PR to anonydog

//known issues:
// * does not render well in chrome
// * sometimes the querySelector returns null
// * adds a permanent marker in chrome (shows in every tab. even outside github)

var github_pr_button = document.querySelector("form#new_pull_request div.form-actions button[type=submit]");

github_pr_button.classList.remove("btn-primary");

var our_button_html = `
  <button class="btn btn-primary">
    Create anonymous pull request
    <img
      src="https://avatars3.githubusercontent.com/u/24738062?v=3&s=16"
      style="margin-left: 3px"
      width="16"
      height="16" />
  </button>
`;
github_pr_button.insertAdjacentHTML("beforebegin", our_button_html);

document.body.style.border = "5px solid red";
