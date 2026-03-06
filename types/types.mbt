///|
pub(all) struct JiraConfig {
  base_url : String
  email : String
  api_token : String
} derive(Show, ToJson, FromJson)

///|
pub(all) struct JiraIssue {
  key : String
  summary : String
  status : String
  assignee : String
  issue_type : String
  priority : String
  description : String
} derive(Show)

///|
pub(all) struct JiraProject {
  key : String
  name : String
  project_type : String
} derive(Show)

///|
pub(all) enum Command {
  Config(base_url~ : String, email~ : String, api_token~ : String)
  ListIssues(jql~ : String)
  GetIssue(key~ : String)
  CreateIssue(
    project~ : String,
    summary~ : String,
    issue_type~ : String,
    description~ : String
  )
  Transition(key~ : String, status~ : String)
  Comment(key~ : String, text~ : String)
  Assign(key~ : String, email~ : String)
  Search(jql~ : String)
  ListProjects
  Help
} derive(Show)
