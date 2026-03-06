///|
test "pad_right: shorter than width" {
  inspect(pad_right("ab", 5), content="ab   ")
}

///|
test "pad_right: equal to width" {
  inspect(pad_right("abcde", 5), content="abcde")
}

///|
test "pad_right: longer than width" {
  inspect(pad_right("abcdef", 5), content="abcdef")
}

///|
test "truncate: shorter than max" {
  inspect(truncate("hello", 10), content="hello")
}

///|
test "truncate: exactly max" {
  inspect(truncate("hello", 5), content="hello")
}

///|
test "truncate: longer than max" {
  inspect(truncate("hello world", 8), content="hello...")
}

///|
test "format_issue_list: empty" {
  inspect(format_issue_list([]), content="No issues found.")
}

///|
test "format_issue_list: single issue" {
  let issues : Array[@types.JiraIssue] = [
    {
      key: "PROJ-1",
      summary: "Fix bug",
      status: "Open",
      assignee: "Alice",
      issue_type: "Bug",
      priority: "High",
      description: "",
    },
  ]
  inspect(
    format_issue_list(issues),
    content=(
      #|KEY           TYPE          STATUS           PRIORITY    SUMMARY                                 
      #|------------  ------------  ---------------  ----------  ----------------------------------------
      #|PROJ-1        Bug           Open             High        Fix bug                                 
    ),
  )
}

///|
test "format_issue_detail" {
  let issue : @types.JiraIssue = {
    key: "PROJ-1",
    summary: "Fix bug",
    status: "Open",
    assignee: "Alice",
    issue_type: "Bug",
    priority: "High",
    description: "Some description",
  }
  inspect(
    format_issue_detail(issue),
    content=(
      #|Key:         PROJ-1
      #|Type:        Bug
      #|Status:      Open
      #|Priority:    High
      #|Assignee:    Alice
      #|Summary:     Fix bug
      #|Description: Some description
    ),
  )
}

///|
test "format_projects: empty" {
  inspect(format_projects([]), content="No projects found.")
}

///|
test "format_projects: single project" {
  let projects : Array[@types.JiraProject] = [
    { key: "PROJ", name: "My Project", project_type: "software" },
  ]
  inspect(
    format_projects(projects),
    content=(
      #|KEY           NAME                            TYPE           
      #|------------  ------------------------------  ---------------
      #|PROJ          My Project                      software       
    ),
  )
}
