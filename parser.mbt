///|
let default_jql : String = "assignee = currentUser() ORDER BY updated DESC"

///|
pub fn parse_args(args : ArrayView[String]) -> Result[Command, String] {
  match args {
    ["help" | "--help" | "-h", ..] => Ok(Help)
    ["config", .. rest] => parse_config(rest)
    ["issues", .. rest] => parse_issues_cmd(rest)
    ["issue", key, ..] => Ok(GetIssue(key~))
    ["issue", ..] => Err("Usage: issue <key>")
    ["create", .. rest] => parse_create(rest)
    ["transition", .. rest] => parse_transition(rest)
    ["comment", .. rest] => parse_comment(rest)
    ["assign", .. rest] => parse_assign(rest)
    ["search", .. rest] => parse_search(rest)
    ["projects"] => Ok(ListProjects)
    [] => Ok(Help)
    [cmd, ..] => Err("Unknown command: \{cmd}")
  }
}

///|
fn parse_flags(
  args : ArrayView[String],
  acc : Map[String, String],
) -> Map[String, String] {
  match args {
    ["--base-url", value, .. rest] =>
      parse_flags(rest, acc..set("base_url", value))
    ["--email", value, .. rest] => parse_flags(rest, acc..set("email", value))
    ["--api-token", value, .. rest] =>
      parse_flags(rest, acc..set("api_token", value))
    ["--project", value, .. rest] =>
      parse_flags(rest, acc..set("project", value))
    ["--summary", value, .. rest] =>
      parse_flags(rest, acc..set("summary", value))
    ["--type", value, .. rest] =>
      parse_flags(rest, acc..set("issue_type", value))
    ["--description", value, .. rest] =>
      parse_flags(rest, acc..set("description", value))
    ["--jql", value, .. rest] => parse_flags(rest, acc..set("jql", value))
    ["--key", value, .. rest] => parse_flags(rest, acc..set("key", value))
    ["--status", value, .. rest] => parse_flags(rest, acc..set("status", value))
    ["--text", value, .. rest] => parse_flags(rest, acc..set("text", value))
    _ => acc
  }
}

///|
fn parse_config(args : ArrayView[String]) -> Result[Command, String] {
  let flags = parse_flags(args, {})
  match (flags.get("base_url"), flags.get("email"), flags.get("api_token")) {
    (Some(base_url), Some(email), Some(api_token)) =>
      Ok(Config(base_url~, email~, api_token~))
    _ =>
      Err("Usage: config --base-url <url> --email <email> --api-token <token>")
  }
}

///|
fn parse_issues_cmd(args : ArrayView[String]) -> Result[Command, String] {
  let flags = parse_flags(args, {})
  let jql = flags.get("jql").unwrap_or(default_jql)
  Ok(ListIssues(jql~))
}

///|
fn parse_create(args : ArrayView[String]) -> Result[Command, String] {
  let flags = parse_flags(args, {})
  match (flags.get("project"), flags.get("summary")) {
    (Some(project), Some(summary)) => {
      let issue_type = flags.get("issue_type").unwrap_or("Task")
      let description = flags.get("description").unwrap_or("")
      Ok(CreateIssue(project~, summary~, issue_type~, description~))
    }
    _ =>
      Err(
        "Usage: create --project <key> --summary <text> [--type <type>] [--description <text>]",
      )
  }
}

///|
fn parse_transition(args : ArrayView[String]) -> Result[Command, String] {
  let flags = parse_flags(args, {})
  match (flags.get("key"), flags.get("status")) {
    (Some(key), Some(status)) => Ok(Transition(key~, status~))
    _ => Err("Usage: transition --key <key> --status <status>")
  }
}

///|
fn parse_comment(args : ArrayView[String]) -> Result[Command, String] {
  let flags = parse_flags(args, {})
  match (flags.get("key"), flags.get("text")) {
    (Some(key), Some(text)) => Ok(Comment(key~, text~))
    _ => Err("Usage: comment --key <key> --text <text>")
  }
}

///|
fn parse_assign(args : ArrayView[String]) -> Result[Command, String] {
  let flags = parse_flags(args, {})
  match (flags.get("key"), flags.get("email")) {
    (Some(key), Some(email)) => Ok(Assign(key~, email~))
    _ => Err("Usage: assign --key <key> --email <email>")
  }
}

///|
fn parse_search(args : ArrayView[String]) -> Result[Command, String] {
  let flags = parse_flags(args, {})
  match flags.get("jql") {
    Some(jql) => Ok(Search(jql~))
    None => Err("Usage: search --jql <jql>")
  }
}
