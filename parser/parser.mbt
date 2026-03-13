///|
let default_jql : String = "assignee = currentUser() ORDER BY updated DESC"

///|
pub fn parse_args(args : ArrayView[String]) -> Result[@types.Command, String] {
  match parse_trailing_help(args) {
    Some(command) => return Ok(command)
    None => ()
  }
  match args {
    [] => Ok(@types.Help(command_name=""))
    ["help" | "--help" | "-h"] => Ok(@types.Help(command_name=""))
    ["help" | "--help" | "-h", .. rest] => parse_help_target(rest)
    ["describe", .. rest] => parse_describe_target(rest)
    ["config", .. rest] => parse_config(rest)
    ["issue", .. rest] => parse_issue_group(rest)
    ["project", .. rest] => parse_project_group(rest)
    ["field", .. rest] => parse_field_group(rest)
    ["issues", .. rest] => parse_issues_cmd(rest)
    ["create", .. rest] => parse_create(rest)
    ["update", .. rest] => parse_update(rest)
    ["transition", .. rest] => parse_transition(rest)
    ["comment", .. rest] => parse_comment(rest)
    ["assign", .. rest] => parse_assign(rest)
    ["search", .. rest] => parse_search(rest)
    ["projects", .. rest] => parse_project_list(rest)
    ["fields", field_id, .. rest] if not(field_id.has_prefix("--")) =>
      parse_get_field(field_id, rest)
    ["fields", .. rest] => parse_field_list(rest)
    [cmd, ..] => Err("Unknown command: \{cmd}")
  }
}

///|
fn parse_help_target(
  command_name_parts : ArrayView[String],
) -> Result[@types.Command, String] {
  if command_name_parts.length() == 0 {
    return Ok(@types.Help(command_name=""))
  }
  match @types.require_command_spec(join_tokens(command_name_parts)) {
    Ok(spec) => Ok(@types.Help(command_name=spec.name))
    Err(message) => Err(message)
  }
}

///|
fn parse_describe_target(
  command_name_parts : ArrayView[String],
) -> Result[@types.Command, String] {
  guard command_name_parts.length() > 0 else {
    return Err("Usage: describe <command>")
  }
  match @types.require_command_spec(join_tokens(command_name_parts)) {
    Ok(spec) => Ok(@types.Describe(command_name=spec.name))
    Err(message) => Err(message)
  }
}

///|
fn join_tokens(tokens : ArrayView[String]) -> String {
  let parts : Array[String] = []
  let mut i = 0
  while i < tokens.length() {
    parts.push(tokens[i])
    i = i + 1
  }
  parts.join(" ")
}

///|
fn parse_trailing_help(args : ArrayView[String]) -> @types.Command? {
  guard args.length() >= 2 else { return None }
  let last = args[args.length() - 1]
  guard last == "--help" || last == "-h" else { return None }
  let target = resolve_trailing_help_target(args)
  match target {
    Some(command_name) => Some(@types.Help(command_name~))
    None => None
  }
}

///|
fn resolve_trailing_help_target(args : ArrayView[String]) -> String? {
  let tokens : Array[String] = []
  let mut i = 0
  while i < args.length() - 1 {
    tokens.push(args[i])
    i = i + 1
  }
  let target = tokens.join(" ")
  match @types.find_command_spec(target) {
    Some(spec) => Some(spec.name)
    None =>
      match tokens {
        ["issue", key, ..] if not(key.has_prefix("--")) => Some("issue get")
        ["fields", field_id, ..] if not(field_id.has_prefix("--")) =>
          Some("field get")
        ["field", "get", field_id, ..] if not(field_id.has_prefix("--")) =>
          Some("field get")
        _ => None
      }
  }
}

