///|
fn parse_error_response(data : @core.Any) -> String {
  let parts : Array[String] = []
  let messages = data._get("errorMessages")
  if not(@core.is_nullish(messages)) {
    let arr = @core.array_from(messages)
    for msg in arr {
      if not(@core.is_nullish(msg)) {
        parts.push(msg.to_string())
      }
    }
  }
  let errors = data._get("errors")
  if not(@core.is_nullish(errors)) {
    let keys = @core.object_keys(errors)
    for k in keys {
      parts.push("'\{k}': \{errors._get(k).to_string()}")
    }
  }
  parts.join(", ")
}

///|
fn truncate_string(s : String, max_len : Int) -> String {
  if s.length() <= max_len {
    s
  } else {
    let buf = StringBuilder::new()
    for i in 0..<max_len {
      buf.write_char(s[i].to_int().unsafe_to_char())
    }
    buf.write_string("...")
    buf.to_string()
  }
}

///|
fn auth_header(config : @types.JiraConfig) -> String {
  let credentials = base64_encode(config.email + ":" + config.api_token)
  "Basic " + credentials
}

///|
async fn api_request(
  config : @types.JiraConfig,
  http_method : String,
  path : String,
  body? : @core.Any = @core.any(""),
) -> @core.Any {
  let url = config.base_url + path
  let headers : Map[String, String] = {
    "Authorization": auth_header(config),
    "Accept": "application/json",
  }
  if http_method != "GET" {
    headers["Content-Type"] = "application/json"
  }
  let response = if http_method == "GET" {
    @http.fetch(url, method_=http_method, headers~)
  } else {
    let actual_body = @core.any(@core.json_stringify(body))
    @http.fetch(url, method_=http_method, headers~, body=actual_body)
  }
  guard response.ok else {
    let error_detail = parse_error_response(response.clone().json()) catch {
      _ =>
        truncate_string(response.text(), 200) catch {
          _ => "(response body could not be read)"
        }
    }
    let msg = "API request failed: \{response.status} \{response.statusText}"
    raise JiraApiError(
      status_code=response.status,
      message=if error_detail == "" { msg } else { msg + " - " + error_detail },
      discovery_hint=@types.empty_discovery_hint(),
    )
  }
  if response.status == 204 {
    return @core.any(())
  }
  response.json()
}

///|
fn get_string(obj : @core.Any, key : String, default? : String = "") -> String {
  if @core.is_nullish(obj) {
    return default
  }
  let value = obj._get(key)
  if @core.is_nullish(value) {
    default
  } else {
    value.to_string()
  }
}

///|
fn any_to_display_string(value : @core.Any) -> String {
  if @core.is_nullish(value) {
    ""
  } else {
    match @core.typeof_(value) {
      "string" | "number" | "boolean" | "bigint" => value.to_string()
      "object" =>
        if @core.is_array(value) {
          @core.array_from(value)
          .map(any_to_display_string)
          .filter(fn(item) { item.length() > 0 })
          .join(", ")
        } else {
          match
            (
              get_string(value, "type"),
              get_string(value, "displayName"),
              get_string(value, "name"),
              get_string(value, "value"),
            ) {
            ("doc", _, _, _) => extract_adf_text(value)
            (_, display_name, _, _) if display_name.length() > 0 => display_name
            (_, _, name, _) if name.length() > 0 => name
            (_, _, _, field_value) if field_value.length() > 0 => field_value
            _ => @core.json_stringify(value)
          }
        }
      _ => value.to_string()
    }
  }
}

///|
fn extract_custom_fields(fields : @core.Any) -> Map[String, String] {
  @core.object_keys(fields)
  .filter(fn(name) { name.has_prefix("customfield_") })
  .fold(init={}, fn(acc, name) {
    let value = any_to_display_string(fields._get(name))
    if value.length() == 0 {
      acc
    } else {
      acc..set(name, value)
    }
  })
}

