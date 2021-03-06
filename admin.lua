 local	pass = 0
 local	cnoname = nil
 local	co_client = {}
 local	client_lev = {}
 local	client_guid = {}
 local	sys_level = {}
 
 --[[
	It must contain a file lev_list.txt where levels are defined
	ex: Admin = 777 !ban, !help, !setlevel, !lev, !ref, !kick, !mute, !unmute, !splat
	There must be a ',' between each commands
 --]]
 
local	cmd_list = {
					"!help",
					"!lev",
					"!listplayer",
					"!spec999",
					"!levlist",
					"!getguid",
					"!cry",
					"!slap",
					"!splat",
					"!swap",
					"!warn",
					"!nextmap",
					"!unmute",
					"!mute",
					"!kick",
					"!putteam",
					"!passvote",
					"!cancelvote",
					"!rename",
					"!finger",
					"!gethealth",
					"!givehealth",
					"!setlevel",
					"!ban",
					"!banlist",
					"!unban",
					"!ref",
					"!unref"
					}

function	getFileContent(filename)
	local	file = io.open(filename, "r")
	local	content

	if (file == nil) then
		return nil
	end
	content = file:read("*all")
	file:close();
	return content
end

function	writeList(list, filename)
	local	file = io.open(filename, "w")

	if (file == nil) then
		xwrite(-1, "cpm \"^3Warning Failed to open file: "..filename.."\"")
		return false
	end
	for _, line in ipairs(list) do
		file:write(line.."\n")
	end
	file:close()
	return true
end
			
function	skip_carac(str, spe, i)
	while (string.sub(str, i, i) == sep) do
		i = i + 1
	end
	return 	i
end

function	explode(str, sep)
	local	tab = {}
	local	len = string.len(str) + 1
	local	wend = skip_carac(str, sep, 1)
	local	wstart = wend
	local	hit = 1

	while (wstart < len) do
		local	carac = string.sub(str, wend, wend)

		if (carac == sep or wend == (len - 1)) then
			if (wend == (len - 1) and carac ~= sep) then hit = 0 end
			table.insert(tab, string.sub(str, wstart, wend - hit))
			wend = skip_carac(str, sep, wend) + 1
			if (wend == (len - 1)) then wend = wend + 1 end
			wstart = wend
		else
			wend = wend + 1
		end
	end
	return	tab
end

function	join(array, sep)
	local	finalStr = ""
	for i, str in ipairs(array) do
		if (i > 1) then finalStr = finalStr .. sep end
		finalStr = finalStr .. str
	end
	return finalStr
end

function	copyTableAt(array, at)
	local	newArray = {}
	
	for i, str in ipairs(array) do
		if (i >= at) then
			table.insert(newArray, str)
		end
	end
	return newArray
end

function	eraseElem(array, elem)
	for i, str in ipairs(array) do
		if (str == elem) then
			table.remove(array, i)
			return true
		end
	end
	return false
end

function	clearTable(array)
	for k, v in pairs(array) do
		array[k] = nil
	end
end

function	epurFromColor(str)
	return et.Q_CleanStr(str) 
end

function	getBiggestWord(array, idx, step)
	local	biggest = 0
	local	tmp

	while (array[idx] ~= nil) do
		tmp = epurFromColor(array[idx])
		if (string.len(tmp) > biggest) then
			biggest = string.len(tmp)
		end
		idx = idx + step
	end
	return biggest
end

function	createSpaces(amount)
	local	spaces = ""

	for i = 0, amount do
		spaces = spaces .. " "
	end
	return spaces
end

function	formatToTable(array, width)
	local	size = table.getn(array)
	local	spaces = {}
	local	final = {}
	local	nb_column
	local	i = 1
	
	if (width > size) then
		nb_column = size
	else
		nb_column = width
	end
	for i = 1, nb_column do
		spaces[i] = getBiggestWord(array, i, width) + 1
	end
	while (i <= size) do
		local	j = 0
		local	str = ""
		while (j < nb_column and i + j <= size) do
			local	tmp
			
			tmp = epurFromColor(array[i + j])
			str = str .. array[i + j] .. createSpaces(spaces[j + 1] - string.len(tmp))
			j = j + 1
		end
		table.insert(final, str)
		i = i + j
	end
	return final
end

function	getName(id)
	return string.gsub(et.gentity_get(id, "pers.netname"), "%^$", "^^ ")
end

function	getCvar(id, cvar)
	return et.Info_ValueForKey(et.trap_GetUserinfo(id), cvar)
end

function	getIp(id)
	local	userinfo = et.trap_GetUserinfo(id)
	local	ip = et.Info_ValueForKey(userinfo, "ip")
	local	a = string.find(ip, ':')
	
	if (a ~= nil) then
		ip = string.sub(ip, 1, a - 1)
	end
	return ip
end

