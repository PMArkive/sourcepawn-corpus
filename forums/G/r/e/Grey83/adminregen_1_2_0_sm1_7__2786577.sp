#if SOURCEMOD_V_MAJOR == 1 && SOURCEMOD_V_MINOR < 7
	#error "You must use SM1.7 or newer to compile this plugin"
#endif

#pragma semicolon 1
#pragma newdecls required

static const char
	PL_NAME[]	= "Admin Regenerate",
	PL_VER[]	= "1.2.0 SM1.7+ (rewritten by Grey83)";

Handle
	hTimer;
bool
	bRegen[MAXPLAYERS+1];
int
	iMaxHP,
	iAdd;
float
	fCD;

public Plugin myinfo =
{
	name		= PL_NAME,
	version		= PL_VER,
	description	= "Lets admins regenerate their health with a command",
	author		= "joac1144/Zyanthius",
	url			= "https://forums.alliedmods.net/showthread.php?t=236606"
}

public void OnPluginStart()
{
	RegAdminCmd("sm_adminregen", Cmd_Regeneration, ADMFLAG_SLAY, "Activates regeneration.");

	CreateConVar("adminregen_version", PL_VER, PL_NAME);

	ConVar cvar;
	cvar = CreateConVar("adminregen_maxhp", "100", "Maximum health you can have by regenerating", _, true, 1.0);
	cvar.AddChangeHook(CVarChange_MaxHP);
	iMaxHP = cvar.IntValue;

	cvar = CreateConVar("adminregen_health", "2", "Amount of health to regenerate", _, true, 1.0);
	cvar.AddChangeHook(CVarChange_Add);
	iAdd = cvar.IntValue;

	cvar = CreateConVar("adminregen_time", "2.0", "Amount of time (in seconds) between each health", _, true, 0.1);
	cvar.AddChangeHook(CVarChange_CD);
	fCD = cvar.FloatValue;

	AutoExecConfig(true, "plugin.adminregen");
}

public void CVarChange_MaxHP(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	iMaxHP = cvar.IntValue;
}

public void CVarChange_Add(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	iAdd = cvar.IntValue;
}

public void CVarChange_CD(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	fCD = cvar.FloatValue;

	OnMapEnd();
	hTimer = CreateTimer(fCD, Timer_Regen, _, TIMER_REPEAT);
}

public Action Cmd_Regeneration(int client, int args)
{
	if(!client || !IsClientInGame(client) || !IsPlayerAlive(client))
		return Plugin_Handled;

	if(bRegen[client])
	{
		ReplyToCommand(client, "[SM] You have deactivated regeneration!");
		PrintToServer("[SM] %N has deactivated regeneration!", client);
		bRegen[client] = false;
		return Plugin_Handled;
	}

	int hp = GetClientHealth(client);
	if(hp >= iMaxHP)
	{
		ReplyToCommand(client, "[SM] You already have maximum HP!");
		PrintToServer("[SM] %N already has maximum HP!", client);
		return Plugin_Handled;
	}


	bRegen[client] = true;
	ReplyToCommand(client, "[SM] You have activated regeneration!");
	PrintToServer("[SM] %N has activated regeneration!", client);

	if(!hTimer) hTimer =  CreateTimer(fCD, Timer_Regen, _, TIMER_REPEAT);

	return Plugin_Handled;
}

public Action Timer_Regen(Handle timer)
{
	int num;
	for(int i = 1, hp, add; i <= MaxClients; i++) if(IsClientInGame(i) && IsPlayerAlive(i) && bRegen[i])
	{
		if((hp = GetClientHealth(i)) < iMaxHP)
		{
			if((add = hp + iAdd) >= iMaxHP)
			{
				bRegen[i] = false;
				add = iMaxHP;
			}
			else num++;
			SetEntityHealth(i, add);
		}
		else bRegen[i] = false;
	}

	if(!num)
	{
		hTimer = null;
		return Plugin_Stop;
	}

	return Plugin_Continue;
}

public void OnClientDisconnect(int client)
{
	bRegen[client] = false;
}

public void OnMapEnd()
{
	if(!hTimer) return;

	CloseHandle(hTimer);
	hTimer = null;
}