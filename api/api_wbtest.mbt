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
        ("parent", @core.from_entries([("key", @core.any("EPIC-1"))])),
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
  assert_eq(issue.parent, "EPIC-1")
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
test "parse_field with schema" {
  let data = @core.from_entries([
    ("id", @core.any("customfield_10001")),
    ("name", @core.any("Severity")),
    ("custom", @core.any(true)),
    (
      "schema",
      @core.from_entries([
        ("type", @core.any("option")),
        (
          "custom",
          @core.any("com.atlassian.jira.plugin.system.customfieldtypes:select"),
        ),
      ]),
    ),
  ])
  let field = parse_field(data)
  assert_eq(field.id, "customfield_10001")
  assert_eq(field.name, "Severity")
  assert_true(field.custom)
  assert_eq(field.schema_type, "option")
  assert_eq(
    field.schema_custom,
    "com.atlassian.jira.plugin.system.customfieldtypes:select",
  )
}

///|
test "parse_field with nullish schema" {
  let data = @core.from_entries([
    ("id", @core.any("customfield_10002")),
    ("name", @core.any("Notes")),
    ("custom", @core.any(true)),
    ("schema", js_null()),
  ])
  let field = parse_field(data)
  assert_eq(field.id, "customfield_10002")
  assert_eq(field.name, "Notes")
  assert_true(field.custom)
  assert_eq(field.schema_type, "")
  assert_eq(field.schema_custom, "")
}

///|
test "requested_api_fields excludes key and dedups aliases" {
  inspect(
    requested_api_fields([
      @types.Key,
      @types.Summary,
      @types.Parent,
      @types.IssueType,
      @types.IssueType,
      @types.Custom("customfield_12345"),
    ]),
    content="[\"summary\", \"parent\", \"issuetype\", \"customfield_12345\"]",
  )
}

