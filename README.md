strands
=======

Embedding strand spaces in Coq and working to verify correctness and other properties.


Requires Coq v8.4pl2
(Available at http://coq.inria.fr/download)


Based on work from the following publications:

Fábrega, F. Javier Thayer, Jonathan C. Herzog, and Joshua D. Guttman. 
  "Strand spaces: Proving security protocols correct." 
  Journal of computer security 7.2 (1999): 191-230.



File Descriptions
=================
CoLoR*.v
- These files are from the CoLoR library (http://color.inria.fr/) - this was used for proofs of the decidability of the transitive closure of a decidable relation, if limited to a finite set. Files were included in this repo so a person cloning this project need not install any other libraries in order to build the project.

finite_set_builder
- Theorems that allow a subset of a finite Ensemble to be derived given some decidable property, such that the derived subset contains all members of the parent set which that property holds for. Used to support proofs where a mathematical set-builder notation generates a set which is reasoned about.


strandlib.v
- mostly generic theorems and lemmas, in the paper and just generally useful ones that arounds during development. Included often to allow for simple, flexible, automated proofs.


strandspace.v
- This contains primarily the definitions related to Strand Spaces, Bundles, etc... the actual algebraic & logical structures

strandspaceNSL
- Proofs regarding an NSL space with DolevYao penetrator strands.

strandspacegeneric.v
- Some general conclusions about DolevYao penetrator Strand Spaces

set_rep_equiv.v
- Some theorems that allow the movement to and from Ensembles and ListSets.

strictorder.v
- This file focuses on the proofs which show for any finite set and strict order there exists a minimal element under said order. This is used in strandspace.v for the minimal member Lemma, since the "less than" relation in a Bundle which is derived from the union and transitive closure of Comm and Successor edges is a strict order.

util.v
- This just contains some convenient notation I feel clarifies work in proofs (the "Case", "SCase" notation, mainly).