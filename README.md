# patcher-in-browser
This is for the CLIphobia who wanna patch but don't wanna touch the command prompt.

## Patches format

Example of patching at specified offset with hex bytes:

       DEADBEEF  FE E1  DE AF
        ACE0FBA5E:  0xFE ED  C0 DE
      0xFEDD06F00D :CA FE  0xBA BE
      DECAFDAD : B0 BA  C0 FF EE
      # BAEBEE : FE EE  F1 F0

Example of searching and replacing with hex bytes:

      # FA CE  B0 0C  =0x0F F1 CE
       0xB0 0B=  D0 0D  0F  DE ED

Comment lines (starting with '#') are ignored.

## Patches in URL

Patches are read from URL hash at start-up, such as `#{"name":"FAE-FEE-F00","patches":"BADBED-DE-FE-CA-7E.FADEDFAD-BE-DE-FE-A7-ED"}`

Patches are written to URL hash upon applying to a file.

Patches in URL can be shared easier than uploading a patch file somewhere.

## Compare file to generate patches

Expand the section "Compare file (Diff hex bytes)" to generate patches for the differences between 2 files.
