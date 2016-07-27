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


(************************************************************************)
(* Based on Sexplib, (c) Jane Street, releaser under Apache License 2.0 *)
(* Custom sexp printer                                                  *)
(*                                                                      *)
(* Current sexplib escaping is not the most convenient for some clients *)
(* so we provide a different, experimental one                          *)
(************************************************************************)

open Format
open Sexplib
open Sexp

let must_escape str =
  let len = String.length str in
  len = 0 ||
    let rec loop ix =
      match str.[ix] with
      | '"' | '(' | ')' | ';' | '\\' -> true
      (* Avoid unquoted comma at the beggining of the string *)
      | ',' -> ix = 0 || loop (ix - 1)
      | '|' -> ix > 0 && let next = ix - 1 in str.[next] = '#' || loop next
      | '#' -> ix > 0 && let next = ix - 1 in str.[next] = '|' || loop next
      | '\000' .. '\032' -> true
      | '\248' .. '\255' -> true
      | _ -> ix > 0 && loop (ix - 1)
    in
    loop (len - 1)

(* XXX: Be faithful to UTF-8 *)
let st_escaped (s : string) =
  let sget = String.unsafe_get in
  let open Bytes in
  let n = ref 0 in
  for i = 0 to String.length s - 1 do
    n := !n +
      (match sget s i with
       | '\"' | '\\' | '\n' | '\t' | '\r' | '\b' -> 2
       | ' ' .. '~' -> 1
       (* UTF-8 are valid between \033 -- \247 *)
       | '\000' .. '\032' -> 4
       | '\248' .. '\255' -> 4
       | _                -> 1)
  done;
  if !n = String.length s then Bytes.of_string s else begin
    let s' = create !n in
    n := 0;
    for i = 0 to String.length s - 1 do
      begin match sget s i with
      | ('\"' | '\\') as c ->
          unsafe_set s' !n '\\'; incr n; unsafe_set s' !n c
      | '\n' ->
          unsafe_set s' !n '\\'; incr n; unsafe_set s' !n 'n'
      | '\t' ->
          unsafe_set s' !n '\\'; incr n; unsafe_set s' !n 't'
      | '\r' ->
          unsafe_set s' !n '\\'; incr n; unsafe_set s' !n 'r'
      | '\b' ->
          unsafe_set s' !n '\\'; incr n; unsafe_set s' !n 'b'
      | (' ' .. '~') as c -> unsafe_set s' !n c
      (* Valid UTF-8 are valid between \033 -- \247 *)
      | '\000' .. '\032'
      | '\248' .. '\255' as c ->
          let a = Char.code c in
          unsafe_set s' !n '\\';
          incr n;
          unsafe_set s' !n (Char.chr (48 + a / 100));
          incr n;
          unsafe_set s' !n (Char.chr (48 + (a / 10) mod 10));
          incr n;
          unsafe_set s' !n (Char.chr (48 + a mod 10));
      | c -> unsafe_set s' !n c
      end;
      incr n
    done;
    s'
  end

let esc_str (str : string) =
  let open Bytes in
  let estr = st_escaped str in
  let elen = length estr in
  let res  = create (elen + 2) in
  blit estr 0 res 1 elen;
  set res 0 '"';
  set res (elen + 1) '"';
  to_string res

let sertop_maybe_esc_str str =
  if must_escape str then esc_str str else str

let rec pp_sertop_internal may_need_space ppf = function
  | Atom str ->
      let str' = sertop_maybe_esc_str str in
      let new_may_need_space = str' == str in
      if may_need_space && new_may_need_space then pp_print_string ppf " ";
      pp_print_string ppf str';
      new_may_need_space
  | List (h :: t) ->
      pp_print_string ppf "(";
      let may_need_space = pp_sertop_internal false ppf h in
      pp_sertop_rest may_need_space ppf t;
      false
  | List [] -> pp_print_string ppf "()"; false

and pp_sertop_rest may_need_space ppf = function
  | h :: t ->
      let may_need_space = pp_sertop_internal may_need_space ppf h in
      pp_sertop_rest may_need_space ppf t
  | [] -> pp_print_string ppf ")"

let pp_sertop ppf sexp = ignore (pp_sertop_internal false ppf sexp)
