open Ctypes

let ( |->> ) s f = !@ (s |-> f)
let getfield f s = s |->> f

let container_of s field p =
  let p = coerce (ptr (reference_type p)) (ptr char) p in
  coerce (ptr char) (ptr s) (p -@ offsetof field)

let ptr_eq p q = ptr_compare p q = 0

let ptr_hash : 'a ptr -> int = fun p ->
  to_voidp p |> raw_address_of_ptr |> Hashtbl.hash

let mk_equal compare x y = compare x y = 0

let bitwise_enum desc =
  let open Unsigned.UInt64 in
  let open Infix in
  let read i =
    List.filter_map (fun (x, cst) ->
      if (i land cst) <> zero then
        Some x
      else None
    ) desc
  in
  let write items =
    List.fold_left (fun i item ->
      (List.assoc item desc) lor i
    ) zero items
  in
  view ~read ~write uint64_t

let bitwise_enum32 desc =
  let open Unsigned.UInt32 in
  let open Infix in
  let read i =
    List.filter_map (fun (x, cst) ->
      if (i land cst) <> zero then
        Some x
      else None
    ) desc
  in
  let write items =
    List.fold_left (fun i item ->
      (List.assoc item desc) lor i
    ) zero items
  in
  view ~read ~write uint32_t

module Ptr = struct
  let compare = ptr_compare
  let hash = ptr_hash
  let equal = ptr_eq
end

module Poly = struct
  let compare = compare
  let hash = Hashtbl.hash
  let equal = (=)
end

module O = struct
  type 'a data =
    | Owned of 'a
    | Transfered_to_C of unit ptr (* GC root *)

  type 'a t = { mutable box : 'a data }

  let compare cmp x1 x2 =
    match (x1.box, x2.box) with
    | Owned o1, Owned o2 -> cmp o1 o2
    | Transfered_to_C p1, Transfered_to_C p2 -> ptr_compare p1 p2
    | Owned _, Transfered_to_C _ -> -1
    | Transfered_to_C _, Owned _ -> 1

  let hash h x =
    match x.box with
    | Owned o -> h o
    | Transfered_to_C p -> ptr_hash p

  let create : 'a -> 'a t = fun data ->
    { box = Owned data }

  let transfer_ownership_to_c : 'a t -> unit = function
    | { box = Owned data } as t ->
      let root = Root.create data in
      t.box <- Transfered_to_C root
    | { box = Transfered_to_C _ } ->
      failwith "transfer_ownership: data not owned"

  let reclaim_ownership : 'a t -> 'a = function
    | { box = Transfered_to_C root } as t ->
      let data = Root.get root in
      Root.release root;
      t.box <- Owned data;
      data
    | { box = Owned _ } ->
      failwith "reclaim_ownership: data not transfered to C"

  let state : 'a t -> [`owned | `transfered_to_c] = function
    | { box = Owned _ } -> `owned
    | { box = Transfered_to_C _ } -> `transfered_to_c
end
