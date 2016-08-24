open Lwt.Infix
module ApiTypes = ApiTypes_j

let msg_process_not_running =
  "process not running"
let msg_token_not_found =
  "token not found"
let msg_observables_less_than_zero =
  "Plot observables must be greater than zero"

let () = Printexc.record_backtrace true

type runtime =
  < parse : ApiTypes.code -> ApiTypes.parse ApiTypes.result Lwt.t;
    start : ApiTypes.parameter -> ApiTypes.token ApiTypes.result Lwt.t;
    status : ApiTypes.token -> ApiTypes.state ApiTypes.result Lwt.t;
    list : unit -> ApiTypes.catalog ApiTypes.result Lwt.t;
    stop : ApiTypes.token -> unit ApiTypes.result Lwt.t;
  >;;

module Base : sig

  class virtual runtime :
    float -> object
      method parse : ApiTypes.code -> ApiTypes.parse ApiTypes.result Lwt.t
      method start : ApiTypes.parameter -> ApiTypes.token ApiTypes.result Lwt.t
      method status : ApiTypes.token -> ApiTypes.state ApiTypes.result Lwt.t
      method list : unit -> ApiTypes.catalog ApiTypes.result Lwt.t
      method stop : ApiTypes.token -> unit ApiTypes.result Lwt.t
      method virtual log : ?exn:exn -> string -> unit Lwt.t
      method virtual yield : unit -> unit Lwt.t
    end;;
