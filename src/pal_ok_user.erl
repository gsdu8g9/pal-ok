%% ----------------------------------------------------------------------------
%% The MIT License
%%
%% Copyright (c) 2014-2015 Andrei Nesterov <ae.nesterov@gmail.com>
%%
%% Permission is hereby granted, free of charge, to any person obtaining a copy
%% of this software and associated documentation files (the "Software"), to
%% deal in the Software without restriction, including without limitation the
%% rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
%% sell copies of the Software, and to permit persons to whom the Software is
%% furnished to do so, subject to the following conditions:
%%
%% The above copyright notice and this permission notice shall be included in
%% all copies or substantial portions of the Software.
%%
%% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
%% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
%% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
%% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
%% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
%% FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
%% IN THE SOFTWARE.
%% ----------------------------------------------------------------------------

-module(pal_ok_user).
-behaviour(pal_authentication).
-behaviour(pal_workflow).

%% Workflow callbacks
-export([
	decl/0
]).

%% Authentication callbacks
-export([
	authenticate/4,
	uid/1,
	info/2
]).

%% Definitions
-define(ODNOKLASSNIKI_URI, <<"https://ok.ru">>).
-define(ODNOKLASSNIKI_API_URI, <<"https://api.ok.ru/fb.do">>).

-define(APPLICATION_KEY, <<"application_key">>).
-define(ACCESS_TOKEN, <<"access_token">>).
-define(METHOD, <<"method">>).
-define(METHOD_VAL, <<"users.getCurrentUser">>).
-define(SIG, <<"sig">>).
-define(FIELDS, <<"fields">>).
%% Fields sorted by alphabet
-define(FIELDS_VAL, <<"birthday,email,first_name,gender,last_name,name,pic50x50,uid">>).

-define(UID, <<"uid">>).
-define(NAME, <<"name">>).
-define(FIRST_NAME, <<"first_name">>).
-define(LAST_NAME, <<"last_name">>).
-define(BIRTHDAY , <<"birthday">>).
-define(PIC50X50, <<"pic50x50">>).
-define(GENDER, <<"gender">>).
-define(MALE, <<"male">>).
-define(FEMALE, <<"female">>).
-define(OTHER, <<"other">>).
-define(EMAIL, <<"email">>).
-define(ERROR_CODE, <<"error_code">>).

%% Types
-type data() :: #{access_token => binary()}.

%% ============================================================================
%% Workflow callbacks
%% ============================================================================

-spec decl() -> pal_workflow:declaration().
decl() ->
	Opts =
		#{request_options => [{follow_redirect, true}]},

	{pal_authentication, ?MODULE, Opts}.

%% ============================================================================
%% Authentication callbacks
%% ============================================================================

-spec authenticate(list(module()), data(), map(), map()) -> pal_authentication:result().
authenticate(Hs, #{access_token := Token} = Data, Meta, State) ->
	#{client_secret := Secret,
		application_key := AppKey,
		request_options := ReqOpts} = State,

	Prefix =
		<<?APPLICATION_KEY/binary, $=, AppKey/binary,
			?FIELDS/binary, $=, ?FIELDS_VAL/binary,
			?METHOD/binary, $=, ?METHOD_VAL/binary>>,
	Hash = hexstr(crypto:hash(md5, <<Token/binary, Secret/binary>>)),
	Sig = hexstr(crypto:hash(md5, <<Prefix/binary, Hash/binary>>)),

	Uri =
		<<?ODNOKLASSNIKI_API_URI/binary,
				$?, ?APPLICATION_KEY/binary, $=, AppKey/binary,
				$&, ?ACCESS_TOKEN/binary, $=, Token/binary,
				$&, ?METHOD/binary, $=, ?METHOD_VAL/binary,
				$&, ?FIELDS/binary, $=, ?FIELDS_VAL/binary,
				$&, ?SIG/binary, $=, Sig/binary>>,

	case hackney:get(Uri, [], <<>>, ReqOpts) of
		{ok, 200, _, Ref} ->
			{ok, Body} = hackney:body(Ref),
			L = jsx:decode(Body),
			%% NOTE: status code 200 on error response
			case pt_kvlist:find(?ERROR_CODE, L) of
				error -> {ok, L};
				_     -> {error, {odnoklassniki, L}}
			end;
		{ok, _, _, Ref} ->
			{ok, Body} = hackney:body(Ref),
			{error, {odnoklassniki, Body}};
		{error, Reason} ->
			exit({Reason, {?MODULE, authenticate, [Hs, Data, Meta, State]}})
	end.

-spec uid(pal_authentication:rawdata()) -> binary().
uid(Data) ->
	pt_kvlist:get(?UID, Data).

-spec info(pal_authentication:rawdata(), map()) -> map().
info([{?UID, Val}|T], M)        -> info(T, M#{uri => uri(Val)});
info([{?NAME, Val}|T], M)       -> info(T, M#{name => Val});
info([{?FIRST_NAME, Val}|T], M) -> info(T, M#{first_name => Val});
info([{?LAST_NAME, Val}|T], M)  -> info(T, M#{last_name => Val});
info([{?EMAIL, Val}|T], M)      -> info(T, M#{email => Val});
info([{?GENDER, Val}|T], M)     -> info(T, M#{gender => Val});
info([{?BIRTHDAY, Val}|T], M)   -> info(T, M#{birthday => Val});
info([{?PIC50X50, Val}|T], M)   -> info(T, M#{image => image(Val)});
info([_|T], M)                  -> info(T, M);
info([], M)                     -> M.

%% ============================================================================
%% Internal functions
%% ============================================================================
-spec uri(binary()) -> binary().
uri(UID) ->
	<<?ODNOKLASSNIKI_URI/binary, "/profile/", UID/binary>>.

-spec image(binary()) -> binary().
image(Uri) ->
	%% NOTE: It's always better to have a secure URI
	re:replace(Uri, <<"^http">>, <<"https">>, [{return, binary}]).

-spec hexstr(binary()) -> binary().
hexstr(Val) ->
	hexstr(Val, <<>>).

-spec hexstr(binary(), binary()) -> binary().
hexstr(<<Val, Rest/binary>>, Acc) ->
  H = hex(Val bsr 4),
  L = hex(Val band 16#0f),
  hexstr(Rest, <<Acc/binary, H, L>>);
hexstr(<<>>, Acc) ->
  Acc.

-spec hex(0..15) -> byte().
hex(0)  -> $0;
hex(1)  -> $1;
hex(2)  -> $2;
hex(3)  -> $3;
hex(4)  -> $4;
hex(5)  -> $5;
hex(6)  -> $6;
hex(7)  -> $7;
hex(8)  -> $8;
hex(9)  -> $9;
hex(10) -> $a;
hex(11) -> $b;
hex(12) -> $c;
hex(13) -> $d;
hex(14) -> $e;
hex(15) -> $f.
