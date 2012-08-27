%%
%% %CopyrightBegin%
%% 
%% Copyright Saravanan Vijayakumaran 2012. All Rights Reserved.
%% 
%% %CopyrightEnd%
%%

%% Purpose : Scheduler module based on gb_trees
%% Author : Saravanan Vijayakumaran

-module(nsime_gbtrees_scheduler).
-author("Saravanan Vijayakumaran").

-export([create/0, stop/0, is_empty/0]).
-export([insert/1, remove/1, remove_next/0, get_event_queue/0]).
-export([loop/1]).

-include("nsime_types.hrl").
-include("nsime_event.hrl").

-behaviour(nsime_scheduler).

create() ->
    EventQueue = gb_trees:empty(),
    register(?MODULE, spawn_link(?MODULE, loop, [EventQueue])).

insert(Event = #nsime_event{}) ->
    Ref = make_ref(),
    ?MODULE ! {insert, self(), Event, Ref},
    receive
        {ok, Ref} -> ok
    end.

is_empty() ->
    Ref = make_ref(),
    ?MODULE ! {is_empty, self(), Ref},
    receive
      {is_empty, IsEmpty, Ref} ->
          IsEmpty
    end.

remove(Event=#nsime_event{}) ->
    Ref = make_ref(),
    ?MODULE ! {remove, self(), Event, Ref},
    receive
        {ok, Ref} -> 
            ok;
        {none, Ref} ->
            none
    end.

remove_next() ->
    Ref = make_ref(),
    ?MODULE ! {remove_next, self(), Ref},
    receive
        {event, Event, Ref} ->
            Event;
        {none, Ref} ->
            none
    end.

stop() ->
    process_flag(trap_exit, true),
    Pid = whereis(?MODULE),
    exit(Pid, kill),
    receive
        {'EXIT', Pid, Reason} ->
            Reason
    end.

get_event_queue() ->
    Ref = make_ref(),
    ?MODULE ! {get_event_queue, self(), Ref},
    receive 
        {event_queue, EventQueue, Ref} -> EventQueue
    end.

loop(EventQueue) ->
    receive
        {is_empty, From, Ref} ->
            From ! {is_empty, gb_trees:is_empty(EventQueue), Ref},
            loop(EventQueue);
        {insert, From, Event = #nsime_event{time = Time}, Ref} ->
            case gb_trees:lookup(nsime_time:value(Time), EventQueue) of
                none -> 
                    NewEventQueue = gb_trees:insert(nsime_time:value(Time), [Event], EventQueue),
                    From ! {ok, Ref},
                    loop(NewEventQueue);
                {value, ExistingEvents} ->
                    NewEventQueue = gb_trees:update(nsime_time:value(Time), [Event | ExistingEvents], EventQueue),
                    From ! {ok, Ref},
                    loop(NewEventQueue)
            end;
        {get_event_queue, From, Ref} ->
            From ! {event_queue, EventQueue, Ref},
            loop(EventQueue);
        {remove_next, From, Ref} -> 
            case gb_trees:is_empty(EventQueue) of
                false ->
                    {Time, [FirstEvent | RemainingEvents], NewEventQueue} = gb_trees:take_smallest(EventQueue),
                    case RemainingEvents of 
                        [] ->
                            From ! {event, FirstEvent, Ref},
                            loop(NewEventQueue);
                        _ ->
                            NewerEventQueue = gb_trees:insert(Time, RemainingEvents, NewEventQueue),
                            From ! {event, FirstEvent, Ref},
                            loop(NewerEventQueue)
                    end;
                true ->
                    From ! {none, Ref},
                    loop(EventQueue)
            end;
        {remove, From, Event = #nsime_event{time = Time}, Ref} -> 
            case gb_trees:is_empty(EventQueue) of
                false ->
                    case gb_trees:lookup(nsime_time:value(Time), EventQueue) of
                        none -> 
                            From ! {none, Ref},
                            loop(EventQueue);
                        {value, ExistingEvents} ->
                            NewEvents = lists:delete(Event, ExistingEvents),
                            case length(NewEvents) of
                                0 -> 
                                    NewEventQueue = gb_trees:delete(nsime_time:value(Time), EventQueue),
                                    From ! {ok, Ref},
                                    loop(NewEventQueue);
                                _ ->
                                    NewEventQueue = gb_trees:update(nsime_time:value(Time), NewEvents, EventQueue),
                                    From ! {ok, Ref},
                                    loop(NewEventQueue)
                            end
                    end;
                true ->
                    From ! {none, Ref},
                    loop(EventQueue)
            end
    end.
