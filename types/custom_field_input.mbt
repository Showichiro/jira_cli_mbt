///|
pub(all) struct CustomFieldInput {
  value : Json
} derive(Show, Eq)

///|
fn is_numeric_string(value : String) -> Bool {
  if value.length() == 0 {
    return false
  }
  for i in 0..<value.length() {
    let c = value[i].to_int().unsafe_to_char()
    if c < '0' || c > '9' {
      return false
    }
  }
  true
}

///|
pub fn custom_field_input_json(value : Json) -> CustomFieldInput {
  { value, }
}

///|
pub fn custom_field_input_string(value : String) -> CustomFieldInput {
  { value: Json::string(value) }
}

///|
pub fn custom_field_input_option_id(value : String) -> CustomFieldInput {
  { value: Json::object({ "id": Json::string(value) }) }
}

///|
pub fn custom_field_input_from_set_value(value : String) -> CustomFieldInput {
  if is_numeric_string(value) {
    custom_field_input_option_id(value)
  } else {
    custom_field_input_string(value)
  }
}

///|
pub fn CustomFieldInput::json_value(self : CustomFieldInput) -> Json {
  self.value
}

///|
pub fn CustomFieldInput::display_value(self : CustomFieldInput) -> String {
  match self.value {
    Json::String(value) => value
    other => other.stringify()
  }
}
