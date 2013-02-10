SoulReaperBot Changelog
=======================

Release Thread
--------------
(SoulReaperBot (v0.2))[http://forums.heroesofnewerth.com/showthread.php?481413-SoulReaperBot-(v0-2)]

v 0.2
-----
* Will now use Ring of Sorcery - code taken from BeheBot by Djulio
* Will now heal on the way back to the well if at low health (so he that if he is getting chased, he stills heals himself)
* Removed a bunch of debug statements

v 0.1
-----

* Initial release
* Items
    * Early: 3x Minor Totems, Ring of Protection, Mark of the Novice, Runes of the Blight
    * Laning: Ring of the Teacher, Marchers, Amulet of the Exile, Ring of Sorcery
    * Mid: Steamboots, Icon of the Goddess, Sheepstick
    * Late: Frostfield Plate, Behemoth's Heart, Barrier Idol
* Have been unable to reach a point where the bot gets enough farm to use a sheepstick, or frostfield plate
* Bot currently is not set up to use Ring of Sorcery
* Uses Ult -> Attack -> Heal if it calculates that it can kill the target (magic resistance is taken into account)
* TODO:
    * Predictive last itting
    * Full item usage
    * Smart farming (with skills)
