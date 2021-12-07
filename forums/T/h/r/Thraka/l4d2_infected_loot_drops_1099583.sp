/* Plugin Template generated by Pawn Studio */

#include <sourcemod>
#include <config>
#include <sdktools>

#define MODEL_NONE "none"
#define PLUGIN_VERSION "2.3d"

#define TEAM_INFECTED 3
#define TEAM_SURVIVOR 2

#define ZC_SMOKER		1
#define ZC_BOOMER		2
#define ZC_HUNTER		3
#define ZC_SPITTER		4
#define ZC_JOCKEY		5
#define ZC_CHARGER		6
#define ZC_WITCH		7
#define ZC_TANK			8
#define ZC_NOTINFECTED	9

#define FACTORYNAME_ITEM "item"
#define FACTORYNAME_WEAPON "weapon"
#define FACTORYNAME_UPGRADE "upgrade"
#define FACTORYNAME_MELEE "melee"
#define FACTORYNAME_INFECTED "infected"

public Plugin:myinfo = 
{
	name = "[L4D2] Infected Loot Drops",
	author = "Thraka",
	description = "Randomly (or not) generate items or infected to spawn when an infected dies.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1099583#"
}

// Globals
new Handle:g_hConfig = INVALID_HANDLE;
new Handle:g_hMaxSpawns = INVALID_HANDLE;
new Handle:g_hMaxSpawnsCounters = INVALID_HANDLE;
new bool:g_bWriteLog = false;
new bool:g_bPluginOn = true;

new Handle:CVAR_loot_cfg = INVALID_HANDLE;
new Handle:CVAR_loot_enabled = INVALID_HANDLE;
new Handle:CVAR_loot_log_enabled = INVALID_HANDLE;
new Handle:CVAR_loot_announce_mode = INVALID_HANDLE;

new bool:g_bSpawnUncommonSupported = false;
new g_iAnnounceMode = 0;

public APLRes:AskPluginLoad2(Handle:hPlugin, bool:isAfterMapLoaded, String:error[], err_max)
{
	// Require Left 4 Dead 2
	decl String:game_name[64];
	GetGameFolderName(game_name, sizeof(game_name));
	if (!StrEqual(game_name, "left4dead2", false))
	{
		Format(error, err_max, "Plugin only supports Left4Dead 2.");
		return APLRes_Failure;
	}
	return APLRes_Success;
}

