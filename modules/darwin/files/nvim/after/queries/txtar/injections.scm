((file_entry
  (file_marker 
    (filename) @_filename)
  (file_content_line)* @injection.content)
 (#lua-match? @_filename "%.go$")
 (#set! injection.language "go")
 (#set! injection.combined))
