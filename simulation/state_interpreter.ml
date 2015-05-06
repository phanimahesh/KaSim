type t = {
  stopping_times : (Nbr.t * int) list ref;
  perturbations_alive : bool array;
  activities : Random_tree.tree;
  variables_overwrite: Expr.alg_expr option array;
}

let initial env counter graph stopping_times =
  let activity_tree =
    Random_tree.create (NamedDecls.size env.Environment.rules) in
  let initial_value e =
    Nbr.to_float
      (Rule_interpreter.value_alg
	 ~get_alg:(fun i -> fst (snd env.Environment.algs.NamedDecls.decls.(i)))
	 counter graph e) in
  let () =
    Array.iteri
      (fun i (_,r) ->
       Random_tree.add i (initial_value r.Primitives.rate) activity_tree)
      env.Environment.rules.NamedDecls.decls in
  let stops =
    ref (List.sort (fun (a,_) (b,_) -> Nbr.compare a b) stopping_times) in
  {
    stopping_times = stops;
    perturbations_alive =
      Array.make (Array.length env.Environment.perturbations) true;
    activities = activity_tree;
    variables_overwrite =
      Array.make (NamedDecls.size env.Environment.algs) None;
}

let get_alg env state i =
  match state.variables_overwrite.(i) with
  | None -> fst (snd env.Environment.algs.NamedDecls.decls.(i))
  | Some expr -> expr

let do_it env domain counter graph state = function
  | Primitives.ITER_RULE ((v,_),_,r) ->
     let get_alg i = get_alg env state i in
     let n = Rule_interpreter.value_alg counter graph ~get_alg v in
     (false,
      Nbr.iteri
	(fun _ g ->
	 fst (Rule_interpreter.force_rule ~get_alg domain counter g r))
	graph n,state)
  | Primitives.UPDATE (va,(expr,_)) ->
     let () =
       match va with
       | Term.ALG i -> state.variables_overwrite.(i) <- Some expr
       | (Term.TIME | Term.EVENT | Term. KAPPA _ | Term.TOK _ | Term.RULE _
	  | Term.PERT _ | Term.ABORT _) ->
	  failwith "Problematic update perturbation" in
     (false, graph, state)
  | Primitives.STOP pexpr ->
     let get_alg i = get_alg env state i in
     let file =
       Format.asprintf
	 "@[<h>%a@]" (Kappa_printer.print_expr_val
			env (fun _ ->
			     Rule_interpreter.value_alg counter graph ~get_alg))
	 pexpr in
     let () =
       Kappa_files.with_snapshot
	 file (Mods.Counter.event counter) "ka"
	 (fun f -> Rule_interpreter.print env f graph) in
     (true,graph,state)
(*     raise (ExceptionDefn.StopReached
	      (Format.sprintf
		 "STOP instruction was satisfied at (%d e,%f t.u)"
		 (Mods.Counter.event counter) (Mods.Counter.time counter))) *)
  | Primitives.PRINT (pe_file,pe_expr) ->
     let get_alg i = get_alg env state i in
     let file =
       Format.asprintf
	 "@[<h>%a@]" (Kappa_printer.print_expr_val
			env (fun _ ->
			     Rule_interpreter.value_alg counter graph ~get_alg))
	 pe_file in
     let desc =
       match file with "" -> Format.std_formatter
		     | _ -> Environment.get_desc file env in
     let () =
       Format.fprintf
	 desc "%a@." (Kappa_printer.print_expr_val
			env (fun _ ->
			     Rule_interpreter.value_alg counter graph ~get_alg))
	 pe_expr in
     (false, graph, state)
  | Primitives.PLOTENTRY -> (false, graph, state)
  | Primitives.SNAPSHOT pexpr  ->
     let get_alg i = get_alg env state i in
     let file =
       Format.asprintf
	 "@[<h>%a@]" (Kappa_printer.print_expr_val
			env (fun _ ->
			     Rule_interpreter.value_alg counter graph ~get_alg))
	 pexpr in
     let () =
       Kappa_files.with_snapshot
	 file (Mods.Counter.event counter) "ka"
	 (fun f -> Rule_interpreter.print env f graph) in
     (false, graph, state)
  | Primitives.CFLOW _ -> (false, graph, state)
  | Primitives.CFLOWOFF _ -> (false, graph, state)
  | Primitives.FLUX _ -> (false, graph, state)
  | Primitives.FLUXOFF _ -> (false, graph, state)

let update_activity get_alg env counter graph state =
  Array.iteri
    (fun i (_,rule) ->
     let rate = Rule_interpreter.value_alg counter graph ~get_alg
					   rule.Primitives.rate in
     let cc_exp =
       Expr.KAPPA_INSTANCE (-3,[rule.Primitives.connected_components]) in
     let act =
       Nbr.mult
	 rate (Rule_interpreter.value_alg counter graph ~get_alg cc_exp) in
     Random_tree.add i (Nbr.to_float act) state.activities)
    env.Environment.rules.NamedDecls.decls

let perturbate env domain counter graph state =
  let get_alg i = get_alg env state i in
  let rec do_until_noop i graph state stop =
    if stop || i >= Array.length env.Environment.perturbations then
     let () = update_activity get_alg env counter graph state in
      (stop,graph,state)
    else
      let pert = env.Environment.perturbations.(i) in
      if state.perturbations_alive.(i) &&
	   Rule_interpreter.value_bool
	     counter graph ~get_alg pert.Primitives.precondition
      then
	let stop,graph,state =
	  List.fold_left (fun (stop,graph,state as acc) effect ->
			  if stop then acc else
			    do_it env domain counter graph state effect)
			 (stop,graph,state) pert.Primitives.effect in
	let () =
	  state.perturbations_alive.(i) <-
	    match pert.Primitives.abort with
	    | None -> false
	    | Some ex ->
	       not (Rule_interpreter.value_bool counter graph ~get_alg ex) in
	do_until_noop 0 graph state stop
      else
	do_until_noop (succ i) graph state stop in
  do_until_noop 0 graph state false

let one_rule env domain counter graph state =
  let rule_id,_ = Random_tree.random state.activities in
  let _,rule = env.Environment.rules.NamedDecls.decls.(rule_id) in
  let get_alg i = get_alg env state i in
  match Rule_interpreter.apply_rule ~get_alg domain counter graph rule with
  | None -> None
  | Some graph' ->
     let () = update_activity get_alg env counter graph state in
     Some (graph',state)

let a_loop env domain counter graph state =
  let activity = Random_tree.total state.activities in
  let rd = Random.float 1.0 in
  let dt = abs_float (log rd /. activity) in
  match !(state.stopping_times) with
  | (ti,_) :: tail
       when Nbr.is_smaller ti (Nbr.F (Mods.Counter.time counter +. dt)) ->
     let () = state.stopping_times := tail in
     let () = counter.Mods.Counter.time <- Nbr.to_float ti in
     perturbate env domain counter graph state
  | _ ->
     let (stop,graph',state') =
       perturbate env domain counter graph state in
     match one_rule env domain counter graph' state' with
     | None ->
	(Mods.Counter.one_null_event counter dt||stop,graph',state')
     | Some (graph'',state'') ->
	(Mods.Counter.one_constructive_event counter dt||stop,graph'',state'')