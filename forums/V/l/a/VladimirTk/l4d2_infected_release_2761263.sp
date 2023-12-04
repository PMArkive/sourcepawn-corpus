/* Plugin Template generated by Pawn Studio */
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

#define CVAR_FLAGS FCVAR_NONE|FCVAR_NOTIFY
#define PLUGIN_VERSION "1.3a"
#define INFECTEDTEAM 3
#define ZOMBIECLASS_SMOKER	1
#define ZOMBIECLASS_BOOMER	2
#define ZOMBIECLASS_HUNTER	3
#define ZOMBIECLASS_SPITTER	4
#define ZOMBIECLASS_JOCKEY	5
#define ZOMBIECLASS_CHARGER	6

ConVar g_hConVar_JockeyReleaseOn;
ConVar g_hConVar_HunterReleaseOn;
ConVar g_hConVar_ChargerReleaseOn;
ConVar g_hConVar_ChargerChargeInterval;
ConVar g_hConVar_JockeyAttackDelay;
ConVar g_hConVar_HunterAttackDelay;
ConVar g_hConVar_ChargerAttackDelay;
bool g_isJockeyEnabled;
bool g_isHunterEnabled;
bool g_isChargerEnabled;

bool g_ButtonDelay[MAXPLAYERS+1];

public Plugin myinfo = 
{
	name = "[L4D2] Infected Release",
	author = "Thraka",
	description = "Allows infected players to release victims with the melee button.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=109715"
}

public APLRes AskPluginLoad2(Handle hPlugin, bool isAfterMapLoaded, char[] error, int err_max)
{
	// Require Left 4 Dead 2
	char game_name[64];
	GetGameFolderName(game_name, sizeof(game_name));
	if (!StrEqual(game_name, "left4dead2", false))
	{
		Format(error, err_max, "Plugin only supports Left4Dead 2.");
		return APLRes_Failure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("l4d2_infected_release_ver", PLUGIN_VERSION, "Version of the infected release plugin.", FCVAR_NONE|FCVAR_SPONLY|FCVAR_NOTIFY);

	g_hConVar_JockeyReleaseOn = CreateConVar("l4d2_jockey_dismount_on", "1", "Jockey dismount is on or off. 1 = on", CVAR_FLAGS);
	g_hConVar_HunterReleaseOn = CreateConVar("l4d2_hunter_release_on", "1", "Hunter release is on or off. 1 = on", CVAR_FLAGS);
	g_hConVar_ChargerReleaseOn = CreateConVar("l4d2_charger_release_on", "1", "Charger release is on or off. 1 = on", CVAR_FLAGS);
	g_hConVar_JockeyAttackDelay = CreateConVar("l4d2_jockey_attackdelay", "1.5", "After dismounting with the jockey, how long can the player not use attack1 and attack2", CVAR_FLAGS, true);
	g_hConVar_HunterAttackDelay = CreateConVar("l4d2_hunter_attackdelay", "1.5", "After dismounting with the hunter, how long can the player not use attack1 and attack2", CVAR_FLAGS, true);
	g_hConVar_ChargerAttackDelay = CreateConVar("l4d2_charger_attackdelay", "1.5", "After dismounting with the charger, how long can the player not use attack1 and attack2", CVAR_FLAGS, true);
	
	g_hConVar_ChargerChargeInterval = FindConVar("z_charge_interval");
	
	HookConVarChange(g_hConVar_JockeyReleaseOn, CVarChange_JockeyRelease);
	HookConVarChange(g_hConVar_HunterReleaseOn, CVarChange_HunterRelease);
	HookConVarChange(g_hConVar_ChargerReleaseOn, CVarChange_ChargerRelease);
	
	AutoExecConfig(true, "l4d2_infected_release");
	
	SetJockeyRelease();
	SetHunterRelease();
	SetChargerRelease();
}

/*
* ===========================================================================================================
* ===========================================================================================================
* 
* CVAR Change events
* 
* ===========================================================================================================
* ===========================================================================================================
*/

public void CVarChange_JockeyRelease(ConVar convar, const char[] oldValue, const char[] newValue)
{
	SetJockeyRelease();
}

public void CVarChange_HunterRelease(ConVar convar, const char[] oldValue, const char[] newValue)
{
	SetHunterRelease();
}

public void CVarChange_ChargerRelease(ConVar convar, const char[] oldValue, const char[] newValue)
{
	SetChargerRelease();
}

void SetJockeyRelease()
{
	g_isJockeyEnabled = GetConVarInt(g_hConVar_JockeyReleaseOn) == 1;
}

void SetHunterRelease()
{
	g_isHunterEnabled = GetConVarInt(g_hConVar_HunterReleaseOn) == 1;
}

void SetChargerRelease()
{
	g_isChargerEnabled = GetConVarInt(g_hConVar_ChargerReleaseOn) == 1;
}

/*
* ===========================================================================================================
* ===========================================================================================================
* 
* Normal Hooks\Events
* 
* ===========================================================================================================
* ===========================================================================================================
*/

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if (client == 0)
		return Plugin_Continue;
	
	if (buttons & IN_ATTACK2 && !g_ButtonDelay[client])
	{
		if (GetClientTeam(client) == INFECTEDTEAM)
		{
			int zombieClass = GetEntProp(client, Prop_Send, "m_zombieClass");
			if (zombieClass == ZOMBIECLASS_JOCKEY && g_isJockeyEnabled)
			{
				int h_vic = GetEntPropEnt(client, Prop_Send, "m_jockeyVictim");
				if (IsValidEntity(h_vic) && h_vic != 0)
				{
					ExecuteCommand(client, "dismount");
					
					CreateTimer(GetConVarFloat(g_hConVar_JockeyAttackDelay), ResetDelay, client)
					g_ButtonDelay[client] = true;
				}
			}
			else if (zombieClass == ZOMBIECLASS_HUNTER && g_isHunterEnabled)
			{
				int h_vic = GetEntPropEnt(client, Prop_Send, "m_pounceVictim");
				if (IsValidEntity(h_vic) && h_vic != 0)
				{
					CallOnPounceEnd(client);

					CreateTimer(GetConVarFloat(g_hConVar_HunterAttackDelay), ResetDelay, client)
					g_ButtonDelay[client] = true;
				}
			}
			else if (zombieClass == ZOMBIECLASS_CHARGER && g_isChargerEnabled)
			{
				int h_vic = GetEntPropEnt(client, Prop_Send, "m_pummelVictim");
				if (IsValidEntity(h_vic) && h_vic != 0)
				{
					CallOnPummelEnded(client);
					
					if (g_hConVar_ChargerChargeInterval != INVALID_HANDLE)
						CallResetAbility(client, GetConVarFloat(g_hConVar_ChargerChargeInterval));
					
					CreateTimer(GetConVarFloat(g_hConVar_ChargerAttackDelay), ResetDelay, client)
					g_ButtonDelay[client] = true;
				}
			}
		}
	}
	
	// If delayed, don't let them click
	if (buttons & IN_ATTACK && g_ButtonDelay[client])
	{
		buttons &= ~IN_ATTACK;
	}
	
	// If delayed, don't let them click
	if (buttons & IN_ATTACK2 && g_ButtonDelay[client])
	{
		buttons &= ~IN_ATTACK2;
	}
	
	return Plugin_Continue;
}


