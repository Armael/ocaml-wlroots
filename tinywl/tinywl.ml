open Wlroots

type view = {
  surface : Xdg_surface.t;
  listener: Wl.Listener.t;
  mutable mapped: bool;
  mutable x: int;
  mutable y: int;
}

type resize = {
  geobox: Box.t;
  edges: Edges.t;
}

type grab = {
  view: view;
  x: float;
  y: float;
  resize: resize option;
}

type keyboard = {
  device: Keyboard.t;
  modifiers: Wl.Listener.t;
  key: Wl.Listener.t;
}

type tinywl_output = {
  output : Output.t;

  frame : Wl.Listener.t;
}

type cursor_mode = Passthrough
                 | Move
                 | Resize of Edges.t

type tinywl_server = {
  display : Wl.Display.t;
  backend : Backend.t;
  renderer : Renderer.t;
  output_layout : Output_layout.t;
  seat : Seat.t;
  cursor : Cursor.t;
  mutable cursor_mode : cursor_mode;
  cursor_mgr : Xcursor_manager.t;
  mutable outputs : tinywl_output list;
  mutable views : view list;
  mutable keyboards : keyboard list;

  new_output : Wl.Listener.t;

  mutable grab: grab option;
}

let default_xkb_rules : Xkbcommon.Rule_names.t = {
  rules = None;
  model = None;
  layout = None;
  variant = None;
  options = None;
}

