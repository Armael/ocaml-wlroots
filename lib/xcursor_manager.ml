open Ctypes
open Wlroots_common.Utils

module Bindings = Wlroots_ffi_f.Ffi.Make (Generated_ffi)
module Types = Wlroots_ffi_f.Ffi.Types

type t = Types.Xcursor_manager.t ptr
include Ptr

let create = Bindings.wlr_xcursor_manager_create
let load = Bindings.wlr_xcursor_manager_load
let set_cursor_image = Bindings.wlr_xcursor_manager_set_cursor_image
