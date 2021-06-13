open Ctypes
open Wlroots_common.Utils

module Bindings = Wlroots_ffi_f.Ffi.Make (Generated_ffi)
module Types = Wlroots_ffi_f.Ffi.Types

type t = Types.Event_pointer_motion_absolute.t ptr
let t = ptr Types.Event_pointer_motion_absolute.t
include Ptr

let device = getfield Types.Event_pointer_motion_absolute.device
let x = getfield Types.Event_pointer_motion_absolute.x
let y = getfield Types.Event_pointer_motion_absolute.y
let time_msec = getfield Types.Event_pointer_motion_absolute.time_msec
