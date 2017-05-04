create or replace package http_pkg is

  -- for getting response
  type response is record (
    status_code number,
    http_version varchar2(64),
    content clob
  );  

  -- types for header's name and value
  subtype header_name is varchar2(4000);
  subtype header_value is varchar2(4000);
  
  -- Proxy control 
  procedure enable_proxy;
  procedure disable_proxy;
  
  -- Add/remove header for POST request
  procedure set_post_header(name in header_name, value in header_value);
  procedure del_post_header(name in header_name);
  
  -- Add/remove header for GET request
  procedure set_get_header(name in header_name, value in header_value);
  procedure del_get_header(name in header_name);

  -- Perform the POST request 
  procedure post_request(url in varchar2, post_data in clob, resp_data in out nocopy response);
  procedure post_request(url in varchar2, post_data in varchar2, resp_data in out nocopy response);
  
  -- Perform the GET request
  procedure get_request(url in varchar2, resp_data in out nocopy response);
  
  -- Check if response is OK
  function isOk(resp_data in out nocopy response) return boolean;
  
end http_pkg;
