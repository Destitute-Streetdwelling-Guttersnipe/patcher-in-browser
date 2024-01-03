# patcher-in-browser
This is for the CLIphobia who wanna patch but don't wanna touch the command prompt.

Use offset and bytes (as hexadecimal number) in the following formats:

        BADC0DE:  41   42 53   54
       DEADBEEF   0x31 32  63 0x64
      0xF00DFACE  : CA FE 0xBA  BE

Support pre-defined patches in URL hash, such as `#{"name":"a_patcher_name","patches":"BADC0DE.41.42.53.54_F00DFACE.CA.FE.BA.BE"}`
