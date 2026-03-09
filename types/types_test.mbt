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
