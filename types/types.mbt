///|
pub(all) struct JiraConfig {
  base_url : String
  email : String
  api_token : String
} derive(Show, ToJson, FromJson)

///|
pub(all) enum IssueField {
  Key
  Summary
  Status
  Assignee
  IssueType
  Priority
  Description
  Custom(String)
} derive(Show, Eq)

///|
pub fn parse_issue_field(name : String) -> Result[IssueField, String] {
  let normalized = name.trim().to_string().to_lower()
  match normalized {
    "key" => Ok(Key)
    "summary" => Ok(Summary)
    "status" => Ok(Status)
    "assignee" => Ok(Assignee)
    "type" | "issue_type" | "issuetype" => Ok(IssueType)
    "priority" => Ok(Priority)
    "description" => Ok(Description)
    "" => Err("Field name must not be empty")
    _ if normalized.has_prefix("customfield_") => Ok(Custom(normalized))
    other => Err("Unsupported issue field: \{other}")
  }
}

///|
pub fn IssueField::api_name(self : IssueField) -> String {
  match self {
    Key => "key"
    Summary => "summary"
    Status => "status"
    Assignee => "assignee"
    IssueType => "issuetype"
    Priority => "priority"
    Description => "description"
    Custom(name) => name
  }
}

///|
pub fn IssueField::list_header(self : IssueField) -> String {
  match self {
    Key => "KEY"
    Summary => "SUMMARY"
    Status => "STATUS"
    Assignee => "ASSIGNEE"
    IssueType => "TYPE"
    Priority => "PRIORITY"
    Description => "DESCRIPTION"
    Custom(name) => name
  }
}

///|
pub fn IssueField::detail_label(self : IssueField) -> String {
  match self {
    Key => "Key"
    Summary => "Summary"
    Status => "Status"
    Assignee => "Assignee"
    IssueType => "Type"
    Priority => "Priority"
    Description => "Description"
    Custom(name) => name
  }
}

///|
pub fn IssueField::table_width(self : IssueField) -> Int {
  match self {
    Key => 12
    Summary => 40
    Status => 15
    Assignee => 20
    IssueType => 12
    Priority => 10
    Description => 40
    Custom(name) => if name.length() > 20 { name.length() } else { 20 }
  }
}

///|
pub(all) struct JiraIssue {
  key : String
  summary : String
  status : String
  assignee : String
  issue_type : String
  priority : String
  description : String
  custom_fields : Map[String, String]
} derive(Show)

///|
pub fn JiraIssue::field_value(self : JiraIssue, field : IssueField) -> String {
  match field {
    Key => self.key
    Summary => self.summary
    Status => self.status
    Assignee => self.assignee
    IssueType => self.issue_type
    Priority => self.priority
    Description => self.description
    Custom(name) => self.custom_fields.get(name).unwrap_or("")
  }
}

///|
pub(all) struct JiraProject {
  key : String
  name : String
  project_type : String
} derive(Show)

///|
pub fn default_list_issue_fields() -> Array[IssueField] {
  [Key, IssueType, Status, Priority, Summary]
}

///|
pub fn default_detail_issue_fields() -> Array[IssueField] {
  [Key, IssueType, Status, Priority, Assignee, Summary, Description]
}

///|
pub(all) enum Command {
  Config(base_url~ : String, email~ : String, api_token~ : String)
  ListIssues(jql~ : String, fields~ : Array[IssueField])
  GetIssue(key~ : String, fields~ : Array[IssueField])
  CreateIssue(
    project~ : String,
    summary~ : String,
    issue_type~ : String,
    description~ : String,
    custom_fields~ : Map[String, String]
  )
  UpdateIssue(
    key~ : String,
    summary~ : String,
    description~ : String,
    priority~ : String,
    issue_type~ : String,
    labels~ : String,
    assignee~ : String,
    custom_fields~ : Map[String, String]
  )
  Transition(key~ : String, status~ : String)
  Comment(key~ : String, text~ : String)
  Assign(key~ : String, email~ : String)
  Search(jql~ : String)
  ListProjects
  Help
} derive(Show)
