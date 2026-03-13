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
fn sanitize_delimited_cell(s : String) -> String {
  let buf = StringBuilder::new()
  for i in 0..<s.length() {
    let c = s[i].to_int().unsafe_to_char()
    if c == '\t' || c == '\n' || c == '\r' {
      buf.write_char(' ')
    } else {
      buf.write_char(c)
    }
  }
  buf.to_string()
}

///|
fn format_tsv_row(cells : Array[String]) -> String {
  cells.map(sanitize_delimited_cell).join("\t")
}

///|
fn json_string(value : String) -> String {
  @core.json_stringify(@core.any(value))
}

///|
fn json_bool(value : Bool) -> String {
  if value {
    "true"
  } else {
    "false"
  }
}

///|
fn json_int(value : Int) -> String {
  value.to_string()
}

///|
fn json_array(items : Array[String]) -> String {
  "[" + items.join(",") + "]"
}

///|
fn json_object(entries : Array[(String, String)]) -> String {
  "{" +
  entries.map(fn(entry) { json_string(entry.0) + ":" + entry.1 }).join(",") +
  "}"
}

///|
fn json_envelope(
  kind : String,
  payload_key : String,
  payload_json : String,
) -> String {
  json_object([
    ("schema_version", json_string("v1")),
    ("kind", json_string(kind)),
    (payload_key, payload_json),
  ])
}

///|
fn issue_field_name(field : @types.IssueField) -> String {
  match field {
    @types.Key => "key"
    @types.Summary => "summary"
    @types.Status => "status"
    @types.Assignee => "assignee"
    @types.IssueType => "type"
    @types.Priority => "priority"
    @types.Description => "description"
    @types.Custom(name) => name
  }
}

///|
fn issue_json(
  issue : @types.JiraIssue,
  fields : Array[@types.IssueField],
) -> String {
  json_object(
    fields.map(fn(field) {
      (issue_field_name(field), json_string(issue.field_value(field)))
    }),
  )
}

///|
fn field_json(field : @types.JiraField) -> String {
  json_object([
    ("id", json_string(field.id)),
    ("name", json_string(field.name)),
    ("custom", json_bool(field.custom)),
    ("type", json_string(field.schema_type)),
    ("custom_type", json_string(field.schema_custom)),
  ])
}

///|
fn option_json(option : @types.JiraFieldOption) -> String {
  json_object([
    ("id", json_string(option.id)),
    ("value", json_string(option.value)),
  ])
}