end = struct
  module IntMap = Mods.IntMap
  type simulator_state =
    { switch : Lwt_switch.t
    ; counter : Counter.t
    ; log_buffer : Buffer.t
    ; plot : ApiTypes.plot ref
    ; distances : ApiTypes.distances ref
    ; snapshots : ApiTypes.snapshot list ref
    ; flux_maps : ApiTypes.flux_map list ref
    ; files : ApiTypes.file_line list ref
    ; error_messages : ApiTypes.errors ref
    ; contact_map : Primitives.contact_map
    ; env : Environment.t
    ; domain : Connected_component.Env.t
    ; mutable graph : Rule_interpreter.t
    ; mutable state : State_interpreter.t
    }
  type context = { states : simulator_state IntMap.t
                 ; id : int }

  let format_error_message (message,linenumber) =
    Format.sprintf "Error at %s : %s"
      (Location.to_string linenumber)
      message
  let build_ast
      (code : string)
      yield
      (log : ?exn:exn -> string -> unit Lwt.t) =
    let lexbuf : Lexing.lexbuf = Lexing.from_string code in
    Lwt.catch
      (fun () ->
         (Lwt.wrap3 KappaParser.start_rule KappaLexer.token
            lexbuf Ast.empty_compil) >>=
         (fun raw_ast ->
            (yield ()) >>=
            (fun () ->
               (Lwt.wrap2 LKappa.compil_of_ast [] raw_ast) >>=
               (fun (sigs,_,_,_ as ast :
                                Signature.s * unit NamedDecls.t * int list *
                                (Ast.agent,
                                 LKappa.rule_agent list,
                                 int,
                                 LKappa.rule) Ast.compil) ->
                 (yield ()) >>=
                 (fun () ->
                    (Lwt.wrap3
                       Eval.init_kasa
                       Remanent_parameters_sig.JS
                       sigs
                       raw_ast) >>=
                    (fun (contact_map,_kasa_state) ->
                       Lwt.return (`Right (ast,contact_map))))))))
      (function
          ExceptionDefn.Syntax_Error e ->
          Lwt.return
            (`Left
               (Api_data.api_location_errors e))
        | ExceptionDefn.Malformed_Decl e ->
          Lwt.return
            (`Left
               (Api_data.api_location_errors e))
        | exn -> log ~exn "" >>=
          (fun () -> Lwt.fail exn))

  class virtual runtime min_run_duration =
    object(self)

      val mutable lastyield = Sys.time ()
      method virtual log : ?exn:exn -> string -> unit Lwt.t
      method virtual yield : unit -> unit Lwt.t
      val mutable context = { states = IntMap.empty
                            ; id = 0 }
      (* not sure if this is good *)
      val start_time : float = Sys.time ()

      method private time_yield () =
        let t = Sys.time () in
        if t -. lastyield > min_run_duration then
          let () = lastyield <- t in
          self#yield ()
        else Lwt.return_unit

      method parse
          (code : ApiTypes.code) : ApiTypes.parse ApiTypes.result Lwt.t =
        Lwt.bind
          (build_ast code self#time_yield self#log)
          (function
            | `Right ((sigs,_,_,_),contact_map) ->
              Lwt.return
                (`Right
                   { ApiTypes.contact_map =
                       Api_data.api_contact_map sigs contact_map })
            | `Left e -> Lwt.return (`Left e))

      method private new_id () : int =
        let result = context.id + 1 in
        let () = context <- { context with id = context.id + 1 } in
        result

      method start
          (parameter : ApiTypes.parameter) :
        ApiTypes.token ApiTypes.result Lwt.t =
        if parameter.ApiTypes.nb_plot > 0 then
          let current_id = self#new_id () in
          let plot : ApiTypes.plot ref =
            ref { ApiTypes.legend = []
                ; ApiTypes.time_series = [] }
          in
          let distances : ApiTypes.distances ref = ref [] in
          let error_messages : ApiTypes.errors ref = ref [] in
          let snapshots : ApiTypes.snapshot list ref = ref [] in
          let flux_maps : ApiTypes.flux_map list ref = ref [] in
          let files : ApiTypes.file_line list ref = ref [] in
          let simulation_log_buffer = Buffer.create 512 in
          let log_form =
            Format.formatter_of_buffer simulation_log_buffer in
          let outputs sigs =
            function
            | Data.Flux flux_map ->
              flux_maps := ((Api_data.api_flux_map flux_map)::!flux_maps)
            | Data.Plot (time,new_observables) ->
              let new_values =
                List.map (fun nbr -> Nbr.to_float nbr)
                  (Array.to_list new_observables) in
              plot := {!plot with ApiTypes.time_series =
                                    { ApiTypes.time = time ;
                                      values = new_values }
                                    :: !plot.ApiTypes.time_series }
            | Data.Print file_line ->
              files := ((Api_data.api_file_line file_line)::!files)
            | Data.Snapshot snapshot ->
              snapshots := ((Api_data.api_snapshot sigs snapshot)::!snapshots)
            | Data.UnaryDistances unary_distances ->
              distances :=
                let (one_big_list,_) =
                  Array.fold_left
                    (fun (l,i) a ->
                       match a with
                       | Some ls ->
                         let add_rule_id =
                           List.map
                             (fun (t,d) ->
                                {ApiTypes.rule_dist =
                                   unary_distances.Data.distances_rules.(i);
                                 ApiTypes.time_dist = t;
                                 ApiTypes.dist = d}) ls
                         in (List.append l add_rule_id, i+1)
                       | None -> (l, i+1))
                    ([],0) unary_distances.Data.distances_data in
                one_big_list
            | Data.Log s ->
              Format.fprintf log_form "%s@." s in
          Lwt.catch
            (fun () ->
               (build_ast parameter.ApiTypes.code self#time_yield self#log) >>=
               (function
                   `Right ((sig_nd,tk_nd,updated_vars,result) ,contact_map) ->
                   let simulation_counter =
                     Counter.create
                       ~init_t:(0. : float)
                       ~init_e:(0 : int)
                       ?max_t:parameter.ApiTypes.max_time
                       ?max_e:parameter.ApiTypes.max_events
                       ~nb_points:(parameter.ApiTypes.nb_plot : int) in
                   Eval.compile
                     ~pause:(fun f -> Lwt.bind (self#time_yield ()) f)
                     ~return:Lwt.return ?rescale_init:None
                     ~outputs:(outputs (Signature.create []))
                     sig_nd tk_nd contact_map
                     simulation_counter result >>=
                   (fun (env,domain,has_tracking,
                         store_distances,_,init_l) ->
                     let simulation =
                       { switch = Lwt_switch.create ()
                       ; counter = simulation_counter
                       ; log_buffer = simulation_log_buffer
                       ; plot = plot
                       ; distances = distances
                       ; error_messages = error_messages
                       ; snapshots = snapshots
                       ; flux_maps = flux_maps
                       ; files = files
                       ; contact_map = contact_map
                       ; env = env
                       ; domain = domain
                       ; graph = Rule_interpreter.empty ~store_distances env
                       ; state = State_interpreter.empty env [] []
                       } in
                     let () =
                       context <-
                         { context with
                           states =
                             IntMap.add current_id simulation context.states } in
                     let () =
                       Lwt.async
                          (fun () ->
                             Lwt.catch (fun () ->
                                 let story_compression =
                                   Tools.option_map
                                     (fun  _ -> ((false,false,false),true))
                                     has_tracking
                                 in
                                 Eval.build_initial_state
                                   ~bind:(fun x f ->
                                       (self#time_yield ()) >>= (fun () -> x >>= f))
                                   ~return:Lwt.return [] simulation_counter
                                   env domain story_compression
                                   store_distances init_l >>=
                                 (fun (graph,state) ->
                                    let () = simulation.graph <- graph;
                                      simulation.state <- state in
                                    let () = ExceptionDefn.flush_warning log_form in
                                    let sigs = Environment.signatures env in
                                    let legend =
                                      Environment.map_observables
                                        (Format.asprintf
                                           "%a"
                                           (Kappa_printer.alg_expr ~env))
                                        env in
                                    let () =
                                      plot :=
                                        { !plot
                                          with ApiTypes.legend = Array.to_list legend}
                                    in
                                    let rstop = ref false in
                                    let rec iter () =
                                      let () =
                                        while (not !rstop) &&
                                              Sys.time () -. lastyield < min_run_duration do
                                          let (stop,graph',state') =
                                            State_interpreter.a_loop
                                              ~outputs:(outputs sigs)
                                              env domain simulation.counter
                                              simulation.graph simulation.state in
                                          rstop := stop;
                                          simulation.graph <- graph';
                                          simulation.state <- state'
                                        done in
                                      if !rstop then
                                        (Lwt_switch.turn_off simulation.switch)
                                        >>= (fun () -> Lwt.return_unit)
                                      else
                                      if Lwt_switch.is_on simulation.switch
                                      then (let () = lastyield <- Sys.time () in
                                            self#yield ()) >>= iter
                                      else Lwt.return_unit in
                                    (iter ()) >>=
                                    (fun () ->
                                       let _ =
                                         State_interpreter.end_of_simulation
                                           ~outputs:(outputs sigs) log_form env
                                           simulation.counter simulation.graph
                                           simulation.state in
                                       Lwt.return_unit)))
                               (function
                                 | ExceptionDefn.Internal_Error error as exn ->
                                   let () = error_messages :=
                                       (Api_data.api_location_errors error)
                                   in
                                   self#log ~exn ""
                                 | Invalid_argument error as exn ->
                                   let () = error_messages :=
                                       (Api_data.api_message_errors ("Runtime error "^ error))
                                   in
                                   self#log ~exn ""
                                 | exn ->
                                   let () = error_messages :=
                                       (Api_data.api_message_errors (Printexc.to_string exn)) in
                                   self#log ~exn ""
                               )) in
                     Lwt.return (`Right current_id))
                 | `Left _ as out -> Lwt.return out))
            (function
              | ExceptionDefn.Malformed_Decl error ->
                Lwt.return (`Left (Api_data.api_location_errors error))
              | ExceptionDefn.Internal_Error error ->
                Lwt.return (`Left (Api_data.api_location_errors error))
              | Invalid_argument error ->
                Lwt.return (`Left (Api_data.api_message_errors ("Runtime error "^ error)))
              | exn ->
                Lwt.return (`Left (Api_data.api_message_errors (Printexc.to_string exn))))
        else
          Api_data.lwt_msg msg_observables_less_than_zero

      method status
          (token : ApiTypes.token) : ApiTypes.state ApiTypes.result Lwt.t =
        Lwt.catch
          (fun () ->
             match IntMap.find_option token context.states with
             | None ->
               Api_data.lwt_msg msg_token_not_found
             | Some state ->
               let () =
                 if not (Lwt_switch.is_on state.switch) then
                   context <-
                     { context with states = IntMap.remove token context.states }
               in
               Lwt.return
                 (match !(state.error_messages) with
                    [] ->
                    `Right
                      ({ ApiTypes.plot =
                           Some !(state.plot);
                         ApiTypes.distances =
                           Some !(state.distances);
                         ApiTypes.time =
                           Counter.time state.counter;
                         ApiTypes.time_percentage =
                           Counter.time_percentage state.counter;
                         ApiTypes.event =
                           Counter.event state.counter;
                         ApiTypes.event_percentage =
                           Counter.event_percentage state.counter;
                         ApiTypes.tracked_events =
                           Counter.tracked_events state.counter;
                         ApiTypes.log_messages =
                           [Buffer.contents state.log_buffer] ;
                         ApiTypes.snapshots =
                           !(state.snapshots);
                         ApiTypes.flux_maps =
                           !(state.flux_maps);
                         ApiTypes.files =
                           !(state.files);
                         is_running =
                           Lwt_switch.is_on state.switch
                       } : ApiTypes.state )
                  | _ ->
                    `Left !(state.error_messages)
                 )
          )
          (fun exn ->
             (self#log ~exn "")
             >>=
             (fun _ -> Api_data.lwt_msg (Printexc.to_string exn))
          )
      method list () : ApiTypes.catalog ApiTypes.result Lwt.t =
        Lwt.return (`Right (List.map fst (IntMap.bindings context.states)))

      method stop (token : ApiTypes.token) : unit ApiTypes.result Lwt.t =
        Lwt.catch
          (fun () ->
             match IntMap.find_option token context.states with
             | None -> Api_data.lwt_msg msg_token_not_found
             | Some state ->
               if Lwt_switch.is_on state.switch then
                 Lwt_switch.turn_off state.switch
                 >>= (fun _ -> Lwt.return (`Right ()))
               else
                 Api_data.lwt_msg msg_process_not_running)
          (fun e -> Api_data.lwt_msg (Printexc.to_string e))

    end;;

end;;
