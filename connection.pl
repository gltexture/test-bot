:- module(connection, [setup_connection/2, disconnect/0, send_message/1, receive_message/1]).
:- use_module(library(socket)).
:- dynamic connection/2.

setup_connection(Host, Port) :-
    tcp_socket(Socket),
    tcp_connect(Socket, Host:Port),
    tcp_open_socket(Socket, StreamPair),
    stream_pair(StreamPair, InRaw, OutRaw),
    set_stream(InRaw, encoding(utf8)),
    set_stream(OutRaw, encoding(utf8)),
    set_stream(OutRaw, newline(dos)),
    writeln('Connected to server!'),
    retractall(connection(_, _)),
    assertz(connection(InRaw, OutRaw)).

disconnect :-
    (   connection(InStream, OutStream) ->
        close(InStream),
        close(OutStream),
        retractall(connection(_, _)),
        writeln('Disconnected from server.')
    ; 
        writeln('No active connection.')
    ).

send_message(Message) :-
    connection(_, OutStream),
    format(OutStream, '~s~n', [Message]),
    flush_output(OutStream).

receive_message(Message) :-
    connection(InStream, _),
    read_line_to_codes(InStream, Codes),
    ( Codes == end_of_file -> Message = end_of_file
    ; Codes == [] -> receive_message(Message)  % пропускаем пустую строку
    ; string_codes(Message, Codes)
    ).