function	getTeamName(id)	-- 1: Axis | 2: Allie | 3: Spec
	local	name
	
	if (id == 1) then name = "^t   Axis   "
	elseif (id == 2) then name = "^q  Allies  "
	elseif (id == 3) then name = "^8 Spectator "
	else name = "" end
	return name
end

function	isAlive(id)
	if (tonumber(et.gentity_get(id, "health")) > 0) then
		return true
	end
	return false
end

function	getStatus(id)
	if (et.gentity_get(id, "sess.muted", 1) == 1) then
		return "^qMuted"
	elseif (tonumber(et.gentity_get(id,"sess.referee")) == 1) then
		return "^2Referee"
	end
	return "^7Normal"
end

function	getClientProGuid(id)
	for i, array in ipairs(client_guid) do
		if (tonumber(id) == tonumber(array[1])) then
			return array[2]
		end
	end
	return 0
end

-- tab[1] = name | tab[2] = guid | tab[3] = level

function	fill_client_level(tab, maxclients)
	local	i = 0

	while (i < maxclients) do
		local	cl_guid = string.lower(getCvar(i, "cl_guid"))
		
		if (cl_guid == tab[2]) then
			client_lev[i + 1] = tonumber(tab[3])
		end
		i = i + 1
	end
end

function	get_pl_levels() -- load client levels
	local	maxclients = tonumber((et.trap_Cvar_Get("sv_maxClients")) - 1)
	local	file = io.open("pl_levels.txt", "r")
	local	line = nil
	local	i = 0

	while (i < maxclients) do -- init to 0
		client_lev[i + 1] = 0
		i = i + 1
	end
	if (file ~= nil) then -- load levels
		line = file:read("*line")
		while (line ~= nil) do
			local	tab = explode(line, ' ')
			fill_client_level(tab, maxclients)
			line = file:read("*line")
		end
		file:close()
	end
end

function	getEpuredName(id)	-- remove spaces and color codes
	local	name = et.gentity_get(id, "pers.netname")

	if (name == nil) then return nil end
	name = epurFromColor(name)
	name = string.gsub(name, " ", "")
	return	name
end
 
function	getLev(clientId)
	return (tonumber(client_lev[clientId + 1]))
end

function	setLev(clientId, lev)
	client_lev[clientId + 1] = tonumber(lev)
end

function	getLastIndexOf(str, char)
	local	lastIndex = nil
	local	p = string.find(str, char, 1)

	lastIndex = p
	while (p) do
		p = string.find(str, char, p + 1)
		if p then
			lastIndex = p
		end
	end
	return lastIndex
end

--[[
	This function returns the id and name of the client
	Argument client can be the id or the name
--]]

function	get_player_info(client)
	local	maxclients = tonumber((et.trap_Cvar_Get("sv_maxClients")) - 1)
	local	name = nil
	local	i = 0

	if (client == nil) then return -1, nil end
	if (string.find(client, "%a") == nil) then
		name = getEpuredName(client)
		return client, name
	end
	client = string.gsub(client, " ", "")
	client = string.gsub(client, "(^%w)", "")
	while (i < maxclients) do
		local	pl_name = getEpuredName(i)

		if (pl_name ~= nil) then
			if (pl_name ~= nil and string.find(pl_name, client) ~= nil) then
				return i, pl_name
			end
		end
		i = i + 1
	end
	return -1, nil
end

function	checkmuted(client)
	return	et.gentity_get(client, "sess.muted", 1)
end

function	countAlivePlayers(id)
	local	maxclients = tonumber((et.trap_Cvar_Get("sv_maxClients")) -1)

	local	team = tonumber(et.gentity_get(id, "sess.sessionTeam"))
	local	alive = 0

	if (team == 3) then return 1 end
	for i = 0, maxclients do
		local	clientteam = tonumber(et.gentity_get(i, "sess.sessionTeam"))

		if (clientteam == team) then
			if (tonumber(et.gentity_get(i, "health")) > 0) then alive = alive + 1 end
		end
	end
	return alive
end

function	get_level_name(line)
	local	pos = string.find(line, '=') -- geting the level name
	local	name = nil

	if (pos == nil) then -- no = in the line
		return nil
	elseif (pos == 1) then -- no name
		return nil
	end
	pos = pos - 1
	name = string.sub(line, 1, pos)
	return name
end

function	get_flag(line)
	local	flag = 0
	local	pos1, pos2
	local	lev = 0
	local	j = 1
	local	commands = {}

	pos1, pos2 = string.find(line, "%d+", 1)
	if (pos1 == nil or pos2 == nil) then return nil, 0 end
	lev = tonumber(string.sub(line, pos1, pos2))
	if (lev == nil) then return nil, 0 end -- no level

	pos1, pos2 = string.find(line, '!')
	if (pos1 == nil) then return lev, flag end
	line = string.sub(line, pos1)
	if (line == nil) then return lev, flag end	-- no commands

	commands = explode(line, ',')
	for _, cmd in ipairs(commands) do
		j = 1
		while (cmd_list[j] ~= nil and cmd_list[j] ~= cmd) do
			j = j + 1
		end
		if (cmd_list[j] ~= nil) then
			flag = flag + math.pow(2, j - 1)
		end
	end
	return lev, flag
