module UIState = Ui_state
module ApiTypes = Api_types_v1_j
module Html = Tyxml_js.Html5
module R = Tyxml_js.R

open ApiTypes

type simulation_limit = TIME_LIMIT | EVENTS_LIMIT
let simulation_limit_to_string : simulation_limit -> string =
    function
    | TIME_LIMIT -> "time"
    | EVENTS_LIMIT -> "event"
let string_to_simulation_limit : string -> simulation_limit option =
    function
    | "time" -> Some TIME_LIMIT
    | "event" -> Some EVENTS_LIMIT
    |  _ -> None

let signal_simulation_limit, set_simulation_limit = React.S.create TIME_LIMIT
let signal_simulation_value, set_simulation_value = React.S.create ""
(*  event update *)
let _ = React.S.map
           (fun x ->
              match React.S.value signal_simulation_limit with
              | TIME_LIMIT -> ()
              | EVENTS_LIMIT ->
                (match x with
                 | Some va -> set_simulation_value (string_of_int va)
                 | None -> ()))
           UIState.model_max_events

let _ = React.S.map
           (fun x ->
              match React.S.value signal_simulation_limit with
            | TIME_LIMIT ->
              (match x with
               | None -> ()
               | Some value ->
                 let value = string_of_float value in
                 let format_float n =
                   let length = String.length n in
                   if length > 0 && String.get n (length - 1) = '.' then
                     n^"0"
                   else
                     n
                 in
                 let value = format_float value in
                 set_simulation_value value)
            | EVENTS_LIMIT ->

              ())
           UIState.model_max_time

let simulation_limit_id = "simulation_limit"
let simulation_limit_input =
  Html.input
    ~a:[Html.a_id simulation_limit_id ;
        Html.a_input_type `Number;
        Html.a_class ["form-control"];
        Tyxml_js.R.Html.a_placeholder
          (React.S.l1
             (function
               | TIME_LIMIT -> "time limit"
               | EVENTS_LIMIT -> "max number")
             signal_simulation_limit
          ) ;
        Tyxml_js.R.Html.a_value signal_simulation_value;
       ]
    ()

let simulation_limit_selector_id = "simulation_limit_selector"
let simulation_limit_selector =
  let option value =
    (* to ensure mapping of limit type only happens in on location *)
    let label = simulation_limit_to_string value in
    Html.option ~a:[ Html.a_value label ] (Html.pcdata label)
  in
  Html.select
    ~a:[Html.a_id simulation_limit_selector_id ; ]
    (List.map option [ TIME_LIMIT ; EVENTS_LIMIT ; ])


let plot_points_id = "plot_points"
let plot_points_input =
  Html.input
    ~a:[Html.a_id plot_points_id;
        Html.a_input_type `Number;
        Html.Unsafe.int_attrib "min" 1 ;
        Html.a_class [ "form-control" ];
        Html.a_placeholder "Expected number";
        Tyxml_js.R.Html.a_value
          (React.S.l1 string_of_int UIState.model_nb_plot)]
    ()

