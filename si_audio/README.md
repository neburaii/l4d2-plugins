plugins that complement eachother quite well, together achieving better SI audio feedback

* proximity_jockey_volume *can* be expanded to cover all SI, but every one except the jockey has very clear cues for each attack/ability. Jockeys make no sound when they use their ability, so they're the only one i felt would benefit from this. Default convar values can probably be fine tuned, but it's better than vanilla! (especially combined with unsilent_jockey. No more silent jockey excuses!!)

* consistent_ability_cue does 2 main things: first is it ensures the sound an SI makes when they use their ability will always play (hunter and charger sometimes wouldn't play it at all), and second is to ensure these sounds can never be interrupted by anything other than sounds of the same high priority, or some event that "ends" or "counters" their ability (hunter being shoved, charger slamming into wall, si dying, etc).
Most silent sounds from my testing came from interruptions happening immediately after the ability sound plays. With that issue directly fixed, expect to encounter far fewer (i don't wanna say never because you never know!) silent abilities
