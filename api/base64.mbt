///|
extern "js" fn ffi_btoa(input : String) -> String =
  #| (s) => btoa(unescape(encodeURIComponent(s)))

///|
fn base64_encode(input : String) -> String {
  ffi_btoa(input)
}
