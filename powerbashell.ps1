#!/bin/bash
# This polyglot patcher can be used as a bash script or PowerShell script

### NOTE: bash script is wrapped in a PowerShell comment block (see https://cspotcode.com/posts/polyglot-powershell-and-bash-script)
echo `# <#` >/dev/null # avoid using #＞ directly, use #""> or something similar

set -eo pipefail

main() { [[ $1 == 'request' ]] && on_request || start_server 8088 ;}
start_server() {
  echo -e "\e[1;42m Listening at http://localhost:$1 \e[0m" >&2
  socat TCP-LISTEN:$1,reuseaddr,fork SYSTEM:"'${BASH_SOURCE[0]}' request"
}
on_request() {
  read -r method path protocol
  echo "------- Request : $method $path $protocol" >&2
  if [[ $path == "/" && $method == 'POST' ]]; then
    while read -r -t1 query ;do : ;done # URL query is at the last line which has no EOL character
    file=$(get_param file "$query")
    patches=$(get_param patches "$query" | sed -E 's/ *#.*//g; s/ +/ /g; s/ ?(:|=) ?/\1/g; s/\b0x([0-9a-f])/\1/gi') # remove comments, repeated spaces, and prefix 0x
    result=$(<<<"$patches" xxd -r -c256 - "$file" 2>&1)
    printf "File : %s\nPatches : %s\nResult : %s\n" "$file" "$patches" "$result" >&2
    msg=${result:-OK}
  fi
  [[ $path == "/"    ]] && response_ok "$(make_html "$msg")" || :
  [[ $path == "/end" ]] && response_ok Kthxbye && kill $SOCAT_PPID || :
}
response_ok() { echo -ne "HTTP/1.1 200 OK\r\n\r\n$1" ;}
response_ok() ( LANG=C; echo -ne "HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=UTF-8\r\nContent-Length: ${#1}\r\n\r\n$1\r\n" ) # need LANG=C to set the correct content length in bytes
# get value of query parameter, convert line-endings to Unix style, decode URL parameters
get_param() { printf %b "$(<<<"$2" grep -oP "(?<=$1=)[^&]+" | sed -E 's/\+/ /g; s/%0D%0A/\n/gi; s/%([0-9a-f]{2})/\\x\1/gi')" ;}
make_html() {
cat <<END-OF-HTML
<!DOCTYPE html>
<html>
<head>
    <title>PowerBashell Patcher</title>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <link rel="icon" href="data:image/svg+xml,%3Csvg" type="image/x-icon">
    <style>
        @media (prefers-color-scheme: light) {}
        a, input, textarea, h3 { display: inline-block; width: 100%; margin: 0 0 20px; padding: 3px; border-width: 3px }
        body, body * { background: #333; color: #4a4; max-width: 1024px; box-sizing: border-box; zoom: 1.5; text-align: center }
        form > *:hover, h3:hover { background: #345; color: #ddd; outline: 2px dotted yellow }
    </style>
</head>
<body>
  <a href="https://github.com/Destitute-Streetdwelling-Guttersnipe/patcher-in-browser" title="{ the go-to source }">⟫⟫ PowerBashell Patcher ⟪⟪</a>
  <form id="form" method="POST">
    <h3 id="name" contenteditable title="〚⟦ edit me ⟧〛">Patchy McPatchface</h3>
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
    <input type="submit" value="【  Patch file  】" title="»»››>>＞＞ click me ＜＜<<‹‹««"/>
  </form>
  <label for="result">Result</label>
  <textarea id="result" rows=4 readonly>$1</textarea>
  <a href="/end">Exit</a>
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
Add-Type -AssemblyName System.Web
function get_param() { param($name, $query)
  if ($query -match "$name=([^&]+)") {
    return [System.Web.HttpUtility]::UrlDecode($Matches[1].Replace('%0D%0A','%0A')) # convert line-endings to Unix style
  }
}
function response_ok() { param($html, $response)
  $buffer = [System.Text.Encoding]::UTF8.GetBytes($html)
  $response.ContentLength64 = $buffer.Length
  $response.OutputStream.Write($buffer, 0, $buffer.Length)
  $response.OutputStream.Close()
}
function patch_file() { param($file, $patches)
  $bytes = [System.IO.File]::ReadAllBytes($file)
  $patches -split '\n' -match '\S' | %{
    $offset, $data = $_.Trim().Replace(':', ' ').Split(' ') | %{ [int32]"0x$_" }
    ([byte[]]$data).CopyTo($bytes, $offset)
  }
  [System.IO.File]::WriteAllBytes($file, $bytes)
}
$lines = (Get-Content $PSCommandPath -Encoding UTF8 -Raw)
$html = [Regex]::Match($lines,"(?sm)END-OF-HTML.(.+?).END-OF-HTML").Groups[1].Value
$listener = [System.Net.HttpListener]::New()
$listener.Prefixes.Add("http://localhost:8088/")
$listener.Start()
if ($listener.IsListening) {
  write-host " Listening at $($listener.Prefixes) " -f 'black' -b 'gre'
}
while ($listener.IsListening) {
  $context = $listener.GetContext()
  $request = $context.Request
  write-host "------- Request : $($request.HttpMethod) $($request.RawUrl)" -f 'gre'
  $result = ''
  if ($request.RawUrl -eq '/' -and $request.HttpMethod -eq 'POST') {
    try {
      $reader = [System.IO.StreamReader]::New($request.InputStream, $request.ContentEncoding)
      $rawParams = $reader.ReadToEnd()
      $file = get_param 'file' $rawParams
      $patches = get_param 'patches' $rawParams
      $patches = $patches -replace ' *#.*','' -replace ' +',' ' -replace ' ?(:|=) ?','$1' -replace '\b0x([0-9a-f])','$1' # remove comments, repeated spaces, and prefix 0x
      patch_file $file $patches
      $result = 'OK'
    } catch { $result = $_ }
    write-host "File : $file`nPatches : $patches`nResult: $result"
  }
  if ($request.RawUrl -eq '/') {
    response_ok $html.Replace('$1', $result) $context.Response
  }
  if ($request.RawUrl -eq '/end') {
    response_ok Kthxbye $context.Response
    break
  }
}
$listener.Stop()