///|
fn parse_issue_group(
  args : ArrayView[String],
) -> Result[@types.Command, String] {
  match args {
    [] => Ok(@types.Help(command_name="issue"))
    ["list", .. rest] => parse_issues_cmd(rest)
    ["get", key, .. rest] => parse_issue_cmd(key, rest)
    ["get"] => Err("Usage: issue get <key>")
    ["create", .. rest] => parse_create(rest)
    ["update", .. rest] => parse_update(rest)
    ["transition", .. rest] => parse_transition(rest)
    ["comment", .. rest] => parse_comment(rest)
    ["assign", .. rest] => parse_assign(rest)
    ["search", .. rest] => parse_search(rest)
    [key, .. rest] if not(key.has_prefix("--")) => parse_issue_cmd(key, rest)
    [subcommand, ..] => Err("Unknown issue subcommand: \{subcommand}")
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
fn extract_switch_flag(
  flag : String,
  args : ArrayView[String],
) -> (Bool, Array[String]) {
  let remaining : Array[String] = []
  let mut found = false
  let mut i = 0
  while i < args.length() {
    if args[i] == flag {
      found = true
    } else {
      remaining.push(args[i])
    }
    i = i + 1
  }
  (found, remaining)
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
  "--limit": "limit",
  "--start-at": "start_at",
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
let search_flags : Map[String, String] = {
  "--jql": "jql",
  "--limit": "limit",
  "--start-at": "start_at",
}

///|
let list_page_flags : Map[String, String] = {
  "--limit": "limit",
  "--start-at": "start_at",
}

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
  match extract_all_flag(args) {
    Err(message) => Err(message)
    Ok((fetch_all, rest)) =>
      match parse_flags(rest[:], issues_flags, {}) {
        Ok(flags) =>
          match
            (
              resolve_issue_fields(
                flags.get("fields"),
                @types.default_list_issue_fields(),
              ),
              resolve_page_request(
                flags,
                fetch_all,
                default_limit=20,
                default_fetch_all=false,
                usage=issues_usage,
              ),
            ) {
            (Ok(fields), Ok(page_request)) => {
              let jql = flags.get("jql").unwrap_or(default_jql)
              Ok(@types.ListIssues(jql~, fields~, page_request~))
            }
            (Err(message), _) => Err(message)
            (_, Err(message)) => Err(message)
          }
        Err(message) => Err(message)
      }
  }
}

///|
let issues_usage : String = "Usage: issue list [--jql <jql>] [--fields <field,...>] [--limit <n>] [--start-at <n>] [--all]"

///|
let search_usage : String = "Usage: search --jql <jql> [--limit <n>] [--start-at <n>] [--all]"

///|
let project_list_usage : String = "Usage: project list [--limit <n>] [--start-at <n>] [--all]"

///|
let field_list_usage : String = "Usage: field list [--limit <n>] [--start-at <n>] [--all]"

///|
fn parse_non_negative_int(flag : String, value : String) -> Result[Int, String] {
  guard value.length() > 0 else { return Err("\{flag} must not be empty") }
  let mut parsed = 0
  for i in 0..<value.length() {
    let c = value[i].to_int().unsafe_to_char()
    guard c >= '0' && c <= '9' else {
      return Err("\{flag} must be a non-negative integer")
    }
    parsed = parsed * 10 + (c.to_int() - '0'.to_int())
  }
  Ok(parsed)
}

///|
fn parse_positive_int(flag : String, value : String) -> Result[Int, String] {
  match parse_non_negative_int(flag, value) {
    Ok(parsed) if parsed > 0 => Ok(parsed)
    Ok(_) => Err("\{flag} must be greater than zero")
    Err(message) => Err(message)
  }
}

///|
fn extract_all_flag(
  args : ArrayView[String],
) -> Result[(Bool, Array[String]), String] {
  let rest : Array[String] = []
  let mut fetch_all = false
  let mut i = 0
  while i < args.length() {
    if args[i] == "--all" {
      fetch_all = true
    } else {
      rest.push(args[i])
    }
    i = i + 1
  }
  Ok((fetch_all, rest))
}

///|
fn resolve_page_request(
  flags : Map[String, String],
  fetch_all : Bool,
  default_limit~ : Int,
  default_fetch_all~ : Bool,
  usage~ : String,
) -> Result[@types.PageRequest, String] {
  if fetch_all && flags.contains("limit") {
    return Err("--all cannot be combined with --limit\n" + usage)
  }
  let start_at = match flags.get("start_at") {
    Some(value) => parse_non_negative_int("--start-at", value)
    None => Ok(0)
  }
  let limit = match flags.get("limit") {
    Some(value) => parse_positive_int("--limit", value)
    None => Ok(default_limit)
  }
  match (start_at, limit) {
    (Err(message), _) => Err(message)
    (_, Err(message)) => Err(message)
    (Ok(start_at), Ok(limit)) =>
      Ok(
        if flags.contains("limit") {
          @types.limited_page_request(limit, start_at~)
        } else if fetch_all || default_fetch_all {
          @types.full_page_request(start_at~)
        } else {
          @types.limited_page_request(limit, start_at~)
        },
      )
  }
}

///|
fn parse_project_list(
  args : ArrayView[String],
) -> Result[@types.Command, String] {
  match extract_all_flag(args) {
    Err(message) => Err(message)
    Ok((fetch_all, rest)) =>
      match parse_flags(rest[:], list_page_flags, {}) {
        Ok(flags) =>
          match
            resolve_page_request(
              flags,
              fetch_all,
              default_limit=0,
              default_fetch_all=true,
              usage=project_list_usage,
            ) {
            Ok(page_request) => Ok(@types.ListProjects(page_request~))
            Err(message) => Err(message)
          }
        Err(message) => Err(message)
      }
  }
}

///|
fn parse_field_list(args : ArrayView[String]) -> Result[@types.Command, String] {
  match extract_all_flag(args) {
    Err(message) => Err(message)
    Ok((fetch_all, rest)) =>
      match parse_flags(rest[:], list_page_flags, {}) {
        Ok(flags) =>
          match
            resolve_page_request(
              flags,
              fetch_all,
              default_limit=0,
              default_fetch_all=true,
              usage=field_list_usage,
            ) {
            Ok(page_request) => Ok(@types.ListFields(page_request~))
            Err(message) => Err(message)
          }
        Err(message) => Err(message)
      }
  }
}

///|
fn parse_search(args : ArrayView[String]) -> Result[@types.Command, String] {
  match extract_all_flag(args) {
    Err(message) => Err(message)
    Ok((fetch_all, rest)) =>
      match parse_flags(rest[:], search_flags, {}) {
        Ok(flags) =>
          match
            (
              flags.get("jql"),
              resolve_page_request(
                flags,
                fetch_all,
                default_limit=20,
                default_fetch_all=false,
                usage=search_usage,
              ),
            ) {
            (Some(jql), Ok(page_request)) =>
              Ok(@types.Search(jql~, page_request~))
            (None, _) => Err(search_usage)
            (_, Err(message)) => Err(message)
          }
        Err(message) => Err(message)
      }
  }
}

///|
fn parse_project_group(
  args : ArrayView[String],
) -> Result[@types.Command, String] {
  match args {
    [] => Ok(@types.Help(command_name="project"))
    ["list", .. rest] => parse_project_list(rest)
    [subcommand, ..] => Err("Unknown project subcommand: \{subcommand}")
  }
}

///|
fn parse_field_group(
  args : ArrayView[String],
) -> Result[@types.Command, String] {
  match args {
    [] => Ok(@types.Help(command_name="field"))
    ["list", .. rest] => parse_field_list(rest)
    ["get", field_id, .. rest] => parse_get_field(field_id, rest)
    ["get"] => Err("Usage: field get <customfield_<id>>")
    [field_id, .. rest] if not(field_id.has_prefix("--")) =>
      parse_get_field(field_id, rest)
    [subcommand, ..] => Err("Unknown field subcommand: \{subcommand}")
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
  let (dry_run, remaining) = extract_switch_flag("--dry-run", args)
  match extract_set_flags(remaining[:]) {
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
                  dry_run~,
                ),
              )
            }
            _ =>
              Err(
                "Usage: create --project <key> --summary <text> [--type <type>] [--description <text>] [--set <field=value>]... [--dry-run]",
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
let update_flags : Map[String, String] = {
  "--summary": "summary",
  "--description": "description",
  "--priority": "priority",
  "--type": "issue_type",
  "--labels": "labels",
  "--assignee": "assignee",
}

///|
let update_usage : String = "Usage: update <key> [--summary <text>] [--description <text>] [--priority <name>] [--type <name>] [--labels <label1,label2>] [--assignee <email>] [--set <field=value>]... [--dry-run]"

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
  let (dry_run, rest) = extract_switch_flag("--dry-run", args[1:])
  match extract_set_flags(rest[:]) {
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
              dry_run~,
            ),
          )
        }
      }
  }
}
