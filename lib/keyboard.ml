open Ctypes
open Wlroots_common.Utils

module Bindings = Wlroots_ffi_f.Ffi.Make (Generated_ffi)
module Types = Wlroots_ffi_f.Ffi.Types

type t = Types.Keyboard.t ptr
include Ptr

type key_state = Types.Key_state.t = Released | Pressed

module Event_key = struct
  type t = Types.Event_keyboard_key.t ptr
  include Ptr

  let time_msec = getfield Types.Event_keyboard_key.time_msec
  let keycode = getfield Types.Event_keyboard_key.keycode
  let update_state = getfield Types.Event_keyboard_key.update_state
  let state = getfield Types.Event_keyboard_key.state
end

let xkb_state = getfield Types.Keyboard.xkb_state

let modifiers = getfield Types.Keyboard.modifiers
let keycodes = getfield Types.Keyboard.keycodes
let num_keycodes = getfield Types.Keyboard.num_keycodes

let set_keymap = Bindings.wlr_keyboard_set_keymap
let get_modifiers = Bindings.wlr_keyboard_get_modifiers

let set_repeat_info keyboard rate delay =
  Bindings.wlr_keyboard_set_repeat_info
    keyboard
    (Signed.Int32.of_int rate)
    (Signed.Int32.of_int delay)

module Events = struct
  let key (keyboard : t) : Event_key.t Wl.Signal.t = {
      c = keyboard |-> Types.Keyboard.events_key;
      typ = ptr Types.Event_keyboard_key.t;
  }

  let modifiers (keyboard : t) : t Wl.Signal.t = {
      c = keyboard |-> Types.Keyboard.events_modifiers;
      typ = ptr Types.Keyboard.t;
  }
end
