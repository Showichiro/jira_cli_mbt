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
    raise JiraApiError(
      "API request failed: \{response.status} \{response.statusText}",
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
  let description = if @core.is_nullish(description_obj) {
    ""
  } else {
    extract_adf_text(description_obj)
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
) -> @core.Any {
  let requested_fields = requested_api_fields(fields)
  @core.from_entries(
    [
      ("jql", @core.any(jql)),
      ("maxResults", @core.any(20)),
      ..if requested_fields.is_empty() {
        []
      } else {
        [("fields", @core.any(requested_fields))]
      },
    ],
  )
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
) -> Array[@types.JiraIssue] {
  let body = build_search_body(jql, fields)
  let data = api_request(config, "POST", "/rest/api/3/search/jql", body~)
  parse_issues(data)
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
) -> String {
  let body = @core.from_entries([
    (
      "fields",
      @core.from_entries(
        [
          ("project", @core.from_entries([("key", @core.any(project))])),
          ("summary", @core.any(summary)),
          ("issuetype", @core.from_entries([("name", @core.any(issue_type))])),
          ..if description.length() > 0 {
            [("description", build_adf_text(description))]
          } else {
            []
          },
        ],
      ),
    ),
  ])
  let result = api_request(config, "POST", "/rest/api/3/issue", body~)
  get_string(result, "key")
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
    None => raise JiraApiError("Transition '\{status_name}' not found")
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
) -> Result[String, String] {
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
    [_, _, ..] => Err("Multiple users matched: \{query}")
    [] =>
      match users {
        [] => Err("User not found: \{query}")
        [user] => Ok(get_string(user, "accountId"))
        [_, _, ..] => Err("Multiple users matched: \{query}")
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
    Err(message) => raise JiraApiError(message)
  }
  let body = @core.from_entries([("accountId", @core.any(account_id))])
  let _ = api_request(config, "PUT", "/rest/api/3/issue/\{key}/assignee", body~)
}

///|
pub async fn list_projects(
  config : @types.JiraConfig,
) -> Array[@types.JiraProject] {
  let data = api_request(config, "GET", "/rest/api/3/project")
  let projects = @core.array_from(data)
  projects.map(parse_project)
}

///|
fn encode_uri_component(s : String) -> String {
  @core.global_this()._call("encodeURIComponent", [@core.any(s)]).to_string()
}
