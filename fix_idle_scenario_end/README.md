# Description
if `sb_all_bot_game` and `allow_all_bot_survivor_team` are `0`, then a round will restart if the only alive and not incapacitated survivors are bots. this includes the bot of idle players.

this can be annoying sometimes. for example, maybe you just pressed idle and immediately the other human players die. you realize this, and take back control of your survivor. but the screen fades to black and the round resets regardless.

that scenario is rare, but when it happens it's really annoying. enabling either of the convars mentioned above isn't a good solution. so, this plugin was made. recently idle players will now count as a real player.

# Usage
you can adjust how recent the idle must have happened. set to -1 to apply to allow any length of time, or 0 to disable plugin.
- `fix_idle_scenario_end_max_idle`

# Changelog
- initial release
