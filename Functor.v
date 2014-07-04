Require Import Coq.Init.Datatypes.
Require Import ZArith Permutation Omega List Classical_sets.
Require Import FunctionalExtensionality.
Require Export CpdtTactics.

Require Setoid.

Axiom prop_ext: ClassicalFacts.prop_extensionality.

Implicit Arguments prop_ext.

Close Scope nat_scope.

Ltac inv H := inversion H; subst; clear H.

(* Set Implicit Arguments. *)

Axiom ext_eq : forall {T1 T2 : Type} (f1 f2 : T1 -> T2),
  (forall x, f1 x = f2 x) -> f1 = f2.

Theorem ext_eqS : forall (T1 T2 : Type) (f1 f2 : T1 -> T2),
  (forall x, f1 x = f2 x) -> f1 = f2.
Proof. intros; rewrite (ext_eq f1 f2); auto. Qed.

Hint Resolve ext_eq.
Hint Resolve ext_eqS.

Ltac ext_eq := (apply ext_eq || apply ext_eqS); intro.
Ltac crush_ext := (intros; ext_eq; crush); intro.

Definition id {X} (a : X) : X := a.

Theorem id_x : forall {A} (f : A -> A) (x : A),
  f = id -> f x = x.
Proof. crush. Defined.

Definition compose {A B C}
  (f : B -> C) (g : A -> B) (x : A) : C := f (g x).

Notation "f ∘ g" := (compose f g) (at level 69, right associativity).

Theorem comp_id_left : forall {A B} (f : A -> B),
  id ∘ f = f.
Proof. crush. Defined.

Theorem comp_id_right : forall {A B} (f : A -> B),
  f ∘ id = f.
Proof. crush. Defined.

Theorem comp_assoc : forall {A B C D} (f : C -> D) (g : B -> C) (h : A -> B),
  f ∘ g ∘ h = (f ∘ g) ∘ h.
Proof. crush. Defined.

Theorem uncompose : forall {A B C} (f : B -> C) (g : A -> B) (x : A) (y : C),
  (f ∘ g) x = f (g x).
Proof. crush. Defined.

Theorem compose_x : forall {A B C} (f : B -> C) (g : A -> B) (x : A) (y : C),
  (f ∘ g) x = y -> f (g x) = y.
Proof. crush. Defined.

Class Isomorphism X Y :=
{ to   : X -> Y
; from : Y -> X

; iso_to   : from ∘ to = id
; iso_from : to ∘ from = id
}.
  Arguments to       {X} {Y} {Isomorphism} x.
  Arguments from     {X} {Y} {Isomorphism} x.
  Arguments iso_to   {X} {Y} {Isomorphism}.
  Arguments iso_from {X} {Y} {Isomorphism}.

Hint Resolve id_x.
Hint Resolve compose_x.
Hint Resolve iso_to.
Hint Resolve iso_from.

Notation "X ≅ Y" := (Isomorphism X Y) (at level 50) : type_scope.
Notation "x ≡ y" := (to x = y /\ from y = x) (at level 50).

Theorem iso_to_x : forall {X Y} `{X ≅ Y} (x : X), from (to x) = x.
Proof. crush. Defined.

Theorem iso_from_x : forall {X Y} `{X ≅ Y} (y : Y), to (from y) = y.
Proof. crush. Defined.

Hint Resolve iso_to_x.
Hint Resolve iso_from_x.

(* Even though we have the Category class in Category.v, the Functors
   and Monads I'm interested in reasoning about are all endofunctors on
   Coq, so there is no reason to carry around that extra machinery. *)

Class Functor (F : Type -> Type) :=
{ fobj := F
; fmap : forall {X Y}, (X -> Y) -> F X -> F Y

; fun_identity : forall {X}, fmap (@id X) = id
; fun_composition : forall {X Y Z} (f : Y -> Z) (g : X -> Y),
    fmap f ∘ fmap g = fmap (f ∘ g)
}.
  Arguments fmap            [F] [Functor] [X] [Y] f g.
  Arguments fun_identity    [F] [Functor] [X].
  Arguments fun_composition [F] [Functor] [X] [Y] [Z] f g.

