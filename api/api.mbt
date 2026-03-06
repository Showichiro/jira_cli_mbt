///|
fn auth_header(config : @types.JiraConfig) -> String {
  let credentials = base64_encode(config.email + ":" + config.api_token)
  "Basic " + credentials
}

///|
async fn api_get(config : @types.JiraConfig, path : String) -> @core.Any {
  let url = config.base_url + path
  let headers : Map[String, String] = {
    "Authorization": auth_header(config),
    "Accept": "application/json",
  }
  let response = @http.fetch(url, method_="GET", headers~)
  guard response.ok else {
    raise JiraApiError(
      "API request failed: \{response.status} \{response.statusText}",
    )
  }
  response.json()
}

///|
async fn api_post(
  config : @types.JiraConfig,
  path : String,
  body : @core.Any,
) -> @core.Any {
  let url = config.base_url + path
  let headers : Map[String, String] = {
    "Authorization": auth_header(config),
    "Accept": "application/json",
    "Content-Type": "application/json",
  }
  let response = @http.fetch(url, method_="POST", headers~, body~)
  guard response.ok else {
    raise JiraApiError(
      "API request failed: \{response.status} \{response.statusText}",
    )
  }
  response.json()
}

///|
async fn api_put(
  config : @types.JiraConfig,
  path : String,
  body : @core.Any,
) -> @core.Any {
  let url = config.base_url + path
  let headers : Map[String, String] = {
    "Authorization": auth_header(config),
    "Accept": "application/json",
    "Content-Type": "application/json",
  }
  let response = @http.fetch(url, method_="PUT", headers~, body~)
  guard response.ok else {
    raise JiraApiError(
      "API request failed: \{response.status} \{response.statusText}",
    )
  }
  response.json()
}

///|
fn get_string(obj : @core.Any, key : String) -> String {
  let value = obj._get(key)
  if @core.is_nullish(value) {
    ""
  } else {
    value.to_string()
  }
}

///|
fn parse_issue(data : @core.Any) -> @types.JiraIssue {
  let fields = data._get("fields")
  let status = fields._get("status")._get("name")
  let assignee = fields._get("assignee")
  let issue_type = fields._get("issuetype")._get("name")
  let priority = fields._get("priority")._get("name")
  let description_obj = fields._get("description")
  let description = if @core.is_nullish(description_obj) {
    ""
  } else {
    @core.json_stringify(description_obj)
  }
  {
    key: get_string(data, "key"),
    summary: get_string(fields, "summary"),
    status: if @core.is_nullish(status) {
      ""
    } else {
      status.to_string()
    },
    assignee: if @core.is_nullish(assignee) {
      "Unassigned"
    } else {
      get_string(assignee, "displayName")
    },
    issue_type: if @core.is_nullish(issue_type) {
      ""
    } else {
      issue_type.to_string()
    },
    priority: if @core.is_nullish(priority) {
      ""
    } else {
      priority.to_string()
    },
    description,
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
pub async fn list_issues(
  config : @types.JiraConfig,
  jql : String,
) -> Array[@types.JiraIssue] {
  let fields : @core.Any = @core.any(
    ["summary", "status", "assignee", "issuetype", "priority", "description"],
  )
  let body = @core.from_entries([
    ("jql", @core.any(jql)),
    ("maxResults", @core.any(20)),
    ("fields", fields),
  ])
  let data = api_post(
    config,
    "/rest/api/3/search/jql",
    @core.any(@core.json_stringify(body)),
  )
  parse_issues(data)
}

///|
pub async fn get_issue(
  config : @types.JiraConfig,
  key : String,
) -> @types.JiraIssue {
  let data = api_get(config, "/rest/api/3/issue/\{key}")
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
  let result = api_post(
    config,
    "/rest/api/3/issue",
    @core.any(@core.json_stringify(body)),
  )
  get_string(result, "key")
}

///|
async fn get_transitions(config : @types.JiraConfig, key : String) -> @core.Any {
  api_get(config, "/rest/api/3/issue/\{key}/transitions")
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
  let _ = api_post(
    config,
    "/rest/api/3/issue/\{key}/transitions",
    @core.any(@core.json_stringify(body)),
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
  let _ = api_post(
    config,
    "/rest/api/3/issue/\{key}/comment",
    @core.any(@core.json_stringify(body)),
  )
}

///|
async fn search_users(config : @types.JiraConfig, email : String) -> @core.Any {
  let encoded = encode_uri_component(email)
  api_get(config, "/rest/api/3/user/search?query=\{encoded}")
}

///|
pub async fn assign_issue(
  config : @types.JiraConfig,
  key : String,
  email : String,
) -> Unit {
  let users = @core.array_from(search_users(config, email))
  guard users.length() > 0 else {
    raise JiraApiError("User not found: \{email}")
  }
  let account_id = get_string(users[0], "accountId")
  let body = @core.from_entries([("accountId", @core.any(account_id))])
  let _ = api_put(
    config,
    "/rest/api/3/issue/\{key}/assignee",
    @core.any(@core.json_stringify(body)),
  )
}

///|
pub async fn list_projects(
  config : @types.JiraConfig,
) -> Array[@types.JiraProject] {
  let data = api_get(config, "/rest/api/3/project")
  let projects = @core.array_from(data)
  projects.map(parse_project)
}

///|
fn encode_uri_component(s : String) -> String {
  @core.global_this()._call("encodeURIComponent", [@core.any(s)]).to_string()
}
