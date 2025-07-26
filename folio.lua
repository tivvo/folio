---@diagnostic disable: undefined-field
--[[
-- Folio [V2] --
> A *(debatebly)*, lightweight scrollable replacement for the action wheel.
  Developed for Project "Starlight"
✦ created by tiv/tivwo

LICENSE: Under the propietary FSL license, (Figura Standard/Scripting License)
         Please see license.md if in repository, or see in a repository with the FSL
         license included.
--]]

--- The Folio module, a replacement for the action wheel.
---@class Folio
local folio = {}
local sharedTextParams = {
    OptionWidth = -10,
    CursorWidth = 2,
    CursorHeight = 8
}

--#region Folio Value Internal
local currentMenu = {}
currentMenu.Actions = {}
local toggleTrack ={}
local expandTrack = {}
local forceClosed = false
local inWheel = false
local pos = 1
---@type Event.Generic[]
local folioRegistars = {}
--#endregion Folio Value Internal

local folioRenderPart = models.model:newPart("folioRenderPart", "GUI")
folioRenderPart:light(15,15)
currentMenu.Title = folioRenderPart:newText("folio.Title"):setText("Actions"):setPos(-10,4,0):setScale(1,1,1):setVisible(false):outlineColor(vec(26/255,37/255,58/255)):outline(true)
local blankTex = textures["1x1white"] or textures:newTexture("1x1white",1,1):setPixel(0,0,vec(1,1,1))
currentMenu.Cursor = folioRenderPart:newSprite("folio.Cursor")
:texture(blankTex, 1,1)
:setVisible(false)
:setScale(2,7)
:setPos(0,0)
events.TICK:register(function ()
    if folioRenderPart:getPos() ~= (vec(-client:getScaledWindowSize().x/2,-client:getScaledWindowSize().y/2,0)) then
        folioRenderPart:setPos(-client:getScaledWindowSize().x/2,-client:getScaledWindowSize().y/2,0)
        folioRenderPart:setLight(15,15)
    end
end, "folioCorrectionRender")

--#region Top-Level Internal Functions (required in classes)

---Applies a symbol to one of the action classes.
---@param symbol string|Texture
---@param self table
local function addSymbol (symbol, self)
    local isToggle = self.OnToggle ~= nil
    if (type(symbol) == "string") then
        self.Symbol = symbol
        local text = (isToggle and toJson({{text=symbol.." "..self.Text},{text=" ■", color = "red"}}) or symbol.." "..self.Text)
        self.Task:setText(text)
    elseif (type(symbol) == "Texture") then
        local text = (isToggle and toJson({{text="   "..self.Text},{text=" ■", color = "red"}}) or "   "..self.Text)
        self.Task:setText(text)
        self.Symbol = folioRenderPart:newSprite("folio.Symbol."..self.Text)
        :pos(self.Task:getPos() +- vec(0,0,-2))
        :texture(symbol, 8,8)
        :setVisible(false)
    end
end

--#endregion Top-Level Internal Functions

--#region Class Registration
--- fyi; follows the same class architecture kinda

---A new task that can be considered a single use action, just like a action page.
---@class ActionTask
---@field Task TextTask
---@field Text string
---@field Symbol SpriteTask|string
---@field OnSelect function
local ActionTask = {}
ActionTask.__index = ActionTask

