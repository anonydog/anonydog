/* exported getAccessToken */

const REDIRECT_URL = browser.identity.getRedirectURL();
const CLIENT_ID = {
  "Firefox" : "f036b9db6ca8625de48c",
  "Chrome"  : "3166dac17185933355e5"
};
const VALIDATION_URL = {
  "Firefox": "https://anonydog-auth-firefox.glitch.me/",
  "Chrome": "https://anonydog-auth-chrome.glitch.me/"
};

const SCOPES = ["user", "repo"];
const AUTH_URL = (clientID, redirectURL, scopes) => (
  `https://github.com/login/oauth/authorize?client_id=${clientID}&redirect_uri=${encodeURIComponent(redirectURL)}&scope=${encodeURIComponent(scopes.join(' '))}`
);

function extractCode(redirectUri) {
  let m = redirectUri.match(/[#?](.*)/);
  if (!m || m.length < 1)
    return null;
  let params = new URLSearchParams(m[1].split("#")[0]);
  return params.get("code");
}

function validate(redirectURL) {
  const code = extractCode(redirectURL);
  if (!code) {
    throw "Authorization failure";
  }
  const requestHeaders = new Headers();
  requestHeaders.append('Accept', 'application/json');
  requestHeaders.append('Content-Type', 'application/json');
  const validationRequest = (browserName) => {
    const validationURL = VALIDATION_URL[browserName];

    return new Request(validationURL, {
      method: "POST",
      headers: requestHeaders,
      body: JSON.stringify({
        code
      })
    });
  };

  function checkResponse(response) {
    return new Promise((resolve, reject) => {
      if (response.status != 200) {
        reject("Token validation error");
      }
      response.json().then((json) => {
        if (json.access_token) {
          resolve(json.access_token);
        } else {
          reject("Token validation error");
        }
      });
    });
  }

  return currentBrowserName()
    .then((name) => fetch(validationRequest(name)))
    .then(checkResponse);
}

function currentBrowserName() {
  if (!browser.runtime.getBrowserInfo) {
    // assume we're in Chrome since the Firefox API isn't available
    return Promise.resolve("Chrome");
  } else {
    return browser.runtime.getBrowserInfo()
      .then(({name}) => name);
  }
}

function authURLForCurrentBrowser() {
  return currentBrowserName()
    .then((name) => {
      const url = AUTH_URL(CLIENT_ID[name], REDIRECT_URL, SCOPES);
      return url;
    });
}

/**
Authenticate and authorize using browser.identity.launchWebAuthFlow().
If successful, this resolves with a redirectURL string that contains
an access token.
*/
function authorize() {
  return authURLForCurrentBrowser()
    .then((authURL) => (
      browser.identity.launchWebAuthFlow({
        interactive: true,
        url: authURL
      })
    ));
}

function getAccessToken() {
  return authorize().then(validate);
}
