# 🖼️ folio
_A lightweight, replacement action wheel._

---
Folio is a replacement for the current action wheel to introduce a menu which can be accessed the same way through the same key, and is mainly meant for those who want a simpler experience over the regular action wheel. I've tried to keep parity as much as possible with the original action wheel, with toggles like the original menu being a avaliable action, but also a drop down category version of the regular scroll menu for outfits as an example.

Built in docs are avaliable, but you may use the wiki (_if it's created_) for any other information.

To get started, all you need to do is the following in your script:
```lua
local folio = require("folio")
-- We're gonna first change our title of our menu, as it defaults to acitons
folio.setTitle("Menu")
-- Just adding a simple action, called test, we'll also attach this function to it so it does something specific when we run it.
local test = folio.newAction("Test", function() print("Tested!") end)
-- Since it returns itself, we can now change its symbol to an emoji, or one of our textures as it'll appear next to it!
test:setSymbol(":star:")
-- And thats it! ✨
```

---
An example avatar is avaliable in the repository for those who need extra help outside of the above example.

---
**folio Is under the FSL (Figura-Standard-License) license, which can be [viewed in the repository](https://github.com/tivvo/folio/LICENSE.md).**