let perturbation_code_id = "perturbation_code"
let perturbation_code_input =
  Html.input
    ~a:[Html.a_id perturbation_code_id;
        Html.a_input_type `Text;
        Html.a_class ["form-control"];
        Html.a_placeholder "Simulation Perturbation";]
    ()

let signal_change id signal_handler =
  let input_dom : Dom_html.inputElement Js.t =
    Js.Unsafe.coerce
      ((Js.Opt.get (Ui_common.document##getElementById (Js.string id))
          (fun () -> assert false))
       : Dom_html.element Js.t) in
  input_dom##.onchange :=
    Dom_html.handler
      (fun _ ->
         let () =
           signal_handler
             (Js.to_string
                (input_dom##.value))
         in Js._true)

let error_messages signal =
  Html.div
    ~a:[Html.a_class ["panel-heading" ;
                      "panel-pre" ;
                      "panel-message" ;] ]
    [Tyxml_js.R.Html.pcdata
       (React.S.bind
          signal
          (fun error ->
             React.S.const
               (match error with
                | [] -> ""
                | h::_ -> h.ApiTypes.message
               )
          )
       )
    ]

let start_button_id = "start_button"
let start_button =
  Html.button
    ~a:([ Html.a_id start_button_id ;
          Html.Unsafe.string_attrib "type" "button" ;
          Html.a_class [ "btn" ;
                         "btn-default" ; ] ; ])
    [ Html.cdata "start" ]

let clear_button_id = "clear_button"
let clear_button =
  Html.button
    ~a:[ Html.a_id clear_button_id
       ; Html.Unsafe.string_attrib "type" "button"
       ; Html.a_class ["btn" ;
                       "btn-default" ; ] ]
    [ Html.cdata "clear" ]

let pause_button_id = "pause_button"
let pause_button =
  Html.button
    ~a:[ Html.a_id pause_button_id
       ; Html.Unsafe.string_attrib "type" "button"
       ; Html.a_class ["btn" ;
                       "btn-default" ; ] ]
    [ Html.cdata "pause" ]

let continue_button_id = "continue_button"
let continue_button =
  Html.button
    ~a:[ Html.a_id continue_button_id
       ; Html.Unsafe.string_attrib "type" "button"
       ; Html.a_class ["btn" ;
                       "btn-default" ; ] ]
    [ Html.cdata "continue" ]

let perturbation_button_id = "perturbation_button"
let perturbation_button =
  Html.button
    ~a:[ Html.a_id perturbation_button_id
       ; Html.Unsafe.string_attrib "type" "button"
       ; Html.a_class ["btn" ;
                       "btn-default" ; ] ]
    [ Html.cdata "perturbation" ]

let select_default_runtime = [ UIState.WebWorker ;
                               UIState.Embedded ; ]
let select_runtime_options, select_runtime_options_handle =
  ReactiveData.RList.create select_default_runtime
let select_runtime =
  Tyxml_js.R.Html.select
    (ReactiveData.RList.map
       (fun runtime -> Html.option
           ~a:[Html.a_value
                 (UIState.runtime_value runtime)]
           (Html.pcdata (UIState.runtime_label runtime)))
       select_runtime_options)

let hidden_class = ["hidden"]
let visible_class = ["visible"]
let visible_on_states
    (t : Ui_simulation.t)
    ?(a_class=[])
    (state : Ui_simulation.simulation_status list) : string list React.signal =
  (React.S.bind
     (Ui_simulation.simulation_status t)
     (fun run_state ->
        React.S.const
          (if List.mem run_state state then
             a_class@visible_class
           else
             a_class@hidden_class)
     )
  )

let progress_bar
    (percent_signal : int Tyxml_js.R.Html.wrap)
    (value_signal : string React.signal) =
  Html.div
    ~a:[ Html.Unsafe.string_attrib "role" "progressbar" ;
         Tyxml_js.R.Html.Unsafe.int_attrib "aria-valuenow" percent_signal ;
         Html.Unsafe.int_attrib "aria-valuemin" 0 ;
         Html.Unsafe.int_attrib "aria-valuemax" 100 ;
         Tyxml_js.R.Html.Unsafe.string_attrib
           "style"
           (React.S.map
              (fun s -> Format.sprintf "width: %d%%;" s)
              percent_signal) ;
         Html.a_class ["progress-bar"] ]
    [ Tyxml_js.R.Html.pcdata
        (React.S.bind
           value_signal
           (fun value -> React.S.const value)
        )
    ]

let lift f x = match x with | None -> None | Some x -> f x
let default x d = match x with | None -> d | Some x -> x
let time_progress_bar  (t : Ui_simulation.t) =
  let simulation_output = (Ui_simulation.simulation_output t) in
  progress_bar
    (React.S.map (fun state ->
         let time_percent : int option =
           lift
             (fun (state : ApiTypes.state) -> state.time_percentage)
             state
         in
         let time_percent : int = default time_percent 0 in
         time_percent
       )
        simulation_output)
    (React.S.map (fun state ->
         let time : float option = lift (fun (state : ApiTypes.state) ->
             Some state.time) state in
         let time : float = default time 0.0 in
         string_of_float time
       )
       simulation_output)

let event_progress_bar (t : Ui_simulation.t) =
  let simulation_output = (Ui_simulation.simulation_output t) in
  progress_bar
    (React.S.map (fun state ->
         let event_percentage : int option =
           lift (fun (state: ApiTypes.state) -> state.event_percentage) state in
         let event_percentage : int = default event_percentage 0 in
         event_percentage
       )
       simulation_output)
    (React.S.map (fun state ->
         let event : int option =
           lift (fun (state : ApiTypes.state) -> Some state.event)
             state
         in
         let event : int = default event 0 in
         string_of_int event
       )
        simulation_output)

let tracked_events state =
  let tracked_events : int option =
    lift (fun (state : ApiTypes.state) -> state.tracked_events)
      state
  in
  match tracked_events with
    None -> None
  | Some tracked_events ->
    if tracked_events > 0 then
      Some tracked_events
    else
      None

let tracked_events_count (t : Ui_simulation.t) =
  let simulation_output = (Ui_simulation.simulation_output t) in
  Tyxml_js.R.Html.pcdata
    (React.S.map (fun state -> match tracked_events state with
           Some tracked_events -> string_of_int tracked_events
         | None -> " "
       )
        simulation_output)

let tracked_events_label (t : Ui_simulation.t) =
  let simulation_output = (Ui_simulation.simulation_output t) in
  Tyxml_js.R.Html.pcdata
    (React.S.map (fun state -> match tracked_events state with
           Some _ -> "tracked events"
         | None -> " "
       )
        simulation_output)

let simulation_messages = error_messages UIState.model_error
let status_indicator (t : Ui_simulation.t) =
  Html.div
    ~a:[ Html.a_class [ "col-md-2" ] ]
    (Ui_common.level
    ~debug:(Tyxml_js.R.Html.pcdata
              (React.S.bind
                 (Ui_simulation.simulation_status t)
                 (fun status ->
                    React.S.const
                      (match status with
                       | Ui_simulation.STOPPED -> "stopped"
                       | Ui_simulation.INITALIZING -> "initalizing"
                       | Ui_simulation.RUNNING -> "running"
                       | Ui_simulation.PAUSED -> "paused"
                      )
                 )
              )) ())

let perturbation_control (t : Ui_simulation.t) =
  Html.div
    ~a:[ Tyxml_js.R.Html.a_class
           (visible_on_states t ~a_class:["row"] [Ui_simulation.PAUSED]) ]
    [Html.div ~a:[Html.a_class [ "col-md-10" ]] [ perturbation_code_input ] ;
     Html.div ~a:[Html.a_class [ "col-md-2"  ]] [ perturbation_button ] ; ]
let initializing_xml (t : Ui_simulation.t) =
  Html.div
    ~a:[ Tyxml_js.R.Html.a_class
           (visible_on_states t [ Ui_simulation.INITALIZING ; ])
       ]
  [[%html {|
  <div class="panel-body panel-controls">
    |}[ Html.entity "nbsp" ]{|
  </div>|}]]

let alert_messages =
  Html.div
    ~a:[Tyxml_js.R.Html.a_class
          (React.S.bind
             UIState.model_error
             (fun error ->
                React.S.const
                  (match error with
                   | [] -> [ "alert-sm" ; "alert" ; ]
                   | _::_ -> [ "alert-sm" ; "alert" ; "alert-danger" ; ]
                  )
             )
          );
       ]
    [Tyxml_js.R.Html.pcdata
       (React.S.bind
          UIState.model_error
          (fun error ->
             React.S.const
               (match error with
                | [] -> ""
                | h::_ -> h.ApiTypes.message
               )
          )
       )
    ]

let stopped_xml (t : Ui_simulation.t) =
  Html.div
    ~a:[ Tyxml_js.R.Html.a_class
           (visible_on_states
              ~a_class:[ "panel-body" ;
                         "panel-controls" ; ]
              t
              [Ui_simulation.STOPPED ;
               Ui_simulation.PAUSED ; ])
       ]
  [%html {|
     <div class="row">
        <div class="col-md-2">
           |}[ simulation_limit_input ]{|
        </div>
        <div class="col-md-1">
           |}[ simulation_limit_selector ]{|
        </div>
        <div class="col-md-9">|}[ alert_messages ]{|</div>
     </div>


      |}[ Html.div
            ~a:[ Tyxml_js.R.Html.a_class
                   (visible_on_states
                     t
                     ~a_class:[ "row" ]
                     [ Ui_simulation.STOPPED ; ]) ]
            [ Html.div
                ~a:[ Html.a_class [ "col-md-2" ] ]
                [ plot_points_input ] ;
              Html.div
                ~a:[ Html.a_class [ "col-md-1" ] ]
                [ Html.pcdata  "points" ] ; ]
        ]{|

     |}[ perturbation_control t ]{|
   |}]

let running_xml (t : Ui_simulation.t) =
  Html.div
    ~a:[ Tyxml_js.R.Html.a_class
           (visible_on_states
              ~a_class:[ "panel-body" ;
                         "panel-controls" ; ]
              t [ Ui_simulation.RUNNING ; ]) ]
  [%html {|
     <div class="row">
        <div class="col-md-4">
            <div class="progress">
            |}[ event_progress_bar t ]{|
            </div>
        </div>
        <div class="col-md-2">events</div>
     </div>

     <div class="row">
        <div class="col-md-4">
            <div class="progress">
            |}[ time_progress_bar t ]{|
            </div>
        </div>
        <div class="col-md-2">time</div>
     </div>

     <div class="row">
        <div class="col-md-4">
           |}[ tracked_events_count t ]{|
        </div>
        <div class="col-md-2">
           |}[ tracked_events_label t ]{|
        </div>
     </div>
   |}]
let controls_xml (t : Ui_simulation.t) =
  [Html.div
     ~a:[ Tyxml_js.R.Html.a_class
            (visible_on_states
               t
               ~a_class:[ "col-md-2" ]
               [ Ui_simulation.STOPPED ; ]) ]
     [ start_button ] ;
   Html.div
     ~a:[ Tyxml_js.R.Html.a_class
            (visible_on_states
               t
               ~a_class:[ "col-md-2" ]
               [ Ui_simulation.PAUSED ; ]) ]
     [ continue_button ] ;
   Html.div
            ~a:[ Tyxml_js.R.Html.a_class
                   (visible_on_states
                     t
                     ~a_class:[ "col-md-2" ]
                     [ Ui_simulation.RUNNING ; ]) ]
            [ pause_button ] ;
   status_indicator t ;
   Html.div
     ~a:[ Tyxml_js.R.Html.a_class
            (visible_on_states
               t
               ~a_class:[ "col-md-2" ]
               [ Ui_simulation.PAUSED ;
                 Ui_simulation.RUNNING ; ]) ]
     [ clear_button ] ;
   Html.div
     ~a:[ Tyxml_js.R.Html.a_class
            (visible_on_states
               t
               ~a_class:[ "col-md-2" ]
               [ Ui_simulation.STOPPED ; ]) ]
     [ select_runtime ] ;
   Html.entity "nbsp" ;

  ]
let footer_xml (t : Ui_simulation.t) =
  [%html {|
  <div class="panel-footer">
      |}[ Html.div
            ~a:[ Html.a_class [ "row"; ] ]
            (controls_xml t) ]{|
  </div>|}]

let configuration_id = "configuration-id"
let xml  (t : Ui_simulation.t) =
  Html.div
    ~a:[ Html.a_id configuration_id;
         R.Html.a_class
           (React.S.bind
              UIState.model_error
              (fun e -> React.S.const
                  ("panel" :: (match e with
                       | [] -> ["panel-default"]
                       | { severity = `Error ; _ }::_ -> ["panel-danger"]
                       | { severity = `Warning ; _ }:: _ -> ["panel-warning"]
                       | { severity = `Info ; _ }::_ -> ["panel-info"]
                     )))
           )]
    [ (* simulation_messages ; *)
      initializing_xml t ;
      stopped_xml t ;
      running_xml t ;
      footer_xml t ; ]

