-- You need to first require Folio to then be able to add menus.
local folio = require("folio")

-- Then, you can now add add acitons as follows!

-- This is a action, it'll execute the function then close the menu automatically.
folio.newAction(
    "Example Action",
    function ()
        print("Hi!")
    end
)

-- This is a toggle, it will return in it's function the state of it.
folio.newToggle(
    "Example Toggle",
    function (state)
        print(state)
    end
)
-- You can also set symbols for tasks, you can provide a texture or a string with an emoji.
-- It just adds on the string, so unicode is also possible!
:setSymbol(":feather:") -- You do need to chain on these however, so you'll need to make your action a variable.


-- This is a category menu, you can add on actions or toggles to it.
-- You only have to call it, and then you can add onto it like below.
local testCat = folio.newCategory(
    "Example Category"
)

-- This adds a action.
testCat:newAction(
    "Example Subaction",
    function ()
        print("Hi! But, inline!")
    end
)
-- Like the others, you can also attach symbols.
:setSymbol(":magic_wand:")

-- This adds a toggle.
testCat:newToggle(
    "Example Subtoggle",
    function (state)
        print(state, "but inline!")
    end
)