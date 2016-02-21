(**
   * bdu_dynamic_views.mli
   * openkappa
   * Jérôme Feret & Ly Kim Quyen, projet Abstraction, INRIA Paris-Rocquencourt
   * 
   * Creation: 2016, the 18th of Feburary
   * Last modification: 
   * 
   * Compute the relations between sites in the BDU data structures
   * 
   * Copyright 2010,2011,2012,2013,2014,2015,2016 Institut National de Recherche 
   * en Informatique et en Automatique.  
   * All rights reserved.  This file is distributed     
   * under the terms of the GNU Library General Public License *)

open Cckappa_sig

let warn parameters mh message exn default =
  Exception.warn parameters mh (Some "Bdu_fixpoint_iteration") message exn
    (fun () -> default)

let local_trace = false

module Int2Map_CV_Modif =
  Map_wrapper.Make
    (SetMap.Make
       (struct
         type t = int * int
         let compare = compare
        end))

type bdu_analysis_dynamic =
  {
    store_update : (int list * Site_map_and_set.Set.t) Int2Map_CV_Modif.Map.t;
  }

(************************************************************************************)
(*implementation*)


let store_covering_classes_modification_update_aux parameter error agent_type_cv
    site_type_cv cv_id store_test_modification_map store_result =
  let add_link (agent_type, cv_id) rule_id_set store_result =
    let error, (l, old) =
      match Int2Map_CV_Modif.Map.find_option_without_logs parameter error
        (agent_type, cv_id) store_result
      with
      | error, None -> error, ([], Site_map_and_set.Set.empty)
      | error, Some (l, s) -> error, (l, s)
    in
    let error', new_set =
      Site_map_and_set.Set.union parameter error rule_id_set old
    in
    let error = Exception.check warn parameter error error' (Some "line 75") Exit in
    let error, result =
      Int2Map_CV_Modif.Map.add_or_overwrite parameter error (agent_type, cv_id) (l, new_set)
        store_result
    in
    error, result
  in
  (*-------------------------------------------------------------------------------*)
  let error, (l, rule_id_set) =
    match Bdu_static_views.Int2Map_Test_Modif.Map.find_option_without_logs parameter error
      (agent_type_cv, site_type_cv) store_test_modification_map
    with
    | error, None -> error, ([], Site_map_and_set.Set.empty)
    | error, Some (l, s) -> error, (l, s)
  in
  let error, result =
    add_link (agent_type_cv, cv_id) rule_id_set store_result
  in
    (*-------------------------------------------------------------------------------*)
    (*map this map*)
  let store_result =
    Int2Map_CV_Modif.Map.map (fun (l, x) -> List.rev l, x) result
  in
  error, store_result
    
(************************************************************************************)

let store_covering_classes_modification_update parameter error
    store_test_modification_map
    store_covering_classes_id =
  let error, store_result =
    Bdu_static_views.Int2Map_CV.Map.fold
      (fun (agent_type_cv, site_type_cv) (l1, l2) store_result ->
        List.fold_left (fun (error, store_current_result) cv_id ->
          let error, result =
            store_covering_classes_modification_update_aux
              parameter
              error
              agent_type_cv
              site_type_cv
              cv_id
              store_test_modification_map
              store_current_result
          in
          error, result
        ) store_result l2
      (*REMARK: when it is folding inside a list, start with empty result,
        because the add_link function has already called the old result.*)
      ) store_covering_classes_id (error, Int2Map_CV_Modif.Map.empty)
  in
  let store_result =
    Int2Map_CV_Modif.Map.map (fun (l, x) -> List.rev l, x) store_result
  in
  error, store_result

