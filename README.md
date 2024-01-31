# patcher-in-browser
This is for the CLIphobia who wanna patch but don't wanna touch the command prompt.

![screenshot](https://github.com/Destitute-Streetdwelling-Guttersnipe/patcher-in-browser/assets/90743025/1c228cef-90b1-4315-bff5-6fa026cfb7df)

## Patches format

Each line contains what to patch (hex bytes) and how to patch (offset or bytes to be searched).

Comment lines (starting with '#') are ignored. Comment should not use `~` (tilde) since it's used for serialization of patches in URL. You can replace `~` with $HOME (in path), or %7E (in URL). 

Example of patching at specified offset with hex bytes:

       DEADBEEF  FE E1  DE AF
        ACE0FBA5E:  0xFE ED  C0 DE
      0xFEDD06F00D :CA FE  0xBA BE
      DECAFDAD : B0 BA  C0 FF EE
      # BAEBEE : FE EE  F1 F0

Example of searching and replacing with hex bytes:

      # FA CE  B0 0C  =0x0F F1 CE
       0xB0 0B=  D0 0D  0F  DE ED

## Patches in URL

Patches are read from URL hash at start-up, such as `#{"name":"FAE-FEE-F00","patches":["BADBED~DE~FE~CA~7E","FADEDFAD~BE~DE~FE~A7~ED"]}`

Patches are written to URL hash when the patches input lose focus.

Patches in URL can be shared easier than uploading a patch file somewhere.

## Compare file to generate patches

Expand the section "Compare file (Diff hex bytes)" to generate patches for the differences between 2 files.

## Similar tools

Other tools that also support patches in URL:

* My fork of RomPatcher.js (patch file in URL) https://destitute-streetdwelling-guttersnipe.github.io/RomPatcher.js/#{"PATCHER":[{"name":"Boaty-McBoatface","file":"data:;base64,VVBTMQAgboMAIG6D+pUXwPqVF8AybecD"}]}
* CyberChef (search & replace hex string) https://gchq.github.io/CyberChef/#recipe=To_Hex('Colon',0)Find_/_Replace({'option':'Regex','string':'97:94:0D:00'},'79:94:0D:00',true,false,true,false)From_Hex('Auto')
