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
  if s.length() <= max_len {
    s
  } else {
    let buf = StringBuilder::new()
    for i in 0..<(max_len - 3) {
      buf.write_char(s[i].to_int().unsafe_to_char())
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
pub fn format_issue_list(issues : Array[JiraIssue]) -> String {
  if issues.is_empty() {
    return "No issues found."
  }
  let headers = ["KEY", "TYPE", "STATUS", "PRIORITY", "SUMMARY"]
  let widths = [12, 12, 15, 10, 40]
  let rows = issues.map(fn(issue) {
    [
      issue.key,
      truncate(issue.issue_type, 12),
      truncate(issue.status, 15),
      truncate(issue.priority, 10),
      truncate(issue.summary, 40),
    ]
  })
  format_table(headers, rows, widths)
}

///|
pub fn format_issue_detail(issue : JiraIssue) -> String {
  [
    "Key:         \{issue.key}",
    "Type:        \{issue.issue_type}",
    "Status:      \{issue.status}",
    "Priority:    \{issue.priority}",
    "Assignee:    \{issue.assignee}",
    "Summary:     \{issue.summary}",
    ..if issue.description.length() > 0 {
      ["Description: \{issue.description}"]
    } else {
      []
    },
  ].join("\n")
}

///|
pub fn format_projects(projects : Array[JiraProject]) -> String {
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
pub fn format_usage() -> String {
  [
    "Jira CLI (MoonBit)", "", "Usage: jira <command> [options]", "", "Commands:",
    "  config      Set Jira configuration", "              --base-url <url> --email <email> --api-token <token>",
    "  issues      List assigned issues (default JQL)", "              [--jql <jql>]",
    "  issue       Get issue details", "              <key>", "  create      Create a new issue",
    "              --project <key> --summary <text> [--type <type>] [--description <text>]",
    "  transition  Transition issue status", "              --key <key> --status <status>",
    "  comment     Add comment to issue", "              --key <key> --text <text>",
    "  assign      Assign issue to user", "              --key <key> --email <email>",
    "  search      Search issues with JQL", "              --jql <jql>", "  projects    List all projects",
    "  help        Show this help message",
  ].join("\n")
}