///|
fn parse_issue(data : @core.Any) -> @types.JiraIssue {
  let fields = data._get("fields")
  let description_obj = fields._get("description")
  let parent_obj = fields._get("parent")
  let description = if @core.is_nullish(description_obj) {
    ""
  } else {
    extract_adf_text(description_obj)
  }
  let parent = {
    let key = get_string(parent_obj, "key")
    if key.length() > 0 {
      key
    } else {
      get_string(parent_obj, "id")
    }
  }
  {
    key: get_string(data, "key"),
    summary: get_string(fields, "summary"),
    status: get_string(fields._get("status"), "name"),
    assignee: get_string(
      fields._get("assignee"),
      "displayName",
      default="Unassigned",
    ),
    parent,
    issue_type: get_string(fields._get("issuetype"), "name"),
    priority: get_string(fields._get("priority"), "name"),
    description,
    custom_fields: extract_custom_fields(fields),
  }
}

///|
fn parse_issues(data : @core.Any) -> Array[@types.JiraIssue] {
  let issues_arr = @core.array_from(data._get("issues"))
  issues_arr.map(parse_issue)
}

///|
fn parse_project(data : @core.Any) -> @types.JiraProject {
  {
    key: get_string(data, "key"),
    name: get_string(data, "name"),
    project_type: get_string(data, "projectTypeKey"),
  }
}

///|
fn issue_type_candidates(
  issue_types : Array[(String, String)],
) -> Array[@types.DiscoveryCandidate] {
  issue_types.map(fn(entry) {
    {
      value: entry.1,
      label: entry.1,
      description: if entry.0.length() > 0 {
        "id: " + entry.0
      } else {
        ""
      },
    }
  })
}

///|
fn transition_candidates(
  transitions : Array[@core.Any],
) -> Array[@types.DiscoveryCandidate] {
  transitions.map(fn(transition) {
    let id = get_string(transition, "id")
    let name = get_string(transition, "name")
    {
      value: name,
      label: name,
      description: if id.length() > 0 {
        "id: " + id
      } else {
        ""
      },
    }
  })
}

///|
fn user_candidate_value(user : @core.Any) -> String {
  let email = get_string(user, "emailAddress")
  if email.length() > 0 {
    email
  } else {
    get_string(user, "accountId")
  }
}

///|
fn user_candidate_label(user : @core.Any) -> String {
  let display_name = get_string(user, "displayName")
  let email = get_string(user, "emailAddress")
  match (display_name, email) {
    (display_name, email) if display_name.length() > 0 && email.length() > 0 =>
      "\{display_name} <\{email}>"
    (display_name, _) if display_name.length() > 0 => display_name
    (_, email) if email.length() > 0 => email
    _ => get_string(user, "accountId")
  }
}

///|
fn user_candidate_description(user : @core.Any) -> String {
  let account_id = get_string(user, "accountId")
  if account_id.length() > 0 {
    "accountId: " + account_id
  } else {
    ""
  }
}

///|
fn user_candidates(
  users : Array[@core.Any],
) -> Array[@types.DiscoveryCandidate] {
  users.map(fn(user) {
    {
      value: user_candidate_value(user),
      label: user_candidate_label(user),
      description: user_candidate_description(user),
    }
  })
}

///|
fn transition_discovery_hint(
  key : String,
  status_name : String,
  transitions : Array[@core.Any],
) -> @types.DiscoveryHint {
  let candidates = transition_candidates(transitions)
  {
    message: "Transition '\{status_name}' not found for issue '\{key}'.",
    candidates,
    required_args: [],
    next_step: match candidates {
      [candidate, ..] =>
        "Re-run `jira-cli issue transition --key \{key} --status \"\{candidate.value}\"`."
      [] =>
        "Inspect the issue in Jira and re-run `jira-cli issue transition --key \{key} --status <exact transition name>`."
    },
  }
}

///|
fn user_search_discovery_hint(
  query : String,
  users : Array[@core.Any],
) -> @types.DiscoveryHint {
  let candidates = user_candidates(users)
  {
    message: if users.is_empty() {
      "User not found: \{query}"
    } else {
      "Multiple users matched: \{query}"
    },
    candidates,
    required_args: [],
    next_step: "",
  }
}

///|
fn invalid_issue_type_discovery_hint(
  field_id : String,
  project : String,
  issue_type : String,
  issue_types : Array[(String, String)],
) -> @types.DiscoveryHint {
  let candidates = issue_type_candidates(issue_types)
  {
    message: "Issue type '\{issue_type}' is not available in project '\{project}' for field '\{field_id}'.",
    candidates,
    required_args: [],
    next_step: match candidates {
      [candidate, ..] =>
        "Re-run `jira-cli field get \{field_id} --project \{project} --type \"\{candidate.value}\"`."
      [] =>
        "Verify the project key '\{project}' and re-run `jira-cli field get \{field_id} --project \{project}`."
    },
  }
}

