Require Import Relations Omega Ensembles Finite_sets Finite_sets_facts List ListSet util.

Require Import ListSet List Relations_1.

(* List Notations *)
Notation " [ ] " := nil.
Notation " [ x ] " := (cons x nil).
Notation " [ x , .. , y ] " := (cons x .. (cons y nil) ..).
Notation "x :: l" := (cons x l) (at level 60, right associativity). 


Section strict_order.

Variable X : Type.
 Hypothesis Xeq_dec : forall (x y:X), {x = y} + {x <> y}.

Definition InSet : forall U : Type, Ensemble U -> U -> Prop := Ensembles.In.

Lemma set_imp_ensemble : forall (s: set X),
NoDup s ->
exists E:Ensemble X, (forall x, set_In x s <-> InSet X E x) /\ 
  exists n, (length s = n) /\ (cardinal X E n).
Proof.
  intros s nodup. generalize dependent nodup.
  induction s; intros nodup.
  Case "[]".
    exists (Empty_set X).
    split.
    SCase "set_In <-> InSet".
      intros x.
      split. intros setin. inversion setin.
      intros  inset. inversion inset.
   SCase "length = size".
     exists 0. 
     split. simpl. reflexivity.
     constructor.
 Case "a :: s".    
   destruct IHs as [E [Hin Hcard]].
   inversion nodup; subst. exact H2.
   exists (Add X E a).
   split.
    SCase "set_In <-> InSet".
      intros x.
      split.
      SSCase "->".
        destruct (Xeq_dec a x) as [eqax | neqax].
        intros setIn. subst x.
        apply Add_intro2.
        intros setIn.
        destruct (Hin x) as [setInx InSetx].
        inversion setIn. assert False as F. apply neqax. exact H. inversion F.
        apply setInx in H. eapply Add_intro1 in H. exact H.
      SSCase "<-".
        intros inSet.
        destruct (Xeq_dec a x) as [eqax | neqax].
        subst. simpl. left. reflexivity. 
        inversion inSet; subst.
        apply Hin in H.
        simpl. right. exact H.
        inversion H.
        assert False as F. apply neqax. exact H0. inversion F.
   SCase "length = size".
     destruct (set_In_dec Xeq_dec a s) as [ins | nins].
     inversion nodup; subst.
     assert False as F. apply H1. exact ins. inversion F.
     destruct Hcard as [n [len card]].
     exists (S n).
     split. simpl. auto.
     apply card_add. exact card.
     intros contra.
     destruct (Hin a) as [setIna InSeta].
     apply InSeta in contra.
     apply nins. exact contra.
Qed.

Lemma set_add_Sn : forall (s: set X) (x: X) (n:nat),
~ set_In x s ->
length s = n ->
length (set_add Xeq_dec x s) = S n.
Proof.
  intros s.
  induction s.
  Case "[]".
    intros x n notIn len.
    simpl. simpl in len.
    auto.
  Case "a :: s".
    intros x n notIn len.
    simpl. destruct (Xeq_dec x a).
    subst x.
    assert False as F. apply notIn. simpl. left. reflexivity. inversion F.
    simpl. rewrite <- len. simpl. destruct n. inversion len.
    assert (~ set_In x s) as xnotIns. 
      intros contra. apply notIn. simpl. right. exact contra.
    assert (length s = n) as slen. auto.      
    rewrite (IHs x n xnotIns slen).
    subst. 
    reflexivity.
Qed.

