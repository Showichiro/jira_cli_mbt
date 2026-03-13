///|
let default_jql : String = "assignee = currentUser() ORDER BY updated DESC"

///|
pub fn parse_args(args : ArrayView[String]) -> Result[@types.Command, String] {
  match args {
    ["help" | "--help" | "-h", ..] => Ok(@types.Help)
    ["config", .. rest] => parse_config(rest)
    ["issues", .. rest] => parse_issues_cmd(rest)
    ["issue", key, .. rest] => parse_issue_cmd(key, rest)
    ["issue", ..] => Err("Usage: issue <key>")
    ["create", .. rest] => parse_create(rest)
    ["update", .. rest] => parse_update(rest)
    ["transition", .. rest] => parse_transition(rest)
    ["comment", .. rest] => parse_comment(rest)
    ["assign", .. rest] => parse_assign(rest)
    ["search", .. rest] => parse_search(rest)
    ["projects"] => Ok(@types.ListProjects)
    ["fields", field_id, .. rest] => parse_get_field(field_id, rest)
    ["fields"] => Ok(@types.ListFields)
    [] => Ok(@types.Help)
    [cmd, ..] => Err("Unknown command: \{cmd}")
  }
}

///|
pub fn parse_request(
  args : ArrayView[String],
) -> Result[@types.Invocation, String] {
  let (output_format, command) = parse_command_line(args)
  match command {
    Ok(command) => Ok({ command, output_format })
    Err(message) => Err(message)
  }
}

///|
pub fn parse_command_line(
  args : ArrayView[String],
) -> (@types.OutputFormat, Result[@types.Command, String]) {
  match extract_output_format(args) {
    Err(message) => (@types.Table, Err(message))
    Ok((output_format, remaining)) => (output_format, parse_args(remaining[:]))
  }
}

///|
fn extract_output_format(
  args : ArrayView[String],
) -> Result[(@types.OutputFormat, Array[String]), String] {
  let remaining : Array[String] = []
  let mut output_format = @types.Table
  let mut i = 0
  while i < args.length() {
    if args[i] == "--format" {
      guard i + 1 < args.length() && not(args[i + 1].has_prefix("--")) else {
        return Err("Missing value for flag: --format")
      }
      match @types.parse_output_format(args[i + 1]) {
        Ok(format) => output_format = format
        Err(message) => return Err(message)
      }
      i = i + 2
    } else {
      remaining.push(args[i])
      i = i + 1
    }
  }
  Ok((output_format, remaining))
}

///|
fn collect_value(
  flag : String,
  args : ArrayView[String],
) -> Result[(String, ArrayView[String]), String] {
  guard args.length() > 0 && not(args[0].has_prefix("--")) else {
    return Err("Missing value for flag: \{flag}")
  }
  let parts : Array[String] = []
  let mut rest = args
  while rest.length() > 0 && not(rest[0].has_prefix("--")) {
    parts.push(rest[0])
    rest = rest[1:]
  }
  Ok((parts.join(" "), rest))
}

///|
let config_flags : Map[String, String] = {
  "--base-url": "base_url",
  "--email": "email",
  "--api-token": "api_token",
}

///|
let issues_flags : Map[String, String] = {
  "--jql": "jql",
  "--fields": "fields",
}

///|
let issue_flags : Map[String, String] = { "--fields": "fields" }

///|
let create_flags : Map[String, String] = {
  "--project": "project",
  "--summary": "summary",
  "--type": "issue_type",
  "--description": "description",
}

///|
let transition_flags : Map[String, String] = {
  "--key": "key",
  "--status": "status",
}

///|
let comment_flags : Map[String, String] = { "--key": "key", "--text": "text" }

///|
let assign_flags : Map[String, String] = { "--key": "key", "--email": "email" }

///|
let search_flags : Map[String, String] = { "--jql": "jql" }

///|
fn parse_flags(
  args : ArrayView[String],
  allowed_flags : Map[String, String],
  acc : Map[String, String],
) -> Result[Map[String, String], String] {
  if args.length() == 0 {
    return Ok(acc)
  }
  match allowed_flags.get(args[0]) {
    Some(key) =>
      match collect_value(args[0], args[1:]) {
        Ok((value, rest)) =>
          parse_flags(rest, allowed_flags, acc..set(key, value))
        Err(message) => Err(message)
      }
    None => Err("Unknown flag or unexpected argument: \{args[0]}")
  }
}

///|
fn parse_config(args : ArrayView[String]) -> Result[@types.Command, String] {
  match parse_flags(args, config_flags, {}) {
    Ok(flags) =>
      match
        (flags.get("base_url"), flags.get("email"), flags.get("api_token")) {
        (Some(base_url), Some(email), Some(api_token)) =>
          Ok(@types.Config(base_url~, email~, api_token~))
        _ =>
          Err(
            "Usage: config --base-url <url> --email <email> --api-token <token>",
          )
      }
    Err(message) => Err(message)
  }
}

