/* Plugin Template generated by Pawn Studio */

#include <sourcemod>
#include <sdktools>

#define CVAR_FLAGS FCVAR_PLUGIN
#define PLUGIN_VERSION "1.4"
#define INFECTEDTEAM 3
#define GHOST_STATE_BLOCKED 1024

#define PLAYER_DID_IT_TEXT 			"You have been automatically killed for using the GHOST-CROUCH exploit."
#define PLAYER_DID_IT_REPORT_TEXT 	"%s was killed for using the GHOST-CROUCH exploit."

new PropOffset_IsGhost;
new PropOffset_GhostSpawnState;
new Handle:hConVar_Kill;

public Plugin:myinfo = 
{
	name = "[L4D] Block Ghost Duck",
	author = "Thraka",
	description = "Forces a player (on spawn) to duck-unduck. Prevents ghosts from using exploits.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=868638"
}

public OnPluginStart()
{
	CreateConVar("l4d_ghost_duck_block_ver", PLUGIN_VERSION, "Version of the ghost block plugin.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	hConVar_Kill = CreateConVar("l4d_ghost_duck_block_kill", "1", "If set to 1, slays the player when they spawn and have used the exploit", CVAR_FLAGS);
	
	HookEvent("player_spawn", Player_Spawn);
	
	PropOffset_IsGhost = FindSendPropInfo("CTerrorPlayer", "m_isGhost");
	PropOffset_GhostSpawnState = FindSendPropInfo("CTerrorPlayer", "m_ghostSpawnState");
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (buttons & IN_DUCK)
	{
		if (GetClientTeam(client) == INFECTEDTEAM)
		{
			decl String:clientClass[64];
			GetEntityNetClass(client, clientClass, sizeof(clientClass));
			
			// If they are a player in the game
			if (StrEqual(clientClass, "CTerrorPlayer", false))
			{
				// If they are a ghost
				if (GetEntData(client, PropOffset_IsGhost, 1))
				{
					// If they are currently blocked by something
					if (GetEntData(client, PropOffset_GhostSpawnState, 4) & GHOST_STATE_BLOCKED)
					{
						// Block +duck
						buttons &= ~IN_DUCK;
					}
				}
				
			}
		}
	}
	
	return Plugin_Continue;
}

public Player_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	// Check for correct team
	if (GetClientTeam(client) == INFECTEDTEAM)
	{
		// They spawned, check in a millisecond if they are still ducked and not ducking
		if (GetConVarBool(hConVar_Kill))
			CreateTimer(0.1, SlayExploitPlayer, client);
		else
			CreateTimer(0.1, DuckPlayer, client);
	}
}

public Action:SlayExploitPlayer(Handle:timer, any:client)
{
	new ducked = GetEntProp(client, Prop_Send, "m_bDucked");
	new ducking = GetEntProp(client, Prop_Send, "m_bDucking");
	new Float:fallingFloat = GetEntPropFloat(client, Prop_Send, "m_flFallVelocity");
	//new fallVelocity = GetEntProp(client,Prop_Send, "m_bInDuckJump");
	
	// Check to see if player is ducked, but not in process of ducking (using the duck command)
	if (ducked == 1 && ducking == 0 && fallingFloat == 0)
	{
		// If they do not have the duck button pushed
		if (!(GetClientButtons(client) & IN_DUCK)) 
		{
			decl String:name[32];
			GetClientName(client, name, sizeof(name));
			
			ShowActivity2(0, "[SM] ", PLAYER_DID_IT_REPORT_TEXT, name);
			PrintHintText(client, PLAYER_DID_IT_TEXT);
			ForcePlayerSuicide(client);
		}
	}
}

public Action:DuckPlayer(Handle:timer, any:client)
{
	if (IsFakeClient(client))
		FakeClientCommand(client, "+duck");
	else
		ClientCommand(client, "+duck");	
	
	CreateTimer(0.01, UnDuckPlayer, client);
}

public Action:UnDuckPlayer(Handle:timer, any:client)
{
	if (IsFakeClient(client))
		FakeClientCommand(client, "-duck");
	else
		ClientCommand(client, "-duck");	
}