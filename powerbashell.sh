#!/bin/bash
# This polyglot patcher can be used as a bash script or PowerShell script

### NOTE: bash script is wrapped in a PowerShell comment block (see https://cspotcode.com/posts/polyglot-powershell-and-bash-script)
echo `# <#` >/dev/null # avoid using #＞ directly, use #""> or something similar

set -eo pipefail

main() { [[ $1 == 'request' ]] && on_http_request || start_http_server 8088 ;}
start_http_server() {
  echo "Listening on port $1"
  socat TCP-LISTEN:$1,reuseaddr,fork SYSTEM:"'${BASH_SOURCE[0]}' request"
}
on_http_request() {
  read -r method path protocol
  echo "------- Request : $method $path $protocol" >&2
  if [[ $method == 'POST' ]]; then
    while read -r -t1 query ;do : ;done # URL query is at the last line which has no EOL character
    file=$(get_param file "$query")
    patches=$(get_param patches "$query" | sed -E '/^ *#/d; s/ +/ /g; s/ ?(:|=) ?/\1/g; s/0x([0-9a-f])/\1/gi') # remove spaces, comment lines, and prefix 0x
    result=$(<<<"$patches" xxd -r -c256 - "$file" 2>&1)
    printf "File : %s\nPatches : %s\nResult : %s\n" "$file" "$patches" "$result" >&2
    msg=${result:-ok}
  fi
  [[ $path == "/" ]] && response_ok "$(make_html "$msg")"
}
response_ok() { echo -ne "HTTP/1.1 200 OK\r\n\r\n$1" ;}
response_ok() { echo -ne "HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=UTF-8\r\nContent-Length: ${#1}\r\n\r\n$1\r\n" ;}
# get value of query parameter, convert line-endings to Unix style, decode URL parameters
get_param() { printf %b "$(<<<"$2" grep -oP "(?<=$1=)[^&]+" | sed -E 's/\+/ /g; s/%0D%0A/\n/gi; s/%([0-9a-f]{2})/\\x\1/gi')" ;}
make_html() {
cat <<END-OF-HTML
<!DOCTYPE html>
<html>
<head>
    <title>PowerBashell Patcher</title>
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <link rel="icon" href="data:image/svg+xml,%3Csvg" type="image/x-icon">
    <style>
        input, textarea, h3 { display: inline-block; width: 100%; margin: 0 0 20px; padding: 3px; border-width: 3px }
        body, body * { background: #333; color: #ccc; max-width: 1024px; box-sizing: border-box; zoom: 1.5 }
        form > *:hover, h3:hover { background: #345; color: #ddd; }
    </style>
</head>
<body>
  <h2>PowerBashell Patcher</h2>
  <h3 id="name" contenteditable>Patchy McPatchface</h3>
  <form id="form" method="POST">
    <label for="patches">Offset and bytes (in hexadecimal)</label>
    <textarea id="patches" name="patches" rows=8 wrap="off" onchange="putPatchesIntoUrl()">
       DEADBEEF  FE E1  DE AF
        ACE0FBA5E:  0xFE ED  C0 DE
      0xFEDD06F00D :CA FE  0xBA BE
      DECAFDAD : B0 BA  C0 FF EE
      # BAEBEE : FE EE  F1 F0
      # FA CE  B0 0C  =0x0F F1 CE
       0xB0 0B=  D0 0D  0F  DE ED
    </textarea>
    <label for="file">Original file</label>
    <input type="text" id="file" name="file" onchange="putPatchesIntoUrl()"/>
    <input type="submit" value="Patch file"/>
  </form>
  <label for="result">Result</label>
  <textarea id="result" rows=8 wrap="off" readonly>$1</textarea>
  <script type="text/javascript">
        var el = (id) => document.getElementById(id)
        function putPatchesIntoUrl() {
            const name = el('name').innerText.trim()
            const file = el('file').value.trim()
            const patches = el('patches').value.trim()
            location.hash = '#' + JSON.stringify({name: name, file: file, patches: patches.replaceAll(' ', '~').split('\\\\n')})
        }
        try { // example: #{"name":"Boaty-McBoatface","file":"/path/to/file","patches":["DEADBEEF~0F~F1~CE","CAFEBABE~FE~ED~FA~CE"]}
            var params = JSON.parse(decodeURI(location.hash.slice(1)))
            el('name').innerText = params.name
            el('file').value = params.file
            el('patches').value = params.patches.join('\\\\n').replaceAll('~', ' ')
        } catch(ex) {
            console.warn('Error: cannot parse parameters from URL hash', ex)
        }
  </script>
</body>
</html>
END-OF-HTML
}
# while true; do
  # res="$(echo -ne "HTTP/1.1 200 OK\r\nContent-Length: ${#html}\r\n\r\n$html")"
  # req="$(printf %s "$res" | nc -l -p 8080 | grep -oP "^(GET|POST) [^ ]+")"
  # echo "$req"
  # case $req in
    # "GET /" ) html="$(make_html 11)" ;;
    # * ) html="$(make_html 22)" ;;
  # esac
# done

main $*
exit ### NOTE: the end of bash script
#> > $null
