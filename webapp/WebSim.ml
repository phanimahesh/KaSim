module ApiTypes = Api_types_v1_j

open Lwt
open Cohttp_lwt_unix
open Request
open Unix
open Lwt_log

let logger (handler : Cohttp_lwt_unix.Server.conn ->
            Cohttp.Request.t ->
            Cohttp_lwt_body.t ->
            (Cohttp.Response.t * Cohttp_lwt_body.t) Lwt.t)
    (conn : Cohttp_lwt_unix.Server.conn)
    (request : Cohttp.Request.t)
    (body : Cohttp_lwt_body.t)
  : (Cohttp.Response.t * Cohttp_lwt_body.t) Lwt.t =
  (Lwt.catch
     (fun () -> handler conn request body)
     (fun exn -> fatal ~exn "" >>=
       (fun () -> Lwt.fail exn))
  )
  >>=
  (fun (response,body) ->
     let ip : string =
       match fst conn with
         Conduit_lwt_unix.TCP {Conduit_lwt_unix.fd; _} ->
         (match Lwt_unix.getpeername fd with
          | Lwt_unix.ADDR_INET (ia,port) ->
            Printf.sprintf
              "%s:%d"
              (Ipaddr.to_string (Ipaddr_unix.of_inet_addr ia))
              port
          | Lwt_unix.ADDR_UNIX path -> Printf.sprintf "sock:%s" path)
       | Conduit_lwt_unix.Vchan _ | Conduit_lwt_unix.Domain_socket _ -> "unknown"
     in
     let t = Unix.localtime (Unix.time ()) in
     let request_method : string =
       Cohttp.Code.string_of_method request.meth
     in
     let uri : Uri.t = Request.uri request in
     let request_path : string = Uri.path uri in
     let response_code : string =
       Cohttp.Code.string_of_status
         response.Cohttp.Response.status
     in
     (Lwt_log_core.info_f
        "%s\t[%02d/%02d/%04d:%02d:%02d:%02d]\t\"%s %s\"\t%s"
        ip
        t.tm_mday t.tm_mon t.tm_year t.tm_hour t.tm_min t.tm_sec
        request_method
        request_path
        response_code)
     >>=
     (fun _ -> Lwt.return (response,body))
  )

let server =
  let common_args = Common_args.default in
  let app_args = App_args.default in
  let websim_args = Websim_args.default in
  let options = App_args.options app_args @
                Websim_args.options websim_args @
                Common_args.options common_args
  in
  let usage_msg : string = "kappa webservice" in
  let () = Arg.parse options (fun _ -> ()) usage_msg in
  let () = Printexc.record_backtrace common_args.Common_args.backtrace in
  let theSeed =
    match app_args.App_args.seed_value with
    | Some seed -> seed
    | None ->
      begin
        Lwt.ignore_result
          (Lwt_log_core.log
             ~level:Lwt_log_core.Info
             "+ Self seeding...@.");
        Random.self_init() ;
        Random.bits ()
      end
  in
  let () =
    Random.init theSeed ;
    Lwt.ignore_result
      (Lwt_log_core.log
	 ~level:Lwt_log_core.Info
         (Printf.sprintf
	    "+ Initialized random number generator with seed %d@."
            theSeed)
      )
  in
  let mode = match websim_args.Websim_args.cert_dir with
    | None -> `TCP (`Port websim_args.Websim_args.port)
    | Some dir ->
      `TLS (`Crt_file_path (dir^"cert.pem"),
	    `Key_file_path (dir^"privkey.pem"),
            `No_password,
	    `Port websim_args.Websim_args.port) in
  let route_handler :
    Cohttp_lwt_unix.Server.conn ->
    Cohttp.Request.t ->
    Cohttp_lwt_body.t ->
    (Cohttp.Response.t * Cohttp_lwt_body.t) Lwt.t
    = Webapp.route_handler
      ~shutdown_key:websim_args.Websim_args.shutdown_key
      ()
  in
  Server.create
    ~mode
    (Server.make
       ~callback:
       (logger
          (match websim_args.Websim_args.api with
	   | Websim_args.V1 -> Webapp_v1.handler
	      ~shutdown_key:websim_args.Websim_args.shutdown_key
           | Websim_args.V2 -> route_handler
	  )
       )
       ()
    )
let () = ignore (Lwt_main.run server)
