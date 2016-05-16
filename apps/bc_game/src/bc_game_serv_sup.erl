%%%-------------------------------------------------------------------
%% @doc bc_game_serv_sup top level supervisor.
%% @end
%%%-------------------------------------------------------------------

-module(bc_game_serv_sup).
-behaviour(supervisor).

%% API
-export([start_link/0]).

%% Supervisor callbacks
-export([init/1]).

%%====================================================================
%% API functions
%%====================================================================

start_link() ->
	supervisor:start_link({local, ?MODULE}, ?MODULE, []).

%%====================================================================
%% Supervisor callbacks
%%====================================================================

%% Child :: {Id,StartFunc,Restart,Shutdown,Type,Modules}
init([]) ->
	BcGameSup = bc_game_sup:start_link(),
	{ok, {
		{one_for_all, 0, 1}, 
			[#{
			   id => bc_game_serv_sup,
			   start => {bc_game_serv, start_link, [BcGameSup]},
			   modules => [bc_game_serv]
			}]
		}}.

%%====================================================================
%% Internal functions
%%====================================================================
