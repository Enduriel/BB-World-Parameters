# Changelog

## Unreleased

## 1.1.0 - 2026-10-21

- Now requires MSU 1.8.0 or later. Older MSU versions broke world map fights on maps with extra settlements or noble houses: weak parties won, both sides died or fights never ended, and saves stopped loading. A save made while such a fight was running may stay broken; load an earlier one.
- Fixed world generation never finishing when a settlement type ran out of names. Such settlements now reuse a name with a numeral, e.g. "Hohenfurt II".
- Fixed the campaign start getting stuck on the loading screen at high settlement spacing or with forced coastal city states.
- Extra passes for the minimum number of city states now only place the missing ones, never more than 3.
- Worldgen now logs the highest faction ID, and a warning when it reaches 64 or more: every extra village and noble house raises it, and in the original game battles with a faction of ID 64 or more can break zones of control.
- When a new world can't be generated, you are now sent back to the main menu with a message saying what failed and which settings to lower, instead of being stuck on the loading screen. For example, with many villages and little spacing there may be no room left for the noble houses' fortresses.
- Fixed the same seed giving different maps with raised settlement or faction settings: the extra settlements and the noble houses are now picked the same way every time.
