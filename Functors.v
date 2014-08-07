Require Export Category.

Open Scope category_scope.

Generalizable All Variables.

Class Functor (C : Category) (D : Category) :=
{ fobj : C → D
; fmap : ∀ {X Y : C}, (X ~> Y) → (fobj X ~> fobj Y)

; functor_id_law      : ∀ {X : C}, fmap (id (A := X)) = id
; functor_compose_law : ∀ {X Y Z : C} (f : Y ~> Z) (g : X ~> Y),
    fmap f ∘ fmap g = fmap (f ∘ g)
}.

Notation "C ⟶ D" := (Functor C D) (at level 90, right associativity).

(* Functors used as functions will map objects of categories, similar to the
   way type constructors behave in Haskell. *)
Coercion fobj : Functor >-> Funclass.

Definition fun_compose
  {C : Category} {D : Category} {E : Category}
  (F : Functor D E) (G : Functor C D) : Functor C E.
  apply Build_Functor with
    (fobj := fun x => fobj (fobj x))
    (fmap := fun _ _ f => fmap (fmap f)).
  - intros.
    rewrite functor_id_law.
    apply functor_id_law.
  - intros.
    rewrite functor_compose_law.
    rewrite functor_compose_law.
    reflexivity.
Defined.

Lemma fun_irrelevance `(C : Category) `(D : Category)
  : ∀ (a : C → D)
      (f g : ∀ {X Y : C}, (X ~> Y) → (a X ~> a Y))
      i i' c c',
  @f = @g ->
  {| fobj := @a
   ; fmap := @f
   ; functor_id_law      := i
   ; functor_compose_law := c |} =
  {| fobj := @a
   ; fmap := @g
   ; functor_id_law      := i'
   ; functor_compose_law := c' |}.
Proof.
  intros. subst. f_equal.
  apply proof_irrelevance.
  apply proof_irrelevance.
Qed.

Class Natural `(F : @Functor C D) `(G : @Functor C D) :=
{ transport  : ∀ {X}, F X ~> G X
; naturality : ∀ {X Y} (f : X ~> Y),
    fmap f ∘ transport = transport ∘ fmap f
}.

Notation "transport/ N" := (@transport _ _ _ _ N _) (at level 44).
Notation "F ⟾ G" := (Natural F G) (at level 90, right associativity).

(* Natural transformations can be applied directly to functorial values to
   perform the functor mapping they imply. *)
Coercion transport : Natural >-> Funclass.

Definition nat_identity `{F : Functor} : Natural F F.
  apply Build_Natural with (transport := fun _ => id).
  intros.
  rewrite right_identity.
  rewrite left_identity.
  reflexivity.
Defined.

Definition nat_compose
  `{F : @Functor C D} `{G : @Functor C D} `{K : @Functor C D}
  (f : Natural G K) (g : Natural F G) : Natural F K.
  apply Build_Natural
    with (transport := fun X =>
           @transport C D G K f X ∘ @transport C D F G g X).
  intros.
  rewrite comp_assoc.
  rewrite naturality.
  rewrite <- comp_assoc.
  rewrite naturality.
  rewrite comp_assoc.
  reflexivity.
Defined.

Lemma nat_irrelevance
  `(C : Category) `(D : Category) `(F : @Functor C D) `(G : @Functor C D)
  : ∀ (f g : ∀ {X}, F X ~> G X) n n',
  @f = @g ->
  {| transport := @f; naturality := n |} =
  {| transport := @g; naturality := n' |}.
Proof.
  intros. subst. f_equal.
  apply proof_irrelevance.
Qed.

(* Nat is the category whose morphisms are natural transformations between
   Functors from C ⟶ D. *)

Instance Nat (C : Category) (D : Category) : Category :=
{ ob      := Functor C D
; hom     := @Natural C D
; id      := @nat_identity C D
; compose := fun _ _ _ => nat_compose
}.
Proof.
  - (* right_identity *)
    intros.
    destruct f.
    apply nat_irrelevance.
    extensionality a.
    unfold nat_identity, nat_compose.
    simpl. rewrite right_identity.
    reflexivity.
  - (* left_identity *)
    intros.
    destruct f.
    apply nat_irrelevance.
    extensionality a.
    unfold nat_identity, nat_compose.
    simpl. rewrite left_identity.
    reflexivity.
  - (* comp_assoc *)
    intros.
    destruct f.
    destruct g.
    destruct h.
    apply nat_irrelevance.
    extensionality a.
    unfold nat_identity, nat_compose.
    simpl. rewrite <- comp_assoc.
    reflexivity.
Defined.

Notation "C ⟹ D" := (Nat C D) (at level 90, right associativity).

Definition Copresheaves (C : Category) := C ⟹ Sets.
Definition Presheaves   (C : Category) := C^op ⟹ Sets.

(*
Bifunctors can be curried:

  C × D ⟶ E   -->  C ⟶ D ⟹ E
  ~~~
  (C, D) -> E  -->  C -> D -> E

Where ~~~ should be read as "Morally equivalent to".

Note: We do not need to define Bifunctors as a separate class, since they can
be derived from functors mapping to a category of functors.  So in the
following two definitions, [P] is effectively our bifunctor.

The trick to [bimap] is that both the [Functor] instances we need (for [fmap]
and [fmap1]), and the [Natural] instance, can be found in the category of
functors we're mapping to by applying [P].
*)

Definition fmap1 `{P : C ⟶ D ⟹ E} `(f : X ~{D}~> Y) {A : C} :
  P A X ~{E}~> P A Y := fmap f.

Definition bimap `{P : C ⟶ D ⟹ E} `(f : X ~{C}~> W) `(g : Y ~{D}~> Z) :
  P X Y ~{E}~> P W Z := let N := @fmap _ _ P _ _ f in transport/N ∘ fmap1 g.

Definition contramap `{F : C^op ⟶ D} `(f : X ~{C}~> Y) :
  F Y ~{D}~> F X := fmap (unop f).

Definition dimap `{P : C^op ⟶ D ⟹ E} `(f : X ~{C}~> W) `(g : Y ~{D}~> Z) :
  P W Y ~{E}~> P X Z := bimap (unop f) g.

(* The Identity [Functor] *)

Definition Id `(C : Category) : Functor C C.
  apply Build_Functor with
    (fobj := fun X => X)
    (fmap := fun X X f => f); crush.
Defined.

Program Instance CoArrow {A : Type} : Arr ⟶ Arr :=
{ fobj := fun Y => A → Y
; fmap := fun _ _ f g => f ∘ g
}.

Program Instance ContraArrow {A : Type} : Arr^op ⟶ Arr :=
{ fobj := fun Y => Y → A
; fmap := fun _ _ f g x => g (unop f x)
}.

Program Instance Arrow : Arr^op ⟶ Arr ⟹ Arr :=
{ fobj := @CoArrow
; fmap := fun _ _ f => {| transport := fun X g x => g (unop f x) |}
}.

Class FullyFaithful `(F : @Functor C D) :=
{ unfmap : ∀ {X Y : C}, (F X ~> F Y) → (X ~> Y)
}.

Program Instance Arrow_Faithful : FullyFaithful Arrow :=
{ unfmap := fun _ _ f => (transport/f) (fun X => X)
}.

Instance CoHom `(C : Category) (X : C) : C ⟶ Sets :=
{ fobj := @hom C X
; fmap := @compose C X
}.
Proof.
  - (* fun_identity *)    intros. extensionality e. crush.
  - (* fun_composition *) intros. extensionality e. crush.
Admitted.

Instance Hom `(C : Category) : C ⟶ C ⟹ Sets :=
{ fobj := @CoHom C
; fmap := fun X Y f => @transport C (C ⟹ Sets) _ _ _ f
}.
Proof.
  - (* fun_identity *)    intros. extensionality e. crush.
  - (* fun_composition *) intros. extensionality e. crush.
Defined.

(* Covariant Yoneda, as opposed to ContraYoneda. *)
Program Instance CoYoneda `(C : Category) : Yoneda C ⟶ Hom.
{ fobj := fun Y => Y
; fmap := fun _ _ f x => (transport/f) (op f x)
}.

Program Instance Yoneda_Functor `(C : Category) : C ⟶ Yoneda C ⟹ Arr :=
{ fobj := fun Y => Y
; fmap := fun _ _ f x => (transport/f) (op f x)
}.