///|
fn unavailable_field_discovery_hint(
  field_id : String,
  project : String,
  issue_type : String,
  issue_types : Array[(String, String)],
) -> @types.DiscoveryHint {
  let alternative_candidates = issue_type_candidates(
    issue_types.filter(fn(entry) { entry.1 != issue_type }),
  )
  {
    message: "Field '\{field_id}' is not available for project '\{project}' issue type '\{issue_type}'.",
    candidates: alternative_candidates,
    required_args: [],
    next_step: match alternative_candidates {
      [candidate, ..] =>
        "Re-run `jira-cli field get \{field_id} --project \{project}` to inspect issue types, then retry with one of the candidates such as \"\{candidate.value}\"."
      [] =>
        "Verify that field '\{field_id}' is on the Jira create screen for project '\{project}' issue type '\{issue_type}'."
    },
  }
}

///|
fn requested_api_fields(fields : Array[@types.IssueField]) -> Array[String] {
  fields
  .map(fn(field) { field.api_name() })
  .filter(fn(name) { name != "key" })
  .fold(init=[], fn(acc, name) {
    if acc.contains(name) {
      acc
    } else {
      [..acc, name]
    }
  })
}

///|
fn build_search_body(
  jql : String,
  fields : Array[@types.IssueField],
  max_results : Int,
  next_page_token? : String = "",
) -> @core.Any {
  let requested_fields = requested_api_fields(fields)
  @core.from_entries(
    [
      ("jql", @core.any(jql)),
      ("maxResults", @core.any(max_results)),
      ..if next_page_token.length() > 0 {
        [("nextPageToken", @core.any(next_page_token))]
      } else {
        []
      },
      ..if requested_fields.is_empty() {
        []
      } else {
        [("fields", @core.any(requested_fields))]
      },
    ],
  )
}

///|
async fn search_issue_count(config : @types.JiraConfig, jql : String) -> Int {
  let body = @core.from_entries([("jql", @core.any(jql))])
  let data = api_request(
    config,
    "POST",
    "/rest/api/3/search/approximate-count",
    body~,
  ) catch {
    _ => return -1
  }
  let count = data._get("count")
  if @core.is_nullish(count) {
    -1
  } else {
    count.cast()
  }
}

///|
fn issue_search_page_size(page_request : @types.PageRequest) -> Int {
  let page_size = 50
  if page_request.fetch_all ||
    page_request.start_at > 0 ||
    page_request.limit > page_size {
    page_size
  } else {
    page_request.limit
  }
}

///|
fn[T] slice_items(
  items : Array[T],
  page_request : @types.PageRequest,
) -> Array[T] {
  let visible : Array[T] = []
  let mut index = page_request.start_at
  while index < items.length() {
    if not(page_request.fetch_all) && visible.length() >= page_request.limit {
      break
    }
    visible.push(items[index])
    index = index + 1
  }
  visible
}

///|
fn build_issue_path(key : String, fields : Array[@types.IssueField]) -> String {
  let requested_fields = requested_api_fields(fields)
  if requested_fields.is_empty() {
    "/rest/api/3/issue/\{key}"
  } else {
    let encoded_fields = encode_uri_component(requested_fields.join(","))
    "/rest/api/3/issue/\{key}?fields=\{encoded_fields}"
  }
}

///|
pub async fn list_issues(
  config : @types.JiraConfig,
  jql : String,
  fields : Array[@types.IssueField],
  page_request : @types.PageRequest,
) -> @types.JiraIssuePage {
  let total = search_issue_count(config, jql)
  let request_size = issue_search_page_size(page_request)
  let items : Array[@types.JiraIssue] = []
  let mut skipped = 0
  let mut next_page_token = ""
  let mut is_last = false
  while true {
    let body = build_search_body(jql, fields, request_size, next_page_token~)
    let data = api_request(config, "POST", "/rest/api/3/search/jql", body~)
    let page_items = parse_issues(data)
    let skip_in_page = {
      let pending_skip = page_request.start_at - skipped
      if pending_skip > 0 {
        if pending_skip > page_items.length() {
          page_items.length()
        } else {
          pending_skip
        }
      } else {
        0
      }
    }
    let mut index = skip_in_page
    while index < page_items.length() {
      if not(page_request.fetch_all) && items.length() >= page_request.limit {
        break
      }
      items.push(page_items[index])
      index = index + 1
    }
    skipped = skipped + page_items.length()
    is_last = get_string(data, "isLast") == "true"
    next_page_token = get_string(data, "nextPageToken")
    if page_items.is_empty() ||
      is_last ||
      next_page_token.length() == 0 ||
      (not(page_request.fetch_all) && items.length() >= page_request.limit) {
      break
    }
  }
  let resolved_total = if total >= 0 {
    total
  } else if is_last {
    skipped
  } else {
    -1
  }
  {
    items,
    page: @types.page_info(
      page_request.start_at,
      if page_request.fetch_all {
        items.length()
      } else {
        page_request.limit
      },
      items.length(),
      resolved_total,
      page_request.fetch_all,
      is_last,
    ),
  }
}

