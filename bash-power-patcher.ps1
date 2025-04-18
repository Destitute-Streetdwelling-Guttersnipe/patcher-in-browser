#!/bin/bash
# This polyglot patcher can be used as a bash script or PowerShell script

### NOTE: bash script is wrapped in a PowerShell comment block (see https://cspotcode.com/posts/polyglot-powershell-and-bash-script)
echo `# <#` >/dev/null # avoid using #＞ directly, use #""> or something similar
set -eo pipefail

main() {
  echo -e "\e[1;42m bash-power-patcher can patch anything anywhere anytime anyhow anyway \e[0m"
  echo -ne "\e[1;32m ?? What do ya wanna patch ?? \e[0m" ; read -r file
  [ ! -f "$file" ] && echo -e "\e[1;31m File not found: $file \e[0m" && exit || :
  while echo -ne "\e[1;32m !! Gimme yo patch !! \e[0m" ; read -r line ; [[ $line ]] ;do
    patch=$(<<<"$line" sed -E 's/(\b0|\\)x([0-9a-f])/ \2/gi; s/ *#.*//g; s/ *([: =]) */\1/g') # remove comments, repeated spaces, and prefix 0x or \x
    if <<<"$patch" grep -viP '^( ?[0-9a-f]+[: ]|( ?\b[0-9a-f]{2})+=)(\b[0-9a-f]{2} ?)+$' >/dev/null
    then echo -e "\e[1;31m Invalid patch: $patch"; show_examples ; continue ;fi
    error=$(patch_file "$file" "$patch" 2>&1 || :)
    echo -e "${error:+\e[1;31m }${error:-\e[1;32m OK}" # show OK in green or show $error in red
  done
}
hash xxd || xxd() ( # emulate `xxd -r` and read data from stdin: `echo 123abc aa bb c d | xxd -r - filename`
  patchdd() { dd seek=$(($2)) of="$1" bs=1 conv=notrunc status=none ;}
  while IFS=': ' read o hex ;do printf \\x${hex// /\\x} | patchdd "${!#}" 0x$o ;done
)
hex() { printf %s "$*" | sed -E 's/\b[0-9a-f]{2}\b/\\x\0/gi; s/ //g' ;} # prepend "\x" to pairs of hex digits and remove spaces in arguments
patch_file() { if [[ $2 =~ = ]] ;then sed "s=$(hex $2)=" -i "$1" ;else <<<"$2" xxd -r -c256 - "$1" ;fi }
show_examples() {
  echo -e "\e[1;32m Lemme show ya how patches look like \e[0m"
  cat <<EXAMPLES
       DEADBEEF  FE E1  DE AF
        ACE0FBA5E:  0xFE ED  C0 DE
      0xFEDD06F00D :CA FE  \xBA BE
      DECAFDAD : B0 BA  C0 FF EE
      # \xBAEBEE : FE EE  F1 F0
      # \xFA CE  B0 0C  =0x0F F1 CE
       0xB0 0B=  D0 0D  0F  DE ED
EXAMPLES
}
main $*
exit ### NOTE: the end of bash script
#> > $null
function main() { param($e = [char]0x1b)
  echo "$e[1;42m bash-power-patcher can patch anything anywhere anytime anyhow anyway $e[0m"
  $file = Read-Host -Prompt "$e[1;32m ?? What do ya wanna patch ?? $e[0m"
  if (![IO.File]::Exists($file)) { echo "$e[1;31m File not found: $file $e[0m" ; return }
  while ($line = Read-Host -Prompt "$e[1;32m !! Gimme yo patch !! $e[0m") {
    $patch = $line -replace '(\b0|\\)x([0-9a-f])',' $2' -replace ' *#.*','' -replace ' *([: =]) *','$1' # remove comments, repeated spaces, and prefix 0x or \x
    $invalid = $patch -notmatch '^( ?[0-9a-f]+[: ]|( ?\b[0-9a-f]{2})+=)(\b[0-9a-f]{2} ?)+$'
    if ($invalid) { echo "$e[1;31m Invalid patch: $patch" ; show_examples ; continue }
    try { patch_file $file $patch } catch { $error = $_ }
    if ($error) { echo "$e[1;31m $error" } else { echo "$e[1;32m OK" }
  }
}
function show_examples() { param($e = [char]0x1b)
  $lines = (Get-Content $PSCommandPath -Encoding UTF8 -Raw)
  echo ([Regex]::Match($lines,'"(.+?)"\n.+?EXAMPLES').Groups[1].Value.Replace('\e', $e)) # extract quoted string in the line before EXAMPLES
  echo ([Regex]::Match($lines,"(?s)EXAMPLES.(.+?).EXAMPLES").Groups[1].Value) # extract lines between EXAMPLES
}
function patch_file() { param($file, $patch)
  $text = [IO.File]::ReadAllText($file, [Text.Encoding]::GetEncoding(1256))
  if ($patch -match '=') {
    $search, $changes = $patch.Trim().Split('=') | %{ -join( -split $_ | %{ [char]([byte]"0x$_") } ) }
    $offset = $text.IndexOf($search)
  } else {
    $offset, $data = $patch.Trim() -split ':| ' | %{ [int]"0x$_" }
    $search = $changes = -join [char[]]$data
  }
  if ($offset -ge 0) { $text = $text.Remove($offset, $search.Length).Insert($offset, $changes) }
  [IO.File]::WriteAllText($file, $text, [Text.Encoding]::GetEncoding(1256))
}
main
