/* Plugin Template generated by Pawn Studio */

#include <sdktools>
#include <sourcemod>
#include <sdkhooks>

public Plugin:myinfo = {
	name = "Weapon Burst Mode For MP5",
	author = "cjsrk",
	description = "<- Description ->",
	version = "0.1",
	url = "<- URL ->"
}

int EnableBurstMode[1024] = {1};    // 1是半自动，0是全自动
int BlockTime2[1024] = {0};


public OnPluginStart(){
	HookEvent("weapon_fire", M16Fire, EventHookMode_Pre);
	HookEvent("round_start", RoundStart_Burst, EventHookMode_Post);
}


bool:IsClient(Client, bool:Alive)
{
	return Client <= MaxClients && IsClientConnected(Client) && IsClientInGame(Client) && (Alive && IsPlayerAlive(Client));
}


public M16Fire(Handle:event,const String:name[],bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	//获取当前武器名字
	if(!IsValidEntity(client))
		return Plugin_Continue;
	
	new currentWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
    if (!IsValidEdict(currentWeapon) || (currentWeapon == -1))
		    return Plugin_Continue;	
	decl String:sWeapon[32];
	GetEdictClassname(currentWeapon, sWeapon, sizeof(sWeapon));
	
	if(StrEqual(sWeapon, "weapon_glock"))
	{
		if(EnableBurstMode[currentWeapon] == 1)
		{
			ClientCommand(client, "-attack");
		}		
	}
}


public Action OnPlayerRunCmd(int client, int &buttons)
{
    if (buttons & IN_ATTACK2)
	{
		if(IsClient(client, true))
		{
			//获取当前武器名字
			if(!IsValidEntity(client))
				return Plugin_Continue;
			
			new currentWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if (!IsValidEdict(currentWeapon) || (currentWeapon == -1))
					return Plugin_Continue;	
			decl String:sWeapon[32];
			GetEdictClassname(currentWeapon, sWeapon, sizeof(sWeapon));
			
			if(StrEqual(sWeapon, "weapon_glock"))
			{
				// 关闭三连发模式
				if(HasEntProp(currentWeapon, Prop_Send, "m_bBurstMode"))
				{
					SetEntProp(currentWeapon, Prop_Send, "m_bBurstMode", 0);
					PrintCenterText(client, "");
				}
				
				if(BlockTime2[currentWeapon] == 0)
				{
					if(EnableBurstMode[currentWeapon] == 1)
					{
						EnableBurstMode[currentWeapon] = 0;
						BlockTime2[currentWeapon] = 1;
						CreateTimer(0.2, Timer_RestrictTime2, currentWeapon);
						CreateTimer(0.1, Timer_RestrictTime3, client);
					}
					else
					{
						EnableBurstMode[currentWeapon] = 1;
						BlockTime2[currentWeapon] = 1;
						CreateTimer(0.2, Timer_RestrictTime2, currentWeapon);
						CreateTimer(0.1, Timer_RestrictTime4, client);
					}
				}
			}
		}
	}
}


public Action:Timer_RestrictTime2(Handle timer, int weapon)
{
	if(!IsValidEntity(weapon))
		return Plugin_Continue;
	BlockTime2[weapon] = 0;
}

public Action:Timer_RestrictTime3(Handle timer, int client)
{
	PrintCenterText(client, "Fully Automatic Mode");
}

public Action:Timer_RestrictTime4(Handle timer, int client)
{
	PrintCenterText(client, "Semi-automatic Mode");
}


public void RoundStart_Burst(Handle hEvent, char[] chEvent, bool bDontBroadcast)
{
	for(int i = 0; i < sizeof(EnableBurstMode); i++)
	{
		EnableBurstMode[i] = 1;
		BlockTime2[i] = 0;
	}
}
