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

module Loc     = Ser_loc
module Names   = Ser_names
module Term    = Ser_constr
module Environ = Ser_environ
module Sorts   = Ser_sorts
module Univ    = Ser_univ

type arity_error =
  [%import: Type_errors.arity_error]
  [@@deriving sexp]

type guard_error =
  [%import: Type_errors.guard_error]
  [@@deriving sexp]

type type_error =
  [%import: Type_errors.type_error
  [@with Term.sorts_family := Sorts.family; ]]
  [@@deriving sexp]

