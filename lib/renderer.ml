open Ctypes
open Wlroots_common.Utils

module Bindings = Wlroots_ffi_f.Ffi.Make (Generated_ffi)
module Types = Wlroots_ffi_f.Ffi.Types

type t = Types.Renderer.t ptr
include Ptr

let begin_ (renderer : t) ~width ~height =
  Bindings.wlr_renderer_begin renderer width height

let end_ (renderer : t) =
  Bindings.wlr_renderer_end renderer

let clear (renderer : t) ((c1,c2,c3,c4) : float * float * float * float) =
  let color_arr = CArray.of_list float [c1;c2;c3;c4] in
  Bindings.wlr_renderer_clear renderer (CArray.start color_arr)

let init_wl_display = Bindings.wlr_renderer_init_wl_display

let render_texture_with_matrix renderer texture matrix alpha =
  Bindings.wlr_render_texture_with_matrix renderer texture matrix alpha
