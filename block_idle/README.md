yet another plugin to fix idle exploits, except this one does a few things i couldn't find in any other plugin:
* automatic idle from director_afk_timeout cvar is covered
* idle is blocked whenever there isn't an available client slot (an issue most noticeable in a mode like hard 28)
* attempting to idle when it's blocked will queue the input, making it happen as soon as blocking conditions are untrue (queue is canceled if survivor moves)
* coming back from idle (take over bot) checks the same conditions for exploit prevention (this also gets queued when attempted during block)

Not all animations block idle