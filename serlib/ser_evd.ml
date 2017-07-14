(************************************************************************)
(*  v      *   The Coq Proof Assistant  /  The Coq Development Team     *)
(* <O___,, *   INRIA - CNRS - LIX - LRI - PPS - Copyright 1999-2016     *)
(*   \VV/  **************************************************************)
(*    //   *      This file is distributed under the terms of the       *)
(*         *       GNU Lesser General Public License Version 2.1        *)
(************************************************************************)

(************************************************************************)
(* Coq serialization API/Plugin                                         *)
(* Copyright 2016 MINES ParisTech                                       *)
(************************************************************************)
(* Status: Very Experimental                                            *)
(************************************************************************)

open Sexplib.Std

module Environ   = Ser_environ
module Reduction = Ser_reduction
module Term      = Ser_constr

type conv_pb = Reduction.conv_pb
  [@@deriving sexp]

type evar_constraint =
  [%import: Evd.evar_constraint]
  [@@deriving sexp]

type unsolvability_explanation =
  [%import: Evd.unsolvability_explanation]
  [@@deriving sexp]