Hint Resolve fun_identity.
Hint Resolve fun_composition.

Notation "f <$> g" := (fmap f g) (at level 68, left associativity).

Notation "fmap[ M ]  f" := (@fmap M _ _ _ f) (at level 68).
Notation "fmap[ M N ]  f" := (@fmap (fun X => M (N X)) _ _ _ f) (at level 66).
Notation "fmap[ M N O ]  f" := (@fmap (fun X => M (N (O X))) _ _ _ f) (at level 64).

Theorem fun_identity_x
  : forall (F : Type -> Type) (app_dict : Functor F) {X} (x : F X),
  fmap id x = id x.
Proof. crush. Defined.

Hint Resolve fun_identity_x.

Theorem fun_composition_x
  : forall (F : Type -> Type) (app_dict : Functor F)
      {X Y Z} (f : Y -> Z) (g : X -> Y) (x : F X),
  f <$> (g <$> x) = (f ∘ g) <$> x.
Proof. intros. rewrite <- fun_composition. reflexivity.  Defined.

Hint Resolve fun_composition_x.

Global Instance Functor_Isomorphism
  {F : Type -> Type} `{Functor F} {A B} `(A ≅ B) : F A ≅ F B :=
{ to   := fmap to
; from := fmap from
}.
Proof.
  - rewrite fun_composition. rewrite iso_to. crush.
  - rewrite fun_composition. rewrite iso_from. crush.
Defined.

Reserved Notation "f <*> g" (at level 68, left associativity).

Class Applicative (F : Type -> Type) :=
{ is_functor :> Functor F

; eta : forall {X}, X -> F X
; apply : forall {X Y}, F (X -> Y) -> F X -> F Y
    where "f <*> g" := (apply f g)

; app_identity : forall {X}, apply (eta (@id X)) = id
; app_composition : forall {X Y Z} (v : F (X -> Y)) (u : F (Y -> Z)) (w : F X),
    eta compose <*> u <*> v <*> w = u <*> (v <*> w)
; app_homomorphism : forall {X Y} (x : X) (f : X -> Y),
    eta f <*> eta x = eta (f x)
; app_interchange : forall {X Y} (y : X) (u : F (X -> Y)),
    u <*> eta y = eta (fun f => f y) <*> u
; app_fmap_unit : forall {X Y} (f : X -> Y), apply (eta f) = fmap f
}.

Notation "eta/ M" := (@eta M _ _) (at level 68).
Notation "eta/ M N" := (@eta (fun X => M (N X)) _ _) (at level 66).

Theorem app_fmap_compose
  : forall (F : Type -> Type) `{Applicative F} A B (f : A -> B),
  eta ∘ f = fmap f ∘ eta.
Proof.
  intros. ext_eq. unfold compose.
  rewrite <- app_homomorphism.
  rewrite app_fmap_unit. reflexivity.
Defined.

Theorem app_fmap_compose_x
  : forall (F : Type -> Type) `{Applicative F} A B (f : A -> B) (x : A),
  eta (f x) = fmap f (eta x).
Proof.
  intros.
  assert (eta (f x) = (eta ∘ f) x). unfold compose. reflexivity.
  assert (fmap f (eta x) = (fmap f ∘ eta) x). unfold compose. reflexivity.
  rewrite H0. rewrite H1. rewrite app_fmap_compose. reflexivity.
Defined.

Hint Resolve app_identity.
Hint Resolve app_composition.
Hint Resolve app_homomorphism.
Hint Resolve app_interchange.
Hint Resolve app_fmap_unit.
Hint Resolve app_fmap_compose.

Notation "f <*> g" := (apply f g) (at level 68, left associativity).

