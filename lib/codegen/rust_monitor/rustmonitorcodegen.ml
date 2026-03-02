open! Base
open Names
open Efsm
open Message

let state_name st = Printf.sprintf "S%d" st

let capitalize_first s =
  if String.is_empty s then s
  else
    String.prefix s 1 |> String.capitalize |> fun first ->
    first ^ String.drop_prefix s 1

let _rust_role_name r = capitalize_first (RoleName.user r)

let snake_case s =
  String.to_array s
  |> Array.to_list
  |> List.concat_mapi ~f:(fun i c ->
         if Char.is_uppercase c then
           if i > 0 then ['_'; Char.lowercase c] else [Char.lowercase c]
         else [c] )
  |> String.of_char_list

let compare_triple (d1, r1, l1) (d2, r2, l2) =
  let c = String.compare d1 d2 in
  if c <> 0 then c
  else
    let c = String.compare r1 r2 in
    if c <> 0 then c else String.compare l1 l2

(* Collect all (direction, role_string, label_string) triples from a graph *)
let collect_triples g =
  let f (_, a, _) acc =
    match a with
    | SendA (r, m, _, _) ->
        ("Send", RoleName.user r, LabelName.user m.label) :: acc
    | RecvA (r, m, _, _) ->
        ("Recv", RoleName.user r, LabelName.user m.label) :: acc
    | Epsilon -> acc
  in
  G.fold_edges_e f g []
  |> List.dedup_and_sort ~compare:compare_triple

(* Collect triples from edges leaving a specific state *)
let collect_start_triples g start =
  let f (_, a, _) acc =
    match a with
    | SendA (r, m, _, _) ->
        ("Send", RoleName.user r, LabelName.user m.label) :: acc
    | RecvA (r, m, _, _) ->
        ("Recv", RoleName.user r, LabelName.user m.label) :: acc
    | Epsilon -> acc
  in
  G.fold_succ_e f g start []
  |> List.dedup_and_sort ~compare:compare_triple

(* Validate that no (direction, role, label) triple appears in multiple protocols *)
let validate_no_overlap protocols =
  let all_triples =
    List.concat_map protocols ~f:(fun (proto, (_, (g, _))) ->
        let triples = collect_triples g in
        List.map triples ~f:(fun triple -> (triple, proto)) )
  in
  (* Group by triple, check for multi-protocol membership *)
  let sorted =
    List.sort all_triples ~compare:(fun (t1, _) (t2, _) ->
        compare_triple t1 t2 )
  in
  let rec check = function
    | [] | [_] -> ()
    | (t1, p1) :: ((t2, p2) :: _ as rest) ->
        if compare_triple t1 t2 = 0
           && not (ProtocolName.equal p1 p2) then (
          let (dir, role, label) = t1 in
          Err.uerr
            (Err.Uncategorised
               (Printf.sprintf
                  "Ambiguous message routing: (%s, %s, %s) appears in \
                   multiple protocols"
                  dir role label ) ) )
        else check rest
  in
  check sorted

