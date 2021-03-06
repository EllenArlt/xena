import analysis.topology.topological_space data.set 
universes u v

structure ring_morphism (α : Type u) (β : Type v) (Ra : comm_ring α) (Rb : comm_ring β) :=
(f : α → β)
(f_zero : f 0 = 0)
(f_one : f 1 = 1)
(f_add : ∀ {a₁ a₂ : α}, f (a₁ + a₂) = f a₁ + f a₂)
(f_mul : ∀ {a₁ a₂ : α}, f (a₁ * a₂) = f a₁ * f a₂) 

structure presheaf_of_rings (α : Type u) [T : topological_space α] 
  (F : Π U : set α, T.is_open U → Type) :=
[Fring : ∀ U O, comm_ring (F U O)]
(res : ∀ (U V : set α) (OU : T.is_open U) (OV : T.is_open V) (H : V ⊆ U), 
  ring_morphism (F U OU) (F V OV) (Fring U OU) (Fring V OV))
(Hid : ∀ (U : set α) (OU : T.is_open U), (res U U OU OU (set.subset.refl _)).f = id)  
(Hcomp : ∀ (U V W : set α) (OU : T.is_open U) (OV : T.is_open V) (OW : T.is_open W)
  (HUV : V ⊆ U) (HVW : W ⊆ V),
  (res U W OU OW (set.subset.trans HVW HUV)).f = (res V W OV OW HVW).f ∘ (res U V OU OV HUV).f )

