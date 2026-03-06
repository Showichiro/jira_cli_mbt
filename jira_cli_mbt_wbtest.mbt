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
test "build_adf_text" {
  let adf = build_adf_text("hello")
  let json_str = @core.json_stringify_pretty(adf, 2)
  inspect(
    json_str,
    content=(
      #|{
      #|  "type": "doc",
      #|  "version": 1,
      #|  "content": [
      #|    {
      #|      "type": "paragraph",
      #|      "content": [
      #|        {
      #|          "type": "text",
      #|          "text": "hello"
      #|        }
      #|      ]
      #|    }
      #|  ]
      #|}
    ),
  )
}

///|
test "parse_flags: basic" {
  let flags = parse_flags(["--key", "PROJ-1", "--status", "Done"][:], {})
  inspect(flags.get("key"), content="Some(\"PROJ-1\")")
  inspect(flags.get("status"), content="Some(\"Done\")")
}

///|
test "parse_flags: empty" {
  let flags = parse_flags([][:], {})
  inspect(flags.length(), content="0")
}

///|
test "format_issue_list: empty" {
  inspect(format_issue_list([]), content="No issues found.")
}

///|
test "format_issue_list: single issue" {
  let issues : Array[JiraIssue] = [
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
  let issue : JiraIssue = {
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
  let projects : Array[JiraProject] = [
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
