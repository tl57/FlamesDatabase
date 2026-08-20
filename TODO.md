# TODO

- [ ] Revisit the Name column's status-color logic in `DataTable.lua` (`BuildRow`) - currently colors by the first column with a number; reconsider how it should handle rows like Steel that only have a grey-tier value. Probably start the logic backwards: look at the color of the last skill range (grey), then green, etc.
- [x] Harden `DataTable.lua`'s `ContinueOnItemLoad` callback against a container being recycled for something else before the async item load completes (add a generation/epoch guard alongside `pendingItemId`). This was a suggestion from Claude because at the time, the Classic & TBC radiobuttons were disapearing as soon as I changed Tab and never came back. A game restart made this go away, so the real cause and solution isn't yet known - This is now outdated per the last commit. DataTable had SimpleGroup elements (Blizzard API) being added to Ace UI elements and those were causing problems and forcing extreme ways to try and update/discard/check ui element trees to prevent visual bugs. As per the last commit, SimpleGroup is no longer used, and the Ace API was fully embraced.
- [ ] reorganize strings into Localization
- [x] add support for keybind usage - to open the main window
- [x] rescan for usage of Blizzard Functions and move them to Functions instead
- [x] instead of quest links, use Questie links if Questie addon is found (impractical, since Questie doesnt have mouseover links)
- [ ] finish DungeonQuestData.lua
- [x] finish DungeonInfoData.lua
- [x] support slash commands - use `AceConfigCmd`'s `CreateChatCommand` (in `options.lua`) so `/flamesdatabase` (or similar) opens the options/main window; this is also what will put the currently-unused `AceConsole-3.0` lib to actual use