public OnPluginStart()
{

	// Create and hook cvars
	CreateConVar("l4d2_loot_version", PLUGIN_VERSION, "Version of the infected loot drops plugins.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	CVAR_loot_cfg = CreateConVar("l4d2_loot_config_filename", "l4d2_infected_loot_drops_loot_settings.conf", "The name of the config file located in the cfg-sourcemod folder.", FCVAR_PLUGIN);
	CVAR_loot_enabled = CreateConVar("l4d2_loot_enabled", "1", "Is the infected loot plugin enabled or not.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	CVAR_loot_log_enabled = CreateConVar("l4d2_loot_logging", "0", "Enable logging.", FCVAR_PLUGIN);
	CVAR_loot_announce_mode = CreateConVar("l4d2_loot_announce_mode", "1", "Announces text to client teams when something spawns (if defined) 0 = Off; 1 = Hint text; 2 = Team chat.", FCVAR_PLUGIN);
	
	HookConVarChange(CVAR_loot_enabled, CvarOnOffChanged);
	HookConVarChange(CVAR_loot_log_enabled, CvarLoggingChanged);
	HookConVarChange(CVAR_loot_cfg, CvarConfigFileChanged);
	HookConVarChange(CVAR_loot_announce_mode, CvarAnnounceModeChanged);
	
	g_bPluginOn = GetConVarBool(CVAR_loot_enabled);
	g_bWriteLog = GetConVarBool(CVAR_loot_log_enabled);
	g_iAnnounceMode = GetConVarInt(CVAR_loot_announce_mode);
	
	// Reg commands
	RegConsoleCmd("loot_reloadconfig", Command_ReloadConfig, "Reloads the current conf file specified by the l4d2_loot_config_filename cvar.", ADMFLAG_KICK);
	RegConsoleCmd("loot_sim", Command_SimInfected, "Simulates an infected killed, so you can see what would happen.", ADMFLAG_KICK);
	RegConsoleCmd("loot_get_thingcount", Command_GetThingCount, "Gets how many times a specific thing has spawned.", ADMFLAG_KICK);
	RegConsoleCmd("loot_add_thingcount", Command_AddThingCount, "Adds 1 to a specific thing count of how many times it's spawned.", ADMFLAG_KICK);
	RegConsoleCmd("loot_get_thingmax", Command_GetThingMax, "Gets the max spawn setting of a thing.", ADMFLAG_KICK);
	RegConsoleCmd("loot_thing_ismaxed", Command_IsThingMaxed, "Informs you of if a thing has already reached the max spawn limit.", ADMFLAG_KICK);
	
	// Enable these for testing if you want.
	//RegConsoleCmd("loot_give", Command_Give, "Executes the give command on the current client.");
	//RegConsoleCmd("loot_spawn", Command_Spawn, "Executes the z_spawn command.");
	
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("round_start", Event_RoundStart);
	
	//Auto config
	AutoExecConfig(true, "l4d2_infected_loot_drops");
	
	LoadConfig();
}

public OnPluginEnd()
{
	CloseHandle(g_hConfig);
	g_hConfig = INVALID_HANDLE;
}

public OnMapStart()
{
	// Precache uncommon infected models
	PrecacheModel("models/infected/common_male_riot.mdl", true);
	PrecacheModel("models/infected/common_male_ceda.mdl", true);
	PrecacheModel("models/infected/common_male_clown.mdl", true);
	PrecacheModel("models/infected/common_male_mud.mdl", true);
	PrecacheModel("models/infected/common_male_roadcrew.mdl", true);
	PrecacheModel("models/infected/common_male_jimmy.mdl", true);
	PrecacheModel("models/infected/common_male_fallen_survivor.mdl", true);
	
	// Precache the other weapons
	PrecacheModel("models/v_models/v_rif_sg552.mdl", true);
	PrecacheModel("models/w_models/weapons/w_rifle_sg552.mdl", true);
	PrecacheModel("models/v_models/v_snip_awp.mdl", true);
	PrecacheModel("models/w_models/weapons/w_sniper_awp.mdl", true);
	PrecacheModel("models/v_models/v_snip_scout.mdl", true);
	PrecacheModel("models/w_models/weapons/w_sniper_scout.mdl", true);
	PrecacheModel("models/v_models/v_smg_mp5.mdl", true);
	PrecacheModel("models/w_models/weapons/w_smg_mp5.mdl", true);
	PrecacheModel("models/w_models/weapons/50cal.mdl", true);
	
	LoadConfig();
	
	// Configure uncommon support
	g_bSpawnUncommonSupported = FindConVar("l4d2_spawn_uncommons_version") != INVALID_HANDLE;
}

///////////////////
// Commands
///////////////////
public Action:Command_SimInfected(client, args)
{
	new String:arg[128]
	new Float:location[3];
	
	if (args == 1 && client != 0)
	{
		GetCmdArg(1, arg, sizeof(arg))
		GetClientAbsOrigin(client, location);
		InfectedKilled(arg, true, location);
	}
	else if (client == 0)
	{
		GetCmdArg(1, arg, sizeof(arg))
		InfectedKilled(arg, true, location);
	}
	else
	{
		ReplyToCommand(client, "Format: loot_sim classname.");
		ReplyToCommand(client, "For example:");
		ReplyToCommand(client, "loot_sim smoker");
		ReplyToCommand(client, "loot_sim tank");
		ReplyToCommand(client, "loot_sim global");
	}
}

public Action:Command_Give(client, args)
{
	if (args == 1 && client != 0)
	{
		new String:arg[128]
		GetCmdArg(1, arg, sizeof(arg))
		GiveItem(client, arg);
	}
	else
		ReplyToCommand(client, "Format: sm_give itemname");
}

public Action:Command_ReloadConfig(client, args)
{
	ReplyToCommand(client, "Loading config...");
	LoadConfig();
}

public Action:Command_Spawn(client, args)
{
	if (args == 1 && client != 0)
	{
		new String:arg[128]
		GetCmdArg(1, arg, sizeof(arg))
		
		new flags = GetCommandFlags("z_spawn");
    
		SetCommandFlags("z_spawn", flags & ~FCVAR_CHEAT);
		FakeClientCommand(GetAnyClient(), "z_spawn %s", arg);
		SetCommandFlags("z_spawn", flags);
		
	}
	else
		ReplyToCommand(client, "Format: sm_spawn classname");
}

public Action:Command_GetThingCount(client, args)
{
	if (args == 2)
	{
		new String:type[128]
		new String:name[128]
		
		GetCmdArg(1, type, sizeof(type))
		GetCmdArg(2, name, sizeof(name))
		
		ReplyToCommand(client, "Count: %i", GetThingCount(name, type));
	}
	else
	{
		ReplyToCommand(client, "Format: loot_get_thingcount [type] [name]");
		ReplyToCommand(client, "Example: loot_get_thingcount weapon weapon_smg");
	}
}

public Action:Command_AddThingCount(client, args)
{
	if (args == 3)
	{
		new String:type[85]
		new String:name[85]
		new String:count[85];
		GetCmdArg(1, type, sizeof(type))
		GetCmdArg(2, name, sizeof(name))
		GetCmdArg(3, count, sizeof(count));
		
		new countInt = StringToInt(count);
		
		ReplyToCommand(client, "Adding %i to count of %s.%s", countInt, type, name);
		AddThingCount(name, type, countInt);
	}
	else
	{
		ReplyToCommand(client, "Format: loot_add_thingcount [type] [name] [count]");
		ReplyToCommand(client, "Example: loot_add_thingcount weapon weapon_smg 2");
	}
}

public Action:Command_IsThingMaxed(client, args)
{
	if (args == 2)
	{
		new String:type[128]
		new String:name[128]
		
		GetCmdArg(1, type, sizeof(type))
		GetCmdArg(2, name, sizeof(name))
		
		if (IsThingMaxReached(name, type))
			ReplyToCommand(client, "YES: %s.%s limit has been reached.", type, name);
		else
			ReplyToCommand(client, "NO: %s.%s limit has not been reached.", type, name);
	}
	else
	{
		ReplyToCommand(client, "Format: loot_thing_ismaxed [type] [name]");
		ReplyToCommand(client, "Example: loot_thing_ismaxed weapon weapon_smg");
	}
}

public Action:Command_GetThingMax(client, args)
{
	if (args == 2)
	{
		new String:type[128]
		new String:name[128]
		
		GetCmdArg(1, type, sizeof(type))
		GetCmdArg(2, name, sizeof(name))
		
		ReplyToCommand(client, "Max allowed of %s.%s is %i", type, name, GetThingMax(name, type));
	}
	else
	{
		ReplyToCommand(client, "Format: loot_get_thingmax [type] [name]");
		ReplyToCommand(client, "Example: loot_get_thingmax weapon weapon_smg");
	}
}
	

	
//////////////////
// CVAR Related
///////////////////
public CvarOnOffChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_bPluginOn = GetConVarBool(CVAR_loot_enabled);
}
public CvarLoggingChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_bWriteLog = GetConVarBool(CVAR_loot_log_enabled);
}
public CvarConfigFileChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	LoadConfig();
}

public CvarAnnounceModeChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_iAnnounceMode = GetConVarInt(CVAR_loot_announce_mode);
}

///////////////////
// Events
///////////////////
public Action:Event_RoundStart(Handle:hEvent, const String:strName[], bool:DontBroadcast)
{
	Log(false, "New round detected, reloading config.");
	LoadConfig();
}

public Action:Event_PlayerDeath(Handle:hEvent, const String:strName[], bool:DontBroadcast)
{
	if (!g_bPluginOn || g_hConfig == INVALID_HANDLE)
		return Plugin_Continue;
	
	decl String:victimTypeBuffer[48];
	decl String:victimType[48];
	new Float:location[3]
	new clientId = 0;
	
	clientId = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if (clientId == 0) 
	{
		// Something died but wasn't a player (bot or not) what was it?
		clientId = GetEventInt(hEvent, "entityid");
		GetEntityNetClass(clientId, victimTypeBuffer, sizeof(victimTypeBuffer));
		StrToLower(victimTypeBuffer, victimType, sizeof(victimType));
	}
	else
	{			
		switch (GetEntProp(clientId, Prop_Send, "m_zombieClass"))
		{
			case ZC_SMOKER:
				victimType = "smoker";
			case ZC_BOOMER: 
				victimType = "boomer";
			case ZC_HUNTER:
				victimType = "hunter";
			case ZC_SPITTER:
				victimType = "spitter";
			case ZC_JOCKEY:
				victimType = "jockey";
			case ZC_CHARGER:
				victimType = "charger";
			case ZC_TANK:
				victimType = "tank";
			case ZC_NOTINFECTED:
				return Plugin_Continue;

		}
	}
	
	GetEntPropVector(clientId, Prop_Send, "m_vecOrigin", location)
	
	InfectedKilled(victimType, false, location);
	
	if (StrEqual(victimType, "smoker", false) ||
		StrEqual(victimType, "hunter", false) ||
		StrEqual(victimType, "charger", false) ||
		StrEqual(victimType, "boomer", false) ||
		StrEqual(victimType, "jockey", false) ||
		StrEqual(victimType, "spitter", false))
	{
		InfectedKilled("normal_infected", false, location);
	}
	else if (StrEqual(victimType, "tank", false) ||
			 StrEqual(victimType, "witch", false))
	{
		InfectedKilled("boss_infected", false, location);
	}
	
	InfectedKilled("global", false, location);
	
	return Plugin_Continue;
}

