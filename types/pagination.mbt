///|
pub(all) struct PageRequest {
  limit : Int
  start_at : Int
  fetch_all : Bool
} derive(Show, Eq)

///|
pub fn limited_page_request(limit : Int, start_at? : Int = 0) -> PageRequest {
  { limit, start_at, fetch_all: false }
}

///|
pub fn full_page_request(start_at? : Int = 0) -> PageRequest {
  { limit: 0, start_at, fetch_all: true }
}

///|
pub(all) struct PageInfo {
  start_at : Int
  limit : Int
  returned : Int
  total : Int
  fetch_all : Bool
  is_last : Bool
} derive(Show, Eq)

///|
pub fn page_info(
  start_at : Int,
  limit : Int,
  returned : Int,
  total : Int,
  fetch_all : Bool,
  is_last : Bool,
) -> PageInfo {
  { start_at, limit, returned, total, fetch_all, is_last }
}

///|
pub fn page_info_from_request(
  request : PageRequest,
  total : Int,
  returned : Int,
) -> PageInfo {
  let limit = if request.fetch_all { returned } else { request.limit }
  page_info(
    request.start_at,
    limit,
    returned,
    total,
    request.fetch_all,
    request.start_at + returned >= total,
  )
}