Lemma set_add_nodup : forall x s,
NoDup (x :: s) ->
NoDup (set_add Xeq_dec x s).
Proof.
  intros x s. generalize dependent x.
  induction s.
  Case "[]".
    intros x xnotIn.
    simpl. exact xnotIn.
  Case "a :: s".
    intros x nodup.
    simpl.
    destruct (Xeq_dec x a) as [eqxa | neqxa].
    subst. inversion nodup. assert False as F. apply H1. simpl. left. reflexivity. inversion F.
    inversion nodup; subst. inversion H2; subst.
    assert (~ In x s) as notxIns.
      intros contra. apply H1. simpl. right. exact contra.
    assert (NoDup (x :: s)) as xsnodup.
      constructor. exact notxIns. exact H4.
    constructor.
    intros contra.
    apply set_add_elim2 in contra.
    apply H3. exact contra.
    intros contra2. subst. inversion nodup. apply H5. simpl. left. reflexivity.
    apply IHs. exact xsnodup.
Qed.

Lemma ensemble_imp_set : forall (E: Ensemble X),
Finite X E ->
exists s: set X, (forall x, set_In x s <-> InSet X E x) /\
  NoDup s /\
  exists n, (length s = n) /\ (cardinal X E n).
Proof.
  intros E fin.
  induction fin.
  Case "Empty_set".
    exists nil.
    split.
    intros x. 
    split. intros setIn. inversion setIn.
    intros inSetx. inversion inSetx.
    split. constructor.
    exists 0. split. simpl. reflexivity.
    apply card_empty.
  Case "Add x".
    destruct IHfin as [s [Hin [Hnodup Hcard]]].
    exists (set_add Xeq_dec x s).
    split.
     SCase "set_In <-> InSet".
       intros a.
       split.
       SSCase "->".
         intros setInx.
         apply set_add_elim in setInx.
         destruct setInx as [eqax | aIns].
         subst a. apply Add_intro2. 
         apply Add_intro1. apply Hin. exact aIns.
       SSCase "<-".
         intros InSeta.
         inversion InSeta; subst.
         apply set_add_intro.
         right.
         destruct (Hin a) as [HsetIn HInSet].
         apply HInSet.
         exact H0.
         inversion H0. subst.
         apply set_add_intro. left. reflexivity.
       split.
     SCase "NoDup s".
       assert (~ set_In x s) as xnotIns.
         destruct (set_In_dec Xeq_dec x s).
         apply Hin in s0. assert False as F. apply H. exact s0. inversion F.
         exact n.
         assert (NoDup (x :: s)) as xsnodup.
           constructor. exact xnotIns. exact Hnodup.
           apply set_add_nodup. exact xsnodup.
     SCase "length /\ card".
       destruct Hcard as [n [slen Acard]].
       destruct (set_In_dec Xeq_dec x s).
       SSCase "x in s".
         destruct (Hin x) as [HsetIn HInSet].
         assert False as F. apply H. apply HsetIn.
         exact s0. inversion F.
       SSCase "x not in s".
         exists (S n).
         split.
         apply set_add_Sn. exact n0. exact slen.
         apply card_add. exact Acard. exact H.
Qed.


Variable R : Relation X.

 Definition Irreflexive (X:Type) (R:Relation X) : Prop := forall x:X, ~R x x.
  Inductive StrictOrder (X:Type) (R:Relation X) : Prop :=
       Definition_of_order :
         Irreflexive X R -> Transitive X R -> StrictOrder X R.

 Hypothesis Rdec : forall (x y:X), {R x y} + {~R x y}.
 Hypothesis Rso : StrictOrder X R.

Fixpoint lt_set (pivot:X) (s:set X) : (set X) :=
match s with
| nil => nil
| x :: srest =>
  if Rdec x pivot
  then set_add Xeq_dec x (lt_set pivot srest)
  else lt_set pivot srest
end.

