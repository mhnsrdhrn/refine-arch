#const numSteps = 1.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 sorts
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

#place = {office, main_library, aux_library}.

#robot = {rob0}.
#textbook = {text0}.
%#printer = {print0}.
%#kitchenware = {kitw0}.
#object = #textbook. % + #printer + #kitchenware.
#thing = #object + #robot.

#boolean = {true, false}.


#step = 0..numSteps.

%% Fluents
#inertial_fluent = loc(#thing, #place).
#fluent = #inertial_fluent.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 predicates
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

val(#fluent, #boolean, #step).
is_defined(#fluent).

obs(#fluent, #boolean, #step).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 rules
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% State Constraints

%% If an object is in one location, it cannot be in another
val(loc(O, L1), false, I) :- val(loc(O, L2), true, I), L1!=L2.


%% General Inertia Axiom
val(F, Y, I+1) :- #inertial_fluent(F),
             	  val(F, Y, I),
                  not -val(F, Y, I+1).



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Defaults
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% D1
val(loc(T, main_library), true, 0) :- #textbook(T),
 				      not -val(loc(T, main_library), true, 0).

%% D2								 
val(loc(T, aux_library), true, 0) :- #textbook(T),
				     -val(loc(T, main_library), true, 0),
				     not -val(loc(T, aux_library), true, 0).

%% D3								 
val(loc(T, office), true, 0) :- #textbook(T),
				-val(loc(T, main_library), true, 0),
				-val(loc(T, aux_library), true, 0),
				not -val(loc(T, office), true, 0).

is_defined(loc(T, P)) :- #textbook(T).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% CR rules
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
val(loc(T, main_library), false, 0) :+ #textbook(T).

val(loc(T, aux_library), false, 0) :+ #textbook(T),
				      -val(loc(T, main_library), true, 0).

val(loc(T, office), false, 0) :+ #textbook(T),
	 			 -val(loc(T, main_library), true, 0),
				 -val(loc(T, aux_library), true, 0).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Reality check + obs rules
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Reality check axioms
:- obs(F, true, I), val(F, false, I).
:- obs(F, false, I), val(F, true, I).

%% Observations set values of fluents, and thus define fluents
%val(F, Y, 0) :- obs(F, Y, 0).
is_defined(F) :- obs(F, Y, 0).

-obs(F, V2, I) :- obs(F, V1, I), V1!=V2.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Rules for val function
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

-val(F, V2, I) :- val(F, V1, I), V1!=V2.
val(F, false, 0) :- not is_defined(F).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Tests
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

obs(loc(text0, main_library), false, 1).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
display
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
val.
%-val.