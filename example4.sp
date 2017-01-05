#const numSteps = 3.

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
#inertial_fluent = loc(#thing, #place) + in_hand(#robot, #object).
#fluent = #inertial_fluent.
#action = move(#robot, #place) + grasp(#robot, #object) + putdown(#robot, #object).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  predicates
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
next_to(#place, #place).

val(#fluent, #boolean, #step).
is_defined(#fluent).

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
%val(loc(O, L1), false, I) :- val(loc(O, L2), true, I), L1!=L2.

%% if a robot is holding an object, the object takes on the location of the robot
val(loc(O, L), true, I) :- val(loc(R, L), true, I), val(in_hand(R, O), true, I).



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Execution Conditions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% You cannot move to a location if you are already there
-occurs(move(R, L), I) :- val(loc(R, L), true, I).

%% You cannot move to a location that is not next to another location
-occurs(move(R, L1), I) :- val(loc(R, L2), true, I), -next_to(L2, L1).

%% Cannot have two actions happening concurrently
-occurs(A2, I) :- occurs(A1, I), A1 != A2. 

%% You cannot pick up/grasp an object if you are not in the same location as the object
-occurs(grasp(R, O), I) :- val(loc(R, L1), true, I), val(loc(O, L2), true, I), L1 != L2.

%% Need the following two rules to prevent incorrect grasping?
-occurs(grasp(R, O), I) :- val(loc(R, L), true, I), val(loc(O, L), false, I).
-occurs(grasp(R, O), I) :- val(loc(R, L), false, I), val(loc(O, L), true, I).


%% You cannot pick up/grasp an object if it is alread in your hand 
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

%% Transitivity and CWA for next_to predicate (not in paper)
next_to(L2, L1) :- next_to(L1, L2).
-next_to(L1,L2) :- not next_to(L1,L2).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Defaults (prioritized)
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
%% History rules
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Take what actually happened into account
occurs(A,I) :- hpd(A,I).

%% Reality check axioms
:- obs(F, true, I), val(F, false, I).
:- obs(F, false, I), val(F, true, I).

%% Observations set values of fluents, and thus define fluents
%val(F, Y, 0) :- obs(F, Y, 0). (remove from paper?)
is_defined(F) :- obs(F, Y, 0).

-obs(F, V2, I) :- obs(F, V1, I), V1!=V2.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Rules for val function
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

-val(F, V2, I) :- val(F, V1, I), V1!=V2.
val(F, false, 0) :- not is_defined(F).


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


goal(I) :- val(loc(text0, office), true, I).




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Test
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

next_to(main_library, aux_library).
next_to(aux_library, office).
next_to(main_library, office).


obs(loc(rob0, office), true, 0).

obs(loc(text0, main_library), false, 1).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
display
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

occurs.
