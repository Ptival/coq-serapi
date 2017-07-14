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

(** We provide the public API here for Ocaml clients  *)
open Sexplib

(******************************************************************************)
(* Basic Protocol Objects                                                     *)
(******************************************************************************)
type coq_object =
    CoqString  of string
  | CoqSList   of string list
  | CoqRichpp  of Richpp.richpp
  | CoqRichXml of Richpp.richpp
  | CoqLoc     of Loc.t
  | CoqOption  of Goptions.option_name * Goptions.option_state
  | CoqConstr  of Constr.constr
  | CoqExpr    of Constrexpr.constr_expr
  | CoqTactic  of Names.KerName.t * Tacenv.ltac_entry
  | CoqQualId  of Libnames.qualid
  | CoqImplicit of Impargs.implicits_list
  | CoqProfData of Profile_ltac.ltacprof_results
  (* | CoqPhyLoc  of Library.library_location * Names.DirPath.t * string (\* CUnix.physical_path *\) *)
  | CoqGoal    of (Constr.constr * (Names.Id.t list * Constr.constr option * Constr.constr) list) Proof.pre_goals

val coq_object_of_sexp : Sexp.t -> coq_object
val sexp_of_coq_object : coq_object -> Sexp.t

(******************************************************************************)
(* Printing Sub-Protocol                                                      *)
(******************************************************************************)

(* no public interface *)

(******************************************************************************)
(* Parsing Sub-Protocol                                                       *)
(******************************************************************************)

(* no public interface *)

(******************************************************************************)
(* Answer Types                                                               *)
(******************************************************************************)

type answer_kind =
    Ack
  | StmCurId     of Stateid.t
  | StmAdded     of Stateid.t * Loc.t * [`NewTip | `Unfocus of Stateid.t ]
  | StmCanceled  of Stateid.t list
  | StmEdited of                        [`NewTip | `Focus   of Stm.focus ]
  | ObjList      of coq_object list
  | CoqExn       of exn
  | Completed

val sexp_of_answer_kind : answer_kind -> Sexp.t
val answer_kind_of_sexp : Sexp.t -> answer_kind

(******************************************************************************)
(* Control Sub-Protocol                                                       *)
(******************************************************************************)

type add_opts = {
  lim    : int       option;
  ontop  : Stateid.t option;
  newtip : Stateid.t option;
  verb   : bool;
}

type control_cmd =
    StmState
  | StmAdd     of       add_opts  * string      (* Stm.add       *)
  | StmQuery   of       Stateid.t * string
  | StmCancel  of       Stateid.t list
  | StmEditAt  of       Stateid.t
  | StmObserve of       Stateid.t
  | StmJoin                                     (* Stm.join      *)
  | StmStopWorker of    string
  | SetOpt     of bool option * Goptions.option_name * Goptions.option_value
  | LibAdd     of string list * string * bool
  | Quit

val sexp_of_control_cmd : control_cmd -> Sexp.t
val control_cmd_of_sexp : Sexp.t -> control_cmd

(******************************************************************************)
(* Query Sub-Protocol                                                         *)
(******************************************************************************)

type query_pred =
  | Prefix of string

val query_pred_of_sexp : Sexp.t -> query_pred
val sexp_of_query_pred : query_pred -> Sexp.t

(** Query output format  *)
type print_format =
  | PpSexp
  | PpStr

val print_format_of_sexp : Sexp.t -> print_format
val sexp_of_print_format : print_format -> Sexp.t

type print_opt = {
  pp_format : print_format;
  pp_depth  : int;
  pp_elide  : string;
  (* pp_margin : int; *)
}

val print_opt_of_sexp : Sexp.t -> print_opt
val sexp_of_print_opt : print_opt -> Sexp.t

type query_opt =
  { preds : query_pred list;
    limit : int option;
    sid   : Stateid.t;
    pp    : print_opt ;
  }

val query_opt_of_sexp : Sexp.t -> query_opt
val sexp_of_query_opt : query_opt -> Sexp.t

(** We would ideally make both query_cmd and coq_object depend on a
  * tag such that query : 'a query -> 'a coq_object.
  *)
type query_cmd =
  | Option
  | Search
  | Goals     of Stateid.t        (* Return goals [TODO: Add filtering/limiting options] *)
  | TypeOf    of string           (* XXX Unimplemented *)
  | Names     of string           (* argument is prefix -> XXX Move to use the prefix predicate *)
  | Tactics   of string           (* argument is prefix -> XXX Move to use the prefix predicate *)
  | Locate    of string           (* argument is prefix -> XXX Move to use the prefix predicate *)
  | Implicits of string           (* XXX Print LTAC signatures (with prefix) *)
  | ProfileData

val query_cmd_of_sexp : Sexp.t -> query_cmd
val sexp_of_query_cmd : query_cmd -> Sexp.t

(******************************************************************************)
(* Help                                                                       *)
(******************************************************************************)

(* no public interface *)

(******************************************************************************)
(* Top-Level Commands                                                         *)
(******************************************************************************)

type cmd =
    Control of control_cmd
  | Print   of print_opt * coq_object
  | Parse   of int * string
  | Query   of query_opt * query_cmd
  | Noop
  | Help

val cmd_of_sexp : Sexp.t -> cmd
val sexp_of_cmd : cmd -> Sexp.t

val exec_cmd : cmd -> answer_kind list

type cmd_tag = string
type tagged_cmd = cmd_tag * cmd

val tagged_cmd_of_sexp : Sexp.t -> tagged_cmd
val sexp_of_tagged_cmd : tagged_cmd -> Sexp.t

type answer =
  | Answer    of cmd_tag * answer_kind
  | Feedback  of Feedback.feedback
  | SexpError of Sexp.t

val sexp_of_answer : answer -> Sexp.t
val answer_of_sexp : Sexp.t -> answer

(******************************************************************************)
(* Global Protocol Options                                                    *)
(******************************************************************************)

type ser_opts = {
  coqlib   : string option;       (* Whether we should load the prelude, and its location *)
  in_chan  : in_channel;          (* Input/Output channels                                *)
  out_chan : out_channel;
  human    : bool;
  print0   : bool;
  lheader  : bool;
  implicit : bool;
  async    : Sertop_init.async_flags;
}

(******************************************************************************)
(* Input/Output -- Main Loop                                                  *)
(******************************************************************************)

(** [ser_loop opts] main se(xp)r-protocol loop *)
val ser_loop : ser_opts -> unit
