local AcceptOnes = "false";
local AcceptRolls = "false";
local AcceptLoserAmount = "false";
local totalrolls = 0
local tierolls = 0;
local theMax
local lowname = ""
local highname = ""
local low = 0
local high = 0
local tie = 0
local highbreak = 0;
local lowbreak = 0;
local tiehigh = 0;
local tielow = 0;
local chatmethod = "RAID";
local whispermethod = false;
local totalentries = 0;
local highplayername = "";
local lowplayername = "";
local rollCmd = SLASH_RANDOM1:upper();


-- LOAD FUNCTION --
function WanderersGambling_OnLoad(self)
	DEFAULT_CHAT_FRAME:AddMessage("|cffffff00<Bronze's Gambling, v.420.69!> /gamble to use");

	self:RegisterEvent("CHAT_MSG_RAID");
	self:RegisterEvent("CHAT_MSG_RAID_LEADER");
	self:RegisterEvent("CHAT_MSG_GUILD");
	self:RegisterEvent("CHAT_MSG_SYSTEM");
	self:RegisterEvent("PLAYER_ENTERING_WORLD");
	self:RegisterForDrag("LeftButton");

	WanderersGambling_ROLL_Button:Disable();
	WanderersGambling_AcceptOnes_Button:Enable();		
	WanderersGambling_LASTCALL_Button:Disable();
	WanderersGambling_CHAT_Button:Enable();
end

local EventFrame=CreateFrame("Frame");
EventFrame:RegisterEvent("CHAT_MSG_WHISPER");-- Need to register an event to receive it
EventFrame:SetScript("OnEvent",function(self,event,msg,sender)
    if msg:lower():find("!stats") then--    We're making sure the command is case insensitive by casting it to lowercase before running a pattern check
        --SendChatMessage("Work in Progress","WHISPER",nil,sender);
		WanderersGambling_MessageStats(sender);
    end
end);

local function Print(pre, red, text)
	if red == "" then red = "/gamble" end
	DEFAULT_CHAT_FRAME:AddMessage(pre..GREEN_FONT_COLOR_CODE..red..FONT_COLOR_CODE_CLOSE..": "..text)
end

local function DebugMsg(level, text)
  if debugLevel < level then return end
  Print("","",GRAY_FONT_COLOR_CODE..date("%H:%M:%S")..RED_FONT_COLOR_CODE.." DEBUG: "..FONT_COLOR_CODE_CLOSE..text)
end

function WanderersGambling_MessageStats(sender)
	local n = 0;
	local sortlistname = {};
	local sortlistamount = {};

	local stats = WanderersGambling["stats"][WanderersGambling["UUID"]] or {};
	local compiledStats = {};
	local total = 0;
	local house = 0;
	local nameOnly = strsplit("-", sender);
	for i, j in pairs(stats) do
		if (j[1]:gsub("^%l", string.upper) == nameOnly:gsub("^%l", string.upper)) then
			total = total + j[3];
			compiledStats[j[2]:gsub("^%l", string.upper)] = (compiledStats[j[2]:gsub("^%l", string.upper)] or 0) + j[3];
		elseif (j[2]:gsub("^%l", string.upper) == nameOnly:gsub("^%l", string.upper)) then
			compiledStats[j[1]:gsub("^%l", string.upper)] = (compiledStats[j[1]:gsub("^%l", string.upper)] or 0) - j[3];
			total = total - j[3];
			house = house + j[4];
		end
	end

	n, sortlistname, sortlistamount = WanderersGambling_SortAndMergeStats(compiledStats);
	
	local sortsign = "";
	for i = 0, n - 1 do
		sortsign = "gave you";
		if(sortlistamount[i] < 0) then sortsign = "took"; end
		SendChatMessage(string.format("%s.  %s %s %s total", BreakUpLargeNumbers(i+1), sortlistname[i], sortsign, BreakUpLargeNumbers(math.abs(sortlistamount[i]))), "WHISPER", nil, sender);
	end

	if (total ~= 0) then
		sortsign = "won";
		if(total < 0) then sortsign = "lost" end
		SendChatMessage(string.format("You have %s %s total.", sortsign, BreakUpLargeNumbers(total)), "WHISPER", nil, sender);
	end
	
	if (house > 0) then
		SendChatMessage(string.format("You have paid the house %s total.", BreakUpLargeNumbers(house)), "WHISPER", nil, sender);
	end
end

function WanderersGambling_CheckUUID()
	if (not WanderersGambling["UUID"]) then
		WanderersGambling_setUUID();
	end
end

function WanderersGambling_setUUID()
	WanderersGambling["UUID"] = WanderersGambling_CreateUUID();
