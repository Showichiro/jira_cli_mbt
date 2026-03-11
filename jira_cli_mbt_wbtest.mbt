///|
test "issue_type_selection_message: empty issue types" {
  assert_eq(
    issue_type_selection_message("AJ", []),
    "No issue types found for project 'AJ'. Verify the project key is correct.",
  )
}

///|
test "issue_type_selection_message: available issue types" {
  assert_eq(
    issue_type_selection_message("AJ", [("1", "Task"), ("2", "Bug")]),
    "Please specify --type. Available issue types for AJ:\n  - Task\n  - Bug",
  )
}
