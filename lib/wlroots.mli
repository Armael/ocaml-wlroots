open Wlroots_common.Sigs

module Wl : sig
  module Event_loop : sig
    include Comparable0
  end

  module Listener : sig
    include Comparable0

    val create : unit -> t
    val state : t -> [`attached | `detached]
    val detach : t -> unit
  end

  module Signal : sig
    include Comparable1

    val add : 'a t -> Listener.t -> (Listener.t -> 'a -> unit) -> unit
  end

  module Display : sig
    include Comparable0

    val create : unit -> t
    val get_event_loop : t -> Event_loop.t
    val run : t -> unit
    val destroy : t -> unit
    val destroy_clients : t -> unit
    val add_socket_auto : t -> string option
    val init_shm : t -> int
    val terminate : t -> unit
  end

  module Resource : sig
    include Comparable0
  end

  module Seat_capability : sig
    type cap = Pointer | Keyboard | Touch
    include Comparable0 with type t = cap list
  end
end

module Texture : sig
  include Comparable0
end

module Surface : sig
  include Comparable0

  val from_resource : Wl.Resource.t -> t
  val has_buffer : t -> bool

  module State : sig
    include Comparable0
    val width : t -> int
    val height : t -> int
    val transform : t -> Output.transform
  end

  val current : t -> State.t
  val pending : t -> State.t
  val send_frame_done : t -> Mtime.t -> unit
  val get_texture : t -> Texture.t option
end

module Box : sig
  type t = { x : int; y : int; width : int; height : int }
  include Comparable0 with type t := t
end

module Matrix : sig
  include Comparable0
  val project_box : Box.t -> Output.transform -> rotation:float -> t -> t
end

module Output : sig
  type transform = Wlroots_ffi_f.Ffi.Types.Wl_output_transform.transform
  include Comparable0

  module Mode : sig
    include Comparable0

    val width : t -> int32
    val height : t -> int32
    val refresh : t -> int32 (* mHz *)
    val preferred : t -> bool
  end

  (* Setting an output mode *)
  val modes : t -> Mode.t list
  val set_mode : t -> Mode.t -> unit
  val preferred_mode : t -> Mode.t option

  val scale : t -> float

  val transform_matrix : t -> Matrix.t
  val create_global : t -> unit
  val attach_render : t -> bool
  val commit : t -> bool
  val enable : t -> bool -> unit

  val effective_resolution : t -> int * int

  val signal_frame : t -> t Wl.Signal.t
  val signal_destroy : t -> t Wl.Signal.t

  val transform_invert : transform -> transform

  val render_software_cursors : t -> unit
end

module Output_layout : sig
  include Comparable0

  val create : unit -> t
  val add_auto : t -> Output.t -> unit
  val output_coords : t -> Output.t -> float -> float -> float * float
end

module Keycodes : sig
  include Comparable0
end

module Keyboard_modifiers : sig
  include Comparable0
  val has_alt : Unsigned.uint32 -> bool
end

module Keyboard : sig
  include Comparable0

  type key_state = Released | Pressed

  module Event_key : sig
    include Comparable0

    val time_msec : t -> Unsigned.uint32
    val keycode : t -> int
    val update_state : t -> bool
    val state : t -> key_state
  end

  val xkb_state : t -> Xkbcommon.State.t
  val modifiers : t -> Keyboard_modifiers.t
  val keycodes : t -> Keycodes.t
  val num_keycodes : t -> Unsigned.size_t
  val set_keymap : t -> Xkbcommon.Keymap.t -> bool
  val set_repeat_info : t -> int -> int -> unit
  val get_modifiers : t -> Unsigned.uint32

  module Events : sig
    val key : t -> Event_key.t Wl.Signal.t
    val modifiers : t -> t Wl.Signal.t
  end
end

module Pointer : sig
  include Comparable0

  type button_state = Released | Pressed
  type axis_source = Wheel | Finger | Continuous | Wheel_tilt
  type axis_orientation = Vertical | Horizontal
end

module Edges : sig
  type edges = None | Top | Bottom | Left | Right
  include Comparable0 with type t = edges list
end

module Touch : sig
  include Comparable0
end

module Tablet_tool : sig
  include Comparable0
end

module Tablet_pad : sig
  include Comparable0
end

module Input_device : sig
  include Comparable0

  type typ =
    | Keyboard of Keyboard.t
    | Pointer of Pointer.t
    | Touch of Touch.t
    | Tablet of Tablet_tool.t
    | Tablet_pad of Tablet_pad.t

  val typ : t -> typ
  val vendor : t -> int
  val product : t -> int
  val name : t -> string

  val signal_destroy : t -> t Wl.Signal.t
end

module Event_pointer_motion : sig
  include Comparable0

  val device : t -> Input_device.t
  val time_msec : t -> Unsigned.uint32
  val delta_x : t -> float
  val delta_y : t -> float
end

module Event_pointer_motion_absolute : sig
  include Comparable0

  val device : t -> Input_device.t
  val x : t -> float
  val y : t -> float
  val time_msec : t -> Unsigned.uint32
end

module Event_pointer_button : sig
  include Comparable0

  val time_msec : t -> Unsigned.uint32
  val button : t -> Unsigned.uint32
  val state : t -> Pointer.button_state
end

module Event_pointer_axis : sig
  include Comparable0

  val time_msec : t -> Unsigned.uint32
  val orientation : t -> Pointer.axis_orientation
  val delta : t -> float
  val delta_discrete : t -> Signed.Int32.t
  val source : t -> Pointer.axis_source
end

