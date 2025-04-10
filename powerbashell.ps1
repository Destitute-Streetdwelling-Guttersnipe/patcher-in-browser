#!/bin/bash
# This polyglot patcher can be used as a bash script or PowerShell script

### NOTE: bash script is wrapped in a PowerShell comment block (see https://cspotcode.com/posts/polyglot-powershell-and-bash-script)
echo `# <#` >/dev/null # avoid using #＞ directly, use #""> or something similar
set -eo pipefail
port=8088

main() { [[ $1 == 'request' ]] && on_request || start_server $port ;}
start_server() {
  hash nc || hash socat || { echo -e "\e[1;31m netcat or socat is not installed \e[0m" ; exit 1 ;}
  echo -e "\e[1;42m Listening at http://localhost:$1 \e[0m"
  read -rsn1 -t0.6 key || { open http://localhost:$1 & } # open browser if no key was pressed within 0.6 second
  if hash nc ;then
    mkfifo ${out="${TMPDIR:-/tmp/}.${BASH_SOURCE[0]##*/}-$RANDOM$RANDOM"}
    trap 'rm "$out"' EXIT ERR
    while nc -l -p $1 <"$out" | on_request >"$out" ;do : ;done
  elif hash socat ;then
    socat TCP-LISTEN:$1,reuseaddr,fork SYSTEM:"'${BASH_SOURCE[0]}' request"
  fi
}
on_request() {
  read -r method path protocol
  echo -e "\e[1;32m ------ Request : $method $path $protocol \e[0m" >&2
  while read -r -t1 query ;do : ;done # URL query is at the last line which has no EOL character
  if [[ $path == "/" && $method == 'POST' ]] ;then
    file=$(get_param file "$query")
    patches=$(get_param patches "$query" | sed -E 's/ *#.*//g; s/ *([: =]) */\1/g; /^ ?$/d; s/\b0x([0-9a-f])/\1/gi') # remove comments, repeated spaces, and prefix 0x
    if invalid=$(<<<"$patches" grep -viP '^( ?[0-9a-f]+[: ]|( ?\b[0-9a-f]{2})+=)(\b[0-9a-f]{2} ?)+$')
    then result="Invalid patches: $invalid"
    else result=$(<<<"$patches" patch_file "$file" 2>&1 | uniq -u) ;fi
    printf "File : %s\nPatches : %s\nResult : %s\n" "$file" "$patches" "$result" >&2
    msg=${result:-OK}
  fi
  [[ $path == "/"    ]] && response_ok "$(make_html "$msg")" || :
  [[ $path == "/end" ]] && response_ok Kthxbye || :
  [[ $path == "/end" ]] && { [[ $SOCAT_PPID ]] && kill "$SOCAT_PPID" || exit 1 ;} || :
}
hash xxd || xxd() ( # emulate `xxd -r` and read data from stdin: `echo 123abc aa bb c d | xxd -r - filename`
  patchdd() { dd seek=$(($2)) of="$1" bs=1 conv=notrunc status=none ;}
  while IFS=': ' read o hex ;do printf \\x${hex// /\\x} | patchdd "${!#}" 0x$o ;done
)
hex() { printf %s "$*" | sed -E 's/\b[0-9a-f]{2}\b/\\x\0/gi; s/ //g' ;} # prepend "\x" to pairs of hex digits and remove spaces in arguments
patch_file() {
  while read -r line ;do # replace with sed or patch with xxd
    if [[ $line =~ '=' ]] ;then sed "s=$(hex $line)=" -i "$1" ;else <<<"$line" xxd -r -c256 - "$1" ;fi
  done
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
        body, body * { background: #333; color: #4c4; max-width: 1024px; box-sizing: border-box; zoom: 1.25; text-align: center; margin: auto }
        a, input, textarea, h3 { display: inline-block; width: 95%; margin: 2px 0 10px; padding: 3px; border-width: 3px }
        form > *:hover, a:hover { background: #383; color: #eee; outline: 3px dotted yellow }
    </style>
</head>
<body>
  <a href="https://github.com/Destitute-Streetdwelling-Guttersnipe/patcher-in-browser" title="{｛ the go-to source ｝}">⟫⟫ _ PowerBashell Patcher _ ⟪⟪</a>
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
    <label for="file">Target file</label>
    <input type="text" id="file" name="file" onchange="putPatchesIntoUrl()"/>
    <input type="submit" value="【  Patch it  】" title="〖 »» ›› >> ＞＞ click me ＜＜ << ‹‹ «« 〗"/>
  </form>
  <label for="result">Aftermath</label>
  <textarea id="result" rows=4 readonly>$1</textarea>
  <a href="/end" title="᚛ᚑᚌᚐᚋ᚜ cease and desist ᚛ᚑᚌᚐᚋ᚜">⟦ » » › › _ Exit _ ‹ ‹ « « ⟧</a>
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
        } catch(ex) { console.warn('Error: cannot parse parameters from URL hash', ex) }
  </script>
</body>
</html>
END-OF-HTML
}
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
  $text = [IO.File]::ReadAllText($file, [Text.Encoding]::GetEncoding(1256))
  $patches.Trim() -split ' ?\n ?' | %{
    if ($_ -match '=') {
      $search, $changes = $_.Split('=') | %{ -join( -split $_ | %{ [char]([byte]"0x$_") } ) }
      $offset = $text.IndexOf($search)
    } else {
      $offset, $data = $_.Replace(':', ' ').Split(' ') | %{ [int]"0x$_" }
      $search = $changes = -join [char[]]$data
    }
    if ($offset -ge 0) { $text = $text.Remove($offset, $search.Length).Insert($offset, $changes) }
  }
  [IO.File]::WriteAllText($file, $text, [Text.Encoding]::GetEncoding(1256))
}
function start_server() { param($port, $e = [char]0x1b)
  $listener = [System.Net.HttpListener]::New()
  $listener.Prefixes.Add("http://localhost:$port/")
  $listener.Start()
  if ($listener.IsListening) {
    Write-Host "$e[1;42m Listening at $($listener.Prefixes) $e[0m"
    Start-Sleep 0.6
    if (![System.Console]::KeyAvailable) { start $listener.Prefixes } # open browser if no key was pressed within 0.6 second
  }
  return $listener
}
function main() {
  $lines = (Get-Content $PSCommandPath -Encoding UTF8 -Raw)
  $html = [Regex]::Match($lines,"(?sm)END-OF-HTML.(.+?).END-OF-HTML").Groups[1].Value.Replace('\\\\','\')
  $port = [Regex]::Match($lines,"port=(.+)").Groups[1].Value
  $listener = start_server $port
  while ($listener.IsListening -and !(on_request $listener.GetContext() $html)) {}
  $listener.Stop()
}
function on_request() { param($context, $html, $e = [char]0x1b)
  $request = $context.Request
  Write-Host "$e[1;32m ------- Request : $($request.HttpMethod) $($request.RawUrl) $e[0m"
  if ($request.RawUrl -eq '/' -and $request.HttpMethod -eq 'POST') {
    try {
      $rawParams = [IO.StreamReader]::New($request.InputStream, $request.ContentEncoding).ReadToEnd()
      $file = get_param 'file' $rawParams
      $patches = get_param 'patches' $rawParams
      $patches = $patches -replace ' *#.*','' -replace ' *([: =]) *','$1' -replace '(?m)^ ?\n','' -replace '\b0x([0-9a-f])','$1' # remove comments, repeated spaces, and prefix 0x
      $invalid = $patches -split "`n" -notmatch '^( ?[0-9a-f]+[: ]|( ?\b[0-9a-f]{2})+=)(\b[0-9a-f]{2} ?)+$' -join "`n"
      if ($invalid) { $result = "Invalid patches: $invalid" }
      else { patch_file $file $patches }
    } catch { $result = $_ }
    Write-Host "File : $file`nPatches : $patches`nResult: $result"
    $msg = $result -replace '^$','OK'
  }
  if ($request.RawUrl -eq '/') { response_ok $html.Replace('$1', $msg) $context.Response }
  if ($request.RawUrl -eq '/end') { response_ok Kthxbye $context.Response ; return $true }
}
main
