(** * Predicates over observations (sequences of actions) *)
(** Basic definitions of observations. *)
Require Import Ssreflect.ssreflect Ssreflect.ssrfun Ssreflect.ssrnat Ssreflect.ssrbool Ssreflect.eqtype Ssreflect.fintype Ssreflect.finfun Ssreflect.seq Ssreflect.tuple.
Require Import x86proved.bitsrep x86proved.x86.ioaction x86proved.charge.csetoid.
Require Import Coq.Setoids.Setoid Coq.Classes.RelationClasses Coq.Classes.Morphisms Coq.Program.Basics.
Require Import Coq.Lists.Streams.
Require Import x86proved.common_definitions.
(** Importing this file really only makes sense if you also import
    ilogic, so we force that. *)
Require Export x86proved.charge.ilogic x86proved.charge.bilogic x86proved.ilogicss.

Set Implicit Arguments.
Unset Strict Implicit.
Import Prenex Implicits.

Definition OPred := ILFunFrm Actions Prop.

Identity Coercion OPred_def : OPred >-> ILFunFrm.

Local Existing Instance ILFun_Ops.
Local Existing Instance ILFun_ILogic.

(** Giving these cost 1 ensures that they are preferred over spec/Prop instances *)
Instance osepILogicOps : ILogicOps OPred | 1 := _.
Instance osepILogic : ILogic OPred | 1 := _.
Global Opaque osepILogicOps osepILogic.

Definition mkOPred (P : Actions -> Prop) : OPred
  := @mkILFunFrm Actions _ Prop _ P (fun t t' H => (eq_rect _ _ (reflexivity _) _ (f_equal P H))).

(** ** Singleton predicate *)
Definition eq_opred s := mkOPred (fun s' => s === s').

(** ** The empty sequence of actions *)
Definition empOP : OPred := eq_opred nil.

(** ** A single output action *)
Definition outOP (c:Chan) (d:Data) : OPred := eq_opred [::Out c d].
Definition inOP (c:Chan) (d:Data) : OPred := eq_opred [::In c d].

(** ** A sequence of actions that splits into the concatenation of one
       satisfying P and one satisfying Q *)
Definition catOP (P Q: OPred) : OPred
 := mkOPred (fun o => exists o1 o2, o = o1++o2 /\ P o1 /\ Q o2).

(** ** Repetition *)
Fixpoint repOP n P := if n is n'.+1 then catOP P (repOP n' P) else empOP.

(** ** Kleene star *)
Definition starOP P : OPred := Exists n, repOP n P.

(** ** Rolling a function on numbers into a single [OPred] *)
Fixpoint rollOP n (f : nat -> OPred) : OPred :=
  match n with
    | 0 => empOP
    | S n' => catOP (f (S n')) (rollOP n' f)
  end.

(** ** Rolling a function on numbers into a single [OPred], with a starting and ending place *)
Fixpoint partial_rollOP (f : nat -> OPred) (start : nat) (count : nat)  : OPred :=
  if count is count'.+1
  then catOP (f start) (partial_rollOP f (start.+1) count')
  else empOP.

(** ** Rolling a function any number of places from a given starting location *)
Definition roll_starOP (f : nat -> OPred) (start : nat) : OPred := Exists n, partial_rollOP f start n.

(** ** Equality with a prefix of a stream *)
Definition eq_opred_stream (x : Stream Action) : OPred
  := mkOPred (list_is_prefix_of_stream x).

(** Generate [eq_opred_stream] by mapping and folding *)
Definition map_opred_to_stream {T} (f1 : T -> Action) (f2 : T -> Actions) (s : Stream T) : OPred
  := eq_opred_stream (flatten_stream (map (fun v => (f1 v, f2 v)) s)).

Global Opaque catOP inOP outOP eq_opred empOP repOP starOP rollOP partial_rollOP roll_starOP eq_opred_stream map_opred_to_stream.
