(** * Laws about predicates over observations. *)
Require Import Ssreflect.ssreflect Ssreflect.ssrfun Ssreflect.ssrbool Ssreflect.eqtype Ssreflect.fintype Ssreflect.finfun Ssreflect.seq Ssreflect.tuple.
Require Import Ssreflect.bigop.
Require Import x86proved.bitsrep x86proved.x86.ioaction.
Require Import x86proved.opred.core.
Require Import x86proved.charge.iltac.
Require Import Coq.Setoids.Setoid Coq.Classes.RelationClasses.
Require Coq.Lists.Streams.
Require Import x86proved.common_tactics.

Generalizable All Variables.
Set Implicit Arguments.

Local Transparent ILFun_Ops ILPre_Ops osepILogicOps osepILogic lentails ltrue lfalse limpl land lor lforall lexists.
Local Transparent catOP empOP eq_opred starOP repOP roll_starOP partial_rollOP rollOP eq_opred_stream map_opred_to_stream.

Create HintDb opred_laws_t discriminated.

Hint Resolve List.app_assoc List.app_nil_l List.app_nil_r symmetry : opred_laws_t.

(** Tactics that will never need to be undone *)
Local Ltac t'_safe_without_evars :=
  do [ eassumption
     | done
     | by hyp_apply *; try eassumption
     | by eauto with opred_laws_t
     | by left
     | by right ].

(** We do replacement without disturbing evars, or if an evar can only
    be one thing (like when we have [x = y ++ z] and [x] and [y] are
    syntactically the same), then we can make progress. *)
