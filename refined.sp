#const numSteps = 5.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
sorts
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% "c" => coarse-resolution, "f" => fine-resolution...
#place_c = {office, main_library, aux_library, kitchen}.
#place_f = {c1, c2, c5, c6}. %% temporarily not including c3, c4...

#robot = {rob0}.
#textbook = {text0}.
#object = #textbook.

#thing = #object + #robot.

#boolean = {true, false}.
#outcome = {true, false, undet}.


%% Fluents; "nk" => non-knowledge, "k" => knowledge...
#inertial_nk_fluent_c = loc_c(#thing, #place_c).
#inertial_nk_fluent_f = loc_f(#thing, #place_f) + 
		      	in_hand(#robot, #object).
#inertial_nk_fluent = #inertial_nk_fluent_c + #inertial_nk_fluent_f.

%% Knowledge fluents; dir=>directly, indir=>indirectly
#inertial_k_fluent =  can_test(#robot, #inertial_nk_fluent_f) + 
		      dir_obs(#robot, #inertial_nk_fluent_f, #outcome) + 
		      indir_obs(#robot, #inertial_nk_fluent_c, #outcome).

#inertial_fluent = #inertial_nk_fluent + #inertial_k_fluent.

#defined_fluent = may_dscvr(#robot, #inertial_nk_fluent_c) + 
		  observed(#robot, #inertial_nk_fluent).

#fluent = #inertial_fluent + #defined_fluent.
#action = move(#robot, #place_f) + 
	  grasp(#robot, #object) + 
	  putdown(#robot, #object) +
	  test(#robot, #inertial_nk_fluent_f).

#step = 0..numSteps.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
predicates
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
next_to_c(#place_c, #place_c).
next_to_f(#place_f, #place_f).

component(#place_f, #place_c).

val(#fluent, #boolean, #step).
is_defined(#fluent).

occurs(#action, #step).

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
val(loc_f(R, C), true, I+1) :- occurs(move(R, C), I).

%% Grasping an object causes object to be in hand
val(in_hand(R, O), true, I+1) :- occurs(grasp(R, O), I).

%% Putting an object down causes it to no longer be in hand
val(in_hand(R, O), false, I+1) :- occurs(putdown(R, O), I).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% State Constraints
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% If an object is in one location, it cannot be in another
val(loc_f(O, L1), false, I) :- val(loc_f(O, L2), true, I), L1!=L2.

%% If a robot is holding an object, the object takes on the location
%% of the robot 
val(loc_f(O, L), true, I) :- val(loc_f(R, L), true, I),
			     val(in_hand(R, O), true, I).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Execution Conditions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% You cannot move to a location if you are already there
-occurs(move(R, L), I) :- val(loc_f(R, L), true, I).

%% You cannot move to a location that is not next to another location
-occurs(move(R, L1), I) :- val(loc_f(R, L2), true, I), 
			   -next_to_f(L2, L1).

%% Cannot have two actions happening concurrently
-occurs(A2, I) :- occurs(A1, I), A1 != A2. 

%% You cannot pick up/grasp an object if you are not in the same
%% location as the object
-occurs(grasp(R, O), I) :- val(loc_f(R, C1), true, I), 
			   val(loc_f(O, C2), true, I), C1 != C2.

%% Need the following two rules to prevent incorrect grasping?
-occurs(grasp(R, O), I) :- val(loc_f(R, C), true, I),
			   val(loc_f(O, C), false, I).
-occurs(grasp(R, O), I) :- val(loc_f(R, C), false, I), 
			   val(loc_f(O, C), true, I).


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

%% CWA for defined fluents
%val(F, false, I) :- not val(F, true, I), #defined_fluent(F).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Rules for val function
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Fluents can only have one value at a time...
-val(F, V2, I) :- val(F, V1, I), V1!=V2.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Component relations
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Transitivity and CWA for next_to predicate (not in paper)
next_to_f(C2, C1) :- next_to_f(C1, C2).
-next_to_f(C1, C2) :- not next_to_f(C1, C2).

%% Describe component relations...
next_to_c(P2, P1) :- next_to_c(P1, P2).
next_to_c(P1, P2) :- next_to_f(C1, C2), component(C1, P1),
		     component(C2, P2), P1 != P2.
-next_to_c(P1, P2) :- not next_to_c(P1, P2).

val(loc_c(Th, P), true, I) :- val(loc_f(Th, C), true, I),
			       component(C, P).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Rules for observations
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Basic rules to determine when a fluent's value can be examined
val(can_test(rob0, loc_f(Th, C)), true, I) :- 
				val(loc_f(rob0, C), true, I).
val(can_test(rob0, in_hand(rob0, O)), true, I).


%% Causal laws for direct observations...
val(dir_obs(rob0, F, true), true, I+1) :- occurs(test(rob0, F), I),
				  	  val(F, true, I).

val(dir_obs(rob0, F, false), true, I+1) :- occurs(test(rob0, F), I),
				   	   val(F, false, I).

%% Executability condition for test action...
-occurs(test(rob0, F), I) :- not val(can_test(rob0, F), true, I).

%% Axioms for indirect observations...
val(indir_obs(rob0, loc_c(Th, P), true), true, I) :- 
		val(dir_obs(rob0, loc_f(Th, C)), true, I),
		component(C, P).

val(may_dscvr(rob0, loc_c(Th, P)), true, I) :-
		not val(indir_obs(rob0, loc_c(Th, P), true), true, I),
		component(C, P),
		val(dir_obs(rob0, loc_f(Th, C), undet), true, I).
		
val(indir_obs(rob0, loc_c(Th, P), false), true, I) :- 
		not val(indir_obs(rob0, loc_c(Th, P), true), true, I),
		val(may_dscvr(rob0, loc_c(Th, P)), false, I).

%% Observed as a result of dir_obs or indir_obs...
val(observed(rob0, F), true, I) :- val(dir_obs(rob0, F, true), true, I).
val(observed(rob0, F), true, I) :- val(indir_obs(rob0, F, true), true, I).


%% Observing something (directly or indirectly) makes it so...
val(F, V, I) :- val(observed(rob0, F), V, I). 



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Planning and goal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Failure is not an option...
success :- goal(I), I <= numSteps.
:- not success. 

%% Cannot stop executing actions, until goal achieved...
occurs(A, I) | -occurs(A, I) :- not goal(I). 

something_happened(I) :- occurs(A, I).

:- not goal(I),
   not something_happened(I).


%goal(I) :- val(loc_f(text0, c5), true, I), 
%	   val(in_hand(rob0, text0), false, I).


goal(I) :- val(loc_f(text0, c6), true, I), 
	   val(in_hand(rob0, text0), false, I).



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Test
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%val(observed(rob0, loc_f(text0, c1)), true, 0).
val(loc_f(text0, c1), true, 0).
val(loc_f(rob0, c1), true, 0).
val(in_hand(rob0, text0), false, 0).

val(dir_obs(rob0, F, undet), true, 0).
val(indir_obs(rob0, F, undet), true, 0).


next_to_f(c1, c2).
%next_to_f(c1, c3).
%next_to_f(c2, c4).
%next_to_f(c3, c4).
component(c1, office).
component(c2, office).
%component(c3, office).
%component(c4, office).
%next_to_c(office, main_library).
next_to_f(c2, c5).
next_to_f(c5, c6).
component(c5, main_library).
component(c6, main_library).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
display
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
occurs.
%val.