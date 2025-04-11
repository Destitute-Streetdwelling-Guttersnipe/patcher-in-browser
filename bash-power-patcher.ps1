#!/bin/bash
# This polyglot patcher can be used as a bash script or PowerShell script

### NOTE: bash script is wrapped in a PowerShell comment block (see https://cspotcode.com/posts/polyglot-powershell-and-bash-script)
echo `# <#` >/dev/null # avoid using #＞ directly, use #""> or something similar
set -eo pipefail

main() {
  echo -e "\e[1;42m bash-power-patcher can patch anything anywhere anytime anyhow anyway \e[0m"
  echo -ne "\e[1;32m ?? What do ya wanna patch ?? \e[0m" && read -r file
  while : ;do
    echo -ne "\e[1;32m !! Gimme yo patch !! \e[0m" && read -r line
    [[ ! $line ]] && break
    patch=$(<<<"$line" sed -E 's/ *#.*//g; s/ *([: =]) */\1/g; s/\b0x([0-9a-f])/\1/gi') # remove comments, repeated spaces, and prefix 0x
    if <<<"$patch" grep -viP '^( ?[0-9a-f]+[: ]|( ?\b[0-9a-f]{2})+=)(\b[0-9a-f]{2} ?)+$' >/dev/null
    then echo -e "\e[1;31m Invalid patch: $patch \e[0m" ; echo -e "$(show_examples)" ; continue ;fi
    error=$(patch_file "$file" "$patch" 2>&1 || :)
    echo -e "${error:+\e[1;31m }${error:-\e[1;32m OK} \e[0m"
  done
}
hash xxd || xxd() ( # emulate `xxd -r` and read data from stdin: `echo 123abc aa bb c d | xxd -r - filename`
  patchdd() { dd seek=$(($2)) of="$1" bs=1 conv=notrunc status=none ;}
  while IFS=': ' read o hex ;do printf \\x${hex// /\\x} | patchdd "${!#}" 0x$o ;done
)
hex() { printf %s "$*" | sed -E 's/\b[0-9a-f]{2}\b/\\x\0/gi; s/ //g' ;} # prepend "\x" to pairs of hex digits and remove spaces in arguments
patch_file() { if [[ $2 =~ '=' ]] ;then sed "s=$(hex $2)=" -i "$1" ;else <<<"$2" xxd -r -c256 - "$1" ;fi }
show_examples() {
cat <<EXAMPLES
\e[1;32m Lemme show ya how patches look like \e[0m
       DEADBEEF  FE E1  DE AF
        ACE0FBA5E:  0xFE ED  C0 DE
      0xFEDD06F00D :CA FE  0xBA BE
      DECAFDAD : B0 BA  C0 FF EE
      # BAEBEE : FE EE  F1 F0
      # FA CE  B0 0C  =0x0F F1 CE
       0xB0 0B=  D0 0D  0F  DE ED
EXAMPLES
}
main $*
exit ### NOTE: the end of bash script
#> > $null
function main() { param($e = [char]0x1b)
  echo "$e[1;42m bash-power-patcher can patch anything anywhere anytime anyhow anyway $e[0m"
  $file = Read-Host -Prompt "$e[1;32m ?? What do ya wanna patch ?? $e[0m"
  while ($true) {
    $line = Read-Host -Prompt "$e[1;32m !! Gimme yo patch !! $e[0m"
    if (!$line) { break }
    $patch = $line -replace ' *#.*','' -replace ' *([: =]) *','$1' -replace '\b0x([0-9a-f])','$1' # remove comments, repeated spaces, and prefix 0x
    $invalid = $patch -notmatch '^( ?[0-9a-f]+[: ]|( ?\b[0-9a-f]{2})+=)(\b[0-9a-f]{2} ?)+$'
    if ($invalid) { echo "$e[1;31m Invalid patch: $patch $e[0m" ; show_examples ; continue }
    try { patch_file $file $patch } catch { $error = $_ }
    if ($error) { echo "$e[1;31m $error $e[0m" } else { echo "$e[1;32m OK $e[0m" }
  }
}
function show_examples() { param($e = [char]0x1b)
  $lines = (Get-Content $PSCommandPath -Encoding UTF8 -Raw)
  echo ([Regex]::Match($lines,"(?s)EXAMPLES.(.+?).EXAMPLES").Groups[1].Value.Replace('\e', $e))
}
function patch_file() { param($file, $patch)
  $text = [IO.File]::ReadAllText($file, [Text.Encoding]::GetEncoding(1256))
  if ($patch -match '=') {
    $search, $changes = $patch.Trim().Split('=') | %{ -join( -split $_ | %{ [char]([byte]"0x$_") } ) }
    $offset = $text.IndexOf($search)
  } else {
    $offset, $data = $patch.Trim().Replace(':', ' ').Split(' ') | %{ [int]"0x$_" }
    $search = $changes = -join [char[]]$data
  }
  if ($offset -ge 0) { $text = $text.Remove($offset, $search.Length).Insert($offset, $changes) }
  [IO.File]::WriteAllText($file, $text, [Text.Encoding]::GetEncoding(1256))
}
main
