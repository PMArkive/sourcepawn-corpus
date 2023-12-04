/* Plugin Template generated by Pawn Studio */

#include <sourcemod>
#include <sdktools_functions>
#pragma semicolon 1
#define PLUGIN_VERSION "1.06"
#define CVAR_FLAGS FCVAR_PLUGIN
#define LOG_ENABLED false
#define TANKRUSH_LOG_PATH		"logs\\tankrush.log"

public Plugin:myinfo = 
{
	name = "[L4D2] Tank Rush",
	author = "Grammernatzi & Psycho Dad",
	description = "Spawns an endless amount of tanks capped by a cvar limit",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=126984"
}

new numtanks;
new directornobossesorig;
new directornomobsorig;
new directornospecialsorig;
new commonlimitorig;
new Handle:maxtanks;
new Handle:tankrushon;
new Handle:tankinterval;
new Handle:tankforceinterval;
new Handle:tankdeathheal;
new Handle:tanksurvheal;
new Handle:tanksurvmaxhealth;
new Handle:tankhealth;
new Handle:safespawn;
new Handle:incapheal;
new Handle:suicideannounce;
new Handle:suicideannounceinterval;
new Handle:tankintervaltimer = INVALID_HANDLE;
new Handle:tankforceintervaltimer = INVALID_HANDLE;
new Handle:announcetimer = INVALID_HANDLE;
new bool:LeftSafeRoom;
new bool:firstrun;
new bool:cvarreset;
new bool:isIncapacitated[MAXPLAYERS+1];
new bool:IsRevive[MAXPLAYERS+1];
new bool:UnderRevive[MAXPLAYERS+1];

#if LOG_ENABLED
static String:	logfilepath[256];
#endif

public OnPluginStart()
{
	#if LOG_ENABLED
	BuildPath(Path_SM, logfilepath, sizeof(logfilepath), TANKRUSH_LOG_PATH);
	#endif

	CreateConVar("tankrush_version", PLUGIN_VERSION, "Tankrush_Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	maxtanks = CreateConVar("tankrush_maxtanks", "20", "Maximum amount of tanks in tank rush", CVAR_FLAGS, true, 0.0);
	tankrushon = CreateConVar("tankrush_on","1", "Is tank rush on? Default = 1", CVAR_FLAGS, true, 0.0);
	tankinterval = CreateConVar("tankrush_interval","12", "How many seconds till another tank spawns.", CVAR_FLAGS, true, 0.0);
	tankforceinterval = CreateConVar("tankrush_force_interval","30", "How many seconds check the plugin that there's a Tank in game and if isn't force spawn one.", CVAR_FLAGS, true, 0.0);
	tankdeathheal = CreateConVar("tankrush_heal","1", "Will survivors be healed on tank death? Default = 1", CVAR_FLAGS, true, 0.0);
	incapheal = CreateConVar("tankrush_incapheal","1", "Will survivors get up on tank death if they incapped? Default = 1", CVAR_FLAGS, true, 0.0);
	safespawn = CreateConVar("tankrush_safe_spawn", "0", "Disable/Enable Tank spawning while survivors are in safe room", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	tanksurvheal = CreateConVar("tankrush_survheal","100", "How much health will Survivors get when tank dies?", CVAR_FLAGS, true, 0.0);
	tanksurvmaxhealth = CreateConVar("tankrush_survmaxhealth","100", "What is the Survivors max in-game health?", CVAR_FLAGS, true, 0.0);
	tankhealth = CreateConVar("tankrush_tankhealth","4000", "What is the Tank in-game health?", CVAR_FLAGS, true, 0.0);
	suicideannounce = CreateConVar("tankrush_suicideannounce","1", "Do you want announcement?", CVAR_FLAGS, true, 0.0);
	suicideannounceinterval = CreateConVar("tankrush_suicideannounceinterval","60", "How many seconds between announcements?", CVAR_FLAGS, true, 0.0);
	
	LeftSafeRoom = false;
	cvarreset = false;
	
	HookConVarChange(maxtanks, CVARChanged);
	HookConVarChange(tankrushon, CVARChanged);
	HookConVarChange(tankinterval, TankIntervalChanged);
	HookConVarChange(tankforceinterval, TankForceIntervalChanged);
	HookConVarChange(tankdeathheal, CVARChanged);
	HookConVarChange(incapheal, CVARChanged);
	HookConVarChange(safespawn, CVARChanged);
	HookConVarChange(tanksurvheal, CVARChanged);
	HookConVarChange(tanksurvmaxhealth, CVARChanged);
	HookConVarChange(tankhealth, CVARChanged);
	HookConVarChange(suicideannounce, AnnounceChanged);
	HookConVarChange(suicideannounceinterval, AnnounceIntervalChanged);

	HookEvent("tank_spawn", TankSpawn);	
	HookEvent("tank_killed", TankKill);
	HookEvent("round_start", RoundStart, EventHookMode_Pre);
	HookEvent("round_end", RoundEnd, EventHookMode_Pre);
	HookEvent("revive_begin", StartRevive, EventHookMode_Pre);
	HookEvent("revive_end", EndRevive);
	HookEvent("revive_success", EndRevive);

	RegConsoleCmd("sm_suicide", Suicide);
		
	AutoExecConfig(true,"L4DTankrush");
	
}

public OnPluginEnd()
{
	if (cvarreset)
	{
		SetConVarInt(FindConVar("director_no_bosses"), directornobossesorig);
		SetConVarInt(FindConVar("director_no_mobs"), directornomobsorig);
		SetConVarInt(FindConVar("director_no_specials"), directornospecialsorig);
		SetConVarInt(FindConVar("z_common_limit"), commonlimitorig);
		
		cvarreset = false;
	}
}

public TankIntervalChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	SetConVarInt(FindConVar("tankrush_interval"), GetConVarInt(tankinterval));

	if (tankintervaltimer != INVALID_HANDLE)
	{
		CloseHandle(tankintervaltimer);
		tankintervaltimer = CreateTimer(GetConVarFloat(tankinterval),TimerUpdate, _, TIMER_REPEAT);
	}
	
}

public TankForceIntervalChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	SetConVarInt(FindConVar("tankrush_force_interval"), GetConVarInt(tankforceinterval));

	if (tankforceintervaltimer != INVALID_HANDLE)
	{
		CloseHandle(tankforceintervaltimer);
		tankforceintervaltimer = CreateTimer(GetConVarFloat(tankforceinterval),TimerUpdate, _, TIMER_REPEAT);
	}
	
}

public AnnounceChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	SetConVarInt(FindConVar("tankrush_suicideannounce"), GetConVarInt(suicideannounce));
	
	if (GetConVarBool(suicideannounce))
	{
		announcetimer = CreateTimer(GetConVarFloat(suicideannounceinterval),SuicideAnnouncement, _,TIMER_REPEAT);
	}
	else
	{
		CloseHandle(announcetimer);
		announcetimer = INVALID_HANDLE;
	}
	
}

public AnnounceIntervalChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	SetConVarInt(FindConVar("tankrush_suicideannounceinterval"), GetConVarInt(suicideannounceinterval));
	
	if (announcetimer != INVALID_HANDLE)
	{
		CloseHandle(announcetimer);
		announcetimer = CreateTimer(GetConVarFloat(suicideannounceinterval),SuicideAnnouncement, _,TIMER_REPEAT);
	}
	
}

public CVARChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	UpdateConVars();
}

UpdateConVars()
{
	SetConVarInt(FindConVar("tankrush_maxtanks"), GetConVarInt(maxtanks));
	SetConVarInt(FindConVar("tankrush_on"), GetConVarInt(tankrushon));
	SetConVarInt(FindConVar("tankrush_heal"), GetConVarInt(tankdeathheal));
	SetConVarInt(FindConVar("tankrush_incapheal"), GetConVarInt(incapheal));
	SetConVarInt(FindConVar("tankrush_safe_spawn"), GetConVarInt(safespawn));
	SetConVarInt(FindConVar("tankrush_survheal"), GetConVarInt(tanksurvheal));
	SetConVarInt(FindConVar("tankrush_survmaxhealth"), GetConVarInt(tanksurvmaxhealth));
	SetConVarInt(FindConVar("tankrush_tankhealth"), GetConVarInt(tankhealth));
	
}

public OnMapStart()
{
	if (GetConVarBool(tankrushon))
	{
		tankintervaltimer = CreateTimer(GetConVarFloat(tankinterval),TimerUpdate, _, TIMER_REPEAT);
		tankforceintervaltimer = CreateTimer(GetConVarFloat(tankforceinterval),IsTankInGame, _, TIMER_REPEAT);
		
		if (GetConVarBool(suicideannounce))
		{
			announcetimer = CreateTimer(GetConVarFloat(suicideannounceinterval),SuicideAnnouncement, _,TIMER_REPEAT);
		}
	}
}

