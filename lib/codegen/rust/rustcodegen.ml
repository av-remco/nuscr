open! Base
open Names
open Efsm
open Message

let state_name st = Printf.sprintf "S%d" st

let capitalize_first s =
  if String.is_empty s then s
  else String.prefix s 1 |> String.capitalize |> fun first ->
    first ^ String.drop_prefix s 1

let rust_role_name r = capitalize_first (RoleName.user r)

let collect_labels g =
  let f (_, a, _) acc =
    match a with
    | SendA (_, m, _, _) | RecvA (_, m, _, _) ->
        Set.add acc (LabelName.user m.label)
    | Epsilon -> acc
  in
  G.fold_edges_e f g (Set.empty (module String))

let gen_state_enum g =
  let buf = Buffer.create 256 in
  Buffer.add_string buf
    "#[derive(Debug, Clone, Copy, PartialEq, Eq)]\nenum State {\n" ;
  G.iter_vertex (fun st ->
    Buffer.add_string buf (Printf.sprintf "    %s,\n" (state_name st))
  ) g ;
  Buffer.add_string buf "}\n" ;
  Buffer.contents buf

let gen_role_enum g =
  let roles = find_all_roles g in
  let buf = Buffer.create 256 in
  Buffer.add_string buf
    "#[derive(Debug, Clone, Copy, PartialEq, Eq)]\nenum Role {\n" ;
  Set.iter roles ~f:(fun r ->
    Buffer.add_string buf (Printf.sprintf "    %s,\n" (rust_role_name r))
  ) ;
  Buffer.add_string buf "}\n" ;
  Buffer.contents buf

let gen_label_enum g =
  let labels = collect_labels g in
  let buf = Buffer.create 256 in
  Buffer.add_string buf
    "#[derive(Debug, Clone, Copy, PartialEq, Eq)]\nenum Label {\n" ;
  Set.iter labels ~f:(fun l ->
    Buffer.add_string buf (Printf.sprintf "    %s,\n" (capitalize_first l))
  ) ;
  Buffer.add_string buf "}\n" ;
  Buffer.contents buf

let gen_direction_enum () =
  "#[derive(Debug, Clone, Copy, PartialEq, Eq)]\n\
   enum Direction {\n\
  \    Send,\n\
  \    Recv,\n\
   }\n"

let gen_support_types () =
  "#[derive(Debug, Clone, PartialEq)]\n\
   struct Value;\n\
   \n\
   struct Memory;\n\
   \n\
   impl Memory {\n\
  \    fn new() -> Self {\n\
  \        Self\n\
  \    }\n\
   }\n\
   \n\
   #[derive(Debug, Clone, PartialEq)]\n\
   struct Action {\n\
  \    dir: Direction,\n\
  \    role: Role,\n\
  \    label: Label,\n\
  \    payloads: Vec<Value>,\n\
   }\n"

let gen_step_fn g =
  let buf = Buffer.create 512 in
  Buffer.add_string buf
    "    fn step(&mut self, action: &Action) -> bool {\n\
    \        match (self.state, action.dir, action.role, action.label) {\n" ;
  G.iter_edges_e (fun (src, a, dst) ->
    match a with
    | SendA (r, m, _, _) ->
        Buffer.add_string buf
          (Printf.sprintf
             "            (State::%s, Direction::Send, Role::%s, Label::%s) \
              => { self.state = State::%s; true }\n"
             (state_name src) (rust_role_name r)
             (capitalize_first (LabelName.user m.label))
             (state_name dst))
    | RecvA (r, m, _, _) ->
        Buffer.add_string buf
          (Printf.sprintf
             "            (State::%s, Direction::Recv, Role::%s, Label::%s) \
              => { self.state = State::%s; true }\n"
             (state_name src) (rust_role_name r)
             (capitalize_first (LabelName.user m.label))
             (state_name dst))
    | Epsilon -> ()
  ) g ;
  Buffer.add_string buf
    "            _ => false,\n\
    \        }\n\
    \    }\n" ;
  Buffer.contents buf

let gen_is_terminal g =
  let terminals = Buffer.create 128 in
  let first = ref true in
  G.iter_vertex (fun st ->
    match state_action_type g st with
    | `Terminal ->
        if !first then (
          Buffer.add_string terminals (Printf.sprintf "State::%s" (state_name st)) ;
          first := false
        ) else
          Buffer.add_string terminals (Printf.sprintf " | State::%s" (state_name st))
    | _ -> ()
  ) g ;
  let terminal_states = Buffer.contents terminals in
  if String.is_empty terminal_states then
    "    fn is_terminal(&self) -> bool {\n\
    \        false\n\
    \    }\n"
  else
    Printf.sprintf
      "    fn is_terminal(&self) -> bool {\n\
      \        matches!(self.state, %s)\n\
      \    }\n"
      terminal_states

let gen_monitor start g =
  let buf = Buffer.create 1024 in
  Buffer.add_string buf
    "struct Monitor {\n\
    \    state: State,\n\
    \    memory: Memory,\n\
     }\n\
     \n\
     impl Monitor {\n\
    \    fn new() -> Self {\n" ;
  Buffer.add_string buf
    (Printf.sprintf
       "        Self { state: State::%s, memory: Memory::new() }\n"
       (state_name start)) ;
  Buffer.add_string buf "    }\n\n" ;
  Buffer.add_string buf (gen_step_fn g) ;
  Buffer.add_string buf "\n" ;
  Buffer.add_string buf (gen_is_terminal g) ;
  Buffer.add_string buf "}\n" ;
  Buffer.contents buf

let gen_code (start, (g, _rec_var_info)) =
  let buf = Buffer.create 4096 in
  Buffer.add_string buf (gen_state_enum g) ;
  Buffer.add_string buf "\n" ;
  Buffer.add_string buf (gen_role_enum g) ;
  Buffer.add_string buf "\n" ;
  Buffer.add_string buf (gen_label_enum g) ;
  Buffer.add_string buf "\n" ;
  Buffer.add_string buf (gen_direction_enum ()) ;
  Buffer.add_string buf "\n" ;
  Buffer.add_string buf (gen_support_types ()) ;
  Buffer.add_string buf "\n" ;
  Buffer.add_string buf (gen_monitor start g) ;
  Buffer.contents buf
