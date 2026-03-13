///|
pub suberror JiraApiError {
  JiraApiError(
    status_code~ : Int,
    message~ : String,
    discovery_hint~ : @types.DiscoveryHint
  )
}

///|
pub suberror JiraMutationPartialSuccess {
  JiraMutationPartialSuccess(
    status_code~ : Int,
    report~ : @types.MutationReport
  )
}