///////////////////
// Methods
///////////////////
LoadConfig()
{
	if (g_hConfig != INVALID_HANDLE)
	{
		CloseHandle(g_hConfig);
		g_hConfig = INVALID_HANDLE;
	}
	
	g_hMaxSpawns = INVALID_HANDLE;
	g_hMaxSpawnsCounters = INVALID_HANDLE;
	
	g_hConfig = ConfigCreate();
	
	decl String:fileName[256];
	decl String:fileNameCvar[256];
	
	GetConVarString(CVAR_loot_cfg, fileNameCvar, sizeof(fileNameCvar));
	Format(fileName, sizeof(fileName), "cfg/sourcemod/%s", fileNameCvar);
	
	new errLine;
	if (!ConfigReadFile(g_hConfig, fileName,_,_,errLine)) 
	{
		LogError("Config file (%s) missing or has error on line %i", fileName, errLine);
		PrintToServer("Config file (%s) missing or has error on line %i", fileName, errLine);
		
		if (g_hConfig != INVALID_HANDLE)
		{
			CloseHandle(g_hConfig);
			g_hConfig = INVALID_HANDLE;
		}
    }
	else
	{
		// Loaded correctly, lets find\create sections.
		g_hMaxSpawns = ConfigLookup(g_hConfig, "max_spawns");
		g_hMaxSpawnsCounters = ConfigSettingAdd(ConfigRootSetting(g_hConfig), "max_spawns_counters", ST_Group);
	}
}

bool:InfectedKilled(String:infected[], bool:sim, Float:location[3])
{
	Log(sim, "Looking up class: %s", infected);
	new Handle:hClass = ConfigLookup(g_hConfig, infected);
	
	// If the class is defined in the drop settings.
	if (hClass != INVALID_HANDLE)
	{
		new bool:foundNormalThing = false;
		new bool:foundForcedThing = false;
		
		new thingRepeat = ConfigSettingGetMemberInt(hClass, "repeat");
		new Handle:hDieCount = ConfigSettingGetMember(hClass, "dice");
		new dieCount = ConfigSettingLength(hDieCount);
		
		Log(sim, "Rolling for %i things", thingRepeat);
		
		// Loop the item count
		for (new thingCounter = 0; thingCounter < thingRepeat; thingCounter++)
		{
			Log(sim, "|-Rolling thing #%i", thingCounter + 1);
			new totalRoll = 0;
			
			// Roll each die
			Log(sim, "|--Rolling %i dice", dieCount);
			for (new dieCounter = 0; dieCounter < dieCount; dieCounter++)
			{
				new sides = ConfigSettingGetIntElement(hDieCount, dieCounter);
				new roll = GetRandomInt(1, sides);
				totalRoll += roll;
				Log(sim, "|---Die #%i (%i sides) rolled %i", dieCounter + 1, sides, roll);
			}
			
			Log(sim, "|--Total roll: %i", totalRoll);
			
			// Done rolling, look for item to spawn
			decl String:thingName[256];
			decl String:thingType[256];
			new thingSideMin;
			new thingSideMax;
			new nextIndex = 0;
			if (FindThing(hClass, totalRoll, nextIndex, thingName, thingType, thingSideMin, thingSideMax))
			{
				do
				{
					Log(sim, "|--Thing found: %s with range of %i-%i", thingName, thingSideMin, thingSideMax);
					
					//item - specific item or weapon entity no special properties
					//weapon - uses weapon_spawn. Give name of special weapon
					//upgrade - can be laser, incendiary, explosive, or any combination seperated by a -.
					//melee - Name of melee weapon, or any for random.
					//infected - z_spawn command parameters, or specials.
					
					if (!IsThingMaxReached(thingName, thingType))
					{
						foundNormalThing = true;
						
						if (StrEqual(thingType, FACTORYNAME_ITEM, false))
						{
							Log(sim, "|---Sending to item factory.");
							ItemFactoryCreate(thingName, sim, location);
						}
						else if (StrEqual(thingType, FACTORYNAME_INFECTED, false))
						{
							Log(sim, "|---Sending to infected factory.");
							InfectedFactoryCreate(thingName, sim);
						}
						else if (StrEqual(thingType, FACTORYNAME_WEAPON, false))
						{
							Log(sim, "|---Sending to weapon factory.");
							WeaponFactoryCreate(thingName, sim, location);
						}
						else if (StrEqual(thingType, FACTORYNAME_UPGRADE, false))
						{
							Log(sim, "|---Sending to upgrade factory.");
							UpgradeFactoryCreate(thingName, sim, location);
						}
						else if (StrEqual(thingType, FACTORYNAME_MELEE, false))
						{
							Log(sim, "|---Sending to upgrade factory.");
							MeleeFactoryCreate(thingName, sim, location);
						}
					}
					else
						Log(sim, "|---Skipping factory, thing max reached.");
				}
				while (FindThing(hClass, totalRoll, nextIndex, thingName, thingType, thingSideMin, thingSideMax))
			}
			else
				Log(sim, "|--No thing found");
		}
		
		// Handle (if any) all things that don't have rolls. For example, when a tank dies, you could force a witch to spawn.
		foundForcedThing = ForcedThings(sim, hClass, location);
		
		if (foundForcedThing || foundNormalThing)
		{
			decl String:infectedNote[256];
			decl String:survivorNote[256];
			new Handle:hInfectedNote = ConfigSettingGetMember(hClass, "tell_infected");
			new Handle:hSurvivorNote = ConfigSettingGetMember(hClass, "tell_survivors");
			
			if (hInfectedNote != INVALID_HANDLE)
				ConfigSettingGetString(hInfectedNote, infectedNote, sizeof(infectedNote));
			if (hSurvivorNote != INVALID_HANDLE)
				ConfigSettingGetString(hSurvivorNote, survivorNote, sizeof(survivorNote));
			
			Announce(infectedNote, survivorNote);
		}
		
		
	}
	else
		Log(sim, "Class not found");
}

