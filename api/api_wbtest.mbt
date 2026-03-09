///|
extern "js" fn js_null() -> @core.Any =
  #|() => null

///|
test "auth_header" {
  let config : @types.JiraConfig = {
    base_url: "https://example.atlassian.net",
    email: "user@example.com",
    api_token: "token123",
  }
  let header = auth_header(config)
  assert_true(header.has_prefix("Basic "))
  let encoded = header[6:].to_string()
  assert_eq(encoded, base64_encode("user@example.com:token123"))
}

///|
test "get_string with normal value" {
  let obj = @core.from_entries([("name", @core.any("Alice"))])
  assert_eq(get_string(obj, "name"), "Alice")
}

///|
test "get_string with missing key" {
  let obj = @core.from_entries([("name", @core.any("Alice"))])
  assert_eq(get_string(obj, "missing"), "")
}

///|
test "get_string with default" {
  let obj = @core.from_entries([])
  assert_eq(get_string(obj, "name", default="N/A"), "N/A")
}

///|
test "parse_issue with all fields" {
  let description = build_adf_text("Test description")
  let data = @core.from_entries([
    ("key", @core.any("TEST-1")),
    (
      "fields",
      @core.from_entries([
        ("summary", @core.any("Test summary")),
        ("status", @core.from_entries([("name", @core.any("In Progress"))])),
        ("assignee", @core.from_entries([("displayName", @core.any("Alice"))])),
        ("issuetype", @core.from_entries([("name", @core.any("Bug"))])),
        ("priority", @core.from_entries([("name", @core.any("High"))])),
        ("description", description),
        ("customfield_12345", @core.any("Platform Team")),
      ]),
    ),
  ])
  let issue = parse_issue(data)
  assert_eq(issue.key, "TEST-1")
  assert_eq(issue.summary, "Test summary")
  assert_eq(issue.status, "In Progress")
  assert_eq(issue.assignee, "Alice")
  assert_eq(issue.issue_type, "Bug")
  assert_eq(issue.priority, "High")
  assert_eq(issue.description, "Test description")
  assert_eq(issue.custom_fields["customfield_12345"], "Platform Team")
}

///|
test "parse_issue with null assignee and description" {
  let data = @core.from_entries([
    ("key", @core.any("TEST-2")),
    (
      "fields",
      @core.from_entries([
        ("summary", @core.any("No assignee")),
        ("status", @core.from_entries([("name", @core.any("Open"))])),
        ("assignee", js_null()),
        ("issuetype", @core.from_entries([("name", @core.any("Task"))])),
        ("priority", @core.from_entries([("name", @core.any("Medium"))])),
        ("description", js_null()),
      ]),
    ),
  ])
  let issue = parse_issue(data)
  assert_eq(issue.assignee, "Unassigned")
  assert_eq(issue.description, "")
}

///|
test "any_to_display_string handles object and array custom field values" {
  let value = any_to_display_string(
    @core.from_entries([("displayName", @core.any("Platform Team"))]),
  )
  let array_value = any_to_display_string(
    @core.any([
      @core.from_entries([("name", @core.any("Backend"))]),
      @core.from_entries([("value", @core.any("Urgent"))]),
    ]),
  )
  assert_eq(value, "Platform Team")
  assert_eq(array_value, "Backend, Urgent")
}

///|
test "parse_issues with empty array" {
  let empty : Array[@core.Any] = []
  let data = @core.from_entries([("issues", @core.any(empty))])
  let issues = parse_issues(data)
  assert_eq(issues.length(), 0)
}

///|
test "parse_issues with multiple elements" {
  let make_issue = fn(key : String) -> @core.Any {
    @core.from_entries([
      ("key", @core.any(key)),
      (
        "fields",
        @core.from_entries([
          ("summary", @core.any("s")),
          ("status", @core.from_entries([("name", @core.any("Open"))])),
          ("assignee", js_null()),
          ("issuetype", @core.from_entries([("name", @core.any("Task"))])),
          ("priority", @core.from_entries([("name", @core.any("Low"))])),
          ("description", js_null()),
        ]),
      ),
    ])
  }
  let data = @core.from_entries([
    ("issues", @core.any([make_issue("A-1"), make_issue("A-2")])),
  ])
  let issues = parse_issues(data)
  assert_eq(issues.length(), 2)
  assert_eq(issues[0].key, "A-1")
  assert_eq(issues[1].key, "A-2")
}

///|
test "parse_project" {
  let data = @core.from_entries([
    ("key", @core.any("PROJ")),
    ("name", @core.any("My Project")),
    ("projectTypeKey", @core.any("software")),
  ])
  let project = parse_project(data)
  assert_eq(project.key, "PROJ")
  assert_eq(project.name, "My Project")
  assert_eq(project.project_type, "software")
}

///|
test "requested_api_fields excludes key and dedups aliases" {
  inspect(
    requested_api_fields([
      @types.Key,
      @types.Summary,
      @types.IssueType,
      @types.IssueType,
      @types.Custom("customfield_12345"),
    ]),
    content="[\"summary\", \"issuetype\", \"customfield_12345\"]",
  )
}

///|
test "build_search_body includes requested fields" {
  inspect(
    @core.json_stringify_pretty(
      build_search_body("project = TEST", [
        @types.Key,
        @types.Summary,
        @types.Assignee,
      ]),
      2,
    ),
    content=(
      #|{
      #|  "jql": "project = TEST",
      #|  "maxResults": 20,
      #|  "fields": [
      #|    "summary",
      #|    "assignee"
      #|  ]
      #|}
    ),
  )
}

///|
test "build_issue_path omits query when key only" {
  inspect(
    build_issue_path("TEST-1", [@types.Key]),
    content="/rest/api/3/issue/TEST-1",
  )
}

///|
test "select_user_account_id prefers exact match" {
  let users : Array[@core.Any] = [
    @core.from_entries([
      ("accountId", @core.any("acc-1")),
      ("emailAddress", @core.any("other@example.com")),
    ]),
    @core.from_entries([
      ("accountId", @core.any("acc-2")),
      ("emailAddress", @core.any("user@example.com")),
    ]),
  ]
  inspect(
    select_user_account_id(users, "user@example.com"),
    content="Ok(\"acc-2\")",
  )
}

///|
test "select_user_account_id rejects ambiguous results" {
  let users : Array[@core.Any] = [
    @core.from_entries([("accountId", @core.any("acc-1"))]),
    @core.from_entries([("accountId", @core.any("acc-2"))]),
  ]
  inspect(
    select_user_account_id(users, "user@example.com"),
    content="Err(\"Multiple users matched: user@example.com\")",
  )
}

///|
test "build_adf_text with empty string" {
  let adf = build_adf_text("")
  let json_str = @core.json_stringify_pretty(adf, 2)
  inspect(
    json_str,
    content=(
      #|{
      #|  "type": "doc",
      #|  "version": 1,
      #|  "content": [
      #|    {
      #|      "type": "paragraph",
      #|      "content": [
      #|        {
      #|          "type": "text",
      #|          "text": ""
      #|        }
      #|      ]
      #|    }
      #|  ]
      #|}
    ),
  )
}
