(** * POP instruction *)
Require Import x86proved.x86.instrrules.core.
Import x86.instrrules.core.instrruleconfig.

(** ** Generic POP *)
Lemma POP_rule (rm:RegMem OpSize4) (sp:DWORD) (oldv v:DWORD):
  |-- specAtRegMemDst rm (fun V =>
      basic (V oldv ** ESP ~= sp    ** sp:->v) (POP rm) 
            (V v    ** ESP ~= sp+#4 ** sp:->v)).
Proof. do_instrrule_triple. Qed.

(** We make this rule an instance of the typeclass, and leave
    unfolding things like [specAtDstSrc] to the getter tactic
    [get_instrrule_of]. *)
Global Instance: forall (rm : RegMem _), instrrule (POP rm) := @POP_rule.


(** ** POP r *)
Corollary POP_R_rule (r:Reg) (sp oldv v:DWORD) :
  |-- basic (r ~= oldv ** ESP ~= sp    ** sp:->v) (POP (RegMemR OpSize4 r)) 
            (r ~= v    ** ESP ~= sp+#4 ** sp:->v).
Proof. basic apply *. Qed.

(** ** POP [r + offset] *)
Corollary POP_M_rule (r:Reg) (offset:nat) (sp oldv v pbase:DWORD) :
  |-- basic (r ~= pbase ** pbase +# offset :-> oldv ** ESP ~= sp ** sp :-> v)
            (POP [r + offset]) 
            (r ~= pbase ** pbase +# offset :-> v ** ESP ~= sp+#4 ** sp :-> v).
Proof. basic apply *. Qed.

(** ** POP [r] *)
Corollary POP_M0_rule (r: Reg) (sp oldv v pbase:DWORD) :
  |-- basic (r ~= pbase ** pbase :-> oldv ** ESP ~= sp    ** sp :-> v)
            (POP [r]) 
            (r ~= pbase ** pbase :-> v    ** ESP ~= sp+#4 ** sp :-> v).
Proof. basic apply *. Qed.
