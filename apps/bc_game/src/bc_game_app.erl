%%%-------------------------------------------------------------------
%% @doc bc_game public API
%% @end
%%%-------------------------------------------------------------------

-module(bc_game_app).
-behaviour(application).

%% Application callbacks
-export([start/2
        ,stop/1]).

%%====================================================================
%% API
%%====================================================================

start(_StartType, _StartArgs) ->
	bc_game:init_model(),
    bc_game_serv_sup:start_link().

%%--------------------------------------------------------------------
stop(_State) ->
    ok.

%%====================================================================
%% Internal functions
%%====================================================================
