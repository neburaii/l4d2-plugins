# Description
Change the title as seen in this screenshot
![motd_title](image/motd_title.png)

## Soft requirements
- [hxstocks](../hxlib/scripting/include/hxstocks.inc) (to compile)

# Usage
there's a convar called `motd_title_type`. its value determines where the plugin gets the final title from. possible types:
- **0**: vanilla (disables plugin)
- **1**: convar (reads title from `motd_title` convar)
- **2**: translation (reads title from sourcemod/translations/motd_title.phrases.txt)

edit the convar values and translation file to your liking

# Changelog
## v2.0
- rewritten with new method. uses usermessage hook to intercept, reformat, and resend the user message responsible for triggering the panel on the client
- new option to read title from a sourcemod translation file
- less prone to bugs and more compatible with other plugins.

## v1.1
- fixes bug where motd auto-opened when it shouldn't have

## v1.0
- original release