bool:FindThing(Handle:hClass, rollAmount, &NextIndex, String:ThingName[], String:ThingType[], &ItemMin, &ItemMax)
{
	if (hClass != INVALID_HANDLE)
	{
		new Handle:hThings = ConfigSettingGetMember(hClass, "things");
		if (hThings != INVALID_HANDLE)
		{
			new thingMax = ConfigSettingLength(hThings);
			for (NextIndex; NextIndex < thingMax; NextIndex++)
			{
				new Handle:hThing = ConfigSettingGetElement(hThings, NextIndex);
				if (rollAmount >= ConfigSettingGetMemberInt(hThing, "min") &&
					rollAmount <= ConfigSettingGetMemberInt(hThing, "max"))
				{
					ConfigSettingGetString(ConfigSettingGetMember(hThing, "name"), ThingName, 256);
					ConfigSettingGetString(ConfigSettingGetMember(hThing, "type"), ThingType, 256);
					ItemMin = ConfigSettingGetInt(ConfigSettingGetMember(hThing, "min"));
					ItemMax = ConfigSettingGetInt(ConfigSettingGetMember(hThing, "max"));
					NextIndex++;
					return true;
				}
			}
		}
	}
	
	return false;
}

bool:ForcedThings(bool:sim, Handle:hClass, Float:location[3])
{
	new bool:returnValue = false;
	
	if (hClass != INVALID_HANDLE)
	{
		new Handle:hThings = ConfigSettingGetMember(hClass, "things_no_roll");
		if (hThings != INVALID_HANDLE)
		{
			new thingMax = ConfigSettingLength(hThings);
			Log(sim, "Forced thing count: %i", thingMax);
			
			for (new i = 0; i < thingMax; i++)
			{
				new Handle:hThing = ConfigSettingGetElement(hThings, i);
				
				decl String:thingName[256];
				decl String:thingType[256];
				
				ConfigSettingGetString(ConfigSettingGetMember(hThing, "name"), thingName, sizeof(thingName));
				ConfigSettingGetString(ConfigSettingGetMember(hThing, "type"), thingType, sizeof(thingType));

				Log(sim, "|-Forcing thing #%i - %s", i + 1, thingName);
				
				if (!IsThingMaxReached(thingName, thingType))
				{
					if (StrEqual(thingType, FACTORYNAME_ITEM, false))
					{
						Log(sim, "|---Sending to item factory.");
						ItemFactoryCreate(thingName, sim, location);
					}
					else if (StrEqual(thingType, FACTORYNAME_INFECTED, false))
					{
						Log(sim, "|---Sending to infected factory.");
						InfectedFactoryCreate(thingName, sim);
					}
					else if (StrEqual(thingType, FACTORYNAME_WEAPON, false))
					{
						Log(sim, "|---Sending to weapon factory.");
						WeaponFactoryCreate(thingName, sim, location);
					}
					else if (StrEqual(thingType, FACTORYNAME_UPGRADE, false))
					{
						Log(sim, "|---Sending to upgrade factory.");
						UpgradeFactoryCreate(thingName, sim, location);
					}
					else if (StrEqual(thingType, FACTORYNAME_MELEE, false))
					{
						Log(sim, "|---Sending to upgrade factory.");
						MeleeFactoryCreate(thingName, sim, location);
					}
					
					returnValue = true;
				}
				else
					Log(sim, "|---Skipping factory, thing max reached.");
			}
		}
		else
			Log(sim, "Skipping forced things, does not exist.");
	}
	
	return returnValue;
}

