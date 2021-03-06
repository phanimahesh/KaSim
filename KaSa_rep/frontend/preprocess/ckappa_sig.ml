(**
 * ckappa_sig.ml
 * openkappa
 * Jérôme Feret, projet Abstraction/Antique, INRIA Paris-Rocquencourt
 *
 * Creation: 01/17/2011
 * Last modification: Time-stamp: <Oct 03 2016>
 * *
 * Signature for prepreprocessing language ckappa
 *
 * Copyright 2010,2011,2012,2013,2014 Institut National de Recherche en Informatique et
 * en Automatique.  All rights reserved.  This file is distributed
 * under the terms of the GNU Library General Public License *)

module Int_Set_and_Map = Map_wrapper.Make(Mods.IntSetMap)

let local_trace = true

(****************************************************************************)

type position       = Location.t
type agent_name     = string
type site_name      = string
type internal_state = string

type c_agent_name = int
type c_agent_id   = int
type c_site_name  = int
type c_state      = int
type c_rule_id    = int

(****************************************************************************)

let dummy_agent_name = 0
let dummy_site_name = 0
let dummy_state_index = 0
let dummy_rule_id = 0
let dummy_agent_id = 0

let dummy_site_name_1 = 1
let dummy_site_name_minus1 = -1 (*REMOVE:Use in views_domain*)

let fst_site = 1
let snd_site = 2

let dummy_state_index_1 = 1

let string_of_agent_name (a: c_agent_name) : string = string_of_int a
let int_of_agent_name (a: c_agent_name) : int = a
let agent_name_of_int (a: int) : c_agent_name = a

let site_name_of_int (a: int) : c_site_name = a
let int_of_site_name (a : c_site_name) : int = a
let string_of_site_name (a: c_site_name) : string = string_of_int a

let state_index_of_int (a:int) : c_state = a
let int_of_state_index (a:c_state) : int = a
let string_of_state_index (a:c_state) : string = string_of_int a

let int_of_rule_id (a: c_rule_id) : int = a
let rule_id_of_int (a: int) : c_rule_id = a
let string_of_rule_id (a: c_rule_id) : string = string_of_int a

let int_of_agent_id (a: c_agent_id) : int = a
let agent_id_of_int (a: int) : c_agent_id = a
let string_of_agent_id (a: c_agent_id) : string = string_of_int a

let get_agent_shape n_sites parameters =
  Misc_sa.fetch_array
    (int_of_site_name n_sites)
    (Remanent_parameters.get_agent_shape_array parameters)
    (Remanent_parameters.get_agent_shape_def parameters)

let get_agent_color n_sites parameters =
  Misc_sa.fetch_array
    (int_of_site_name n_sites)
    (Remanent_parameters.get_agent_color_array parameters)
    (Remanent_parameters.get_agent_color_def parameters)

(***************************************************************************)

module Agent_type_nearly_Inf_Int_storage_Imperatif =
  (
    Int_storage.Nearly_inf_Imperatif: Int_storage.Storage
    with type key = c_agent_name
     and type dimension = int
  )

module Agent_type_quick_nearly_Inf_Int_storage_Imperatif =
  (
    Int_storage.Quick_key_list (Agent_type_nearly_Inf_Int_storage_Imperatif): Int_storage.Storage
    with type key = c_agent_name
     and type dimension = int
  )

module Rule_id_nearly_Inf_Int_storage_Imperatif =
  (
    Int_storage.Nearly_inf_Imperatif: Int_storage.Storage
    with type key = c_rule_id
     and type dimension = int
  )
module Rule_id_quick_nearly_Inf_Int_storage_Imperatif =
  (
    Int_storage.Quick_key_list (Rule_id_nearly_Inf_Int_storage_Imperatif): Int_storage.Storage
    with type key = c_rule_id
     and type dimension = int
  )

module Agent_type_site_nearly_Inf_Int_Int_storage_Imperatif_Imperatif =
  (
    Int_storage.Nearly_Inf_Int_Int_storage_Imperatif_Imperatif: Int_storage.Storage
    with type key = c_agent_name * c_site_name
     and type dimension = int * int
  )