end

function WanderersGambling_SlashCmd(msg)
	local msg = msg:lower();
	local msgPrint = 0;
	if (msg == "" or msg == nil) then
	    Print("", "", "~Following commands for WanderersGambling~");
		Print("", "", "show - Shows the frame");
		Print("", "", "hide - Hides the frame");
		Print("", "", "reset - Resets the AddOn");
		Print("", "", "resetstats - Resets the stats");
		Print("", "", "joinstats [main] [alt] - Apply [alt]'s win/losses to [main]");
		Print("", "", "unjoinstats [alt] - Unjoin [alt]'s win/losses from whomever it was joined to");
		Print("", "", "ban - Ban's the user from being able to roll");
		Print("", "", "unban - Unban's the user");
		Print("", "", "listban - Shows ban list");
		Print("", "", "stats - Show win/loss stats");
		Print("", "", "house - Toggles guild house cut");
		Print("", "", "house [percent] - Sets the house cut to [percentage]. [percentage] must be a value between 0 and 1. 0.10 would be a 10% cut.");
		Print("", "", "loser - Toggles ability for loser to set next amount.");
		msgPrint = 1;
	end
	if (msg == "hide") then
		WanderersGambling_Frame:Hide();
		WanderersGambling["active"] = 0;
		msgPrint = 1;
	end
	if (msg == "show") then
		WanderersGambling_Frame:Show();
		WanderersGambling["active"] = 1;
		msgPrint = 1;
	end
	if (msg == "reset") then
		Print("", "", "|cffffff00GCG has now been reset");
		WanderersGambling_Reset();
		WanderersGambling_AcceptOnes_Button:SetText("Open Entry");
		msgPrint = 1;		
	end
	if (msg == "resetstats") then
		Print("", "", "|cffffff00GCG stats have now been reset");
		WanderersGambling_ResetStats();
		msgPrint = 1;
	end
	if (string.sub(msg, 1, 9) == "joinstats") then
		WanderersGambling_JoinStats(strsub(msg, 11));
		msgPrint = 1;
	end
	if (string.sub(msg, 1, 11) == "unjoinstats") then
		WanderersGambling_UnjoinStats(strsub(msg, 13));
		msgPrint = 1;
	end

	if (string.sub(msg, 1, 3) == "ban") then
		WanderersGambling_AddBan(strsub(msg, 5));
		msgPrint = 1;
	end

	if (string.sub(msg, 1, 5) == "unban") then
		WanderersGambling_RemoveBan(strsub(msg, 7));
		msgPrint = 1;
	end

	if (string.sub(msg, 1, 7) == "listban") then
		WanderersGambling_ListBan();
		msgPrint = 1;
	end
	if (string.sub(msg, 1, 5) == "loser") then
		WanderersGambling_ToggleLoser();
		msgPrint = 1;
	end
	if (string.sub(msg, 1, 5) == "house") then
		WanderersGambling_ToggleHouse(strsub(msg, 7));
		msgPrint = 1;
	end
	if (string.sub(msg, 1, 4) == "stat") then
		WanderersGambling_OnClickSTATS();
		msgPrint = 1;
	end
	if (msgPrint == 0) then
		Print("", "", "|cffffff00Invalid argument for command /gamble");
	end
end

SLASH_WanderersGambling1 = "/Gamble";
SLASH_WanderersGambling2 = "/gamble";
SlashCmdList["WanderersGambling"] = WanderersGambling_SlashCmd