public OnMapEnd()
{
	if (GetConVarBool(tankrushon))
	{
		if (tankintervaltimer != INVALID_HANDLE)
		{
			CloseHandle(tankintervaltimer);
			tankintervaltimer = INVALID_HANDLE;
		}
		
		if (tankforceintervaltimer != INVALID_HANDLE)
		{	
			CloseHandle(tankforceintervaltimer);
			tankforceintervaltimer = INVALID_HANDLE;
		}
		
		if (announcetimer != INVALID_HANDLE)
		{
			CloseHandle(announcetimer);
			announcetimer = INVALID_HANDLE;
		}
	}
	
	numtanks = 0;
	LeftSafeRoom = false;
	firstrun = false;
}

public Action:RoundStart(Handle:event, String:event_name[], bool:dontBroadcast)
{
	LeftSafeRoom = GetConVarBool(safespawn);
	
	new Handle:Plugin_ClientPref = FindPluginByFile("L4DTankrush.smx");
	new PluginStatus:Plugin_ClientPref_Status = GetPluginStatus(Plugin_ClientPref);
	
	if (GetConVarBool(tankrushon) && Plugin_ClientPref_Status == Plugin_Running)
	{
		if (!LeftSafeRoom)
		{
			CreateTimer(1.0, PlayerLeftStart);
		}
		firstrun = true;
	}
	else if (cvarreset && (!GetConVarBool(tankrushon) || Plugin_ClientPref_Status != Plugin_Running))
	{
		SetConVarInt(FindConVar("director_no_bosses"), directornobossesorig);
		SetConVarInt(FindConVar("director_no_mobs"), directornomobsorig);
		SetConVarInt(FindConVar("director_no_specials"), directornospecialsorig);
		SetConVarInt(FindConVar("z_common_limit"), commonlimitorig);
		
		cvarreset = false;
	}
}

public Action:RoundEnd(Handle:event, String:event_name[], bool:dontBroadcast)
{
	numtanks = 0;
	LeftSafeRoom = false;
	firstrun = false;
}

public StartRevive (Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "subject"));
	IsRevive[client] = true;
}

public EndRevive (Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "subject"));
	IsRevive[client] = false;
	
	if (UnderRevive[client])
	{
		CreateTimer(0.1, SetHP, client);
		UnderRevive[client] = false;
	}
}

public Action:Suicide(client, args)
{
	if (IsValidClient(client) && GetClientTeam(client) == 2)
	{
		new String:name[32];
		GetClientName(client, name, sizeof(name));
		PrintToChatAll("[R.I.P.] %s commit suicide!", name);
		ForcePlayerSuicide(client);
	}
}

public Action:SuicideAnnouncement(Handle:timer)
{
	PrintToChatAll("[Tank Rush] Type !suicide to kill yourself!");
}


public Action:TimerUpdate(Handle:timer)
{
	if (GetConVarBool(tankrushon))
	{
		if (firstrun)
		{
			new Handle:directornobosses;
			new Handle:directornomobs;
			new Handle:directornospecials;
			new Handle:commonlimit;
			directornobosses = FindConVar("director_no_bosses");
			directornomobs = FindConVar("director_no_mobs");
			directornospecials = FindConVar("director_no_specials");
			commonlimit = FindConVar("z_common_limit");
			directornobossesorig = GetConVarInt(directornobosses);
			directornomobsorig = GetConVarInt(directornomobs);
			directornospecialsorig = GetConVarInt(directornospecials);
			commonlimitorig = GetConVarInt(commonlimit);
			SetConVarInt(directornobosses, 1);
			SetConVarInt(directornomobs, 1);
			SetConVarInt(directornospecials, 1);
			SetConVarInt(commonlimit, 0);
			
			cvarreset = true;			
			firstrun = false;
		}
	
		new client = Misc_GetAnyClient();
		if (client > 0)
		{
			if (LeftSafeRoom)
			{
				if (numtanks < GetConVarInt(maxtanks))
				{	
					new flags = GetCommandFlags("z_spawn");
					SetCommandFlags("z_spawn", flags & ~FCVAR_CHEAT);
				
					FakeClientCommand(client, "z_spawn tank auto");
					numtanks += 1;
				
					SetCommandFlags("z_spawn", flags|FCVAR_CHEAT);
				}
			}
		}
	}
}

public Action:IsTankInGame(Handle:timer)
{
	if ((GetConVarBool(tankrushon)) && (LeftSafeRoom))
	{
		new client = Misc_GetAnyClient();
		if (client > 0)
		{
			new tanknum;
			tanknum = 0;
			for (new i = 1; i <= MaxClients; i++) 
			{
				if (IsClientInGame(i) && IsPlayerAlive(i) && IsPlayerTank(i))
				{
					tanknum += 1;
				}
			}
			if (tanknum <= 0)
			{
				new flags = GetCommandFlags("z_spawn");
				SetCommandFlags("z_spawn", flags & ~FCVAR_CHEAT);
			
				FakeClientCommand(client, "z_spawn tank auto");
				numtanks = 1;
			
				SetCommandFlags("z_spawn", flags|FCVAR_CHEAT);
			}
		}
	}
}