Theorem app_identity_x
  : forall {F : Type -> Type} `{Applicative F} {X} {x : F X},
  apply (eta (@id X)) x = id x.
Proof.
  intros. rewrite app_fmap_unit. apply fun_identity_x.
Defined.

Notation "[| f x y .. z |]" := (.. (f <$> x <*> y) .. <*> z)
    (at level 9, left associativity, f at level 9,
     x at level 9, y at level 9, z at level 9).

Theorem app_homomorphism_2
  : forall {F : Type -> Type} {app_dict : Applicative F}
      {X Y Z} (x : X) (y : Y) (f : X -> Y -> Z),
  f <$> eta x <*> eta y = eta (f x y).
Proof.
  intros.
  rewrite <- app_homomorphism.
  rewrite <- app_homomorphism.
  rewrite app_fmap_unit. reflexivity.
Defined.

Hint Resolve app_homomorphism_2.

Definition flip {X Y} (x : X) (f : X -> Y) : Y := f x.

Theorem app_flip
  : forall {F : Type -> Type} {app_dict : Applicative F}
      {X Y} (x : F X) (f : X -> Y),
  eta f <*> x = eta flip <*> x <*> eta f.
Proof.
  intros. rewrite app_interchange.
  rewrite <- app_composition.
  rewrite app_fmap_unit.
  rewrite app_fmap_unit.
  rewrite app_homomorphism_2.
  unfold compose.
  rewrite app_fmap_unit. reflexivity.
Defined.

Definition app_unit {F : Type -> Type} `{Applicative F} : F unit := eta tt.

Global Instance LTuple_Isomorphism {A} : unit * A ≅ A :=
{ to   := @snd unit A
; from := pair tt
}.
Proof. crush_ext. crush. Defined.

Global Instance RTuple_Isomorphism {A} : A * unit ≅ A :=
{ to   := @fst A unit
; from := fun x => (x, tt)
}.
Proof. crush_ext. crush_ext. Defined.

Definition tuple_swap_a_bc_to_ab_c {A B C} (x : A * (B * C)) : A * B * C :=
  match x with
    (a, (b, c)) => ((a, b), c)
  end.

Definition tuple_swap_ab_c_to_a_bc {A B C} (x : A * B * C) : A * (B * C) :=
  match x with
    ((a, b), c) => (a, (b, c))
  end.

Definition left_triple {A B C} (x : A) (y : B) (z : C) : A * B * C :=
  ((x, y), z).

Definition right_triple {A B C} (x : A) (y : B) (z : C) : A * (B * C) :=
  (x, (y, z)).

Global Instance Tuple_Assoc {A B C} : A * B * C ≅ A * (B * C) :=
{ to   := tuple_swap_ab_c_to_a_bc
; from := tuple_swap_a_bc_to_ab_c
}.
Proof. crush_ext. crush_ext. Defined.

Definition uncurry {X Y Z} (f : X -> Y -> Z) (xy : X * Y) : Z :=
  match xy with (x, y) => f x y end.

Theorem uncurry_works : forall {X Y Z} (x : X) (y : Y) (f : X -> Y -> Z),
  uncurry f (x, y) = f x y.
Proof. crush. Defined.

Theorem uncurry_under_functors
  : forall {F : Type -> Type} {app_dict : Applicative F}
      {X Y Z} (x : X) (y : Y) (f : X -> Y -> Z),
  uncurry f <$> eta (x, y) = eta (f x y).
Proof.
  intros. rewrite <- app_fmap_unit.
  rewrite app_homomorphism. crush.
Defined.

Definition app_merge {X Y Z W} (f : X -> Y) (g : Z -> W)
  (t : X * Z) : Y * W  :=
  match t with (x, z) => (f x, g z) end.

Notation "f *** g" := (app_merge f g) (at level 68, left associativity).

Definition app_prod {F : Type -> Type} `{Applicative F}
  {X Y} (x : F X) (y : F Y) : F (X * Y) := pair <$> x <*> y.

Notation "f ** g" := (app_prod f g) (at level 68, left associativity).

Ltac rewrite_app_homomorphisms :=
  (repeat (rewrite <- app_fmap_unit);
   rewrite app_homomorphism;
   repeat (rewrite app_fmap_unit)).

Theorem app_embed
  : forall {F : Type -> Type} `{Applicative F}
      {G : Type -> Type} `{Applicative G}
      {X Y} (x : G (X -> Y)) (y : G X),
  eta (x <*> y) = eta apply <*> eta x <*> eta y.
Proof.
  intros.
  rewrite_app_homomorphisms.
  rewrite <- app_homomorphism.
  rewrite <- app_fmap_unit.
  reflexivity.
Defined.

Theorem app_eta_inj : forall {F : Type -> Type} `{Applicative F} {X} (x y : X),
  x = y -> eta x = eta y.