end
 
function	get_levels()		-- get levels from file
	local	levels = {}			-- contains Name - level - flag
	local	file = io.open("lev_list.txt", "r")
	local	line = nil
	local	i = 1

	if (file ~= nil) then -- load levels
		line = file:read("*line")
		while (line ~= nil) do
			levels[i] = {}		-- create the second dimention to stock the informations
			local	name = get_level_name(line)
			if (name == nil) then return nil end
			levels[i][1] = name
			line = string.sub(line, string.find(line, '=') + 1)
			if (line == nil) then return nil end
			line = string.gsub(line, ' ', '') -- take off the spaces
			levels[i][2], levels[i][3] = get_flag(line)
			if (levels[i][2] == nil) then return nil end
			line = file:read("*line")
			i = i + 1
		end
		file:close()
	end
	return levels
end


function	get_pl_rank_from_lev(pl_level)
	local	i = 1

	while (sys_level[i] ~= nil and sys_level[i][2] ~= pl_level) do
		i = i + 1
	end
	if (sys_level[i] ~= nil) then return sys_level[i][1] end
	return "not set"
end 

function	get_pl_flag_from_lev(pl_level)
	local	i = 1

	while (sys_level[i] ~= nil and sys_level[i][2] ~= pl_level) do
		i = i + 1
	end
	if (sys_level[i] ~= nil) then return sys_level[i][3] end
	return 0
end

function	convert_to_binary(nb)
	local	bin = {}
	local	i = 1
	local	cast = 0

	while (nb > 0) do
		bin[i] = math.mod(nb, 2)
		nb = nb / 2
		cast = math.mod(nb, 1)
		nb = nb - cast
		i = i + 1
	end
	return bin
end

function	helpCmd(client, flag, unused1, unused2)
	local	bits = convert_to_binary(flag)
	local	cmd = {}
	local	finalList = {}
	local	tflag = flag
	local	i = 1

	et.trap_SendServerCommand(client, "print \"\nCommand list^q:\n\n\"")
	while (cmd_list[i] ~= nil) do
		if (bits[i] == 1) then
			table.insert(cmd, cmd_list[i])
		end
		i = i + 1
	end
	finalList = formatToTable(cmd, 4)
	for _, str in ipairs(finalList) do
		et.trap_SendServerCommand(client, "print \""..str.."\n\"")
	end
	et.trap_SendServerCommand(client, "print \"\n^7Total^q: ^2"..table.getn(cmd).." ^7command"..((table.getn(cmd) > 1) and "s" or "").."\n\n\"")
end

function	levCmd(client, unused1, rank, unused2)
	et.trap_SendServerCommand(-1, "chat \"^7Player ^7"..getName(client).."^7 is level ^q"..getLev(client).."^7, rank: ^2"..rank.."\"")
end

function	listPlayerCmd(client, unused1, rank, unused2)
	local	array = {}
	local	finalList = {}
	local	maxclients = tonumber(et.trap_Cvar_Get("sv_maxclients")) - 1
	local	nbColumn = 6

	table.insert(array, "^q#")
	table.insert(array, "^7L")
	table.insert(array, "^2RANK")
	table.insert(array, "^7NAME")
	table.insert(array, "^7ALIVE")
	table.insert(array, "^7STATUS")
	for i = 1, 3 do
		for j = 0, maxclients do
			if (et.gentity_get(j, "pers.connected") == 2 and et.gentity_get(j, "sess.sessionTeam") == i) then
				table.insert(array, tostring(j))
				table.insert(array, tostring(getLev(j)))
				table.insert(array, tostring(get_pl_rank_from_lev(getLev(j))))
				table.insert(array, tostring(getName(j)))
				table.insert(array, tostring((isAlive(j) == true) and "^2  O" or "^q  O"))
				table.insert(array, tostring(getStatus(j)))
			end
		end
	end
	finalList = formatToTable(array, nbColumn)
	et.trap_SendServerCommand(client, "print \"\n\"")
	for i, str in ipairs(finalList) do
		if (i >= 2) then
			local	cuTeam = et.gentity_get(array[nbColumn * (i - 1) + 1], "sess.sessionTeam")
			
			if (i == 2) then
				et.trap_SendServerCommand(client, "print \"^z----------------------------------------"..getTeamName(cuTeam).."^z------------------------------\n\"")
			elseif (i > 2) then
				local	prevTeam = et.gentity_get(array[nbColumn * (i - 2) + 1], "sess.sessionTeam")
				
				if (cuTeam ~= prevTeam) then
					et.trap_SendServerCommand(client, "print \"^z----------------------------------------"..getTeamName(cuTeam).."^z------------------------------\n\"")
				end
			end
		end
		et.trap_SendServerCommand(client, "print \""..str.."\n\"")
	end
	et.trap_SendServerCommand(client, "print \"\n\"")
