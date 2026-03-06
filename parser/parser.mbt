///|
let default_jql : String = "assignee = currentUser() ORDER BY updated DESC"

///|
pub fn parse_args(args : ArrayView[String]) -> Result[@types.Command, String] {
  match args {
    ["help" | "--help" | "-h", ..] => Ok(@types.Help)
    ["config", .. rest] => parse_config(rest)
    ["issues", .. rest] => parse_issues_cmd(rest)
    ["issue", key, ..] => Ok(@types.GetIssue(key~))
    ["issue", ..] => Err("Usage: issue <key>")
    ["create", .. rest] => parse_create(rest)
    ["transition", .. rest] => parse_transition(rest)
    ["comment", .. rest] => parse_comment(rest)
    ["assign", .. rest] => parse_assign(rest)
    ["search", .. rest] => parse_search(rest)
    ["projects"] => Ok(@types.ListProjects)
    [] => Ok(@types.Help)
    [cmd, ..] => Err("Unknown command: \{cmd}")
  }
}

///|
fn collect_value(args : ArrayView[String]) -> (String, ArrayView[String]) {
  let parts : Array[String] = []
  let mut rest = args
  while rest.length() > 0 && not(rest[0].has_prefix("--")) {
    parts.push(rest[0])
    rest = rest[1:]
  }
  (parts.join(" "), rest)
}

///|
let flag_map : Map[String, String] = {
  "--base-url": "base_url",
  "--email": "email",
  "--api-token": "api_token",
  "--project": "project",
  "--summary": "summary",
  "--type": "issue_type",
  "--description": "description",
  "--jql": "jql",
  "--key": "key",
  "--status": "status",
  "--text": "text",
}

///|
fn parse_flags(
  args : ArrayView[String],
  acc : Map[String, String],
) -> Map[String, String] {
  if args.length() == 0 {
    return acc
  }
  match flag_map.get(args[0]) {
    Some(key) => {
      let (value, rest) = collect_value(args[1:])
      parse_flags(rest, acc..set(key, value))
    }
    None => acc
  }
}

///|
fn parse_config(args : ArrayView[String]) -> Result[@types.Command, String] {
  let flags = parse_flags(args, {})
  match (flags.get("base_url"), flags.get("email"), flags.get("api_token")) {
    (Some(base_url), Some(email), Some(api_token)) =>
      Ok(@types.Config(base_url~, email~, api_token~))
    _ =>
      Err("Usage: config --base-url <url> --email <email> --api-token <token>")
  }
}

///|
fn parse_issues_cmd(args : ArrayView[String]) -> Result[@types.Command, String] {
  let flags = parse_flags(args, {})
  let jql = flags.get("jql").unwrap_or(default_jql)
  Ok(@types.ListIssues(jql~))
}

///|
fn parse_create(args : ArrayView[String]) -> Result[@types.Command, String] {
  let flags = parse_flags(args, {})
  match (flags.get("project"), flags.get("summary")) {
    (Some(project), Some(summary)) => {
      let issue_type = flags.get("issue_type").unwrap_or("Task")
      let description = flags.get("description").unwrap_or("")
      Ok(@types.CreateIssue(project~, summary~, issue_type~, description~))
    }
    _ =>
      Err(
        "Usage: create --project <key> --summary <text> [--type <type>] [--description <text>]",
      )
  }
}

///|
fn parse_transition(args : ArrayView[String]) -> Result[@types.Command, String] {
  let flags = parse_flags(args, {})
  match (flags.get("key"), flags.get("status")) {
    (Some(key), Some(status)) => Ok(@types.Transition(key~, status~))
    _ => Err("Usage: transition --key <key> --status <status>")
  }
}

///|
fn parse_comment(args : ArrayView[String]) -> Result[@types.Command, String] {
  let flags = parse_flags(args, {})
  match (flags.get("key"), flags.get("text")) {
    (Some(key), Some(text)) => Ok(@types.Comment(key~, text~))
    _ => Err("Usage: comment --key <key> --text <text>")
  }
}

///|
fn parse_assign(args : ArrayView[String]) -> Result[@types.Command, String] {
  let flags = parse_flags(args, {})
  match (flags.get("key"), flags.get("email")) {
    (Some(key), Some(email)) => Ok(@types.Assign(key~, email~))
    _ => Err("Usage: assign --key <key> --email <email>")
  }
}

///|
fn parse_search(args : ArrayView[String]) -> Result[@types.Command, String] {
  let flags = parse_flags(args, {})
  match flags.get("jql") {
    Some(jql) => Ok(@types.Search(jql~))
    None => Err("Usage: search --jql <jql>")
  }
}
