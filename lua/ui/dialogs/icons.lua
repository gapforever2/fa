local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Group = import("/lua/maui/group.lua").Group
local Popup = import("/lua/ui/controls/popups/popup.lua").Popup
local TextArea = import("/lua/ui/controls/textarea.lua").TextArea

local dialog = false
local selectedIcon = nil
local iconTexture = "/textures/ui/common/unknown.dds"


local originalTextures = {}
local isLow = false;

local function CopyFile(fromPath, toPath)
  local success = false
  local file = nil

    if type(FileSystem) == 'table' then
        file = FileSystem.Open(fromPath, 'rb')
    elseif type(Open) == 'function' then
      file = Open(fromPath, 'rb')
    end
  

  if file then
      local contents = file:Read()
      local writeFile = nil;
      if type(FileSystem) == 'table' then
        writeFile = FileSystem.Open(toPath, 'wb')
      elseif type(Open) == 'function' then 
        writeFile = Open(toPath, 'wb')
      end


      if writeFile then
          writeFile:Write(contents)
          writeFile:Close()
          success = true
      end
      file:Close()
  end
  return success
end


function SetIconTexture(texturePath)
    iconTexture = texturePath;
    WARN("NEW TEXTURE " .. texturePath)
    -- Здесь будет код для замены текстуры, например:
    --  if CurrentGameObject and CurrentGameObject.SetMyTexture then
    --    CurrentGameObject:SetMyTexture(iconTexture)
    --  end
end

local function SwitchIcons()
    isLow = not isLow;
	local sourceDir = "textures\\ui\\common\\game\\strategicicons";
	local targetDir = "textures\\ui\\common\\game\\strategicicons2";
	if (isLow) then
		for i = 1, 12 do
            local filename = 'strategicicon'..i..'.dds';
			if (CopyFile(targetDir ..'\\'.. filename, sourceDir ..'\\'.. filename)) then
				WARN('Copied from '.. targetDir ..'\\'.. filename .. ' to '.. sourceDir ..'\\'.. filename);
			else
				WARN('Failed to copy from '.. targetDir ..'\\'.. filename .. ' to '.. sourceDir ..'\\'.. filename);
			end;

        end
	else
		for i = 1, 12 do
            local filename = 'strategicicon'..i..'.dds';
		    if (CopyFile(targetDir ..'\\'.. filename, sourceDir ..'\\'.. filename)) then
				WARN('Copied from '.. sourceDir ..'\\'.. filename .. ' to '.. targetDir ..'\\'.. filename);
			else
				WARN('Failed to copy from '.. sourceDir ..'\\'.. filename .. ' to '.. targetDir ..'\\'.. filename);
			end;
        end
	end
    -- Если требуется обновить текстуры в самой игре, используйте методы API вашей игры, например:
    --  if CurrentGameObject and CurrentGameObject.UpdateTextures then
    --      CurrentGameObject:UpdateTextures()
    --  end
end

local function RestoreOriginalIcons()
    isLow = false;
	local sourceDir = "textures\\ui\\common\\game\\strategicicons";
	local targetDir = "textures\\ui\\common\\game\\strategicicons2";

		for i = 1, 12 do
            local filename = 'strategicicon'..i..'.dds';
		    if (CopyFile(targetDir ..'\\'.. filename, sourceDir ..'\\'.. filename)) then
				WARN('Copied from '.. targetDir ..'\\'.. filename .. ' to '.. sourceDir ..'\\'.. filename);
			else
				WARN('Failed to copy from '.. targetDir ..'\\'.. filename .. ' to '.. sourceDir ..'\\'.. filename);
			end;
        end
	--  if CurrentGameObject and CurrentGameObject.UpdateTextures then
    --      CurrentGameObject:UpdateTextures()
    --  end
end

function CreateDialog()
    if dialog then
        return
    end

    local dialogContent = Group(GetFrame(0))
    LayoutHelpers.SetDimensions(dialogContent, 360, 200)

    dialog = Popup(GetFrame(0), dialogContent)

    local title = UIUtil.CreateText(dialogContent, "<LOC icons_0001>Advanced strategic icons", 14, UIUtil.titleFont)
    LayoutHelpers.AtTopIn(title, dialogContent, 10)
    LayoutHelpers.AtHorizontalCenterIn(title, dialogContent)

    --local infoText = TextArea(dialogContent, 340, 80)
    --infoText:SetText(LOC("<LOC icons_0002>Icons for leveling."))
    --LayoutHelpers.Below(infoText, title)
    --LayoutHelpers.AtLeftIn(infoText, dialogContent, 10)

    
    local lowBtn = UIUtil.CreateButtonWithDropshadow(dialogContent, '/BUTTON/medium/', "<LOC icons_0003>Small Icon")
    LayoutHelpers.SetDimensions(lowBtn, 100, 50)
    lowBtn.Left:Set(800)
    lowBtn.Top:Set(450)
    WARN("lowBtn: Left = " .. tostring(lowBtn.Left()) .. ", Top = " .. tostring(lowBtn.Top()))

    lowBtn.OnClick = function(self, modifiers)
        SwitchIcons()
        KillThread(dialog.countdownThread)
        dialog:Close()
    end
	
	local MediumBtn = UIUtil.CreateButtonWithDropshadow(dialogContent, '/BUTTON/medium/', "<LOC icons_0003>Medium Icon")
    LayoutHelpers.SetDimensions(MediumBtn, 100, 50)
    MediumBtn.Left:Set(800)
    MediumBtn.Top:Set(500)
    WARN("MediumBtn: Left = " .. tostring(MediumBtn.Left()) .. ", Top = " .. tostring(MediumBtn.Top()))

    MediumBtn.OnClick = function(self, modifiers)
        KillThread(dialog.countdownThread)
        dialog:Close()
    end

    local HighBtn = UIUtil.CreateButtonWithDropshadow(dialogContent, '/BUTTON/medium/', "<LOC icons_0003>Large Icon")
    LayoutHelpers.SetDimensions(HighBtn, 100, 50)
     HighBtn.Left:Set(800)
     HighBtn.Top:Set(550)
     WARN("HighBtn: Left = " .. tostring(HighBtn.Left()) .. ", Top = " .. tostring(HighBtn.Top()))

    HighBtn.OnClick = function(self, modifiers)
        if selectedIcon then
            SetIconTexture(selectedIcon)
        end
        KillThread(dialog.countdownThread)
        dialog:Close()
    end


    local reportBtn = UIUtil.CreateButtonWithDropshadow(dialogContent, '/BUTTON/medium/', "<LOC icons_0004>Exit")
    LayoutHelpers.SetDimensions(reportBtn, 100, 50)
     reportBtn.Left:Set(1000)
    reportBtn.Top:Set(550)
     WARN("reportBtn: Left = " .. tostring(reportBtn.Left()) .. ", Top = " .. tostring(reportBtn.Top()))

    UIUtil.setEnabled(reportBtn, true)
    reportBtn.OnClick = function(self, modifiers)
        KillThread(dialog.countdownThread)
        dialog:Close()
    end


    dialog.OnClosed = function(self)
        dialog = false
    end

    dialog.OnEscapePressed = function(self)
    end

    dialog.OnShadowClicked = function(self)
    end
    
    dialog.dialog:Close()
end