///|
pub async fn get_issue(
  config : @types.JiraConfig,
  key : String,
  fields : Array[@types.IssueField],
) -> @types.JiraIssue {
  let data = api_request(config, "GET", build_issue_path(key, fields))
  parse_issue(data)
}

///|
pub async fn create_issue(
  config : @types.JiraConfig,
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
  let body = @core.from_entries([
    (
      "fields",
      @core.from_entries(
        create_issue_field_entries(
          project, summary, issue_type, description, parent, custom_fields,
        ),
      ),
    ),
  ])
  let result = api_request(config, "POST", "/rest/api/3/issue", body~)
  create_issue_success_report(project, get_string(result, "key"), field_changes)
}

///|
pub async fn update_issue(
  config : @types.JiraConfig,
  key~ : String,
  summary~ : String,
  description~ : String,
  priority~ : String,
  issue_type~ : String,
  labels~ : String,
  parent~ : String,
  assignee~ : String,
  custom_fields~ : Map[String, @types.CustomFieldInput],
) -> @types.MutationReport {
  let field_changes = update_issue_field_changes(
    summary, description, priority, issue_type, labels, parent, assignee, custom_fields,
  )
  let field_entries = update_issue_field_entries(
    summary, description, priority, issue_type, labels, parent, custom_fields,
  )
  if not(field_entries.is_empty()) {
    let body = @core.from_entries([
      ("fields", @core.from_entries(field_entries)),
    ])
    let _ = api_request(config, "PUT", "/rest/api/3/issue/\{key}", body~)
  }
  if assignee.length() > 0 {
    assign_issue(config, key, assignee) catch {
      JiraApiError(status_code~, message~, discovery_hint~) =>
        if field_entries.is_empty() {
          raise JiraApiError(status_code~, message~, discovery_hint~)
        } else {
          raise JiraMutationPartialSuccess(
            status_code~,
            report=partial_update_report(
              key, field_changes, field_entries, message, discovery_hint,
            ),
          )
        }
      e => raise e
    }
  }
  update_issue_success_report(key, field_changes, field_entries, assignee)
}

///|
async fn get_transitions(config : @types.JiraConfig, key : String) -> @core.Any {
  api_request(config, "GET", "/rest/api/3/issue/\{key}/transitions")
}

///|
async fn do_transition(
  config : @types.JiraConfig,
  key : String,
  transition_id : String,
) -> Unit {
  let body = @core.from_entries([
    ("transition", @core.from_entries([("id", @core.any(transition_id))])),
  ])
  let _ = api_request(
    config,
    "POST",
    "/rest/api/3/issue/\{key}/transitions",
    body~,
  )
}

///|
pub async fn transition_issue(
  config : @types.JiraConfig,
  key : String,
  status_name : String,
) -> Unit {
  let data = get_transitions(config, key)
  let transitions = @core.array_from(data._get("transitions"))
  let lower_status = status_name.to_lower()
  let found = transitions
    .iter()
    .find_first(fn(t) { get_string(t, "name").to_lower() == lower_status })
  match found {
    Some(t) => do_transition(config, key, get_string(t, "id"))
    None => {
      let discovery_hint = transition_discovery_hint(
        key, status_name, transitions,
      )
      raise JiraApiError(
        status_code=409,
        message=discovery_hint.message,
        discovery_hint~,
      )
    }
  }
}

