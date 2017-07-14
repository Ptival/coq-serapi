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

module Loc        = Ser_loc

type 'a _t = {
  v   : 'a;
  loc : Loc.t option;
} [@@deriving sexp]

type 'a t = 'a CAst.t

let t_of_sexp f s = let { v ; loc } = _t_of_sexp f s in CAst.make ?loc v
let sexp_of_t f { CAst.v ; loc} = sexp_of__t f { v ; loc}
