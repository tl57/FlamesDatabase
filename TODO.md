# TODO

- [ ] Revisit the Name column's status-color logic in `DataTable.lua` (`BuildRow`) - currently colors by the first column with a number; reconsider how it should handle rows like Steel that only have a grey-tier value. Probably start the logic backwards: look at the color of the last skill range (grey), then green, etc.
- [ ] Harden `DataTable.lua`'s `ContinueOnItemLoad` callback against a container being recycled for something else before the async item load completes (add a generation/epoch guard alongside `pendingItemId`). This was a suggestion from Claude because at the time, the Classic & TBC radiobuttons were disapearing as soon as I changed Tab and never came back. A game restart made this go away, so the real cause and solution isn't yet known
- [ ] reorganize strings into Localization
- [ ] add support for keybind usage - to open the main window
- [ ] rescan for usage of Blizzard Functions and move them to Functions instead