def inter {α : Type u} [ T : topological_space α] (U V : {U : set α // T.is_open U})
: {U : set α // T.is_open U} :=
begin
let W : set α := U.val ∩ V.val,
have W_is_open : T.is_open W := T.is_open_inter U.1 V.1 U.2 V.2,
exact ⟨W,W_is_open⟩,
end

lemma inter_sub_left {α : Type u} [T : topological_space α] 
  (U V : {U : set α // T.is_open U}) : (inter U V).1 ⊆ U.1 :=
λ x Hx,Hx.left

lemma inter_sub_right {α : Type u} [T : topological_space α] 
  (U V : {U : set α // T.is_open U}) : (inter U V).1 ⊆ V.1 :=
λ x Hx,Hx.right

def res_to_inter_left {α : Type u} [T : topological_space α] 
  (F : Π U : set α, T.is_open U → Type)
  (FP : presheaf_of_rings α F) 
  (U V : set α) (OU : T.is_open U) (OV : T.is_open V) : 
    ring_morphism (F U OU) (F (U ∩ V) (T.is_open_inter U V OU OV)) (FP.Fring _ _) (FP.Fring _ _):=
begin
let W := U ∩ V,
exact (FP.res U W OU _ (set.inter_subset_left U V))
end

def res_to_inter_right {α : Type u} [T : topological_space α]
  (F : Π U : set α, T.is_open U → Type)
  (FP : presheaf_of_rings α F)
  (U V : set α) (OU:...)
  ({U : set α // T.is_open U}) : ring_morphism _ _ _ _ :=
begin
let W := inter U V,
exact (FP.res V W (inter_sub_right U V))
end

lemma cov_is_subs {α : Type u} [T : topological_space α]
  (U : {U : set α // T.is_open U}) 
  {γ : Type v} (Ui : γ → {U : set α // T.is_open U}) 
  (Hcov : (⋃ (x : γ), (Ui x).1) = U.1) : ∀ x : γ, (Ui x).1 ⊆ U.1 :=
begin
have H₁ : (⋃ (x : γ), (Ui x).1) ⊆ U.1,
{ rw Hcov,
  exact set.subset.refl _ },
have H₂ := set.Union_subset_iff.1 H₁,
exact H₂,
end 

def gluing {α : Type u} [T : topological_space α] (FP : presheaf_of_rings α)
  (U : {U : set α // T.is_open U}) 
  {γ : Type v} (Ui : γ → {U : set α // T.is_open U}) 
  (Hcov : (⋃ (x : γ), (Ui x).1) = U.1) : 
  (FP.F U) → {a : (Π (x : γ), (FP.F (Ui x))) | ∀ (x y : γ), 
    (res_to_inter_left FP (Ui x) (Ui y)).f (a x) = 
    (res_to_inter_right FP (Ui x) (Ui y)).f (a y)} :=
begin
intro r,
existsi (λ x,(FP.res U (Ui x) (cov_is_subs U Ui Hcov x)).f r),
intros x₁ y₁,
show (
      (FP.res (Ui x₁) (inter (Ui x₁) (Ui y₁)) _).f ∘ (FP.res U (Ui x₁) _).f) r =
      ((FP.res (Ui y₁) (inter (Ui x₁) (Ui y₁)) _).f ∘ (FP.res U (Ui y₁) _).f) r,
rw [←(FP.Hcomp (cov_is_subs U Ui Hcov x₁) (inter_sub_left  (Ui x₁) (Ui y₁)))],
rw [←(FP.Hcomp (cov_is_subs U Ui Hcov y₁) (inter_sub_right (Ui x₁) (Ui y₁)))],
end

structure sheaf_of_rings (α : Type u) [T : topological_space α] :=
(FP : presheaf_of_rings α)
(Fsheaf : ∀ (U : {U : set α // T.is_open U}) 
          {γ : Type} (Ui : γ → {U : set α // T.is_open U}) 
          (Hcov : (⋃ (x : γ), (Ui x).1) = U.1),
            function.bijective (gluing FP U Ui Hcov)
)

structure ideal (R : Type u) [RR : comm_ring R] :=
(I_set : set R)
(I_zero : RR.zero ∈ I_set)
(I_ab_group : ∀ a b : R, a ∈ I_set → b ∈ I_set → a-b ∈ I_set)
(I_module : ∀ (r : R) (i ∈ I_set), r*i ∈ I_set)




/-

Mario said: "ring_morphism: make Ra and Rb instance implicit" -- try this later

Uncurrying will save you the trouble of stuff like def inter and
inter_sub_left which are duplicates of existing theorems

Note that you can mark fields as instance implicit too

and by make F a parameter I meant this

structure presheaf_of_rings (α : Type u) [topological_space α] (F : Π U : set α, is_open U → Type) :=
[Fring : ∀ U O, comm_ring (F U O)]

It's good for the digestion if you've had too much curry

    why don't you use add_comm_group?

Re: ideal, you should have a is_subgroup predicate for asserting that I is closed under group operations for this
It should be similar to is_submodule in algebra/module
Mario Carneiro
@digama0
05:26

    with now no clue as to how to figure out that F U is a ring

Whenever you are trying to make a typeclass instance solvable, you need to add an instance keyed to the form of the thing being inferred. If it's FP.F then this is easy, just have a theorem like instance : comm_ring (FP.F U O) or whatever
If it's a parameter, the comm_ring part will also need to be a parameter, so it shows up in the local context of all such theorems (or else it is derivable from something in the context that only depends on F)

I might also suggest removing the is_open parameter from F entirely, but I don't
know if that will interfere with some construction or another since that's not an
isomorphic modification (seeing as how partial functions are not nice to work 
with in practice)

and by make F a parameter I meant this

structure presheaf_of_rings (α : Type u) [topological_space α] (F : Π U : set α, is_open U → Type) :=
[Fring : ∀ U O, comm_ring (F U O)]

It's good for the digestion if you've had too much curry

    why don't you use add_comm_group?

Re: ideal, you should have a is_subgroup predicate for asserting that I is closed under group operations for this
It should be similar to is_submodule in algebra/module
Mario Carneiro
@digama0
05:26

    with now no clue as to how to figure out that F U is a ring

Whenever you are trying to make a typeclass instance solvable, you need to add an instance keyed to the form of the thing being inferred. If it's FP.F then this is easy, just have a theorem like instance : comm_ring (FP.F U O) or whatever
If it's a parameter, the comm_ring part will also need to be a parameter, so it shows up in the local context of all such theorems (or else it is derivable from something in the context that only depends on F)
Patrick Massot
@PatrickMassot
14:43
I think the question of how to define something as composite as a sheaf and not be buried under cumbersome notations and explicit arguments is crucial. Here my try at reducing the mess a bit:

variables (α : Type u) [T : topological_space α]
include T
def open_sets :=  {U : set α // T.is_open U}

instance open_inter : has_inter (open_sets α):= 
⟨λ U V, ⟨U.1 ∩ V.1, T.is_open_inter U.1 V.1 U.2 V.2⟩⟩

instance open_subset : has_subset (open_sets α) := 
⟨λ U V, U.1 ⊆ V.1⟩

lemma inter_sub_left (U V : open_sets α) : U ∩ V ⊆ U :=
  λ x Hx,Hx.left

lemma inter_sub_right (U V : open_sets α) : U ∩ V ⊆ V :=
λ x Hx,Hx.right

structure presheaf_of_rings  :=
(F : open_sets α  → Type)
[Fring : ∀ U, comm_ring (F U)]
(res : ∀  (U V : open_sets α) (H : V ⊆ U), 
  @ring_morphism (F U) (F V) (Fring U) (Fring V))
(Hid : ∀ {U : open_sets α}, (res U U (set.subset.refl _)).f = id)  
(Hcomp : ∀ {U V W : open_sets α} (HUV : V ⊆ U) (HVW : W ⊆ V),
  (res U W (set.subset.trans HVW HUV)).f = (res V W HVW).f ∘ (res U V HUV).f )

instance presheaf_ring (FP: presheaf_of_rings α) (U : open_sets α): comm_ring (FP.F U) := 
FP.Fring U

variables U V : open_sets α

def res_to_inter_left (FP : presheaf_of_rings α) 
  (U V : open_sets α) : ring_morphism (FP.F U) (FP.F (U ∩ V)) :=
FP.res U (U ∩ V) (inter_sub_left α U V)

def res_to_inter_right (FP : presheaf_of_rings α) 
  (U V : open_sets α) : ring_morphism (FP.F V) (FP.F (U ∩ V)) :=
FP.res V (U ∩ V) (inter_sub_right α U V)

Here it seems enough to have α explicit everywhere but T implicit.
I should have said that I have:
structure ring_morphism (α : Type u) (β : Type v) [Ra : comm_ring α] [Rb : comm_ring β]
in the definition of morphisms
In the definition of presheaf I need to give the instances explicitly but then in res_to_inter_* I don't
thanks to presheaf_ring
Patrick Massot
@PatrickMassot
14:50
I don't how many theorem you unlock by providing has_inter and has_subset instances. But at least you get convenient notations

-/