GiveItem(client, const String:itemName[])
{
	new flags = GetCommandFlags("give");
    
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "give %s", itemName);
	SetCommandFlags("give", flags);
}

ClientCheatCommand(client, const String:command[])
{
	new flags = GetCommandFlags(command);
    
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, command);
	SetCommandFlags(command, flags);
}

SpawnInfected(const String:name[])
{
	Log(false, "zspawn %s", name);
	new flags = GetCommandFlags("z_spawn");
    
	SetCommandFlags("z_spawn", flags & ~FCVAR_CHEAT);
	FakeClientCommand(GetAnyClient(), "z_spawn %s", name);
	SetCommandFlags("z_spawn", flags);
}

SpawnHorde(const String:name[])
{
	if (g_bSpawnUncommonSupported)
	{
		new flags = GetCommandFlags("sm_spawnuncommonhorde");
		
		SetCommandFlags("sm_spawnuncommonhorde", flags & ~ADMFLAG_CHEATS);
		FakeClientCommand(GetAnyClient(), "sm_spawnuncommonhorde %s", name);
		SetCommandFlags("sm_spawnuncommonhorde", flags);
	}
}

SpawnItem(Float:location[3] = NULL_VECTOR, Float:angles[3] = NULL_VECTOR, Float:velocity[3] = NULL_VECTOR, const String:name[], const String:model[] = MODEL_NONE, bool:dontSpawn = false)
{
	new entity = CreateEntityByName(name);
	
	if (entity != -1)
	{
		if (StrEqual(model, MODEL_NONE) == false)
			SetEntityModel(entity, model);
		
		DispatchKeyValue(entity, "spawnflags", "1");
		
		if (!dontSpawn)
		{
			DispatchSpawn(entity);
			ActivateEntity(entity);
			TeleportEntity(entity, location, angles, velocity);
		}
	}
	return entity;
}

SpawnItemFinish(entity, Float:location[3] = NULL_VECTOR, Float:angles[3] = NULL_VECTOR, Float:velocity[3] = NULL_VECTOR)
{
	DispatchSpawn(entity);
	ActivateEntity(entity);
	TeleportEntity(entity, location, angles, velocity);	
}

bool:IsThingMaxReached(String:name[], String:type[])
{
	if (g_hMaxSpawns != INVALID_HANDLE)
	{
		// Look up that thing and type. if 0 it was not found or set to 0 meaning don't max.
		new maxAmount = GetThingMax(name, type);
		
		// If -1, it's set to not allow.
		if (maxAmount == -1)
			return true;
		else if (maxAmount > 0)
		{
			// We have an amount, lets check for current 
			return GetThingCount(name, type) >= maxAmount
		}	
	}
	
	return false;
}

GetThingMax(String:name[], String:type[])
{
	if (g_hMaxSpawns != INVALID_HANDLE)
	{
		decl String:pathMax[256];
		Format(pathMax, sizeof(pathMax), "max_spawns.%s.%s", type, name);
		
		// Look up that thing and type. if 0 it was not found or set to 0 meaning don't max.
		return ConfigLookupInt(g_hConfig, pathMax);
	}
	
	return 0;
}


AddThingCount(String:name[], String:type[], countToAdd)
{
	if (g_hMaxSpawnsCounters != INVALID_HANDLE)
	{
		new Handle:hThing;
		new thingCount = GetThingCount(name, type, hThing);
		
		if (hThing != INVALID_HANDLE)
		{
			// Get the value, add one, return.
			ConfigSettingSetInt(hThing, thingCount + countToAdd);
		}
	}
}

GetThingCount(String:name[], String:type[], &Handle:thing = INVALID_HANDLE)
{
	if (g_hMaxSpawnsCounters != INVALID_HANDLE)
	{
		// Find or create type
		new Handle:hType = ConfigSettingGetMember(g_hMaxSpawnsCounters, type);
		
		if (hType == INVALID_HANDLE)
		{	
			hType = ConfigSettingAdd(g_hMaxSpawnsCounters, type, ST_Group);
			
			if (hType == INVALID_HANDLE)
			{
				Log(false, "Unable to create max_spawns_counters.%s", type);
				LogError("Unable to create max_spawns_counters.%s", type);
				thing = INVALID_HANDLE;
				return 0;
			}
		}
		
		// Find or create thing
		thing = ConfigSettingGetMember(hType, name);
		
		if (thing == INVALID_HANDLE)
		{	
			thing = ConfigSettingAdd(hType, name, ST_Int);
			
			if (thing == INVALID_HANDLE)
			{
				Log(false, "Unable to create max_spawns_counters.%s.%s", type, name);
				LogError("Unable to create max_spawns_counters.%s.%s", type, name);
				thing = INVALID_HANDLE;
			}
			
			// Return here. We created it or didn't. Still return 0 and whatever the handle is.
			return 0;
		}
		
		// It exists already, so grab and return.
		return ConfigSettingGetInt(thing);
	}
	
	thing = INVALID_HANDLE;
	return 0
}

