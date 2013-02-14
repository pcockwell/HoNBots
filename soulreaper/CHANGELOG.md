SoulReaperBot Changelog
=======================

Release Thread
--------------
[SoulReaperBot (v0.4)]( http://forums.heroesofnewerth.com/showthread.php?481413-SoulReaperBot-(v0-4) )

v 0.4
-----
* Changed harass bonus for successful usage of ultimate
* Modified combo for ultimate
    * Will now ultimate, (attack if ready) and move towards the target position (without interrupting any attack orders)
    * Result is that the bot attempts to close ground without sacrificing damage to get a heal off
* Added significant laning harass code
    * 1v1
        * Will check regen, health percents, and enemy hero attack type and damage and adjust harass utility accordingly
        * Will take levels into account and adjust utility accordingly
    * 1+ man disadvantage
        * Will play more passive - especially if enemies are ranged
    * 1+ man advantage
        * Will play more agressive - especially if enemies are melee

v 0.3
-----
* Significant last hitting improvements
* Test results for 10 minutes of solo mid freefarm:
    * Before: 27/26, 24/24
    * After: 38/41, 46/43
* Overall improvement appears to be approximately a 50% increase in effectiveness last hitting and denying

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
