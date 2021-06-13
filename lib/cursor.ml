open Ctypes
open Wlroots_common.Utils

module Bindings = Wlroots_ffi_f.Ffi.Make (Generated_ffi)
module Types = Wlroots_ffi_f.Ffi.Types

type t = Types.Cursor.t ptr
include Ptr

let x = getfield Types.Cursor.x
let y = getfield Types.Cursor.y


let create = Bindings.wlr_cursor_create
let attach_output_layout = Bindings.wlr_cursor_attach_output_layout
let attach_input_device = Bindings.wlr_cursor_attach_input_device
let set_surface = Bindings.wlr_cursor_set_surface
let move = Bindings.wlr_cursor_move

let signal_motion (cursor: t) : Event_pointer_motion.t Wl.Signal.t = {
  c = cursor |-> Types.Cursor.events_motion;
  typ = Event_pointer_motion.t;
}

let signal_motion_absolute (cursor: t) :
  Event_pointer_motion_absolute.t Wl.Signal.t = {
  c = cursor |-> Types.Cursor.events_motion_absolute;
  typ = Event_pointer_motion_absolute.t;
}

let signal_button (cursor: t) : Event_pointer_button.t Wl.Signal.t = {
  c = cursor |-> Types.Cursor.events_button;
  typ = Event_pointer_button.t;
}

let signal_axis (cursor: t) : Event_pointer_axis.t Wl.Signal.t = {
  c = cursor |-> Types.Cursor.events_axis;
  typ = Event_pointer_axis.t;
}

let signal_frame (cursor: t) : unit Wl.Signal.t = {
  c = cursor |-> Types.Cursor.events_frame;
  typ = void;
}

let warp_absolute = Bindings.wlr_cursor_warp_absolute
