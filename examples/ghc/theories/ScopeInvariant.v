Require Import CoreSyn.
Require Import VarSet.

Require Import Coq.Lists.List.
Import ListNotations.

Set Bullet Behavior "Strict Subproofs".

(*
This file describes an invariant of Core files that
 * all variables must be in scope
 * and be structurally equal to their binder
*)

(* This returns a [Prop] rather than a bool because
   we do not have a function that determines structural
   equality.
*)

(* The termination checker does not like recursion through [Forall], but
   through [map] is fine... oh well. *)
Definition Forall' {a} (P : a -> Prop) xs := Forall id (map P xs).

Fixpoint wellScoped (e : CoreExpr) (in_scope : VarSet) {struct e} : Prop :=
  match e with
  | Var v => match lookupVarSet in_scope v with
    | None => False
    | Some v' => v = v'
    end
  | Lit l => True
  | App e1 e2 => wellScoped e1 in_scope /\  wellScoped e2 in_scope
  | Lam v e => wellScoped e (extendVarSet in_scope v)
  | Let (NonRec v rhs) body => 
      wellScoped rhs in_scope /\ wellScoped body (extendVarSet in_scope v)
  | Let (Rec pairs) body => 
      (* TODO: Maybe we want the variables to be disjoint? *)
      let in_scope' := extendVarSetList in_scope (map fst pairs) in
      Forall' (fun p => wellScoped (snd p) in_scope') pairs /\
      wellScoped body in_scope'
  | Case scrut bndr ty alts  => 
    wellScoped scrut in_scope /\
    Forall' (fun alt =>
      let in_scope' := extendVarSetList in_scope (bndr :: snd (fst alt)) in
      wellScoped (snd alt) in_scope') alts
  | Cast e _ =>   wellScoped e in_scope
  | Tick _ e =>   wellScoped e in_scope
  | Type_ _  =>   True
  | Coercion _ => True
  end.
