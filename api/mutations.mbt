///|
fn sorted_custom_field_entries(
  custom_fields : Map[String, @types.CustomFieldInput],
) -> Array[(String, @types.CustomFieldInput)] {
  let entries = custom_fields
    .iter()
    .map(fn(entry) { (entry.0, entry.1) })
    .to_array()
  entries.sort_by_key(fn(entry) { entry.0 })
  entries
}

///|
fn normalized_label_values(labels : String) -> Array[String] {
  labels
  .split(",")
  .map(fn(label) { label.trim().to_string() })
  .filter(fn(label) { label.length() > 0 })
  .to_array()
}

///|
fn is_numeric_issue_reference(value : String) -> Bool {
  if value.length() == 0 {
    return false
  }
  for i in 0..<value.length() {
    let c = value[i].to_int().unsafe_to_char()
    if c < '0' || c > '9' {
      return false
    }
  }
  true
}

///|
fn parent_field_value(parent : String) -> @core.Any {
  if is_numeric_issue_reference(parent) {
    @core.from_entries([("id", @core.any(parent))])
  } else {
    @core.from_entries([("key", @core.any(parent))])
  }
}

///|
fn mutation_field_change(
  name : String,
  value : String,
) -> @types.MutationFieldChange {
  { name, value }
}

///|
fn mutation_operation(
  name : String,
  status : @types.MutationOperationStatus,
  detail : String,
) -> @types.MutationOperation {
  { name, status, detail }
}

///|
fn create_issue_field_changes(
  project : String,
  summary : String,
  issue_type : String,
  description : String,
  parent : String,
  custom_fields : Map[String, @types.CustomFieldInput],
) -> Array[@types.MutationFieldChange] {
  let changes : Array[@types.MutationFieldChange] = [
    mutation_field_change("project", project),
    mutation_field_change("summary", summary),
    mutation_field_change("issue_type", issue_type),
  ]
  if description.length() > 0 {
    changes.push(mutation_field_change("description", description))
  }
  if parent.length() > 0 {
    changes.push(mutation_field_change("parent", parent))
  }
  for entry in sorted_custom_field_entries(custom_fields) {
    changes.push(mutation_field_change(entry.0, entry.1.display_value()))
  }
  changes
}

///|
fn update_issue_field_changes(
  summary : String,
  description : String,
  priority : String,
  issue_type : String,
  labels : String,
  parent : String,
  assignee : String,
  custom_fields : Map[String, @types.CustomFieldInput],
) -> Array[@types.MutationFieldChange] {
  let changes : Array[@types.MutationFieldChange] = []
  if summary.length() > 0 {
    changes.push(mutation_field_change("summary", summary))
  }
  if description.length() > 0 {
    changes.push(mutation_field_change("description", description))
  }
  if priority.length() > 0 {
    changes.push(mutation_field_change("priority", priority))
  }
  if issue_type.length() > 0 {
    changes.push(mutation_field_change("issue_type", issue_type))
  }
  let label_values = normalized_label_values(labels)
  if not(label_values.is_empty()) {
    changes.push(mutation_field_change("labels", label_values.join(",")))
  }
  if parent.length() > 0 {
    changes.push(mutation_field_change("parent", parent))
  }
  if assignee.length() > 0 {
    changes.push(mutation_field_change("assignee", assignee))
  }
  for entry in sorted_custom_field_entries(custom_fields) {
    changes.push(mutation_field_change(entry.0, entry.1.display_value()))
  }
  changes
}

///|
fn create_issue_field_entries(
  project : String,
  summary : String,
  issue_type : String,
  description : String,
  parent : String,
  custom_fields : Map[String, @types.CustomFieldInput],
) -> Array[(String, @core.Any)] {
  [
    ("project", @core.from_entries([("key", @core.any(project))])),
    ("summary", @core.any(summary)),
    ("issuetype", @core.from_entries([("name", @core.any(issue_type))])),
    ..if description.length() > 0 {
      [("description", build_adf_text(description))]
    } else {
      []
    },
    ..if parent.length() > 0 {
      [("parent", parent_field_value(parent))]
    } else {
      []
    },
    ..sorted_custom_field_entries(custom_fields).map(fn(entry) {
      (entry.0, custom_field_value(entry.1))
    }),
  ]
}

///|
fn update_issue_field_entries(
  summary : String,
  description : String,
  priority : String,
  issue_type : String,
  labels : String,
  parent : String,
  custom_fields : Map[String, @types.CustomFieldInput],
) -> Array[(String, @core.Any)] {
  let field_entries : Array[(String, @core.Any)] = []
  if summary.length() > 0 {
    field_entries.push(("summary", @core.any(summary)))
  }
  if description.length() > 0 {
    field_entries.push(("description", build_adf_text(description)))
  }
  if priority.length() > 0 {
    field_entries.push(
      ("priority", @core.from_entries([("name", @core.any(priority))])),
    )
  }
  if issue_type.length() > 0 {
    field_entries.push(
      ("issuetype", @core.from_entries([("name", @core.any(issue_type))])),
    )
  }
  let label_values = normalized_label_values(labels)
  if not(label_values.is_empty()) {
    field_entries.push(("labels", @core.any(label_values)))
  }
  if parent.length() > 0 {
    field_entries.push(("parent", parent_field_value(parent)))
  }
  for entry in sorted_custom_field_entries(custom_fields) {
    field_entries.push((entry.0, custom_field_value(entry.1)))
  }
  field_entries
}

