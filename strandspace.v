(** * strandspace.v: Basic Strand Space Definitions *)

(* Created by Andrew Kent
   Brigham Young University
 *)

(* Source Material(s): 

1) Strand Spaces: Proving Security Protocols Correct.
   F. Javier Thayer Fabrega, Jonathan C. Herzog, Joshua D. Guttman. 
   Journal of Computer Security, 7 (1999), pages 191-230.
   http://web.cs.wpi.edu/~guttman/pubs/jcs_strand_spaces.pdf

2) Authentication tests and the structure of bundles.
   Joshua D. Guttman, F. Javier Thayer, Theoretical Computer Science, 
   v.283 n.2, p.333-380, June 14, 2002.
   http://www.mitre.org/work/tech_papers/tech_papers_01/guttman_bundles/
 *)

Require Import Logic List Arith Peano_dec Omega Ensembles.
Require Import Finite_sets_facts Finite_sets Relation_Definitions.
Require Import Relation_Operators strictorder util.

(* atomic messages *)
Variable Text : Set.
Variable eq_text_dec : forall (x y:Text), {x = y} + {x <> y}.
Hint Resolve eq_text_dec.

(* representing kryptographic key *)
Variable Key : Set.
(* TODO - injective, unary operation (inv : key -> key)
          Or in Coq would this make more sense
          instead as  key -> key -> Prop?
          The text notes the ability to handle
          both symmetric and asymmetric keys... *)
Variable eq_key_dec : forall (x y:Key), {x = y} + {x <> y}.
Hint Resolve eq_key_dec.

(* TODO? For the analysis of the NSL protocol, they 
   include an extension of term/message definitions
   that includes names and public keys which are
   associated with a specific name.*)

(* message or term *)
Inductive Msg : Type :=
| msg_text : Text -> Msg
| msg_app : Msg -> Msg -> Msg 
| msg_crypt : Key -> Msg -> Msg.
(* [REF 1] Section 2.1 pg 5 
           Section 2.3 pg 9 *)
(* [REF 2] pg 4 paragraph 3 (details of encryption and subterms) *)
Hint Constructors Msg.

Definition eq_msg_dec : forall x y : Msg,  
  {x = y} + {x <> y}.
Proof.
  decide equality.
Qed.
Hint Resolve eq_msg_dec.

(* subterm relationship for messages *)
(* subterm -> encompassing term -> Prop *)
Inductive Subterm : Msg -> Msg -> Prop :=
| st_refl : forall m, Subterm m m
(* | stcryp : forall a g, Subterm a g -> Subterm a encrpt(g)  *)
| st_app_l : forall st l r, 
               Subterm st l -> Subterm st (msg_app l r)
| st_app_r : forall st l r, 
               Subterm st r -> Subterm st (msg_app l r)
| st_crpyt : forall st t k, 
               Subterm st t -> Subterm st (msg_crypt k t).
(* [REF 1] Section 2.1 pg 6 and Definition 2.11 *)
Hint Constructors Subterm.

(* signed message, + (tx) or - (rx) *)
Inductive SMsg : Type := 
| tx : Msg -> SMsg
| rx : Msg -> SMsg.
(* [REF 1] Definition 2.1 pg 6 
   They are defined as a pair, w/ the first member being in {+, -} 
   and the second a signed message. *)
Hint Constructors SMsg.

Definition eq_smsg_dec : forall x y : SMsg,  
  {x = y} + {x <> y}.
Proof.
 intros. decide equality.
Qed. 
Hint Resolve eq_smsg_dec.

