/* exported getAccessToken */

const REDIRECT_URL = browser.identity.getRedirectURL();
const CLIENT_ID = "92e28d0045609221a09d"; //FIXME: bogus id. change (and store somewhere safe?)
const CLIENT_SECRET = "a7fdfab8c5e2d0d8dd6c32c9ea5dc9e89298bad8"; //FIXME: bogus secret. change (and definetely store somewhere safe)
const SCOPES = ["user", "repo"];
const AUTH_URL =
`https://github.com/login/oauth/authorize?client_id=${CLIENT_ID}&redirect_uri=${encodeURIComponent(REDIRECT_URL)}&scope=${encodeURIComponent(SCOPES.join(' '))}`;
const VALIDATION_BASE_URL=`https://github.com/login/oauth/access_token`;

function extractCode(redirectUri) {
  let m = redirectUri.match(/[#?](.*)/);
  if (!m || m.length < 1)
    return null;
  let params = new URLSearchParams(m[1].split("#")[0]);
  return params.get("code");
}

/**
Validate the token contained in redirectURL.
This follows essentially the process here:
https://developers.google.com/identity/protocols/OAuth2UserAgent#tokeninfo-validation
- make a GET request to the validation URL, including the access token
- if the response is 200, and contains an "aud" property, and that property
matches the clientID, then the response is valid
- otherwise it is not valid

Note that the Google page talks about an "audience" property, but in fact
it seems to be "aud".
*/
function validate(redirectURL) {
  const code = extractCode(redirectURL);
  if (!code) {
    throw "Authorization failure";
  }
  const validationURL = `${VALIDATION_BASE_URL}`;
  const requestHeaders = new Headers();
  requestHeaders.append('Accept', 'application/json');
  requestHeaders.append('Content-Type', 'application/json');
  const validationRequest = new Request(validationURL, {
    method: "POST",
    headers: requestHeaders,
    body: JSON.stringify({
      client_id: CLIENT_ID,
      client_secret: CLIENT_SECRET,
      code
    })
  });

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

  return fetch(validationRequest).then(checkResponse);
}

/**
Authenticate and authorize using browser.identity.launchWebAuthFlow().
If successful, this resolves with a redirectURL string that contains
an access token.
*/
function authorize() {
  return browser.identity.launchWebAuthFlow({
    interactive: true,
    url: AUTH_URL
  });
}

function getAccessToken() {
  return authorize().then(validate);
}
