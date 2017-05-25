Set Warnings "-notation-overridden".

Require Import Category.Lib.
Require Export Category.Theory.Functor.

Generalizable All Variables.
Set Primitive Projections.
Set Universe Polymorphism.
Unset Transparent Obligations.

Section Monad.

Context `{M : C ⟶ C}.

Class Monad := {
  ret {a}  : a ~> M a;          (* Id    ⟹ M *)
  join {a} : M (M a) ~> M a;    (* M ○ M ⟹ M *)

  fmap_ret {a b} (f : a ~> b) : ret ∘ f ≈ fmap f ∘ ret;
  join_fmap_join {a} : join ∘ fmap (@join a) ≈ join ∘ join;
  join_fmap_ret  {a} : join ∘ fmap (@ret a) ≈ id;
  join_ret       {a} : join ∘ @ret (M a) ≈ id;

  (* This law states that join is a natural transformation from [fmap . fmap]
     to [fmap]. *)
  join_fmap_fmap {a b} (f : a ~> b) :
    join ∘ fmap (fmap f) ≈ fmap f ∘ join
}.

End Monad.

Notation "ret[ M ]" := (@ret _ M _ _)
  (at level 9, format "ret[ M ]") : category_scope.
Notation "join[ M ]" := (@join _ M _ _)
  (at level 9, format "join[ M ]") : category_scope.

Section MonadLib.

Context `{@Monad C M}.

Definition bind {a b : C} (f : a ~> M b) : M a ~> M b :=
  join ∘ fmap[M] f.

End MonadLib.

Notation "m >>= f" := (bind f m) (at level 42, right associativity) : morphism_scope.
Notation "f >> g" := (f >>= fun _ => g)%morphism
  (at level 81, right associativity) : morphism_scope.

Require Import Category.Construction.Opposite.
Require Import Category.Functor.Opposite.

Definition Comonad `{M : C ⟶ C} := @Monad (C^op) (M^op).
