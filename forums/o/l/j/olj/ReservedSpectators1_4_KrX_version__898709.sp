#define PLUGIN_VERSION "1.4(KrX)"
#define PLUGIN_NAME "L4D Reserved spectator slots"
#define CVAR_FLAGS FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY

#include <sourcemod>
#include <sdktools>
new Handle:h_TimeBeforeKick = INVALID_HANDLE;
new Handle:h_PlayersBeforeKick = INVALID_HANDLE;
new Float:TimeBeforeKick, PlayersBeforeKick;
public Plugin:myinfo = 
{
    name = PLUGIN_NAME,
    author = "Olj, KrX",
    description = "[L4D] Reserves spectator slots for admins only",
    version = PLUGIN_VERSION,
    url = "http://www.sourcemod.net/"
}

public OnPluginStart()
	{
		CreateConVar("l4d_rs_version", PLUGIN_VERSION, "Version of Reserved Spectators plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
		LoadTranslations("reserved_spectators.phrases");
		h_TimeBeforeKick = CreateConVar("l4d_reserved_spectators_timetokick", "10.00", "Specifies time before non-admin spectator will be kicked.", CVAR_FLAGS);
		h_PlayersBeforeKick = CreateConVar("l4d_reserved_spectators_playersb4kick", "8", "Specifies how many players to have before adding timer to start kicking", CVAR_FLAGS);
		TimeBeforeKick = GetConVarFloat(h_TimeBeforeKick);
		PlayersBeforeKick = GetConVarInt(h_PlayersBeforeKick);
		HookConVarChange(h_TimeBeforeKick, KickTimeChanged);
		AutoExecConfig(true, "L4D_ReservedSpectators");
	}

public OnClientPostAdminCheck(client)
    {
		if (!IsValidPlayer(client)) return;
		new i = 0, totalClients = 0;
		for(i = 0; i < MaxClients; i++) {
			if(IsValidPlayer(i))
				totalClients++;
		}
		if(!IsClientMember(client) && totalClients > PlayersBeforeKick)
        {
            CreateTimer(TimeBeforeKick, KickTimer, client);
        }
    }
    
public KickTimeChanged(Handle:hVariable, const String:strOldValue[], const String:strNewValue[])
	{
		TimeBeforeKick = GetConVarFloat(h_TimeBeforeKick);
	}
	
public Action:KickTimer(Handle:timer, any:client)
    {
        if ((IsValidPlayer(client))&&(!IsClientMember(client))&&(GetClientTeam(client)==1))
            {
                decl String:name[MAX_NAME_LENGTH];
                GetClientName(client, name, MAX_NAME_LENGTH);
                KickClient(client, "%t", "KICK_MESSAGE");
                PrintToChatAll("\x05%s \x01%t",name, "KICK_CHATALL_MESSAGE");
            }
    }
	
public IsValidPlayer (client)
{
	if (client == 0)
		return false;
	
	if (!IsClientConnected(client))
		return false;
	
	if (!IsClientInGame(client))
		return false;
	
	if (IsFakeClient(client))
		return false;
	
	return true;
}

bool:IsClientMember (client)
{
	// Checks valid player
	//if (!IsValidPlayer (client))
		//return false;
	
	// Gets the admin id
	new AdminId:id = GetUserAdmin(client);
	
	// If player is not admin ...
	if (id == INVALID_ADMIN_ID)
		return false;
	
	// If player has at least reservation ...
	if (GetAdminFlag(id, Admin_Reservation)||GetAdminFlag(id, Admin_Root)||GetAdminFlag(id, Admin_Kick))
		return true;
	else
	return false;
}