end

function	inactiveCmd(unused1, unused2, unused3, unused4)
	local	removed = 0
	local	maxclients = tonumber(et.trap_Cvar_Get("sv_maxclients")) - 1
	
	for i = 0, maxclients do
		local team = tonumber(et.gentity_get(i,"sess.sessionTeam"))

		if (team == 1 or team == 2) then
			if (tonumber(et.gentity_get(i, "ps.ping")) >= 999) then
				et.trap_SendConsoleCommand(et.EXEC_APPEND, "ref remove "..i.."\"")
				removed = removed + 1
			end
		end
	end
	et.trap_SendServerCommand(-1, "chat \"^2Spec999: ^7Moving ^1" ..removed.. " ^7players to spectator\"")
end

function	levlistCmd(client, flag, rank, id)
	for i = 1, table.getn(sys_level) do
		et.trap_SendServerCommand(client, "chat \""..sys_level[i][1]..": ^2"..sys_level[i][2].."\"")
	end
end

function	getguidCmd(client, unused1, unused2, unused3)
	local	pl_guid = string.lower(getCvar(client, "cl_guid"))

	if (pl_guid == nil or pl_guid == "unknown") then
		et.trap_SendServerCommand(client, "chat \"Unknown guid\"")
	else
		et.trap_SendServerCommand(client, "chat \"^2GUID: ^7["..pl_guid.."]\"")
	end
end

function	cryCmd(client, unused1, unused2, id)
	local	crysound = "sound/cry.wav"
	local	soundindex = et.G_SoundIndex(crysound)

	et.G_Sound(id, soundindex)
	et.trap_SendServerCommand(-1, "chat \"^7"..et.gentity_get(id, "pers.netname").." ^7is crying like a ^1baby ^7!\"")
end
 
function	slapCmd(client, unused1, unused2, id)
	local	cname = getName(client)
	local	vname = getName(id)
	local	slapsound = "sound/slap.wav"
	local	soundindex = et.G_SoundIndex(slapsound)

	if (et.gentity_get(id, "health") <= 0) then
		et.trap_SendServerCommand(client, "print \""..cname.." ^7is beating "..vname"^7's dead corpse\"")
	else
	    et.gentity_set(id,"health", (et.gentity_get(id,"health") - 15))
		et.trap_SendServerCommand(-1, "chat \""..vname.." ^7got ^qSlapped ^7by "..cname.."\"")
	end
	et.G_Sound(client, soundindex)	
end

function	splatCmd(client, flag, rank, id)
	local	namep = string.gsub(et.gentity_get(id, "pers.netname"), "%^$", "^^ ")
	local	namec = string.gsub(et.gentity_get(client, "pers.netname"), "%^$", "^^ ")

	et.gentity_set(id, "health", -500)
	et.G_globalSound("sound/player/gib.wav")
	et.trap_SendServerCommand(-1, "chat \""..namep.." ^7got ^qSplated ^7by "..namec.."\"")
	if (tonumber(et.trap_Cvar_Get( "gamestate")) == 0 and countAlivePlayers(id) == 0) then
		et.trap_SendServerCommand(-1, "chat \"^t-^7Match ended because there was no players alive^t-\"")
		et.trap_SendConsoleCommand(et.EXEC_APPEND, "ref matchreset")
	end
end

function	playToAll(sound)
	et.G_globalSound(sound)
end

function	swapCmd(unused1, unused2, unused3, unused4)
	playToAll("sound/misc/referee.wav")
	et.trap_SendConsoleCommand(et.EXEC_APPEND, "swap_teams")
	et.trap_SendServerCommand(-1, "chat \"^3Swap^w: ^fteams got swapped!\"")
end

function	warnCmd(client, unused1, unused2, id, argv)
	local	warnsound = "sound/misc/referee.wav"
	local	soundindex = et.G_SoundIndex(warnsound)
	local	reasonTable = copyTableAt(argv, 4)
	local	reason = join(reasonTable, " ")
	local	wName = getEpuredName(id)

	et.G_Sound(id, soundindex)
	et.trap_SendConsoleCommand(et.EXEC_APPEND, "ref warn \""..wName.."\" \""..reason.."\"")
end

function	nextmapCmd(unused1, unused2, unused3, unused4)
	playToAll("sound/misc/referee.wav")
	et.trap_SendConsoleCommand(et.EXEC_APPEND, "timelimit 0.01")
	et.trap_SendConsoleCommand(et.EXEC_INSERT, "start_match")
end

