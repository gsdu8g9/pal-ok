# Pragmatic Authentication Library: OK (Odnoklassniki) workflows

Collection of OK workflows for [PAL][pal].

### 1. OK Login (OAuth2 Authorization Code Grant) workflow

For details, read the OK [documentation][ok-oauth2-doc].

#### Options

You can configure the workflow by passing options below into `pal:new/2` or `pal:group/2` functions:

- `client_id` (required) -
		The client ID obtained from the email after the application would be created.
- `client_secret` (required) -
		The client secret obtained from the email after the application would be created.
- `redirect_uri` (required) -
		The client redirection endpoint.
		After completing its interaction with the resource owner,
		the authorization server directs the resource owner's user-agent to this uri.
- `scope` (optional) -
		A list of requested [permissions][ok-oauth2-scope].
- `request_options` (optional) -
		Options for the [hackney][hackney] HTTP client.
- `includes` (optional) -
		Parts of authentication schema to be processed by this workflow.
		All by default, `[uid, credentials, info, extra, rules]`.

Application can be created on [that][ok-app-dashboard] page.

#### Input Data

- `code` -
		The authorization code.
- `state` -
		The state previously passed to the authentication provider.
- `error`
		When request fails due to a missing, invalid, or mismatching
		redirection URI, or if the client identifier is missing or invalid.

#### Authentication Schema

An successful execution of `pal:authenticate/{2,3}` function returns
the authentication schema below.

```erlang
#{access_token => <<"...">>,
  token_type => <<"session">>,
  refresh_token => <<"...">>,
  expires_in => 1800}
```

See a complete example with PAL and [Cowboy][cowboy] HTTP server [here][pal-example].

### 2. OK User (user's profile data) workflow

#### Options

You can configure the workflow by passing options below into `pal:new/2` or `pal:group/2` functions:

- `application_key` (required) -
		The application key obtained from the email after the application would be created.
- `request_options` (optional) -
		Options for the [hackney][hackney] HTTP client.
- `includes` (optional) -
		Parts of authentication schema to be processed by this workflow.
		All by default, `[uid, credentials, info, extra, rules]`.

Application can be created on [that][ok-app-dashboard] page.

#### Input Data

- `access_token` -
		The access token obtained using the `pal_ok_oauth2_authcode` workflow.

#### Authentication Schema

An successful execution of `pal:authenticate/{2,3}` function returns
the authentication schema below.

```erlang
#{uid => <<"...">>,
  info =>
    #{name => <<"John Doe">>,
      first_name => <<"John">>,
      last_name => <<"Doe">>,
      gender => <<"male">>,
      email => <<"john@example.com">>,
      image => <<"https://i508.mycdn.me/image...">>,
      uri => <<"https://ok.ru/profile...">>}}
```

See a complete example with PAL and [Cowboy][cowboy] HTTP server [here][pal-example].

### License

The source code is provided under the terms of [the MIT license][license].

[license]:http://www.opensource.org/licenses/MIT
[cowboy]:https://github.com/extend/cowboy
[ok-oauth2-doc]:http://apiok.ru/wiki/pages/viewpage.action?pageId=81822109
[ok-oauth2-scope]:http://apiok.ru/wiki/pages/viewpage.action?pageId=81822097
[ok-app-dashboard]:http://ok.ru/dk?st.cmd=appsInfoMyDevList&st._aid=Apps_Info_MyDev&st._aid=Apps_Info_MyDev
[hackney]:https://github.com/benoitc/hackney
[pal]:https://github.com/manifest/pal
[pal-example]:https://github.com/manifest/pal-example