module Agent_type_site_state_nearly_Inf_Int_Int_Int_storage_Imperatif_Imperatif_Imperatif =
  (
    Int_storage.Nearly_Inf_Int_Int_Int_storage_Imperatif_Imperatif_Imperatif : Int_storage.Storage
    with type key = (c_agent_name * (c_site_name * c_state))
     and type dimension = (int * (int * int))
  )

(*site*)
module Site_type_nearly_Inf_Int_storage_Imperatif =
  (
    Int_storage.Nearly_inf_Imperatif: Int_storage.Storage
    with type key = c_site_name
     and type dimension = int
  )

module Site_type_quick_nearly_Inf_Int_storage_Imperatif =
  (
    Int_storage.Quick_key_list (Site_type_nearly_Inf_Int_storage_Imperatif): Int_storage.Storage
    with type key = c_site_name
     and type dimension = int
  )

(*state*)
module State_index_nearly_Inf_Int_storage_Imperatif =
  (
    Int_storage.Nearly_inf_Imperatif: Int_storage.Storage
    with type key = c_state
     and type dimension = int
  )

module State_index_quick_nearly_Inf_Int_storage_Imperatif =
  (
    Int_storage.Quick_key_list (State_index_nearly_Inf_Int_storage_Imperatif): Int_storage.Storage
    with type key = c_state
     and type dimension = int
  )

(*rule_id*)
module Rule_nearly_Inf_Int_storage_Imperatif =
  (
    Int_storage.Nearly_inf_Imperatif: Int_storage.Storage
    with type key = c_rule_id
     and type dimension = int
  )

module Rule_quick_nearly_Inf_Int_storage_Imperatif =
  (
    Int_storage.Quick_key_list (Rule_nearly_Inf_Int_storage_Imperatif) : Int_storage.Storage
    with type key = c_rule_id
     and type dimension = int
  )

module Site_union_find =
  Union_find.Make(Site_type_nearly_Inf_Int_storage_Imperatif)

(****************************************************************************)
(*Define module fifo take rule_id*)

module Rule =
struct
  type t = c_rule_id
  let compare = compare
  let print = Format.pp_print_int
end

module Rule_FIFO = Fifo.WlMake (Rule)

(****************************************************************************)

module Agent_id_nearly_Inf_Int_storage_Imperatif =
  (
    Int_storage.Nearly_inf_Imperatif : Int_storage.Storage
    with type key = c_agent_id
     and type dimension = int
  )

module Agent_id_quick_nearly_Inf_Int_storage_Imperatif =
  (
    Int_storage.Quick_key_list (Agent_id_nearly_Inf_Int_storage_Imperatif) : Int_storage.Storage
    with type key = c_agent_id
     and type dimension = int
  )

(***************************************************************************)

module Agent_map_and_set =
  Map_wrapper.Make
    (SetMap.Make
       (struct
         type t = c_agent_name
         let compare = compare
         let print = Format.pp_print_int
       end
       ))

module Agent_id_map_and_set =
  Map_wrapper.Make
    (SetMap.Make
       (struct
         type t = c_agent_id
         let compare = compare
         let print = Format.pp_print_int
       end
       ))

module Rule_map_and_set =
  Map_wrapper.Make
    (SetMap.Make
       (struct
         type t = c_rule_id
         let compare = compare
         let print = Format.pp_print_int
       end))

module State_map_and_set =
  Map_wrapper.Make
    (SetMap.Make
       (struct
         type t = c_state
         let compare = compare
         let print = Format.pp_print_int
       end))

module AgentRule_map_and_set =
  Map_wrapper.Make
    (SetMap.Make
       (struct
         type t = c_agent_name * c_rule_id
         let compare = compare
         let print = Pp.pair Format.pp_print_int Format.pp_print_int
       end))

