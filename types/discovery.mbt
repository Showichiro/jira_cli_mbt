///|
pub(all) struct DiscoveryCandidate {
  value : String
  label : String
  description : String
} derive(Show, Eq)

///|
pub(all) struct DiscoveryHint {
  message : String
  candidates : Array[DiscoveryCandidate]
  required_args : Array[String]
  next_step : String
} derive(Show, Eq)

///|
pub fn empty_discovery_hint() -> DiscoveryHint {
  { message: "", candidates: [], required_args: [], next_step: "" }
}

///|
pub fn DiscoveryHint::is_empty(self : DiscoveryHint) -> Bool {
  self.message.length() == 0 &&
  self.candidates.is_empty() &&
  self.required_args.is_empty() &&
  self.next_step.length() == 0
}
