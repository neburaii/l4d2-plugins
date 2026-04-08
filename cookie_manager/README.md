# Description
**replaces clientprefs.smx!!**

this was created with the following goals:
1. to streamline updating a plugin's internal data when cookies have their values updated.
2. support translation of a cookie's name/description
3. offer more ways to configure a cookie's value through a panel
4. improve how a cookie menu is constructed, and put it in the control of the server operator

plugins can register a function to be called when a specified cookie's value is changed. these callbacks will be called on any value change that originated from this plugin's interfaces. that's why it's designed as a replacement for clientprefs.smx, as it replaces all the commands from that plugin.

cookies can have additional data defined, via easy to use configuration files.
this data includes a localized display name/description, and an input type. depending on the input type, additional data is supported.

The input types are:
- **text** - prompts the user to type out the value in chat. it's not sent as a message, and instead redirected to be accepted as the new value for the cookie
- **text2** - same as text, but the prompt to type a message can be customized.
- **yesno** - select 1 for Yes (1), 2 for No (0)
- **onoff** - select 1 for On (1), 2 for Off (0)
- **multiple_choice** - manually define choices with custom labels, and what value to set the cookie to per choice. you can define any amount of choices.
- **slider** - press 1 and 2 to decrement/increment a value within a numeric range. a slider GUI will be displayed to visualize the value and its range

read more about how to define each input type in the provided [cookies.txt](./data/cookies.txt) file.

a custom cookie menu can be constructed from a single configuration file. the menu is a hierarchal structure. you can nest directories within eachother, to any depth you want.

aside from subdirectories, each directory may include buttons for "special" items, or cookies. clicking a cookie item brings up the input menu as per the defined input type of that cookie.

list of "special" items:
- **search** - opens a prompt asking for a search query. the user sends their query as a message, and a search using fuzzy matching is performed on the internal name of every publicly accessible cookie. a menu will display the results. if the query is an exact match, it instead directly opens the input menu for that cookie.
- **all** - a special directory built on demand. it contains every publicly accessible cookie.
- **all_categorized** - same as "all", except it filters to show only cookies that are manually added to any directory.
- **all_uncategorized** - same as "all", except it excludes all cookies manually added to any directory.

special keys are used in the default configuration to give an out of the box experience that's usable for every cookie installed on the server.

cookies without definitions will still be displayed in a menu. the display name/description will be its internal name/desc, and the input type will be "text" (this is the only one that can reliably be used to set any type of value, so it's a safe default).

## Soft requirements
- [multicolors](https://github.com/Bara/Multi-Colors) - to compile.
- [hxstocks](../hxlib/scripting/include/hxstocks.inc) - to compile.

## Suggested
- [panels_hide_hud](../panels_hide_hud/README.md) - makes panel menus more usable for HUDs with lots of overlap

# Usage
## Commands
- `sm_cookies` - behaves according to the total arguments provided.
	- for 0 arguments, it will print a list of cookies to the player's console.
	- for 1 arguments, it will read arg 1 as a cookie name and print its value to chat if a cookie is found with that name
	- for 2 or more arguments, arg 1 will be a cookie name and arg 2 onward will be concatenated as a value to set the cookie to (if cookie is found and you're allowed to set it).

- `sm_settings` - opens the cookie menu from the root directory

- `sm_set` - behaves according to the total arguments provided.
	- for 0 arguments, it will open the cookie menu from the root directory (shortcut for `sm_settings`)
	- for 1 argument, it will use arg 1 as a search query and perform a search of that cookie. if there's an exact match, a panel is opened for that cookie's input menu, otherwise a panel with the search results is displayed
	- for 2 or more arguments, it's the same as `sm_cookies` with 2 or more args. sets a cookie (arg 1) to a value (arg >= 2)

## Plugin Implementation
it's designed to not be a hard requirement for plugins that make use of its features. you may include a drop-in configuration file at "sourcemod/data/cookies.d/" to register additional data that makes the cookie compatible with features from this plugin.

a plugin may use a set of natives to register a CookieChanged callback to be called whenever a specified cookie's value changes.
I want to emphasize that this plugin is designed to NOT be a hard requirement. for plugins making use of this change hook system, i suggest you mark this plugin as optional and check for its library's existence as a condition for calling its natives.

## Cookie Defintions
to display localized names/descriptions, along with the input related data - configuration files are required to define this data for cookies.

there are 2 configuration locations:
1. [sourcemod/data/cookies.txt](./data/cookies.txt)
2. sourcemod/data/cookies.d/

**cookies.d** is a directory for drop-in configurations. this plugin will parse every file in here as a cookies definition config file. this is intended for plugins to include a definition config for the cookies they implement, without overriding the configuration intended for server operator use only.

**cookies.txt** is for server operators to manually define cookie data. it can also be used to override any drop in.
the parser will read this file first, and then the drop-ins in alphabetical order. the plugin will register the first defintiions encountered for a cookie. repeated encounters will be ignored. the takeaway is that the **cookies.txt** file has priority.

there are comments inside the included [cookies.txt](./data/cookies.txt) file that go over the formatting.

## Menu Customization
this is very different from the CookieMenu that comes with clientprefs. i wanted the structure of the menu to be configured from a single location, completely in the control of the server operator.

you may configure the menu in [sourcemod/data/cookie_menu.txt](./data/cookie_menu.txt).
an example is included. it's configured to have a search option, and a single directory containing every publicly accessible cookie.

there are comments in the file explaining the formatting.

# Changelog
## v1.0
- initial release
