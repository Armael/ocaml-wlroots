open Ctypes
open Wlroots_common.Utils

module Bindings = Wlroots_ffi_f.Ffi.Make (Generated_ffi)
module Types = Wlroots_ffi_f.Ffi.Types

type t = Types.Event_pointer_motion.t ptr
let t = ptr Types.Event_pointer_motion.t
include Ptr

let device = getfield Types.Event_pointer_motion.device
let time_msec = getfield Types.Event_pointer_motion.time_msec
let delta_x = getfield Types.Event_pointer_motion.delta_x
let delta_y = getfield Types.Event_pointer_motion.delta_y
