open Ctypes
open Wlroots_common.Utils

module Bindings = Wlroots_ffi_f.Ffi.Make (Generated_ffi)
module Types = Wlroots_ffi_f.Ffi.Types

type t = Types.Surface.t ptr
include Ptr

let from_resource = Bindings.wlr_surface_from_resource
let has_buffer = Bindings.wlr_surface_has_buffer

module State = struct
  type t = Types.Surface_state.t ptr
  include Ptr

  let width = getfield Types.Surface_state.width
  let height = getfield Types.Surface_state.height
  let transform = getfield Types.Surface_state.transform
end

let current = getfield Types.Surface.current
let pending = getfield Types.Surface.pending

let send_frame_done = Bindings.wlr_surface_send_frame_done

let get_texture surf =
  let t = Bindings.wlr_surface_get_texture surf in
  if is_null t
  then None
  else Some t
