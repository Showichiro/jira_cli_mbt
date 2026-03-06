///|
fn base64_encode(input : String) -> String {
  @buffer.Buffer::from_string(input).toString(encoding="base64")
}