public Action ResetDelay(Handle timer, any client)
{
	g_ButtonDelay[client] = false;
}
/*
* ===========================================================================================================
* ===========================================================================================================
* 
* Private Methods
* 
* ===========================================================================================================
* ===========================================================================================================
*/

void ExecuteCommand(int Client, char[] strCommand)
{
	int flags = GetCommandFlags(strCommand);
	SetCommandFlags(strCommand, flags & ~FCVAR_CHEAT);
	FakeClientCommand(Client, "%s", strCommand);
	SetCommandFlags(strCommand, flags);
}

void CallOnPummelEnded(int client)
{
    static Handle hOnPummelEnded=INVALID_HANDLE;
    if (hOnPummelEnded==INVALID_HANDLE)
	{
        Handle hConf = INVALID_HANDLE;
        hConf = LoadGameConfigFile("l4d2_infected_release");
        StartPrepSDKCall(SDKCall_Player);
        PrepSDKCall_SetFromConf(hConf, SDKConf_Signature, "CTerrorPlayer::OnPummelEnded");
        PrepSDKCall_AddParameter(SDKType_Bool,SDKPass_Plain);
        PrepSDKCall_AddParameter(SDKType_CBasePlayer,SDKPass_Pointer,VDECODE_FLAG_ALLOWNULL);
        hOnPummelEnded = EndPrepSDKCall();
        CloseHandle(hConf);
        if (hOnPummelEnded == INVALID_HANDLE)
		{
            SetFailState("Can't get CTerrorPlayer::OnPummelEnded SDKCall!");
            return;
        }            
    }
    SDKCall(hOnPummelEnded,client,true,-1);
}

void CallOnPounceEnd(int client)
{
    static Handle hOnPounceEnd=INVALID_HANDLE;
    if (hOnPounceEnd == INVALID_HANDLE)
	{
        Handle hConf = INVALID_HANDLE;
        hConf = LoadGameConfigFile("l4d2_infected_release");
        StartPrepSDKCall(SDKCall_Player);
        PrepSDKCall_SetFromConf(hConf, SDKConf_Signature, "CTerrorPlayer::OnPounceEnd");
        hOnPounceEnd = EndPrepSDKCall();
        CloseHandle(hConf);
        if (hOnPounceEnd == INVALID_HANDLE)
		{
            SetFailState("Can't get CTerrorPlayer::OnPounceEnd SDKCall!");
            return;
        }            
    }
    SDKCall(hOnPounceEnd,client);
} 

void CallResetAbility(int client, float time)
{
	static Handle hStartActivationTimer = INVALID_HANDLE;
	if (hStartActivationTimer == INVALID_HANDLE)
	{
		Handle hConf = INVALID_HANDLE;
		hConf = LoadGameConfigFile("l4d2_infected_release");

		StartPrepSDKCall(SDKCall_Entity);

		PrepSDKCall_SetFromConf(hConf, SDKConf_Signature, "CBaseAbility::StartActivationTimer");
		PrepSDKCall_AddParameter(SDKType_Float,SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_Float,SDKPass_Plain);

		hStartActivationTimer = EndPrepSDKCall();
		CloseHandle(hConf);
		
		if (hStartActivationTimer == INVALID_HANDLE)
		{
			SetFailState("Can't get CBaseAbility::StartActivationTimer SDKCall!");
			return;
		}            
	}
	int AbilityEnt = GetEntPropEnt(client, Prop_Send, "m_customAbility");
	SDKCall(hStartActivationTimer, AbilityEnt, time, 0.0);
}