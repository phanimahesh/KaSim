(**
   * contact_map_domain.ml
   * openkappa
   * Jérôme Feret & Ly Kim Quyen, projet Abstraction, INRIA Paris-Rocquencourt
   *
   * Creation: 2016, the 22th of February
   * Last modification:
   *
   * Abstract domain to record live rules
   *
   * Copyright 2010,2011,2012,2013,2014,2015,2016 Institut National de Recherche
   * en Informatique et en Automatique.
   * All rights reserved.  This file is distributed
   * under the terms of the GNU Library General Public License *)

let warn parameters mh message exn default =
  Exception.warn parameters mh (Some "Contact map domain") message exn
    (fun () -> default)

let local_trace = false

module Domain =
struct

  (*type agent_type = Cckappa_sig.agent_name
  type site_type = Cckappa_sig.site_name
  type state_index = Cckappa_sig.state_index
    
  module PairAgentSiteState_map_and_set = Cckappa_sig.PairAgentSiteState_map_and_set

  module Rule_map_and_set = Cckappa_sig.Rule_map_and_set*)

  type local_static_information =
    {
      bond_rhs : Ckappa_sig.PairAgentSiteState_map_and_set.Set.t Ckappa_sig.Rule_map_and_set.Map.t;
      bond_lhs : Ckappa_sig.PairAgentSiteState_map_and_set.Set.t Ckappa_sig.Rule_map_and_set.Map.t
    }

  type static_information =
    {
      global_static_information : Analyzer_headers.global_static_information;
      local_static_information  : local_static_information
    }

  (*module AgentSite_map_and_set = Cckappa_sig.AgentSite_map_and_set
    
  module State_map_and_set = Cckappa_sig.State_map_and_set*)
    
  type local_dynamic_information = 
    {
      contact_map_dynamic : Ckappa_sig.PairAgentSiteState_map_and_set.Set.t;
      bonds_per_site : (Ckappa_sig.c_agent_name * Ckappa_sig.c_site_name * 
                          Ckappa_sig.c_state)
        Ckappa_sig.State_map_and_set.Map.t Ckappa_sig.AgentSite_map_and_set.Map.t
    }

  type dynamic_information =
    {
      local  : local_dynamic_information;
      global : Analyzer_headers.global_dynamic_information
    }

  (**************************************************************************)
  (*local static information*)

  let get_global_static_information static = static.global_static_information

  let lift f x = f (get_global_static_information x)

  let get_parameter static = lift Analyzer_headers.get_parameter static

  let get_kappa_handler static = lift Analyzer_headers.get_kappa_handler static

  let get_compil static = lift Analyzer_headers.get_cc_code static

  let get_local_static_information static = static.local_static_information

  let set_local_static_information local static =
    {
      static with
        local_static_information = local
    }

  let get_bond_rhs static = (get_local_static_information static).bond_rhs

  let set_bond_rhs bond static =
    set_local_static_information
      {
        (get_local_static_information static) with
          bond_rhs = bond
      } static

  let get_bond_lhs static = (get_local_static_information static).bond_lhs

  let set_bond_lhs bond static =
    set_local_static_information
      {
        (get_local_static_information static) with
          bond_lhs = bond
      } static

  (*--------------------------------------------------------------------*)
  (** dynamic information*)

  let get_local_dynamic_information dynamic = dynamic.local

  let set_local_dynamic_information local dynamic =
    {
      dynamic with local = local
    }

  let get_contact_map_dynamic dynamic =
    (get_local_dynamic_information dynamic).contact_map_dynamic

  let set_contact_map_dynamic contact_map dynamic =
    set_local_dynamic_information
      {
        (get_local_dynamic_information dynamic) with
          contact_map_dynamic = contact_map
      } dynamic
      
  let get_bonds_per_site dynamic =
    (get_local_dynamic_information dynamic).bonds_per_site

  let set_bonds_per_site bonds dynamic =
    set_local_dynamic_information
      {
        (get_local_dynamic_information dynamic) with
          bonds_per_site = bonds
      } dynamic
      
  (**************************************************************************)
  (*implementations*)

  (*dual: contact map including initial state, use in views_domain*)
      
  (*module AgentSiteState_map_and_set = Cckappa_sig.AgentSiteState_map_and_set*)
    
  let collect_dual_map parameter error handler store_result =
    let error, store_result =
      (*Int_storage.Nearly_Inf_Int_Int_Int_storage_Imperatif_Imperatif_Imperatif.fold*)
      Ckappa_sig.Agent_type_site_state_nearly_Inf_Int_Int_Int_storage_Imperatif_Imperatif_Imperatif.fold
        parameter error
        (fun parameter error (agent_type, (site_type, state))
          (agent_type', site_type', state') store_result ->
            let error, old_set =
              match Ckappa_sig.AgentSiteState_map_and_set.Map.find_option_without_logs parameter error
                (agent_type, site_type, state) store_result
              with
              | error, None -> error, Ckappa_sig.AgentSiteState_map_and_set.Set.empty
              | error, Some s -> error, s
            in
            let error', set =
              Ckappa_sig.AgentSiteState_map_and_set.Set.add_when_not_in parameter error
                (agent_type', site_type', state') 
                Ckappa_sig.AgentSiteState_map_and_set.Set.empty
            in
            let error = Exception.check warn parameter error error'
              (Some "line 446") Exit 
            in
            let error'', new_set = 
              Ckappa_sig.AgentSiteState_map_and_set.Set.union parameter error set old_set
            in
            let error = Exception.check warn parameter error error''
              (Some "line 446") Exit 
            in
            let error, store_result = 
              Ckappa_sig.AgentSiteState_map_and_set.Map.add_or_overwrite parameter error
                (agent_type, site_type, state) new_set store_result
            in
            error, store_result
        ) handler.Cckappa_sig.dual store_result
    in
    error, store_result

  let collect_agent_type_state parameter error agent site_type =
    match agent with
    | Cckappa_sig.Ghost
    | Cckappa_sig.Unknown_agent _
    | Cckappa_sig.Dead_agent _ ->
      warn parameter error (Some "line 199") Exit (Ckappa_sig.dummy_agent_name, 0)
    | Cckappa_sig.Agent agent1 ->
      let agent_type1 = agent1.Cckappa_sig.agent_name in
      let error, state1 =
        match Ckappa_sig.Site_map_and_set.Map.find_option_without_logs
          parameter
          error
          site_type
          agent1.Cckappa_sig.agent_interface
        with
        | error, None ->  warn parameter error (Some "line 228") Exit 0
        | error, Some port ->
          let state = port.Cckappa_sig.site_state.Cckappa_sig.max in
          if state > 0
          then error, state
          else warn parameter error (Some "line 234") Exit 0
      in
      error, (agent_type1, state1) 

  let add_link_set parameter error rule_id (x, y) store_result =
    let error, old_set =
      match Ckappa_sig.Rule_map_and_set.Map.find_option_without_logs parameter error 
        rule_id store_result
      with
      | error, None -> error, Ckappa_sig.PairAgentSiteState_map_and_set.Set.empty
      | error, Some p -> error, p
    in
    let error', set = 
      Ckappa_sig.PairAgentSiteState_map_and_set.Set.add_when_not_in
        parameter error 
        (x, y)
        old_set
    in    
    let error = Exception.check warn parameter error error' (Some "line 246") Exit in
    let error'', union_set =
      Ckappa_sig.PairAgentSiteState_map_and_set.Set.union parameter error set old_set 
    in
    let error = Exception.check warn parameter error error'' (Some "line 250") Exit in
    let error, store_result =
      Ckappa_sig.Rule_map_and_set.Map.add_or_overwrite parameter error rule_id union_set store_result
    in
    error, store_result

  let collect_bonds parameter error rule_id bonds views store_result =
    let error, store_result =
      Int_storage.Quick_Nearly_inf_Imperatif.fold parameter error
        (fun parameter error agent_id bonds_map store_result ->
          let error, store_result =
            Ckappa_sig.Site_map_and_set.Map.fold
              (fun site_type_source site_add (error, store_result) ->
                let agent_index_target = site_add.Cckappa_sig.agent_index in
                let site_type_target = site_add.Cckappa_sig.site in
                let error, agent_source =
                  match Ckappa_sig.Agent_id_quick_nearly_inf_Imperatif.get
                    parameter error agent_id views
                  with
                  | error, None -> warn parameter error (Some "line 271") Exit
                    Cckappa_sig.Ghost
                  | error, Some agent -> error, agent
                in
                let error, agent_target =
                  match Ckappa_sig.Agent_id_quick_nearly_inf_Imperatif.get
                    parameter error agent_index_target views
                  with
                  | error, None -> warn parameter error (Some "line 279") Exit
                    Cckappa_sig.Ghost
                  | error, Some agent -> error, agent
                in
                let error, (agent_type1, state1) =
                  collect_agent_type_state
                    parameter
                    error
                    agent_source
                    site_type_source
                in
                let error, (agent_type2, state2) =
                  collect_agent_type_state
                    parameter
                    error
                    agent_target
                    site_type_target
                in
                let pair = ((agent_type1, site_type_source, state1),
                            (agent_type2, site_type_target, state2)) 
                in
                let error, store_result =
                  add_link_set parameter error rule_id pair store_result 
                in
                error, store_result
              ) bonds_map (error, store_result)
          in
          error, store_result
        ) bonds store_result
    in
    error, store_result

   (*collect bonds lhs*)
  let collect_bonds_rhs parameter error rule_id rule store_result =
    let views = rule.Cckappa_sig.rule_rhs.Cckappa_sig.views in
    let bonds = rule.Cckappa_sig.rule_rhs.Cckappa_sig.bonds in
    let error, store_result =
      collect_bonds 
        parameter 
        error
        rule_id
	bonds
	views
	store_result
    in
    error, store_result

  let collect_bonds_lhs parameter error rule_id rule store_result =
    let views = rule.Cckappa_sig.rule_lhs.Cckappa_sig.views in
    let bonds = rule.Cckappa_sig.rule_lhs.Cckappa_sig.bonds in
    let error, store_result =
      collect_bonds parameter error rule_id bonds views store_result
    in
    error, store_result

  (**************************************************************************)

  let scan_rule_set static dynamic error =
    let parameter = get_parameter static in
    let compil = get_compil static in
    let error, static =
      Int_storage.Nearly_inf_Imperatif.fold
        parameter
        error
        (fun parameter error rule_id rule static ->
          let store_rhs = get_bond_rhs static in
          (*bond rhs*)
          let error, store_rhs =
            collect_bonds_rhs
              parameter
              error
              rule_id
              rule.Cckappa_sig.e_rule_c_rule
              store_rhs
          in
          let static = set_bond_rhs store_rhs static in
          (*bond lhs*)
          let store_lhs = get_bond_lhs static in
          let error, store_lhs =
            collect_bonds_lhs
              parameter
              error
              rule_id
              rule.Cckappa_sig.e_rule_c_rule
              store_lhs
          in
          let static = set_bond_lhs store_lhs static in
          error, static
        ) compil.Cckappa_sig.rules static
    in
    error, static, dynamic

  (**************************************************************************)

  let initialize static dynamic error =
    let init_domain_static =
      {
        bond_rhs = Ckappa_sig.Rule_map_and_set.Map.empty;
        bond_lhs = Ckappa_sig.Rule_map_and_set.Map.empty;
      }
    in
    let init_global_static_information =
      {
        global_static_information = static;
        local_static_information  = init_domain_static
      }
    in
    let init_local =
      {
        contact_map_dynamic = Ckappa_sig.PairAgentSiteState_map_and_set.Set.empty;
        bonds_per_site      = Ckappa_sig.AgentSite_map_and_set.Map.empty
      }
    in
    let init_global_dynamic_information =
      {
        local  = init_local;
        global = dynamic
      }
    in
    let error, static, dynamic =
      scan_rule_set init_global_static_information init_global_dynamic_information error
    in
    error, static, dynamic

  (**************************************************************************)

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

  (**************************************************************************)
  (*Implementation*)
    
  let add_oriented_bond_in_set_of_bonds static dynamic error (x, y) =
    let parameter = get_parameter static in
    let contact_map_dynamic = get_contact_map_dynamic dynamic in
    let error, contact_map_dynamic =
      Ckappa_sig.PairAgentSiteState_map_and_set.Set.add_when_not_in
        parameter error 
        (x, y)
        contact_map_dynamic
    in
    let dynamic = set_contact_map_dynamic contact_map_dynamic dynamic in
    error, dynamic		       

  let add_bond_in_set_of_bonds static dynamic error (x, y) =
    let error, dynamic = add_oriented_bond_in_set_of_bonds static dynamic error (x, y) in
    add_oriented_bond_in_set_of_bonds static dynamic error (y, x)
      
  let add_oriented_bond_in_map_of_bonds static dynamic error (x, y) =
    let (agent_type, site_type, state) = x in
    let (agent_type', site_type', state') = y in
    let parameter = get_parameter static in
    let bonds_per_site = get_bonds_per_site dynamic in
    let error, old_map =
      match 
        Ckappa_sig.AgentSite_map_and_set.Map.find_option_without_logs
	  parameter error
	  (agent_type, site_type)
	  bonds_per_site
      with
      | error, None -> error, Ckappa_sig.State_map_and_set.Map.empty
      | error, Some m -> error, m
    in
    let error, state_map =
      Ckappa_sig.State_map_and_set.Map.add_or_overwrite parameter error
        state
        (agent_type', site_type', state')
        old_map
    in
    let error, bonds_per_site =
      Ckappa_sig.AgentSite_map_and_set.Map.add_or_overwrite parameter error
        (agent_type, site_type)
        state_map
        bonds_per_site
    in
    let dynamic = set_bonds_per_site bonds_per_site dynamic in
    error, dynamic

  let add_bond_in_map_of_bonds static dynamic error (x, y) =
    let error, dynamic = add_oriented_bond_in_map_of_bonds static dynamic error (x, y) in
    add_oriented_bond_in_map_of_bonds static dynamic error (y, x)

  let add_oriented_bond static dynamic error bond =
    let error, dynamic = add_oriented_bond_in_set_of_bonds static dynamic error bond in
    add_oriented_bond_in_map_of_bonds static dynamic error bond
      
  let add_bond static dynamic error bond =
    let error, dynamic = add_bond_in_set_of_bonds static dynamic error bond in
    add_bond_in_map_of_bonds static dynamic error bond

  (* make sure the appropriate version among oriented and unoriented, is
     used each one (the result must be unonriented) *)
  (* basically, either the input is unoriented, which means that each time
     the bond (x,y) is given, the bond (y,x) is given as well, and we can use
     the oriented version *)
  (* but if this is not the case, we have to use the unoriented version *)
      
  (**bond occurs in the initial state*)

  let collect_bonds_initial static dynamic error init_state =
    let parameter = get_parameter static in
    let views = init_state.Cckappa_sig.e_init_c_mixture.Cckappa_sig.views in
    let bonds = init_state.Cckappa_sig.e_init_c_mixture.Cckappa_sig.bonds in
    let error, dynamic =
      Int_storage.Quick_Nearly_inf_Imperatif.fold parameter error
        (fun parameter error agent_id bonds_map dynamic ->
          let error, store_result =
            Ckappa_sig.Site_map_and_set.Map.fold
              (fun site_type_source site_add (error, dynamic) ->
                let agent_index_target = site_add.Cckappa_sig.agent_index in
                let site_type_target = site_add.Cckappa_sig.site in
                let error, agent_source =
                  match Ckappa_sig.Agent_id_quick_nearly_inf_Imperatif.get
                    parameter error agent_id views
                  with
                  | error, None -> warn parameter error (Some "line 473") Exit
                    Cckappa_sig.Ghost
                  | error, Some agent -> error, agent
                in
                let error, agent_target =
                  match Ckappa_sig.Agent_id_quick_nearly_inf_Imperatif.get
                    parameter error agent_index_target views
                  with
                  | error, None -> warn parameter error (Some "line 480") Exit
                    Cckappa_sig.Ghost
                  | error, Some agent -> error, agent
                in
                let error, (agent_type1, state1) =
                  collect_agent_type_state
                    parameter
                    error
                    agent_source
                    site_type_source
                in
                let error, (agent_type2, state2) =
                  collect_agent_type_state
                    parameter
                    error
                    agent_target
                    site_type_target
                in
                let pair_triple = ((agent_type1, site_type_source, state1),
                                   (agent_type2, site_type_target, state2)) 
                in
                (*use the oriented bonds, when given the bond (x, y), the
                  bond (y, x) is given as well*)
                let error, dynamic = add_oriented_bond static dynamic error pair_triple in
                error, dynamic
              ) bonds_map (error, dynamic)
          in
          error, dynamic
        ) bonds dynamic
    in
    error, dynamic

  (**************************************************************************)

  let add_initial_state static dynamic error species =
    let event_list = [] in
    let error, dynamic =
      collect_bonds_initial static dynamic error species
    in
    error, dynamic, event_list

  (**************************************************************************)
  
  let is_enabled static dynamic error rule_id precondition =
    (*test if the bond in the lhs has already in the contact map, if not
      None, *)
    let parameter = get_parameter static in
    let bond_lhs = get_bond_lhs static in
    let contact_map = get_contact_map_dynamic dynamic in
    let error, bond_lhs_set =
      match Ckappa_sig.Rule_map_and_set.Map.find_option_without_logs parameter error
        rule_id bond_lhs
      with
      | error, None -> error, Ckappa_sig.PairAgentSiteState_map_and_set.Set.empty
      | error, Some l -> error, l
    in
    let error, inter =
      Ckappa_sig.PairAgentSiteState_map_and_set.Set.inter
        parameter error contact_map bond_lhs_set
    in
    if Ckappa_sig.PairAgentSiteState_map_and_set.Set.is_empty inter
    then 
      (* use the function Communication.overwrite_potential_partners_map to
         fill the two fields related to the dynamic contact map *)
      (* then use the functions get_potential_partner and/or
         fold_over_potential_partners in the views domain to use the incremental
         (dynamic) contact map *)
      (* instead of the static one *)
      let error, precondition =
        Communication.overwrite_potential_partners_map 
          parameter 
          error
          precondition
          (fun agent_type site_type state ->
	    (* Here you should fetch the partner in the dynamic contact
	       map, if defined, *)
            let error, statemap_bottop =
              Ckappa_sig.AgentSite_map_and_set.Map.find_option_without_logs parameter error
                (agent_type, site_type) dynamic.local.bonds_per_site
            in
            match statemap_bottop with
            | None -> Usual_domains.Val (agent_type, site_type, state)
            | Some statemap ->
              Ckappa_sig.State_map_and_set.Map.fold
                (fun state (agent_type', site_type', state') _ ->
                  Usual_domains.Val (agent_type', site_type', state')
                ) statemap Usual_domains.Any)
          {
            Communication.fold =
	      begin
		fun parameter error agent_type site_type ->
		  let error, statemap_bottop = 
                    Ckappa_sig.AgentSite_map_and_set.Map.find_option_without_logs 
                      parameter error
                      (agent_type, site_type) dynamic.local.bonds_per_site
                  in
		  match statemap_bottop with
		  | None -> error,
		    (Usual_domains.Val
		       (fun f error init -> error, init))
		  | Some statemap ->
		    error,
		    Usual_domains.Val
		      (fun f error init ->
		        Ckappa_sig.State_map_and_set.Map.fold
			  (f parameter)
		       	  statemap
			  (error, init)
		      )
	      end
          }
      in
      error, dynamic, Some precondition
    else error, dynamic, None
      
  (**************************************************************************)

  let apply_rule static dynamic error rule_id precondition =
    let event_list = [] in
    let parameter = get_parameter static in
    (*add the bonds in the rhs into the contact map*)
    let contact_map = get_contact_map_dynamic dynamic in
    let bond_rhs_map = get_bond_rhs static in
    let error, bond_rhs_set =
      match Ckappa_sig.Rule_map_and_set.Map.find_option_without_logs parameter error rule_id
        bond_rhs_map
      with
      | error, None -> error, Ckappa_sig.PairAgentSiteState_map_and_set.Set.empty
      | error, Some s -> error, s
    in
    let error', union =
      Ckappa_sig.PairAgentSiteState_map_and_set.Set.union 
        parameter error contact_map bond_rhs_set
    in
    let error = Exception.check warn parameter error error' (Some "line 590") Exit in
    let dynamic = set_contact_map_dynamic union dynamic in
    let new_contact_map = get_contact_map_dynamic dynamic in
    let error', map_diff =
      Ckappa_sig.PairAgentSiteState_map_and_set.Set.diff 
        parameter error new_contact_map contact_map
    in
    let error = Exception.check warn parameter error error' (Some "line 569") Exit in
    (*update the second field*)
    let error, dynamic =
      Ckappa_sig.PairAgentSiteState_map_and_set.Set.fold
        (fun bond (error, dynamic) ->
          add_bond_in_map_of_bonds static dynamic error bond
	) map_diff (error, dynamic)
    in
    (*check if it is seen for the first time, if not update the contact
      map, and raise an event*)
    let dynamic = set_contact_map_dynamic new_contact_map dynamic in
    let event_list =
      Ckappa_sig.PairAgentSiteState_map_and_set.Set.fold (fun pair event_list ->
        (Communication.See_a_new_bond pair) :: event_list
      ) map_diff event_list
    in
    error, dynamic, (precondition, event_list)

  let rec apply_event_list static dynamic error event_list =
    let event_list = [] in
    error, dynamic, event_list

  let export static dynamic error kasa_state =
    error, dynamic, kasa_state

  let print static dynamic error loggers =
    error, dynamic, ()

  let lkappa_mixture_is_reachable static dynamic error lkappa =
    error, dynamic, Usual_domains.Maybe (* to do *)

  let cc_mixture_is_reachable static dynamic error lkappa =
    error, dynamic, Usual_domains.Maybe (* to do *)

end