Proof. crush. Defined.

Theorem app_split
  : forall (F : Type -> Type) `{Applicative F}
      A B C (f : A -> B -> C) (x : F A) (y : F B),
  f <$> x <*> y = uncurry f <$> (x ** y).
Proof.
  intros. unfold app_prod.
  repeat (rewrite <- app_fmap_unit).
  repeat (rewrite <- app_composition; f_equal).
  repeat (rewrite app_homomorphism).
  crush.
Defined.

Theorem app_naturality
  : forall {F : Type -> Type} `{Applicative F}
      {A B C D} (f : A -> C) (g : B -> D) (u : F A) (v : F B),
  fmap (f *** g) (u ** v) = (fmap f u) ** (fmap g v).
Proof.
  intros. unfold app_prod.
  rewrite <- app_fmap_unit.
  rewrite fun_composition_x.
  repeat (rewrite <- app_fmap_unit).
  rewrite <- app_composition.
  rewrite <- app_composition.
  rewrite <- app_composition.
  rewrite <- app_composition.
  rewrite app_composition.
  rewrite app_composition.
  f_equal.
  rewrite_app_homomorphisms.
  rewrite fun_composition_x.
  rewrite fun_composition_x.
  rewrite app_interchange.
  rewrite app_fmap_unit.
  rewrite fun_composition_x.
  f_equal.
Qed.

Theorem app_left_identity
  : forall (F : Type -> Type) `{Applicative F} {A} (v : F A),
  (eta tt ** v) ≡ v.
Proof.
  intros. unfold app_prod, app_unit. rewrite_app_homomorphisms.
  split.
    assert (fmap (pair tt) =
            (@from (F (unit * A)) (F A) 
                   (Functor_Isomorphism LTuple_Isomorphism))).
      reflexivity. rewrite H0.
    apply iso_from_x.
    reflexivity.
Defined.

Theorem app_right_identity
  : forall (F : Type -> Type)`{Applicative F} {A : Type} (v : F A),
  (v ** eta tt) ≡ v.
Proof.
  intros. unfold app_prod, app_unit.
  rewrite <- app_fmap_unit.
  rewrite app_interchange.
  rewrite <- app_composition.
  rewrite app_homomorphism.
  rewrite app_homomorphism.
  rewrite app_fmap_unit.
  unfold compose.

  split.
    assert (fmap (fun x : A => (x, tt)) =
            (@from (F (A * unit)) (F A) 
                   (Functor_Isomorphism RTuple_Isomorphism))).
      reflexivity. rewrite H0.
    apply iso_from_x. 
    reflexivity.
Defined.

Theorem app_embed_left_triple
  : forall {F : Type -> Type} `{app_dict : Applicative F}
      A B C (u : F A) (v : F B) (w : F C),
  u ** v ** w = left_triple <$> u <*> v <*> w.
Proof.
  intros. unfold app_prod.
  repeat (rewrite <- app_fmap_unit).
  rewrite <- app_composition.
  f_equal. f_equal.
  rewrite_app_homomorphisms.
  rewrite fun_composition_x.
  reflexivity.
Defined.

Theorem app_embed_right_triple
  : forall {F : Type -> Type} `{app_dict : Applicative F}
      A B C (u : F A) (v : F B) (w : F C),
  u ** (v ** w) = right_triple <$> u <*> v <*> w.
Proof.
  intros. unfold app_prod.
  repeat (rewrite <- app_fmap_unit).
  rewrite <- app_composition.
  f_equal. f_equal.
  repeat (rewrite app_fmap_unit).
  rewrite fun_composition_x.
  repeat (rewrite <- app_fmap_unit).
  rewrite <- app_composition.
  f_equal.
  repeat (rewrite app_fmap_unit).
  rewrite fun_composition_x.
  rewrite app_interchange.
  rewrite app_fmap_unit.
  rewrite fun_composition_x.
  unfold compose.
  reflexivity.