module Renderer : sig
  include Comparable0

  val begin_ : t -> width:int -> height:int -> unit
  val end_ : t -> unit
  val clear : t -> float * float * float * float -> unit
  val init_wl_display : t -> Wl.Display.t -> bool
  val render_texture_with_matrix : t -> Texture.t -> Matrix.t -> float -> bool
end

module Backend : sig
  include Comparable0

  val autocreate : Wl.Display.t -> t
  val start : t -> bool
  val destroy : t -> unit

  val get_renderer : t -> Renderer.t

  val signal_new_output : t -> Output.t Wl.Signal.t
  val signal_new_input : t -> Input_device.t Wl.Signal.t
  val signal_destroy : t -> t Wl.Signal.t
end

module Data_device : sig
  module Manager : sig
    include Comparable0

    val create : Wl.Display.t -> t
  end
end

module Compositor : sig
  include Comparable0

  val create : Wl.Display.t -> Renderer.t -> t
end

module rec Xdg_toplevel: sig
  include Comparable0

  module Events: sig
    module Move : sig
      type t
      val surface : t -> Xdg_surface.t
      val seat : t -> Seat.t
      val serial : t -> Unsigned.UInt32.t
    end

    module Resize : sig
      type t
      val surface : t -> Xdg_surface.t
      val seat : t -> Seat.t
      val serial : t -> Unsigned.UInt32.t
      val edges : t -> Edges.t
    end

    val request_move : t -> Move.t Wl.Signal.t
    val request_resize : t -> Resize.t Wl.Signal.t
  end
end

and Xdg_surface : sig
  include Comparable0
  type role = Wlroots_ffi_f.Ffi.Types.Xdg_surface_role.role

  val role : t -> role
  val surface : t -> Surface.t
  val toplevel : t -> Xdg_toplevel.t

  val from_surface : Surface.t -> t option
  val get_geometry : t -> Box.t
  val toplevel_set_activated : t -> bool -> Unsigned.uint32
  val toplevel_set_size : t -> int -> int -> Unsigned.uint32
  val surface_at : t -> float -> float -> (Surface.t * float * float) option
  val for_each_surface : t -> (Surface.t -> int -> int -> unit) -> unit

  module Events : sig
    val destroy : t -> t Wl.Signal.t
    val ping_timeout : t -> t Wl.Signal.t
    val new_popup : t -> t Wl.Signal.t
    val map : t -> t Wl.Signal.t
    val unmap : t -> t Wl.Signal.t
    val configure : t -> t Wl.Signal.t
    val ack_configure : t -> t Wl.Signal.t

  end
end

and Xdg_shell : sig
  include Comparable0

  val create : Wl.Display.t -> t
  val signal_new_surface : t -> Xdg_surface.t Wl.Signal.t
end

module Cursor : sig
  include Comparable0

  val x : t -> float
  val y : t -> float

  val create : unit -> t
  val attach_output_layout : t -> Output_layout.t -> unit
  val attach_input_device : t -> Input_device.t -> unit
  val set_surface : t -> Surface.t -> int -> int -> unit
  val move : t -> Input_device.t -> float -> float -> unit

  val signal_motion : t -> Event_pointer_motion.t Wl.Signal.t
  val signal_motion_absolute : t -> Event_pointer_motion_absolute.t Wl.Signal.t
  val signal_button : t -> Event_pointer_button.t Wl.Signal.t
  val signal_axis : t -> Event_pointer_axis.t Wl.Signal.t
  val signal_frame : t -> unit (* ? *) Wl.Signal.t
  val warp_absolute : t -> Input_device.t -> float -> float -> unit
end

module Xcursor_manager : sig
  include Comparable0

  val create : string option -> int -> t
  val load : t -> float -> int
  val set_cursor_image : t -> string -> Cursor.t -> unit
end

module Seat : sig
  include Comparable0

  module Client : sig
    include Comparable0
  end

  module Pointer_state : sig
    include Comparable0

    val focused_client : t -> Client.t
    val focused_surface : t -> Surface.t
  end

  module Keyboard_state : sig
    include Comparable0

    val keyboard : t -> Keyboard.t
    val focused_surface : t -> Surface.t option
  end

  module Pointer_request_set_cursor_event : sig
    include Comparable0

    val seat_client : t -> Client.t
    val surface : t -> Surface.t
    val hotspot_x : t -> int
    val hotspot_y : t -> int
  end

  val pointer_state : t -> Pointer_state.t
  val keyboard_state : t -> Keyboard_state.t

  val create : Wl.Display.t -> string -> t
  val signal_request_set_cursor :
    t -> Pointer_request_set_cursor_event.t Wl.Signal.t
  val set_capabilities : t -> Wl.Seat_capability.t -> unit
  val set_keyboard : t -> Input_device.t -> unit
  val keyboard_notify_modifiers : t -> Keyboard_modifiers.t -> unit
  val keyboard_notify_enter :
    t -> Surface.t -> Keycodes.t -> Unsigned.size_t -> Keyboard_modifiers.t -> unit
  val keyboard_notify_key :
    t -> Keyboard.Event_key.t -> unit
  val pointer_notify_enter :
    t -> Surface.t -> float -> float -> unit
  val pointer_clear_focus :
    t -> unit
  val pointer_notify_motion :
    t -> Unsigned.uint32 -> float -> float -> unit
  val pointer_notify_button :
    t -> Unsigned.uint32 -> Unsigned.uint32 -> Pointer.button_state -> Unsigned.uint32
  val pointer_notify_axis :
    t -> Unsigned.uint32 -> Pointer.axis_orientation -> float -> Signed.Int32.t -> Pointer.axis_source -> unit
  val pointer_notify_frame :
    t -> unit
end

module Log : sig
  type importance =
    | Silent
    | Error
    | Info
    | Debug

  val init : importance -> unit
end