///|
fn parse_issue_fields(
  value : String,
) -> Result[Array[@types.IssueField], String] {
  let names = value
    .split(",")
    .map(fn(name) { name.trim().to_string() })
    .filter(fn(name) { name.length() > 0 })
    .to_array()
  guard not(names.is_empty()) else {
    return Err("Field list must not be empty")
  }
  names.fold(init=Ok([]), fn(acc, name) {
    match (acc, @types.parse_issue_field(name)) {
      (Err(message), _) => Err(message)
      (_, Err(message)) => Err(message)
      (Ok(fields), Ok(field)) =>
        Ok(if fields.contains(field) { fields } else { [..fields, field] })
    }
  })
}

///|
fn resolve_issue_fields(
  value : String?,
  default_fields : Array[@types.IssueField],
) -> Result[Array[@types.IssueField], String] {
  match value {
    Some(fields) => parse_issue_fields(fields)
    None => Ok(default_fields)
  }
}

///|
fn parse_issues_cmd(args : ArrayView[String]) -> Result[@types.Command, String] {
  match parse_flags(args, issues_flags, {}) {
    Ok(flags) =>
      match
        resolve_issue_fields(
          flags.get("fields"),
          @types.default_list_issue_fields(),
        ) {
        Ok(fields) => {
          let jql = flags.get("jql").unwrap_or(default_jql)
          Ok(@types.ListIssues(jql~, fields~))
        }
        Err(message) => Err(message)
      }
    Err(message) => Err(message)
  }
}

///|
fn parse_issue_cmd(
  key : String,
  args : ArrayView[String],
) -> Result[@types.Command, String] {
  match parse_flags(args, issue_flags, {}) {
    Ok(flags) =>
      match
        resolve_issue_fields(
          flags.get("fields"),
          @types.default_detail_issue_fields(),
        ) {
        Ok(fields) => Ok(@types.GetIssue(key~, fields~))
        Err(message) => Err(message)
      }
    Err(message) => Err(message)
  }
}

///|
fn parse_one_set_entry(value : String) -> Result[(String, String), String] {
  let idx = {
    let mut found = -1
    for i in 0..<value.length() {
      if value[i].to_int().unsafe_to_char() == '=' {
        found = i
        break
      }
    }
    found
  }
  guard idx > 0 else {
    return Err(
      "Invalid --set format: '\{value}'. Expected 'customfield_<id>=<value>'",
    )
  }
  let key_buf = StringBuilder::new()
  for i in 0..<idx {
    key_buf.write_char(value[i].to_int().unsafe_to_char())
  }
  let key = key_buf.to_string()
  let val_buf = StringBuilder::new()
  for i in (idx + 1)..<value.length() {
    val_buf.write_char(value[i].to_int().unsafe_to_char())
  }
  let val = val_buf.to_string()
  guard key.has_prefix("customfield_") && key.length() > "customfield_".length() else {
    return Err(
      "Only customfield_* fields are allowed with --set, got: '\{key}'",
    )
  }
  guard val.length() > 0 else {
    return Err(
      "Empty value for --set field '\{key}'. Expected 'customfield_<id>=<value>'",
    )
  }
  Ok((key, val))
}

///|
fn extract_set_flags(
  args : ArrayView[String],
) -> Result[(Array[(String, String)], Array[String]), String] {
  let set_entries : Array[(String, String)] = []
  let rest : Array[String] = []
  let mut i = 0
  while i < args.length() {
    if args[i] == "--set" {
      match collect_value("--set", args[i + 1:]) {
        Err(msg) => return Err(msg)
        Ok((value, remaining)) => {
          match parse_one_set_entry(value) {
            Ok(entry) => set_entries.push(entry)
            Err(msg) => return Err(msg)
          }
          let consumed = args.length() - i - 1 - remaining.length()
          i = i + 1 + consumed
        }
      }
    } else {
      rest.push(args[i])
      i = i + 1
    }
  }
  Ok((set_entries, rest))
}

///|
fn parse_create(args : ArrayView[String]) -> Result[@types.Command, String] {
  match extract_set_flags(args) {
    Err(message) => Err(message)
    Ok((set_entries, rest)) =>
      match parse_flags(rest[:], create_flags, {}) {
        Ok(flags) =>
          match (flags.get("project"), flags.get("summary")) {
            (Some(project), Some(summary)) => {
              let issue_type = flags.get("issue_type").unwrap_or("Task")
              let description = flags.get("description").unwrap_or("")
              let custom_fields : Map[String, String] = {}
              for entry in set_entries {
                custom_fields[entry.0] = entry.1
              }
              Ok(
                @types.CreateIssue(
                  project~,
                  summary~,
                  issue_type~,
                  description~,
                  custom_fields~,
                ),
              )
            }
            _ =>
              Err(
                "Usage: create --project <key> --summary <text> [--type <type>] [--description <text>] [--set <field=value>]...",
              )
          }
        Err(message) => Err(message)
      }
  }
}