Defined.

Theorem app_associativity
  : forall {F : Type -> Type} `{app_dict : Applicative F}
      A B C (u : F A) (v : F B) (w : F C),
  ((u ** v) ** w) ≡ (u ** (v ** w)).
Proof.
  intros.
  rewrite app_embed_left_triple.
  rewrite app_embed_right_triple.
  unfold left_triple.
  unfold right_triple.
  assert (forall {X Y Z} (x : X) (y : Y) (z : Z),
          left_triple x y z ≡ right_triple x y z).
    intros. split; reflexivity.
  split; simpl.
  - (* pose proof (@iso_to_x (F (A * B * C)) (F (A * (B * C))) *)
    (*                       (Functor_Isomorphism Tuple_Assoc)). *)
    (* specialize (H0 (u ** v ** w)). *)
    (* rewrite <- H0. simpl. *)
    (* repeat (rewrite fun_composition_x). *)
    (* repeat f_equal. *)
    (* ext_eq. unfold compose. *)
    specialize (H (F A) (F B) (F C) u v w).
    inversion H.
    admit.
  - repeat (rewrite <- app_split).
    admit.
Abort.

Theorem fmap_unit_eq
  : forall (F : Type -> Type) `{Applicative F} A B (f : A -> B) (x : A),
  fmap f (eta x) = eta (f x).
Proof.
  intros.
  rewrite <- app_fmap_unit.
  rewrite app_interchange.
  rewrite app_homomorphism.
  reflexivity.
Defined.

Definition liftA2 {F : Type -> Type} {app_dict : Applicative F}
  {A B C} (f : A -> B -> C) (x : F A) (y : F B) : F C := f <$> x <*> y.

Class Monad (M : Type -> Type) :=
{ is_applicative :> Applicative M

; mu : forall {X}, M (M X) -> M X

; monad_law_1 : forall {X}, mu ∘ fmap mu = (@mu X) ∘ mu
; monad_law_2 : forall {X}, mu ∘ fmap (@eta M is_applicative X) = id
; monad_law_3 : forall {X}, (@mu X) ∘ eta = id
; monad_law_4 : forall {X Y} (f : X -> Y), mu ∘ fmap (fmap f) = fmap f ∘ mu
}.

Notation "mu/ M" := (@mu M _ _) (at level 68).
Notation "mu/ M N" := (@mu (fun X => M (N X)) _ _) (at level 66).

