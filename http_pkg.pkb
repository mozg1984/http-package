create or replace package body http_pkg is
  
  type headers is table of header_value index by header_name;
  
  -- collection of headers for GET/POST requests
  post_headers_list headers;
  get_headers_list headers;

  -- Proxy settings
  proxy_addr constant varchar2(20) := 'your-proxy-address';
  proxy_user constant varchar2(10) := 'your-proxy-user';
  proxy_psswd constant varchar2(5) := 'your-proxy-password';
  through_proxy boolean := false;

  -- Current http version
  http_version constant varchar2(20) := utl_http.HTTP_VERSION_1_1;
  
  /* @public
   * Enable proxy mode
   */
  procedure enable_proxy
  is
  begin
    through_proxy := true;
  end;
  
  /* @public
   * Disable proxy mode
   */
  procedure disable_proxy
  is
  begin
    through_proxy := false;
  end;
  
  /* @private
   * Set proxy for request
   */
  procedure set_proxy(req in out nocopy utl_http.req)
  is
  begin
    utl_http.set_proxy(proxy_addr, '');
    utl_http.set_authentication(req, proxy_user, proxy_psswd, for_proxy => true);
  end;
  
  /* @private
   * Set wallet for https request
   */
  procedure set_wallet_if_https(url in varchar2)
  is
  begin
    if regexp_like(ltrim(url), '^https://', 'i') then
      utl_http.set_wallet('\path\to\wallet', 'Wallet-Name');
    end if;
  end;
 
  /* @public
   * Add header for POST request
   */
  procedure set_post_header(name in header_name, value in header_value)
  is 
  begin
    post_headers_list(name) := value;  
  end;
  
  /* @public
   * Remove header for POST request
   */
  procedure del_post_header(name in header_name)
  is 
  begin
    post_headers_list.delete(name);  
  end;
  
  /* @public
   * Add header for GET request
   */
  procedure set_get_header(name in header_name, value in header_value)
  is 
  begin
    get_headers_list(name) := value; 
  end;
  
  /* @public
   * Remove header for GET request
   */
  procedure del_get_header(name in header_name)
  is 
  begin
    get_headers_list.delete(name);  
  end;
  
  /* @private
   * Set all headers to request
   */
  procedure set_headers_list(req in out nocopy utl_http.req, headers_list in out nocopy headers)
  is
    header header_name; 
  begin
    header := headers_list.first;
    for i in 1..headers_list.count loop      
      utl_http.set_header(req, header, headers_list(header));      
      header := headers_list.next(header);
    end loop; 
  end;
 
  /* @public
   * Perform the POST request
   */
  procedure post_request(url in varchar2, post_data in clob, resp_data in out nocopy response)
  is
    req utl_http.req;
    res utl_http.resp;

    buffer varchar2(4000);
    max_buffer varchar2(32767);
    clob_buffer clob;

    data_length integer;
    offset integer := 1;
    amount integer := 2000;
  begin
    set_wallet_if_https(url);
    
    data_length := nvl(dbms_lob.getlength(post_data), 0);
    req := utl_http.begin_request(url, 'POST', http_version);
    set_headers_list(req, post_headers_list);

    if through_proxy then
      set_proxy(req);
    end if;

    if data_length <= 32767 then
      utl_http.set_header(req, 'Content-Length', data_length);
      utl_http.write_text(req, to_char(post_data));
    else
      utl_http.set_header(req, 'Transfer-Encoding', 'chunked');

      while offset < data_length loop
        dbms_lob.read(post_data, amount, offset, buffer);
        utl_http.write_text(req, buffer);
        offset := offset + amount;
      end loop;
    end if;

    res := utl_http.get_response(req);
    resp_data.status_code := res.status_code;
    resp_data.http_version := http_version;

    -- read content of response
    begin
      clob_buffer := empty_clob;

      loop
        utl_http.read_text(res, max_buffer, length(max_buffer));
        clob_buffer := clob_buffer || max_buffer;
      end loop;

      utl_http.end_response(res);
      resp_data.content := clob_buffer;

      exception
        when utl_http.end_of_body then
          utl_http.end_response(res);
          resp_data.content := clob_buffer;
        when others then null;
          utl_http.end_response(res);
          dbms_output.put_line(sqlerrm);
          dbms_output.put_line(dbms_utility.format_error_backtrace);
    end;

    exception
      when others then
        dbms_output.put_line(sqlerrm);
  end;
  
  /* @public
   * Perform the POST request
   */
  procedure post_request(url in varchar2, post_data in varchar2, resp_data in out nocopy response)
  is
  begin
    post_request(url, to_clob(post_data), resp_data);
  end;

  /* @public
   * Perform the GET request
   */
  procedure get_request(url in varchar2, resp_data in out nocopy response)
  is
    req utl_http.req;
    res utl_http.resp;
    buffer varchar2(32767);
    clob_buffer clob;
  begin
    set_wallet_if_https(url);
    
    req := utl_http.begin_request(url, 'GET', http_version);
    set_headers_list(req, get_headers_list);

    if through_proxy then
      set_proxy(req);
    end if;

    res := utl_http.get_response(req);
    resp_data.status_code := res.status_code;
    resp_data.http_version := http_version;

    -- read content of response
    begin
      clob_buffer := empty_clob;

      loop
        utl_http.read_text(res, buffer, length(buffer));
        clob_buffer := clob_buffer || buffer;
      end loop;

      utl_http.end_response(res);
      resp_data.content := clob_buffer;

      exception
        when utl_http.end_of_body then
          utl_http.end_response(res);
          resp_data.content := clob_buffer;
        when others then null;
          utl_http.end_response(res);
          dbms_output.put_line(sqlerrm);
          dbms_output.put_line(dbms_utility.format_error_backtrace);
    end;

    exception
      when others then
        dbms_output.put_line(sqlerrm);
  end;
  
  /* @public
   * Check if response is OK
   */
  function isOk(resp_data in out nocopy response) return boolean
  is
  begin
    return resp_data.status_code = utl_http.HTTP_OK;
  end;

begin 
  -- default headers
  post_headers_list('Content-Type') := 'charset=UTF-8';
  post_headers_list('Content-Encoding') := 'UTF-8';
  get_headers_list('User-Agent') := 'Mozilla/4.0';
end http_pkg;