Announce(String:infectedText[] = NULL_STRING, String:survivorText[] = NULL_STRING)
{
	if (g_iAnnounceMode != 0)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i) || IsFakeClient(i))
				continue;
			
			new team = GetClientTeam(i);
			
			if (!StrEqual(infectedText, NULL_STRING) && team == TEAM_INFECTED)
			{
				if (g_iAnnounceMode == 1)
					PrintHintText(i, infectedText);
				
				else if (g_iAnnounceMode == 2)
					PrintToChat(i, infectedText);
			}
			
			if (!StrEqual(survivorText, NULL_STRING) && team == TEAM_SURVIVOR)
			{
				if (g_iAnnounceMode == 1)
					PrintHintText(i, survivorText);
				
				else if (g_iAnnounceMode == 2)
					PrintToChat(i, survivorText);
			}
		}
	}
}

///////////////////
// Helpers
///////////////////
GetAnyClient()
{
	for (new i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i))
			return i;

	return 0;
}

Log(bool:sim, const String:format[], any:...)
{
	new String:newString[256];
	
	VFormat(newString, sizeof(newString), format, 3);
	
	if (sim)
	{
		PrintToChatAll(newString);
		PrintToServer(newString);
	}
	else if (g_bWriteLog)
	{
		LogMessage(newString);
		PrintToServer(newString);
	}

}

ConfigSettingGetMemberInt(Handle:setting, String:name[])
{
	new Handle:hMember = ConfigSettingGetMember(setting, name);
	if (hMember != INVALID_HANDLE)
		return ConfigSettingGetInt(hMember);
	else
		return -1;
}

stock StrToLower(const String:str[], String:buffer[], bufsize) {

    new n=0, x=0;
    while (str[n] != '\0' && x < (bufsize-1)) { // Make sure we are inside bounds

        new char = str[n++]; // Caching
    
        if (IsCharUpper(char)) { // Am I big ?
            char = CharToLower(char); // Big becomes low
        }

        buffer[x++] = char; // Write into our new string
    }

    buffer[x++] = '\0'; // Finalize with the end ( = always 0 for strings)

    return x; // return number of bytes written for later proove
}  

///////////////////
// Factories
///////////////////
ItemFactoryCreate(String:itemName[], bool:sim, Float:location[3])
{
	Log(sim, "Item Factory Creating: %s", itemName);
	
	if (!sim)
	{
		// Mod location so it spawns around mid level of model.
		location[2] += 10.0;
		
		// Create random velocity
		new Float:vel[3];
		vel[0] = GetRandomFloat(-80.0, 80.0);
		vel[1] = GetRandomFloat(-80.0, 80.0);
		vel[2] = GetRandomFloat(40.0, 80.0);
		
		SpawnItem(location, _, vel, itemName);
		AddThingCount(itemName, FACTORYNAME_ITEM, 1);
	}
}

WeaponFactoryCreate(String:name[], bool:sim, Float:location[3])
{
	Log(sim, "Weapon Factory Creating: %s", name);
	
	if (!sim)
	{
		new entity = SpawnItem(_, _, _, "weapon_spawn", _, true);
		
		// Mod location so it spawns around mid level of model.
		location[2] += 10.0;
		
		// Create random velocity
		new Float:vel[3];
		vel[0] = GetRandomFloat(-80.0, 80.0);
		vel[1] = GetRandomFloat(-80.0, 80.0);
		vel[2] = GetRandomFloat(40.0, 80.0);
		
		DispatchKeyValueVector(entity, "origin", location);
		DispatchKeyValue(entity, "weapon_selection", name);
		DispatchKeyValue(entity, "spawnflags", "1");
		DispatchKeyValue(entity, "solid", "6");
		DispatchKeyValue(entity, "count", "1");
		DispatchKeyValue(entity, "body", "0");
		DispatchKeyValue(entity, "spawn_without_director", "1");
		
		SpawnItemFinish(entity, _, _, vel);
		AddThingCount(name, FACTORYNAME_WEAPON, 1);
	}
}