Definition bind {M} `{Monad M} {X Y}
  (f : (X -> M Y)) (x : M X) : M Y := mu (fmap f x).

Notation "m >>= f" := (bind f m) (at level 67, left associativity).

Theorem monad_law_1_x
  : forall (M : Type -> Type) (m_dict : Monad M) A (x : M (M (M A))),
  mu (fmap mu x) = (@mu M m_dict A) (mu x).
Proof.
  intros.
  assert (mu (fmap mu x) = (mu ∘ fmap mu) x). unfold compose. reflexivity.
  assert (mu (mu x) = (mu ∘ mu) x). unfold compose. reflexivity.
  rewrite H. rewrite H0. rewrite monad_law_1. reflexivity.
Defined.

Theorem monad_law_2_x
  : forall (M : Type -> Type) (m_dict : Monad M) A (x : M A),
  mu (fmap (@eta M _ A) x) = x.
Proof.
  intros.
  assert (mu (fmap eta x) = (mu ∘ fmap eta) x). unfold compose. reflexivity.
  rewrite H. rewrite monad_law_2. reflexivity.
Defined.

Theorem monad_law_3_x
  : forall (M : Type -> Type) (m_dict : Monad M) A (x : M A),
  (@mu M m_dict A) (eta x) = x.
Proof.
  intros.
  assert (mu (eta x) = (mu ∘ eta) x). unfold compose. reflexivity.
  rewrite H. rewrite monad_law_3. reflexivity.
Defined.

Theorem monad_law_4_x
  : forall (M : Type -> Type) (m_dict : Monad M)
      A B (f : A -> B) (x : M (M A)),
  mu (fmap (fmap f) x) = fmap f (mu x).
Proof.
  intros.
  assert (mu (fmap (fmap f) x) = (mu ∘ fmap (fmap f)) x).
    unfold compose. reflexivity.
  assert (fmap f (mu x) = (fmap f ∘ mu) x). unfold compose. reflexivity.
  rewrite H. rewrite H0. rewrite monad_law_4. reflexivity.
Defined.

(* Composition of functors produces a functor. *)

Definition compose_fmap
  (F : Type -> Type) (G : Type -> Type)
  `{Functor F} `{Functor G} {A B} :=
  (@fmap F _ (G A) (G B)) ∘ (@fmap G _ A B).

Global Instance Functor_Compose
  (F : Type -> Type) (G : Type -> Type) `{Functor F} `{Functor G}
  : Functor (fun X => F (G X)) :=
{ fmap := fun _ _ => compose_fmap F G
}.
Proof.
  - (* fun_identity *)
    intros. ext_eq. unfold compose_fmap, compose.
    rewrite fun_identity.
    rewrite fun_identity. reflexivity.

  - (* fun_composition *)
    intros. ext_eq. unfold compose_fmap, compose.
    rewrite fun_composition_x.
    rewrite fun_composition. reflexivity.
Defined.

Theorem fmap_compose
  : forall (F : Type -> Type) (G : Type -> Type)
      `{f_dict : Functor F} `{g_dict : Functor G}
      {X Y} (f : X -> Y),
  (@fmap F f_dict (G X) (G Y) (@fmap G g_dict X Y f)) =
  (@fmap (fun X => F (G X)) _ X Y f).
Proof.
  intros. simpl. unfold compose_fmap. reflexivity.
Qed.

(* Composition of applicatives produces an applicative. *)

Definition compose_eta (F : Type -> Type) (G : Type -> Type)
  `{Applicative F} `{Applicative G} {A} : A -> F (G A) :=
  (@eta F _ (G A)) ∘ (@eta G _ A).

Definition compose_apply (F : Type -> Type) (G : Type -> Type)
  `{Applicative F} `{Applicative G} {A B}
  : F (G (A -> B)) -> F (G A) -> F (G B) :=
  apply ∘ fmap (@apply G _ A B).

Global Instance Applicative_Compose
  (F : Type -> Type) (G : Type -> Type)
  `{f_dict : Applicative F} `{g_dict : Applicative G}
  : Applicative (fun X => F (G X))  :=
{ is_functor := Functor_Compose F G
; eta := fun _ => compose_eta F G
; apply := fun _ _ => compose_apply F G
}.
Proof.
  - (* app_identity *) intros.
    ext_eq. unfold compose_apply, compose_eta, compose.
    rewrite <- app_fmap_unit.
    rewrite app_homomorphism.
    rewrite app_identity.
    rewrite app_fmap_unit.
    rewrite fun_identity.
    reflexivity.

  - (* app_composition *) intros.
    (* apply <$> (apply <$> (apply <$> eta (eta compose) <*> u) <*> v) <*> w =
       apply <$> u <*> (apply <$> v <*> w) *)
    unfold compose_apply, compose_eta, compose.
    rewrite <- app_composition.
    f_equal.
    rewrite_app_homomorphisms.
    rewrite fun_composition_x.
    rewrite app_split.
    rewrite app_split.
    rewrite <- app_naturality.
    rewrite fun_composition_x.
    rewrite fun_composition_x.
    f_equal. ext_eq.
    destruct x.
    unfold compose at 3.
    unfold app_merge.
    rewrite uncurry_works.
    unfold compose at 1.
    unfold compose at 1.
    rewrite uncurry_works.
    ext_eq.
    rewrite <- app_fmap_unit.
    rewrite app_composition.
    unfold compose.
    reflexivity.

  - (* app_homomorphism *) intros.
    unfold compose_apply, compose_eta, compose.
    rewrite <- app_fmap_unit.
    repeat (rewrite app_homomorphism).
    reflexivity.

  - (* app_interchange *) intros.
    unfold compose_apply, compose_eta, compose.
    repeat (rewrite <- app_fmap_unit).
    rewrite app_interchange.
    rewrite_app_homomorphisms.
    rewrite fun_composition_x.
    unfold compose. f_equal. ext_eq.
    rewrite <- app_fmap_unit.
    rewrite app_interchange.
    reflexivity.

  - (* app_fmap_unit *) intros.
    unfold compose_apply, compose_eta, compose.
    rewrite_app_homomorphisms.
    reflexivity.
Defined.

(* "Suppose that (S,μˢ,ηˢ) and (T,μᵗ,ηᵗ) are two monads on a category C.  In
   general, there is no natural monad structure on the composite functor ST.
   On the other hand, there is a natural monad structure on the functor ST if
   there is a distribute law of the monad S over the monad T."

     http://en.wikipedia.org/wiki/Distr_law_between_monads

   My main source for this material was the paper "Composing monads":

     http://citeseerx.ist.psu.edu/viewdoc/summary?doi=10.1.1.138.4552
*)
Class MonadDistribute (M : Type -> Type) (N : Type -> Type)
  `{Monad M} `{Monad N} `{Monad (fun X => M (N X))} :=
{ swap {A : Type} : N (M A) -> M (N A) :=
    (@mu (fun X => M (N X)) _ A) ∘ (@eta M _ _) ∘ (fmap (fmap eta))
; prod {A : Type} : N (M (N A)) -> M (N A) :=
    (@mu (fun X => M (N X)) _ A) ∘ (@eta M _ (N (M (N A))))
; dorp {A : Type} : M (N (M A)) -> M (N A) :=
    (@mu (fun A => M (N A)) _ A) ∘ (@fmap (fun A => M (N A)) _ _ _ (fmap eta))

; swap_law_1 : forall {A B : Type} (f : (A -> B)),
    swap ∘ fmap (fmap f) = fmap (fmap f) ∘ swap
; swap_law_2 : forall {A : Type},
    swap ∘ eta = fmap (@eta N _ A)
; swap_law_3 : forall {A : Type},
    swap ∘ fmap (@eta M _ A) = eta
; swap_law_4 : forall {A : Type},
    prod ∘ fmap (@dorp A) = dorp ∘ prod
}.

