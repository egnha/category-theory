Set Warnings "-notation-overridden".

Require Import Category.Lib.
Require Export Category.Theory.Category.

Generalizable All Variables.
Set Primitive Projections.
Set Universe Polymorphism.

Section Product.

Context `{C : Category}.
Context `{D : Category}.

(* A Groupoid is a category where all morphisms are isomorphisms, and morphism
   equivalence is equivalence of isomorphisms. *)

Program Instance Product : Category := {
  ob      := C * D;
  hom     := fun X Y => (fst X ~> fst Y) * (snd X ~> snd Y);
  homset  := fun _ _ => {| cequiv := fun f g =>
                             (fst f ≋ fst g) * (snd f ≋ snd g) |} ;
  id      := fun _ => (id, id);
  compose := fun _ _ _ f g => (fst f ∘ fst g, snd f ∘ snd g)
}.
Next Obligation.
  proper.
  split; simpl.
    apply compose_respects.
      destruct X; assumption.
    destruct X0; assumption.
  apply compose_respects.
    destruct X; assumption.
  destruct X0; assumption.
Defined.
Next Obligation.
  split; simpl.
    split; simpl in *.
Abort.

End Product.

Notation "C ∏ D" := (@Product C D) (at level 90) : category_scope.