function WanderersGambling_OnEvent(self, event, ...)

	-- LOADS ALL DATA FOR INITIALIZATION OF ADDON --
	arg1,arg2 = ...;
	if (event == "PLAYER_ENTERING_WORLD") then
		WanderersGambling_EditBox:SetJustifyH("CENTER");

		if(not WanderersGambling) then
			WanderersGambling = {
				["active"] = 1, 
				["chat"] = false, 
				["whispers"] = false, 
				["strings"] = { },
				["lowtie"] = { },
				["hightie"] = { },
				["bans"] = { },
				["guildCutPercentage"] = 0.1
			}
		end
		
		if(not WanderersGambling["house"]) then WanderersGambling["house"] = 0; end
		if(not WanderersGambling["lastroll"]) then WanderersGambling["lastroll"] = 100; end
		if(not WanderersGambling["stats"]) then WanderersGambling["stats"] = { }; end
		if(not WanderersGambling["joinstats"]) then WanderersGambling["joinstats"] = { }; end
		if(not WanderersGambling["chat"]) then WanderersGambling["chat"] = false; end
		if(not WanderersGambling["whispers"]) then WanderersGambling["whispers"] = false; end
		if(not WanderersGambling["bans"]) then WanderersGambling["bans"] = { }; end
		if(not WanderersGambling["isHouseCut"]) then WanderersGambling["isHouseCut"] = 1; end
		if(not WanderersGambling["loser"]) then WanderersGambling["loser"] = 1; end
		if(not WanderersGambling["guildCutPercentage"]) then WanderersGambling["guildCutPercentage"] = 0.1; end
		WanderersGambling_CheckUUID();

		WanderersGambling_EditBox:SetText(""..WanderersGambling["lastroll"]);

		if(WanderersGambling["chat"] == false) then
			WanderersGambling_CHAT_Button:SetText("(Guild)");
			chatmethod = "GUILD";
		elseif(WanderersGambling["chat"] == true) then
			WanderersGambling_CHAT_Button:SetText("(Raid)");
			chatmethod = "RAID";
		end
		
		if(WanderersGambling["whispers"] == false) then

			whispermethod = false;
		else
			WanderersGambling_WHISPER_Button:SetText("(Whispers)");
			whispermethod = true;
		end

		if(WanderersGambling["active"] == 1) then
			WanderersGambling_Frame:Show();
		else
			WanderersGambling_Frame:Hide();
		end
	end


	-- IF IT'S A RAID MESSAGE... --
	if ((event == "CHAT_MSG_RAID" or event == "CHAT_MSG_RAID_LEADER" and WanderersGambling["chat"] == true) or (event == "CHAT_MSG_GUILD" and WanderersGambling["chat"] == false)) then
		if(AcceptOnes=="true") then
			-- ADDS USER TO THE ROLL POOL - CHECK TO MAKE SURE THEY ARE NOT BANNED --
			if (arg1 == "1") then
				if(WanderersGambling_ChkBan(tostring(arg2)) == 0) then
					WanderersGambling_Add(tostring(arg2));
					if (not WanderersGambling_LASTCALL_Button:IsEnabled() and totalrolls == 1) then
						WanderersGambling_LASTCALL_Button:Enable();
					end
					if totalrolls == 2 then
						WanderersGambling_AcceptOnes_Button:Disable();
						WanderersGambling_AcceptOnes_Button:SetText("Open Entry");
					end
				else
					SendChatMessage("Sorry, but you're banned from the game!", chatmethod);
				end
			elseif(arg1 == "-1") then
				WanderersGambling_Remove(tostring(arg2));
				if (WanderersGambling_LASTCALL_Button:IsEnabled() and totalrolls == 0) then
					WanderersGambling_LASTCALL_Button:Disable();
				end
				if totalrolls == 1 then
					WanderersGambling_AcceptOnes_Button:Enable();
					WanderersGambling_AcceptOnes_Button:SetText("Open Entry");
				end
			end
		elseif (AcceptLoserAmount ~= "false") then --AcceptLoserAmount is set to player that just lost
			charname, realmname = strsplit("-", tostring(arg2));
			if (charname:gsub("^%l", string.upper) == AcceptLoserAmount) then
				key, amount = strsplit(" ", arg1);
				if (key == "!amount" and tonumber(amount)) then
					WanderersGambling_EditBox:SetText(tonumber(amount));
					WanderersGambling["lastroll"] = tonumber(amount);
					SendChatMessage(string.format("%s set next gamble amount to %s.", AcceptLoserAmount, BreakUpLargeNumbers(tonumber(amount))), chatmethod);
					AcceptLoserAmount = "false";
				end
			end
		end
	end

	if (event == "CHAT_MSG_SYSTEM" and AcceptRolls=="true") then
		local temp1 = tostring(arg1);
		WanderersGambling_ParseRoll(temp1);		
	end	
end


function WanderersGambling_ResetStats()
	WanderersGambling["stats"] = { };
	WanderersGambling["house"] = 0;
end

function WanderersGambling_ToggleLoser()
	if (WanderersGambling["loser"] == 1) then
		WanderersGambling["loser"] = 0
		Print("", "", "|cffffff00Loser is no longer able to set next gamble amount.");
	else
		WanderersGambling["loser"] = 1
		Print("", "", "|cffffff00Loser can now set next gamble amount.");		
	end
end