let render_surface st output (view : view) when_ surf sx sy = Surface.(
    match get_texture surf with
    | None -> ()
    | Some texture ->
       let (ox', oy') : float * float = Output_layout.output_coords st.output_layout output 0.0 0.0 in
       let ox = Float.(add ox' (of_int (view.x + sx))) in
       let oy = Float.(add oy' (of_int (view.y + sy))) in
       let scale = Output.scale output in
       let current_surf = current surf in
       let box: Box.t = {
         x = Float.(to_int (mul ox scale));
         y = Float.(to_int (mul oy scale));
         width = Float.(to_int (mul (of_int (State.width current_surf)) scale));
         height = Float.(to_int (mul (of_int (State.height current_surf)) scale));
       } in
       let transform = Output.transform_invert (State.transform current_surf) in
       let matrix = Matrix.project_box box transform ~rotation:0.0 (Output.transform_matrix output) in
       ignore (Renderer.render_texture_with_matrix st.renderer texture matrix 1.0);
       send_frame_done surf when_
  )

let output_frame st output _ _ =
  let now = Mtime_clock.now () in
  if Output.attach_render output
  then
    let (w, h) = Output.effective_resolution output in Renderer.(
      begin_ st.renderer ~width:w ~height:h;
      clear st.renderer (0.3, 0.3, 0.3, 1.0);
      List.iter (fun view ->
        if view.mapped
        then Xdg_surface.for_each_surface view.surface
               (render_surface st output view now)
      ) (List.rev st.views);
      Output.render_software_cursors output;
      end_ st.renderer;
      ignore (Output.commit output)
    )


let server_new_output st _ output =
  let output_ok =
    match Output.preferred_mode output with
    | Some mode ->
       Output.(
         set_mode output mode;
         enable output true;
         commit output
       )
    | None -> true
  in
  if output_ok then begin
    let o = { output; frame = Wl.Listener.create () } in
    Wl.Signal.add (Output.signal_frame output) o.frame (output_frame st output);
    st.outputs <- o :: st.outputs;

    Output_layout.add_auto st.output_layout output;
    Output.create_global output;
  end

let begin_interactive st view mode =
  let focused_surface = Seat.(Pointer_state.focused_surface (pointer_state st.seat)) in
  if Xdg_surface.surface view.surface == focused_surface then (
    st.cursor_mode <- mode;
    match mode with
    | Passthrough -> ()
    | Move ->
      st.grab <- Some {
        view = view;
        x = Float.(sub (Cursor.x st.cursor) (of_int view.x));
        y = Float.(sub (Cursor.y st.cursor) (of_int view.y));
        resize = None;
      }
    | Resize edges ->
      let geobox = Xdg_surface.get_geometry view.surface in
      let border_x =
        view.x + geobox.x + (
          if List.exists ((==) Edges.Right) edges then geobox.width else 0
        )
      in
      let border_y =
        view.y + geobox.y + (
          if List.exists ((==) Edges.Bottom) edges then geobox.height else 0
        )
      in
      st.grab <- Some {
        view = view;
        x = Float.(sub (Cursor.x st.cursor) (of_int border_x));
        y = Float.(sub (Cursor.y st.cursor) (of_int border_y));
        resize = Some { edges; geobox; };
      }
  )


let focus_view st view surf =
  let keyboard_state = Seat.keyboard_state st.seat in
  let prev_surface = Seat.Keyboard_state.focused_surface keyboard_state in
  let to_deactivate =
    Option.bind prev_surface (fun prev ->
        if prev == Xdg_surface.surface surf
        then None
        else Xdg_surface.from_surface prev
      )
  in
  Option.iter (fun s -> ignore (Xdg_surface.toplevel_set_activated s false))
    to_deactivate;
  let keyboard = Seat.Keyboard_state.keyboard keyboard_state in
  st.views <- view :: List.filter ((!=) view) st.views;
  ignore (Xdg_surface.toplevel_set_activated surf true);
  Keyboard.(
    Seat.keyboard_notify_enter
      st.seat
      (Xdg_surface.surface surf)
      (keycodes keyboard)
      (num_keycodes keyboard)
      (modifiers keyboard)
  )

let keyboard_handle_modifiers st device _ keyboard =
  let _ = Seat.set_keyboard st.seat device in
  let _ = Seat.keyboard_notify_modifiers st.seat (Keyboard.modifiers keyboard) in
  ()

let server_new_xdg_surface st _listener (surf : Xdg_surface.t) =
  begin match Xdg_surface.role surf with
    | None -> ()
    | Popup -> ()
    | TopLevel ->
      let view_listener = Wl.Listener.create () in

      let view = {
        surface = surf;
        listener = view_listener;
        mapped = false;
        x = 0;
        y = 0;
      } in

      st.views <- view :: st.views;

      Wl.Signal.(
        Xdg_surface.Events.(
          add (destroy surf) view_listener
            (fun _ _ -> st.views <- List.filter (fun item -> item <> view) st.views;);
          add (map surf) view_listener
            (fun _ _ ->
              view.mapped <- true;
              focus_view st view surf);
          add (unmap surf) view_listener
            (fun _ _ -> view.mapped <- false;)
        );

        Xdg_toplevel.Events.(
          (* cotd *)
          let toplevel = Xdg_surface.toplevel surf in

          add (request_move toplevel) view_listener
            (fun _ _ -> begin_interactive st view Move);
          add (request_resize toplevel) view_listener
            (fun _ ev -> begin_interactive st view (Resize (Resize.edges ev)))
        )
      )
  end

let process_cursor_move st _time grab =
  grab.view.x <- Float.(to_int (sub (Cursor.x st.cursor) grab.x));
  grab.view.y <- Float.(to_int (sub (Cursor.y st.cursor) grab.y))

let process_cursor_resize st _time edges (grab, resize) =
  let view = grab.view in
  let border_x = Float.sub (Cursor.x st.cursor) grab.x in
  let border_y = Float.sub (Cursor.y st.cursor) grab.y in

  let (new_top, new_bottom) =
    if List.exists ((==) Edges.Top) edges
    then
      let new_top = border_y in
      let new_bottom = resize.geobox.y + resize.geobox.height in
      if new_top >= Float.of_int new_bottom
      then (new_bottom - 1, new_bottom)
      else (truncate new_top, new_bottom)
    else if List.exists ((==) Edges.Bottom) edges
    then
      let new_top = resize.geobox.y in
      let new_bottom = border_y in
      if new_bottom <= Float.of_int new_top
      then (new_top, new_top + 1)
      else (new_top, truncate new_bottom)
    else (resize.geobox.y, resize.geobox.y + resize.geobox.height)
  in
  let (new_left, new_right) =
    if List.exists ((==) Edges.Left) edges
    then
      let new_left = border_x in
      let new_right = resize.geobox.x + resize.geobox.width in
      if new_left >= Float.of_int new_right
      then (new_right - 1, new_right)
      else (truncate new_left, new_right)
    else if List.exists ((==) Edges.Right) edges
    then
      let new_left = resize.geobox.x in
      let new_right = border_x in
      if new_right <= Float.of_int new_left
      then (new_left, new_left + 1)
      else (new_left, truncate new_right)
    else (resize.geobox.x, resize.geobox.x + resize.geobox.width)
  in

  let geobox = Xdg_surface.get_geometry view.surface in
  view.x <- new_left - geobox.x;
  view.y <- new_top - geobox.y;

  let new_width = new_right - new_left in
  let new_height = new_bottom - new_top in

  ignore (Xdg_surface.toplevel_set_size view.surface, new_width, new_height)

let view_at lx ly (view : view) =
  let view_sx = Float.(sub lx (of_int view.x)) in
  let view_sy = Float.(sub ly (of_int view.y)) in
  Xdg_surface.surface_at view.surface view_sx view_sy

let desktop_view_at cursor =
  List.find_map (fun view ->
      Option.map (fun (surf, x, y) -> (view, surf, x, y))
        Cursor.(view_at (x cursor) (y cursor) view))

let process_cursor_motion st time =
  begin match st.cursor_mode with
  | Move ->
    Option.iter (process_cursor_move st time) st.grab
  | Resize edges -> Option.(
       let resizing = bind st.grab (fun g -> map (fun r -> (g, r)) g.resize)
       in iter (process_cursor_resize st time edges) resizing
     )
  | Passthrough ->
    let view = desktop_view_at st.cursor st.views in
    match view with
    | None ->
      Xcursor_manager.set_cursor_image st.cursor_mgr "left_ptr" st.cursor;
      Seat.pointer_clear_focus st.seat
    | Some (_view, surf, sub_x, sub_y) ->
      let focus_changed = Seat.(Pointer_state.focused_surface (pointer_state st.seat)) != surf in
      Seat.pointer_notify_enter st.seat surf sub_x sub_y;
      if not focus_changed then Seat.pointer_notify_motion st.seat time sub_x sub_y
  end

let server_cursor_motion st _ (evt: Event_pointer_motion.t) = Event_pointer_motion.(
    Cursor.move st.cursor (device evt) (delta_x evt) (delta_y evt);
    process_cursor_motion st (time_msec evt)
  )

let server_cursor_motion_absolute st _ (evt: Event_pointer_motion_absolute.t) =
  Event_pointer_motion_absolute.(
    Cursor.warp_absolute st.cursor (device evt) (x evt) (y evt);
    process_cursor_motion st (time_msec evt)
  )

let server_cursor_button st _ (evt: Event_pointer_button.t) =
  let button_state = Event_pointer_button.state evt in
  ignore Event_pointer_button.(
    Seat.pointer_notify_button st.seat (time_msec evt) (button evt) button_state
  );
  if button_state == Pointer.Released
  then st.cursor_mode <- Passthrough
  else
    let found_view = desktop_view_at st.cursor st.views in
    Option.iter (fun (view, surf, _, _) ->
        Option.iter (focus_view st view) (Xdg_surface.from_surface surf))
      found_view

let server_cursor_axis st _ (evt : Event_pointer_axis.t) = Event_pointer_axis.(
    Seat.pointer_notify_axis
      st.seat
      (time_msec evt)
      (orientation evt)
      (delta evt)
      (delta_discrete evt)
      (source evt)
 )

let server_cursor_frame st _ _ =
  Seat.pointer_notify_frame st.seat

let handle_keybinding st sym =
  if sym == Xkbcommon.Keysyms._Escape
  then
    let () = Wl.Display.terminate st.display in
    true
  else if sym == Xkbcommon.Keysyms._F1
  then
    match st.views with
    | [] -> true
    | [_] -> true
    | (x :: y :: xs) ->
       let () = focus_view st y y.surface in
       st.views <- y :: List.append xs [x];
       true
  else false

let keyboard_handle_key st keyboard device _ key_evt =
  let keycode = Keyboard.Event_key.keycode key_evt in
  let syms = Xkbcommon.State.key_get_syms (Keyboard.xkb_state keyboard) keycode in
  let modifiers = Keyboard.get_modifiers keyboard in
  let handled =
    if Keyboard_modifiers.has_alt modifiers && Keyboard.Event_key.state key_evt == Keyboard.Pressed
    then List.fold_left (fun _ sym -> handle_keybinding st sym) false syms
    else false
  in
  if not handled then
    let () = Seat.set_keyboard st.seat device in
    Seat.keyboard_notify_key st.seat key_evt

let server_new_keyboard_set_settings (keyboard: Keyboard.t) =
  let xkb_context = match Xkbcommon.Context.create () with
    | Some ctx -> ctx
    | None -> failwith "Xkbcommon.Context.create"
  in
  let keymap = match Xkbcommon.Keymap.new_from_names xkb_context default_xkb_rules with
    | Some m -> m
    | None -> failwith "Xkbcommon.Keymap.new_from_names"
  in
  let _ = Keyboard.set_keymap keyboard keymap in
  (* Is this for some reference counting stuff?????? *)
  let _ = Xkbcommon.Keymap.unref keymap in
  let _ = Xkbcommon.Context.unref xkb_context in
  Keyboard.set_repeat_info keyboard 25 6000

let server_new_keyboard st (device: Input_device.t) =
  match Input_device.typ device with
  | Input_device.Keyboard keyboard ->
     server_new_keyboard_set_settings keyboard;
     let modifiers_l = Wl.Listener.create () in
     let key_l = Wl.Listener.create () in
     Wl.Signal.(Keyboard.Events.(
       add (modifiers keyboard) modifiers_l
         (keyboard_handle_modifiers st device);
       add (key keyboard) key_l
         (keyboard_handle_key st keyboard device);
     ));
     let tinywl_keyboard = {
       device = keyboard;
       modifiers = modifiers_l;
       key = key_l;
     } in

     st.keyboards <- tinywl_keyboard :: st.keyboards;
  | _ -> ()

let server_new_pointer st (pointer: Input_device.t) =
  Cursor.attach_input_device st.cursor pointer

let server_new_input st _ (device: Input_device.t) = Input_device.(
    match typ device with
    | Keyboard _ ->
      server_new_keyboard st device
    | Pointer _ ->
      server_new_pointer st device
    | _ -> ()
  );

  let caps =
    Wl.Seat_capability.Pointer ::
    (match st.keyboards with
     | [] -> []
     | _ -> [Wl.Seat_capability.Keyboard])
  in
  Seat.set_capabilities st.seat caps

let server_request_cursor st _ (ev: Seat.Pointer_request_set_cursor_event.t) =
  let focused_client =
    st.seat |> Seat.pointer_state |> Seat.Pointer_state.focused_client in

  Seat.Pointer_request_set_cursor_event.(
    if Seat.Client.equal focused_client (seat_client ev)
    then Cursor.set_surface st.cursor (surface ev) (hotspot_x ev) (hotspot_y ev)
  )

let () =
  Log.(init Debug);
  let startup_cmd =
    match Array.to_list Sys.argv |> List.tl with
    | ["-s"; cmd] -> Some cmd
    | [] -> None
    | _ ->
      Printf.printf "Usage: %s [-s startup command]\n" Sys.argv.(0);
      exit 0
  in

  let display = Wl.Display.create () in
  let backend = Backend.autocreate display in
  let renderer = Backend.get_renderer backend in
  assert (Renderer.init_wl_display renderer display);

  let _compositor = Compositor.create display renderer in
  let _data_manager = Data_device.Manager.create display in

  let output_layout = Output_layout.create () in

  let xdg_shell = Xdg_shell.create display in

  let cursor = Cursor.create () in
  Cursor.attach_output_layout cursor output_layout;

  let cursor_mgr = Xcursor_manager.create None 24 in
  ignore (Xcursor_manager.load cursor_mgr 1. : int);

  let seat = Seat.create display "seat0" in

  Wl.Listener.(
    let new_output = create () in
    let new_xdg_surface = create () in
    let cursor_motion = create () in
    let cursor_motion_absolute = create () in
    let cursor_button = create () in
    let cursor_axis = create () in
    let cursor_frame = create () in
    let new_input = create () in
    let request_cursor = create () in
    let st = { display; backend; renderer; output_layout; new_output; seat;
               cursor; cursor_mode = Passthrough; cursor_mgr; outputs = [];
               views = []; keyboards = []; grab = None } in

    Wl.Signal.(
      add (Backend.signal_new_output backend) new_output
        (server_new_output st);
      add (Xdg_shell.signal_new_surface xdg_shell) new_xdg_surface
        (server_new_xdg_surface st);

      Cursor.(
        add (signal_motion cursor) cursor_motion
          (server_cursor_motion st);
        add (signal_motion_absolute cursor) cursor_motion_absolute
          (server_cursor_motion_absolute st);
        add (signal_button cursor) cursor_button
          (server_cursor_button st);
        add (signal_axis cursor) cursor_axis
          (server_cursor_axis st);
        add (signal_frame cursor) cursor_frame
          (server_cursor_frame st)
      );

      add (Backend.signal_new_input backend) new_input
        (server_new_input st);
      add (Seat.signal_request_set_cursor seat) request_cursor
        (server_request_cursor st)
    )
  );

  let socket = match Wl.Display.add_socket_auto display with
    | None -> Backend.destroy backend; exit 1
    | Some socket -> socket
  in

  Backend.(if not (start backend) then (
    destroy backend;
    Wl.Display.destroy display;
    exit 1
  ));

  Unix.putenv "WAYLAND_DISPLAY" socket;
  begin match startup_cmd with
    | Some cmd ->
      if Unix.fork () = 0 then Unix.execv "/bin/sh" [|"/bin/sh"; "-c"; cmd|]
    | None -> ()
  end;

  Printf.printf "Running wayland compositor on WAYLAND_DISPLAY=%s" socket;

  Wl.Display.(
    run display;
    destroy_clients display;
    destroy display
  )
