(*
  * views_domain.mli
  * openkappa
  * Jérôme Feret & Ly Kim Quyen, projet Abstraction, INRIA Paris-Rocquencourt
  *
  * Creation: 2016, the 30th of January
  * Last modification: Time-stamp: <Oct 14 2016>
  *
  * A monolitich domain to deal with all concepts in reachability analysis
  * This module is temporary and will be split according to different concepts
  * thanks to the functor Product
  *
  * Copyright 2010,2011,2012,2013,2014,2015,2016 Institut National de Recherche
  * en Informatique et en Automatique.
  * All rights reserved.  This file is distributed
  * under the terms of the GNU Library General Public License *)

(** Abstract domain to over-approximate the set of reachable views *)

let local_trace = false

module Domain =
struct

  (* the type of the struct that contains all static information as in the
     previous version of the analysis *)

  (*************************************************************************)
  (* Domain specific information:
     Collect the set of tuples (A,x,y,B,z,t) such that there exists a rule
     with two agents of type A and B and two bonds between A.x and B.z, and A.y
     and B.t.
     - For each tuple, collect a map -> (A,x,y,B,z,t) -> (Ag_id,Ag_id) list
     RuleIdMap to explain which rules can create a bond of type A.x.z.B
     (and at which position (its internal state ~u~p, ...).
     - A map -> (A,x,y,B,z,t) -> (Ag_id,Ag_id) list RuleIdMap to explain
     which rules can create a bond of type A.y.t.B (and at which position
     - And a map (A,x,y,B,z,t) -> (Ag_id,Ag_id) list RuleIdMap to explain
     which rules can contain parallel bonds in their lhs *)
  (*************************************************************************)

  type static_information =
    {
      global_static_information : Analyzer_headers.global_static_information;
      local_static_information  : Parallel_bonds_static.local_static_information
    }

  (*--------------------------------------------------------------*)
  (* One map: for each tuple: Yes, No, Maybe.
    - Yes: to say that when the sites x and y are bound with sites of
     the good type, then they are bound to the same B.
    - No: to say that when the sites x and y are bound with sites of the good
     type, then they are never bound to the same B.
    - Maybe: both cases may happen.*)

  type local_dynamic_information =
    {
      dummy: unit;
      store_value:
         bool Usual_domains.flat_lattice
          Parallel_bonds_type.PairAgentSitesStates_map_and_set.Map.t
    }

  type dynamic_information =
    {
      local  : local_dynamic_information ;
      global : Analyzer_headers.global_dynamic_information;
    }

  (** Static information:
      Explain how to extract the handler for kappa expressions from a value
      of type static_information. Kappa handler is static and thus it should
      never updated. *)

  (*global static information*)

  let get_global_static_information static = static.global_static_information

  let lift f x = f (get_global_static_information x)

  let get_parameter static = lift Analyzer_headers.get_parameter static

  let get_kappa_handler static = lift Analyzer_headers.get_kappa_handler static

  let get_compil static = lift Analyzer_headers.get_cc_code static

  let get_views_rhs static = lift Analyzer_headers.get_views_rhs static

  let get_action_binding static =
    lift Analyzer_headers.get_action_binding static

  let get_project_modified_map static =
    lift Analyzer_headers.get_project_modified_map static

  let get_local_static_information static = static.local_static_information

  let set_local_static_information local static =
    {
      static with
      local_static_information = local
    }

  let get_rule parameter error static r_id =
    let compil = get_compil static in
    let error, rule  =
      Ckappa_sig.Rule_nearly_Inf_Int_storage_Imperatif.get
        parameter
        error
        r_id
        compil.Cckappa_sig.rules
    in
    error, rule

  (*static information*)

  let get_tuples_of_interest static =
    (get_local_static_information
       static).Parallel_bonds_static.store_tuples_of_interest

  let set_tuples_of_interest bonds static =
    set_local_static_information
      {
        (get_local_static_information static) with
        Parallel_bonds_static.store_tuples_of_interest = bonds
      }
      static

  let get_rule_double_bonds_rhs static =
    (get_local_static_information
       static).Parallel_bonds_static.store_rule_double_bonds_rhs

  let set_rule_double_bonds_rhs bonds static =
    set_local_static_information
      {
        (get_local_static_information static) with
        Parallel_bonds_static.store_rule_double_bonds_rhs = bonds
      }
      static

  let get_fst_site_create_parallel_bonds_rhs static =
    (get_local_static_information
       static).Parallel_bonds_static.store_fst_site_create_parallel_bonds_rhs

  let set_fst_site_create_parallel_bonds_rhs l static =
    set_local_static_information
      {
        (get_local_static_information static) with
        Parallel_bonds_static.store_fst_site_create_parallel_bonds_rhs = l
      }
      static

  let get_snd_site_create_parallel_bonds_rhs static =
    (get_local_static_information
       static).Parallel_bonds_static.store_snd_site_create_parallel_bonds_rhs

  let set_snd_site_create_parallel_bonds_rhs l static =
    set_local_static_information
      {
        (get_local_static_information static) with
        Parallel_bonds_static.store_snd_site_create_parallel_bonds_rhs = l
      }
      static

  let get_rule_double_bonds_lhs static =
    (get_local_static_information
       static).Parallel_bonds_static.store_rule_double_bonds_lhs

  let set_rule_double_bonds_lhs bonds static =
    set_local_static_information
      {
        (get_local_static_information static) with
        Parallel_bonds_static.store_rule_double_bonds_lhs = bonds
      }
      static

  (*map tuple to sites*)

  let get_tuple_to_sites static =
    (get_local_static_information
       static).Parallel_bonds_static.store_tuple_to_sites

  let set_tuple_to_sites tuple static =
    set_local_static_information
      {
        (get_local_static_information static) with
        Parallel_bonds_static.store_tuple_to_sites = tuple
      }
      static

  let get_sites_to_tuple static =
    (get_local_static_information
       static).Parallel_bonds_static.store_sites_to_tuple

  let set_sites_to_tuple sites static =
    set_local_static_information
      {
        (get_local_static_information static) with
        Parallel_bonds_static.store_sites_to_tuple = sites
      }
      static

  (*global dynamic information*)

  let get_global_dynamic_information dynamic = dynamic.global

  let get_local_dynamic_information dynamic = dynamic.local

  let set_local_dynamic_information local dynamic =
    {
      dynamic with local = local
    }

  let set_global_dynamic_information global dynamic =
    {
      dynamic with global = global
    }

(*dynamic information*)

  let get_value dynamic =
    (get_local_dynamic_information dynamic).store_value

  let set_value value dynamic =
    set_local_dynamic_information
      {
        (get_local_dynamic_information dynamic) with
        store_value = value
      } dynamic

  (*--------------------------------------------------------------*)

  type 'a zeroary =
    static_information
    -> dynamic_information
    -> Exception.method_handler
    -> Exception.method_handler * dynamic_information * 'a

  type ('a, 'b) unary =
    static_information
    -> dynamic_information
    -> Exception.method_handler
    -> 'a
    -> Exception.method_handler * dynamic_information * 'b

  type ('a, 'b, 'c) binary =
    static_information
    -> dynamic_information
    -> Exception.method_handler
    -> 'a
    -> 'b
    -> Exception.method_handler * dynamic_information * 'c

  (****************************************************************)
  (*rule*)
  (*****************************************************************)

  let scan_rule static _dynamic error rule_id rule =
    let parameters = get_parameter static in
    (*------------------------------------------------------*)
    (*a set of rules that has a potential double binding or potential non double binding on the lhs*)
    let store_result = get_rule_double_bonds_lhs static in
    let error, store_result =
      Parallel_bonds_static.collect_rule_double_bonds_lhs
        parameters error rule_id rule store_result
    in
    let static = set_rule_double_bonds_lhs store_result static in
    (*------------------------------------------------------*)
    (*a set of rules that has a potential double bindings on the rhs*)
    let store_result = get_rule_double_bonds_rhs static in
    let error, store_result =
      Parallel_bonds_static.collect_rule_double_bonds_rhs
        parameters error rule_id rule store_result
    in
    let static = set_rule_double_bonds_rhs store_result static in
    error, static

(****************************************************************)
(*rules*)
(****************************************************************)

  let scan_rules static dynamic error =
    let parameters = get_parameter static in
    let compil = get_compil static in
    let error, static =
      Ckappa_sig.Rule_nearly_Inf_Int_storage_Imperatif.fold
        parameters
        error
        (fun _ error rule_id rule static ->
           scan_rule
             static dynamic error rule_id rule.Cckappa_sig.e_rule_c_rule
        ) compil.Cckappa_sig.rules static
    in
    (*------------------------------------------------------*)
    (*A(x!1, y), B(x!1, y): first site is an action binding*)
    (*------------------------------------------------------*)
    let lift_map error s =
      Ckappa_sig.Rule_map_and_set.Map.fold
        (fun _ big_store (error, set) ->
           Parallel_bonds_static.project_away_ag_id_and_convert_into_set
             parameters error big_store set)
        s
        (error, Parallel_bonds_type.PairAgentSitesStates_map_and_set.Set.empty)
    in
    let error, store_result1 =
      lift_map error (get_rule_double_bonds_lhs static) in
    let error, store_result2 =
      lift_map error (get_rule_double_bonds_rhs static) in
    let error, store_result =
      Parallel_bonds_type.PairAgentSitesStates_map_and_set.Set.union
        parameters error store_result1 store_result2
    in
    let static =
      set_tuples_of_interest store_result static
    in
    (*------------------------------------------------------*)
    let tuple_of_interest = store_result in
    let store_action_binding = get_action_binding static in
    let error, store_result =
      Parallel_bonds_static.collect_fst_site_create_parallel_bonds_rhs
        parameters error store_action_binding tuple_of_interest
    in
    let static = set_fst_site_create_parallel_bonds_rhs store_result static in
    (*------------------------------------------------------*)
    (*A(x, y!1), B(x, y!1): second site is an action binding *)
    let error, store_result =
      Parallel_bonds_static.collect_snd_site_create_parallel_bonds_rhs
        parameters error store_action_binding tuple_of_interest
    in
    let static = set_snd_site_create_parallel_bonds_rhs store_result static in
    (*------------------------------------------------------*)
    (*map tuples to sites*)
    let tuple_of_interest = get_tuples_of_interest static in
    let error, store_result =
      Parallel_bonds_static.collect_tuple_to_sites
        parameters error
        tuple_of_interest
    in
    let static = set_tuple_to_sites store_result static in
    (*------------------------------------------------------*)
    (*map sites to tuple*)
    let tuple_to_sites = get_tuple_to_sites static in
    let store_sites_to_tuple = get_sites_to_tuple static in
    let error, store_result =
      Parallel_bonds_static.collect_sites_to_tuple
        parameters error
        tuple_to_sites
        store_sites_to_tuple
    in
    let static = set_sites_to_tuple store_result static in
    error, static, dynamic

  (***************************************************************)

  let initialize static dynamic error =
    let init_global_static_information =
      {
        global_static_information = static;
        local_static_information = Parallel_bonds_static.init_local_static;
      }
    in
    let init_local_dynamic_information =
      {
        dummy = ();
        store_value =
          Parallel_bonds_type.PairAgentSitesStates_map_and_set.Map.empty
      }
    in
    let init_global_dynamic_information =
      {
        global = dynamic;
        local = init_local_dynamic_information ;
      }
    in
    let error, static, dynamic =
      scan_rules
        init_global_static_information
        init_global_dynamic_information error
    in
    error, static, dynamic

  (***************************************************************)
  (*a map of parallel bonds in the initial states, if the set
    is empty then returns false, if it has parallel bonds, returns
    true.*)

  let compute_value_init static dynamic error init_state =
    let parameters = get_parameter static in
    let tuples_of_interest =
      get_tuples_of_interest static
    in
    let kappa_handler = get_kappa_handler static in
    (*value of parallel and non parallel bonds*)
    let store_result = get_value dynamic in
    let error, store_result =
      Parallel_bonds_init.collect_parallel_or_not_bonds_init
        parameters kappa_handler error
        tuples_of_interest init_state store_result
    in
    let dynamic = set_value store_result dynamic in
    error, dynamic

  (*************************************************************)

  let add_initial_state static dynamic error species =
    let event_list = [] in
    (*parallel bonds in the initial states*)
    let error, dynamic =
      compute_value_init static dynamic error species
    in
    error, dynamic, event_list

  (*************************************************************)
  (* if a parallel bound occurs on the lhs, check that this is possible *)

  let is_enabled static dynamic error (rule_id:Ckappa_sig.c_rule_id) precondition =
    let parameters = get_parameter static in
    (*-----------------------------------------------------------*)
    (*look into the lhs, whether or not there exists a double bound.*)
    let store_rule_has_parallel_bonds_lhs = get_rule_double_bonds_lhs static in
    let error, parallel_map =
      match Ckappa_sig.Rule_map_and_set.Map.find_option_without_logs
              parameters error rule_id store_rule_has_parallel_bonds_lhs
      with
      | error, None ->
        error,
        Parallel_bonds_type.PairAgentsSitesStates_map_and_set.Map.empty
      | error, Some s -> error, s
    in
    let list =
      Parallel_bonds_type.PairAgentsSitesStates_map_and_set.Map.bindings parallel_map
    in
    (*-----------------------------------------------------------*)
    let store_value = get_value dynamic in
    let error, bool =
      begin
        let rec scan list error =
          match
            list
          with
          | [] -> error, true
          | (tuple, parallel_or_not) :: tail ->
            let pair = Parallel_bonds_type.project2 tuple in
            let error, value =
              match
                Parallel_bonds_type.PairAgentSitesStates_map_and_set.Map.find_option_without_logs
                  parameters error
                  pair
                  store_value
              with
              (*if we do not find the pair on the lhs inside the result, then return undefined, if there is a double bound then returns its value.*)
              | error, None -> error, Usual_domains.Undefined
              | error, Some v -> error, v
            in
            (*matching the value on the lhs*)
            match value with
            | Usual_domains.Undefined
            | Usual_domains.Val false -> error, false
            (*if the value in the result is different than the value on the lhs, then returns false*)
            | Usual_domains.Val b when b <> parallel_or_not -> error, false
            (*otherwise continue until the rest of the list*)
            | Usual_domains.Val _
            |  Usual_domains.Any -> scan tail error
        in
        scan list error
      end
    in
    if bool
    then error, dynamic, Some precondition
    else error, dynamic, None

  (***************************************************************)
  (* when one bond is created, check in the precondition, whether the two
     other sites may be bound, check whether they must be bound to the same
     agents, whether they cannot be bound to the same agent, whether we cannot
     know, and deal with accordingly *)

  (***********************************************************)
  (* we know from the syntax that a created bond necessarily belongs to
     a pair of parallel bonds or a pair of non-parallel bonds *)

  let necessarily_double idx idy (x, y) map =
    Parallel_bonds_type.PairAgentsSitesStates_map_and_set.Map.mem
      (idx, (x, y))
      map ||
    Parallel_bonds_type.PairAgentsSitesStates_map_and_set.Map.mem
      (idy, (y, x))
      map

  type pos = Fst | Snd

  let apply_gen pos parameters error static dynamic precondition rule_id rule =
    let store_site_create_parallel_bonds_rhs =
      match pos with
      | Fst -> get_fst_site_create_parallel_bonds_rhs static
      | Snd -> get_snd_site_create_parallel_bonds_rhs static
    in
    let error, store_pair_bind_map =
      match
        Ckappa_sig.Rule_map_and_set.Map.find_option_without_logs
          parameters error
          rule_id
          store_site_create_parallel_bonds_rhs
      with
      | error, None ->
        error,
        Parallel_bonds_type.PairAgentsSiteState_map_and_set.Map.empty
      | error, Some m -> error, m
    in
    let store_rule_double_bonds_rhs = get_rule_double_bonds_rhs static in
    (*from rule_id get a map of tuples that created a paralllel bonds on the
      rhs*)
    let error, rule_double_bonds_rhs_map =
      match
        Ckappa_sig.Rule_map_and_set.Map.find_option_without_logs
          parameters error
          rule_id
          store_rule_double_bonds_rhs
      with
      | error, None ->
        error, Parallel_bonds_type.PairAgentsSitesStates_map_and_set.Map.empty
      | error, Some map -> error, map
    in
    (*-----------------------------------------------------------*)
    Parallel_bonds_type.PairAgentsSiteState_map_and_set.Map.fold
      (fun (_, _) parallel_list (error, dynamic, precondition, store_result) ->
         let error, dynamic, precondition, store_result =
           List.fold_left
             (fun
               (error, dynamic, precondition, store_result) (z, t) ->
               let (agent_id1, agent_type1, site_type1, site_type2, state1,
                    state2) = z
               in
               let (agent_id1', agent_type1', site_type1', site_type2',
                    state1', state2') = t
               in
               let z' = Parallel_bonds_type.project z in
               let t' = Parallel_bonds_type.project t in
               let other_site, other_site' =
                 match pos with
                 | Fst -> site_type2, site_type2'
                 | Snd -> site_type1, site_type1'
               in
               if
                 necessarily_double
                   agent_id1
                   agent_id1'
                   (z', t')
                   rule_double_bonds_rhs_map (**)
               then
                 (error, dynamic, precondition, store_result)
               else
                 (*check the agent_type, and site_type1*)
                 let error, old_value =
                   match
                     Parallel_bonds_type.PairAgentsSitesStates_map_and_set.Map.find_option_without_logs
                       parameters error
                       (agent_id1, (z', t'))
                       store_result
                   with
                   | error, None ->
                     error, Usual_domains.Undefined
                   | error, Some value -> error, value
                 in
                 (*------------------------------------------------------*)
                 (*get a list of potential states of the second site*)
                 let error, dynamic, precondition, state_list =
                   Communication.get_state_of_site_in_postcondition
                     get_global_static_information
                     get_global_dynamic_information
                     set_global_dynamic_information
                     error static dynamic
                     (rule_id, rule)
                     agent_id1 (*A*)
                     other_site
                     precondition
                 in
                 let error, dynamic, precondition, state_list' =
                   Communication.get_state_of_site_in_postcondition
                     get_global_static_information
                     get_global_dynamic_information
                     set_global_dynamic_information
                     error static dynamic
                     (rule_id,rule)
                     agent_id1' (*B*)
                     other_site'
                     precondition
                 in
                 let error, dynamic, precondition, store_result =
                   match state_list, state_list' with
                   | _::_::_, _::_::_ ->
                     (*we know for sure that none of the two sites have been
                       modified*)
                     error, dynamic, precondition, store_result
                   | [], _ | _, [] ->
                     let error, () =
                       Exception.warn parameters error __POS__
                         ~message: "empty list in potential states in post condition" Exit ()
                     in
                     error, dynamic, precondition, store_result
                   | [_], _ | _, [_] -> (*general case*)
                     let error, potential_list =
                       List.fold_left
                         (fun (error, current_list) pre_state ->
                            List.fold_left
                              (fun (error, current_list) pre_state' ->
                                 let state1, state2, state1', state2' =
                                   match pos with
                                   | Fst ->
                                     state1, pre_state, state1', pre_state'
                                   | Snd ->
                                     pre_state, state2, pre_state', state2'
                                 in
                                 let potential_list =
                                   ((agent_id1, agent_type1, site_type1,
                                     site_type2, state1, state2),
                                    (agent_id1', agent_type1', site_type1',
                                     site_type2', state1', state2'))
                                   :: current_list
                                 in
                                 error, potential_list
                              ) (error, current_list) state_list'
                         ) (error, []) state_list
                     in
                     (*------------------------------------------------------*)
                     (*fold over a potential list and compare with parallel
                       list*)
                     let error, value =
                       List.fold_left (fun (error, value) (x', y') ->
                           let site_other, pre_state_other, site_other',
                               pre_state_other' =
                             match pos with
                             | Fst ->
                               let (_, _, _, s_type2, _, pre_state2) = x' in
                               let (_, _, _, s_type2', _, pre_state2') = y' in
                               s_type2, pre_state2, s_type2', pre_state2'
                             | Snd ->
                               let (_, _, s_type1, _, pre_state1, _) = x' in
                               let (_, _, s_type1', _, pre_state1', _) = y' in
                               s_type1, pre_state1, s_type1', pre_state1'
                           in
                           (*check if the pre_state2 and pre_state2' of the
                             other sites are bound and if yes which the good
                             state?  -
                             Firstly check that if the parallel bonds depend on
                             the state of the second site, it will give a
                             different value: whether Undefined or Any,
                             (question 1 and 2)*)
                           begin
                             (*question 1: if the pre_state2/pre_state2' of A
                               or B is free -> undefined*)
                             if
                               Ckappa_sig.int_of_state_index pre_state_other = 0
                             then
                               (*answer of question 1: the second site is free*)
                               let new_value =
                                 Usual_domains.lub value
                                   Usual_domains.Undefined
                               in
                               error, new_value
                             else
                               (* the pre_state2 is bound or pre_state2' is
                                  bound. Question
                                  2: both sites are bound with the good sites,
                                  then return Any, if not return false*)
                               begin
                                 if site_other = site_other' &&
                                    pre_state_other = pre_state_other' &&
                                    not (Ckappa_sig.int_of_state_index
                                           pre_state_other' = 0)
                                 then
                               (*both question1 and 2 are yes: return any*)
                                   let new_value =
                                     Usual_domains.lub value
                                       Usual_domains.Any
                                   in
                                   error, new_value
                                 else
                               (*the question1 is true but the question 2 is false -> false*)
                                   let new_value =
                                     Usual_domains.lub value
                                       (Usual_domains.Val false)
                                   in
                                   error, new_value
                               end
                           end
                         ) (error, old_value) potential_list
                     in
                     (*------------------------------------------------------*)
                     (*call the symmetric add *)
                     let error, store_result =
                       Parallel_bonds_type.add_symmetric_tuple_pair
                         (fun parameters error t map ->
                            Parallel_bonds_type.PairAgentsSitesStates_map_and_set.Map.add_or_overwrite
                              parameters error
                              t
                              value
                              map)
                         parameters
                         error
                         (z, t)
                         store_result
                     in
                     error, dynamic, precondition, store_result
                 in
                 error, dynamic, precondition, store_result
             ) (error, dynamic, precondition, store_result) parallel_list
         in
         error, dynamic, precondition, store_result
      ) store_pair_bind_map
      (error, dynamic, precondition,
       Parallel_bonds_type.PairAgentsSitesStates_map_and_set.Map.empty)

  let discover_a_new_pair_of_modify_sites store_set event_list =
  let event_list =
    Parallel_bonds_type.PairAgentSite_map_and_set.Set.fold
      (fun (x, y, z, t) event_list ->
         (Communication.Modified_sites x) ::
         (Communication.Modified_sites y) ::
         (Communication.Modified_sites z) ::
         (Communication.Modified_sites t) :: event_list
      ) store_set event_list
  in
  event_list

(*if it is not the first time it is apply then do not apply *)

  let can_we_prove_this_is_not_the_first_application precondition =
    match
      Communication.is_the_rule_applied_for_the_first_time precondition
    with
    | Usual_domains.Sure_value b ->
      if b
      then true
      else false
    | Usual_domains.Maybe -> false

  let apply_rule static dynamic error rule_id precondition =
    (*--------------------------------------------------------------*)
    let parameters = get_parameter static in
    let event_list = [] in
    (*-----------------------------------------------------------*)
    let kappa_handler = get_kappa_handler static in
    let error, rule = get_rule parameters error static rule_id in
    match rule with
    | None ->
      let error, () =
        Exception.warn parameters error __POS__ Exit ()
      in
      error, dynamic, (precondition, event_list)
    | Some rule ->
      let parameters =
        Remanent_parameters.update_prefix parameters "                "
      in
      let dump_title () =
        if local_trace ||
           Remanent_parameters.get_dump_reachability_analysis_diff parameters
        then
          let () =
            Loggers.fprintf
              (Remanent_parameters.get_logger parameters)
              "%sUpdate information about potential double bindings"
              (Remanent_parameters.get_prefix parameters)
          in
          Loggers.print_newline (Remanent_parameters.get_logger parameters)
        else
          ()
      in
      (*------------------------------------------------------------------*)
      (*the rule creates a bond matching with
        the first bond in a potential double bindings*)
      (*-----------------------------------------------------------*)
      let error, dynamic, precondition, store_value1 =
        apply_gen Fst parameters error static dynamic precondition rule_id rule
      in
      (*------------------------------------------------------------------*)
      (*the rule creates a bond matching with
        the second bond in a potential double bindings*)
      (*-----------------------------------------------------------*)
      let error, dynamic, precondition, store_value2 =
        apply_gen Snd parameters error static dynamic precondition rule_id rule
      in
      (*-----------------------------------------------------------*)
      (*combine two value above*)
      let bool =
        if Parallel_bonds_type.PairAgentsSitesStates_map_and_set.Map.is_empty
            store_value1
        && Parallel_bonds_type.PairAgentsSitesStates_map_and_set.Map.is_empty
             store_value2
        then
          false
        else
          let () = dump_title () in
          true
      in
      let error, store_value =
        Parallel_bonds_type.PairAgentsSitesStates_map_and_set.Map.fold2
          parameters error
          (fun parameters error x value store_result ->
             let error, store_result =
               Parallel_bonds_type.add_value_from_refined_tuple
                 parameters error kappa_handler x value store_result
             in
             error, store_result
          )
          (fun parameters error x value store_result ->
             let error, store_result =
               Parallel_bonds_type.add_value_from_refined_tuple
                 parameters error kappa_handler
                 x value store_result
             in
             error, store_result
          )
          (fun parameters error x value1 value2 store_result ->
             let new_value = Usual_domains.lub value1 value2 in
             let error, store_result =
               Parallel_bonds_type.add_value_from_refined_tuple
                 parameters error kappa_handler
                 x new_value store_result
             in
             error, store_result
          )
          store_value1
          store_value2
          Parallel_bonds_type.PairAgentSitesStates_map_and_set.Map.empty
      in
      (*--------------------------------------------------------------*)
      (*if it belongs to non parallel bonds then false*)
      (*deal with creation*)
      let store_parallel_map =
        if can_we_prove_this_is_not_the_first_application precondition
        then
          (*it is not applied for the first time.
            Sure_value is true then compute the double bonds on the rhs*)
          get_rule_double_bonds_rhs static
        else
        (*it is applied for the first time.
          Sure_value is false then it is empty*)
          Ckappa_sig.Rule_map_and_set.Map.empty
      in
      (*--------------------------------------------------------------*)
      let error, double_rhs_list =
        match
          Ckappa_sig.Rule_map_and_set.Map.find_option_without_logs parameters
            error
            rule_id
            store_parallel_map
        with
        | error, None ->
          error,
          Parallel_bonds_type.PairAgentsSitesStates_map_and_set.Map.empty
        | error, Some m -> error, m
      in
      let error, store_non_parallel =
        Parallel_bonds_type.PairAgentsSitesStates_map_and_set.Map.fold
          (fun (_,y) b (error, store_result)  ->
             if b then error, store_result
             else
               let error, store_result =
                 Parallel_bonds_type.PairAgentSitesStates_map_and_set.Map.add_or_overwrite
                   parameters error
                   y
                   (Usual_domains.Val false)
                   store_result
               in
               error, store_result
          )
          double_rhs_list
          (error,
           Parallel_bonds_type.PairAgentSitesStates_map_and_set.Map.empty)
      in
      (*--------------------------------------------------------------*)
      (*fold with store_value above*)
      let error, map_value = error, store_value in
      let () =
        if not bool &&
           Parallel_bonds_type.PairAgentSitesStates_map_and_set.Map.is_empty
             store_non_parallel
        then
          ()
        else
          dump_title ()
      in
      let store_result = get_value dynamic in
      let error, (store_set, store_result) =
        Parallel_bonds_type.PairAgentSitesStates_map_and_set.Map.fold2
          parameters error
          (fun parameters error x value (store_set, store_result) ->
             Parallel_bonds_type.add_value_and_event
               parameters error kappa_handler
               x
               value
               store_set
               store_result
          )
          (fun parameters error x value (store_set, store_result) ->
             Parallel_bonds_type.add_value_and_event parameters error
               kappa_handler
               x
               value
               store_set
               store_result
          )
          (fun parameters error x value1 value2 (store_set, store_result) ->
             let new_value = Usual_domains.lub value1 value2 in
             Parallel_bonds_type.add_value_and_event
               parameters error kappa_handler
               x
               new_value
               store_set
               store_result
          )
          map_value
          store_non_parallel
          (Parallel_bonds_type.PairAgentSite_map_and_set.Set.empty,
           store_result)
      in
      let dynamic = set_value store_result dynamic in
      (*---------------------------------------------------------------------*)
      (*check the new event*)
      let event_list = discover_a_new_pair_of_modify_sites store_set event_list
      in
      (*--------------------------------------------------------------*)
      (*if it belongs to parallel bonds then true*)
      let error, store_parallel =
        Parallel_bonds_type.PairAgentsSitesStates_map_and_set.Map.fold
          (fun (x, y) b (error, store_result) ->
             if b then
               let pair = Parallel_bonds_type.project2 (x, y) in
               let error, store_result =
                 Parallel_bonds_type.PairAgentSitesStates_map_and_set.Map.add_or_overwrite
                   parameters error
                   pair
                   (Usual_domains.Val true)
                   store_result
               in
               error, store_result
             else error, store_result
          )
          double_rhs_list
          (error,
           Parallel_bonds_type.PairAgentSitesStates_map_and_set.Map.empty)
      in
      (*--------------------------------------------------------------*)
      (*fold over the store_value and parallel bond value *)
      let () =
        if not bool &&
           Parallel_bonds_type.PairAgentSitesStates_map_and_set.Map.is_empty
             store_parallel
        then
          ()
        else
          dump_title ()
      in
      let store_result = get_value dynamic in
      let error, (store_set, store_result) =
        Parallel_bonds_type.PairAgentSitesStates_map_and_set.Map.fold
          (fun x value (error, (store_set, store_result)) ->
             Parallel_bonds_type.add_value_and_event parameters error
               kappa_handler
               x
               value
               store_set
               store_result
          )
          store_parallel
          (*get the store_set from the previous result*)
          (error, (store_set, store_result))
      in
      let dynamic = set_value store_result dynamic in
      let event_list = discover_a_new_pair_of_modify_sites store_set event_list
      in
      error, dynamic, (precondition, event_list)

  (* events enable communication between domains. At this moment, the
     global domain does not collect information *)

  let apply_event_list_rule_in_lhs_rhs_aux error store_rule_double_bonds
      event_list tuple_pair_set =
  let error, event_list =
    Ckappa_sig.Rule_map_and_set.Map.fold
      (fun rule_id tuple_pair_map (error, event_list) ->
         let error, event_list =
           Parallel_bonds_type.PairAgentsSitesStates_map_and_set.Map.fold
             (fun tuple_pair b (error, event_list) ->
                let proj (_,((b, c, d, e, f), (g, h, k, i, j))) =
                  (b, c, d, e, f), (g, h, k, i, j)
                in
                let proj_tuple = proj tuple_pair in
                (*check if the tuple belongs to the good tuple*)
                if Parallel_bonds_type.PairAgentSitesStates_map_and_set.Set.mem
                    proj_tuple
                    tuple_pair_set
                then
                  error, (Communication.Check_rule rule_id) :: event_list
                else
                  error, event_list
             ) tuple_pair_map (error, event_list)
         in
         error, event_list
      ) store_rule_double_bonds (error, event_list)
  in
  error, event_list

  let apply_event_list_rule_in_first_and_second_aux error
      store_site_create_parallel_bonds event_list tuple_pair_set =
    let error, event_list =
      Ckappa_sig.Rule_map_and_set.Map.fold
        (fun rule_id tuple_pair_map (error, event_list) ->
           Parallel_bonds_type.PairAgentsSiteState_map_and_set.Map.fold
             (fun tuple_pair tuple_list (error, event_list) ->
                List.fold_left (fun (error, event_list) tuple ->
                    let proj (_,b, c, d, e, f) = (b, c, d, e, f) in
                    let proj2 (x, y) = proj x, proj y in
                    (*check if the tuple belongs to the good tuple*)
                    if
                      Parallel_bonds_type.PairAgentSitesStates_map_and_set.Set.mem
                        (proj2 tuple)
                        tuple_pair_set
                    then
                      error, (Communication.Check_rule rule_id) :: event_list
                    else
                      error, event_list
                  ) (error, event_list) tuple_list
             ) tuple_pair_map (error, event_list)
      ) store_site_create_parallel_bonds (error, event_list)
  in
  error, event_list

  let apply_event_list static dynamic error event_list =
      let parameters = get_parameter static in
      let store_sites_to_tuple = get_sites_to_tuple static in
      (*get a list tuple pair that the pair of modified sites belong to*)
      let error, event_list =
        List.fold_left (fun (error, event_list) event ->
            match event with
            | Communication.Dummy
            | Communication.Check_rule _
            | Communication.See_a_new_bond _ -> error, event_list
            | Communication.Modified_sites (agent_type, site_type) ->
              (*search with tuple that this pair of site belong to*)
              let error, tuple_pair_set =
                match
                  Parallel_bonds_type.AgentSite_map_and_set.Map.find_option_without_logs
                    parameters error
                    (agent_type, site_type)
                    store_sites_to_tuple (*tuple from lhs and rhs*)
                with
                | error, None ->
                  error,
                  Parallel_bonds_type.PairAgentSitesStates_map_and_set.Set.empty
                | error, Some s -> error, s
              in
              (*-----------------------------------------------------------*)
              (*get rule_id from tuple on the lhs*)
              let store_rule_double_bonds_lhs =
                get_rule_double_bonds_lhs static in
              let error, event_list =
                apply_event_list_rule_in_lhs_rhs_aux
                  error store_rule_double_bonds_lhs
                  event_list
                  tuple_pair_set
              in
              (*-----------------------------------------------------------*)
              (*get rule_id from tuple on the rhs*)
              let store_rule_double_bonds_rhs =
                get_rule_double_bonds_rhs static in
              let error, event_list =
                apply_event_list_rule_in_lhs_rhs_aux
                  error
                  store_rule_double_bonds_rhs
                  event_list
                  tuple_pair_set
              in
              (*-----------------------------------------------------------*)
              (*rule_id in the case when the first site created the tuple*)
              let store_fst_site_create_parallel_bonds_rhs =
                get_fst_site_create_parallel_bonds_rhs static in
              let error, event_list =
                apply_event_list_rule_in_first_and_second_aux
                  error
                  store_fst_site_create_parallel_bonds_rhs
                  event_list
                  tuple_pair_set
              in
              (*-----------------------------------------------------------*)
              let store_snd_site_create_parallel_bonds_rhs =
                get_snd_site_create_parallel_bonds_rhs static in
              let error, event_list =
                apply_event_list_rule_in_first_and_second_aux
                  error
                  store_snd_site_create_parallel_bonds_rhs
                  event_list
                  tuple_pair_set
              in
              error, event_list
          ) (error, []) event_list
      in
      error, dynamic, event_list

  (****************************************************************)

  let stabilize _static dynamic error = error, dynamic, ()

  let print static dynamic (error:Exception.method_handler) loggers =
    let kappa_handler = get_kappa_handler static in
    let parameters = get_parameter static in
    let log = loggers in
    (*-------------------------------------------------------*)
    let error =
      if Remanent_parameters.get_dump_reachability_analysis_result
          parameters
      then
        let () =
          Loggers.fprintf log
            "------------------------------------------------------------\n";
          Loggers.fprintf log "* Properties of pairs of bonds\n";
          Loggers.fprintf log
            "------------------------------------------------------------\n"
        in
        let store_value = get_value dynamic in
        let error =
          Parallel_bonds_type.PairAgentSitesStates_map_and_set.Map.fold
            (fun tuple value error ->
               Parallel_bonds_type.print_parallel_constraint
                 ~verbose:true
                 ~sparse:true
                 ~final_resul:true
                 ~dump_any:true parameters error kappa_handler tuple value
            ) store_value error
        in error
      else
        error
    in
    (***************************************************************)
    (*print a map tuple to sites*)
    let error =
      if Remanent_parameters.get_dump_reachability_analysis_result
          parameters
      then
        let () =
        Loggers.fprintf log
          "------------------------------------------------------------\n";
        Loggers.fprintf log "* Properties of pairs of bonds, a map from tuples to sites\n";
        Loggers.fprintf log
          "------------------------------------------------------------\n"
        in
        let store_result = get_tuple_to_sites static in
        let error =
          Parallel_bonds_type.PairAgentSite_map_and_set.Map.fold
            (fun (x, y, z, t) pair_set error ->
               Parallel_bonds_type.PairAgentSitesStates_map_and_set.Set.fold
                 (fun (a, b) error ->
                    (*print tuples of interest*)
                    let error, (string_agent, string_site, string_site', string_agent1, string_site1, string_site1') =
                      Parallel_bonds_type.convert_tuple
                        parameters error kappa_handler
                        (a, b)
                    in
                    (*convert first pair*)
                    let error, (string_agent_x, string_site_x) =
                      Parallel_bonds_type.convert_pair parameters error
                        kappa_handler
                        x
                    in
                    let error, (string_agent_y, string_site_y) =
                      Parallel_bonds_type.convert_pair parameters error
                        kappa_handler
                        y
                    in
                    let error, (string_agent_z, string_site_z) =
                      Parallel_bonds_type.convert_pair parameters error
                        kappa_handler
                        z
                    in
                    let error, (string_agent_t, string_site_t) =
                      Parallel_bonds_type.convert_pair parameters error
                        kappa_handler
                        t
                    in
                    (*Print*)
                    let () =
                      Loggers.fprintf log "%s(%s,%s), %s(%s, %s) => (%s, %s); (%s, %s); (%s, %s); (%s, %s)\n"
                        string_agent string_site string_site'
                        string_agent1 string_site1 string_site1'
                        string_agent_x string_site_x
                        string_agent_y string_site_y
                        string_agent_z string_site_z
                        string_agent_t string_site_t
                    in
                    error
                 ) pair_set error
            ) store_result error
        in
        error
      else error
    in
    (***************************************************************)
    (*print a map tuple to sites*)
    let error =
      if Remanent_parameters.get_dump_reachability_analysis_result
          parameters
      then
      let () =
      Loggers.fprintf log
        "------------------------------------------------------------\n";
      Loggers.fprintf log "* Properties of pairs of bonds, a map from sites to tuple\n";
      Loggers.fprintf log
        "------------------------------------------------------------\n"
      in
      let store_result = get_sites_to_tuple static in
      let error =
        Parallel_bonds_type.AgentSite_map_and_set.Map.fold
          (fun (agent_type_x, site_type_x) tuple_set error' ->
             Parallel_bonds_type.PairAgentSitesStates_map_and_set.Set.fold
               (fun (u, v) error' ->
                  (*convert first pair*)
                  let error, (string_agent_x, string_site_x) =
                    Parallel_bonds_type.convert_pair parameters error
                      kappa_handler
                      (agent_type_x, site_type_x)
                  in
                  let error,
                      (string_agent, string_site, string_site',
                       string_agent1, string_site1, string_site1') =
                    Parallel_bonds_type.convert_tuple parameters error
                      kappa_handler (u, v)
                  in
                  let () =
                    Loggers.fprintf log
                      "(%s, %s) => %s(%s, %s), %s(%s, %s)\n"
                      string_agent_x string_site_x
                      string_agent string_site string_site'
                      string_agent1 string_site1 string_site1'
                  in
                  error'
               ) tuple_set error
          ) store_result error
      in
      error
      else error
    in
    error, dynamic, ()

  (****************************************************************)

  let export _static dynamic error kasa_state =
    error, dynamic, kasa_state

  let lkappa_mixture_is_reachable _static dynamic error _lkappa =
    error, dynamic, Usual_domains.Maybe (* to do *)

  let cc_mixture_is_reachable _static dynamic error _ccmixture =
    error, dynamic, Usual_domains.Maybe (* to do *)

end