function WanderersGambling_ToggleHouse(percent)
	if ((not percent) or percent == -1 or string.len(percent) == 0) then
		if (WanderersGambling["isHouseCut"] == 1) then
			WanderersGambling["isHouseCut"] = 0
			Print("", "", "|cffffff00Guildbank house cut has been turned off.");
		else
			WanderersGambling["isHouseCut"] = 1
			Print("", "", "|cffffff00Guildbank house cut has been turned on.");		
		end
		return
	elseif (tonumber(percent) > 0 and tonumber(percent) < 1) then
		WanderersGambling["guildCutPercentage"] = tonumber(percent);
		Print("", "", string.format("|cffffff00House cut has been set to %02d%%", WanderersGambling["guildCutPercentage"] * 100));
	else
		Print("", "", "house - Toggles guild house cut");
		Print("", "", "house [percent] - Sets the house cut to [percentage]. [percentage] must be a value between 0 and 1. 0.10 would be a 10% cut.");
	end
end

function WanderersGambling_OnClickCHAT()
	if(WanderersGambling["chat"] == nil) then WanderersGambling["chat"] = false; end

	WanderersGambling["chat"] = not WanderersGambling["chat"];
	
	if(WanderersGambling["chat"] == false) then
		WanderersGambling_CHAT_Button:SetText("(Guild)");
		chatmethod = "GUILD";
	else
		WanderersGambling_CHAT_Button:SetText("(Raid)");
		chatmethod = "RAID";
	end
end

function WanderersGambling_OnClickWHISPERS()
	if(WanderersGambling["whispers"] == nil) then WanderersGambling["whispers"] = false; end

	WanderersGambling["whispers"] = not WanderersGambling["whispers"];
	
	if(WanderersGambling["whispers"] == false) then
		WanderersGambling_WHISPER_Button:SetText("(No Whispers)");
		whispermethod = false;
	else
		WanderersGambling_WHISPER_Button:SetText("(Whispers)");
		whispermethod = true;
	end
end

function WanderersGambling_JoinStats(msg)
	local i = string.find(msg, " ");
	if((not i) or i == -1 or string.find(msg, "[", 1, true) or string.find(msg, "]", 1, true)) then
		ChatFrame1:AddMessage("");
		return;
	end
	local mainname = string.sub(msg, 1, i-1);
	local altname = string.sub(msg, i+1);
	ChatFrame1:AddMessage(string.format("Joined alt '%s' -> main '%s'", altname, mainname));
	WanderersGambling["joinstats"][altname] = mainname;
end

function WanderersGambling_UnjoinStats(altname)
	if(altname ~= nil and altname ~= "") then
		ChatFrame1:AddMessage(string.format("Unjoined alt '%s' from any other characters", altname));
		WanderersGambling["joinstats"][altname] = nil;
	else
		local i, e;
		for i, e in pairs(WanderersGambling["joinstats"]) do
			ChatFrame1:AddMessage(string.format("currently joined: alt '%s' -> main '%s'", i, e));
		end
	end
end

function WanderersGambling_HideWindow()
	WanderersGambling_Frame:Hide();
	WanderersGambling["active"] = 0;
end

function WanderersGambling_SortAndMergeStats(stats)
	local n = 0;
	local i, j, k;
	local sortlistname = {};
	local sortlistamount = {};
	
	for i, j in pairs(stats) do
		local name = i;
		if(WanderersGambling["joinstats"][strlower(i)] ~= nil) then
			name = WanderersGambling["joinstats"][strlower(i)]:gsub("^%l", string.upper);
		end
		for k=0,n do
			if(k == n) then
				sortlistname[n] = name;
				sortlistamount[n] = j;
				n = n + 1;
				break;
			elseif(strlower(name) == strlower(sortlistname[k])) then
				sortlistamount[k] = (sortlistamount[k] or 0) + j;
				break;
			end
		end
	end
	
	for i = 0, n-1 do
		for j = i+1, n-1 do
			if(sortlistamount[j] > sortlistamount[i]) then
				sortlistamount[i], sortlistamount[j] = sortlistamount[j], sortlistamount[i];
				sortlistname[i], sortlistname[j] = sortlistname[j], sortlistname[i];
			end
		end
	end
	
	return n, sortlistname, sortlistamount;
end