///|
fn project_json(project : @types.JiraProject) -> String {
  json_object([
    ("key", json_string(project.key)),
    ("name", json_string(project.name)),
    ("project_type", json_string(project.project_type)),
  ])
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
fn format_issue_list_tsv(
  issues : Array[@types.JiraIssue],
  fields : Array[@types.IssueField],
) -> String {
  let headers = fields.map(issue_field_name)
  let rows = issues.map(fn(issue) {
    fields.map(fn(field) { issue.field_value(field) })
  })
  [format_tsv_row(headers), ..rows.map(format_tsv_row)].join("\n")
}

///|
fn format_issue_list_json(
  issues : Array[@types.JiraIssue],
  fields : Array[@types.IssueField],
  kind : String,
) -> String {
  json_object([
    ("schema_version", json_string("v1")),
    ("kind", json_string(kind)),
    (
      "fields",
      json_array(fields.map(fn(field) { json_string(issue_field_name(field)) })),
    ),
    ("items", json_array(issues.map(fn(issue) { issue_json(issue, fields) }))),
  ])
}

///|
pub fn format_issue_list_for_output(
  issues : Array[@types.JiraIssue],
  fields : Array[@types.IssueField],
  output_format : @types.OutputFormat,
  kind? : String = "issues",
) -> String {
  match output_format {
    @types.Table => format_issue_list(issues, fields)
    @types.Tsv => format_issue_list_tsv(issues, fields)
    @types.Json => format_issue_list_json(issues, fields, kind)
  }
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
fn format_issue_detail_tsv(
  issue : @types.JiraIssue,
  fields : Array[@types.IssueField],
) -> String {
  let rows = fields.filter_map(fn(field) {
    let value = issue.field_value(field)
    match (field, value) {
      (@types.Description, "") => None
      _ => Some([issue_field_name(field), value])
    }
  })
  [format_tsv_row(["field", "value"]), ..rows.map(format_tsv_row)].join("\n")
}

///|
fn format_issue_detail_json(
  issue : @types.JiraIssue,
  fields : Array[@types.IssueField],
) -> String {
  json_object([
    ("schema_version", json_string("v1")),
    ("kind", json_string("issue")),
    (
      "fields",
      json_array(fields.map(fn(field) { json_string(issue_field_name(field)) })),
    ),
    ("item", issue_json(issue, fields)),
  ])
}

///|
pub fn format_issue_detail_for_output(
  issue : @types.JiraIssue,
  fields : Array[@types.IssueField],
  output_format : @types.OutputFormat,
) -> String {
  match output_format {
    @types.Table => format_issue_detail(issue, fields)
    @types.Tsv => format_issue_detail_tsv(issue, fields)
    @types.Json => format_issue_detail_json(issue, fields)
  }
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
fn format_projects_tsv(projects : Array[@types.JiraProject]) -> String {
  let rows = projects.map(fn(project) {
    [project.key, project.name, project.project_type]
  })
  [format_tsv_row(["key", "name", "project_type"]), ..rows.map(format_tsv_row)].join(
    "\n",
  )
}

///|
fn format_projects_json(projects : Array[@types.JiraProject]) -> String {
  json_envelope("projects", "items", json_array(projects.map(project_json)))
}

///|
pub fn format_projects_for_output(
  projects : Array[@types.JiraProject],
  output_format : @types.OutputFormat,
) -> String {
  match output_format {
    @types.Table => format_projects(projects)
    @types.Tsv => format_projects_tsv(projects)
    @types.Json => format_projects_json(projects)
  }
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
fn format_fields_tsv(fields : Array[@types.JiraField]) -> String {
  let rows = fields.map(fn(field) {
    [field.id, field.name, field.schema_type, field.schema_custom]
  })
  [
    format_tsv_row(["id", "name", "type", "custom_type"]),
    ..rows.map(format_tsv_row),
  ].join("\n")
}

///|
fn format_fields_json(fields : Array[@types.JiraField]) -> String {
  json_envelope("fields", "items", json_array(fields.map(field_json)))
}

///|
pub fn format_fields_for_output(
  fields : Array[@types.JiraField],
  output_format : @types.OutputFormat,
) -> String {
  match output_format {
    @types.Table => format_fields(fields)
    @types.Tsv => format_fields_tsv(fields)
    @types.Json => format_fields_json(fields)
  }
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
fn format_field_detail_tsv(detail : @types.JiraFieldDetail) -> String {
  let rows = [
    ["field", "id", detail.field.id],
    ["field", "name", detail.field.name],
    ["field", "type", detail.field.schema_type],
    ["field", "custom_type", detail.field.schema_custom],
    ..detail.options.map(fn(option) { ["option", option.id, option.value] }),
  ]
  [format_tsv_row(["section", "name", "value"]), ..rows.map(format_tsv_row)].join(
    "\n",
  )
}

///|
fn format_field_detail_json(detail : @types.JiraFieldDetail) -> String {
  json_envelope(
    "field_detail",
    "item",
    json_object([
      ("field", field_json(detail.field)),
      ("options", json_array(detail.options.map(option_json))),
    ]),
  )
}

///|
pub fn format_field_detail_for_output(
  detail : @types.JiraFieldDetail,
  output_format : @types.OutputFormat,
) -> String {
  match output_format {
    @types.Table => format_field_detail(detail)
    @types.Tsv => format_field_detail_tsv(detail)
    @types.Json => format_field_detail_json(detail)
  }
}

///|
pub fn format_issue_types_for_output(
  project : String,
  issue_types : Array[(String, String)],
  output_format : @types.OutputFormat,
) -> String {
  match output_format {
    @types.Table => {
      let headers = ["ID", "NAME"]
      let widths = [12, 30]
      let rows = issue_types.map(fn(entry) { [entry.0, entry.1] })
      "Please specify --type. Available issue types for \{project}:\n" +
      format_table(headers, rows, widths)
    }
    @types.Tsv => {
      let rows = issue_types.map(fn(entry) { [entry.0, entry.1] })
      [format_tsv_row(["id", "name"]), ..rows.map(format_tsv_row)].join("\n")
    }
    @types.Json =>
      json_object([
        ("schema_version", json_string("v1")),
        ("kind", json_string("issue_types")),
        ("project", json_string(project)),
        (
          "items",
          json_array(
            issue_types.map(fn(entry) {
              json_object([
                ("id", json_string(entry.0)),
                ("name", json_string(entry.1)),
              ])
            }),
          ),
        ),
      ])
  }
}

///|
pub fn format_error_for_output(
  category : @types.CliErrorCategory,
  message : String,
  output_format : @types.OutputFormat,
  usage? : String = "",
) -> String {
  match output_format {
    @types.Json =>
      json_object(
        [
          ("schema_version", json_string("v1")),
          ("kind", json_string("error")),
          ("category", json_string(category.name())),
          ("exit_code", json_int(category.exit_code())),
          ("message", json_string(message)),
          ..if usage.length() > 0 {
            [("usage", json_string(usage))]
          } else {
            []
          },
        ],
      )
    _ =>
      if usage.length() > 0 {
        usage + "\n\nError: " + message
      } else {
        "Error: " + message
      }
  }
}

///|
fn yes_no(value : Bool) -> String {
  if value {
    "yes"
  } else {
    "no"
  }
}

///|
fn default_label(value : String) -> String {
  if value.length() == 0 {
    "-"
  } else {
    value
  }
}

///|
fn format_names(values : Array[String]) -> String {
  if values.is_empty() {
    "none"
  } else {
    values.join(", ")
  }
}

///|
fn format_output_formats(formats : Array[@types.OutputFormat]) -> String {
  format_names(formats.map(fn(format) { format.name() }))
}

///|
fn command_positional_json(spec : @types.CommandPositionalSpec) -> String {
  json_object([
    ("name", json_string(spec.name)),
    ("description", json_string(spec.description)),
    ("required", json_bool(spec.required)),
  ])
}

///|
fn command_flag_json(spec : @types.CommandFlagSpec) -> String {
  json_object([
    ("name", json_string(spec.name)),
    ("value_name", json_string(spec.value_name)),
    ("description", json_string(spec.description)),
    ("required", json_bool(spec.required)),
    ("repeatable", json_bool(spec.repeatable)),
    ("default_value", json_string(spec.default_value)),
    ("aliases", json_array(spec.aliases.map(json_string))),
  ])
}

///|
fn command_spec_json(spec : @types.CommandSpec) -> String {
  json_object([
    ("name", json_string(spec.name)),
    ("summary", json_string(spec.summary)),
    ("usage", json_string("jira-cli " + spec.usage)),
    ("aliases", json_array(spec.aliases.map(json_string))),
    ("positionals", json_array(spec.positionals.map(command_positional_json))),
    ("flags", json_array(spec.flags.map(command_flag_json))),
    (
      "output_formats",
      json_array(
        spec.output_formats.map(fn(format) { json_string(format.name()) }),
      ),
    ),
    (
      "default_output_format",
      json_string(if spec.output_formats.is_empty() { "" } else { "table" }),
    ),
    ("notes", json_array(spec.notes.map(json_string))),
    ("examples", json_array(spec.examples.map(json_string))),
  ])
}

///|
fn format_command_description_tsv(spec : @types.CommandSpec) -> String {
  let rows : Array[Array[String]] = [
    ["command", "name", spec.name, "", "", "", "Canonical command name"],
    ["command", "summary", spec.summary, "", "", "", ""],
    ["command", "usage", "jira-cli " + spec.usage, "", "", "", ""],
  ]
  for alias_name in spec.aliases {
    rows.push(["alias", "command", alias_name, "", "", "", ""])
  }
  for positional in spec.positionals {
    rows.push([
      "positional",
      positional.name,
      "",
      yes_no(positional.required),
      "no",
      "",
      positional.description,
    ])
  }
  for flag in spec.flags {
    rows.push([
      "flag",
      flag.name,
      flag.value_name,
      yes_no(flag.required),
      yes_no(flag.repeatable),
      flag.default_value,
      flag.description,
    ])
    for flag_alias in flag.aliases {
      rows.push(["flag_alias", flag.name, flag_alias, "", "", "", ""])
    }
  }
  for format in spec.output_formats {
    rows.push(["output_format", format.name(), "", "", "", "", ""])
  }
  if not(spec.output_formats.is_empty()) {
    rows.push(["command", "default_output_format", "table", "", "", "", ""])
  }
  for note in spec.notes {
    rows.push(["note", "", note, "", "", "", ""])
  }
  for example in spec.examples {
    rows.push(["example", "", example, "", "", "", ""])
  }
  [
    format_tsv_row([
      "section", "name", "value", "required", "repeatable", "default_value", "description",
    ]),
    ..rows.map(format_tsv_row),
  ].join("\n")
}

///|
pub fn format_command_help(spec : @types.CommandSpec) -> String {
  let lines : Array[String] = [
    spec.name + " - " + spec.summary,
    "",
    "Usage:",
    "  jira-cli " + spec.usage,
  ]
  if not(spec.aliases.is_empty()) {
    lines.push("")
    lines.push("Aliases:")
    lines.push("  " + spec.aliases.join(", "))
  }
  if not(spec.positionals.is_empty()) {
    lines.push("")
    lines.push("Positional arguments:")
    let headers = ["NAME", "REQUIRED", "DESCRIPTION"]
    let widths = [18, 8, 56]
    let rows = spec.positionals.map(fn(positional) {
      [
        positional.name,
        yes_no(positional.required),
        truncate(positional.description, 56),
      ]
    })
    lines.push(format_table(headers, rows, widths))
  }
  if not(spec.flags.is_empty()) {
    lines.push("")
    lines.push("Flags:")
    let headers = [
      "FLAG", "VALUE", "REQUIRED", "REPEAT", "DEFAULT", "DESCRIPTION",
    ]
    let widths = [14, 24, 8, 6, 28, 44]
    let rows = spec.flags.map(fn(flag) {
      [
        flag.name,
        "<" + flag.value_name + ">",
        yes_no(flag.required),
        yes_no(flag.repeatable),
        truncate(default_label(flag.default_value), 28),
        truncate(flag.description, 44),
      ]
    })
    lines.push(format_table(headers, rows, widths))
  }
  if not(spec.output_formats.is_empty()) {
    lines.push("")
    lines.push("Output formats:")
    lines.push(
      "  " + format_output_formats(spec.output_formats) + " (default: table)",
    )
  }
  if not(spec.notes.is_empty()) {
    lines.push("")
    lines.push("Notes:")
    for note in spec.notes {
      lines.push("  - " + note)
    }
  }
  if not(spec.examples.is_empty()) {
    lines.push("")
    lines.push("Examples:")
    for example in spec.examples {
      lines.push("  " + example)
    }
  }
  lines.join("\n")
}

///|
pub fn format_command_description_for_output(
  spec : @types.CommandSpec,
  output_format : @types.OutputFormat,
) -> String {
  match output_format {
    @types.Table => format_command_help(spec)
    @types.Tsv => format_command_description_tsv(spec)
    @types.Json =>
      json_envelope("command_description", "command", command_spec_json(spec))
  }
}

///|
pub fn format_usage() -> String {
  let specs = @types.command_specs()
  let mut name_width = 0
  for spec in specs {
    if spec.name.length() > name_width {
      name_width = spec.name.length()
    }
  }
  let lines : Array[String] = [
    "Jira CLI (MoonBit)", "", "Usage: jira-cli <command> [options]", "Alias: jira-cli-mbt <command> [options]",
    "", "Global options:", "  --format    table | tsv | json (supported by read-only commands and describe, default: table)",
    "", "Commands:",
  ]
  for spec in specs {
    lines.push("  " + pad_right(spec.name, name_width) + " " + spec.summary)
    lines.push("              " + spec.usage)
  }
  lines.push("")
  lines.push("Run `jira-cli help <command>` for per-command help.")
  lines.push(
    "Run `jira-cli describe <command> --format json` for machine-readable metadata.",
  )
  lines.join("\n")
}