function	unmuteCmd(client, flag, rank, id)
	local	name = string.gsub(et.gentity_get(id, "pers.netname"), "%^$", "^^ ")

	if (checkmuted(id) ~= 1) then 				-- already muted
		et.trap_SendServerCommand(client, "chat \"^2The player is not muted\"")
		return 1
	end
	et.gentity_set(id, "sess.muted", 0)
	et.trap_SendServerCommand(-1, "cpm \""..name.."^7 is ^qunmuted\"")
	return 1
end

function	muteCmd(client, flag, rank, id, argv)		-- time doesnt work yet
	local	name = string.gsub(et.gentity_get(id, "pers.netname"), "%^$", "^^ ")
	local	mu_time = argv[4]
	
	if (checkmuted(id) == 1) then 				-- already muted
		et.trap_SendServerCommand(client, "chat \"^2The player is already muted\"")
		return 1
	end
	if (mu_time == nil) then
		mu_time = 600	-- muted time set to 10 mins
	end
	et.gentity_set(id, "sess.muted", 1)
	et.trap_SendServerCommand(-1, "cpm \""..name.."^7 is ^qmuted\"")
	return 1
end

function	kickCmd(unused1, unused2, unused3, id)
	et.trap_DropClient(id, "Kicked by admin", 600) -- kick for 10 mins
end

function	putteamCmd(client, unused2, unused3, id, argv)
	local	player_team = 2	-- 1: Axis | 2: Allie | 3: Spec
	local 	player_name = getName(id)
	local	command = ""
	local	teamName = ""
	local	where = argv[4]

	if (where == nil) then
		et.trap_SendServerCommand(client, "print \"^8Syntax : ^g!put [name or #slot] [b|r|s]\n\"")
		return
	end
	if (player_team == 1 and where == "r") then
		et.trap_SendServerCommand(client, "print \"^gAlready in axis\"")
		return
	elseif (player_team == 2 and where == "b") then
		 et.trap_SendServerCommand(client, "print \"^gAlready in allies\"")
		 return
	elseif (player_team == 3 and where == "s") then
		 et.trap_SendServerCommand(client, "print \"^gAlready in spectator\"")
		 return
	end
	if (where == "r" or where == "axis" ) then
		command = "putaxis"
		teamName = "axis"
	elseif (where == "b" or where == "allies" ) then
		command = "putallies"
		teamName = "allies"
	elseif (where == "s" or where == "spec" ) then
		command = "remove"
		teamName = "spectators"
	else
		et.trap_SendServerCommand(client, "print \"^8Syntax : ^g!put [name or #slot] [b|r|s]\n\"")
		return
	end
	et.trap_SendConsoleCommand(et.EXEC_APPEND, "ref "..command.." "..id)
	et.trap_SendServerCommand(-1, "chat \"^3Putteam^w: ^1" ..player_name.." ^fjoined the "..teamName.."\"")
end

function    passVoteCmd(unused1, unused2, unused3, unused4)
    et.trap_SendConsoleCommand(et.EXEC_APPEND , "passvote") 
end

function    cancelVoteCmd(unused1, unused2, unused3, unused4)
    et.trap_SendConsoleCommand(et.EXEC_APPEND , "cancelvote") 
end

function	renameCmd(client, unused2, unused3, id, argv)
	local	name = argv[4]
	if (name == nil) then
		et.trap_SendServerCommand(client, "chat \"^8Syntax : ^g!rename ^7name newName\n\"")
		return
	end
	local	userinfo = et.Info_SetValueForKey(et.trap_GetUserinfo(id), "name", name)
	et.trap_SetUserinfo(id, userinfo)
	et.ClientUserinfoChanged(id)
end 

function	fingerCmd(client, unused2, unused3, id)
	local	name = getName(id)
	local	ip = getIp(id)
	local	pl_guid = string.lower(getCvar(id, "cl_guid"))
	local	pr_guid = getClientProGuid(id)

	et.trap_SendServerCommand(client, "print \"^3Finger: ^7["..name.."]^7 | id: ["..id.."] | ip: ["..ip.."]\nclient guid: ["..pl_guid.."]\netpro guid: ["..pr_guid.."]\"")
end

function	getHealthCmd(client, unused2, unused3, id)
	local	hp = tonumber(et.gentity_get(id, "health"))
	local	name = getName(id)
	
	et.trap_SendServerCommand(client, "chat \""..name.." ^7has ^2"..hp.." ^7hp\"")
end

function	giveHealthCmd(client, unused2, unused3, id, argv)
	local	hp = tonumber(et.gentity_get(id, "health"))
	local	amount = tonumber(argv[4])

	if (amount <= 0 or amount > 30000) then	
		et.trap_SendServerCommand(client, "chat \"Amount must be between ^q[^71 ^2- ^730000^q]\"")
		return
	end
	et.gentity_set(id, "health", hp + amount)
	et.trap_SendServerCommand(id, "cpm \"You were given ^2"..amount.." ^7hp\"")