function WanderersGambling_OnClickSTATS()
	local sortlistname = {};
	local sortlistamount = {};
	local n = 0;

	local length = WanderersGambling_TableLength(WanderersGambling["stats"]);

	local compiledStats = {};
	if (length > 0) then
		for i, j in pairs(WanderersGambling["stats"][WanderersGambling["UUID"]]) do
			compiledStats[j[1]:gsub("^%l", string.upper)] = (compiledStats[j[1]:gsub("^%l", string.upper)] or 0) + j[3];
			compiledStats[j[2]:gsub("^%l", string.upper)] = (compiledStats[j[2]:gsub("^%l", string.upper)] or 0) - j[3];
		end
	end

	n, sortlistname, sortlistamount = WanderersGambling_SortAndMergeStats(compiledStats);

	if(n == 0) then
		DEFAULT_CHAT_FRAME:AddMessage("No stats yet!");
		return;
	end

	DEFAULT_CHAT_FRAME:AddMessage("--- WanderersGambling Stats ---", chatmethod);

	for i = 0, n - 1 do
		sortsign = "won";
		if(sortlistamount[i] < 0) then sortsign = "lost"; end
		SendChatMessage(string.format("%d.  %s %s %s total.", i+1, sortlistname[i], sortsign, BreakUpLargeNumbers(math.abs(sortlistamount[i]))), chatmethod);
	end
	
	if (WanderersGambling["house"] > 0) then
		SendChatMessage(string.format("The house has taken %s total.", BreakUpLargeNumbers(WanderersGambling["house"])), chatmethod);
	end
end


function WanderersGambling_OnClickROLL()
	if (totalrolls > 0 and AcceptRolls == "true") then
		if table.getn(WanderersGambling.strings) ~= 0 then
			WanderersGambling_List();
		end	
		return;
	end
	if (totalrolls >1) then
		AcceptOnes = "false";
		AcceptRolls = "true";
		if (tie == 0) then
			SendChatMessage("Roll now!",chatmethod,GetDefaultLanguage("player"));
		end

		if (lowbreak == 1) then
			SendChatMessage(format("%s%d%s", "Low end tiebreaker! Roll 1-", theMax, " now!"),chatmethod,GetDefaultLanguage("player"));
			WanderersGambling_List();
		end

		if (highbreak == 1) then
			SendChatMessage(format("%s%d%s", "High end tiebreaker! Roll 1-", theMax, " now!"),chatmethod,GetDefaultLanguage("player"));
			WanderersGambling_List();
		end

		WanderersGambling_EditBox:ClearFocus();

	end

	if (AcceptOnes == "true" and totalrolls <1) then
		SendChatMessage("Not enough Players!",chatmethod,GetDefaultLanguage("player"));
	end
end

function WanderersGambling_TableLength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

function WanderersGambling_OnClickLASTCALL()
	SendChatMessage("Last Call to join!",chatmethod,GetDefaultLanguage("player"));
	WanderersGambling_EditBox:ClearFocus();
	WanderersGambling_LASTCALL_Button:Disable();
	WanderersGambling_ROLL_Button:Enable();
end

function WanderersGambling_OnClickACCEPTONES() 
	if WanderersGambling_EditBox:GetText() ~= "" and WanderersGambling_EditBox:GetText() ~= "1" then
		WanderersGambling_Reset();
		WanderersGambling_ROLL_Button:Disable();
		WanderersGambling_LASTCALL_Button:Disable();
		AcceptOnes = "true";
		AcceptLoserAmount = "false";
		local fakeroll = "";
		local withdrawComment = "with much shame!"
		local amount = tonumber(WanderersGambling_EditBox:GetText())
		local highRoller = ""
		local sRandomComment = "Welcome to"
		local sRandomCommentEnd = ""
		if amount % 2 > 0 then withdrawComment = "how embarrassing!" sRandomComment = "Focus up for" sRandomCommentEnd = " A product from, Boomur & Sons!"	 end		
		if amount > 99999 then highRoller = "Let's go High Rollers!" end
		SendChatMessage(format("%s%s%s%s", sRandomComment.." BronzeKnight's Gambling!"..sRandomCommentEnd.." Rolling for: ", BreakUpLargeNumbers(amount), "!"..highRoller.." Type 1 to join!  (-1 to withdraw, "..withdrawComment..")", fakeroll),chatmethod,GetDefaultLanguage("player"));
        WanderersGambling["lastroll"] = WanderersGambling_EditBox:GetText();
		theMax = tonumber(WanderersGambling_EditBox:GetText()); 
		low = theMax+1;
		tielow = theMax+1;
		WanderersGambling_EditBox:ClearFocus();
		WanderersGambling_AcceptOnes_Button:SetText("New Game");
		WanderersGambling_LASTCALL_Button:Disable();
		WanderersGambling_EditBox:ClearFocus();
	else
		message("Please enter a number to roll from.", chatmethod);
	end
end

function WanderersGambling_OnClickRollUser() 
hash_SlashCmdList[rollCmd](WanderersGambling_EditBox:GetText())
end

function WanderersGambling_OnClickRoll1()
	if(WanderersGambling["chat"] == false) then
		SendChatMessage("1","Guild");
	else
		SendChatMessage("1","Raid");
	end
end

WG_Settings = {
	MinimapPos = 75 
	
}


