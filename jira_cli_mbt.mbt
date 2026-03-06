///|
pub async fn execute(cmd : Result[Command, String]) -> String {
  match cmd {
    Err(msg) => format_usage() + "\n\nError: " + msg
    Ok(Help) => format_usage()
    Ok(Config(base_url~, email~, api_token~)) => {
      save_config({ base_url, email, api_token })
      "Configuration saved to ~/.config/jira_cli_mbt/config.json"
    }
    Ok(ListIssues(jql~)) => {
      let config = load_config()
      format_issue_list(list_issues(config, jql))
    }
    Ok(GetIssue(key~)) => {
      let config = load_config()
      format_issue_detail(get_issue(config, key))
    }
    Ok(CreateIssue(project~, summary~, issue_type~, description~)) => {
      let config = load_config()
      let key = create_issue(config, project, summary, issue_type, description)
      "Issue created: \{key}"
    }
    Ok(Transition(key~, status~)) => {
      let config = load_config()
      transition_issue(config, key, status)
      "Issue \{key} transitioned to '\{status}'"
    }
    Ok(Comment(key~, text~)) => {
      let config = load_config()
      add_comment(config, key, text)
      "Comment added to \{key}"
    }
    Ok(Assign(key~, email~)) => {
      let config = load_config()
      assign_issue(config, key, email)
      "Issue \{key} assigned to \{email}"
    }
    Ok(Search(jql~)) => {
      let config = load_config()
      format_issue_list(list_issues(config, jql))
    }
    Ok(ListProjects) => {
      let config = load_config()
      format_projects(list_projects(config))
    }
  }
}
