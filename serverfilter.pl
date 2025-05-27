:- module(serverfilter, [parse_room_info/4]).

% Directions
direction(north) --> ":north".
direction(south) --> ":south".
direction(east)  --> ":east".
direction(west)  --> ":west".

% Utils
blanks --> [C], { char_type(C, space) }, blanks.
blanks --> [].

optional_comma --> ",".
optional_comma --> [].

optional_period --> ".", !.
optional_period --> [].

% atom_chars
atom_chars([C|Rest]) --> [C], { char_type(C, csymf) }, atom_chars_rest(Rest).
atom_chars_rest([C|Rest]) --> [C], { char_type(C, csym) }, !, atom_chars_rest(Rest).
atom_chars_rest([]) --> [].

% Skip to "Exits:"
skip_until_exits --> ( [ _ ], skip_until_exits ) ; "Exits:".

% Exits
exits_list([D|Rest]) --> direction(D), blanks, optional_comma, blanks, exits_list(Rest).
exits_list([]) --> [].

exits(Dirs) --> skip_until_exits, blanks, exits_list(Dirs), optional_period, blanks.

% Skip to quest
skip_until_quest --> ( [ _ ], skip_until_quest ) ; "Quest:".

% Quest parsing
quest_items([I|Rest]) --> ":", atom_chars(Chars), { atom_chars(I, Chars) }, blanks, optional_comma, blanks, quest_items(Rest).
quest_items([]) --> [].

quest(quest(Needs, Gives)) --> skip_until_quest, blanks, "you need", blanks, quest_items(Needs), ".", blanks, "You'll get", blanks, ":", atom_chars(GiveChars), { atom_chars(Gives, GiveChars) }, optional_period.

quest_opt(Q) --> quest(Q), !.
quest_opt(none) --> [].

% Skip to item
skip_until_item --> ( [ _ ], skip_until_item ) ; "There is ".

% Single item
item(Item) --> skip_until_item, blanks, ":", atom_chars(Chars), " here.", blanks, { atom_chars(Item, Chars) }.

% Multiple items
items([I|Rest]) --> item(I), items(Rest).
items([]) --> [].


% ====================================

% Room info parser
room_info(Exits, Items, QuestOpt) -->
    exits(Exits), blanks,
    items(Items), blanks,
    quest_opt(QuestOpt), blanks, !.

% Main entry
parse_room_info(Exits, Items, QuestOpt, Input) :-
    string_codes(Input, Codes),
    phrase(room_info(Exits, Items, QuestOpt), Codes).
