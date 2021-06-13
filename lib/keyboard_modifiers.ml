open Ctypes
open Wlroots_common.Utils

module Bindings = Wlroots_ffi_f.Ffi.Make (Generated_ffi)
module Types = Wlroots_ffi_f.Ffi.Types

type t = Types.Keyboard_modifiers.t ptr
include Ptr

let has_alt modifiers =
  Signed.Int64.of_int 0 !=
    Signed.Int64.logand
       (Unsigned.UInt32.to_int64 modifiers)
       Types.Keyboard_modifier._WLR_MODIFIER_ALT