let onload (t : Ui_simulation.t) : unit =
  let perturbation_button_dom =
    Tyxml_js.To_dom.of_button perturbation_button
  in
  let select_runtime_dom =
    Tyxml_js.To_dom.of_select select_runtime
  in
  let start_button_dom =
    Tyxml_js.To_dom.of_button start_button
  in
  let pause_button_dom =
    Tyxml_js.To_dom.of_button pause_button
  in
  let clear_button_dom =
    Tyxml_js.To_dom.of_button clear_button
  in
  let continue_button_dom =
    Tyxml_js.To_dom.of_button continue_button
  in
  let perturb_button_dom =
    Tyxml_js.To_dom.of_button perturbation_button
  in
  let perturbation_code_input_dom =
    Tyxml_js.To_dom.of_input perturbation_code_input
  in
  let simulation_limit_selector_dom =
    Tyxml_js.To_dom.of_select simulation_limit_selector
  in

  let args = Url.Current.arguments in
  let set_runtime
      (runtime : Ui_state.runtime)
      (continuation : unit -> unit) =
    let r_val = Ui_state.runtime_value runtime in
    Ui_state.set_runtime_url
      r_val
      (fun success ->
         if success then
           select_runtime_dom##.value := Js.string r_val
         else
           continuation ())
  in
  let default_runtime () =
    set_runtime
      UIState.default_runtime
      (fun _ -> ())
  in
  let () =
    try
      let hosts = List.filter (fun (key,_) -> key = "host") args in
      let hosts : Ui_state.remote option list =
        List.map (fun (_,url) -> Ui_state.parse_remote url) hosts in
      let () = List.iter
          (fun value ->
             match value
             with
             | Some remote ->
               ReactiveData.RList.cons
                 (Ui_state.Remote remote)
                 select_runtime_options_handle
             | None -> ())
          hosts
      in
      match ReactiveData.RList.value select_runtime_options
      with
      | head::_ -> set_runtime head (default_runtime)
      | _ -> default_runtime ()
    with _ -> default_runtime () in
  let run_pertubation () : unit =
    Lwt_js_events.async
      (fun _ ->
         let code : string =
           Js.to_string perturbation_code_input_dom##.value
         in
         Ui_simulation.perturb_simulation t ~code:code)
  in
  let () = perturb_button_dom##.onclick :=
      Dom.handler
        (fun _ -> let () = run_pertubation () in Js._true)
  in
  let () =
    Common.input_enter
      ~id:perturbation_code_id
      ~handler:run_pertubation in
  let () = continue_button_dom##.onclick :=
      Dom.handler
        (fun _ ->
           let () =
             Lwt_js_events.async
               (fun _ -> Ui_simulation.continue_simulation t) in
           Js._true)
  in
  let () = pause_button_dom##.onclick :=
      Dom.handler
        (fun _ ->
           let () =
             Lwt_js_events.async
               (fun _ -> Ui_simulation.pause_simulation t) in
           Js._true)
  in
  let () = clear_button_dom##.onclick :=
      Dom.handler
        (fun _ ->
           let () =
             Lwt_js_events.async
               (fun _ -> Ui_simulation.stop_simulation t)
           in
           Js._true)
  in
  let () = start_button_dom##.onclick :=
      Dom.handler
        (fun _ ->
           let () = Lwt_js_events.async
               (fun _ -> Ui_simulation.start_simulation t) in
           Js._true)
  in
  let handle_simulation_limit_selector () =
    match string_to_simulation_limit
            (Js.to_string simulation_limit_selector_dom##.value)
    with
    | Some simulation_limit ->
      let () = Common.debug simulation_limit in
      let () =
        (let () = set_simulation_value "" in
         match simulation_limit with
         | TIME_LIMIT -> Ui_state.set_model_max_events None
         | EVENTS_LIMIT -> Ui_state.set_model_max_time None)
      in
      set_simulation_limit simulation_limit
    | None ->
      let () = Common.debug "handle_simulation_limit_selector" in
      failwith "handle_simulation_limit_selector"
  in
  let () = handle_simulation_limit_selector () in
  let () = simulation_limit_selector_dom ##.onchange :=
      Dom.handler
        (fun _ -> let () = handle_simulation_limit_selector () in
          Js._true)
  in
  let () = select_runtime_dom##.onchange :=
      Dom.handler
        (fun _ ->
           let () = UIState.set_runtime_url
               (Js.to_string select_runtime_dom##.value)
               (fun success ->
                  if success then
                    ()
                  else
                    select_runtime_dom##.value :=
                      Js.string
                        (UIState.runtime_value UIState.default_runtime)
               ) in
           Js._true
        )
  in
  let () = signal_change simulation_limit_id
      (fun value ->
         match React.S.value signal_simulation_limit with
         | TIME_LIMIT ->
           UIState.set_model_max_time
             (try Some (float_of_string value)
              with | Failure _ -> None)
         | EVENTS_LIMIT ->
           UIState.set_model_max_events
             (try Some (int_of_string value)
              with | Failure _ -> None)
      )
  in
  let () = signal_change plot_points_id
      (fun value ->
         try UIState.set_model_nb_plot (int_of_string value)
         with | Not_found | Failure _ -> ()) in
  let () = perturbation_button_dom##.onclick :=
      Dom.handler
        (fun _ ->
           let () = run_pertubation () in
           Js._true)
  in

  ()
let onresize (_ : Ui_simulation.t) : unit = ()