MeleeFactoryCreate(String:name[], bool:sim, Float:location[3])
{
	Log(sim, "Melee Factory Creating: %s", name);
	
	if (!sim)
	{
		new entity = SpawnItem(_, _, _, "weapon_melee_spawn", _, true);
		
		// Mod location so it spawns around mid level of model.
		location[2] += 10.0;
		
		// Create random velocity
		new Float:vel[3];
		vel[0] = GetRandomFloat(-80.0, 80.0);
		vel[1] = GetRandomFloat(-80.0, 80.0);
		vel[2] = GetRandomFloat(40.0, 80.0);
		
		DispatchKeyValueVector(entity, "origin", location);
		DispatchKeyValue(entity, "spawnflags", "1");
		DispatchKeyValue(entity, "solid", "6");
		DispatchKeyValue(entity, "count", "1");
		DispatchKeyValue(entity, "body", "0");
		DispatchKeyValue(entity, "melee_weapon", name);
		
		SpawnItemFinish(entity, _, _, vel);
		AddThingCount(name, FACTORYNAME_MELEE, 1);
	}
}

UpgradeFactoryCreate(String:name[], bool:sim, Float:location[3])
{
	Log(sim, "Upgrade Factory Creating: %s", name);
	
	if (!sim)
	{
		new entity = SpawnItem(_, _, _, "upgrade_spawn", _, true);
		
		// Mod location so it spawns around mid level of model.
		location[2] += 10.0;
		
		// Create random velocity
		new Float:vel[3];
		vel[0] = GetRandomFloat(-80.0, 80.0);
		vel[1] = GetRandomFloat(-80.0, 80.0);
		vel[2] = GetRandomFloat(40.0, 80.0);
		
		DispatchKeyValueVector(entity, "origin", location);
		DispatchKeyValue(entity, "spawnflags", "1");
		
		// Do the individual upgrades
		if (StrContains(name, "laser", false) != -1)
		{
			DispatchKeyValue(entity, "laser_sight", "1");
			DispatchKeyValue(entity, "spawnflags", "2");
		}
		else
			DispatchKeyValue(entity, "laser_sight", "0");
			
		if (StrContains(name, "incendiary", false) != -1)
			DispatchKeyValue(entity, "upgradepack_incendiary", "1");
		else
			DispatchKeyValue(entity, "upgradepack_incendiary", "0");
			
		if (StrContains(name, "explosive", false) != -1)
			DispatchKeyValue(entity, "upgradepack_explosive", "1");
		else
			DispatchKeyValue(entity, "upgradepack_explosive", "0");
			
		SpawnItemFinish(entity, _, _, vel);
		AddThingCount(name, FACTORYNAME_UPGRADE, 1);
	}
}

InfectedFactoryCreate(String:name[], bool:sim, bool:skipCount = false)
{
	Log(sim, "Infected Factory Creating: %s", name);
	
	if (!sim)
	{
		// Check for any special commands
		if (StrEqual(name, "panic", false))
		{
			ClientCheatCommand(GetAnyClient(), "director_force_panic_event");
			
			if (!skipCount)
				AddThingCount(name, FACTORYNAME_INFECTED, 1);
		}
		else if (StrContains(name, "mob-", false) != -1)
		{
			decl String:parts[2][10];
			if (ExplodeString(name, "-", parts, 2, 10) > 1)
			{
				SpawnHorde(parts[1]);
			}
			
			if (!skipCount)
				AddThingCount(name, FACTORYNAME_INFECTED, 1);
		}
		else if (StrEqual(name, "infected-team", false))
		{
			InfectedFactoryCreate("boomer auto", sim, true);
			InfectedFactoryCreate("hunter auto", sim, true);
			InfectedFactoryCreate("smoker auto", sim, true);
			InfectedFactoryCreate("spitter auto", sim, true);
			InfectedFactoryCreate("jockey auto", sim, true);
			InfectedFactoryCreate("charger auto", sim, true);
			
			if (!skipCount)
				AddThingCount(name, FACTORYNAME_INFECTED, 1);
		}
		else if (StrEqual(name, "boss-team", false))
		{
			InfectedFactoryCreate("tank auto", sim, true);
			InfectedFactoryCreate("witch auto", sim, true);
			
			if (!skipCount)
				AddThingCount(name, FACTORYNAME_INFECTED, 1);
		}
		else
		{
			if (!skipCount)
				AddThingCount(name, FACTORYNAME_INFECTED, 1);
			
			ReplaceString(name, 256, "_", " ");
			
			SpawnInfected(name);
		}
	}
}
