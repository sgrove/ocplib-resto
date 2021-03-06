(**************************************************************************)
(*  ocplib-resto                                                          *)
(*  Copyright (C) 2016, OCamlPro.                                         *)
(*                                                                        *)
(*    All rights reserved.  This file is distributed under the terms      *)
(*    of the GNU Lesser General Public License version 2.1, with the      *)
(*    special exception on linking described in the file LICENSE.         *)
(*                                                                        *)
(**************************************************************************)

open Resto_impl

(** Typed path argument. *)
module Arg : sig

  type 'a arg = 'a Arg.arg
  val make:
    ?descr:string ->
    name:string ->
    destruct:(string -> ('a, string) result) ->
    construct:('a -> string) ->
    'a arg

  type descr = Arg.descr = {
    name: string ;
    descr: string option ;
  }
  val descr: 'a arg -> descr

  val int: int arg
  val int32: int32 arg
  val int64: int64 arg
  val float: float arg

end


(** Parametrized path to services. *)
module Path : sig

  type 'params path = (unit, 'params) Path.path

  val root: unit path

  val add_suffix: 'params path -> string -> 'params path
  val (/): 'params path -> string -> 'params path

  val add_arg: 'params path -> 'a Arg.arg -> ('params * 'a) path
  val (/:): 'params path -> 'a Arg.arg -> ('params * 'a) path

  val map: ('a -> 'b) -> ('b -> 'a) -> 'a path -> 'b path

end


(** Services. *)
type ('params, 'input, 'output) service =
  (unit, 'params, 'input, 'output) Resto_impl.service

val service:
  ?description: string ->
  input: 'input Json_encoding.encoding ->
  output: 'output Json_encoding.encoding ->
  'params Path.path ->
  ('params, 'input, 'output) service

type json = Json_repr.Ezjsonm.value

val forge_request:
  ('params, 'input, 'output) service ->
  'params -> 'input -> string list * json

val read_answer:
  ('params, 'input, 'output) service ->
  json -> ('output, string) result

module Make (Repr : Json_repr.Repr) : sig

  val forge_request:
    ('params, 'input, 'output) service ->
    'params -> 'input -> string list * Repr.value

  val read_answer:
    ('params, 'input, 'output) service ->
    Repr.value -> ('output, string) result

end

(** Service directory description *)
module Description : sig

  type service_descr =
    Description.service_descr = {
    description: string option ;
    input: Json_schema.schema ;
    output: Json_schema.schema ;
  }

  type directory_descr =
    Description.directory_descr =
    | Static of static_directory_descr
    | Dynamic of string option

  and static_directory_descr =
    Description.static_directory_descr = {
    service: service_descr option ;
    subdirs: static_subdirectories_descr option ;
  }

  and static_subdirectories_descr =
    Description.static_subdirectories_descr =
    | Suffixes of directory_descr Map.Make(String).t
    | Arg of Arg.descr * directory_descr

  val service:
    ?description:string ->
    'params Path.path ->
    ('params, bool option, directory_descr) service

  val pp_print_directory_descr:
    Format.formatter -> directory_descr -> unit

end
