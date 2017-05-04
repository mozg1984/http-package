declare
  response http_pkg.response;

begin
  utl_http.set_response_error_check(false);
  
  /* 1. POST request (CLOB or VARCHAR2 data types) */
  
  /*
  You can set different headers before performing POST request:
  http_pkg.set_post_header('Content-Type', 'application/x-www-form-urlencoded');
  http_pkg.set_post_header('Some-header-name-1', 'Some-header-value-1');
  http_pkg.set_post_header('Some-header-name-2', 'Some-header-value-2');
  ...
  
  For removing header:
  http_pkg.del_post_header('Content-Type');
  http_pkg.del_post_header('Some-header-name-1');
  http_pkg.del_post_header('Some-header-name-2');
  ...
  */
  
  http_pkg.post_request('http://localhost:8080/', 'some-post-data', response);  
  
  /* 2. GET request */
  
  /*
  You can set different headers before performing GET request:
  http_pkg.set_get_header('Content-Type', 'application/x-www-form-urlencoded');
  http_pkg.set_get_header('Some-header-name-1', 'Some-header-value-1');
  http_pkg.set_get_header('Some-header-name-2', 'Some-header-value-2');
  ...
  
  For removing header:
  http_pkg.del_get_header('Content-Type');
  http_pkg.del_get_header('Some-header-name-1');
  http_pkg.del_get_header('Some-header-name-2');
  ...
  */
  
  http_pkg.get_request('http://localhost:8080/', response);
  
  /* 3. Checking response */
  
  -- You can check response like that (STATUS CODE = 200)
  if http_pkg.isOk(response) then
    null;  
  end if;
  
  -- or like that. It's the same way
  if response.status_code = utl_http.HTTP_OK then
    null;  
  end if;
  
  /* 4. Getting response message (CLOB data type)*/
  
  dbms_output.put_line(to_char(response.content));
  
end if;