///|
pub async fn add_comment(
  config : @types.JiraConfig,
  key : String,
  text : String,
) -> Unit {
  let body = @core.from_entries([("body", build_adf_text(text))])
  let _ = api_request(config, "POST", "/rest/api/3/issue/\{key}/comment", body~)
}

///|
async fn search_users(config : @types.JiraConfig, email : String) -> @core.Any {
  let encoded = encode_uri_component(email)
  api_request(config, "GET", "/rest/api/3/user/search?query=\{encoded}")
}

///|
fn select_user_account_id(
  users : Array[@core.Any],
  query : String,
) -> Result[String, @types.DiscoveryHint] {
  let lower_query = query.to_lower()
  let exact_matches : Array[String] = []
  for user in users {
    let account_id = get_string(user, "accountId")
    let email = get_string(user, "emailAddress").to_lower()
    if account_id.to_lower() == lower_query || email == lower_query {
      exact_matches.push(account_id)
    }
  }
  match exact_matches {
    [account_id] => Ok(account_id)
    [_, _, ..] => Err(user_search_discovery_hint(query, users))
    [] =>
      match users {
        [] => Err(user_search_discovery_hint(query, users))
        [user] => Ok(get_string(user, "accountId"))
        [_, _, ..] => Err(user_search_discovery_hint(query, users))
      }
  }
}

///|
pub async fn assign_issue(
  config : @types.JiraConfig,
  key : String,
  email : String,
) -> Unit {
  let users = @core.array_from(search_users(config, email))
  let account_id = match select_user_account_id(users, email) {
    Ok(account_id) => account_id
    Err(discovery_hint) => {
      let first_retryable = discovery_hint.candidates
        .iter()
        .find_first(fn(candidate) {
          candidate.value.length() > 0 && candidate.value.contains("@")
        })
      let enriched_hint = {
        ..discovery_hint,
        next_step: match first_retryable {
          Some(candidate) =>
            "Re-run `jira-cli issue assign --key \{key} --email \{candidate.value}`."
          None =>
            "Re-run `jira-cli issue assign --key \{key} --email <exact email>` with a Jira-visible email address."
        },
      }
      raise JiraApiError(
        status_code=if users.is_empty() { 404 } else { 409 },
        message=enriched_hint.message,
        discovery_hint=enriched_hint,
      )
    }
  }
  let body = @core.from_entries([("accountId", @core.any(account_id))])
  let _ = api_request(config, "PUT", "/rest/api/3/issue/\{key}/assignee", body~)
}

///|
pub async fn list_projects(
  config : @types.JiraConfig,
  page_request : @types.PageRequest,
) -> @types.JiraProjectPage {
  let data = api_request(config, "GET", "/rest/api/3/project")
  let projects = @core.array_from(data)
  let items = projects.map(parse_project)
  let visible = slice_items(items, page_request)
  {
    items: visible,
    page: @types.page_info_from_request(
      page_request,
      items.length(),
      visible.length(),
    ),
  }
}

///|
fn parse_field(f : @core.Any) -> @types.JiraField {
  let schema = f._get("schema")
  {
    id: get_string(f, "id"),
    name: get_string(f, "name"),
    custom: f._get("custom").to_string() == "true",
    schema_type: if @core.is_nullish(schema) {
      ""
    } else {
      get_string(schema, "type")
    },
    schema_custom: if @core.is_nullish(schema) {
      ""
    } else {
      get_string(schema, "custom")
    },
  }
}

///|
pub async fn list_fields(
  config : @types.JiraConfig,
  page_request : @types.PageRequest,
) -> @types.JiraFieldPage {
  let data = api_request(config, "GET", "/rest/api/3/field")
  let fields = @core.array_from(data)
  let items = fields
    .filter(fn(f) { f._get("custom").to_string() == "true" })
    .map(parse_field)
  let visible = slice_items(items, page_request)
  {
    items: visible,
    page: @types.page_info_from_request(
      page_request,
      items.length(),
      visible.length(),
    ),
  }
}

///|
pub async fn list_issue_types(
  config : @types.JiraConfig,
  project : String,
) -> Array[(String, String)] {
  let data = api_request(
    config,
    "GET",
    "/rest/api/3/issue/createmeta/\{project}/issuetypes",
  )
  let raw = data._get("issueTypes")
  guard not(@core.is_nullish(raw)) else {
    raise JiraApiError(
      status_code=500,
      message="Unexpected API response: 'issueTypes' not found for project '\{project}'",
      discovery_hint=@types.empty_discovery_hint(),
    )
  }
  let issue_types = @core.array_from(raw)
  issue_types.map(fn(it) { (get_string(it, "id"), get_string(it, "name")) })
}