///|
fn parse_transition(args : ArrayView[String]) -> Result[@types.Command, String] {
  match parse_flags(args, transition_flags, {}) {
    Ok(flags) =>
      match (flags.get("key"), flags.get("status")) {
        (Some(key), Some(status)) => Ok(@types.Transition(key~, status~))
        _ => Err("Usage: transition --key <key> --status <status>")
      }
    Err(message) => Err(message)
  }
}

///|
fn parse_comment(args : ArrayView[String]) -> Result[@types.Command, String] {
  match parse_flags(args, comment_flags, {}) {
    Ok(flags) =>
      match (flags.get("key"), flags.get("text")) {
        (Some(key), Some(text)) => Ok(@types.Comment(key~, text~))
        _ => Err("Usage: comment --key <key> --text <text>")
      }
    Err(message) => Err(message)
  }
}

///|
fn parse_assign(args : ArrayView[String]) -> Result[@types.Command, String] {
  match parse_flags(args, assign_flags, {}) {
    Ok(flags) =>
      match (flags.get("key"), flags.get("email")) {
        (Some(key), Some(email)) => Ok(@types.Assign(key~, email~))
        _ => Err("Usage: assign --key <key> --email <email>")
      }
    Err(message) => Err(message)
  }
}

///|
fn parse_search(args : ArrayView[String]) -> Result[@types.Command, String] {
  match parse_flags(args, search_flags, {}) {
    Ok(flags) =>
      match flags.get("jql") {
        Some(jql) => Ok(@types.Search(jql~))
        None => Err("Usage: search --jql <jql>")
      }
    Err(message) => Err(message)
  }
}

///|
let update_flags : Map[String, String] = {
  "--summary": "summary",
  "--description": "description",
  "--priority": "priority",
  "--type": "issue_type",
  "--labels": "labels",
  "--assignee": "assignee",
}

///|
let update_usage : String = "Usage: update <key> [--summary <text>] [--description <text>] [--priority <name>] [--type <name>] [--labels <label1,label2>] [--assignee <email>] [--set <field=value>]..."

///|
let get_field_flags : Map[String, String] = {
  "--project": "project",
  "--type": "issue_type",
}

///|
fn parse_get_field(
  field_id : String,
  args : ArrayView[String],
) -> Result[@types.Command, String] {
  match parse_flags(args, get_field_flags, {}) {
    Ok(flags) => {
      let project = flags.get("project").unwrap_or("")
      let issue_type = flags.get("issue_type").unwrap_or("")
      if issue_type.length() > 0 && project.length() == 0 {
        return Err("--type requires --project to be specified")
      }
      Ok(@types.GetField(field_id~, project~, issue_type~))
    }
    Err(msg) => Err(msg)
  }
}

///|
fn parse_update(args : ArrayView[String]) -> Result[@types.Command, String] {
  guard args.length() > 0 && not(args[0].has_prefix("--")) else {
    return Err(update_usage)
  }
  let key = args[0]
  let rest = args[1:]
  match extract_set_flags(rest) {
    Err(message) => Err(message)
    Ok((set_entries, remaining)) =>
      match parse_flags(remaining[:], update_flags, {}) {
        Err(message) => Err(message)
        Ok(flags) => {
          let summary = flags.get("summary").unwrap_or("")
          let description = flags.get("description").unwrap_or("")
          let priority = flags.get("priority").unwrap_or("")
          let issue_type = flags.get("issue_type").unwrap_or("")
          let labels = flags.get("labels").unwrap_or("")
          let assignee = flags.get("assignee").unwrap_or("")
          let custom_fields : Map[String, String] = {}
          for entry in set_entries {
            custom_fields[entry.0] = entry.1
          }
          guard summary.length() > 0 ||
            description.length() > 0 ||
            priority.length() > 0 ||
            issue_type.length() > 0 ||
            labels.length() > 0 ||
            assignee.length() > 0 ||
            custom_fields.length() > 0 else {
            return Err(
              "At least one field must be specified for update\n" + update_usage,
            )
          }
          Ok(
            @types.UpdateIssue(
              key~,
              summary~,
              description~,
              priority~,
              issue_type~,
              labels~,
              assignee~,
              custom_fields~,
            ),
          )
        }
      }
  }
}
