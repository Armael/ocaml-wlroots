open Ctypes
open Wlroots_common.Utils

module Bindings = Wlroots_ffi_f.Ffi.Make (Generated_ffi)
module Types = Wlroots_ffi_f.Ffi.Types

type t = Types.Event_pointer_axis.t ptr
let t = ptr Types.Event_pointer_axis.t
include Ptr

let time_msec = getfield Types.Event_pointer_axis.time_msec
let orientation = getfield Types.Event_pointer_axis.orientation
let delta = getfield Types.Event_pointer_axis.delta
let delta_discrete = getfield Types.Event_pointer_axis.delta_discrete
let source = getfield Types.Event_pointer_axis.source