(************************************************************************************)
(*combine update(c) and update(c') of side effects together*)

(************************************************************************************)
(*update function added information of rule_id in side effects*)

let store_covering_classes_modification_side_effects parameter error 
    store_test_modification_map
    store_potential_side_effects
    covering_classes
    store_result =
  let add_link (agent_type, cv_id) rule_id_set store_result =
    let error, (l, old) =
      match Int2Map_CV_Modif.Map.find_option_without_logs parameter error
        (agent_type, cv_id) store_result
      with
      | error, None -> error, ([], Site_map_and_set.Set.empty)
      | error, Some (l, s) -> error, (l, s)
    in
    let error', new_set =
      Site_map_and_set.Set.union parameter error rule_id_set old
    in
    let error = Exception.check warn parameter error error' (Some "line 169") Exit in
    let error, result =
      Int2Map_CV_Modif.Map.add_or_overwrite parameter error (agent_type, cv_id) (l, new_set) 
        store_result
    in
    error, result
  in
  (*-------------------------------------------------------------------------------*)
  let _, store_potential_side_effects_bind = store_potential_side_effects in
  let error, store_result =
    Common_static.Int2Map_potential_effect.Map.fold 
      (fun (agent_type_partner, rule_id_effect) pair_list (error, store_result) ->
        List.fold_left (fun (error, store_result) (site_type_partner, state) ->
          let error, store_result =
            Int_storage.Quick_Nearly_inf_Imperatif.fold parameter error
              (fun parameter error agent_type_cv remanent store_result ->
                let cv_dic = remanent.Covering_classes_type.store_dic in
                let error, store_result =
                  Covering_classes_type.Dictionary_of_Covering_class.fold
                    (fun list_of_site_type ((), ()) cv_id (error, store_result) ->
                    (*get a set of rule_id in update(c)*)
                      let error, (l, rule_id_set) =
                        match 
                          Bdu_static_views.Int2Map_Test_Modif.Map.find_option_without_logs
                            parameter error
                            (agent_type_partner, site_type_partner)
                            store_test_modification_map
                        with
                        | error, None -> error, ([], Site_map_and_set.Set.empty)
                        | error, Some (l, s) -> error, (l, s)
                      in
                      (*add rule_id_effect into rule_id_set*)
                      let error, new_rule_id_set =
                        Site_map_and_set.Set.add parameter error rule_id_effect rule_id_set
                      in
                      let error, store_result =
                        add_link (agent_type_partner, cv_id) new_rule_id_set store_result
                      in
                      error, store_result
                    ) cv_dic (error, store_result)
                in
                error, store_result
              ) covering_classes store_result
          in
          error, store_result
        ) (error, store_result) pair_list
      ) store_potential_side_effects_bind (error, store_result)
  in
  error, store_result

(************************************************************************************)

let store_update parameter error store_test_modification_map store_potential_side_effects
    store_covering_classes_id covering_classes store_result =
  let add_link error (agent_type, cv_id) rule_id_set store_result =
    let error, (l, old) =
      match Int2Map_CV_Modif.Map.find_option_without_logs parameter error
        (agent_type, cv_id) store_result
      with
      | error, None -> error, ([], Site_map_and_set.Set.empty)
      | error, Some (l, s) -> error, (l, s)
    in
    let error', new_set =
      Site_map_and_set.Set.union parameter error rule_id_set old
    in
    let error = Exception.check warn parameter error error' (Some "line 251") Exit in
    let error, result =
      Int2Map_CV_Modif.Map.add_or_overwrite
        parameter error (agent_type, cv_id) (l, new_set) store_result
    in
    error, result
  in
  let error, store_update_modification =
    store_covering_classes_modification_update
      parameter
      error
      store_test_modification_map
      store_covering_classes_id
  in
  let init_cv_modification_side_effects  = Int2Map_CV_Modif.Map.empty in
  let error, store_update_with_side_effects =
    store_covering_classes_modification_side_effects
      parameter
      error
      store_test_modification_map
      store_potential_side_effects
      covering_classes
      init_cv_modification_side_effects
  in
  (*---------------------------------------------------------------------------*)
  (*fold 2 map*)
  Int2Map_CV_Modif.Map.fold2
    parameter
    error
    (*exists in 'a t*)
    (fun parameter error (agent_type, cv_id) (_, rule_id_set) store_result ->
      let error, store_result =
        add_link error (agent_type, cv_id) rule_id_set store_result
      in
      error, store_result
    )
    (*exists in 'b t*)
    (fun parameter error (agent_type, cv_id) (_, rule_id_set) store_result ->
      let error, store_result =
        add_link error (agent_type, cv_id) rule_id_set store_result
      in
      error, store_result
    )
    (*both*)
    (fun parameter error (agent_type, cv_id) (_, s1) (_, s2) store_result ->
      let error, union_set =
        Site_map_and_set.Set.union parameter error s1 s2
      in
      let error, store_result =
        add_link error (agent_type, cv_id) union_set store_result
      in
      error, store_result
    )
    store_update_modification
    store_update_with_side_effects
    store_result

(************************************************************************************)

let scan_rule_dynamic parameter error rule_id rule compiled
    handler_bdu
    covering_classes
    store_covering_classes_id
    store_potential_side_effects
    store_pre_static
    store_result 
    =
  let error, store_update =
    store_update
      parameter
      error
      store_pre_static.Bdu_static_views.store_test_modif_map
      store_potential_side_effects
      store_covering_classes_id
      covering_classes
      store_result.store_update
  in
  error, handler_bdu,
  {
    store_update = store_update
  }

(************************************************************************************)

let init_bdu_analysis_dynamic =
  let init_bdu_analysis_dynamic =
    {
      store_update  = Int2Map_CV_Modif.Map.empty
    }
  in
  init_bdu_analysis_dynamic

(************************************************************************************)
(*rules*)

let scan_rule_set_dynamic parameter error compiled handler_bdu
    store_pre_static
    covering_classes
    store_covering_classes_id
    store_potential_side_effects =
  let error, (handler_bdu, store_result) =
    Int_storage.Nearly_inf_Imperatif.fold parameter error
      (fun parameter error rule_id rule (handler_bdu, store_result) ->
        let error, handler_bdu, store_result =
          scan_rule_dynamic
            parameter
            error
            rule_id
            rule.Cckappa_sig.e_rule_c_rule
            compiled
            handler_bdu
            covering_classes
            store_covering_classes_id
            store_potential_side_effects
            store_pre_static
            store_result
        in
        error, (handler_bdu, store_result)
      ) compiled.Cckappa_sig.rules (handler_bdu, init_bdu_analysis_dynamic)
  in
  error, (handler_bdu, store_result)