public Action:TankSpawn(Handle:event, String:event_name[], bool:dontBroadcast)
{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(IsValidEntity(client) && IsClientInGame(client))
		{
			SetEntityHealth(client, GetConVarInt(tankhealth));
		}
}

public Action:TankKill(Handle:event, String:event_name[], bool:dontBroadcast)
{
	numtanks -= 1;
	if (GetConVarBool(tankdeathheal))
	{
		for (new i=1; i<=MaxClients; i++)
		{
			if (IsValidClient(i) && GetClientTeam(i) == 2)
			{
				if (!IsRevive[i])
				{
					if (GetEntProp(i, Prop_Send, "m_isIncapacitated", 1) && (GetConVarBool(incapheal)))
					{
						isIncapacitated[i] = true;
						SetEntProp(i, Prop_Send, "m_isIncapacitated", 0);
						
						if (GetEntProp(i, Prop_Send, "m_isHangingFromLedge", 1))
						{
							SetEntProp(i, Prop_Send, "m_isHangingFromLedge", 0);
							SetEntProp(i, Prop_Send, "m_isFallingFromLedge", 0);
						}
					}
					CreateTimer(0.1, SetHP, i);
				}
				else
				{
					UnderRevive[i] = true;
				}
			}
		}
	}
}

public Action:SetHP(Handle:timer, any:client)
{
	new temphpoffset = FindSendPropOffs("CTerrorPlayer","m_healthBuffer");
	SetEntDataFloat(client, temphpoffset, 0.0, true);

	new HP;

	if (isIncapacitated[client])
	{
		HP = 1;
		isIncapacitated[client] = false;
	}
	else
	{
		HP = GetClientHealth(client);
	}
	
	new Heal = GetConVarInt(tanksurvheal);
	new MaxHP = GetConVarInt(tanksurvmaxhealth);

	if ((HP + Heal) <= MaxHP)
	{
		SetEntityHealth(client, HP + Heal);
	}	
	else if (((HP + Heal) > MaxHP) && (HP < MaxHP))
	{
		SetEntityHealth(client, MaxHP);
	}
}

public Action:PlayerLeftStart(Handle:Timer) // code from Tordecybombo
{
	if (LeftStartArea())
	{
		if (!LeftSafeRoom)
		{
			LeftSafeRoom = true;
			CreateTimer(1.0,TimerUpdate);
		}
	}
	else
	{
		CreateTimer(1.0, PlayerLeftStart);
	}
	
	return Plugin_Continue;
}

bool:LeftStartArea() // code from Tordecybombo
{
	new ent = -1, maxents = GetMaxEntities();
	for (new i = MaxClients+1; i <= maxents; i++)
	{
		if (IsValidEntity(i))
		{
			decl String:netclass[64];
			GetEntityNetClass(i, netclass, sizeof(netclass));
			
			if (StrEqual(netclass, "CTerrorPlayerResource"))
			{
				ent = i;
				break;
			}
		}
	}
	
	if (ent > -1)
	{
		new offset = FindSendPropInfo("CTerrorPlayerResource", "m_hasAnySurvivorLeftSafeArea");
		if (offset > 0)
		{
			if (GetEntData(ent, offset))
			{
				if (GetEntData(ent, offset) == 1) return true;
			}
		}
	}
	return false;
}

public IsValidClient(i) // code from Mortiegama
{
	if (i == 0)
		return false;

	if (!IsClientConnected(i))
		return false;
	
//	if (IsFakeClient(i))
//		return false;
	
	if (!IsClientInGame(i))
		return false;
	
	if (!IsPlayerAlive(i))
		return false;

	if (!IsValidEntity(i))
		return false;

	return true;
}

Misc_GetAnyClient() // code from Mecha the Slag
{
    for (new i = 1; i <= MaxClients; i++) 
	{
        if (IsClientInGame(i) && IsPlayerAlive(i)) 
		{
            return i;
        }
    }
    return 0;
}

stock bool:IsPlayerTank(i) // code from Mecha the Slag
{
    new String:model[128]; 
    GetClientModel(i, model, sizeof(model));
    if (StrContains(model, "hulk", false) <= 0)  return false;
    return true;
}