///|
pub async fn get_field_detail(
  config : @types.JiraConfig,
  field_id : String,
  project : String,
  issue_type : String,
) -> @types.JiraFieldDetail {
  let data = api_request(config, "GET", "/rest/api/3/field")
  let fields = @core.array_from(data)
  let field_data = fields
    .iter()
    .find_first(fn(f) { get_string(f, "id") == field_id })
  let f = match field_data {
    Some(f) => f
    None =>
      raise JiraApiError(
        status_code=404,
        message="Field not found: " + field_id,
        discovery_hint=@types.empty_discovery_hint(),
      )
  }
  let field = parse_field(f)
  let options : Array[@types.JiraFieldOption] = []
  if project.length() > 0 && issue_type.length() > 0 {
    let types_data = api_request(
      config,
      "GET",
      "/rest/api/3/issue/createmeta/\{project}/issuetypes",
    )
    let issue_types_raw = types_data._get("issueTypes")
    guard not(@core.is_nullish(issue_types_raw)) else {
      raise JiraApiError(
        status_code=500,
        message="Unexpected API response: 'issueTypes' not found for project '\{project}'",
        discovery_hint=@types.empty_discovery_hint(),
      )
    }
    let issue_types = @core.array_from(issue_types_raw)
    let available_issue_types = issue_types.map(fn(it) {
      (get_string(it, "id"), get_string(it, "name"))
    })
    let type_entry = issue_types
      .iter()
      .find_first(fn(it) { get_string(it, "name") == issue_type })
    let type_id = match type_entry {
      Some(it) => get_string(it, "id")
      None => {
        let discovery_hint = invalid_issue_type_discovery_hint(
          field_id, project, issue_type, available_issue_types,
        )
        raise JiraApiError(
          status_code=400,
          message=discovery_hint.message,
          discovery_hint~,
        )
      }
    }
    let createmeta_fields : Array[@core.Any] = []
    let mut start_at = 0
    let page_size = 50
    while true {
      let fields_data = api_request(
        config,
        "GET",
        "/rest/api/3/issue/createmeta/\{project}/issuetypes/\{type_id}?startAt=\{start_at}&maxResults=\{page_size}",
      )
      let createmeta_fields_raw = fields_data._get("fields")
      guard not(@core.is_nullish(createmeta_fields_raw)) else {
        raise JiraApiError(
          status_code=500,
          message="Unexpected API response: 'fields' not found for project '\{project}' issue type '\{issue_type}'",
          discovery_hint=@types.empty_discovery_hint(),
        )
      }
      let page_fields = @core.array_from(createmeta_fields_raw)
      for f in page_fields {
        createmeta_fields.push(f)
      }
      let total_raw = fields_data._get("total")
      let total = if @core.is_nullish(total_raw) { 0 } else { total_raw.cast() }
      start_at = start_at + page_fields.length()
      if page_fields.length() < page_size || start_at >= total {
        break
      }
    }
    let target_field = createmeta_fields
      .iter()
      .find_first(fn(cf) { get_string(cf, "fieldId") == field_id })
    match target_field {
      Some(cf) => {
        let allowed = cf._get("allowedValues")
        if not(@core.is_nullish(allowed)) {
          let allowed_arr = @core.array_from(allowed)
          for opt in allowed_arr {
            let display = any_to_display_string(opt)
            options.push({ id: get_string(opt, "id"), value: display })
          }
        }
      }
      None => {
        let discovery_hint = unavailable_field_discovery_hint(
          field_id, project, issue_type, available_issue_types,
        )
        raise JiraApiError(
          status_code=400,
          message=discovery_hint.message,
          discovery_hint~,
        )
      }
    }
  }
  { field, options }
}

///|
extern "js" fn json_string_to_any(text : String) -> @core.Any =
  #|(text) => JSON.parse(text)

///|
fn custom_field_value(value : @types.CustomFieldInput) -> @core.Any {
  json_string_to_any(value.json_value().stringify())
}

///|
fn encode_uri_component(s : String) -> String {
  @core.global_this()._call("encodeURIComponent", [@core.any(s)]).to_string()
}