///|
fn mutation_report(
  command : String,
  status : @types.MutationStatus,
  issue_key : String,
  project_key : String,
  message : String,
  field_changes : Array[@types.MutationFieldChange],
  operations : Array[@types.MutationOperation],
  discovery_hint? : @types.DiscoveryHint = @types.empty_discovery_hint(),
) -> @types.MutationReport {
  {
    command,
    status,
    issue_key,
    project_key,
    dry_run: status == @types.DryRun,
    message,
    field_changes,
    operations,
    discovery_hint,
  }
}

///|
pub fn preview_create_issue(
  project : String,
  summary : String,
  issue_type : String,
  description : String,
  parent : String,
  custom_fields : Map[String, @types.CustomFieldInput],
) -> @types.MutationReport {
  let field_changes = create_issue_field_changes(
    project, summary, issue_type, description, parent, custom_fields,
  )
  mutation_report(
    "issue create",
    @types.DryRun,
    "",
    project,
    "Dry run: would create a new issue in project \{project}.",
    field_changes,
    [
      mutation_operation(
        "create_issue",
        @types.Planned,
        "Would create a new issue with \{field_changes.length()} field value(s).",
      ),
    ],
  )
}

///|
fn create_issue_success_report(
  project : String,
  issue_key : String,
  field_changes : Array[@types.MutationFieldChange],
) -> @types.MutationReport {
  mutation_report(
    "issue create",
    @types.Success,
    issue_key,
    project,
    "Issue \{issue_key} created",
    field_changes,
    [
      mutation_operation(
        "create_issue",
        @types.Applied,
        "Created issue \{issue_key} with \{field_changes.length()} field value(s).",
      ),
    ],
  )
}

///|
pub fn preview_update_issue(
  key : String,
  summary : String,
  description : String,
  priority : String,
  issue_type : String,
  labels : String,
  parent : String,
  assignee : String,
  custom_fields : Map[String, @types.CustomFieldInput],
) -> @types.MutationReport {
  let field_changes = update_issue_field_changes(
    summary, description, priority, issue_type, labels, parent, assignee, custom_fields,
  )
  let field_entries = update_issue_field_entries(
    summary, description, priority, issue_type, labels, parent, custom_fields,
  )
  let operations : Array[@types.MutationOperation] = []
  if not(field_entries.is_empty()) {
    operations.push(
      mutation_operation(
        "update_fields",
        @types.Planned,
        "Would update \{field_entries.length()} field value(s).",
      ),
    )
  }
  if assignee.length() > 0 {
    operations.push(
      mutation_operation(
        "assign_issue",
        @types.Planned,
        "Would assign issue to \{assignee}.",
      ),
    )
  }
  mutation_report(
    "issue update",
    @types.DryRun,
    key,
    "",
    "Dry run: would update issue \{key}.",
    field_changes,
    operations,
  )
}

///|
fn update_issue_success_report(
  key : String,
  field_changes : Array[@types.MutationFieldChange],
  field_entries : Array[(String, @core.Any)],
  assignee : String,
) -> @types.MutationReport {
  let operations : Array[@types.MutationOperation] = []
  if not(field_entries.is_empty()) {
    operations.push(
      mutation_operation(
        "update_fields",
        @types.Applied,
        "Updated \{field_entries.length()} field value(s).",
      ),
    )
  }
  if assignee.length() > 0 {
    operations.push(
      mutation_operation(
        "assign_issue",
        @types.Applied,
        "Assigned issue to \{assignee}.",
      ),
    )
  }
  mutation_report(
    "issue update",
    @types.Success,
    key,
    "",
    "Issue \{key} updated",
    field_changes,
    operations,
  )
}

///|
fn partial_update_next_step(
  key : String,
  hint : @types.DiscoveryHint,
) -> String {
  let confirm_step = "Re-fetch `jira-cli issue get \{key}` to confirm the applied fields."
  if hint.next_step.length() > 0 {
    confirm_step + " Then " + hint.next_step
  } else {
    confirm_step +
    " Retry only the failed assignee change after confirming the issue state."
  }
}

///|
fn partial_update_discovery_hint(
  key : String,
  hint : @types.DiscoveryHint,
) -> @types.DiscoveryHint {
  if hint.is_empty() {
    { ..hint, next_step: partial_update_next_step(key, hint) }
  } else {
    { ..hint, next_step: partial_update_next_step(key, hint) }
  }
}

///|
fn partial_update_report(
  key : String,
  field_changes : Array[@types.MutationFieldChange],
  field_entries : Array[(String, @core.Any)],
  message : String,
  discovery_hint : @types.DiscoveryHint,
) -> @types.MutationReport {
  let enriched_hint = partial_update_discovery_hint(key, discovery_hint)
  mutation_report(
    "issue update",
    @types.PartialSuccess,
    key,
    "",
    "Issue \{key} partially updated; assignee change failed after field updates.",
    field_changes,
    [
      mutation_operation(
        "update_fields",
        @types.Applied,
        "Updated \{field_entries.length()} field value(s).",
      ),
      mutation_operation("assign_issue", @types.Failed, message),
    ],
    discovery_hint=enriched_hint,
  )
}