-- ** do not call from the mod's OnLoad, VARIABLES_LOADED or later is fine. **
function WG_MinimapButton_Reposition()
	WG_MinimapButton:SetPoint("TOPLEFT","Minimap","TOPLEFT",52-(80*cos(WG_Settings.MinimapPos)),(80*sin(WG_Settings.MinimapPos))-52)
end


function WG_MinimapButton_DraggingFrame_OnUpdate()

	local xpos,ypos = GetCursorPosition()
	local xmin,ymin = Minimap:GetLeft(), Minimap:GetBottom()

	xpos = xmin-xpos/UIParent:GetScale()+70 
	ypos = ypos/UIParent:GetScale()-ymin-70

	WG_Settings.MinimapPos = math.deg(math.atan2(ypos,xpos)) 
	WG_MinimapButton_Reposition() 
end


function WG_MinimapButton_OnClick()
	DEFAULT_CHAT_FRAME:AddMessage(tostring(arg1).." was clicked.")
end

function WanderersGambling_Report()
	local goldowed = high - low
	local houseCut = 0
	if (WanderersGambling["isHouseCut"] == 1) then 
		houseCut = floor(goldowed * WanderersGambling["guildCutPercentage"])
		goldowed = goldowed - houseCut
		WanderersGambling["house"] = (WanderersGambling["house"] or 0) + houseCut;
	end
	if (goldowed ~= 0) then
		lowname = lowname:gsub("^%l", string.upper)
		highname = highname:gsub("^%l", string.upper)
		local string3 = strjoin(" ", "", lowname, "owes", highname, BreakUpLargeNumbers(goldowed),"gold.")

		if (WanderersGambling["isHouseCut"] == 1) then
			string3 = strjoin(" ", "", lowname, "owes", highname, BreakUpLargeNumbers(goldowed),"gold and",  BreakUpLargeNumbers(houseCut),"to the guildbank.")
		end
		
		local final = {highname, lowname, goldowed, houseCut};
		local index = 0;
		
		if (not WanderersGambling["stats"][WanderersGambling["UUID"]]) then
			WanderersGambling["stats"][WanderersGambling["UUID"]] = { }
		end
		
		table.insert(WanderersGambling["stats"][WanderersGambling["UUID"]], final); --won, lost, owed
	
		SendChatMessage(string3,chatmethod,GetDefaultLanguage("player"));
		
		if (WanderersGambling["loser"] == 1) then
			SendChatMessage(string.format("%s can now set the next gambling amount by saying !amount x", lowname), chatmethod);
			AcceptLoserAmount = lowname;
		end
	else
		SendChatMessage("It was a tie! No payouts on this roll!",chatmethod,GetDefaultLanguage("player"));
	end
	WanderersGambling_Reset();
	WanderersGambling_AcceptOnes_Button:SetText("Open Entry");
	WanderersGambling_CHAT_Button:Enable();
end

function WanderersGambling_Tiebreaker()
	tierolls = 0;
	totalrolls = 0;
	tie = 1;
	if table.getn(WanderersGambling.lowtie) == 1 then
		WanderersGambling.lowtie = {};
	end
	if table.getn(WanderersGambling.hightie) == 1 then
		WanderersGambling.hightie = {};
	end
	totalrolls = table.getn(WanderersGambling.lowtie) + table.getn(WanderersGambling.hightie);
	tierolls = totalrolls;
	if (table.getn(WanderersGambling.hightie) == 0 and table.getn(WanderersGambling.lowtie) == 0) then
		WanderersGambling_Report();
	else
		AcceptRolls = "false";
		if table.getn(WanderersGambling.lowtie) > 0 then
			lowbreak = 1;
			highbreak = 0;
			tielow = theMax+1;
			tiehigh = 0;
			WanderersGambling.strings = WanderersGambling.lowtie;
			WanderersGambling.lowtie = {};
			WanderersGambling_OnClickROLL();			
		end
		if table.getn(WanderersGambling.hightie) > 0  and table.getn(WanderersGambling.strings) == 0 then
			lowbreak = 0;
			highbreak = 1;
			tielow = theMax+1;
			tiehigh = 0;
			WanderersGambling.strings = WanderersGambling.hightie;
			WanderersGambling.hightie = {};
			WanderersGambling_OnClickROLL();
		end
	end
end

