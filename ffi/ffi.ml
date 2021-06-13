open Ctypes
open Wlroots_common.Utils

module Types = Wlroots_types_f.Types.Make (Generated_types)

module Make (F : Cstubs.FOREIGN) =
struct
  open F
  open Types

  (* time *)

  let mtime_of_timespec timespec =
    let open Time in
    let ns = Int64.(add timespec.Timespec.sec
                      (of_int timespec.Timespec.nsec)) in
    Mtime.of_uint64_ns ns

  let timespec_of_mtime mtime =
    let ns_in_sec = 1_000_000_000L in
    let ns = Mtime.to_uint64_ns mtime in
    let sec = Int64.div ns ns_in_sec in
    let nsec = Int64.rem ns ns_in_sec |> Int64.to_int in
    Time.Timespec.{ sec; nsec }

  let time : Mtime.t typ =
    view
      ~read:(fun timespec_p -> mtime_of_timespec (!@ timespec_p))
      ~write:(fun mtime ->
        let timespec = timespec_of_mtime mtime in
        allocate Time_unix.Timespec.t timespec)
      (ptr Time_unix.Timespec.t)

  (* wl_list *)

  type wl_list_p = Wl_list.t ptr
  let wl_list_p = ptr Wl_list.t

  let prev (l: wl_list_p) : wl_list_p = Ctypes.(getf (!@ l) Wl_list.prev)
  let next (l: wl_list_p) : wl_list_p = Ctypes.(getf (!@ l) Wl_list.next)

  let wl_list_init = foreign "wl_list_init"
      (wl_list_p @-> returning void)

  let wl_list_remove = foreign "wl_list_remove"
      (wl_list_p @-> returning void)

  let ocaml_of_wl_list
      (extract_elt : wl_list_p -> 'a)
      (l : wl_list_p) :
    'a list
    =
    let rec aux acc elt =
      if ptr_eq elt l then List.rev acc
      else aux ((extract_elt elt)::acc) (next elt)
    in
    if Ctypes.(ptr_eq (coerce wl_list_p (ptr void) l) null) then []
    else aux [] (next l)

  (* wl_listener *)

  let wl_listener_p = ptr Wl_listener.t

  (* wl_signal *)

  let wl_signal_p = ptr Wl_signal.t

  let wl_signal_add = foreign "wl_signal_add"
      (wl_signal_p @-> wl_listener_p @-> returning void)

  (* wl_event_loop *)

  let wl_event_loop_p = ptr void

  (* wl_display *)

  let wl_display_p = ptr void

  let wl_display_create = foreign "wl_display_create"
      (void @-> returning wl_display_p)

  let wl_display_get_event_loop = foreign "wl_display_get_event_loop"
      (wl_display_p @-> returning wl_event_loop_p)

  let wl_display_run = foreign "wl_display_run"
      (wl_display_p @-> returning void)

  let wl_display_destroy = foreign "wl_display_destroy"
      (wl_display_p @-> returning void)

  let wl_display_destroy_clients = foreign "wl_display_destroy_clients"
      (wl_display_p @-> returning void)

  let wl_display_add_socket_auto = foreign "wl_display_add_socket_auto"
      (wl_display_p @-> returning string_opt)

  let wl_display_init_shm = foreign "wl_display_init_shm"
      (wl_display_p @-> returning int)

  let wl_display_terminate = foreign "wl_display_terminate"
      (wl_display_p @-> returning void)

  (* wl_resource *)

  let wl_resource_p = ptr Wl_resource.t

  (* wl_output_transform *)

  let wl_output_transform = Wl_output_transform.t

  (* wlr_output_mode *)

  let wlr_output_mode_p = ptr Output_mode.t

  (* wlr_output *)

  let wlr_output_p = ptr Output.t

  let wlr_output_set_mode = foreign "wlr_output_set_mode"
      (wlr_output_p @-> wlr_output_mode_p @-> returning void)

  let wlr_output_create_global = foreign "wlr_output_create_global"
      (wlr_output_p @-> returning void)

  let wlr_output_attach_render = foreign "wlr_output_attach_render"
      (wlr_output_p @-> ptr int @-> returning bool)

  let wlr_output_commit = foreign "wlr_output_commit"
      (wlr_output_p @-> returning bool)

  let wlr_output_preferred_mode = foreign "wlr_output_preferred_mode"
      (wlr_output_p @-> returning wlr_output_mode_p)

  let wlr_output_enable = foreign "wlr_output_enable"
      (wlr_output_p @-> bool @-> returning void)

  let wlr_output_effective_resolution = foreign "wlr_output_effective_resolution"
      (wlr_output_p @-> ptr int @-> ptr int @-> returning void)

  let wlr_output_transform_invert = foreign "wlr_output_transform_invert"
      (wl_output_transform @-> returning wl_output_transform)

  let wlr_output_render_software_cursors = foreign "wlr_output_render_software_cursors"
      (* FIXME: The void pointer is a pixman_region32_t for which no bindings exist (yet).
         This is only ok because so far, no one uses it. *)
      (wlr_output_p @-> ptr void @-> returning void)

  (* wlr_output_layout *)

  let wlr_output_layout_p = ptr Output_layout.t

  let wlr_output_layout_create = foreign "wlr_output_layout_create"
      (void @-> returning wlr_output_layout_p)

  let wlr_output_layout_add_auto = foreign "wlr_output_layout_add_auto"
      (wlr_output_layout_p @-> wlr_output_p @-> returning void)

  let wlr_output_layout_output_coords = foreign "wlr_output_layout_output_coords"
      (wlr_output_layout_p @-> wlr_output_p @-> ptr double @-> ptr double @-> returning void)

  (* wlr_box *)

  let wlr_box_p = ptr Box.t

  (* wlr_matrix *)

  let wlr_matrix_p = ptr float

  let wlr_matrix_project_box = foreign "wlr_matrix_project_box"
      (wlr_matrix_p @-> wlr_box_p @-> Wl_output_transform.t @-> float @->
       wlr_matrix_p @-> returning void)

  (* wlr_texture *)

  let wlr_texture_p = ptr Texture.t

  (* wlr_surface *)

  let wlr_surface_p = ptr Surface.t

  let wlr_surface_from_resource = foreign "wlr_surface_from_resource"
      (wl_resource_p @-> returning wlr_surface_p)

  let wlr_surface_has_buffer = foreign "wlr_surface_has_buffer"
      (wlr_surface_p @-> returning bool)

  let wlr_surface_send_frame_done = foreign "wlr_surface_send_frame_done"
      (wlr_surface_p @-> time @-> returning void)

  let wlr_surface_get_texture = foreign "wlr_surface_get_texture"
      (wlr_surface_p @-> returning wlr_texture_p)

  (* wlr_renderer *)

  let wlr_renderer_p = ptr Renderer.t

  let wlr_renderer_begin = foreign "wlr_renderer_begin"
      (wlr_renderer_p @-> int @-> int @-> returning void)

  let wlr_renderer_end = foreign "wlr_renderer_end"
      (wlr_renderer_p @-> returning void)

  let wlr_renderer_clear = foreign "wlr_renderer_clear"
      (wlr_renderer_p @-> ptr float @-> returning void)

  let wlr_renderer_init_wl_display = foreign "wlr_renderer_init_wl_display"
      (wlr_renderer_p @-> wl_display_p @-> returning bool)

  let wlr_render_texture_with_matrix = foreign "wlr_render_texture_with_matrix"
      (wlr_renderer_p @-> wlr_texture_p @-> ptr double @-> double @-> returning bool)

  (* wlr_keyboard *)

  let wlr_keyboard_p = ptr Keyboard.t

  let wlr_keyboard_set_keymap = foreign "wlr_keyboard_set_keymap"
      (wlr_keyboard_p @-> Xkbcommon.Keymap.t @-> returning bool)

  let wlr_keyboard_modifiers_p = ptr Keyboard_modifiers.t

  let wlr_keyboard_set_repeat_info = foreign "wlr_keyboard_set_repeat_info"
      (wlr_keyboard_p @-> int32_t @-> int32_t @-> returning void)

  let wlr_keyboard_get_modifiers = foreign "wlr_keyboard_get_modifiers"
      (wlr_keyboard_p @-> returning uint32_t)

  (* wlr_backend *)

  let wlr_backend_p = ptr Backend.t

  let wlr_backend_get_renderer = foreign "wlr_backend_get_renderer"
      (wlr_backend_p @-> returning wlr_renderer_p)

  let wlr_backend_autocreate = foreign "wlr_backend_autocreate"
      (wl_display_p @-> Backend.renderer_create_func_t @-> returning wlr_backend_p)

  let wlr_backend_start = foreign "wlr_backend_start"
      (wlr_backend_p @-> returning bool)

  let wlr_backend_destroy = foreign "wlr_backend_destroy"
      (wlr_backend_p @-> returning void)

  (* wlr_data_device_manager *)

  let wlr_data_device_manager_p = ptr Data_device_manager.t

  let wlr_data_device_manager_create = foreign "wlr_data_device_manager_create"
      (wl_display_p @-> returning wlr_data_device_manager_p)

  (* wlr_compositor *)

  let wlr_compositor_p = ptr Compositor.t

  let wlr_compositor_create = foreign "wlr_compositor_create"
      (wl_display_p @-> wlr_renderer_p @-> returning wlr_compositor_p)

  (* wlr_xdg_shell *)

  let wlr_xdg_shell_p = ptr Xdg_shell.t

  let wlr_xdg_shell_create = foreign "wlr_xdg_shell_create"
      (wl_display_p @-> returning wlr_xdg_shell_p)

  (* wlr_xdg_surface *)

  let wlr_xdg_surface_p = ptr Xdg_surface.t

  let wlr_surface_is_xdg_surface = foreign "wlr_surface_is_xdg_surface"
      (wlr_surface_p @-> returning bool)

  let wlr_xdg_surface_from_wlr_surface = foreign "wlr_xdg_surface_from_wlr_surface"
      (wlr_surface_p @-> returning wlr_xdg_surface_p)

  let wlr_xdg_surface_get_geometry = foreign "wlr_xdg_surface_get_geometry"
      (wlr_xdg_surface_p @-> wlr_box_p @-> returning void)

  let wlr_xdg_surface_surface_at = foreign "wlr_xdg_surface_surface_at"
      (wlr_xdg_surface_p @-> double @-> double @-> ptr double @-> ptr double @-> returning wlr_surface_p)

  let wlr_xdg_surface_for_each_surface = foreign "wlr_xdg_surface_for_each_surface"
      (wlr_xdg_surface_p @-> Surface.wlr_surface_iterator_func_t @-> ptr void @-> returning void)

  (* wlr_xdg_toplevel *)

  let wlr_xdg_toplevel_set_activated = foreign "wlr_xdg_toplevel_set_activated"
      (wlr_xdg_surface_p @-> bool @-> returning uint32_t)

  let wlr_xdg_toplevel_set_size = foreign "wlr_xdg_toplevel_set_size"
      (wlr_xdg_surface_p @-> int @-> int @-> returning uint32_t)

  (* wlr_input_device *)

  let wlr_input_device_p = ptr Input_device.t

  (* wlr_cursor *)

  let wlr_cursor_p = ptr Cursor.t

  let wlr_cursor_create = foreign "wlr_cursor_create"
      (void @-> returning wlr_cursor_p)

  let wlr_cursor_attach_output_layout =
    foreign "wlr_cursor_attach_output_layout"
      (wlr_cursor_p @-> wlr_output_layout_p @-> returning void)

  let wlr_cursor_attach_input_device =
    foreign "wlr_cursor_attach_input_device"
      (wlr_cursor_p @-> wlr_input_device_p @-> returning void)

  let wlr_cursor_set_surface =
    foreign "wlr_cursor_set_surface"
      (wlr_cursor_p @-> wlr_surface_p @-> int @-> int @-> returning void)

  let wlr_cursor_move =
    foreign "wlr_cursor_move"
      (wlr_cursor_p @-> wlr_input_device_p @-> double @-> double @-> returning void)

  let wlr_cursor_warp_absolute = foreign "wlr_cursor_warp_absolute"
      (wlr_cursor_p @-> wlr_input_device_p @-> double @-> double @-> returning void)

  (* wlr_xcursor_manager *)

  let wlr_xcursor_manager_p = ptr Xcursor_manager.t

  let wlr_xcursor_manager_create = foreign "wlr_xcursor_manager_create"
      (string_opt @-> int @-> returning wlr_xcursor_manager_p)

  let wlr_xcursor_manager_load = foreign "wlr_xcursor_manager_load"
      (wlr_xcursor_manager_p @-> float @-> returning int)

  let wlr_xcursor_manager_set_cursor_image = foreign "wlr_xcursor_manager_set_cursor_image"
      (wlr_xcursor_manager_p @-> string @-> wlr_cursor_p @-> returning void)

  (* wlr_seat *)

  let wlr_seat_p = ptr Seat.t

  let wlr_seat_create = foreign "wlr_seat_create"
      (wl_display_p @-> string @-> returning wlr_seat_p)

  let wlr_seat_set_capabilities = foreign "wlr_seat_set_capabilities"
      (wlr_seat_p @-> Wl_seat_capability.t @-> returning void)

  let wlr_seat_set_keyboard = foreign "wlr_seat_set_keyboard"
      (wlr_seat_p @-> wlr_input_device_p @-> returning void)

  let wlr_seat_keyboard_notify_modifiers = foreign "wlr_seat_keyboard_notify_modifiers"
      (wlr_seat_p @-> wlr_keyboard_modifiers_p @-> returning void)

  let wlr_seat_keyboard_notify_enter = foreign "wlr_seat_keyboard_notify_enter"
      (wlr_seat_p
       @-> wlr_surface_p
       @-> Keycodes.t
       @-> size_t
       @-> wlr_keyboard_modifiers_p
       @-> returning void)

  let wlr_seat_keyboard_notify_key = foreign "wlr_seat_keyboard_notify_key"
      (wlr_seat_p @-> uint32_t @-> uint32_t @-> uint32_t @-> returning void)

  let wlr_seat_pointer_notify_enter = foreign "wlr_seat_pointer_notify_enter"
      (wlr_seat_p @-> wlr_surface_p @-> double @-> double @-> returning void)

  let wlr_seat_pointer_clear_focus = foreign "wlr_seat_pointer_clear_focus"
      (wlr_seat_p @-> returning void)

  let wlr_seat_pointer_notify_motion = foreign "wlr_seat_pointer_notify_motion"
      (wlr_seat_p @-> uint32_t @-> double @-> double @-> returning void)

  let wlr_seat_pointer_notify_button = foreign "wlr_seat_pointer_notify_button"
      (wlr_seat_p @-> uint32_t @-> uint32_t @-> Button_state.t @-> returning uint32_t)

  let wlr_seat_pointer_notify_axis = foreign "wlr_seat_pointer_notify_axis"
      (wlr_seat_p
       @-> uint32_t
       @-> Axis_orientation.t
       @-> double
       @-> int32_t
       @-> Axis_source.t
       @-> returning void)

  let wlr_seat_pointer_notify_frame = foreign "wlr_seat_pointer_notify_frame"
      (wlr_seat_p @-> returning void)

  (* wlr_log *)

  (* TODO *)
  let log_callback_t = ptr void
  let log_importance_t = Log.importance

  let wlr_log_init = foreign "wlr_log_init"
      (log_importance_t @-> log_callback_t @-> returning void)
end
