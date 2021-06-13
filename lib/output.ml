open Ctypes
open Wlroots_common.Utils

module Bindings = Wlroots_ffi_f.Ffi.Make (Generated_ffi)
module Types = Wlroots_ffi_f.Ffi.Types

type t = Types.Output.t ptr
include Ptr

let signal_frame (output : t) : t Wl.Signal.t = {
  c = output |-> Types.Output.events_frame;
  typ = ptr Types.Output.t;
}

let signal_destroy (output : t) : t Wl.Signal.t = {
  c = output |-> Types.Output.events_destroy;
  typ = ptr Types.Output.t;
}

module Mode = struct
  type t = Types.Output_mode.t ptr
  include Ptr

  let width = getfield Types.Output_mode.width
  let height = getfield Types.Output_mode.height
  let refresh = getfield Types.Output_mode.refresh
  let preferred = getfield Types.Output_mode.preferred
end

let modes (output : t) : Mode.t list =
  (output |-> Types.Output.modes)
  |> Bindings.ocaml_of_wl_list
    (container_of Types.Output_mode.t Types.Output_mode.link)

let transform_matrix (output : t) : Matrix.t =
  CArray.start (output |->> Types.Output.transform_matrix)

let set_mode (output : t) (mode : Mode.t): unit =
  Bindings.wlr_output_set_mode output mode

let preferred_mode output =
  let mode = Bindings.wlr_output_preferred_mode output in
  if is_null mode then None else Some mode

let create_global (output : t) =
  Bindings.wlr_output_create_global output

let attach_render (output : t): bool =
  (* TODO: handle buffer age *)
  Bindings.wlr_output_attach_render output (coerce (ptr void) (ptr int) null)

let commit (output : t): bool =
  Bindings.wlr_output_commit output

let enable = Bindings.wlr_output_enable

let scale = getfield Types.Output.scale

let effective_resolution (output: t) : int * int =
  let width = allocate int 0 in
  let height = allocate int 0 in
  Bindings.wlr_output_effective_resolution output width height;
  (!@ width, !@ height)

type transform = Types.Wl_output_transform.transform

let transform_invert = Bindings.wlr_output_transform_invert

let render_software_cursors output =
  Bindings.wlr_output_render_software_cursors output null