Local Ltac progress_lists' :=
  idtac;
  lazymatch goal with
    | [ |- appcontext[(nil ++ ?a)%list] ] => replace (nil ++ a)%list with a by by symmetry; apply List.app_nil_l
    | [ |- appcontext[(?a ++ nil)%list] ] => replace (a ++ nil)%list with a by by symmetry; apply List.app_nil_r
    | [ |- appcontext[((?a ++ ?b) ++ ?c)%list] ] => replace ((a ++ b) ++ c)%list with (a ++ (b ++ c))%list by by apply List.app_assoc
    | [ |- ?x = ?y ] => progress (structurally_unify_lists x y; change (x = y))
                                 (** the [change (x = y)] above is a hack to get [progress] to notice instantiation of evars; see https://coq.inria.fr/bugs/show_bug.cgi?id=3412 *)
  end.

Local Ltac t'_safe :=
  do [ move => ?
     | progress instantiate
     | progress evar_safe_reflexivity
     | progress split_safe_goals
     | progress destruct_safe_hyps
     | progress destruct_head_hnf or
     | progress destruct_head_hnf sum
     | progress destruct_head_hnf sumbool
     | progress change @cat with @app
     | progress_lists'
     | progress hnf
     | not goal_has_evar; t'_safe_without_evars ].

Local Ltac t' :=
  do ![do ![ do !do !t'_safe
           | hnf; match goal with |- ex _ => idtac end; esplit
           | eassumption ]
      | by hyp_apply *; try eassumption ].

(** Solving evars is a side effect, so sometimes we need to let [do
    ?t'] fail on a goal, solve the other goals, and then try again. *)
Local Ltac t := do ?do ?[ do !t'
                        | by left; do ?t'
                        | by right; do ?t' ].

Add Parametric Morphism : catOP with signature lentails ==> lentails ==> lentails as catOP_entails_m.
Proof. t. Qed.

Add Parametric Morphism : catOP with signature lequiv ==> lequiv ==> lequiv as catOP_equiv_m.
Proof. t. Qed.

(** [catOP] has [empOP] as left and right unit, and is associative *)
Lemma empOPR P : catOP P empOP -|- P.
Proof. t. Qed.

Lemma empOPL P : catOP empOP P -|- P.
Proof. t. Qed.

Lemma catOPA (P Q R : OPred) : catOP (catOP P Q) R -|- catOP P (catOP Q R).
Proof. t. Qed.

Lemma catOP_trueL P : P |-- catOP ltrue P.
Proof. t. Qed.

Lemma catOP_trueR P : P |-- catOP P ltrue.
Proof. t. Qed.

Lemma catOP_eq_opred (O: OPred) o1 o2
: O o2 ->
  catOP (eq_opred o1) O (o1++o2).
Proof. t. Qed.


Hint Extern 0 (catOP ?empOP ?O |-- ?P) => by apply empOPL.
Hint Extern 0 (catOP ?O ?empOP |-- ?P) => by apply empOPR.

Lemma starOP_def (P: OPred) : starOP P -|- empOP \\// catOP P (starOP P).
Proof.
  t;
  match goal with
    | _ => by instantiate (1 := 0); t
    | _ => by instantiate (1 := S _); t
    | [ x : nat |- _ ] => induction x; by t
  end.
Qed.

Lemma rollOP_def n f : rollOP n f = match n with
                                      | 0 => empOP
                                      | S n' => catOP (f (S n')) (rollOP n' f)
                                    end.
Proof. by destruct n. Qed.

Lemma rollOP_def0 f : rollOP 0 f = empOP.
Proof. reflexivity. Qed.

Lemma rollOP_defS n f : rollOP (S n) f = catOP (f (S n)) (rollOP n f).
Proof. reflexivity. Qed.

Lemma catOP_landL P Q R : catOP (P//\\Q) R |-- (catOP P R) //\\ (catOP Q R).
Proof. t. Qed.

Lemma catOP_landR P Q R : catOP P (Q//\\R) |-- (catOP P Q) //\\ (catOP P R).
Proof. t. Qed.

Lemma catOP_lfalseL P : catOP lfalse P -|- lfalse.
Proof. t. Qed.

Lemma catOP_lfalseR P : catOP P lfalse -|- lfalse.
Proof. t. Qed.

Lemma catOP_lexists1 T P Q : catOP (Exists x : T, P x) Q -|- Exists x : T, catOP (P x) Q.
Proof. t. Qed.

Lemma catOP_lexists2 T P Q : catOP P (Exists x : T, Q x) -|- Exists x : T, catOP P (Q x).
Proof. t. Qed.

Lemma catOP_lforall1 T P Q : catOP (Forall x : T, P x) Q |-- Forall x : T, catOP (P x) Q.
Proof. t. Qed.

Lemma catOP_lforall2 T P Q : catOP P (Forall x : T, Q x) |-- Forall x : T, catOP P (Q x).
Proof. t. Qed.

Lemma catOP_lor1 P1 P2 Q : catOP (P1 \\// P2) Q -|- catOP P1 Q \\// catOP P2 Q.
Proof. t. Qed.

Lemma catOP_lor2 P Q1 Q2 : catOP P (Q1 \\// Q2) -|- catOP P Q1 \\// catOP P Q2.
Proof. t. Qed.

Lemma catOP_O_starOP_O' O O' : catOP O (catOP (starOP O) O') |-- catOP (starOP O) O'.
Proof.
  do !t'_safe.
  do 2 esplit; do !t'_safe; try eassumption; do?t'_safe.
  eexists (S _).
  t.
Qed.

Lemma catOP_O_roll_starOP_O' start O O' : catOP (O start) (catOP (roll_starOP O (S start)) O') |-- catOP (roll_starOP O start) O'.
Proof.
  do !t'_safe.
  do 2 esplit; do !t'_safe; try eassumption; do?t'_safe.
  eexists (S _).
  t.
Qed.

Lemma starOP1 O : O |-- starOP O.
Proof.
  t.
  instantiate (1 := 1).
  t.
Qed.

Lemma repOP_rollOP n O : repOP n O -|- rollOP n (fun _ => O).
Proof.
  induction n; first by reflexivity.
  rewrite /repOP/rollOP-/repOP-/rollOP.
  rewrite IHn.
  reflexivity.
Qed.

Lemma roll_starOP__starOP n O : roll_starOP (fun _ => O) n -|- starOP O.
Proof.
  rewrite /starOP/roll_starOP.
  split; (lexistsL => n'; lexistsR n');
  revert n; (induction n'; first by reflexivity) => n;
  rewrite /repOP-/repOP/partial_rollOP-/partial_rollOP;
  f_cancel;
  hyp_apply *.
Qed.

Lemma roll_starOP_def O n : roll_starOP O n -|- empOP \\// catOP (O n) (roll_starOP O (S n)).
Proof.
  t;
  match goal with
    | _ => by instantiate (1 := 0); t
    | _ => by instantiate (1 := S _); t
    | [ x : nat |- _ ] => induction x; by t
  end.
Qed.

Lemma starOP_empOP : starOP empOP -|- empOP.
Proof.
  t;
  match goal with
    | [ H : nat |- _ ] => induction H
    | [ |- context[?E] ] => is_evar E; unify E 0
  end;
  t.
Qed.

Lemma roll_starOP_empOP n : roll_starOP (fun _ => empOP) n -|- empOP.
Proof.
  rewrite -> roll_starOP__starOP.
  exact starOP_empOP.
Qed.

Local Ltac t_catOP_fold :=
    repeat match goal with
           | _ => reflexivity
           | _ => progress rewrite ?empOPL ?empOPR ?catOPA
           | _ => (test intros) => ?
           | _ => progress simpl in *
           | [ IH : _ |- context[?a] ] => not constr_eq a empOP; rewrite -> (IH a)
         end.

Lemma foldl_catOP_pull xs
: forall x, foldl catOP x xs -|- catOP x (foldl catOP empOP xs).
Proof. induction xs; t_catOP_fold. Qed.
Lemma foldr_catOP_pull xs
: forall x, foldr catOP x xs -|- catOP (foldr catOP empOP xs) x.
Proof. induction xs; t_catOP_fold. Qed.

Lemma foldl_flip_catOP_pull xs
: forall x, foldl (Basics.flip catOP) x xs -|- catOP (foldl (Basics.flip catOP) empOP xs) x.
Proof. induction xs; t_catOP_fold. Qed.
Lemma foldr_flip_catOP_pull xs
: forall x, foldr (Basics.flip catOP) x xs -|- catOP x (foldr (Basics.flip catOP) empOP xs).
Proof. rewrite /Basics.flip; induction xs; t_catOP_fold. Qed.

Lemma foldl_fun_catOP_pull {T} (xs : seq T) f
: forall x, foldl (fun x (y : T) => catOP x (f y)) x xs -|- catOP x (foldl (fun x (y : T) => catOP x (f y)) empOP xs).
Proof. induction xs; t_catOP_fold. Qed.
Lemma foldr_fun_catOP_pull {T} (xs : seq T) f
: forall x, foldr (fun (x : T) y => catOP y (f x)) x xs -|- catOP x (foldr (fun (x : T) y => catOP y (f x)) empOP xs).
Proof. induction xs; t_catOP_fold. Qed.

Lemma foldl_fun_flip_catOP_pull {T} (xs : seq T) f
: forall x, foldl (fun x (y : T) => catOP (f y) x) x xs -|- catOP (foldl (fun x (y : T) => catOP (f y) x) empOP xs) x.
Proof. induction xs; t_catOP_fold. Qed.
Lemma foldr_fun_flip_catOP_pull {T} (xs : seq T) f
: forall x, foldr (fun (x : T) y => catOP (f x) y) x xs -|- catOP (foldr (fun (x : T) y => catOP (f x) y) empOP xs) x.
Proof. induction xs; t_catOP_fold. Qed.

(** This tactic pulls the initial value of a [foldl] or [foldr] out *)
Ltac fold_catOP_pull' :=
  idtac;
  match goal with
    | [ |- context[catOP empOP ?a] ] => rewrite -> (empOPL a)
    | [ |- context[catOP ?a empOP] ] => rewrite -> (empOPR a)
    | [ |- context[foldl catOP ?a ?xs] ] => not constr_eq a empOP; rewrite -> (foldl_catOP_pull xs a)
    | [ |- context[foldr catOP ?a ?xs] ] => not constr_eq a empOP; rewrite -> (foldr_catOP_pull xs a)
    | [ |- context[foldl (Basics.flip catOP) ?a ?xs] ] => not constr_eq a empOP; rewrite -> (foldl_flip_catOP_pull xs a)
    | [ |- context[foldr (Basics.flip catOP) ?a ?xs] ] => not constr_eq a empOP; rewrite -> (foldr_flip_catOP_pull xs a)
    | [ |- context[foldl (fun x y => catOP x (@?f y)) ?a ?xs] ] => not constr_eq a empOP; rewrite -> (foldl_fun_catOP_pull xs f a)
    | [ |- context[foldr (fun x y => catOP y (@?f x)) ?a ?xs] ] => not constr_eq a empOP; rewrite -> (foldr_fun_catOP_pull xs f a)
    | [ |- context[foldl (fun x y => catOP (@?f y) x) ?a ?xs] ] => not constr_eq a empOP; rewrite -> (foldl_fun_flip_catOP_pull xs f a)
    | [ |- context[foldr (fun x y => catOP (@?f x) y) ?a ?xs] ] => not constr_eq a empOP; rewrite -> (foldr_fun_flip_catOP_pull xs f a)
  end.

Ltac fold_catOP_pull := do !fold_catOP_pull'.

(** Sometimes, we want to push instead *)
Lemma foldl_catOP_push x y xs
: catOP x (foldl catOP y xs) -|- foldl catOP (catOP x y) xs.
Proof. fold_catOP_pull; by rewrite ?catOPA. Qed.
Lemma foldr_catOP_push x y xs
: catOP (foldr catOP x xs) y -|- foldr catOP (catOP x y) xs.
Proof. fold_catOP_pull; by rewrite ?catOPA. Qed.

Lemma foldl_flip_catOP_push x y xs
: catOP (foldl (Basics.flip catOP) x xs) y -|- foldl (Basics.flip catOP) (catOP x y) xs.
Proof. fold_catOP_pull; by rewrite ?catOPA. Qed.
Lemma foldr_flip_catOP_push x y xs
: catOP x (foldr (Basics.flip catOP) y xs) -|- foldr (Basics.flip catOP) (catOP x y) xs.
Proof. fold_catOP_pull; by rewrite ?catOPA. Qed.

Lemma foldl_fun_catOP_push {T} x y (xs : seq T) f
: catOP x (foldl (fun x (y : T) => catOP x (f y)) y xs) -|- foldl (fun x (y : T) => catOP x (f y)) (catOP x y) xs.
Proof. fold_catOP_pull; by rewrite ?catOPA. Qed.
Lemma foldr_fun_catOP_push {T} x y (xs : seq T) f
: catOP x (foldr (fun (x : T) y => catOP y (f x)) y xs) -|- foldr (fun (x : T) y => catOP y (f x)) (catOP x y) xs.
Proof. fold_catOP_pull; by rewrite ?catOPA. Qed.

Lemma foldl_fun_flip_catOP_push {T} x y (xs : seq T) f
: catOP (foldl (fun x (y : T) => catOP (f y) x) x xs) y -|- foldl (fun x (y : T) => catOP (f y) x) (catOP x y) xs.
Proof. fold_catOP_pull; by rewrite ?catOPA. Qed.
Lemma foldr_fun_flip_catOP_push {T} x y (xs : seq T) f
: catOP (foldr (fun (x : T) y => catOP (f x) y) x xs) y -|- foldr (fun (x : T) y => catOP (f x) y) (catOP x y) xs.
Proof. fold_catOP_pull; by rewrite ?catOPA. Qed.

(** This tactic pushes the initial value of a [foldl] or [foldr] in *)
Ltac fold_catOP_push' :=
  idtac;
  match goal with
    | [ |- context[catOP empOP ?a] ] => rewrite -> (empOPL a)
    | [ |- context[catOP ?a empOP] ] => rewrite -> (empOPR a)
    | [ |- context[catOP ?x (foldl catOP ?y ?xs)] ] => rewrite -> (foldl_catOP_push x y xs)
    | [ |- context[catOP (foldr catOP ?x ?xs) ?y] ] => rewrite -> (foldr_catOP_push x y xs)
    | [ |- context[catOP (foldl (Basics.flip catOP) ?x ?xs) ?y] ] => rewrite -> (foldl_flip_catOP_push x y xs)
    | [ |- context[catOP ?x (foldr (Basics.flip catOP) ?y ?xs)] ] => rewrite -> (foldr_flip_catOP_push x y xs)
    | [ |- context[catOP ?x (foldl (fun x y => catOP x (@?f y)) ?y ?xs)] ] => rewrite -> (foldl_fun_catOP_push x y xs f)
    | [ |- context[catOP ?x (foldr (fun x y => catOP y (@?f x)) ?y ?xs)] ] => rewrite -> (foldr_fun_catOP_push x y xs f)
    | [ |- context[catOP (foldl (fun x y => catOP (@?f y) x) ?x ?xs) ?y] ] => rewrite -> (foldl_fun_flip_catOP_push x y xs f)
    | [ |- context[catOP (foldr (fun x y => catOP (@?f x) y) ?x ?xs) ?y] ] => rewrite -> (foldr_fun_flip_catOP_push x y xs f)
  end.

Ltac fold_catOP_push := do !fold_catOP_push'.

Local Ltac foldl_catOP_foldr_t :=
  let ls := match goal with ls : seq _ |- _ => constr:(ls) end in
  (induction ls => //=; []);
    repeat match goal with
             | [ IHls : context[ls] |- _ ] => rewrite <- IHls; clear IHls
             | _ => progress fold_catOP_pull
             | _ => done
             | _ => rewrite /Basics.flip
           end.

Lemma foldl_catOP_foldr ls
: foldl catOP empOP ls -|- foldr catOP empOP ls.
Proof. foldl_catOP_foldr_t. Qed.

Lemma foldl_flip_catOP_foldr ls
: foldl (Basics.flip catOP) empOP ls -|- foldr (Basics.flip catOP) empOP ls.
Proof. foldl_catOP_foldr_t. Qed.

Lemma foldl_fun_catOP_foldr {T} (ls : seq T) f
: foldl (fun x (y : T) => catOP x (f y)) empOP ls -|- foldr (fun (x : T) y => catOP (f x) y) empOP ls.
Proof. foldl_catOP_foldr_t. Qed.

Lemma foldl_fun_flip_catOP_foldr {T} (ls : seq T) f
: foldl (fun x (y : T) => catOP (f y) x) empOP ls -|- foldr (fun (x : T) y => catOP y (f x)) empOP ls.
Proof. foldl_catOP_foldr_t. Qed.

Local Opaque lentails.

(** Miscellaneous laws about [fold] and [lentails].  Very ugly, rather
    special-purpose, currently to be used in
    examples/accumulate_example.v *)
Lemma respect_lentails_under_foldl A B a o1 o2 f acc xs (H : forall v, o1 v |-- o2 v) v
: (snd
     (foldl
        (fun (xy : A * (OPred -> OPred)) (v : B) =>
           (acc (fst xy) v, (fun o' => catOP o' (f (fst xy) v)) \o (snd xy)))
        (a, o1) xs)) v
                     |-- (snd
                            (foldl
                               (fun (xy : A * (OPred -> OPred)) (v : B) =>
                                  (acc (fst xy) v, (fun o' => catOP o' (f (fst xy) v)) \o (snd xy)))
                               (a, o2) xs)) v.
Proof.
  revert o1 o2 H a.
  induction xs => //= *.
  rewrite -> IHxs; first reflexivity; unfold funcomp; simpl => *.
    by hyp_rewrite -> *.
Qed.

Lemma respect_lequiv_under_foldl A B a o1 o2 f acc xs (H : forall v, o1 v -|- o2 v) v
: (snd
     (foldl
        (fun (xy : A * (OPred -> OPred)) (v : B) =>
           (acc (fst xy) v, (fun o' => catOP o' (f (fst xy) v)) \o (snd xy)))
        (a, o1) xs))
    v
    -|- (snd
           (foldl
              (fun (xy : A * (OPred -> OPred)) (v : B) =>
                 (acc (fst xy) v, (fun o' => catOP o' (f (fst xy) v)) \o (snd xy)))
              (a, o2) xs)) v.
Proof.
  split; apply respect_lentails_under_foldl => *; hyp_rewrite *; reflexivity.
Qed.

Lemma foldl_catOP_to_functions A B a o f acc xs
: (snd
     (foldl
        (fun (xy : A * OPred) (v : B) =>
           (acc (fst xy) v, catOP (snd xy) (f (fst xy) v)))
        (a, o) xs))
    -|-
    ((snd
        (foldl
           (fun (xy : A * (OPred -> OPred)) (v : B) =>
              (acc (fst xy) v, (fun o' => catOP o' (f (fst xy) v)) \o (snd xy)))
           (a, (fun o' => catOP o' o))
           xs)))
    empOP.
Proof.
  revert f o a.
  induction xs => //= *.
  { by rewrite empOPL. }
  { rewrite IHxs.
    unfold funcomp; simpl.
    apply respect_lequiv_under_foldl => *.
      by rewrite catOPA. }
Qed.

Lemma catOP_foldl_helper {A B} (acc : A -> B -> A) (xs : seq B) (a : A) (o' : OPred) (f : A -> B -> OPred) (o0 : OPred -> OPred := id)
: (catOP o'
         (snd
            (foldl
               (fun (xy : A * (OPred -> OPred)) (v : B) =>
                  (acc (fst xy) v,
                   (fun o' : OPred => catOP o' (f (fst xy) v)) \o snd xy))
               (a, o0) xs) empOP))
    -|- (snd
           (foldl
              (fun (xy : A * (OPred -> OPred)) (v : B) =>
                 (acc (fst xy) v,
                  (fun o' : OPred => catOP o' (f (fst xy) v)) \o snd xy))
              (a, o0 \o (fun o0 : OPred => catOP o0 o')) xs) empOP).
Proof.
  revert a o'.
  induction xs => //=.
  { unfold funcomp, o0; simpl => *.
    (by rewrite ?empOPL ?empOPR). }
    { move => *.
      unfold funcomp, o0 in *; simpl in *.
      etransitivity; last first.
      eapply respect_lequiv_under_foldl => *; set_evars; rewrite catOPA; subst_evars; higher_order_reflexivity.
      rewrite -!IHxs !catOPA.
      reflexivity. }
Qed.

Lemma catOP_foldl_helper' {A B} (acc : A -> B -> A) (xs : seq B) (a : A) (o' : OPred) (f : A -> B -> OPred)
: (catOP o'
         (snd
            (foldl
               (fun (xy : A * (OPred -> OPred)) (v : B) =>
                  (acc (fst xy) v,
                   (fun o' : OPred => catOP o' (f (fst xy) v)) \o snd xy))
               (a, id) xs) empOP))
    -|- (snd
           (foldl
              (fun (xy : A * (OPred -> OPred)) (v : B) =>
                 (acc (fst xy) v,
                  (fun o' : OPred => catOP o' (f (fst xy) v)) \o snd xy))
              (a, (fun o0 : OPred => catOP o0 o')) xs) empOP).
Proof. apply catOP_foldl_helper. Qed.

Local Transparent lentails.

Lemma empOP_eq_opred_stream xs : empOP |-- eq_opred_stream xs.
Proof. t. Qed.

Local Hint Immediate empOP_eq_opred_stream.

Lemma eq_opred_stream_def x (xs : Streams.Stream Action)
: eq_opred_stream (Streams.Cons x xs) -|- empOP \\// catOP (eq_opred (x::nil)) (eq_opred_stream xs).
Proof. t; destruct_head' Actions; t. Qed.

Lemma unfold_map_opred_to_stream {T} f1 f2 s
: @map_opred_to_stream T f1 f2 s = eq_opred_stream (flatten_stream (Streams.map (fun v => (f1 v, f2 v)) s)).
Proof. reflexivity. Qed.

Local Opaque lor.

Local Ltac map_t' :=
  do [ progress rewrite ?map_step ?flatten_stream_step ?eq_opred_stream_def /=
     | by rewrite {1}unfold_map_opred_to_stream
     | f_cancel; [ match goal with |- lequiv _ _ => idtac end ]
     | destruct_atomic_in_match' ].

Local Ltac map_t := do !map_t'.

Lemma map_opred_to_stream_def {T} f1 f2 x xs
: (@map_opred_to_stream T f1 f2 (Streams.Cons x xs))
    -|- (foldr (fun x y => empOP \\// catOP x y) (map_opred_to_stream f1 f2 xs) (map (fun v => eq_opred (v::nil)) ((f1 x)::(f2 x)))).
Proof.
  rewrite {1}unfold_map_opred_to_stream.
  map_t.
  destruct (f2 x); simpl.
  { map_t. }
  { let x := match goal with x : Action |- _ => constr:(x) end in
    revert x.
    let ls := match goal with ls : seq Action |- _ => constr:(ls) end in
    induction ls => //= *.
    { map_t. }
    { hyp_rewrite <- *.
      by rewrite flatten_stream_step eq_opred_stream_def /=. } }
Qed.