(* Generate per-protocol module *)
let gen_protocol_module proto_name start g =
  let mod_name = snake_case (ProtocolName.user proto_name) in
  let buf = Buffer.create 2048 in
  (* Module header *)
  Buffer.add_string buf (Printf.sprintf "mod %s {\n" mod_name) ;
  Buffer.add_string buf "    use super::*;\n\n" ;
  (* State enum *)
  Buffer.add_string buf
    "    #[derive(Debug, Clone, Copy, PartialEq, Eq)]\n" ;
  Buffer.add_string buf "    pub enum State {\n" ;
  G.iter_vertex
    (fun st ->
      Buffer.add_string buf
        (Printf.sprintf "        %s,\n" (state_name st)) )
    g ;
  Buffer.add_string buf "    }\n\n" ;
  (* Monitor struct *)
  Buffer.add_string buf "    #[derive(Debug)]\n" ;
  Buffer.add_string buf "    pub struct Monitor {\n" ;
  Buffer.add_string buf "        state: State,\n" ;
  Buffer.add_string buf "    }\n\n" ;
  Buffer.add_string buf "    impl Monitor {\n" ;
  (* new() *)
  Buffer.add_string buf "        pub fn new() -> Self {\n" ;
  Buffer.add_string buf
    (Printf.sprintf "            Self { state: State::%s }\n"
       (state_name start) ) ;
  Buffer.add_string buf "        }\n\n" ;
  (* step() *)
  Buffer.add_string buf
    "        pub fn step(&mut self, action: &Action) -> bool {\n" ;
  Buffer.add_string buf
    "            match (self.state, action.dir, action.role.as_str(), \
     action.label.as_str()) {\n" ;
  G.iter_edges_e
    (fun (src, a, dst) ->
      match a with
      | SendA (r, m, _, _) ->
          Buffer.add_string buf
            (Printf.sprintf
               "                (State::%s, Direction::Send, \"%s\", \"%s\") \
                => {\n\
               \                    self.state = State::%s;\n\
               \                    true\n\
               \                }\n"
               (state_name src) (RoleName.user r)
               (LabelName.user m.label)
               (state_name dst) )
      | RecvA (r, m, _, _) ->
          Buffer.add_string buf
            (Printf.sprintf
               "                (State::%s, Direction::Recv, \"%s\", \"%s\") \
                => {\n\
               \                    self.state = State::%s;\n\
               \                    true\n\
               \                }\n"
               (state_name src) (RoleName.user r)
               (LabelName.user m.label)
               (state_name dst) )
      | Epsilon -> () )
    g ;
  Buffer.add_string buf "                _ => false,\n" ;
  Buffer.add_string buf "            }\n" ;
  Buffer.add_string buf "        }\n\n" ;
  (* is_terminal() *)
  let terminals = Buffer.create 128 in
  let first = ref true in
  G.iter_vertex
    (fun st ->
      match state_action_type g st with
      | `Terminal ->
          if !first then (
            Buffer.add_string terminals
              (Printf.sprintf "State::%s" (state_name st)) ;
            first := false )
          else
            Buffer.add_string terminals
              (Printf.sprintf " | State::%s" (state_name st))
      | _ -> () )
    g ;
  let terminal_states = Buffer.contents terminals in
  Buffer.add_string buf "        pub fn is_terminal(&self) -> bool {\n" ;
  if String.is_empty terminal_states then
    Buffer.add_string buf "            false\n"
  else
    Buffer.add_string buf
      (Printf.sprintf "            matches!(self.state, %s)\n"
         terminal_states ) ;
  Buffer.add_string buf "        }\n\n" ;
  (* is_initiating() *)
  Buffer.add_string buf
    "        pub fn is_initiating(action: &Action) -> bool {\n" ;
  Buffer.add_string buf
    "            matches!((action.dir, action.role.as_str(), \
     action.label.as_str()),\n" ;
  let start_edges = G.succ_e g start in
  let first = ref true in
  List.iter start_edges ~f:(fun (_, a, _) ->
      match a with
      | SendA (r, m, _, _) ->
          if !first then first := false
          else Buffer.add_string buf "\n                | " ;
          Buffer.add_string buf
            (Printf.sprintf "                (Direction::Send, \"%s\", \"%s\")"
               (RoleName.user r)
               (LabelName.user m.label) )
      | RecvA (r, m, _, _) ->
          if !first then first := false
          else Buffer.add_string buf "\n                | " ;
          Buffer.add_string buf
            (Printf.sprintf "                (Direction::Recv, \"%s\", \"%s\")"
               (RoleName.user r)
               (LabelName.user m.label) )
      | Epsilon -> () ) ;
  Buffer.add_string buf "\n            )\n" ;
  Buffer.add_string buf "        }\n" ;
  (* Close impl and module *)
  Buffer.add_string buf "    }\n" ;
  Buffer.add_string buf "}\n" ;
  Buffer.contents buf

(* Generate shared types *)
let gen_shared_types () =
  "#[derive(Debug, Clone, Copy, PartialEq, Eq)]\n\
   pub enum Direction {\n\
  \    Send,\n\
  \    Recv,\n\
   }\n\
   \n\
   #[derive(Debug, Clone)]\n\
   pub struct Action {\n\
  \    pub dir: Direction,\n\
  \    pub role: String,\n\
  \    pub label: String,\n\
   }\n"

(* Generate ProtocolType enum *)
let gen_protocol_type_enum protocols =
  let buf = Buffer.create 256 in
  Buffer.add_string buf
    "#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]\n" ;
  Buffer.add_string buf "pub enum ProtocolType {\n" ;
  List.iter protocols ~f:(fun (proto, _) ->
      Buffer.add_string buf
        (Printf.sprintf "    %s,\n"
           (capitalize_first (ProtocolName.user proto)) ) ) ;
  Buffer.add_string buf "}\n" ;
  Buffer.contents buf

(* Generate route function *)
let gen_route_fn protocols =
  let buf = Buffer.create 512 in
  Buffer.add_string buf
    "fn route(dir: Direction, role: &str, label: &str) -> \
     Option<ProtocolType> {\n" ;
  Buffer.add_string buf "    match (dir, role, label) {\n" ;
  List.iter protocols ~f:(fun (proto, (_, (g, _))) ->
      let proto_variant = capitalize_first (ProtocolName.user proto) in
      let triples = collect_triples g in
      List.iter triples ~f:(fun (dir, role, label) ->
          Buffer.add_string buf
            (Printf.sprintf
               "        (Direction::%s, \"%s\", \"%s\") => \
                Some(ProtocolType::%s),\n"
               dir role label proto_variant ) ) ) ;
  Buffer.add_string buf "        _ => None,\n" ;
  Buffer.add_string buf "    }\n" ;
  Buffer.add_string buf "}\n" ;
  Buffer.contents buf

(* Generate initiating function *)
let gen_initiating_fn protocols =
  let buf = Buffer.create 512 in
  Buffer.add_string buf
    "fn initiating(dir: Direction, role: &str, label: &str) -> \
     Option<ProtocolType> {\n" ;
  Buffer.add_string buf "    match (dir, role, label) {\n" ;
  List.iter protocols ~f:(fun (proto, (start, (g, _))) ->
      let proto_variant = capitalize_first (ProtocolName.user proto) in
      let start_triples = collect_start_triples g start in
      List.iter start_triples ~f:(fun (dir, role, label) ->
          Buffer.add_string buf
            (Printf.sprintf
               "        (Direction::%s, \"%s\", \"%s\") => \
                Some(ProtocolType::%s),\n"
               dir role label proto_variant ) ) ) ;
  Buffer.add_string buf "        _ => None,\n" ;
  Buffer.add_string buf "    }\n" ;
  Buffer.add_string buf "}\n" ;
  Buffer.contents buf

(* Generate MonitorError enum *)
let gen_monitor_error () =
  "#[derive(Debug)]\n\
   pub enum MonitorError {\n\
  \    ConcurrentSameType(ProtocolType),\n\
  \    UncorrelatedMessage,\n\
  \    ProtocolViolation(ProtocolType),\n\
   }\n"

(* Generate MonitorInstance enum *)
let gen_monitor_instance protocols =
  let buf = Buffer.create 512 in
  Buffer.add_string buf "#[derive(Debug)]\n" ;
  Buffer.add_string buf "enum MonitorInstance {\n" ;
  List.iter protocols ~f:(fun (proto, _) ->
      let variant = capitalize_first (ProtocolName.user proto) in
      let mod_name = snake_case (ProtocolName.user proto) in
      Buffer.add_string buf
        (Printf.sprintf "    %s(%s::Monitor),\n" variant mod_name) ) ;
  Buffer.add_string buf "}\n\n" ;
  (* impl block *)
  Buffer.add_string buf "impl MonitorInstance {\n" ;
  (* new *)
  Buffer.add_string buf
    "    fn new(proto: ProtocolType) -> Self {\n\
    \        match proto {\n" ;
  List.iter protocols ~f:(fun (proto, _) ->
      let variant = capitalize_first (ProtocolName.user proto) in
      let mod_name = snake_case (ProtocolName.user proto) in
      Buffer.add_string buf
        (Printf.sprintf
           "            ProtocolType::%s => \
            MonitorInstance::%s(%s::Monitor::new()),\n"
           variant variant mod_name ) ) ;
  Buffer.add_string buf "        }\n    }\n\n" ;
  (* step *)
  Buffer.add_string buf
    "    fn step(&mut self, action: &Action) -> bool {\n\
    \        match self {\n" ;
  List.iter protocols ~f:(fun (proto, _) ->
      let variant = capitalize_first (ProtocolName.user proto) in
      Buffer.add_string buf
        (Printf.sprintf
           "            MonitorInstance::%s(m) => m.step(action),\n" variant ) ) ;
  Buffer.add_string buf "        }\n    }\n\n" ;
  (* is_terminal *)
  Buffer.add_string buf
    "    fn is_terminal(&self) -> bool {\n\
    \        match self {\n" ;
  List.iter protocols ~f:(fun (proto, _) ->
      let variant = capitalize_first (ProtocolName.user proto) in
      Buffer.add_string buf
        (Printf.sprintf
           "            MonitorInstance::%s(m) => m.is_terminal(),\n" variant ) ) ;
  Buffer.add_string buf "        }\n    }\n" ;
  Buffer.add_string buf "}\n" ;
  Buffer.contents buf

(* Generate Dispatcher struct *)
let gen_dispatcher () =
  "#[derive(Debug)]\n\
   pub struct Dispatcher {\n\
  \    monitors: HashMap<(u8, u8, ProtocolType), MonitorInstance>,\n\
   }\n\
   \n\
   impl Dispatcher {\n\
  \    pub fn new() -> Self {\n\
  \        Self { monitors: HashMap::new() }\n\
  \    }\n\
   \n\
  \    pub fn dispatch(\n\
  \        &mut self,\n\
  \        sys_id: u8,\n\
  \        comp_id: u8,\n\
  \        action: &Action,\n\
  \    ) -> Result<(), MonitorError> {\n\
  \        let proto = match route(action.dir, &action.role, &action.label) {\n\
  \            Some(p) => p,\n\
  \            None => return Err(MonitorError::UncorrelatedMessage),\n\
  \        };\n\
  \        let key = (sys_id, comp_id, proto);\n\
  \        if let Some(monitor) = self.monitors.get_mut(&key) {\n\
  \            if !monitor.step(action) {\n\
  \                if initiating(action.dir, &action.role, &action.label).is_some() {\n\
  \                    return Err(MonitorError::ConcurrentSameType(proto));\n\
  \                }\n\
  \                return Err(MonitorError::ProtocolViolation(proto));\n\
  \            }\n\
  \            if monitor.is_terminal() {\n\
  \                self.monitors.remove(&key);\n\
  \            }\n\
  \        } else {\n\
  \            if initiating(action.dir, &action.role, &action.label).is_none() {\n\
  \                return Err(MonitorError::UncorrelatedMessage);\n\
  \            }\n\
  \            let mut monitor = MonitorInstance::new(proto);\n\
  \            monitor.step(action);\n\
  \            if !monitor.is_terminal() {\n\
  \                self.monitors.insert(key, monitor);\n\
  \            }\n\
  \        }\n\
  \        Ok(())\n\
  \    }\n\
   }\n"

let gen_code protocols =
  validate_no_overlap protocols ;
  let buf = Buffer.create 8192 in
  Buffer.add_string buf "use std::collections::HashMap;\n\n" ;
  (* Shared types *)
  Buffer.add_string buf (gen_shared_types ()) ;
  Buffer.add_string buf "\n" ;
  Buffer.add_string buf (gen_protocol_type_enum protocols) ;
  Buffer.add_string buf "\n" ;
  (* Per-protocol modules *)
  List.iter protocols ~f:(fun (proto, (start, (g, _))) ->
      Buffer.add_string buf (gen_protocol_module proto start g) ;
      Buffer.add_string buf "\n" ) ;
  (* Route and initiating functions *)
  Buffer.add_string buf (gen_route_fn protocols) ;
  Buffer.add_string buf "\n" ;
  Buffer.add_string buf (gen_initiating_fn protocols) ;
  Buffer.add_string buf "\n" ;
  (* Dispatcher *)
  Buffer.add_string buf (gen_monitor_error ()) ;
  Buffer.add_string buf "\n" ;
  Buffer.add_string buf (gen_monitor_instance protocols) ;
  Buffer.add_string buf "\n" ;
  Buffer.add_string buf (gen_dispatcher ()) ;
  Buffer.contents buf
