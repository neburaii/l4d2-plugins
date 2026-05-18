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
### 2.2
- fixed error when motd is shown by ShowVGUIPanel native (which fixes broken compat with basetriggers.smx)
- fixed broken code for translation motd_title_type

### 2.1
- added plugin library

### 2.0
- rewritten with new method. uses usermessage hook to intercept, reformat, and resend the user message responsible for triggering the panel on the client
- new option to read title from a sourcemod translation file
- less prone to bugs and more compatible with other plugins.

### 1.1
- fixes bug where motd auto-opened when it shouldn't have

### 1.0
- original release
