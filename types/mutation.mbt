///|
pub(all) enum MutationStatus {
  DryRun
  Success
  PartialSuccess
} derive(Show, Eq)

///|
pub fn MutationStatus::name(self : MutationStatus) -> String {
  match self {
    DryRun => "dry_run"
    Success => "success"
    PartialSuccess => "partial_success"
  }
}

///|
pub(all) enum MutationOperationStatus {
  Planned
  Applied
  Failed
} derive(Show, Eq)

///|
pub fn MutationOperationStatus::name(self : MutationOperationStatus) -> String {
  match self {
    Planned => "planned"
    Applied => "applied"
    Failed => "failed"
  }
}

///|
pub(all) struct MutationFieldChange {
  name : String
  value : String
} derive(Show, Eq)

///|
pub(all) struct MutationOperation {
  name : String
  status : MutationOperationStatus
  detail : String
} derive(Show, Eq)

///|
pub(all) struct MutationReport {
  command : String
  status : MutationStatus
  issue_key : String
  project_key : String
  dry_run : Bool
  message : String
  field_changes : Array[MutationFieldChange]
  operations : Array[MutationOperation]
  discovery_hint : DiscoveryHint
} derive(Show, Eq)
