open Ctypes
open Wlroots_common.Utils

module Bindings = Wlroots_ffi_f.Ffi.Make (Generated_ffi)
module Types = Wlroots_ffi_f.Ffi.Types

type t = Types.Seat.t ptr
include Ptr

module Pointer_request_set_cursor_event = struct
  type t = Types.Seat_pointer_request_set_cursor_event.t ptr
  let t = ptr Types.Seat_pointer_request_set_cursor_event.t
  include Ptr

  let seat_client (ev: t) =
    ev |->> Types.Seat_pointer_request_set_cursor_event.seat_client
  let surface ev =
    ev |->> Types.Seat_pointer_request_set_cursor_event.surface
  let hotspot_x ev =
    ev |->> Types.Seat_pointer_request_set_cursor_event.hotspot_x
  let hotspot_y ev =
    ev |->> Types.Seat_pointer_request_set_cursor_event.hotspot_y
end

module Client = struct
  type t = Types.Seat_client.t ptr
  let t = ptr Types.Seat_client.t
  include Ptr
end

module Pointer_state = struct
  type t = Types.Seat_pointer_state.t ptr
  let t = ptr Types.Seat_pointer_state.t
  include Ptr

  let focused_client (st: t) =
    st |->> Types.Seat_pointer_state.focused_client
  let focused_surface =
    getfield Types.Seat_pointer_state.focused_surface
end

module Keyboard_state = struct
  type t = Types.Seat_keyboard_state.t ptr
  let t = ptr Types.Seat_keyboard_state.t
  include Ptr

  let keyboard = getfield Types.Seat_keyboard_state.keyboard

  let focused_surface (st : t) =
    let surf = st |-> Types.Seat_keyboard_state.focused_surface in
    if is_null surf
    then None
    else Some (!@ surf)
end

let pointer_state seat = seat |-> Types.Seat.pointer_state
let keyboard_state seat = seat |-> Types.Seat.keyboard_state

let create = Bindings.wlr_seat_create

let signal_request_set_cursor (seat: t) : _ Wl.Signal.t = {
  c = seat |-> Types.Seat.events_request_set_cursor;
  typ = Pointer_request_set_cursor_event.t
}

let set_capabilities seat caps =
  Bindings.wlr_seat_set_capabilities
    seat (coerce Wl.Seat_capability.t uint64_t caps)

let set_keyboard =
  Bindings.wlr_seat_set_keyboard

let keyboard_notify_modifiers =
  Bindings.wlr_seat_keyboard_notify_modifiers

let keyboard_notify_enter =
  Bindings.wlr_seat_keyboard_notify_enter

let keyboard_notify_key seat evt =
  Bindings.wlr_seat_keyboard_notify_key
    seat
    (Keyboard.Event_key.time_msec evt)
    (Unsigned.UInt32.of_int (Keyboard.Event_key.keycode evt))
    (coerce Types.Key_state.t uint32_t (Keyboard.Event_key.state evt))

let pointer_notify_enter =
  Bindings.wlr_seat_pointer_notify_enter

let pointer_clear_focus =
  Bindings.wlr_seat_pointer_clear_focus

let pointer_notify_motion =
  Bindings.wlr_seat_pointer_notify_motion

let pointer_notify_button =
  Bindings.wlr_seat_pointer_notify_button

let pointer_notify_axis =
  Bindings.wlr_seat_pointer_notify_axis

let pointer_notify_frame =
  Bindings.wlr_seat_pointer_notify_frame