---Creates a new action task.
---@param name string The name of the task, this will also be used as the label.
---@param onSelect function The function that will be executed when the task is selected.
---@param override string? A override for when creating a task to set it's class suffix to something different.
---@param isSubAction boolean? If this task is a sub action or not.
---@param parent string? The parent of this task, used in subaction related functions.
function ActionTask.new (name, onSelect, override, isSubAction, parent)
    local self = {
        Task = folioRenderPart:newText(override ~= nil and override or "folio.Action."..name)
        :setText(name)
        :setPos(-10, #currentMenu.Actions+1)
        :setScale(1,1,1)
        :setBackgroundColor(0,0,0,0.24705)
        :setVisible(false),
        Text = name,
        Symbol = nil,
        OnSelect = onSelect,
        Parent = parent or nil,
        IsSubAction = isSubAction or false
    }
    table.insert(currentMenu.Actions, self)
    setmetatable(self, ActionTask)
    return self 
end

---Sets the symbol for the task.
---@param symbol string|Texture The symbol that will be used for the task, this can be an emoji or texture, but it will appear right before the task.
function ActionTask:setSymbol (symbol)
    addSymbol(symbol, self)
end

---A new task that can be considered a toggle, just like aciton pages.
---@class ToggleTask
---@field Task TextTask
---@field Text string
---@field Symbol SpriteTask|string
---@field OnToggle function
local ToggleTask = {}
ToggleTask.__index = ToggleTask

---Creates a new toggle task.
---@param name string The name of the task, this will also be used as the label.
---@param onToggle function The function that will be executed when the task is selected.
---@param override string? A override for when creating a task to set it's class suffix to something different.
---@param isSubAction boolean? If this task is a sub action or not.
---@param parent string? The parent of this task, used in subaction related functions.
function ToggleTask.new (name, onToggle, override, isSubAction, parent)
    local self = {
        Task = folioRenderPart:newText(override ~= nil and override or "folio.Action."..name)
        :setText(toJson({{text=name, color="grey"},{text=" ■", color = "red"}}))
        :setPos(-10,#currentMenu.Actions+1)
        :setScale(1,1,1)
        :setBackgroundColor(0,0,0,0.24705)
        :setVisible(false),
        Text = name,
        Symbol = nil,
        OnToggle = onToggle,
        Parent = parent or nil,
        IsSubAction = isSubAction or false
    }
    table.insert(currentMenu.Actions, self)
    setmetatable(self, ToggleTask)
    return self
end

--Sets the symbol for the task.
---@param symbol string|Texture The symbol that will be used for the task, this can be an emoji or texture, but it will appear right before the task.
function ToggleTask:setSymbol (symbol)
    addSymbol(symbol, self)
end

---A new task that can be considered a category, when selected it'll expand it's child tasks to be visible.
---@class CategoryTask
---@field Task TextTask
---@field Text string
---@field Symbol SpriteTask|string
---@field Expand function
local CategoryTask = {}
CategoryTask.__index = CategoryTask

---Creates a new category, where actions can be parented to it after.
---@param categoryName string The name of the category, this will also be used as the label for the expansion menu.
function CategoryTask.new(categoryName)
    local self = {
        Task = folioRenderPart:newText("folio.Action."..categoryName)
        :setText(categoryName)
        :setPos(-10,#currentMenu.Actions+1)
        :setScale(1,1,1)
        :setBackgroundColor(0,0,0,0.24705)
        :setVisible(false),
        Text = categoryName,
        Symbol = nil,
        Expand = categoryName,
    }
    table.insert(currentMenu.Actions, self)
    setmetatable(self, CategoryTask)
    return self
end

--Sets the symbol for the action task.
---@param symbol string|Texture The symbol that will be used for the task, this can be an emoji or texture, but it will appear right before the task.
function CategoryTask:setSymbol (symbol)
    addSymbol(symbol, self)
end

---@param name string The name of the task, this will also be used as the label.
---@param onSelect function The function that will be executed when the task is selected.
---@return ActionTask
function CategoryTask:newAction (name, onSelect)
    return (ActionTask.new(name, onSelect, "folio."..self.Text..".SubAction."..name, true, self.Text))
end

---@param name string The name of the task, this will also be used as the label.
---@param onToggle fun(state: boolean) The function that which on toggle will be executed when the task is selected.
---@return ToggleTask   
function CategoryTask:newToggle (name, onToggle)
    return (ToggleTask.new(name, onToggle, "folio."..self.Text..".SubToggle."..name, true, self.Text))
end

--#endregion Class Registration

--#region Folio Access Functions

---Creates a new action task for the dropdown menu.
---@param name string The name that will be used for the action, and that will be used as the label for the action.
---@param onSelect function The function that will be executed when the task is selected.
---@return ActionTask
folio.newAction = function (name, onSelect)
    return (ActionTask.new(name,onSelect))
end

---Creates a new toggle task for the dropdown menu, when using it the state will be parsed through the function.
---@param name string The name that will be used for the action, and that will be used as the label for the action.
---@param onToggle fun(state: boolean) The function that which on toggle will be executed when the task is selected.
---@return ToggleTask
folio.newToggle = function (name, onToggle)
    return (ToggleTask.new(name, onToggle))    
end

---Creates a new category that you can add toggle tasks/actions too, this will be expanded/compacted when selected.
---@param categoryName string The name that will be used for the category for the drop down menu.
---@return CategoryTask
folio.newCategory = function (categoryName)
    return (CategoryTask.new(categoryName))
end

---Sets the title for the Folio menu.
---@param title string
folio.setTitle = function (title)
    currentMenu.Title:setText(title)
end
--#endregion Folio Access Functions

--#region Folio Internal Functions

---Clears all events inside of the folioRegistars table, causing them to stop.
local function removeRegistarEvents ()
    for _, ev in pairs(folioRegistars) do
        ev:clear()
    end
    --- just flushing the cache that's why
    folioRegistars = {}
end

---Gets all the Folio objects inside of the FolioRenderPart
local function getFolioObjects ()
    local ret = {}
    for _, v in pairs(folioRenderPart:getTask()) do
        if v:getName():find("folio") then
            table.insert(ret, v)
        end
    end
    return ret
end

---Correctly realigns every folio action/toggle task into its proper position, mainlyused for subactions.
local function reAlignTasks()
    local sub = 1 -- offset correciton, btw
    for i, action in ipairs(currentMenu.Actions) do        
        if action.IsSubAction then
            if (expandTrack[action.Parent] == true) then
                action.Task:setPos(-18,(-7+(-10*(i-sub))))
                if (type(action.Symbol) == "SpriteTask") and (action.Symbol) then
                    action.Symbol:setPos(-18,(-7+(-10*(i-sub))), -2)
                end
            else
                sub = sub+1
            end
        else
            action.Task:setPos(-10,(-7+(-10*(i-sub))))
            if (type(action.Symbol) == "SpriteTask") and (action.Symbol) then
                action.Symbol:setPos(-10,(-7+(-10*(i-sub))), -2)
            end
        end
    end
end

--- i'm not writing docs for this dude this is an internal function
--- and is what it is
local function quadInOut(t)
    if t < 0.5 then
        return 2 * t * t
    else
        return -1 + (4 - 2 * t) * t
    end
end

local tweenLib = nil
for _, k in pairs(listFiles(nil, true)) do
    if (k:find("tween")) then
        tweenLib = require(k)
        break
    end
end

local firstSwap = false

---Tweens the cursor to it's next position
---@param position number The position in the action menu the cursor should tween to.
---@param noTween boolean Wether the cursor should tween to the position or not.
local function cursorMove (position, noTween)
    local curAction = currentMenu.Actions[position].Task
    local elapsed = 0
    if not (noTween) then
        if tweenLib == nil then
            --- FALLBACK
            local actionPos = curAction:getPos() + vec(4,0,0)
            local time = 0.65
            local old, new, target = currentMenu.Cursor:getPos(), currentMenu.Cursor:getPos(), actionPos
            function events.tick()
                old = new
                new = math.lerp(old, target, quadInOut(time))
            end

            function events.render(delta)
                local lerped = math.lerp(old, new, delta)
                currentMenu.Cursor:setPos(lerped)
            end
        else
            --- TWEEN-LIB | because i used it so yeah
            tweenLib.new(
                {
                    from = currentMenu.Cursor:getPos(),
                    to = curAction:getPos() + vec(4,0,0),
                    duration = 0.10,
                    easing = "inOutQuad",
                    tick = function (vec)
                        currentMenu.Cursor:setPos(vec)
                    end
                }
            )
        end
    else
        if not (firstSwap) then
            firstSwap = not firstSwap
            currentMenu.Cursor:setPos(-6,-6)
        else
            currentMenu.Cursor:setPos(
                curAction:getPos().x + 4,
                curAction:getPos().y - 0
            )
        end
    end
end

---Corrects the scroll for devices with low scroll decimals.
---@param val number The number that will be clamped.
local function scrollCorrect (val)
    return (math.clamp( (math.floor(val <= -0 and -1 or val >= 1 and 1 or 1)), -1, 1))
end

---Creates the scroll event used for scrolling in the menu.
local function makeFolioScrollEvent ()
    local e = events.MOUSE_SCROLL:register(function (dir)
        local availIndex = {}
        --- to those judging my code yes i know its unconventinal
        --- but it works really well LOL
        for i, action in ipairs (currentMenu.Actions) do
            local parentType = action.Task:getName():match("^folio%.([^.]+)%.")
            if (parentType ~= "Action" and parentType ~= "Toggle") then
                if (expandTrack[parentType] == true) then
                    table.insert(availIndex, tostring(i))
                end
            else
                table.insert(availIndex, tostring(i))
            end
        end

        if (inWheel) then
            pos = math.clamp(pos+-scrollCorrect(dir), 1, #availIndex)
            cursorMove(
                tonumber(availIndex[pos]),
                false
            )
        end
        return true
    end, "folioScroll")
    table.insert(folioRegistars, e)
end

local function closeMenu ()
    removeRegistarEvents()
    for _, render in pairs(getFolioObjects()) do
        render:setVisible(false)
    end
    for k,_ in pairs(expandTrack) do
        expandTrack[k] = false
    end
    pos=1
    inWheel=false
end

local function expandAction (name)
    if not (expandTrack[name]) then expandTrack[name] = false end
    expandTrack[name] = not expandTrack[name]

    for _, action in pairs(currentMenu.Actions) do
        if (action.Parent ~= nil and action.Parent == name and action.IsSubAction) then
            action.Task:setVisible(expandTrack[name])
            if (type(action.Symbol) == "SpriteTask") then action.Symbol:setVisible(expandTrack[name]) end
        end
    end

    reAlignTasks()
end

local function makeFolioMouseEvent ()
    local e = events.MOUSE_PRESS:register(function (button,status,modifier)
        local availIndex = {}
        for i, action in ipairs (currentMenu.Actions) do
            if (expandTrack[action.Parent] == true and action.IsSubAction) then
                if (expandTrack[action.Parent] == true) then
                    table.insert(availIndex, tostring(i))
                end
            elseif not (action.IsSubAction) then
                table.insert(availIndex, tostring(i))
            end
        end

        if (button == 1 and status == 1) and (currentMenu.Actions ~= {}) then
            local currentAction = currentMenu.Actions[tonumber(availIndex[pos])]
            if (currentAction.OnSelect) then currentAction.OnSelect() closeMenu() forceClosed = true end
            if (currentAction.Expand) then expandAction(currentAction.Text) end
            if (currentAction.OnToggle) then
                local taskName = currentAction.Task:getName():match("^[^.]+%.[^.]+%.([^.]+)$") or currentAction.Task:getName():match("^[^.]+")
                if not (toggleTrack[taskName]) then toggleTrack[taskName] = false end
                toggleTrack[taskName] = not toggleTrack[taskName]
                local symbol = type(currentAction.Symbol) == "string" and currentAction.Symbol.." " or type(currentAction.Symbol) == "SpriteTask" and "   " or ""
                currentAction.Task:setText(
                toJson(
                {
                    {text= symbol ~= false and symbol..""..currentAction.Text},
                    {text = " ■", color=toggleTrack[taskName] and "green" or not toggleTrack[taskName] and "red"}
                    }
                    )
                )
                currentAction.OnToggle(toggleTrack[taskName])
            end
        end
    end, "folioClick")
    table.insert(folioRegistars, e)
end

--#endregion Folio Internal Functions

if host:isHost() then
    events.KEY_PRESS:register(function (key,status)
        if (key == keybinds:fromVanilla("figura.config.action_wheel_button"):getID() and not host:isChatOpen()) then
            if (status == 0) then
                pos=1
                removeRegistarEvents()
                closeMenu()
                forceClosed = false
            elseif (not inWheel) and (forceClosed == false) then
                inWheel = true
                local folioObjects = getFolioObjects()
                --[[for _, render in pairs(folioObjects) do
                    if not (render:getName():find("SubAction") or render:getName():find("SubToggle") or render:getName():find("Symbol")) then
                        render:setVisible(true)
                    end
                end]]
                currentMenu.Title:setVisible(true)
                currentMenu.Cursor:setVisible(true)
                for _, render in pairs(currentMenu.Actions) do
                    if not (render.IsSubAction) then
                        render.Task:setVisible(true)
                        if (type(render.Symbol) == "SpriteTask") then
                            render.Symbol:setVisible(true)
                        end
                    end
                end
                
                cursorMove(1, true)
                makeFolioScrollEvent()
                makeFolioMouseEvent()
                reAlignTasks()
            end

            return true
        end
    end, "folioPagesKeyPress")
end 

return folio