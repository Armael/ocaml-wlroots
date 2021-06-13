open Ctypes
open Wlroots_common.Utils

module Bindings = Wlroots_ffi_f.Ffi.Make (Generated_ffi)
module Types = Wlroots_ffi_f.Ffi.Types

module Event_loop = struct
  type t = unit ptr
  include Ptr
end

module Listener = struct
  (* Resources associated to a [Listener.t] (subscription to events
     broadcasted by a ['a Signal.t]) are manually managed.

     Attaching a listener to a signal using [Signal.add] registers the listener
     and gives its ownership to the C code. After attaching it, dropping the
     handle on a listener will not free the listener and its associated
     resources: one needs to explicitly call [detach] first (which un-registers
     it from the signal).

     NB: Detaching a listener then re-attaching it to the same or a different
     signal is possible -- detaching a listener does not necessarily means
     destroying it *)
  type callback = Types.Wl_listener.t ptr -> unit ptr -> unit
  let callback_dummy _ _ = assert false

  type listener = {
    c : Types.Wl_listener.t ptr;
    (* Tie the lifetime of the OCaml callbacks to the lifetime of the C
       structure, to prevent untimely memory collection *)
    mutable notify : callback;
  }

  type t = listener O.t

  let compare x1 x2 = O.compare (fun t1 t2 -> ptr_compare t1.c t2.c) x1 x2
  let equal x y = mk_equal compare x y
  let hash t = O.hash (fun t -> ptr_hash t.c) t

  let create () : t =
    let c_struct = make Types.Wl_listener.t in
    (* we do not set the [notify] field of the C structure yet. It will be
       done by [Signal.add], which will provide the coercion function from
       [void*] to ['a], computed from the [typ] field of the signal, and
       compose it with the callback (of type ['a -> unit]), pre, and post, to
       obtain [notify]. *)
    O.create { c = addr c_struct; notify = callback_dummy }

  let state (listener : t) : [`attached | `detached] =
    match O.state listener with
    | `owned -> `detached
    | `transfered_to_c -> `attached

  let detach (listener : t) =
    match O.state listener with
    | `owned -> ()
    | `transfered_to_c ->
      let raw_listener = O.reclaim_ownership listener in
      (* Throw away [notify], so that the user closure can get garbage
         collected *)
      raw_listener.notify <- callback_dummy;
      (* Detach the listener from its signal, as advised in the documentation of
         [wl_listener]. *)
      Bindings.wl_list_remove (raw_listener.c |-> Types.Wl_listener.link)
end

module Signal = struct
  type 'a t = {
    c : Types.Wl_signal.t ptr;
    typ : 'a typ;
  }

  let compare t1 t2 = ptr_compare t1.c t2.c
  let equal x y = mk_equal compare x y
  let hash t = ptr_hash t.c

  let add (signal : 'a t) (listener : Listener.t)
      (user_callback: Listener.t -> 'a -> unit) =
    match listener with
    | O.{ box = Owned raw_listener } ->
      let notify _ data = user_callback listener (coerce (ptr void) signal.typ data) in
      raw_listener.notify <- notify;
      setf (!@ (raw_listener.c)) Types.Wl_listener.notify notify;
      Bindings.wl_signal_add signal.c raw_listener.c;
      O.transfer_ownership_to_c listener
    | O.{ box = Transfered_to_C _ } ->
      failwith "Signal.add: cannot attach the same listener to multiple signals"
end

module Display = struct
  type t = unit ptr
  include Ptr

  let create () =
    let dpy = Bindings.wl_display_create () in
    if is_null dpy then failwith "Display.create";
    dpy

  let get_event_loop dpy =
    let el = Bindings.wl_display_get_event_loop dpy in
    if is_null el then failwith "Display.get_event_loop";
    el

  let run = Bindings.wl_display_run
  let destroy = Bindings.wl_display_destroy
  let destroy_clients = Bindings.wl_display_destroy_clients
  let add_socket_auto = Bindings.wl_display_add_socket_auto
  let init_shm = Bindings.wl_display_init_shm
  let terminate = Bindings.wl_display_terminate
end

module Resource = struct
  type t = Types.Wl_resource.t ptr
  include Ptr
end

module Seat_capability = struct
  type cap = Pointer | Keyboard | Touch
  type t = cap list
  include Poly

  let t : cap list typ =
    bitwise_enum Types.Wl_seat_capability.([
      Pointer, _WL_SEAT_CAPABILITY_POINTER;
      Keyboard, _WL_SEAT_CAPABILITY_KEYBOARD;
      Touch, _WL_SEAT_CAPABILITY_TOUCH;
    ])
end
