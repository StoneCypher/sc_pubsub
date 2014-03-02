
%% Does not implement OTP start and stop.

-module(sc_pubsub).





-export([

    start/0,
      stop/0,
    
    pub/2,

    sub/1,
      sub/2,
    
    unsub/1,
      unsub/2,

    destroy/1

]).





fetch_core_loop() ->

    case whereis(sc_pubsub) of

        undefined -> 
            NPid = spawn(fun start/0),
            true = register(sc_pubsub, NPid),
            NPid;

        TPid when is_pid(TPid) ->
            TPid

    end.





start() ->

    core_loop().





stop() ->

    fetch_core_loop() ! terminate.





get_listeners(Channel) ->

    case get( {channel,Channel} ) of
        undefined         -> [];
        { targets, List } -> List
    end.





core_loop() ->

    receive

        terminate ->
            ok;

        { publish, Source, Channel, Content } ->
            [ Target ! { broadcast, Channel, Content, Source } || Target <- get_listeners(Channel) ],
            core_loop();

        { subscribe, Listener, Channel } ->
            put( {channel,Channel}, { targets, lists:usort(get_listeners(Channel) ++ [Listener]) }),
            core_loop();

        { unsubscribe, Listener, Channel } ->
            put( {channel,Channel}, { targets, [ Pid || Pid <- get_listeners(Channel), Pid =/= Listener ] } ),
            core_loop();

        { destroy, Channel } ->
            erase(Channel),
            core_loop();

        _ ->
            core_loop()

    end.





%% simple messaging API





pub(Channel, Content) -> 

    fetch_core_loop() ! { publish, self(), Channel, Content }.





sub(Channel) -> 

    sub(Channel, self()).





sub(Channel, Listener) -> 

    fetch_core_loop() ! { subscribe, Listener, Channel }.





unsub(Channel) ->

    unsub(Channel, self()).





unsub(Channel, Listener) ->

    fetch_core_loop() ! { unsubscribe, Listener, Channel }.





destroy(Channel) ->

    fetch_core_loop() ! { destroy, Channel }.
