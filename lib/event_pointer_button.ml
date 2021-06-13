open Ctypes
open Wlroots_common.Utils

module Bindings = Wlroots_ffi_f.Ffi.Make (Generated_ffi)
module Types = Wlroots_ffi_f.Ffi.Types

type t = Types.Event_pointer_button.t ptr
let t = ptr Types.Event_pointer_button.t
include Ptr

let time_msec = getfield Types.Event_pointer_button.time_msec
let button = getfield Types.Event_pointer_button.button
let state = getfield Types.Event_pointer_button.state
