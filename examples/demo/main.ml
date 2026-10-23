open Workflow_runtime
module Runtime = Make (struct let now_ms () = 1_000L end) (Memory_backend)
let get = function Ok value -> value | Error error -> failwith (Runtime.error_to_string error)
let () =
  let backend = Memory_backend.create () in
  let workflow = {
    id = "demo-1"; tenant_id = "demo"; kind = "example";
    subject_id = None; name = Some "Local lifecycle example"; metadata = [];
  } in
  get (Runtime.enqueue backend workflow (enqueue_options ()));
  Printf.printf "In-memory workflow, no external storage\n";
  let claim = get (Runtime.claim_next backend ~worker_id:"worker-1" ~lease_ms:30_000L) in
  (match claim with
   | None -> failwith "workflow was not claimed"
   | Some claim -> Printf.printf "Claimed %s as %s\n" claim.item.workflow.id (status_to_string claim.item.status));
  let completed = get (Runtime.complete backend ~workflow_id:"demo-1" ~worker_id:"worker-1"
      ~status:Succeeded ~message:"local example finished") in
  assert completed;
  let items = get (Runtime.snapshot backend) in
  List.iter (fun (item : Workflow_runtime.item) -> Printf.printf "Final state: %s\n" (status_to_string item.status)) items;
  Printf.printf "Memory_backend does not survive process exit.\n"