module RuleAgent_map_and_set =
  Map_wrapper.Make
    (SetMap.Make
       (struct
         type t = c_rule_id * c_agent_id
         let compare = compare
         let print = Pp.pair Format.pp_print_int Format.pp_print_int
       end))

(*use in site_accross_bonds_domain*)
module SiteState_map_and_set =
  Map_wrapper.Make
    (SetMap.Make
       (struct
         type t = c_site_name * c_state
         let compare = compare
         let print = Pp.pair Format.pp_print_int Format.pp_print_int
       end))


module AgentSiteState_map_and_set =
  Map_wrapper.Make
    (SetMap.Make
       (struct
         type t = c_agent_name * c_site_name * c_state
         let compare = compare
         let print f (a,b,c) = Format.fprintf f "(%i, %i, %i)" a b c
       end))

module Rule_setmap =
  SetMap.Make (
  struct
    type t = c_rule_id
    let compare = compare
    let print = Format.pp_print_int
  end)

module Agent_id_setmap =
  SetMap.Make (
  struct
    type t = c_agent_id
    let compare = compare
    let print = Format.pp_print_int
  end)

module PairRule_setmap =
  SetMap.Make
    (struct
      type t = c_rule_id * c_rule_id
      let compare = compare
      let print = Pp.pair Format.pp_print_int Format.pp_print_int
    end)

(****************************************************************************)

module Site_map_and_set =
  Map_wrapper.Make
    (SetMap.Make
       (struct
         type t      = c_site_name
         let compare = compare
         let print = Format.pp_print_int
       end))

module AgentSite_map_and_set =
  Map_wrapper.Make
    (SetMap.Make
       (struct
         type t = c_agent_name * c_site_name
         let compare = compare
         let print = Pp.pair Format.pp_print_int Format.pp_print_int
       end))

module Agents_map_and_set =
  Map_wrapper.Make
    (SetMap.Make
       (struct
         type t = c_agent_id * c_agent_name
         let compare = compare
         let print = Pp.pair Format.pp_print_int Format.pp_print_int
       end))

module AgentsSite_map_and_set =
  Map_wrapper.Make
    (SetMap.Make
       (struct
         type t = c_agent_id * c_agent_name * c_site_name
         let compare = compare
         let print f (a,b,c) = Format.fprintf f "(%i, %i, %i)" a b c
       end))

module AgentsSiteState_map_and_set =
  Map_wrapper.Make
    (SetMap.Make
       (struct
         type t = c_agent_id * c_agent_name * c_site_name * c_state
         let compare = compare
         let print f (a,b,c,d) = Format.fprintf f "(%i, %i, %i, %i)" a b c d
       end))
(***************************************************************************)
(*bonds in rhs and lhs*)

module PairAgentsSiteState_map_and_set =
  Map_wrapper.Make
    (SetMap.Make
       (struct
         type t = (c_agent_id * c_agent_name * c_site_name * c_state) *
                  (c_agent_id * c_agent_name * c_site_name * c_state)
         let compare = compare
         let print _ _ = ()
       end))

module PairAgentSiteState_map_and_set =
  Map_wrapper.Make
    (SetMap.Make
       (struct
         type t = (c_agent_name * c_site_name * c_state) *
                  (c_agent_name * c_site_name * c_state)
         let compare = compare
         let print _ _ = ()
       end))

(*******************************************************************)

module Views_bdu =
  (Mvbdu_wrapper.Mvbdu: Mvbdu_wrapper.Mvbdu with type key = c_site_name and type value = c_state with type mvbdu = Mvbdu_wrapper.Mvbdu.mvbdu)

module Views_intbdu = Mvbdu_wrapper.Internalize (Views_bdu)

(***************************************************************)

type binding_state =
  | Free
  | Lnk_type of agent_name * site_name

type mixture =
  | SKIP  of mixture
  | COMMA of agent * mixture
  | DOT   of c_agent_id * agent * mixture
  | PLUS  of c_agent_id * agent * mixture
  | EMPTY_MIX

