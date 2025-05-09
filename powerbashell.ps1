#!/bin/bash
# This polyglot patcher can be used as a bash script or PowerShell script

### NOTE: bash script is wrapped in a PowerShell comment block (see https://cspotcode.com/posts/polyglot-powershell-and-bash-script)
echo `# <#` >/dev/null # avoid using #＞ directly, use #""> or something similar
set -eo pipefail
port=8088

main() { [[ $1 = request ]] && on_request || start_server $port ;}
start_server() {
  hash nc || hash socat || { echo -e "\e[1;31m netcat or socat is not installed \e[0m" ; exit 1 ;}
  echo -e "\e[1;42m Listening at http://localhost:$1 \e[0m"
  read -rsn1 -t0.6 key || { open http://localhost:$1 & } # open browser if no key was pressed within 0.6 second
  if hash nc ;then
    mkfifo ${out="${TMPDIR:-/tmp/}.${0##*/}-$RANDOM$RANDOM"}
    trap 'rm "$out"' EXIT ERR
    while nc -l -p $1 <"$out" | on_request >"$out" ;do : ;done
  elif hash socat ;then
    socat TCP-LISTEN:$1,reuseaddr,fork SYSTEM:"'$0' request || kill \$SOCAT_PPID"
  fi
}
on_request() {
  read -r method path protocol
  echo -e "\e[1;32m ------ Request : $method $path $protocol \e[0m" >&2
  html=$(make_html)
  while read -r -t1 query ;do : ;done # URL query is at the last line which has no EOL character
  if [[ $path = / && $method = POST ]] ;then
    file=$(get_param file "$query")
    patches=$(get_param patches "$query" | sed -E 's/(\b0|\\)x([0-9a-f])/ \2/gi; s/ *#.*//g; s/ *([: =]) */\1/g; /^ ?$/d') # remove comments, repeated spaces, and prefix 0x or \x
    if invalid=$(<<<"$patches" grep -viP '^( ?[0-9a-f]+[: ]|( ?\b[0-9a-f]{2})+=)(\b[0-9a-f]{2} ?)+$')
    then result="Invalid patches: $invalid"
    elif [ ! -f "$file" ]; then result="File not found: $file"
    else result=$(while read line ;do patch_file "$file" "$line" 2>&1 ;done <<<"$patches" | uniq) ;fi
    printf "File : %s\nPatches : %s\nResult : %s\n" "$file" "$patches" "$result" >&2
    msg=${result:-OK}
  fi
  [[ $path = /    ]] && response_ok "${html/\$msg/${msg//</&lt}}" || :
  [[ $path = /end ]] && response_ok Kthxbye && exit 2 || :
}
patchdd() { dd seek=$(($2)) of="$1" bs=1 conv=notrunc status=none ;}
hex() { printf %s "$*" | sed -E 's/\b5e\b/\\^/gi; s/\b[0-9a-f]{2}\b/[\\x\0]/gi; s/ //g' ;} # prepend "\x" and wrap with "[]" for pairs of hex digits and remove spaces in arguments (to escape special characters in sed replacement)
find_offset() ( o=$(LANG=C sed ':0;$!{N;b0};'$(hex "s/${*:2}.*//;t;Q1") <(cat "$1"; echo) | wc -c) && echo $((o-1)) || : )
patch_file() { # find matched bytes and overwrite with patch bytes
  if [[ $2 =~ = ]] ;then
    [[ ! ${o=$(find_offset "$1" ${2%=*})} ]] && echo "cannot find: ${2%=*}" && exit
    patch="$(printf %x $o) ${2#*=}"
  fi
  args=(${patch:-${2/:/ }}) # read offset bytes <<<${patch:-${2/:/ }}
  printf $(printf '\\x%s' ${args[*]:1}) | patchdd "$1" 0x${args[0]}
}
response_ok() { printf "HTTP/1.1 200 OK\r\n\r\n%s" "$1" ;}
response_ok() ( LANG=C; printf "HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=UTF-8\r\nContent-Length: %s\r\n\r\n%s\r\n" ${#1} "$1" ) # need LANG=C to set the correct content length in bytes
# get value of query parameter, convert line-endings to Unix style, decode URL parameters
get_param() { printf %b "$(<<<"$2" grep -oP "(?<=$1=)[^&]+" | sed -E 's/\+/ /g; s/%0D%0A/\n/gi; s/%([0-9a-f]{2})/\\x\1/gi')" ;}
make_html() {
cat <<'HTML-TEMPLATE'
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
      0xFEDD06F00D :CA FE  \xBA BE
      DECAFDAD : B0 BA  C0 FF EE
      # \xBAEBEE : FE EE  F1 F0
      # \xFA CE  B0 0C  =0x0F F1 CE
       0xB0 0B=  D0 0D  0F  DE ED
    </textarea>
    <label for="file">Target file</label>
    <input type="text" id="file" name="file" onchange="putPatchesIntoUrl()"/>
    <input type="submit" value="【  Patch it  】" title="〖 »» ›› >> ＞＞ click me ＜＜ << ‹‹ «« 〗"/>
  </form>
  <label for="result">Aftermath</label>
  <textarea id="result" rows=4 readonly>$msg</textarea>
  <a href="/end" title="᚛ᚑᚌᚐᚋ᚜ cease and desist ᚛ᚑᚌᚐᚋ᚜">⟦ » » › › _ Exit _ ‹ ‹ « « ⟧</a>
  <script type="text/javascript">
        var el = (id) => document.getElementById(id)
        function putPatchesIntoUrl() {
            const name = el('name').innerText.trim()
            const file = el('file').value.trim()
            const patches = el('patches').value.trim()
            location.hash = '#' + JSON.stringify({name: name, file: file, patches: patches.replaceAll(' ', '~').split('\n')})
        }
        try { // example: #{"name":"Boaty-McBoatface","file":"/path/to/file","patches":["DEADBEEF~0F~F1~CE","CAFEBABE~FE~ED~FA~CE"]}
            var params = JSON.parse(decodeURI(location.hash.slice(1)))
            if (params.patches && (el('result').value || confirm('Load patches from URL?\n(Patches may contain illegal or offensive text)'))) {
                el('name').innerText = params.name
                el('file').value = params.file
                el('patches').value = params.patches.join('\n').replaceAll('~', ' ')
            }
        } catch(ex) { console.warn('Cannot parse parameters from URL hash: ', ex) }
  </script>
</body>
</html>
HTML-TEMPLATE
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
  if (($i=$patch.IndexOf('=')) -gt 0) {
    $search  = -join ( $patch[0..$i-1].Split(' ') | %{ [char][byte]"0x$_" } )
    $changes = $patch.Remove(0, $i+1).Split(' ') | %{ [byte]"0x$_" }
    $text = [IO.File]::ReadAllText($file, [Text.Encoding]::GetEncoding(1256))
    if (($offset = $text.IndexOf($search)) -lt 0) { throw "cannot find: $($patch[0..$i-1])" }
  } else {
    $offset, $changes = $patch -split ':| ' | %{ [int64]"0x$_" }
  }
  $stream = [IO.File]::OpenWrite($file)
  $stream.Seek($offset, [IO.SeekOrigin]::Begin) | Out-Null
  $stream.Write([byte[]]$changes, 0, $changes.Length) ; $stream.Close()
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
  $html = [Regex]::Match($lines,"(?s)HTML-TEMPLATE.(.+?).HTML-TEMPLATE").Groups[1].Value.Trim()
  $port = [Regex]::Match($lines,"port=(.+)").Groups[1].Value
  $listener = start_server $port
  while ($listener.IsListening -and !(on_request $listener.GetContext() $html)) {}
  $listener.Stop()
}
function on_request() { param($context, $html, $e = [char]0x1b)
  $request = $context.Request
  Write-Host "$e[1;32m ------- Request : $($request.HttpMethod) $($request.RawUrl) $e[0m"
  if ($request.RawUrl -ceq '/' -and $request.HttpMethod -ceq 'POST') {
    try {
      $rawParams = [IO.StreamReader]::New($request.InputStream, $request.ContentEncoding).ReadToEnd()
      $file = get_param 'file' $rawParams
      $patches = get_param 'patches' $rawParams
      $patches = $patches -replace '(\b0|\\)x([0-9a-f])',' $2' -replace ' *#.*','' -replace ' *([: =]) *','$1' -replace '(?m)^ ?\n','' # remove comments, repeated spaces, and prefix 0x or \x
      $invalid = $patches.Trim() -split "`n" -notmatch '^( ?[0-9a-f]+[: ]|( ?\b[0-9a-f]{2})+=)(\b[0-9a-f]{2} ?)+$' -join "`n"
      if ($invalid) { $result = "Invalid patches: $invalid" }
      elseif (![IO.File]::Exists($file)) { throw "File not found: $file" }
      else { $patches.Trim() -split ' ?\n ?' | %{ patch_file $file $_ } }
    } catch { $result = $_ }
    Write-Host "File : $file`nPatches : $patches`nResult: $result"
    $msg = $result -replace '^$','OK' -replace '<','&lt'
  }
  if ($request.RawUrl -ceq '/') { response_ok $html.Replace('$msg', $msg) $context.Response }
  if ($request.RawUrl -ceq '/end') { response_ok Kthxbye $context.Response ; return $true }
}
main
