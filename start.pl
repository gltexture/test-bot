:- use_module(connection, [setup_connection/2, disconnect/0, send_message/1, receive_message/1]).
:- use_module(serverfilter, [parse_room_info/4]).

botname('bot01').

mv_direction("north") --> [north].
mv_direction("south") --> [south].
mv_direction("east") --> [east].
mv_direction("west") --> [west].

setup :-
    write('Port='),
    read(Port),
    setup_connection('localhost', Port),
    hello,
    loop(1, wait(no)),
    disconnect.

hello:-
    botname(Name),
    format('Bot Name: ~w~n', [Name]),
    atom_string(Name, NameStr),
    send_message(NameStr).

move(Dir) :-
    phrase(mv_direction(DirStr), Dir),
    format('Move: ~w~n', [DirStr]),
    format(string(Msg), "move ~w", [DirStr]),
    send_message(Msg).

use(ItemStr, Dir) :-
    phrase(mv_direction(DirStr), Dir),
    format('Use: ~w ~w~n', [ItemStr, DirStr]),
    format(string(Msg), "use ~w ~w", [ItemStr, DirStr]),
    send_message(Msg).

grab(ItemStr) :-
    format('Grab: ~w~n', [ItemStr]),
    format(string(Msg), "grab ~w", [ItemStr]),
    send_message(Msg).

quest :-
    writeln('Quest Completion!'),
    send_message("quest").


% Algorithm

do_step(1, 2) :- move([north]).
do_step(2, 3) :- grab("keys").
do_step(3, 4) :- move([south]).
do_step(4, 5) :- use("keys", [east]).
do_step(5, 6) :- move([east]).
do_step(6, 7) :- grab("crossbow").
do_step(7, 8) :- move([west]).
do_step(8, 9) :- move([south]).
do_step(9, 10) :- move([east]).
do_step(10, 11) :- grab("arrow"), grab("snake").
do_step(11, 12) :- move([west]).
do_step(12, 13) :- move([south]).
do_step(13, 14) :- quest.
do_step(14, 15) :- move([north]).
do_step(15, 16) :- move([west]).
do_step(16, 17) :- quest.
do_step(17, 18) :- use("exit_key", [north]), move([north]).
do_step(18, 19) :- move([north]).
do_step(19, 20) :- writeln("Algorithm complete."), disconnect.


loop(Step, wait(WaitFlag)) :-
    Step < 20,
    receive_message(ServerMsg),
    sleep(1),
    (
        ServerMsg == end_of_file ->
            writeln('Disconnected...'),
            disconnect
        ;
        ServerMsg == "" ->
            loop(Step, wait(WaitFlag))
        ;
        string(ServerMsg),
        writeln(''),
        format('Received. ~s~n', [ServerMsg]),
        (
            sub_string(ServerMsg, _, _, _, "Exits:") ->
                parse_room_info(Exits, Items, Quest, ServerMsg),
                format('Parsed exits: ~w~n', [Exits]),
                format('Parsed items: ~w~n', [Items]),
                ( Quest \== none ->
                    Quest = quest(Need, Reward),
                    format('Quest: need ~w, reward ~w~n', [Need, Reward])
                ; true ),
                write(Step), write(' '),
                do_step(Step, NextStep),
                loop(NextStep, wait(yes))
            ;
                ( WaitFlag == yes ->
                    do_step(Step, NextStep),
                    loop(NextStep, wait(no))
                ;
                    loop(Step, wait(WaitFlag))
                )
        )
    ).