(* strand *)
Definition Strand : Type := list SMsg.
(* [REF 1] First sentence of Abstract: "sequence of events"  
   Haven't hit a better def, and they start using strands
   pretty early so I'm rolling with this. *)

Definition eq_strand_dec : forall x y : Strand,  
  {x = y} + {x <> y}.
Proof.
 intros. decide equality.
Qed.
Hint Resolve eq_strand_dec.

Definition StrandSet := Ensemble Strand.
Definition MsgSet := Ensemble Msg.
Definition SMsgSet := Ensemble SMsg.

(* strand space *)
Inductive StrandSpace : Type :=
| strandspace : MsgSet -> StrandSet -> StrandSpace.
(* [REF 1] Definition 2.2 pg 6 "A strand space over A (set of possible msgs) 
           is a set E with a trace mapping tr : E -> list smsg" *)
Hint Constructors StrandSpace.

Definition SS_msgset (ss:StrandSpace) : MsgSet :=
  match ss with
    | strandspace m_set s_set => m_set
  end.

Definition SS_strandset (ss:StrandSpace) : StrandSet :=
  match ss with
    | strandspace m_set s_set => s_set
  end.

(* node in a strand space *)
Definition Node : Type := {n: (Strand * nat) | (snd n) < (length (fst n))}.
(* [REF 1] Definition 2.3.1 pg 6
   -"A node is a pair <s,i> where s is a strand and i a nat in [0, (length s))"
     NOTE: changed to be 0 based instead of 1 based sequences
   -"node <s,i> belongs to strand s"
   -"Every node belongs to a unique strand" *)

Definition Edge : Type := (prod Node Node).
Definition NodeSet := Ensemble Node.
Definition EdgeSet := Ensemble Edge.


(* index of a node *)
Definition Node_index (n:Node) : nat :=
  match n with
    | exist npair _ 
      => snd npair
  end.
(* [REF 1] Definition 2.3.2 pg 6
   "If n = <s,i> then index(n) = i." *)

(* strand of a node *)
Definition Node_strand (n:Node) : Strand :=
  match n with
    | exist npair _ 
      => fst npair
  end.
(* [REF 1] Definition 2.3.2 pg 6
   "If n = <s,i> then ... strand(n) = s." *)

(* signed message of a node *)
Fixpoint Node_smsg_option (n:Node) : (option SMsg) :=
  match n with
    | exist (s, i) p 
      =>  nth_error s i
  end. 
(* [REF 1] Definition 2.3.2 pg 6
   "Define term(n) to be the ith signed term of the trace of s." *)

Lemma nth_error_len : 
forall {X:Type} {l:list X} i,
  None = nth_error l i -> (length l) <= i.
Proof.
  intros X l i. generalize dependent l.
  induction i. 
  Case "i = 0".
    intros l H.
    unfold nth_error in H.
    unfold error in H.
    destruct l.
    auto. inversion H.
  Case "i = S i".
    intros l' H.
    destruct l'.
    simpl; omega.
    inversion H.
    apply IHi in H1.
    simpl. omega. 
Qed.

Lemma node_smsg_valid :
forall (n:Node), {m:SMsg | Some m = Node_smsg_option n}.
Proof.
  intros n.
  remember (Node_smsg_option n) as funcall.
  destruct n. destruct funcall.  
  exists s. reflexivity.

  unfold Node_smsg_option in Heqfuncall.
  destruct x. simpl in l.
  apply nth_error_len in Heqfuncall.
  omega.
Qed.

(* signed message of a node *)
Definition Node_smsg (n:Node) : SMsg :=
  match node_smsg_valid n with
    | exist m _ => m
  end.

(* unsigned message of a node *)
Fixpoint Node_msg (n:Node) : Msg :=
  match Node_smsg n with
    | tx t => t
    | rx t => t
  end. 
(* [REF 1] Definition 2.3.2 pg 6
   "Define uns_term(n) to be the unsigned part of the ith signed term 
    of the trace of s." *)

Definition eq_node_dec : forall x y : Node,
 {x = y} + {x <> y}.
Proof.
  intros [[xs xn] xp] [[ys yn] yp].
  destruct (eq_strand_dec xs ys) as [EQs | NEQs]; subst.
  destruct (eq_nat_dec xn yn) as [EQn | NEQn]; subst.
  left. rewrite (proof_irrelevance (lt yn (length ys)) xp yp). reflexivity.

  right. intros C. inversion C. auto.
  right. intros C. inversion C. auto.
Qed.

Lemma eq_nodes : forall x y : Node,
Node_index x = Node_index y ->
Node_strand x = Node_strand y ->
x = y.
Proof.
  intros [[xs xn] xp] [[ys yn] yp] eq_index eq_strand.
  simpl in eq_index. simpl in eq_strand. subst.
  rewrite (proof_irrelevance (lt yn (length ys)) xp yp). reflexivity.
Qed.

Lemma node_imp_strand_nonempty : forall s n,
Node_strand n = s ->
length s > 0.
Proof.
  intros s n Hns.
  destruct n. destruct x.
  destruct n. simpl in l.
  destruct s.
  Case "s = []".
    assert (s0 = nil). auto.
  subst. inversion l.
  Case "s = s :: s1".
    simpl. omega.
    simpl in l. 
    assert (s0 = s). auto.
    rewrite <- H.
    omega.
Qed.

Inductive Comm : relation Node :=
| comm :  forall n m t, ((Node_smsg n = tx t 
                                    /\ Node_smsg m = rx t)
                        /\ Node_strand n <> Node_strand m)
                        -> Comm n m.
Hint Constructors Comm.
(* [REF 1] Definition 2.3.3 pg 6
   "there is an edge n1 -> n2 iff term(n1) = +a and term(n2) = -a ... 
   recording a potential causal link between those strands**"
  **We take this to mean a causal link between two *different* 
  strands, as this is logical, and fits numerous informal 
  descriptions in the literature such as "A strand (process) 
  may send or receive a message but not both at the 
  same time". *)

Lemma comm_dec : forall x y,
{Comm x y} + {~ Comm x y}.
Proof.
  intros x y.
  remember (Node_smsg x) as xsmsg. remember (Node_smsg y) as ysmsg.
  remember (Node_strand x) as xstrand. remember (Node_strand y) as ystrand.
  destruct xsmsg.
  Case "x (tx m)".
    destruct ysmsg.
    SCase "y (tx m0)".
      right. intros contracomm. inversion contracomm; subst.
      destruct H as [[xtx yrx] strandneq].
      rewrite <- Heqysmsg in yrx. inversion yrx.      
    SCase "y (rx m0)".
      destruct (eq_msg_dec m m0) as [msgeq | msgneq].
      SSCase "m = m0".
        destruct (eq_strand_dec xstrand ystrand) as [strandeq | strandneq].
        SSSCase "strands eq".
          right. intros contracomm.
          inversion contracomm; subst. destruct H as [msgs strandsneq].
          apply strandsneq. exact strandeq. 
        SSSCase "strands neq".
          subst m0. left.
          apply (comm x y m). split. split.
          auto. auto. subst. exact strandneq.        
      SSCase "m <> m0".
        right. intros contracomm. inversion contracomm; subst. 
        destruct H as [[xtx yrx] strandneq].
        apply msgneq. rewrite <- Heqxsmsg in xtx.
        rewrite <- Heqysmsg in yrx. inversion xtx; subst. 
        inversion yrx; subst. reflexivity.
  Case "x (rx m)".
    right.
    intros contracomm. inversion contracomm; subst.
    destruct H as [[xtx yrx] strandneq].
    rewrite <- Heqxsmsg in xtx. inversion xtx.
Qed.

Theorem comm_irreflexivity : forall n,
~ Comm n n.
Proof.
  intros n contraedge.
  inversion contraedge; subst.
  destruct H as [[txsmsg rxsmsg] strandneq].
  apply strandneq. reflexivity.
Qed.
Hint Resolve comm_irreflexivity.

Theorem comm_antisymmetry : 
Antisymmetric Node Comm.
Proof.
  intros n m Hcomm contra.
  assert False.
  inversion Hcomm; subst.
  inversion contra; subst.
  destruct H as [H Hneq_s].
  destruct H as [Htx1 Hrx1].
  destruct H0 as [H Hneq_s2].
  destruct H as [Htx2 Hrx2].
  rewrite Htx2 in Hrx1. inversion Hrx1.
  inversion H.
Qed.
Hint Resolve comm_antisymmetry.

(* predecessor edge *)
(* node's direct predecessor -> node -> Prop *)
Inductive Pred : relation Node :=
| pred : forall i j, Node_strand i = Node_strand j 
                       -> (Node_index i) + 1 = Node_index j 
                       -> Pred i j.
(* [REF 1] Definition 2.3.4 pg 6
   "When n1= <s,i> and n2=<s,i+1> are members of N (set of node), there is
    an edge n1 => n2." *)

Lemma pred_dec : forall x y,
{Pred x y} + {~Pred x y}.
Proof.
  intros x y.
  remember (Node_index x) as xi. remember (Node_index y) as yi.
  remember (Node_strand x) as xstrand. remember (Node_strand y) as ystrand.
  destruct (eq_strand_dec xstrand ystrand) as [seq | sneq].
  Case "strands eq".
    destruct (eq_nat_dec yi (S xi)) as [predi | wrongi].
    SCase "yi = S xi". left. apply (pred x y). rewrite <- Heqxstrand.
      rewrite <- Heqystrand.  exact seq. omega.
    SCase "yi <> S xi".
      right. intros contrapred. apply wrongi. inversion contrapred; subst; omega.
  Case "strands neq".
    right. intros contrapred. apply sneq. inversion contrapred; subst; auto.
Qed.  

Theorem pred_irreflexivity : forall n,
~Pred n n.
Proof.
  intros n edge.
  inversion edge; subst. omega.
Qed.
Hint Resolve pred_irreflexivity.

Theorem pred_antisymmetry :
Antisymmetric Node Pred.
Proof.
  intros n m Hpe1 Hpe2.
  destruct Hpe1. destruct Hpe2.
  rewrite <- H0 in H2. omega.
Qed.
Hint Resolve pred_antisymmetry.

(* predecessor multi edge (not nec. immediate predecessor) *)
(* node's eventual predecessor -> node -> Prop *)
Definition PredPath : relation Node := 
clos_trans Node Pred.
 (* [REF 1] Definition 2.3.4 pg 6
   "ni =>+ nj means that ni precedes nj (not necessarily immediately) on
    the same strand." *)
Hint Constructors clos_trans.

Lemma ppath_imp_eq_strand : forall x y,
PredPath x y -> Node_strand x = Node_strand y.
Proof.
  intros x y path.
  induction path.
  Case "step".
    destruct H; auto.
  Case "trans".
    rewrite IHpath1.
    rewrite IHpath2.
    reflexivity.
Qed.
Hint Resolve ppath_imp_eq_strand.

Lemma ppath_imp_index_lt : forall x y,
PredPath x y -> Node_index x < Node_index y.
Proof.
  intros x y path.
  induction path.
  Case "step". inversion H; subst. omega.
  Case "trans". omega.
Qed.
Hint Resolve ppath_imp_index_lt.

Lemma ppath_irreflexivity : forall n,
~PredPath n n.
Proof.
  intros n contra.
  apply ppath_imp_index_lt in contra.
  omega.
Qed.
Hint Resolve ppath_irreflexivity.

Theorem ppath_transitivity :
Transitive Node PredPath.
Proof.
  intros i j k Hij Hjk.
  apply (t_trans Node Pred i j k Hij Hjk).
Qed.
Hint Resolve ppath_transitivity.

Definition SSEdge : relation Node :=
union Node Comm Pred.
Hint Constructors or.

Lemma ssedge_dec : forall x y,
{SSEdge x y} + {~SSEdge x y}.
Proof.
  intros x y.
  destruct (comm_dec x y) as [cxy | nocxy].
  Case "Comm x y".
    left. left. exact cxy.
  Case "~Comm x y".
    destruct (pred_dec x y) as [pxy | nopxy].
    SCase "Pred x y".
      left. right. exact pxy.
    SCase "~Pred x y".
      right. intros contrass.
       destruct contrass.
       SSCase "false Comm".
         apply nocxy; exact H.
       SSCase "false Pred".
         apply nopxy; exact H.
Qed.

Theorem ssedge_irreflexivity : forall n,
~SSEdge n n.
Proof.
  intros n Hedge.
  inversion Hedge; subst; auto.
  eapply (comm_irreflexivity); eauto.
  eapply (pred_irreflexivity); eauto.
Qed.
Hint Resolve ssedge_irreflexivity.

Theorem ssedge_antisymmetry :
Antisymmetric Node SSEdge.
Proof.
  intros n m Hss Hcontra.
  inversion Hss; subst. inversion Hcontra; subst.
  apply (comm_antisymmetry n m H) in H0. exact H0.
  assert False.
  inversion H; subst. inversion H0; subst.
  inversion H1. apply H5. symmetry. exact H2.
  inversion H1.
  assert False.
  inversion Hcontra; subst. inversion H; subst.
  inversion H0; subst. inversion H3. apply H5.
  symmetry. exact H1.
  inversion H; subst. inversion H0; subst.
  omega. inversion H0.
Qed.
Hint Resolve ssedge_antisymmetry.

(* transitive closure of edges. *)
Definition SSPath : relation Node := 
clos_trans Node SSEdge.

Lemma sspath_dec : forall x y,
{SSPath x y} + {~SSPath x y}.
Proof.
  Admitted. (* TODO!!! *)
(* Assumptions that may be of use?
   - SSPath is the transitive closure of SSEdge, which
      is known to be decidable (see ssedge_dec)
   - Anything in Bundle?
     - anything with an SSEdge is in the bundle
     - we're working with a finite set of possible edges / relations ?
   - Would writing a function that does a depth first search for
     a path between x and y work?? Granted this would have to be
     with the assumption we were working within a finite set,
     and it would have to be a ListSet representation (which is 
     not a problem, NoDup ListSet's are equivalent to
     Ensembles that are Finite (see strict_order.v)) *)

Theorem ppath_imp_sspath : forall i j,
PredPath i j -> SSPath i j.
Proof.
  unfold SSPath.
  intros i j Hpath.
  induction Hpath.
  constructor. right. exact H.
  apply (t_trans Node SSEdge x y z IHHpath1 IHHpath2).
Qed.  

Theorem sspath_transitivity :
Transitive Node SSPath.
Proof.
  unfold SSPath.
  intros i j k Hij Hjk.
  apply (t_trans Node SSEdge i j k Hij Hjk).
Qed.

(* transitive reflexive closure of edges. *)
Definition SSPathEq : relation Node :=
clos_refl_trans Node SSEdge.
Hint Constructors clos_refl_trans.

Theorem sspatheq_opts: forall n m,
SSPathEq n m -> SSPath n m \/ n = m.
Proof.
  intros n m Hpatheq.
  induction Hpatheq.
  left. apply t_step. exact H.
  right. reflexivity.
  destruct IHHpatheq1 as [pathxy | eqxy].
    destruct IHHpatheq2 as [pathyz | eqyz].
      left. eapply t_trans. exact pathxy. exact pathyz.
      subst y. left. exact pathxy.
    destruct IHHpatheq2 as [pathyz | eqyz].
      subst x. left. exact pathyz.
      right. subst. reflexivity.
Qed.

Theorem sspatheq_transitivity :
Transitive Node SSPathEq.
Proof.
  unfold Transitive.
  intros i j k Hij Hjk.
  destruct Hij. 
    eapply rt_trans. eapply rt_step. exact H. 
    exact Hjk. exact Hjk. 
    eapply rt_trans. exact Hij1. eapply rt_trans.
    exact Hij2. exact Hjk.
Qed.

(* In for members of pairs *)
Inductive InPair {X:Type} (E:Ensemble (X*X)) (x:X): Prop :=
| inp_l : (exists y, In (X*X) E (x,y))
          -> InPair E x
| inp_r : (exists y, In (X*X) E (y,x))
          -> InPair E x.
Hint Constructors InPair.

(* * * * * BUNDLE DEFINITION * * * * *)
Inductive ValidEdges (N: NodeSet) (E: EdgeSet) : Prop :=
| validedges :
    (* N is the set of nodes incident with any edge in E *)
    (and (forall x, InPair E x -> In Node N x)
    (* edges and the SSEdge property are equivalent *)
         (forall x y, In Edge E (x,y) <-> SSEdge x y))
    -> ValidEdges N E.
(* TODO justification *)

Inductive ExistsUniqueTx (N:NodeSet) (E:EdgeSet) : Prop :=
| uniqtx : forall z m, In Node N z ->
              Node_smsg z = rx m -> 
              (* there exists a transmitter *)
              (exists x, (Node_smsg x = tx m
                          /\ Comm x z
                          /\ In Edge E (x,z)))
              (* a transmitter is unique *)
              /\ (forall x y, Comm x z ->
                              Comm y z ->
                              x = y) -> ExistsUniqueTx N E.
(* TODO justification *)

Definition Acyclic (N:NodeSet) (E:EdgeSet) : Prop :=
forall x, ~ SSPath x x.
(* TODO justification *)

Inductive Bundle : NodeSet -> EdgeSet -> Prop :=
| bundle : forall N E,
             Finite Node N ->
             Finite Edge E ->
             ValidEdges N E ->
             ExistsUniqueTx N E ->
             Acyclic N E ->
             Bundle N E.

Lemma neq_sspatheq_imp_sspath : forall x y,
x <> y ->
SSPathEq x y ->
SSPath x y.
Proof.
  intros x y neq patheqxy.
  induction patheqxy.
  Case "SSEdge x y".
    apply t_step. exact H.
  Case "x = y". assert False as F. apply neq. reflexivity. inversion F.
  Case "x y z".
    destruct (eq_node_dec y z) as [eqyz | neqyz].
    SCase "y = z". subst y. apply IHpatheqxy1. exact neq.
    SCase "y <> z". 
      destruct (eq_node_dec x y) as [eqxy | neqxy].
      SSCase "x = y". subst x. apply IHpatheqxy2. exact neqyz.
      SSCase "x <> y". eapply t_trans. apply IHpatheqxy1. exact neqxy.
        apply IHpatheqxy2. exact neqyz.
Qed.      

Lemma sspatheq_trans_cycle : forall x y,
x <> y ->
SSPathEq x y ->
SSPathEq y x ->
SSPath x x.
Proof.
  intros x y neq patheqxy patheqyx.
  eapply t_trans.
  Case "path x y".
    eapply neq_sspatheq_imp_sspath. exact neq. exact patheqxy.
  Case "path y x".
    eapply neq_sspatheq_imp_sspath. intros contra. subst.
    apply neq. reflexivity.
    exact patheqyx.
Qed.

Lemma bunble_partial_order : forall N E,
Bundle N E ->
Order Node SSPathEq.
Proof.
  intros N E B.
  split.
  Case "Reflexivity".
    intros x. apply rt_refl. 
  Case "Transitivity".
    intros x y z xy yz.
    eapply rt_trans. exact xy. exact yz.
  Case "AntiSymmetry".
    intros x y xy yz.
    destruct B as [N E finN finE valE uniqtx acyc].
    destruct (eq_node_dec x y) as [xyeq | xyneq].
    SCase "x = y". exact xyeq.
    SCase "x <> y". 
      assert (SSPath x x) as contraxx.
        eapply sspatheq_trans_cycle. exact xyneq.
        exact xy. exact yz. apply acyc in contraxx. inversion contraxx.
Qed.

Lemma sspath_strict_order : forall N E,
Bundle N E ->
StrictOrder Node SSPath.
Proof.
  intros N E B.
  destruct B as [N E finN finE valE uniqtx acyc].
  split.
  Case "Irreflexivity".
    intros x. apply acyc.
  Case "Transitivity".
    apply sspath_transitivity.
Qed.

Lemma bundle_subset_minimal : forall N E N',
Bundle N E ->
Included Node N' N ->
N' <> Empty_set Node ->
exists min, In Node N' min 
/\ forall x, In Node N' x -> ~ SSPath x min.
Proof.
  intros N E N' B incl nempty.
  inversion B as [M F finN finE valE uniqtx acyc]; subst.
  assert (Finite Node N') as finN'. eapply Finite_downward_closed.
    exact finN. exact incl.
  destruct (finite_cardinal Node N' finN') as [n card].
  destruct n. inversion card. rewrite H in nempty.
  assert False as F. apply nempty. reflexivity. inversion F.
  destruct (minimal_finite_ensemble_mem Node 
                                        eq_node_dec 
                                        SSPath 
                                        sspath_dec 
                                        (sspath_strict_order N E B) 
                                        N' 
                                        n 
                                        card) as [min [minIn nolt]].
  exists min. split. exact minIn. exact nolt.
Qed.