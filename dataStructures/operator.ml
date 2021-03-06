type bin_alg_op = MULT | SUM | DIV | MINUS | POW | MODULO | MIN | MAX
type un_alg_op = LOG | SQRT | EXP | SINUS | COSINUS | TAN | INT | UMINUS
type state_alg_op = CPUTIME | TIME_VAR | EVENT_VAR | NULL_EVENT_VAR
                  | TMAX_VAR | EMAX_VAR | PLOTNUM
type bool_op = AND | OR
type compare_op = GREATER | SMALLER | EQUAL | DIFF

type rev_dep = ALG of int | RULE of int | PERT of int

let bin_alg_op_to_string = function
  | MULT -> "*"
  | SUM -> "+"
  | DIV -> "/"
  | MINUS -> "-"
  | POW -> "^"
  | MODULO -> "[mod]"
  | MIN -> "[min]"
  | MAX -> "[max]"

let print_bin_alg_op f op =
  Format.fprintf f "%s" (bin_alg_op_to_string op)

let bin_alg_op_to_json op = `String (bin_alg_op_to_string op)
let bin_alg_op_of_json = function
  | `String "*" -> MULT
  | `String "+" -> SUM
  | `String "/" -> DIV
  | `String "-" -> MINUS
  | `String "^" -> POW
  | `String "[mod]" -> MODULO
  | `String "[min]" -> MIN
  | `String "[max]" -> MAX
  | x -> raise (Yojson.Basic.Util.Type_error ("Uncorrect bin_alg_op",x))

let un_alg_op_to_string = function
  | COSINUS -> "[cos]"
  | SINUS -> "[sin]"
  | TAN -> "[tan]"
  | EXP -> "[exp]"
  | SQRT -> "[sqrt]"
  | INT -> "[int]"
  | LOG -> "[log]"
  | UMINUS -> "-"

let print_un_alg_op f op =
  Format.pp_print_string f (un_alg_op_to_string op)

let un_alg_op_to_json op = `String (un_alg_op_to_string op)
let un_alg_op_of_json = function
  | `String "[cos]" -> COSINUS
  | `String "[sin]" -> SINUS
  | `String "[tan]" -> TAN
  | `String "[exp]" -> EXP
  | `String "[sqrt]" -> SQRT
  | `String "[int]" -> INT
  | `String "[log]" -> LOG
  | `String "-" -> UMINUS
  | x -> raise (Yojson.Basic.Util.Type_error ("Uncorrect un_alg_op",x))

let state_alg_op_to_string = function
  | CPUTIME -> "[Tsim]"
  | TIME_VAR -> "[T]"
  | EVENT_VAR -> "[E]"
  | NULL_EVENT_VAR -> "[E-]"
  | TMAX_VAR -> "[Tmax]"
  | EMAX_VAR -> "[Emax]"
  | PLOTNUM -> "[p]"

let print_state_alg_op f op =
  Format.pp_print_string f (state_alg_op_to_string op)

let state_alg_op_to_json op = `String (state_alg_op_to_string op)
let state_alg_op_of_json = function
  | `String "[Tsim]" -> CPUTIME
  | `String "[T]" -> TIME_VAR
  | `String "[E]" -> EVENT_VAR
  | `String "[E-]" ->  NULL_EVENT_VAR
  | `String "[Tmax]" -> TMAX_VAR
  | `String "[Emax]" -> EMAX_VAR
  | `String "[p]" -> PLOTNUM
  | x -> raise (Yojson.Basic.Util.Type_error ("Uncorrect state_alg_op",x))

let bool_op_to_string = function
  | AND -> "&&"
  | OR -> "||"

let print_bool_op f op =
  Format.pp_print_string f (bool_op_to_string op)

let bool_op_to_json op = `String (bool_op_to_string op)
let bool_op_of_json = function
  | `String "&&" -> AND
  | `String "||" -> OR
  | x -> raise (Yojson.Basic.Util.Type_error ("Uncorrect boolean op",x))

let compare_op_to_string = function
  | GREATER -> ">"
  | SMALLER -> "<"
  | EQUAL -> "="
  | DIFF -> "!="

let print_compare_op f op =
  Format.pp_print_string f (compare_op_to_string op)

let compare_op_to_json op = `String (compare_op_to_string op)
let compare_op_of_json = function
  | `String ">" -> GREATER
  | `String "<" -> SMALLER
  | `String "=" -> EQUAL
  | `String "!=" -> DIFF
  | x -> raise (Yojson.Basic.Util.Type_error ("Uncorrect compare_op",x))

let print_rev_dep f = function
  | RULE id ->
    Format.fprintf f "rate_of_rule [%i]" id
  (*"rate of rule '%a'" (Environment.print_rule env) id*)
  | ALG id ->
    Format.fprintf f "algebraic variable [%i]" id
  (*"variable '%a'" (Environment.print_alg env) id*)
  | PERT id -> Format.fprintf f "perturbation [%i]" id
module DepSetMap = SetMap.Make (struct type t = rev_dep
    let compare = compare
    let print = print_rev_dep end)
module DepSet = DepSetMap.Set
