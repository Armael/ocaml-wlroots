open Ctypes
open Wlroots_common.Utils

module Bindings = Wlroots_ffi_f.Ffi.Make (Generated_ffi)
module Types = Wlroots_ffi_f.Ffi.Types

type t = Types.Xdg_toplevel.t ptr
let t = ptr Types.Xdg_toplevel.t

include Ptr

module Events = struct
  module Move = struct
    type t = Types.Xdg_toplevel_move_event.t ptr
    let t = ptr Types.Xdg_toplevel_move_event.t

    let surface = getfield Types.Xdg_toplevel_move_event.surface
    let seat = getfield Types.Xdg_toplevel_move_event.seat
    let serial = getfield Types.Xdg_toplevel_move_event.serial
  end

  module Resize = struct
    type t = Types.Xdg_toplevel_resize_event.t ptr
    let t = ptr Types.Xdg_toplevel_resize_event.t

    let surface = getfield Types.Xdg_toplevel_resize_event.surface
    let seat = getfield Types.Xdg_toplevel_resize_event.seat
    let serial = getfield Types.Xdg_toplevel_resize_event.serial
    let edges ev = coerce uint32_t Edges.t
                     (getfield Types.Xdg_toplevel_resize_event.edges ev)
  end

  let request_move (toplevel : t) : Move.t Wl.Signal.t = {
    c = toplevel |-> Types.Xdg_toplevel.events_request_move;
    typ = Move.t;
  }

  let request_resize (toplevel : t) : Resize.t Wl.Signal.t = {
    c = toplevel |-> Types.Xdg_toplevel.events_request_resize;
    typ = Resize.t;
  }
end
