val on_message :
  Api.manager -> (string -> unit Lwt.t) -> string -> unit Lwt.t

class virtual manager : ?timeout:float -> unit -> object
    method virtual post_message : string -> unit
    method virtual sleep : float -> unit Lwt.t
    method receive : string -> unit
    inherit Api.manager
  end

val message_delimter : char