end

function	setlevelCmd(adm, unused1, unused2, client, argv) -- set the new level of a client
	local	ptr = io.open("pl_levels.txt", "r")
	local	file = {}
	local	i = 1
	local	j = 1
	local	id, name = get_player_info(client)
	local	lev = argv[4]
	
	if (lev == nil) then
		et.trap_SendServerCommand(client, "chat \"^3Usage: ^7!setlevel [Name/id] level\"")
		return
	elseif (ptr == nil) then
		et.trap_SendServerCommand(client, "chat \"^qError: ^7File pl_levels.txt not found\"")
		return
	elseif (id == -1 or name == nil) then
		et.trap_SendServerCommand(adm, "chat \"Player "..client.." doesn't exist\"")
		return -1
	end

	local	pl_guid = string.lower(et.Info_ValueForKey(et.trap_GetUserinfo(id), "cl_guid"))
	if (pl_guid == "unknown") then
		et.trap_SendServerCommand(adm, "chat \"Unknown guid\"")
		return -1
	end
	line = ptr:read("*l")
	while (line ~= nil) do
		file[i] = line
		i = i + 1
		line = ptr:read("*l")
	end
	ptr:close()
	ptr = io.open("pl_levels.txt", "w")
	if (ptr == nil) then
		et.trap_SendServerCommand(client, "chat \"^qError: ^7Failed to open file pl_levels.txt\"")
		return
	end
	while (j < i and string.find(file[j], pl_guid) == nil) do
		j = j + 1
	end
	file[j] = name .. " " .. pl_guid .. " " .. lev
	if (j == i) then
		i = i + 1
	end
	j = 1
	while (j < i) do
		ptr:write(file[j])
		ptr:write("\n")
		j = j + 1
	end
	ptr:close()
	name = string.gsub(et.gentity_get(id, "pers.netname"), "%^$", "^^ ")
	et.trap_SendServerCommand(-1, "chat \"^7Player ^7"..name.."^7 has been set to level "..lev.."\"")
	setLev(client, lev)
	return 0
end

function	banlistCmd(client, unused1, unused2, unused3)
	local	tmp = getFileContent("banlist.txt")
	if (tmp == nil) then
		et.trap_SendServerCommand(client, "print \"\n^7Total: ^q0\"")
		return
	end
	local	content = explode(tmp, "\n")
	local	remainingTime
	local	formatTable = {}
	
	table.insert(formatTable, "Nom")
	table.insert(formatTable, "Ip")
	table.insert(formatTable, "Etpro Guid")
	table.insert(formatTable, "Client Guid")
	table.insert(formatTable, "Ban Time")
	table.insert(formatTable, "Remaining")
	for _, str in ipairs(content) do
		local	sep = getLastIndexOf(str, '|')
		if (sep ~= nil) then
			local	name = string.sub(str, 2, sep - 1)
			str = string.sub(str, sep + 2)
			local	plInfo = explode(str, ' ')

			remainingTime = tonumber(plInfo[4]) - (os.time() - tonumber(plInfo[5]))
			if (remainingTime < 0) then remainingTime = 0 end
			table.insert(formatTable, name)
			table.insert(formatTable, plInfo[1])
			table.insert(formatTable, plInfo[2])
			table.insert(formatTable, plInfo[3])
			table.insert(formatTable, plInfo[4])
			table.insert(formatTable, remainingTime)
		end
	end
	formatTable = formatToTable(formatTable, 6)
	for _, str in ipairs(formatTable) do
		et.trap_SendServerCommand(client, "print \""..str.."\n\"")
	end
	et.trap_SendServerCommand(client, "print \"^7Total: ^q"..table.getn(content).."\"")
end

function	unbanCmd(client, unused1, unused2, unused3, argv)
	local	Bname = argv[3]
	local	tmp = getFileContent("banlist.txt")
	if (tmp == nil) then return end
	local	content = explode(tmp, "\n")
	local	hit = 0
	local	plInfo

	for i, str in ipairs(content) do
		if (hit == 0) then
			local sep = getLastIndexOf(str, '|')
			if (sep ~= nil) then
				local	name = string.sub(str, 2, sep - 1)
				
				if (string.find(epurFromColor(name), epurFromColor(Bname)) ~= nil) then
					hit = i
				end
			end
		end
	end
	if (hit == 0) then
		et.trap_SendServerCommand(client, "chat \"^7Player "..Bname.." ^7not found in the banlist\"")
		return
	end
	
	local	str = content[hit]
	table.remove(content, hit)
	writeList(content, "banlist.txt")
	local	sep = getLastIndexOf(str, '|')
	local	name = string.sub(str, 2, sep - 1)
	str = string.sub(str, sep + 2)
	local	plInfo = explode(str, ' ')

	et.trap_SendConsoleCommand(et.EXEC_APPEND , "PB_SV_UnBanGuid " .. plInfo[3]) -- cl_guid 
	et.trap_SendConsoleCommand(et.EXEC_INSERT , "pb_sv_updbanfile")
	et.trap_SendServerCommand(-1, "cpm \"^7Player "..name.." ^7has been unbanned^q.\"")
