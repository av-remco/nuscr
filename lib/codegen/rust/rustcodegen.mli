(** Generate Rust monitor code from EFSM *)

val gen_code : Efsm.state * Efsm.t -> string