Lemma in_lt_imp_in_set : forall x y s,
set_In y (lt_set x s) ->
set_In y s.
Proof.
  intros x y s.
  induction s as [|h s'].
  Case "s = []".
    intros yIn. inversion yIn.
  Case "s = h :: s'".
    intros yIn.
    destruct (Xeq_dec y h) as [eqyh | neqyh].
    SCase "y = h".
      subst h. left. reflexivity.
    SCase "y <> h".
      right. apply IHs'.
      simpl in yIn.
      destruct (Rdec h x) as [Rhx | nRhx].
      SSCase "Rhx".
        apply set_add_elim in yIn.
        destruct yIn.
          contradiction.
          exact H.
      SSCase "~Rhx".
        exact yIn.
Qed.

Lemma lt_set_rel_equiv : forall x y s,
set_In y s ->
(R y x <-> set_In y (lt_set x s)).
Proof.
  intros x y s yIn.
  split.
  Case "Ryx -> In".
    intros Ryx.
    induction s as [| h s'].
      SCase "s = []".
        inversion yIn.
      SCase "s = h :: s'".
        destruct (Xeq_dec h y) as [eqyh | neqyh].
        SSCase "y = h".
          subst h. simpl.
          destruct (Rdec y x) as [yRyx | nRyx].
            apply set_add_intro2. reflexivity.
            contradiction.
        SSCase " y <> h".
          simpl. 
          destruct (Rdec h x) as [yRhx | nRhx].
            apply set_add_intro1. apply IHs'. 
            destruct yIn. 
              contradiction. exact H.
            apply IHs'. 
            destruct yIn.
              contradiction. exact H.
  Case "Ryx <- In".
    intros yInlt.
    induction s as [| h s'].
    SCase "s = []".
      inversion yIn.
    SCase "s = [h s']".
      destruct (Xeq_dec y h) as [eqyh | neqyh].
      SSCase "y = x".
        subst h. simpl in yInlt.
        destruct (Rdec y x) as [Ryx | nRyx].
          exact Ryx.
          apply IHs'.
          eapply in_lt_imp_in_set. exact yInlt. 
          exact yInlt.
      SSCase "y <> h".
        destruct yIn.
          symmetry in H. contradiction.
          simpl in yInlt.
          destruct (Rdec h x) as [Rhx | nRhx].
            apply set_add_elim in yInlt.
            destruct yInlt.
              contradiction.
              apply IHs'. exact H. exact H0.
              apply IHs'. exact H. exact yInlt.
Qed.

Fixpoint gt_set (pivot:X) (s:set X) : (set X) :=
match s with
| nil => nil
| x :: srest =>
  if Rdec pivot x
  then set_add Xeq_dec x (gt_set pivot srest)
  else gt_set pivot srest
end.

Lemma in_gt_imp_in_set : forall x y s,
set_In y (gt_set x s) ->
set_In y s.
Proof.
  intros x y s.
  induction s as [|h s'].
  Case "s = []".
    intros yIn. inversion yIn.
  Case "s = h :: s'".
    intros yIn.
    destruct (Xeq_dec y h) as [eqyh | neqyh].
    SCase "y = h".
      subst h. left. reflexivity.
    SCase "y <> h".
      right. apply IHs'.
      simpl in yIn.
      destruct (Rdec x h) as [Rxh | nRxh].
      SSCase "Rxh".
        apply set_add_elim in yIn.
        destruct yIn.
          contradiction.
          exact H.
      SSCase "~Rxh".
        exact yIn.
Qed.

Lemma gt_set_rel_equiv : forall x y s,
set_In y s ->
(R x y <-> set_In y (gt_set x s)).
Proof.
  intros x y s yIn.
  split.
  Case "Rxy -> In".
    intros Rxy.
    induction s as [| h s'].
      SCase "s = []".
        inversion yIn.
      SCase "s = h :: s'".
        destruct (Xeq_dec h y) as [eqyh | neqyh].
        SSCase "y = h".
          subst h. simpl.
          destruct (Rdec x y) as [yRxy | nRxy].
            apply set_add_intro2. reflexivity.
            contradiction.
        SSCase " y <> h".
          simpl. 
          destruct (Rdec x h) as [yRxh | nRxh].
            apply set_add_intro1. apply IHs'. 
            destruct yIn. 
              contradiction. exact H.
            apply IHs'. 
            destruct yIn.
              contradiction. exact H.
  Case "Rxy <- In".
    intros yInlt.
    induction s as [| h s'].
    SCase "s = []".
      inversion yIn.
    SCase "s = [h s']".
      destruct (Xeq_dec y h) as [eqyh | neqyh].
      SSCase "y = h".
        subst h. simpl in yInlt.
        destruct (Rdec x y) as [Rxy | nRxy].
          exact Rxy.
          apply IHs'.
          eapply in_gt_imp_in_set. exact yInlt. exact yInlt.
      SSCase "y <> h".
        destruct yIn.
          symmetry in H. contradiction.
          simpl in yInlt.
          destruct (Rdec x h) as [Rxh | nRxh].
            apply set_add_elim in yInlt.
            destruct yInlt.
              contradiction.
              apply IHs'. exact H. exact H0.
              apply IHs'. exact H. exact yInlt.
Qed.

Fixpoint norel_set (pivot:X) (s:set X) : (set X) :=
match s with
| nil => nil
| x :: srest =>
  if Rdec x pivot
  then norel_set pivot srest
  else if Rdec pivot x
       then norel_set pivot srest
       else set_add Xeq_dec x (norel_set pivot srest)
end.

Lemma in_norel_imp_in_set : forall x y s,
set_In y (norel_set x s) ->
set_In y s.
Proof.
  intros x y s.
  induction s as [|h s'].
  Case "s = []".
    intros yIn. inversion yIn.
  Case "s = h :: s'".
    intros yIn.
    destruct (Xeq_dec y h) as [eqyh | neqyh].
    SCase "y = h".
      subst h. left. reflexivity.
    SCase "y <> h".
      right. apply IHs'.
      simpl in yIn.
      destruct (Rdec h x) as [Rhx | nRhx].
      SSCase "Rhx".
        exact yIn.
        destruct (Rdec x h) as [Rxh | nRxh].
        SSSCase "Rxh".
          exact yIn.
        SSCase "~Rxh".
          apply set_add_elim in yIn.
          destruct yIn.
            contradiction.
            exact H.
Qed.

Lemma norel_set_rel_equiv : forall x y s,
set_In y s ->
((and (~R x y) (~R y x)) <-> set_In y (norel_set x s)).
Proof.
  intros x y s yIn.
  split.
  Case "no relation -> In".
    intros Rand.
    destruct Rand as [nRxy nRyx].
    induction s as [| h s'].
      SCase "s = []".
        inversion yIn.
      SCase "s = h :: s'".
        destruct (Xeq_dec h y) as [eqyh | neqyh].
        SSCase "y = h".
          subst h. simpl.
          destruct (Rdec y x) as [yRyx | nRyx2].
          SSSCase "Ryx".
            contradiction.
          SSSCase "~Ryx".
            destruct (Rdec x y) as [yRxy | nRxy2].
            SSSSCase "Rxy".
              contradiction.
            SSSSCase "~Rxy".
              apply set_add_intro2. reflexivity.
        SSCase "y <> h".
          simpl.
          destruct (Rdec h x) as [yRhx | nRhx].
          SSSCase "Rhx".
            apply IHs'.
            destruct yIn.
              contradiction. exact H.
          SSSCase "~Rhx".
            destruct (Rdec x h) as [yRxh | nRxh].
            SSSSCase "Rxh".
              apply IHs'.
              destruct yIn.
                contradiction. exact H.
              apply set_add_intro1.
              apply IHs'.
              destruct yIn.
                contradiction. exact H.
  Case "no relation <- In".
    intros yInlt.
    induction s as [| h s'].
    SCase "s = []".
      inversion yIn.
    SCase "s = [h s']".
      destruct (Xeq_dec y h) as [eqyh | neqyh].
      SSCase "y = h".
        subst h. simpl in yInlt.
        destruct (Rdec x y) as [Rxy | nRxy].
        SSSCase "Rxy".
          destruct (Rdec y x) as [Ryx | nRyx].
          SSSSCase "Ryx".
            assert (R x x) as contraR.
              eapply Rso. exact Rxy. exact Ryx.
            apply Rso in contraR. inversion contraR.
          SSSSCase "~Ryx".
            apply IHs'.
            eapply in_norel_imp_in_set. exact yInlt.
            exact yInlt.
        SSSCase "~Rxy".
          destruct (Rdec y x) as [Ryx | nRyx].
          SSSSCase "Ryx".
            apply IHs'.
            eapply in_norel_imp_in_set. exact yInlt.
            exact yInlt.
          SSSSCase "~Ryx".
            split. exact nRxy. exact nRyx.
      SSCase "y <> h".
        apply IHs'.
        destruct yIn. symmetry in H. contradiction.
        exact H.
        simpl in yInlt.
        destruct (Rdec h x) as [Rhx | nRhx].
        SSSCase "Rhx".
          exact yInlt.
        SSSCase "~Rhx".
          destruct (Rdec x h) as [Rxh | nRxh].
          SSSSCase "Rxh".
            exact yInlt.
          SSSSCase "~Rxh".
            eapply set_add_elim in yInlt.
            destruct yInlt.
              contradiction.
              exact H.
Qed.

Lemma lt_set_only : forall x y s,
set_In y (lt_set x s) ->
~set_In y (gt_set x s) /\ ~set_In y (norel_set x s).
Proof.
  intros x y s yIn.
  split.
  Case "y not in gt".
    intros contraIn.
    apply lt_set_rel_equiv in yIn.
    apply gt_set_rel_equiv in contraIn.
    assert (R y y). eapply Rso. exact yIn. exact contraIn.
    eapply Rso. exact H.
    eapply in_gt_imp_in_set. exact contraIn.
    eapply in_gt_imp_in_set. exact contraIn.
  Case "y not in indiff".
    intros contraIn.
    apply norel_set_rel_equiv in contraIn. destruct contraIn.
    apply lt_set_rel_equiv in yIn.
    contradiction.
    eapply in_lt_imp_in_set. exact yIn.
    eapply in_lt_imp_in_set. exact yIn.
Qed.

Lemma gt_set_only : forall x y s,
set_In y (gt_set x s) ->
~set_In y (lt_set x s) /\ ~set_In y (norel_set x s).
Proof.
  intros x y s yIn.
  split.
  Case "y not in gt".
    intros contraIn.
    apply gt_set_rel_equiv in yIn.
    apply lt_set_rel_equiv in contraIn.
    eapply Rso. eapply Rso. exact yIn. exact contraIn.
    eapply in_lt_imp_in_set. exact contraIn.
    eapply in_gt_imp_in_set. exact yIn.
  Case "y not in indiff".
    intros contraIn.
    apply norel_set_rel_equiv in contraIn. destruct contraIn.
    apply gt_set_rel_equiv in yIn.
    contradiction.
    eapply in_gt_imp_in_set. exact yIn.
    eapply in_gt_imp_in_set. exact yIn.
Qed.

Lemma norel_set_only : forall x y s,
set_In y (norel_set x s) ->
~set_In y (lt_set x s) /\ ~set_In y (gt_set x s).
Proof.
  intros x y s yIn.
  split.
  Case "y not in lt".
    intros contraIn.
    apply lt_set_only in contraIn. destruct contraIn as [ngt nindiff].
    contradiction.
  Case "y not in gt".
    intros contraIn.
    apply gt_set_only in contraIn. destruct contraIn as [nlt nindiff].
    contradiction.
Qed.

Lemma lt_preserve_nodup : forall x s,
NoDup s ->
NoDup (lt_set x s).
Proof.
  intros x s.
  induction s as [| h rest].
  Case "s = []".
    intros nodup.
    simpl. constructor.
  Case "s = [h :: rest]".
    intros nodup.
    simpl.
    destruct (Rdec h x) as [Rhx |nRhx].
      inversion nodup; subst.
      apply set_add_nodup.
      constructor.
      intros contra. apply H1. eapply in_lt_imp_in_set.
      exact contra. apply IHrest. exact H2.
      apply IHrest. inversion nodup; auto.
Qed.

Lemma exists_empty_lt_set : forall s,
NoDup s ->
s <> nil ->
exists x, set_In x s /\ lt_set x s = nil.
Proof.
  intros s nodup notempty.
  induction s as [| x1 s'].
  Case "s = []".
    assert False as F. apply notempty. reflexivity. inversion F.
  Case "S =  a :: s".
    destruct s' as [| x2 s''].
    SCase "s' = []".
      exists x1. simpl.
      destruct (Rdec x1 x1).
      assert False as F. eapply Rso. exact r. inversion F. 
      split. left. reflexivity. reflexivity.
    SCase "s' = x2 :: s''".
      assert (x2 :: s'' <> []) as notmt.
        intros contra. inversion contra.
      apply IHs' in notmt.
      destruct notmt as [m mltnil].
      destruct (Rdec x1 m).
      SSCase "R x1 m".
        exists x1. simpl.
        destruct (Rdec x1 x1).
        apply Rso in r0. inversion r0.
        destruct (Rdec x2 x1).
        SSSCase "R x2 x1".
          assert (set_In x2 (lt_set m (x2 :: s''))) as contra.
          eapply lt_set_rel_equiv. left. reflexivity.
          eapply Rso. exact r0. exact r.
          split. left. reflexivity.
          destruct mltnil as [mltnilIn mltnil].
          rewrite mltnil in contra. inversion contra.
          SSSCase "~R x2 x1".
            remember (lt_set x1 s'') as x1lt.
            destruct (x1lt).
            SSSSCase "lt_set x1 s'' = []". split. left. reflexivity. reflexivity.
            SSSSCase "x :: x1lt = lt_set x1 s''".
              assert (set_In x (lt_set x1 s'')) as xInx1lt.
              rewrite <- Heqx1lt. left. reflexivity.
              assert (set_In x s'') as xcontraIn.
              eapply in_lt_imp_in_set. exact xInx1lt.
              assert (R x m) as Rxm.
              eapply Rso. apply lt_set_rel_equiv in xInx1lt.
              exact xInx1lt. exact xcontraIn. exact r.
              assert (set_In x (lt_set m (x2 :: s''))) as contraInmlt.
              apply lt_set_rel_equiv. right. exact xcontraIn. exact Rxm.
              split. left. reflexivity.
              destruct mltnil as [mltnilIn mltnil].
              rewrite mltnil in contraInmlt. inversion contraInmlt.
      SSCase "R x1 m".
        exists m.
        split.
        destruct mltnil as [mltnilIn mltnil].
        right. exact mltnilIn.
        destruct mltnil as [mltnilIn mltnil].
        simpl. destruct (Rdec x1 m). contradiction. 
        exact mltnil.
        inversion nodup; auto.
Qed.

Lemma minimal_finite_ensemble_mem : 
  forall E n,
    cardinal X E (S n) ->
    exists min, InSet X E min /\ 
                forall y, InSet X E y -> ~R y min.
Proof.
  intros E n card.
  assert (Finite X E) as finE.
  eapply cardinal_finite. exact card.
  destruct (ensemble_imp_set E finE) as [s [allIn [nodup [i [slen scard]]]]].
  assert (s <> nil) as nonil.
  intros contra. subst s. simpl in slen. subst i. inversion scard. subst E.
  inversion card. symmetry in H. apply not_Empty_Add in H. inversion H.
  destruct (exists_empty_lt_set s nodup nonil) as [min [minIn ltnil]].
  exists min.
  split. apply allIn. exact minIn.
  intros y yIn contraR.
  assert (set_In y s) as yIns. apply allIn. exact yIn.
  apply (lt_set_rel_equiv min y s yIns) in contraR.
  rewrite ltnil in contraR.
  inversion contraR.
Qed.

End strict_order.