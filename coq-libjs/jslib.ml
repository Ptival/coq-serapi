(* Coq JavaScript API. Based in the coq source code and js_of_ocaml.
 *
 * By Emilio J. Gallego Arias, Mines ParisTech, Paris.
 * LICENSE: GPLv3+
 *
 * This file contains the basic coq library definitions used in jscoq.
 *)

(* Information about a Coq library.
 *
 * We could have accessed Loadpath.t, etc..., but we've opted to keep
 * this module separated from Coq
 *)
type digest = string
  (* [@@deriving json] *)

type coq_pkg = {
  pkg_id    : string list;
  vo_files  : (string * digest) list;
  cma_files : (string * digest) list;
} (* [@@deriving json] *)

let to_dir  pkg = String.concat "/" (pkg.pkg_id)
let to_desc pkg = String.concat "." (pkg.pkg_id)

type coq_bundle = {
  desc      : string;
  deps      : string list;
  pkgs      : coq_pkg list;
} (* [@@deriving json] *)

let no_files pkg = List.length pkg.vo_files + List.length pkg.cma_files

(* JSON handling *)
open Yojson.Safe

let file_to_json (f : (string * Digest.t)) : json =
  `String (fst f)

let coq_pkg_to_yojson (p : coq_pkg) : json =
  `Assoc ["pkg_id",    `List (List.map (fun s -> `String s) p.pkg_id);
          "vo_files",  `List (List.map file_to_json p.vo_files);
          "cma_files", `List (List.map file_to_json p.cma_files)]

let json_to_file (f : json) : (string * Digest.t) =
  match f with
  | `String name -> (name, Digest.string "")
  | _            -> raise (Failure "JSON")

let json_to_string (s : json) : string =
  match s with
  | `String name -> name
  | _            -> raise (Failure "JSON")

let coq_pkg_of_yojson (p : json) : coq_pkg =
  match p with
  | `Assoc ["pkg_id", `List pid; "vo_files", `List vo_files; "cma_files", `List cma_files] ->
     { pkg_id    = List.map json_to_string pid;
       vo_files  = List.map json_to_file vo_files;
       cma_files = List.map json_to_file cma_files;
     }
  | _ -> raise (Failure "JSON")

let coq_bundle_to_yojson (b : coq_bundle) : json =
  `Assoc ["desc", `String b.desc;
          "deps", `List ((List.map (fun s -> `String s) b.deps));
          "pkgs", `List (List.map coq_pkg_to_yojson b.pkgs)]

let coq_bundle_of_yojson (p : json) : coq_bundle =
  match p with
  | `Assoc ["desc", `String desc;
            "deps", `List deps;
            "pkgs", `List pkgs
           ] ->
     { desc = desc;
       deps = List.map json_to_string deps;
       pkgs = List.map coq_pkg_of_yojson pkgs;
     }
  | _ -> raise (Failure "JSON")

