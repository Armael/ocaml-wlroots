open Ctypes
open Wlroots_common.Utils

module Bindings = Wlroots_ffi_f.Ffi.Make (Generated_ffi)
module Types = Wlroots_ffi_f.Ffi.Types

type t = Types.Output_layout.t ptr
include Ptr

let create = Bindings.wlr_output_layout_create
let add_auto = Bindings.wlr_output_layout_add_auto

let output_coords layout output x y =
  let lx = allocate double x in
  let ly = allocate double y in
  Bindings.wlr_output_layout_output_coords layout output lx ly;
  (!@ lx, !@ ly)
