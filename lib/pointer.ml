open Ctypes
open Wlroots_common.Utils

module Bindings = Wlroots_ffi_f.Ffi.Make (Generated_ffi)
module Types = Wlroots_ffi_f.Ffi.Types

type t = Types.Pointer.t ptr
include Ptr

type button_state = Types.Button_state.t = Released | Pressed

type axis_source = Types.Axis_source.t = Wheel | Finger | Continuous | Wheel_tilt

type axis_orientation = Types.Axis_orientation.t = Vertical | Horizontal