///|
test "build_search_body includes requested fields" {
  inspect(
    @core.json_stringify_pretty(
      build_search_body(
        "project = TEST",
        [@types.Key, @types.Summary, @types.Assignee],
        20,
      ),
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
test "slice_items respects limit and start-at" {
  let items = [1, 2, 3, 4, 5]
  assert_eq(slice_items(items, @types.limited_page_request(2, start_at=1)), [
    2, 3,
  ])
}

///|
test "slice_items returns remaining items for fetch_all" {
  let items = [1, 2, 3, 4, 5]
  assert_eq(slice_items(items, @types.full_page_request(start_at=3)), [4, 5])
}

///|
test "issue_search_page_size uses stable cursor page size when offset exists" {
  assert_eq(
    issue_search_page_size(@types.limited_page_request(5, start_at=10)),
    50,
  )
}

///|
test "issue_search_page_size keeps small single-page requests" {
  assert_eq(issue_search_page_size(@types.limited_page_request(5)), 5)
}

///|
test "preview_create_issue returns stable dry-run report" {
  let report = preview_create_issue(
    "APP",
    "Fix login bug",
    "Bug",
    "",
    "EPIC-1",
    {
      "customfield_200": @types.custom_field_input_string("Zed"),
      "customfield_100": @types.custom_field_input_string("Alpha"),
    },
  )
  assert_eq(report.command, "issue create")
  assert_eq(report.status, @types.DryRun)
  assert_true(report.dry_run)
  assert_eq(report.project_key, "APP")
  assert_eq(
    report.field_changes.map(fn(change) { change.name }).join(","),
    "project,summary,issue_type,parent,customfield_100,customfield_200",
  )
  assert_eq(report.operations.length(), 1)
  assert_eq(report.operations[0].status, @types.Planned)
}

///|
test "preview_update_issue includes planned operations and normalized labels" {
  let report = preview_update_issue(
    "APP-123",
    "Refine rollout plan",
    "",
    "High",
    "",
    "backend, urgent",
    "EPIC-1",
    "user@example.com",
    { "customfield_10001": @types.custom_field_input_option_id("10401") },
  )
  assert_eq(report.command, "issue update")
  assert_eq(report.status, @types.DryRun)
  assert_true(report.dry_run)
  assert_eq(report.issue_key, "APP-123")
  assert_eq(
    report.field_changes
    .map(fn(change) { change.name + "=" + change.value })
    .join(","),
    "summary=Refine rollout plan,priority=High,labels=backend,urgent,parent=EPIC-1,assignee=user@example.com,customfield_10001={\"id\":\"10401\"}",
  )
  assert_eq(
    report.operations
    .map(fn(operation) { operation.name + ":" + operation.status.name() })
    .join(","),
    "update_fields:planned,assign_issue:planned",
  )
}

///|
test "partial_update_report appends safe retry guidance" {
  let report = partial_update_report(
    "APP-123",
    [@types.MutationFieldChange::{ name: "summary", value: "Updated" }],
    [("summary", @core.any("Updated"))],
    "User lookup failed",
    {
      message: "Multiple Jira users matched user@example.com.",
      candidates: [
        {
          value: "user@example.com",
          label: "user@example.com",
          description: "Exact email",
        },
      ],
      required_args: ["--assignee"],
      next_step: "Re-run `jira-cli issue assign --key APP-123 --email user@example.com`.",
    },
  )
  assert_eq(report.status, @types.PartialSuccess)
  assert_false(report.dry_run)
  assert_true(report.message.contains("partially updated"))
  assert_eq(report.operations[0].status, @types.Applied)
  assert_eq(report.operations[1].status, @types.Failed)
  assert_true(
    report.discovery_hint.next_step.contains("jira-cli issue get APP-123"),
  )
  assert_true(report.discovery_hint.next_step.contains("jira-cli issue assign"))
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
    @core.from_entries([
      ("accountId", @core.any("acc-1")),
      ("displayName", @core.any("User One")),
      ("emailAddress", @core.any("user.one@example.com")),
    ]),
    @core.from_entries([
      ("accountId", @core.any("acc-2")),
      ("displayName", @core.any("User Two")),
      ("emailAddress", @core.any("user.two@example.com")),
    ]),
  ]
  match select_user_account_id(users, "user@example.com") {
    Err(hint) => {
      assert_eq(hint.message, "Multiple users matched: user@example.com")
      assert_eq(hint.candidates.length(), 2)
      assert_eq(hint.candidates[0].value, "user.one@example.com")
      assert_eq(hint.candidates[0].label, "User One <user.one@example.com>")
      assert_eq(hint.candidates[0].description, "accountId: acc-1")
      assert_eq(hint.next_step, "")
    }
    Ok(_) => assert_false(true)
  }
}

///|
test "parse_error_response with errorMessages only" {
  let data = @core.from_entries([
    (
      "errorMessages",
      @core.any([@core.any("Field is required"), @core.any("Invalid value")]),
    ),
  ])
  assert_eq(parse_error_response(data), "Field is required, Invalid value")
}

///|
test "parse_error_response with errors only" {
  let data = @core.from_entries([
    (
      "errors",
      @core.from_entries([("customfield_12345", @core.any("cannot be set"))]),
    ),
  ])
  assert_eq(parse_error_response(data), "'customfield_12345': cannot be set")
}

///|
test "parse_error_response with both errorMessages and errors" {
  let data = @core.from_entries([
    ("errorMessages", @core.any([@core.any("Issue type is required")])),
    (
      "errors",
      @core.from_entries([("customfield_999", @core.any("invalid value"))]),
    ),
  ])
  assert_eq(
    parse_error_response(data),
    "Issue type is required, 'customfield_999': invalid value",
  )
}

///|
test "parse_error_response with empty/nullish data" {
  let data = @core.from_entries([])
  assert_eq(parse_error_response(data), "")
}

///|
test "truncate_string within limit" {
  assert_eq(truncate_string("hello", 10), "hello")
}

///|
test "truncate_string exceeds limit" {
  assert_eq(truncate_string("hello world", 5), "hello...")
}

///|
test "custom_field_value: numeric wraps as id object" {
  let result = @core.json_stringify(
    custom_field_value(@types.custom_field_input_option_id("123")),
  )
  assert_true(result.contains("\"id\""))
  assert_true(result.contains("\"123\""))
}

///|
test "custom_field_value: non-numeric passes as string" {
  let result = custom_field_value(@types.custom_field_input_string("hello"))
  assert_eq(result.to_string(), "hello")
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