end

function	banCmd(client, unused1, unused2, id, argv)
	local	ban_time = tonumber(argv[4])
	local	ip = getIp(id)

	if (ban_time == nil) then
		ban_time = 6000000
	end
	if (ban_time <= 0) then
		et.trap_SendServerCommand(client, "chat \"ban time must be positive\"")
		return 1
	end
	local	file = io.open("banlist.txt", "a")
	local	cuTime = os.time()
	
	if (file == nil) then
		et.trap_SendServerCommand(client, "cpm \"^3Warning: ^7Ban could not be saved\"")
	else
		file:write("|"..getName(id) .. "| "..ip.." "..getClientProGuid(id).." " ..string.lower(getCvar(id, "cl_guid")).. " " ..ban_time.." "..cuTime.."\n")
		file:close()
	end
	et.trap_DropClient(id, "Banned by admin", ban_time)
end

function	refCmd(client, unused1, unused2, unused3)
	local	refStatus = tonumber(et.gentity_get(client,"sess.referee"))

	if (refStatus ~= 0) then
		et.trap_SendServerCommand(client, "chat \"^7You are already referee ^q!\"")
	else
		et.trap_SendConsoleCommand(et.EXEC_APPEND, "ref referee "..client.."")
	end
end

function	unrefCmd(client, unused1, unused2, unused3)
	et.trap_SendConsoleCommand(et.EXEC_APPEND, "ref unreferee "..client.."")
end

function	checkLevel(id1, id2)
	if (getLev(id1) >= getLev(id2)) then
		return 1
	else
		et.trap_SendServerCommand(id1, "chat \"You can't use this command on this player because of your level\"")
		return -1
	end
end

function	playerExist(client, id)
	if (id == -1 or et.gentity_get(id, "pers.connected") ~= 2) then
		et.trap_SendServerCommand(client, "print \"No such player\"")
		return -1
    end
	return 1
end

local cmdTable = 	{
						{helpCmd, nil, nil},
						{levCmd, nil, nil},
						{listPlayerCmd, nil, nil},
						{inactiveCmd, nil, nil},
						{levlistCmd, nil, nil},
						{getguidCmd, nil, nil},
						{cryCmd, playerExist, nil},
						{slapCmd, playerExist, checkLevel},
						{splatCmd, playerExist, checkLevel},
						{swapCmd, nil, nil},
						{warnCmd, playerExist, nil},
						{nextmapCmd, nil, nil},
						{unmuteCmd, playerExist, nil},
						{muteCmd, playerExist, checkLevel},
						{kickCmd, playerExist, checkLevel},
						{putteamCmd, playerExist, checkLevel},
						{passVoteCmd, nil, nil},
						{cancelVoteCmd, nil, nil},
						{renameCmd, playerExist, checkLevel},
						{fingerCmd, playerExist, checkLevel},
						{getHealthCmd, playerExist, nil},
						{giveHealthCmd, playerExist, checkLevel},
						{setlevelCmd, playerExist, checkLevel},
						{banCmd, playerExist, checkLevel},
						{banlistCmd, nil, nil},
						{unbanCmd, nil, nil},
						{refCmd, nil, nil},
						{unrefCmd, nil, nil}
					}
					
function	handle_cmd(client, flag, rank, arg, id)
	local	bits = convert_to_binary(flag)

	for idx, tab in ipairs(cmdTable) do
		if (string.len(arg[2]) >= 3 and string.find(cmd_list[idx], arg[2]) ~= nil) then
			if (bits[idx] == 1) then
				if ((tab[2] == nil or tab[2](client, id) == 1)
				and	(tab[3] == nil or tab[3](client, id) == 1)) then
					tab[1](client, flag, rank, id, arg)
				end
				return 1
			else
				et.trap_SendServerCommand(client, "chat \"Level too low\"")
			end
		end
	end
	return 0
end

function	catchPm(clientNum, arg)
	local	id, nameT = get_player_info(arg[2])
	if (id == -1) then return 0 end

	local	maxclients = tonumber((et.trap_Cvar_Get("sv_maxClients")) - 1)
	local	array = copyTableAt(arg, 3)
	local	str = join(array, " ")
	local	nameF = getName(clientNum)
	
	nameT = getName(id)
	for i = 0, maxclients do
		if (et.gentity_get(i, "pers.connected") == 2 and getLev(i) >= 10 and i ~= id and i ~= clientNum) then -- Means admin to me, replace the value by yours
			et.trap_SendServerCommand(i, "chat \"("..nameF.."^7 -> "..nameT.."^7): "..str.."\"")
		end
	end
