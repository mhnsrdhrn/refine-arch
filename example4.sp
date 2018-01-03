#const numSteps = 6.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  sorts
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

#place = {office, main_library, aux_library, kitchen}.

#robot = {rob0}.
#textbook = {text0}.
%#printer = {print0}.
%#kitchenware = {kitw0}.
#object = #textbook. % + #printer + #kitchenware.

#thing = #object + #robot.

#boolean = {true, false}.

#default = d1(#textbook) + d2(#textbook) + d3(#textbook).

#step = 0..numSteps.

%% Fluents
#inertial_fluent = loc(#thing, #place) + in_hand(#robot, #object).
#fluent = #inertial_fluent.
#action = move(#robot, #place) + grasp(#robot, #object) + putdown(#robot, #object).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  predicates
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
next_to(#place, #place).

ab(#default).
better(#default, #default).
defined_by_default(#fluent).

val(#fluent, #boolean, #step).

occurs(#action, #step).

obs(#fluent, #boolean, #step).
hpd(#action, #step).

success().
goal(#step). 
something_happened(#step).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 rules			        
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Causal Laws
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Moving changes location to target place
val(loc(R, P), true, I+1) :- occurs(move(R, P), I).

%% Grasping an object causes object to be in hand
val(in_hand(R, O), true, I+1) :- occurs(grasp(R, O), I).

%% Putting an object down causes it to no longer be in hand
val(in_hand(R, O), false, I+1) :- occurs(putdown(R, O), I).



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% State Constraints
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% If an object is in one location, it cannot be in another
val(loc(O, L1), false, I) :- val(loc(O, L2), true, I), L1!=L2.

%% if a robot is holding an object, the object takes on the location of the robot
val(loc(O, L), true, I) :- val(loc(R, L), true, I), val(in_hand(R, O), true, I).



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Executability Conditions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% You cannot move to a location if you are already there
-occurs(move(R, L), I) :- val(loc(R, L), true, I).

%% You cannot move to a location that is not next to another location
-occurs(move(R, L1), I) :- val(loc(R, L2), true, I), -next_to(L2, L1).

%% Cannot have two actions happening concurrently
-occurs(A2, I) :- occurs(A1, I), A1 != A2. 

%% You cannot pick up/grasp an object unless you are in the same location as the object
-occurs(grasp(R, O), I) :- val(loc(R, L1), true, I), val(loc(O, L2), true, I), L1 != L2.

%% Need the following two rules to prevent incorrect grasping?
-occurs(grasp(R, O), I) :- val(loc(R, L), true, I), val(loc(O, L), false, I).
-occurs(grasp(R, O), I) :- val(loc(R, L), false, I), val(loc(O, L), true, I).

%% You cannot grasp an object if it is alread in your hand 
-occurs(grasp(R, O), I) :- val(in_hand(R, O), true, I).

%% You can put down an object only if it is in your hand
-occurs(putdown(R, O), I) :-  not val(in_hand(R, O), true, I).



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Inertial axiom + CWA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

val(F, Y, I+1) :- #inertial_fluent(F),
             	  val(F, Y, I),
                  not -val(F, Y, I+1), I < numSteps.

%% CWA for Actions
-occurs(A,I) :- not occurs(A,I).

%% Commutivity and CWA for next_to predicate
next_to(L2, L1) :- next_to(L1, L2).
-next_to(L1,L2) :- not next_to(L1,L2).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Defaults (prioritized)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% D1
val(loc(T, main_library), true, 0) :- #textbook(T),
				      not ab(d1(T)).

%% D2								 
val(loc(T, aux_library), true, 0) :- #textbook(T),
				     not ab(d2(T)).

%% D3								 
val(loc(T, office), true, 0) :- #textbook(T),
				not ab(d3(T)).

%% If a default of higher-priority is applicable, lower-priority
%% defaults are inapplicable...
ab(X2) :- better(X1, X2), not ab(X1).

%% Priority relations between defaults are transitive...
better(X1, X3) :- better(X1, X2),
		  better(X2, X3).

%% Priority relations are between two different defaults...
-better(X1, X1).


%% A book's location is often defined by one of the defaults...
defined_by_default(loc(T, main_library)) :- #textbook(T),
					    not ab(d1(T)).

defined_by_default(loc(T, aux_library)) :- #textbook(T),
					    not ab(d2(T)).

defined_by_default(loc(T, office)) :- #textbook(T),
				      not ab(d3(T)).

%% If not, book's location is one of the other possible options...
val(loc(T, kitchen), true, 0) :- not defined_by_default(loc(T, main_library)),
				 not defined_by_default(loc(T, aux_library)),
				 not defined_by_default(loc(T, office)),
				 #textbook(T).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% CR rules
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ab(d1(T)) :+ #textbook(T).
ab(d2(T)) :+ #textbook(T).
ab(d3(T)) :+ #textbook(T).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% History rules
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Take what actually happened into account
occurs(A,I) :- hpd(A,I).

%% Reality check axioms
:- obs(F, true, I), val(F, false, I).
:- obs(F, false, I), val(F, true, I).

%% Observations set values of fluents in the initial state...
val(F, Y, 0) :- obs(F, Y, 0).

%% Only one value possible for a fluent; not really necessary...
-val(F, V2, I) :- val(F, V1, I), V1!=V2.

%-obs(F, V2, I) :- obs(F, V1, I), V1!=V2.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Planning and GOAL
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
success :- goal(I), I <= numSteps.

%% Failure is not an option
:- not success. 

%% Persevere, i.e., cannot stop executing actions, until goal achieved
occurs(A, I) | -occurs(A, I) :- not goal(I). 

something_happened(I) :- occurs(A, I).

:- not goal(I),
   not something_happened(I).


goal(I) :- val(loc(text0, kitchen), true, I), not val(in_hand(rob0, text0), true, I).




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Test
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Statics
next_to(main_library, aux_library).
next_to(aux_library, office).
next_to(office, kitchen).

better(d1(text0), d2(text0)).
better(d2(text0), d3(text0)).


%% Observations
obs(loc(rob0, office), true, 0).
obs(loc(text0, main_library), false, 1).
%obs(loc(text0, aux_library), false, 1).
%obs(loc(text0, office), false, 1).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
display
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

occurs.
%val.
ab.
%better.