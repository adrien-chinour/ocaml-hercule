(** Hydra Battles *)
(* Message utilisé lorsqu'un bug est détecté – par exemple, dans les fonctions de réplication *)

let the_msg = "ouah, le bug!"

let the_debug = "C'est là !"

(* Une hydre est représentée sous la forme d'un arbre enraciné dont les noeuds peuvent avoir un nombre quelconque mais néanmoins fini de filles. *)

type hydra = Node of hydra list

(* Quelques abréviations  simples *)

(* Hydre à une seule tête *)
let head = Node []
let is_head : hydra -> bool = fun h -> h = head

(* Nœuds à 1, 2 ou 3 filles *)
let single h = Node [h]
let bi h1 h2 = Node [h1;h2]
let tri h1 h2 h3 = Node [h1;h2;h3]

(* Idem, lorsque les filles sont identiques *)
let bisame h = bi h h
let trisame h = tri h h h

(* Liste des filles d'un nœud *)
let les_filles (Node hs) = hs

(* Liste des filles des filles d'un noeud (Ajouté par Adrien) *)
let les_filles_des_filles h =
  let rec aux (l : hydra list) acc = match l with
    | [] -> acc
    | (h::t) -> aux t (les_filles h)@acc
  in aux (les_filles h) []

(* Exemples d'hydres *)

let baby_hydra = single head
let very_small_hydra = bi head head
let small_hydra = single (bi head head)
let my_hydra = tri head head  (single (single (tri head head head)))
let another_hydra = single (tri head head head)
let yet_another_hydra = single small_hydra
let goodstein_hydra = tri head head (tri head head head)

(* Exemple du sujet, page 1 *)
let example_hydra = tri head (bi (single (tri head head head)) head) head
(* Exemple du sujet après 2 coups d'Hercule et réplication en surface *)
let example_shallow = bi (bi (trisame very_small_hydra) head) head
(* Exemple du sujet après 2 coups d'Hercule et réplication en profondeur *)
let example_deep =
  let one = bisame very_small_hydra in
  let two = tri one one head in
  tri two head two
(* L'hydre qu'on aurait obtenue si la duplication en profondeur avait fait 2 copies *)
let example_deep_two_copies =
  let one = trisame very_small_hydra in
  let two = Node[one; one; one; head] in
  Node [two; two; two; head]

(* Les hydres pouvant être assez grosses, il est utile de fournir quelques mesures  *)

(* Écrire une fonction donnant la taille d'une hydre (nombre total de noeuds) *)
let size : hydra -> int = fun h ->
  let rec aux h acc = match h with
    | Node [] -> acc
    | _ -> aux (Node (les_filles_des_filles h)) (List.length(les_filles h) + acc)
  in aux h 1

(* Écrire une fonction donnant la hauteur d'une hydre (longueur maximale d'un  chemin partant du pied) *)
let height : hydra -> int = fun h ->
  let rec aux h acc =
    match les_filles h with
    | [] -> acc
    | _ -> aux (Node (les_filles_des_filles h)) (acc + 1)
  in aux h 0

(* Écrire une fonction qui calcule l'histogramme d'une hydre, nombre de noeuds à chaque niveau *)
let histogram : hydra -> int list = fun h ->
  let rec aux h acc = match h with
    | Node [] -> acc
    | _ -> aux (Node (les_filles_des_filles h)) (List.length(les_filles h)::acc)
  in List.rev( aux h [1])

(* Écrire une fonction qui compte le nombre de têtes à chaque niveau. *)
let histogram_heads : hydra -> int list = fun h ->
  let rec aux h acc = match h with
    | Node [] -> acc
    | _ -> aux (Node (les_filles_des_filles h)) (List.length(List.filter is_head (les_filles h))::acc)
  in List.rev( aux h [0] )

(*
   Écrire une fonction qui retourne une liste triée d'arêtes de l'hydre, avec
   les contraintes décrites dans le sujet.
 *)
let rec next_hydra : (hydra * int) list -> int -> hydra = fun l n ->
  match l with
  | (h,k)::l' -> if n = 0 then h else next_hydra l' (n - 1)
  | [] -> failwith "erreur in next_hydra"
             
let hydra_edges : hydra -> (int * int) list = fun h ->
  let rec aux : (hydra * int) list -> int -> (int * int) list -> (int * int) list = fun t next acc ->
    match t with
    | (h,k)::t' ->
       (match les_filles h with
        | a::l -> if is_head a
                  then aux ((Node l,k)::t') (next + 1) ((k,next)::acc)
                  else aux ((Node l,k)::((a,next)::t')) (next + 1) ((k,next)::acc)
        | [] -> aux t' next acc)
    | [] -> acc
  in List.rev (aux [(h,0)] 1 [])


(*
   Affiche une hydre h.
   Prérequis : la fonction hydra_edges doit avoir été écrite.
*)
let show_hydra h =
  (* Translates the list of edges in dot format, and outputs it to filename *)
  let hydra_to_dot h filename =
    let rec edges_to_dot edges channel =
      match edges with
        [] -> ()
      | (a,b)::r -> Printf.fprintf channel "%d -- %d\n" a b; edges_to_dot r channel
    in
    let dot_preamble = "graph hydra {\n" ^
                       "\trankdir=BT;\n" ^
                       "\tnode [label=\"\" shape=point style=filled fixedsize=true];\n"
    in
    let dot_postamble = "\n}" in
    let edges = hydra_edges h in
    let channel = open_out filename in
    Printf.fprintf channel "%s\n" dot_preamble;
    edges_to_dot edges channel;
    Printf.fprintf channel "%s\n" dot_postamble;
    close_out channel
  in
  (* Get uname of the system to properly set the png viewer *)
  let uname() =
    let (inchannel, outchannel) = Unix.open_process "uname" in
    let name = input_line inchannel in
    close_in inchannel;
    close_out outchannel;
    name
  in
  (* Set viewer to Imagemagick "display" under Linux, or "open" under OSX, otherwise fail :)  *)
  let viewer = let uname = uname() in
    if uname = "Linux" then " display "
    else if uname = "Darwin" then " open "
    else failwith "Viewer not set under windows" in
  (* Set style to view hydra's heads *)
  let style = "{style=\"invisible\",$.shape=\"none\",height=0.2,width=0.2,image=\"head.png\",label=\"\"}" in
  (* Prepare command *)
  let command = "gvpr -c 'N[$.outdegree==0] " ^ style ^ "' tmp.dot" (* post-process dot file to set style and view hydra's heads *)
                ^ "|" ^ "dot -T png -o tmp.png "                    (* Launch dot on resulting file *)
                ^ "&&" ^ viewer ^ " tmp.png" ^ "&"                  (* Launch viewer in bg *)
  in
  let _ = hydra_to_dot h "tmp.dot" in
  Unix.system command

(*
   Pour désigner un noeud ou une tête, on utilise une notation dite "de Dewey" : le chemin d'accés à un noeud
   est une liste d'indices qui représente le chemin à suivre depuis la racine ("le pied", si on préfère).
   un 0 signifie "aller vers la fille la plus à gauche", etc.
*)

type path = int list

(*
   Réactions de l'Hydre.
   Quand la tête de l'Hydre donnée par le chemin p est supprimée, l'Hydre
   effectue son algorithme de réplication.
*)

let rec repeat_concat n a l =
  if n <= 0
  then l
  else repeat_concat (n-1) a (a::l)

(* Supprime le i-ème élément de hs (si c'est une tête) *)

let rec remove_head i hs =
  match i,hs with
  | 0,(Node []) ::hs' -> hs'
  | i, h::hs' when i> 0 -> h :: remove_head (i-1) hs'
  |  _,_  -> failwith "erreur in remove_head"

(* Un tour de base :
   - Hercule coupe une tête de l'Hydre h donnée par le chemin p.
   - L'Hydre se réplique n fois.
*)

type replication_fun = path -> hydra -> int -> hydra

(* Version en profondeur *)
let rec deep_replication : replication_fun = fun  p h n ->
  match p,h with
    [i], Node l -> Node (remove_head i l)
  | (_::_), Node l -> Node (deep_replication_list p l n)
  | _,_ -> failwith "erreur in deep_replication"
and deep_replication_list p l n =
  match p,l with
    0::p', h::lh -> repeat_concat (1+n) (deep_replication p' h n) lh
  | i::p', h::lh when i> 0 -> h :: deep_replication_list (i-1::p') lh n
  | _,_ -> failwith "erreur in deep_replication_list"

(* Version en surface *)
let rec shallow_replication : replication_fun = fun p h n ->
  match p,h with
    [i], Node l -> Node (remove_head i l)
  | (_::_), Node l -> Node (shallow_replication_list p l n)
  | _,_ -> failwith "erreur in shallow_replication"
and shallow_replication_list p l n =
  match p,l with
    [0;i], Node l :: lh -> repeat_concat (1+n) (Node (remove_head  i l)) lh
  | 0::p',  h::lh -> shallow_replication p' h n :: lh
  | i::p', h::lh when i> 0 -> h :: shallow_replication_list (i-1::p') lh n
  | _,_ -> failwith "erreur in shallow_replication_list"

(* Les stratégies: Hercule et l'Hydre suivent chacun une stratégie *)

(*
   Une stratégie d'Hercule est, à partir d'une Hydre, de choisir une tête.
   Le programmeur qui définit une stratégie doit s'assurer qu'elle retourne
   toujours un chemin vers une tête.
*)

type hercules_strat =  hydra -> path

(*
   Suggestion: avant la fonction check_hercules_strategy, écrire une fonction sub_hydra
   telle que sub_hydra path h renvoie la sous-hydre de h donnée par le chemin path.
*)

let rec sub_hydra : path -> hydra -> hydra = fun path h ->
  match path with
  |[]-> h
  |x::path1-> sub_hydra path1 (List.nth (les_filles h) x)


(* Écrire la fonction suivante qui teste si une stratégie choisit bien une tête  *)
let check_hercules_strategy : hercules_strat -> hydra -> bool = fun strat  h  ->
  (sub_hydra (strat h) h = (Node []))

(* Écrire la stratégie choisissant la tête la plus à gauche *)
let leftmost_head_strat : hercules_strat = fun  h  ->
  let rec aux h acc = match h with
    |Node [] -> acc
    |_-> aux (List.nth (les_filles h) 0) (0::acc)
  in aux h []

(* Soit x le nombre de chemins accessibles à partir d'un noeud quelconque.
la fonction prend k chemins parmi x, ce qui signifie que si l'on a n noeuds
a visiter afin d'obtenir la tête la plus à gauche, k*n têtes seront vues.
si aucun chemin n'est accessible, la fonction renvoie la liste contenant les k*n têtes.

On considère une suite u(n) où u(n) est le nombre de têtes vue au bout de n parcours.
La tête suivante est u(n+1) = u(n)+k, d'où u(n+1)-u(n) = k.
La suite est alors arithmétique de raison k, alors u(n) = u(0)+n*k, avec :
> u(0) = 0, car dans ce cas aucune tête n'est vue (on est au pied de l'hydre)
> k = 1, car si une tête est vue, ses voisines ne le sont pas : il est imposible d'accéder
à une tête voisine sans passer par le noeud qui la précède, une seule tête est vue
On cherche donc à montrer par récurrence u(n) = 0+n*1 = n pour tout n>=1.

> initialisation: pour n=1, u(n)=1 vrai au premier rang
> hérédité: On suppose que la propriété est toujours vraie au rang suivant.
u(n+1) = u(0)+(n+1)*k = n+1 vrai au rang suivant

La propriété est vraie au premier rang, est héréditaire et la fonction remplie bien son rôle

complexité: O(n) car la fonction fait un parcours complet des tête à gauche pour n têtes*)

(* Fonction utile pour stratégie tête de hauteur max / min *)
let edges_from : int -> hydra -> int list = fun n h ->
  let rec aux l acc path =
    if acc = 0
    then path
    else
      match List.find (fun (x,y) -> y = acc) l with
      | (x,y) -> aux l x (x::path)
  in aux (hydra_edges h) n [n]

let first_fille : int -> hydra -> int = fun k h ->
  let rec aux l =
    match List.hd l with
    |(x,y) -> if x = k then y else aux (List.tl l)
  in aux (hydra_edges h)

let dir_from_path : int list -> hydra -> path = fun l h->
  let rec aux l acc =
    match l with
    | (x::y) ->
      if y = []
      then acc
      else aux (List.tl l) (((List.hd y) - (first_fille x h))::acc)
    | [] -> acc
  in List.rev (aux l [])

let first_head : hydra -> int = fun h ->
  let rec aux l acc =
    match l with
    | (a,b)::l' -> aux l' (b::(List.filter (fun x -> x != a) acc))
    | [] -> List.hd (List.rev acc)
  in aux (hydra_edges h) []
                    
(* Écrire la stratégie choisissant une tête de hauteur maximale *)
let highest_head_strat : hercules_strat = fun h -> dir_from_path (edges_from ((size h) - 1) h) h

                                                     
(* Écrire une stratégie visant à choisir une tête le plus près du sol possible *)
let closest_to_ground_strat : hercules_strat = fun h -> dir_from_path (edges_from (first_head h) h) h


(* En apprenant à utiliser la bibliothèque Random, écrire une stratégie pour choisir une tête au hasard *)

let random_strat : hercules_strat = fun h ->
  let rec aux h acc dir= match h with
    |Node [] -> List.rev acc
    |_-> if ((List.length(les_filles(List.nth (les_filles h) dir ))) > 2) then aux (List.nth (les_filles h) dir) (dir::acc) (Random.int (List.length(les_filles(List.nth (les_filles h) dir )))) else  aux (List.nth (les_filles h) dir) (dir::acc) 0
  in aux h [] (Random.int (List.length(les_filles h)))


(* Étant donnée une date, l'Hydre peut calculer un nombre de réplications >= 1 *)

type time = Time of int
                      
let next_time t = match t with Time(n) -> Time (n + 1)

let t10 = Time(10)
let t100 = Time(100)
let t1000 = Time(1000)

type hydra_strat =  time -> int

let check_hydra_strategy : hydra_strat -> time -> bool = fun st t -> st t >= 1

(* Une stratégie classique (celle de la vidéo): à chaque tour, le nombre de réplications est incrémenté. *)

let original_hydra_strat : hydra_strat = function Time  t -> t + 1

let simple_hydra_strat : hydra_strat = function Time t -> t

(* Une stratégie plus amusante : attention à l'explosion de pile ! *)

let boum : hydra_strat = function (Time t) ->
  let rec exp2 i =
    if i = 0 then 1 else 2 * exp2 (i-1)
  in exp2 t

(* Genre de bataille *)

type genre_de_bataille = Battle_kind of replication_fun * hercules_strat * hydra_strat


let genre_sco = (Battle_kind(shallow_replication, closest_to_ground_strat, original_hydra_strat))
let genre_dco = (Battle_kind(deep_replication, closest_to_ground_strat, original_hydra_strat))
let genre_sho = (Battle_kind(shallow_replication, highest_head_strat, original_hydra_strat))
let genre_dho = (Battle_kind(deep_replication, highest_head_strat, original_hydra_strat))
let genre_classique = (Battle_kind(shallow_replication, leftmost_head_strat, original_hydra_strat))

(*  Le score final d'une bataille *)
type result =
    Hercules_wins of time       (* Nombre de tours effectués *)
  | Hercules_gives_up of hydra  (* Hydre restante *)

(* Écrire la fonction de simulation *)
let simulation : genre_de_bataille -> hydra -> time -> result =
  fun (Battle_kind(replication,hercules_strat, hydra_strat)) initial_hydra (Time(duration)) ->
    let rec aux h t =
      if t = (Time(duration))
      then Hercules_gives_up h
      else
        match h with
        | Node [] -> Hercules_wins t
        | _ -> aux (replication (hercules_strat h) h (hydra_strat t)) (next_time t)
    in aux initial_hydra (Time(0))

(*
   Écrire une fonction make_trace telle que make_trace measure bat h_init (Time t) donne la suite

   des valeurs de la fonction measure sur les hydres obtenues en partant de l'hydre h_init et
   en effectuant t tours de la bataille de genre bat.
*)

let make_trace : (hydra -> 'a) -> genre_de_bataille -> hydra -> time -> 'a list =
  fun measure (Battle_kind(replication,hercules_strat, hydra_strat)) initial_hydra (Time duration) ->
    let rec aux h t acc =
      if t = (Time(duration))
      then acc
      else
        match h with
        | Node [] -> (measure h)::acc
        | _ -> aux (replication (hercules_strat h) h (hydra_strat t)) (next_time t) ((measure h)::acc)
    in aux initial_hydra (Time(0)) []



(* Extensions *)

(* prouver qu'une stratégie d'hercule marche bien *)

(* comparaison de 2 hydres *)

(*Pour comparer deux hydres il faut que leur histogrammes soient les mêmes à chaque embranchement,
pour cela on prend une branche depuis la racine de la première hydre et on cherche une branche depuis la racine
de la deuxième hydre qui a le même histogramme et on répète le même processus pour toutes les branches *)


(* fonction annexe qui compare 2 histogrammes *)

let rec check_histogram :int list-> int list-> bool =fun l1 l2 ->
  match l1 with
  |[]->(match l2 with
    |[]->true
    |_->false)
  |x::tl1->(match l2 with
    |[]->false
    |y::tl2->if (x=y) then check_histogram tl1 tl2 else false)

(*trouve une branche équivalente*)
let find :hydra -> int list -> int =fun h l1 ->
  let rec aux n=
    if(check_histogram l1 (histogram ((List.nth(les_filles h) n)))) then n  else if (n<List.length(les_filles h)) then  aux (n+1) else 0
in aux 0


(*let comparison :hydra-> hydra -> bool =fun hp hs ->
  let rec aux h1 h2 c1 c2  =
    match h1 with
    |Node[]->true
    |_-> if(c1<(List.length (les_filles h1))) then
        if(check_histogram (histogram h1) (histogram h2)) then
          if (aux (List.nth (les_filles h1) c1) (List.nth (les_filles h2) (find h2 (histogram(h1)))) 0 ) then
            aux h1 h2 (c1+1) (find h2 )
          else false
        else false
      else false
  in aux hp hs 0 (find hp (histogram(hs)))
 *)


(* Écrire ici vos tests *)

let test_size = ((size example_hydra) = 10) && (size baby_hydra = 2);;
test_size;;

let test_height = ((height example_hydra) = 4);;
test_height;;

let test_leftmost_head_strat = check_hercules_strategy leftmost_head_strat example_hydra;;
test_leftmost_head_strat;;

let test_random_head_strat = check_hercules_strategy random_strat example_hydra;;
test_random_head_strat;;

let test_highest_head_strat = (check_hercules_strategy highest_head_strat example_hydra) && (check_hercules_strategy highest_head_strat goodstein_hydra);;
test_highest_head_strat;;

let test_closest_to_ground_strat =(check_hercules_strategy closest_to_ground_strat example_hydra) && (check_hercules_strategy closest_to_ground_strat goodstein_hydra);;
test_closest_to_ground_strat;;

let goodstein_hydra_time = Node[Node []; Node []; Node [Node []; Node []]; Node [Node []; Node []];Node [Node []; Node []]]

(* Extension random *)


(*prend en argument un entier et renvoie une hydre avec approximativement le même nombre de noeuds *)                               
let random_nodes_new sizereq=
  let rec aux acc s rand =
    if(s>1) then match rand with
      |0-> aux (Node[]::acc) (s-1) ((Random.int(s-1))+1)
      |_->if (s>(rand)) then aux ((aux [] rand ((Random.int(rand))+1))::acc) (s-rand) ((Random.int(s-rand))+1) else aux ((aux [] rand ((Random.int(rand))+1))::acc) (s-rand) 0
    else Node(acc)
  in aux [] sizereq ((Random.int(sizereq)));;

(*petite variante où la hauteur max est donnée en argument*)
let random_hydra_new sizereq height=
  let rec aux acc s rand h =
    if((s>1)&&(height>h)) then match rand with
      |0-> aux (Node[]::acc) (s-1) (Random.int(s-1)) h
      |_-> aux ((aux [] rand (Random.int(rand)) (h+1))::acc) (s-rand) (Random.int(s-rand)) (h+1)
    else Node(acc)
  in aux [] sizereq (Random.int(sizereq)) 0;;

let _=show_hydra (random_hydra_new 20 5);;
let _=size (random_hydra_new 20 5);;
let _=height (random_hydra_new 20 5);;