function WanderersGambling_ParseRoll(temp2)
	local temp1 = strlower(temp2);

	local player, junk, roll, range = strsplit(" ", temp1);

	if junk == "rolls" and WanderersGambling_Check(player)==1 then
		minRoll, maxRoll = strsplit("-",range);
		minRoll = tonumber(strsub(minRoll,2));
		maxRoll = tonumber(strsub(maxRoll,1,-2));
		roll = tonumber(roll);
		if (maxRoll == theMax and minRoll == 1) then
			if (tie == 0) then
				if (roll == high) then
					if table.getn(WanderersGambling.hightie) == 0 then
						WanderersGambling_AddTie(highname, WanderersGambling.hightie);
					end
					WanderersGambling_AddTie(player, WanderersGambling.hightie);
				end
				if (roll>high) then
					highname = player
					highplayername = player
					if (high == 0) then
						high = roll
						if (whispermethod) then
							SendChatMessage(string.format("You have the HIGHEST roll so far: %s and you might win a max of %sg", roll, (high - 1)),"WHISPER",GetDefaultLanguage("player"),player);
						end
					else
						high = roll
						if (whispermethod) then
							SendChatMessage(string.format("You have the HIGHEST roll so far: %s and you might win %sg from %s", roll, (high - low), lowplayername),"WHISPER",GetDefaultLanguage("player"),player);
							SendChatMessage(string.format("%s now has the HIGHEST roller so far: %s and you might owe him/her %sg", player, roll, (high - low)),"WHISPER",GetDefaultLanguage("player"),lowplayername);
						end
					end
					WanderersGambling.hightie = {};
			
				end
				if (roll == low) then
					if table.getn(WanderersGambling.lowtie) == 0 then
						WanderersGambling_AddTie(lowname, WanderersGambling.lowtie);
					end
					WanderersGambling_AddTie(player, WanderersGambling.lowtie);
				end
				if (roll<low) then 
					lowname = player
					lowplayername = player
					low = roll
					if (high ~= low) then
						if (whispermethod) then
							SendChatMessage(string.format("You have the LOWEST roll so far: %s and you might owe %s %sg ", roll, highplayername, (high - low)),"WHISPER",GetDefaultLanguage("player"),player);
						end
					end
					WanderersGambling.lowtie = {};				
			
				end
			else
				if (lowbreak == 1) then
					if (roll == tielow) then
						
						if table.getn(WanderersGambling.lowtie) == 0 then
							WanderersGambling_AddTie(lowname, WanderersGambling.lowtie);
						end
						WanderersGambling_AddTie(player, WanderersGambling.lowtie);
					end
					if (roll<tielow) then 
						lowname = player
						tielow = roll;
						WanderersGambling.lowtie = {};				
		
					end
				end
				if (highbreak == 1) then
					if (roll == tiehigh) then
						if table.getn(WanderersGambling.hightie) == 0 then
							WanderersGambling_AddTie(highname, WanderersGambling.hightie);
						end
						WanderersGambling_AddTie(player, WanderersGambling.hightie);
					end
					if (roll>tiehigh) then
						highname = player
						tiehigh = roll;
						WanderersGambling.hightie = {};
			
					end
				end
			end
			WanderersGambling_Remove(tostring(player));
			totalentries = totalentries + 1;

			if table.getn(WanderersGambling.strings) == 0 then
				if tierolls == 0 then
					WanderersGambling_Report();
				else
					if totalentries == 2 then
						WanderersGambling_Report();
					else
						WanderersGambling_Tiebreaker();
					end
				end
			end
		end	
	end
end

function WanderersGambling_Check(player)
	for i=1, table.getn(WanderersGambling.strings) do
		if strlower(WanderersGambling.strings[i]) == tostring(player) then
			return 1
		end
	end
	return 0
end

function WanderersGambling_List()
	for i=1, table.getn(WanderersGambling.strings) do
	  	local string3 = strjoin(" ", "", tostring(WanderersGambling.strings[i]):gsub("^%l", string.upper),"still needs to roll.")
		SendChatMessage(string3,chatmethod,GetDefaultLanguage("player"));
	end
end

function WanderersGambling_ListBan()
	local bancnt = 0;
	Print("", "", "|cffffff00To ban do /gamble ban (Name) or to unban /gamble unban (Name) - The Current Bans:");
	for i=1, table.getn(WanderersGambling.bans) do
		bancnt = 1;
		DEFAULT_CHAT_FRAME:AddMessage(strjoin("|cffffff00", "...", tostring(WanderersGambling.bans[i])));
	end
	if (bancnt == 0) then
		DEFAULT_CHAT_FRAME:AddMessage("|cffffff00To ban do /gamble ban (Name) or to unban /gamble unban (Name).");
	end
end