Definition compose_mu (M : Type -> Type) (N : Type -> Type)
  `{Monad M} `{Monad N} `{MonadDistribute M N} {A}
  : M (N (M (N A))) -> M (N A) := fmap mu ∘ mu ∘ fmap swap.

Global Instance Monad_Compose (M : Type -> Type) (N : Type -> Type)
  `{Monad M} `{Monad N} `{MonadDistribute M N}
  : Monad (fun X => M (N X)) :=
{ is_applicative := Applicative_Compose M N
; mu := fun _ => compose_mu M N
}.
Proof.
  - (* monad_law_1 *) intros.
    unfold compose_mu, prod. f_equal. simpl.
    unfold compose_fmap.
    unfold compose at 1.
    (* fmap[M N] compose_mu M N = compose_mu M N *)
    admit.

  - (* monad_law_2 *) intros.
    repeat (rewrite <- comp_assoc).
    unfold swap.

    (* fmap mu ∘ mu ∘ fmap (distr (N X)) ∘ fmap eta = id *)

    admit.

  - (* monad_law_3 *) intros.
    repeat (rewrite <- comp_assoc).
    unfold swap.

    (* fmap mu ∘ mu ∘ fmap (distr (N X)) ∘ eta = id *)

    admit.

  - (* monad_law_4 *) intros.
    repeat (rewrite <- comp_assoc).
    unfold swap.

    (* fmap mu ∘ mu ∘ fmap (distr (N Y)) ∘ fmap (fmap f) =
       fmap f ∘ fmap mu ∘ mu ∘ fmap (distr (N X)) *)

    admit.
Defined.