end

function	et_ClientCommand(clientNum, command)
	local	argc = et.trap_Argc()
	local	i = 0
	local	arg = {}

	while (i < argc) do
		arg[i + 1] = et.trap_Argv(i)
		i = i + 1
	end
	if (arg[1] == "say" and arg[2] ~= nil and string.find(arg[2], '!') == 1) then
		local	id, name = get_player_info(arg[3])
		local	flag = get_pl_flag_from_lev(getLev(clientNum))
		local	rank = get_pl_rank_from_lev(getLev(clientNum))
		
		if (handle_cmd(clientNum, flag, rank, arg, id) == 1) then return 1 end
	elseif (arg[1] == "m" and arg[2] ~= nil and arg[3] ~= nil) then	-- send it to admins
		catchPm(clientNum, arg)
	end
	return 0
end

------------------

function	removeClientGuid(id)
	for i, array in ipairs(client_guid) do
		if (id == array[1]) then
			table.remove(client_guid, i)
			return true
		end
	end
	return false
end

function	checkIfBanned(id)
	local	tmp = getFileContent("banlist.txt")
	if (tmp == nil) then return false, 0 end
	local	content = explode(tmp, "\n")
	local	clientInfo = {getName(id), getIp(id), getClientProGuid(id), string.lower(getCvar(id, "cl_guid"))}

	for j, str in ipairs(content) do
		local	hit = 0
		local	sep = getLastIndexOf(str, '|')
		local	name = string.sub(str, 2, sep - 1)
		str = string.sub(str, sep + 2)
		local	plInfo = explode(str, ' ')
		table.insert(plInfo, 1, name)				-- name, ip, etpro_guid, cl_guid

		for i, info in ipairs(clientInfo) do
			if (info == plInfo[i]) then
				hit = 1
			end
		end
		if (hit == 1) then
			local	remainingTime = tonumber(plInfo[5]) - (os.time() - tonumber(plInfo[6]))
			
			if (remainingTime <= 0) then
				local	tab = {nil, nil, plInfo[1]}
				unbanCmd(-1, nil, nil, nil, tab)
				return false
			end
			for i, info in ipairs(clientInfo) do
				if (info ~= nil and info ~= plInfo[i]) then
					if (i ~= 3 or (i == 3 and info ~= "0")) then -- etpro guid not registered
						plInfo[i] = info	-- update ban info
					end
				end
			end
			content[j] = "|" .. plInfo[1] .. "| "..plInfo[2].." "..plInfo[3].." "..plInfo[4].." "..plInfo[5].." "..plInfo[6]
			writeList(content, "banlist.txt")
			return true, remainingTime
		end
	end
	return false, 0
end

function	et_Print(text)
	if (cnoname == nil) then return end
	local	cleantext = et.Q_CleanStr(text)

	if (string.find(cleantext,"etpro IAC:") ~= nil) then 
		if (string.find(cleantext, "GUID") ~= nil) then
			local	guid = cleantext
			local	id = 0
			local	a, b = string.find(cleantext, '%[.-%]')
			
			cnoname = nil
			guid = string.sub(cleantext, a + 1, b - 1)
			a, b = string.find(cleantext, '%d')
			id = string.sub(cleantext, a, b)
			id = tonumber(id)

			local	banned, Rtime = checkIfBanned(id)
			if (banned == true) then
				et.trap_DropClient(id, "Banned by admin", Rtime)
				return
			end
			table.insert(client_guid, {id, guid})
		end	
	end
end

function 	et_ClientBegin(clientNum)
	local	gamestate = tonumber(et.trap_Cvar_Get("gamestate"))
	
	if (pass == 0) then	-- Also need to do it here because lua are loading when game starts
		sys_level = get_levels()
		if (sys_level == nil) then et.trap_SendServerCommand(-1, "chat \"FAIL\"") end
		get_pl_levels()
		pass = 1
	end
	if (eraseElem(co_client, clientNum) == true) then
		local	banned, Rtime = checkIfBanned(clientNum)
		if (banned == true) then
			et.trap_DropClient(clientNum, "Banned by admin", Rtime)
			return
		end
		local	name = getCvar(clientNum, "name")
		local	rank = get_pl_rank_from_lev(getLev(clientNum))

		cnoname = et.Info_ValueForKey(et.trap_GetUserinfo(clientNum), "name")
		et.trap_SendServerCommand(-1, "chat \"^7Welcome to "..name..", ^2"..rank.."\"")
	end
end

function 	et_ClientConnect(clientNum, firstTime, isBot)
	if (firstTime == 0) then return end
	get_pl_levels()	-- need to refresh the players level
	table.insert(co_client, clientNum)
end

function	et_ClientDisconnect(clientNum)
	get_pl_levels()	-- need to refresh the players level
	eraseElem(co_client, clientNum)
	removeClientGuid(clientNum)
end
