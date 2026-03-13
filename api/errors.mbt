///|
pub suberror JiraApiError {
  JiraApiError(
    status_code~ : Int,
    message~ : String,
    discovery_hint~ : @types.DiscoveryHint
  )
}
