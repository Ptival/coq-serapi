(************************************************************************)
(*  v      *   The Coq Proof Assistant  /  The Coq Development Team     *)
(* <O___,, *   INRIA - CNRS - LIX - LRI - PPS - Copyright 1999-2016     *)
(*   \VV/  **************************************************************)
(*    //   *      This file is distributed under the terms of the       *)
(*         *       GNU Lesser General Public License Version 2.1        *)
(************************************************************************)

(************************************************************************)
(* Coq serialization API -- Async loop                                  *)
(* Copyright 2016 MINES ParisTech                                       *)
(************************************************************************)
(* Status: Very Experimental                                            *)
(************************************************************************)

open Sexplib
open Sertop_protocol

(* There a subtles differences between the sync and async loop, so we
   keep a bit of duplication for now. *)

let read_cmd cmd_sexp : [`Error of Sexp.t | `Ok of string * cmd ] =
  try         `Ok (tagged_cmd_of_sexp cmd_sexp)
  with exn -> `Error (Conv.sexp_of_exn exn)

(* Initialize Coq. *)
let sertop_init (fb_out : Sexp.t -> unit) =
  let open Sertop_init in
  let fb_handler fb = sexp_of_answer (Feedback fb) |> fb_out in
  let no_asyncf     = {
    enable_async = None;
    async_full   = false;
    deep_edits   = false;
  }                                                 in
  let coq_opts = {
    fb_handler = fb_handler;
    aopts      = no_asyncf;
    iload_path = [];
    implicit_prelude = false;
  } in
  Sertop_init.coq_init coq_opts

(* Callback for a command. Not thread-safe. *)
let sertop_callback (out_fn : Sexp.t -> unit) sexp =
  let out_answer a = out_fn (sexp_of_answer a) in
  match read_cmd sexp with
  | `Error err         -> out_answer (SexpError err)
  | `Ok (cmd_tag, cmd) -> out_answer (Answer (cmd_tag, Ack));
                          List.(iter out_answer @@ map (fun a -> Answer (cmd_tag, a))
                                     (exec_cmd cmd))

