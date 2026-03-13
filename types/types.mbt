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
pub(all) enum OutputFormat {
  Table
  Tsv
  Json
} derive(Show, Eq)

///|
pub fn parse_output_format(name : String) -> Result[OutputFormat, String] {
  let normalized = name.trim().to_string().to_lower()
  match normalized {
    "table" => Ok(Table)
    "tsv" => Ok(Tsv)
    "json" => Ok(Json)
    "" => Err("Output format must not be empty")
    _ => Err("Unsupported output format: \{normalized}")
  }
}

///|
pub fn OutputFormat::name(self : OutputFormat) -> String {
  match self {
    Table => "table"
    Tsv => "tsv"
    Json => "json"
  }
}

///|
pub(all) enum CliErrorCategory {
  Usage
  Config
  Auth
  NotFound
  Validation
  General
} derive(Show, Eq)

///|
pub fn CliErrorCategory::name(self : CliErrorCategory) -> String {
  match self {
    Usage => "usage"
    Config => "config"
    Auth => "auth"
    NotFound => "not_found"
    Validation => "validation"
    General => "general"
  }
}

///|
pub fn CliErrorCategory::exit_code(self : CliErrorCategory) -> Int {
  match self {
    Usage => 2
    Config | Auth => 4
    NotFound => 3
    Validation => 5
    General => 1
  }
}

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
pub(all) struct JiraIssuePage {
  items : Array[JiraIssue]
  page : PageInfo
} derive(Show)

///|
pub(all) struct JiraProjectPage {
  items : Array[JiraProject]
  page : PageInfo
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
  ListIssues(
    jql~ : String,
    fields~ : Array[IssueField],
    page_request~ : PageRequest
  )
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
  Search(jql~ : String, page_request~ : PageRequest)
  ListProjects(page_request~ : PageRequest)
  ListFields(page_request~ : PageRequest)
  GetField(field_id~ : String, project~ : String, issue_type~ : String)
  Help(command_name~ : String)
  Describe(command_name~ : String)
} derive(Show)

///|
pub(all) struct Invocation {
  command : Command
  output_format : OutputFormat
} derive(Show)

///|
pub(all) struct CommandRunResult {
  stdout : String
  stderr : String
  exit_code : Int
} derive(Show, Eq)

///|
pub(all) struct JiraField {
  id : String
  name : String
  custom : Bool
  schema_type : String
  schema_custom : String
} derive(Show)

///|
pub(all) struct JiraFieldPage {
  items : Array[JiraField]
  page : PageInfo
} derive(Show)

///|
pub(all) struct JiraFieldOption {
  id : String
  value : String
} derive(Show)

///|
pub(all) struct JiraFieldDetail {
  field : JiraField
  options : Array[JiraFieldOption]
} derive(Show)
