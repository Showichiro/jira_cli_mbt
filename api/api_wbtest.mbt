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
        ("description", @core.any("desc")),
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
