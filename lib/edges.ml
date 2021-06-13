open Ctypes
open Wlroots_common.Utils

module Bindings = Wlroots_ffi_f.Ffi.Make (Generated_ffi)
module Types = Wlroots_ffi_f.Ffi.Types

type edges = None | Top | Bottom | Left | Right
type t = edges list
include Poly

let t : edges list typ =
  bitwise_enum32 Types.Edges.([
    None, _WLR_EDGE_NONE;
    Top, _WLR_EDGE_TOP;
    Bottom, _WLR_EDGE_BOTTOM;
    Right, _WLR_EDGE_RIGHT;
    Left, _WLR_EDGE_LEFT;
  ])
