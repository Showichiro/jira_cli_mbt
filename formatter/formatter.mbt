///|
fn pad_right(s : String, width : Int) -> String {
  if s.length() >= width {
    s
  } else {
    s + " ".repeat(width - s.length())
  }
}

///|
fn truncate(s : String, max_len : Int) -> String {
  let chars = s.to_array()
  if chars.length() <= max_len {
    s
  } else if max_len <= 3 {
    ".".repeat(max_len)
  } else {
    let buf = StringBuilder::new()
    for i in 0..<(max_len - 3) {
      buf.write_char(chars[i])
    }
    buf.write_string("...")
    buf.to_string()
  }
}

///|
fn format_table(
  headers : Array[String],
  rows : Array[Array[String]],
  widths : Array[Int],
) -> String {
  let header_line = headers
    .mapi(fn(i, h) { pad_right(h, widths[i]) })
    .join("  ")
  let separator = widths.map(fn(w) { "-".repeat(w) }).join("  ")
  let body = rows
    .map(fn(row) { row.mapi(fn(i, c) { pad_right(c, widths[i]) }).join("  ") })
    .join("\n")
  [header_line, separator, body].join("\n")
}

///|
pub fn format_issue_list(
  issues : Array[@types.JiraIssue],
  fields : Array[@types.IssueField],
) -> String {
  if issues.is_empty() {
    return "No issues found."
  }
  let headers = fields.map(fn(field) { field.list_header() })
  let widths = fields.map(fn(field) { field.table_width() })
  let rows = issues.map(fn(issue) {
    fields.map(fn(field) {
      truncate(issue.field_value(field), field.table_width())
    })
  })
  format_table(headers, rows, widths)
}

///|
fn format_detail_line(
  issue : @types.JiraIssue,
  field : @types.IssueField,
) -> String? {
  let value = issue.field_value(field)
  let label = pad_right(field.detail_label() + ":", 12)
  match (field, value) {
    (@types.Description, "") => None
    _ => Some("\{label} \{value}")
  }
}

///|
pub fn format_issue_detail(
  issue : @types.JiraIssue,
  fields : Array[@types.IssueField],
) -> String {
  fields.filter_map(fn(field) { format_detail_line(issue, field) }).join("\n")
}

///|
pub fn format_projects(projects : Array[@types.JiraProject]) -> String {
  if projects.is_empty() {
    return "No projects found."
  }
  let headers = ["KEY", "NAME", "TYPE"]
  let widths = [12, 30, 15]
  let rows = projects.map(fn(p) {
    [p.key, truncate(p.name, 30), p.project_type]
  })
  format_table(headers, rows, widths)
}

///|
pub fn format_fields(fields : Array[@types.JiraField]) -> String {
  if fields.is_empty() {
    return "No custom fields found."
  }
  let headers = ["ID", "NAME", "TYPE", "CUSTOM TYPE"]
  let widths = [25, 30, 15, 40]
  let rows = fields.map(fn(f) {
    [f.id, truncate(f.name, 30), f.schema_type, truncate(f.schema_custom, 40)]
  })
  format_table(headers, rows, widths)
}

///|
pub fn format_field_detail(detail : @types.JiraFieldDetail) -> String {
  let f = detail.field
  let lines = [
    "ID:          " + f.id,
    "Name:        " + f.name,
    "Type:        " + f.schema_type,
    "Custom Type: " + f.schema_custom,
  ]
  if detail.options.is_empty() {
    lines.join("\n") + "\n\nNo options available for this field."
  } else {
    let opt_headers = ["ID", "VALUE"]
    let opt_widths = [10, 30]
    let opt_rows = detail.options.map(fn(o) { [o.id, truncate(o.value, 30)] })
    lines.join("\n") +
    "\n\nOptions:\n" +
    format_table(opt_headers, opt_rows, opt_widths)
  }
}

///|
pub fn format_usage() -> String {
  [
    "Jira CLI (MoonBit)", "", "Usage: jira <command> [options]", "", "Commands:",
    "  config      Set Jira configuration", "              --base-url <url> --email <email> --api-token <token>",
    "  issues      List assigned issues (default JQL)", "              [--jql <jql>] [--fields <field,...>]",
    "  issue       Get issue details", "              <key> [--fields <field,...>]",
    "              fields: key,summary,status,assignee,type,priority,description,customfield_<id>",
    "  create      Create a new issue", "              --project <key> --summary <text> [--type <type>] [--description <text>] [--set <field=value>]...",
    "  update      Update an existing issue", "              <key> [--summary <text>] [--description <text>] [--priority <name>] [--type <name>] [--labels <label1,label2>] [--assignee <email>] [--set <field=value>]...",
    "  transition  Transition issue status", "              --key <key> --status <status>",
    "  comment     Add comment to issue", "              --key <key> --text <text>",
    "  assign      Assign issue to user", "              --key <key> --email <email>",
    "  search      Search issues with JQL", "              --jql <jql>", "  fields      List custom fields",
    "              [customfield_XXXXX]  Show field details and options", "  projects    List all projects",
    "  help        Show this help message",
  ].join("\n")
}