and agent =
  {
    ag_nme     : string;
    ag_intf    : interface;
    ag_nme_pos : position (*; ag_pos:position*)
  }

and interface =
  | EMPTY_INTF
  | PORT_SEP of port * interface

and port =
  {
    port_nme  : string;
    port_int  : internal;
    port_lnk  : link;
    (*port_pos: position ;*)
    port_free : bool option
  }

and internal = string list

and link =
  | LNK_VALUE of (c_agent_id * agent_name * site_name * c_agent_id * position)
  | FREE
  | LNK_ANY   of position
  | LNK_SOME  of position
  | LNK_TYPE  of (string Location.annot * string Location.annot)

type 'mixture rule =
  {
    prefix: int;
    delta: int;
    lhs   : 'mixture;
    arrow : Ast.arrow;
    rhs   : 'mixture;
    k_def : ('mixture,string) Alg_expr.e Location.annot;
    k_un  : ('mixture,string) Alg_expr.e Location.annot option
  }

type 'mixture perturbation = ('mixture,string) Ast.perturbation

type 'mixture modif_expr   = ('mixture,string) Ast.modif_expr

type 'mixture variable     = ('mixture,string) Ast.variable_def

type direction = Direct | Reverse

type ('agent,'mixture,'rule) compil =
  ('agent, 'mixture, string, 'rule) Ast.compil

type ('a, 'b) site_type =
  | Internal of 'a
  | Binding  of 'b

type site = (site_name, site_name) site_type

type state = (internal_state, binding_state) site_type

(*move from c*)
type c_binding_state =
  | C_Free
  | C_Lnk_type of c_agent_name * c_site_name

type state' = (internal_state, c_binding_state) site_type

module State =
struct
  type t = state'
  let compare = compare
  let print _ _ = ()
end

module Dictionary_of_States =
  (
    Dictionary.Dictionary_of_Ord (State) : Dictionary.Dictionary
    with type key = c_state
     and type value = state'
  )

(**)

type internal_state_specification =
  {
    string : internal_state;
  }

module Site =
struct
  type t = site
  let compare = compare
  let print _ _ = ()
end

module Kasim_agent_name =
struct
  type t = agent_name
  let compare = compare
  let print = Format.pp_print_string
end

module Dictionary_of_agents =
  (
    Dictionary.Dictionary_of_Ord (Kasim_agent_name): Dictionary.Dictionary
    with type key = c_agent_name
     and type value = agent_name
  )

module Dictionary_of_sites =
  (
    Dictionary.Dictionary_of_Ord (Site): Dictionary.Dictionary
    with type key = c_site_name
     and type value = site
  )

type site_list =
  {
    used     : (site_name list * position) list;
    declared : (site_name list * position) list;
    creation : (site_name list * position) list
  }

type agent_dic = (unit,unit) Dictionary_of_agents.dictionary
type site_dic  = (unit,unit) Dictionary_of_sites.dictionary
type state_dic = (unit,unit) Dictionary_of_States.dictionary

type agent_specification =
  {
    binding_sites_usage : site_list;
    marked_sites_usage  : site_list
  }

type kappa_handler =
  {
    agents_dic            : agent_dic;
    interface_constraints : agent_specification Int_storage.Nearly_inf_Imperatif.t;
    sites                 : site_dic Int_storage.Nearly_inf_Imperatif.t;
    states_dic            : state_dic Int_storage.Nearly_inf_Imperatif.t
        Int_storage.Nearly_inf_Imperatif.t
  }

type 'a interval  = {min:'a; max:'a}

type c_port =
  {
    c_site_name     : c_site_name;
    c_site_position : position;
    c_site_interval : c_state interval
  }

type c_interface = c_port Site_map_and_set.Map.t

type c_proper_agent =
  {
    c_agent_kasim_id  : c_agent_id;
    c_agent_name      : c_agent_name;
    c_agent_interface : c_interface;
    c_agent_position  : position
  }

type site_address =
  {
    agent_index : c_agent_id;
    site        : c_site_name
  }

type c_bond = site_address * site_address

type c_agent =
  | C_ghost
  | C_agent of c_proper_agent

type c_mixture =
  {
    c_views : c_agent Int_storage.Quick_Nearly_inf_Imperatif.t;
    c_bonds :
      site_address Site_map_and_set.Map.t Int_storage.Nearly_inf_Imperatif.t;
    c_plus  : (int * int) list;
    c_dot   : (int * int) list
  }

type c_variable = (c_mixture,string) Alg_expr.e

type action =
  | Release    of c_bond
  | Bind       of c_bond
  | Half_breaf of site_address

type c_rule =
  {
    c_rule_lhs     : c_mixture;
    c_rule_arrow   : Ast.arrow;
    c_rule_rhs     : c_mixture;
    c_diff_direct  : c_mixture;
    c_diff_reverse : c_mixture;
    c_side_effects : action list
  }

type c_perturbation =
  ((((c_mixture,string) Alg_expr.bool_expr) * position)
   * (c_modif_expr list)
   * ((c_mixture,string) Alg_expr.bool_expr * position) option)
  * position

and c_modif_expr =
  | C_INTRO    of ((c_mixture,string) Alg_expr.e * c_mixture * position)
  | C_DELETE   of ((c_mixture,string) Alg_expr.e * c_mixture * position)
  | C_UPDATE   of
      (string * (c_mixture,string) Alg_expr.e * position) (*TODO: pause*)
  | C_STOP     of position
  | C_SNAPSHOT of position (*maybe later of mixture too*)

type enriched_rule =
  {
    e_rule_label  : (string * position) option;
    e_rule_direct : bool;
    e_rule_rule   : c_mixture rule;
    e_rule_c_rule : c_rule
  }

type enriched_init =
  {
    e_init_factor    : int;
    e_init_mixture   : mixture;
    e_init_c_mixture : c_mixture;
    e_init_pos       : position
  }

type c_compil =
  {
    c_variables : c_variable Int_storage.Nearly_inf_Imperatif.t;
    (*pattern declaration for reusing as variable in perturbations or kinetic rate*)
    c_signatures : (agent * position) Int_storage.Nearly_inf_Imperatif.t;
    (*agent signature declaration*)
    c_rules : enriched_rule Int_storage.Nearly_inf_Imperatif.t;
    (*rules (possibly named)*)
    c_observables : (c_mixture,string) Alg_expr.e Int_storage.Nearly_inf_Imperatif.t;
    (*list of patterns to plot*)
    c_init : enriched_init Int_storage.Nearly_inf_Imperatif.t  ;
    (*initial graph declaration*)
    c_perturbations :
      c_mixture Location.annot perturbation Int_storage.Nearly_inf_Imperatif.t
  }

let lift to_int from_int p =
  fun a i -> from_int (p (to_int a) i)
let pred_site_name = pred
let pred_agent_name = pred
let pred_state_index = pred
let gen_rule_id = lift int_of_rule_id rule_id_of_int
let sub_rule_id = gen_rule_id (fun a b -> a - b)
let add_rule_id = gen_rule_id (fun a b -> a + b)
let add_agent_id = lift int_of_agent_id agent_id_of_int (fun a b -> a + b)
let next_rule_id = succ
let next_agent_id = succ
let next_agent_name = succ
let next_site_name = succ
let next_state_index = succ
let compare_rule_id = compare
let compare_agent_id = compare
let compare_site_name = compare
let compare_state_index = compare
let compare_agent_name = compare

let compare_unit _ _ = 0
let compare_unit_agent_name _ _ = dummy_agent_name
let compare_unit_site_name _ _ = dummy_site_name
let compare_unit_state_index _ _ = dummy_state_index

let array_of_list_rule_id create set parameters error list =
  let n = List.length list in
  let a = create parameters error n in
  let rec aux l k a =
    match l with
    | [] -> a
    | t::q ->
      begin
        aux q
          (next_rule_id k)
          (set parameters (fst a) k t (snd a))
      end
  in aux list dummy_rule_id a
