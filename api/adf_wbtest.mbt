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