function WanderersGambling_Add(name)
	local charname, realmname = strsplit("-",name);
	local insname = strlower(charname);
	if (insname ~= nil or insname ~= "") then
		local found = 0;
		for i=1, table.getn(WanderersGambling.strings) do
		  	if WanderersGambling.strings[i] == insname then
				found = 1;
			end
        	end
		if found == 0 then
		      	table.insert(WanderersGambling.strings, insname)
			totalrolls = totalrolls+1
		end
	end
end

function WanderersGambling_ChkBan(name)
	local charname, realmname = strsplit("-",name);
	local insname = strlower(charname);
	if (insname ~= nil or insname ~= "") then
		for i=1, table.getn(WanderersGambling.bans) do
			if strlower(WanderersGambling.bans[i]) == strlower(insname) then
				return 1
			end
		end
	end
	return 0
end

function WanderersGambling_AddBan(name)
	local charname, realmname = strsplit("-",name);
	local insname = strlower(charname);
	if (insname ~= nil or insname ~= "") then
		local banexist = 0;
		for i=1, table.getn(WanderersGambling.bans) do
			if WanderersGambling.bans[i] == insname then
				Print("", "", "|cffffff00Unable to add to ban list - user already banned.");
				banexist = 1;
			end
		end
		if (banexist == 0) then
			table.insert(WanderersGambling.bans, insname)
			Print("", "", "|cffffff00User is now banned!");
			local string3 = strjoin(" ", "", "User Banned from rolling! -> ",insname, "!")
			DEFAULT_CHAT_FRAME:AddMessage(strjoin("|cffffff00", string3));
		end
	else
		Print("", "", "|cffffff00Error: No name provided.");
	end
end

function WanderersGambling_RemoveBan(name)
	local charname, realmname = strsplit("-",name);
	local insname = strlower(charname);
	if (insname ~= nil or insname ~= "") then
		for i=1, table.getn(WanderersGambling.bans) do
			if strlower(WanderersGambling.bans[i]) == strlower(insname) then
				table.remove(WanderersGambling.bans, i)
				Print("", "", "|cffffff00User removed from ban successfully.");
				return;
			end
		end
	else
		Print("", "", "|cffffff00Error: No name provided.");
	end
end
				
function WanderersGambling_AddTie(name, tietable)
	local charname, realmname = strsplit("-",name);
	local insname = strlower(charname);
	if (insname ~= nil or insname ~= "") then
		local found = 0;
		for i=1, table.getn(tietable) do
		  	if tietable[i] == insname then
				found = 1;
			end
        	end
		if found == 0 then
		    table.insert(tietable, insname)
			tierolls = tierolls+1	
			totalrolls = totalrolls+1		
		end
	end
end

function WanderersGambling_Remove(name)
	local charname, realmname = strsplit("-",name);
	local insname = strlower(charname);
	for i=1, table.getn(WanderersGambling.strings) do
		if WanderersGambling.strings[i] ~= nil then
		  	if strlower(WanderersGambling.strings[i]) == strlower(insname) then
				table.remove(WanderersGambling.strings, i)
				totalrolls = totalrolls - 1;
			end
		end
      end
end

function WanderersGambling_RemoveTie(name, tietable)
	local charname, realmname = strsplit("-",name);
	local insname = strlower(charname);
	for i=1, table.getn(tietable) do
		if tietable[i] ~= nil then
		  	if strlower(tietable[i]) == insname then
				table.remove(tietable, i)
			end
		end
      end
end

function WanderersGambling_Reset()
		WanderersGambling["strings"] = { };
		WanderersGambling["lowtie"] = { };
		WanderersGambling["hightie"] = { };
		AcceptOnes = "false"
		AcceptRolls = "false"
		totalrolls = 0
		theMax = 0
		tierolls = 0;
		lowname = ""
		highname = ""
		low = theMax
		high = 0
		tie = 0
		highbreak = 0;
		lowbreak = 0;
		tiehigh = 0;
		tielow = 0;
		totalentries = 0;
		highplayername = "";
		lowplayername = "";
		WanderersGambling_ROLL_Button:Disable();
		WanderersGambling_AcceptOnes_Button:Enable();		
		WanderersGambling_LASTCALL_Button:Disable();
		WanderersGambling_CHAT_Button:Enable();
end

function WanderersGambling_ResetCmd()
	SendChatMessage("BronzeKnight's Gambling game has been reset!", chatmethod)	
end

function WanderersGambling_EditBox_OnLoad()
	WanderersGambling_EditBox:SetNumeric(true);
	WanderersGambling_EditBox:SetAutoFocus(false);
end

function WanderersGambling_CreateUUID()
	local random = math.random
    local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function (c)
        local v = (c == 'x') and random(0, 0xf) or random(8, 0xb)
        return string.format('%x', v)
    end)
end
