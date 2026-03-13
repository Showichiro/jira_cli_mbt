///|
test "parse_issue_field supports aliases" {
  inspect(@types.parse_issue_field("type"), content="Ok(IssueType)")
  inspect(@types.parse_issue_field("issuetype"), content="Ok(IssueType)")
  inspect(
    @types.parse_issue_field("customfield_12345"),
    content="Ok(Custom(\"customfield_12345\"))",
  )
}

///|
test "default issue field sets stay stable" {
  inspect(
    @types.default_list_issue_fields(),
    content="[Key, IssueType, Status, Priority, Summary]",
  )
  inspect(
    @types.default_detail_issue_fields(),
    content="[Key, IssueType, Status, Priority, Assignee, Summary, Description]",
  )
}

///|
test "parse_output_format supports stable names" {
  inspect(@types.parse_output_format("table"), content="Ok(Table)")
  inspect(@types.parse_output_format("tsv"), content="Ok(Tsv)")
  inspect(@types.parse_output_format("json"), content="Ok(Json)")
  inspect(
    @types.parse_output_format("yaml"),
    content="Err(\"Unsupported output format: yaml\")",
  )
}

///|
test "cli error categories map to stable exit codes" {
  assert_eq(@types.Usage.exit_code(), 2)
  assert_eq(@types.CliErrorCategory::Config.exit_code(), 4)
  assert_eq(@types.Auth.exit_code(), 4)
  assert_eq(@types.NotFound.exit_code(), 3)
  assert_eq(@types.Validation.exit_code(), 5)
  assert_eq(@types.General.exit_code(), 1)
}

///|
test "jira issue field_value reads requested field" {
  let issue : @types.JiraIssue = {
    key: "PROJ-1",
    summary: "Fix bug",
    status: "Open",
    assignee: "Alice",
    issue_type: "Bug",
    priority: "High",
    description: "Details",
    custom_fields: { "customfield_12345": "Platform Team" },
  }
  assert_eq(issue.field_value(@types.Assignee), "Alice")
  assert_eq(issue.field_value(@types.Description), "Details")
  assert_eq(
    issue.field_value(@types.Custom("customfield_12345")),
    "Platform Team",
  )
}