Class CompoundMonad (M : Type -> Type) (N : Type -> Type)
  `{Applicative M} `{Applicative N} `{Monad (fun X => M (N X))} :=
{ dunit : forall {α : Type}, M α -> M (N α)
; dmap  : forall {α β : Type}, (α -> M β) -> M (N α) -> M (N β)
; djoin : forall {α : Type}, M (N (N α)) -> M (N α)

; compound_law_1 : forall {A : Type},
    dmap (@eta M _ A) = id
; compound_law_2 : forall {A B C : Type} (f : (B -> M C)) (g : (A -> B)),
    dmap (f ∘ g) = dmap f ∘ (@fmap (fun A => M (N A)) _ _ _ g)
; compound_law_3 : forall {A B : Type} (f : (A -> M A)),
    dmap f ∘ (@eta (fun A => M (N A)) _ A) = @dunit A ∘ f
; compound_law_4 : forall {A B : Type} (f : (A -> M B)),
    djoin ∘ dmap (dmap f) = dmap f ∘ (@mu (fun A => M (N A)) _ A)
; compound_law_5 : forall {A : Type},
    @djoin A ∘ dunit = id
; compound_law_6 : forall {A : Type},
    djoin ∘ dmap (@eta (fun A => M (N A)) _ A) = id
; compound_law_7 : forall {A : Type},
    djoin ∘ dmap djoin = djoin ∘ (@mu (fun A => M (N A)) _ (N A))
; compound_law_8 : forall {A B : Type} (f : A -> M (N B)),
    (@bind (fun A => M (N A)) _ A B f) = djoin ∘ dmap f
}.

(* "The following definition captures the idea that a triple with functor T2 ∘
    T1 is in a natural way the composite of triples with functors T2 and T1."

   "Toposes, Triples and Theories", Barr and Wells
*)
Class MonadCompatible (M : Type -> Type) (N : Type -> Type)
  `{Monad M} `{Monad N} `{Monad (fun X => M (N X))} :=
{ compatible_1a : forall {A : Type},
    fmap (@eta N _ A) ∘ (@eta M _ A) = (@eta (fun X => M (N X)) _ A)
; compatible_1b : forall {A : Type},
    (@eta M _ (N A)) ∘ (@eta N _ A) = (@eta (fun X => M (N X)) _ A)
; compatible_2 : forall {A : Type},
    (@mu (fun X => M (N X)) _ A) ∘ fmap (fmap (@eta M _ (N A))) =
    fmap (@mu N _ A)
; compatible_3 : forall {A : Type},
    (@mu (fun X => M (N X)) _ A) ∘ fmap eta = (@mu M _ (N A))
}.

(* These proofs are due to Jeremy E. Dawson in "Categories and Monads in
   HOL-Omega".
*)
Theorem compatible_4 : forall (M : Type -> Type) (N : Type -> Type)
  `{Monad M} `{Monad N} `{MonadCompatible M N} {A},
  (@mu M _ (N A)) ∘ fmap (@mu (fun X => M (N X)) _ A) =
  (@mu (fun X => M (N X)) _ A) ∘ (@mu M _ (N (M (N A)))).
Proof.
  intros.
  rewrite <- compatible_3.
  rewrite <- compatible_3.
  rewrite compatible_3. 
  rewrite comp_assoc.
  rewrite <- (@monad_law_1 (fun X => M (N X)) _).
  rewrite <- comp_assoc.
  replace (@fmap (fun X => M (N X)) _ _ _ (@mu (fun X => M (N X)) _ A))
    with (@fmap M _ _ _ ((@fmap N _ _ _ (@mu (fun X => M (N X)) _ A)))).
    rewrite fun_composition.
    assert ((@eta N _ (M (N A))) ∘ (@mu (fun X => M (N X)) _ A) =
            fmap (@mu (fun X => M (N X)) _ A) ∘ (@eta N _ (M (N (M (N A)))))).
      ext_eq. unfold compose.
      rewrite <- app_homomorphism.
      rewrite <- app_fmap_unit.
      reflexivity.
    rewrite <- H5.
    rewrite <- fun_composition.
    rewrite <- compatible_3.
    reflexivity.
  rewrite fmap_compose.
  Set Printing All.
Abort.
