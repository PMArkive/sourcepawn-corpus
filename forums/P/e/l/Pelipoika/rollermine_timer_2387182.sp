#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>

#pragma newdecls required

//#define DEBUG
#define PLUGIN_VERSION	"1.2"

enum
{
	STATE_IDLE = 0,
	STATE_OPEN,
	STATE_CLOSED,
	STATE_STUNNED,
};

#define ROLLERMINE_SE_CLEAR					0
#define ROLLERMINE_SE_TAUNT					0x1

#define ROLLERMINE_MAX_ATTACK_DIST			4096
#define	ROLLERMINE_OPEN_THRESHOLD			256
#define ROLLERMINE_HOP_DELAY				2	// Don't allow hops faster than this, Doesn't actually do anything

int g_iShockIndex = -1;
int g_iShockHaloIndex = -1;

public Plugin myinfo = 
{
	name = "[TF2] Rollermine", 
	author = "Pelipoika", 
	description = "Zzap", 
	version = PLUGIN_VERSION, 
	url = ""
};

public void OnPluginStart()
{
	RegAdminCmd("sm_rollermine", Command_Rollermine, ADMFLAG_ROOT);
	RegAdminCmd("sm_clearmines", Command_ClearMines, ADMFLAG_ROOT);
	
	CreateConVar("tf2_rollermine_version", PLUGIN_VERSION, "Rollermine spawner version", FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_SPONLY);
}

public void OnPluginEnd()
{
	int iCount = 0;
	
	int index = -1;
	while((index = FindEntityByClassname(index, "prop_physics_multiplayer")) != -1)
	{
		if (IsValidEntity(index))
		{
			char strName[64];
			GetEntPropString(index, Prop_Data, "m_iName", strName, sizeof(strName));
			
			if(StrContains(strName, "RollerMine") != -1)
			{
				StopSound(index, SNDCHAN_AUTO, "npc/roller/mine/rmine_seek_loop2.wav");
				StopSound(index, SNDCHAN_AUTO, "npc/roller/mine/rmine_moveslow_loop1.wav");
				StopSound(index, SNDCHAN_AUTO, "npc/roller/mine/rmine_movefast_loop1.wav");
			
				AcceptEntityInput(index, "Kill");
				
				iCount++;
			}
		}
	}
	
	#if defined DEBUG
	PrintToChatAll("[SM] Removed %i Rollermines", iCount);
	#endif
}

public void OnMapStart()
{
	PrecacheModel("models/roller.mdl");
	PrecacheModel("models/roller_spikes.mdl");
	
	g_iShockHaloIndex = PrecacheModel("sprites/bluelight1.vmt");
	g_iShockIndex = PrecacheModel("sprites/rollermine_shock.vmt");
	
	PrecacheModel("sprites/rollermine_shock_yellow.vmt");
	
	PrecacheSound("npc/roller/mine/rmine_blades_in1.wav");
	PrecacheSound("npc/roller/mine/rmine_blades_in2.wav");
	PrecacheSound("npc/roller/mine/rmine_blades_in3.wav");
	
	PrecacheSound("npc/roller/mine/rmine_blades_out1.wav");
	PrecacheSound("npc/roller/mine/rmine_blades_out2.wav");
	PrecacheSound("npc/roller/mine/rmine_blades_out3.wav");
	
	PrecacheSound("npc/roller/mine/rmine_seek_loop2.wav");
	PrecacheSound("npc/roller/mine/rmine_movefast_loop1.wav");
	PrecacheSound("npc/roller/mine/rmine_moveslow_loop1.wav");
	PrecacheSound("npc/roller/mine/rmine_taunt1.wav");
	PrecacheSound("npc/roller/mine/rmine_explode_shock1.wav");
}

public Action Command_ClearMines(int client, int args)
{
	OnPluginEnd();
	return Plugin_Handled;
}

public void OnEntityDestroyed(int entity)
{
	if(entity > MaxClients && IsValidEntity(entity))
	{
		char strName[64];
		GetEntPropString(entity, Prop_Data, "m_iName", strName, sizeof(strName));
		if(StrContains(strName, "RollerMine") != -1)
		{
			StopSound(entity, SNDCHAN_AUTO, "npc/roller/mine/rmine_seek_loop2.wav");
			StopSound(entity, SNDCHAN_AUTO, "npc/roller/mine/rmine_moveslow_loop1.wav");
			StopSound(entity, SNDCHAN_AUTO, "npc/roller/mine/rmine_movefast_loop1.wav");
		}
	}
}

public Action Command_Rollermine(int client, int args)
{
	if(client > 0 && client <= MaxClients && IsClientInGame(client))
	{
		float origin[3], angles[3], pos[3];
		GetClientEyePosition(client, origin);
		GetClientEyeAngles(client, angles);
		
		Handle trace = TR_TraceRayFilterEx(origin, angles, MASK_SOLID, RayType_Infinite, TraceFilterSelf, client);
		
		if(TR_DidHit(trace))
		{
			TR_GetEndPosition(pos, trace);
			pos[2] += 15.0;
			
			int iEnt = CreateEntityByName("prop_physics_multiplayer");
			if(IsValidEntity(iEnt))
			{
				char strName[64];
				Format(strName, sizeof(strName), "RollerMine%i", iEnt);
				DispatchKeyValue(iEnt, "targetname", strName);
				DispatchKeyValueVector(iEnt, "origin", pos);
				DispatchKeyValue(iEnt, "model", "models/roller.mdl");
				DispatchSpawn(iEnt);

				CreateTimer(0.001, OnRollermineThink, EntIndexToEntRef(iEnt));
				
				int iMotor = CreateEntityByName("phys_torque");
				DispatchKeyValueVector(iMotor, "origin", pos);
				DispatchKeyValue(iMotor, "attach1", strName);
				DispatchKeyValue(iMotor, "force", "5000");
				DispatchKeyValue(iMotor, "speed", "200");
				DispatchSpawn(iMotor);
				
				SetVariantString("!activator");
				AcceptEntityInput(iMotor, "SetParent", iEnt);
				
				ActivateEntity(iMotor);
			}
		}
		
		delete trace;
	}

	return Plugin_Handled;
}

public Action OnRollermineThink(Handle timet, any ref)
{
	int iEnt = EntRefToEntIndex(ref);
	if(iEnt != INVALID_ENT_REFERENCE && IsValidEntity(iEnt))
	{
		int iMotor = GetEntPropEnt(iEnt, Prop_Data, "m_hMoveChild");
		if(IsValidEntity(iMotor))
		{	
			if(GetRollerState(iEnt) != STATE_STUNNED)
			{
				float flEntPos[3];
				GetEntPropVector(iEnt, Prop_Data, "m_vecAbsOrigin", flEntPos);
			
				int iTarget = Entity_GetClosestClient(iEnt);		
				if(iTarget > 0 && iTarget <= MaxClients && IsClientInGame(iTarget))
				{
					float flClientPos[3];
					GetClientAbsOrigin(iTarget, flClientPos);
					
					float flDistance = GetVectorDistance(flClientPos, flEntPos);
					if(flDistance <= ROLLERMINE_OPEN_THRESHOLD)
					{
						if(GetRollerState(iEnt) != STATE_OPEN)
						{
							SetRollerState(iEnt, STATE_OPEN);
						}
					}
					else if(GetRollerState(iEnt) != STATE_CLOSED)
					{
						AcceptEntityInput(iMotor, "Deactivate");
						SetRollerState(iEnt, STATE_CLOSED);
					}
					
					if(flDistance <= 400.0 && !(GetRollerFlags(iEnt) & ROLLERMINE_SE_TAUNT))
					{
						EmitSoundToAll("npc/roller/mine/rmine_taunt1.wav", iEnt, _, _, _, _, GetRandomInt(90, 110));
						
						int iFlags = GetRollerFlags(iEnt) | ROLLERMINE_SE_TAUNT;
						SetRollerFlags(iEnt, iFlags); 
						
						#if defined DEBUG
						PrintToChatAll("TAUNT");
						#endif
					}
					
					if(flDistance <= 35.0)
					{
						EmitSoundToAll("npc/roller/mine/rmine_explode_shock1.wav", iEnt, _, _, _, _, GetRandomInt(100, 120));
						
						float impulse[3];
						SubtractVectors(flEntPos, flClientPos, impulse);
						impulse[2] = 0.0;
						NormalizeVector(impulse, impulse);
						impulse[2] = 0.75;
						NormalizeVector(impulse, impulse);
						ScaleVector(impulse, 600.0);
			
						TeleportEntity(iEnt, NULL_VECTOR, NULL_VECTOR, impulse);
						
						SDKHooks_TakeDamage(iTarget, iEnt, iEnt, 35.0, DMG_SHOCK);
						
						SetRollerState(iEnt, STATE_STUNNED);
						AcceptEntityInput(iMotor, "Deactivate");
						
						CreateTimer(1.5, Timer_UnStun, EntIndexToEntRef(iEnt));
					}
					
					float flDirection[3];
					MakeVectorFromPoints(flEntPos, flClientPos, flDirection);
					flDirection[2] = 0.0;
					
					NormalizeVector(flDirection, flDirection);
					
					float flRight[3];
					GetVectorVectors(flDirection, flRight, NULL_VECTOR);
					
					NegateVector(flRight);
					
					SetEntPropVector(iMotor, Prop_Data, "m_axis", flRight);
			
					AcceptEntityInput(iMotor, "Deactivate");
					AcceptEntityInput(iMotor, "Activate");
				}
				else if(GetRollerState(iEnt) != STATE_IDLE)
				{
					AcceptEntityInput(iMotor, "Deactivate");
						
					SetRollerState(iEnt, STATE_IDLE);
				}
			}
			else if(GetRollerState(iEnt) == STATE_STUNNED)
			{
				AcceptEntityInput(iMotor, "Deactivate");
			}
			
			CreateTimer(0.001, OnRollermineThink, EntIndexToEntRef(iEnt));
		}
	}
}

public Action Timer_UnStun(Handle timet, any ref)
{
	int iEnt = EntRefToEntIndex(ref);
	if(iEnt != INVALID_ENT_REFERENCE && IsValidEntity(iEnt))
	{
		SetRollerState(iEnt, STATE_IDLE);
	}
}

stock void SetRollerFlags(int iRollerMine, int iFlags)
{
	SetEntProp(iRollerMine, Prop_Data, "m_fFlags", iFlags);
}

stock int GetRollerFlags(int iRollerMine)
{
	return GetEntProp(iRollerMine, Prop_Data, "m_fFlags");
}

stock void SetRollerState(int iRollerMine, int iState)
{
	switch(iState)
	{
		case STATE_IDLE:
		{
			SetEntityModel(iRollerMine, "models/roller.mdl");

			StopSound(iRollerMine, SNDCHAN_AUTO, "npc/roller/mine/rmine_seek_loop2.wav");
			StopSound(iRollerMine, SNDCHAN_AUTO, "npc/roller/mine/rmine_moveslow_loop1.wav");
			StopSound(iRollerMine, SNDCHAN_AUTO, "npc/roller/mine/rmine_movefast_loop1.wav");
			
			EmitSoundToAll("npc/roller/mine/rmine_seek_loop2.wav", iRollerMine);
			
			switch(GetRandomInt(1, 3))
			{
				case 1: EmitSoundToAll("npc/roller/mine/rmine_blades_in1.wav", iRollerMine, _, _, _, _, GetRandomInt(90, 110));
				case 2: EmitSoundToAll("npc/roller/mine/rmine_blades_in2.wav", iRollerMine, _, _, _, _, GetRandomInt(90, 110));
				case 3: EmitSoundToAll("npc/roller/mine/rmine_blades_in3.wav", iRollerMine, _, _, _, _, GetRandomInt(90, 110));
			}
			
			#if defined DEBUG
			PrintToChatAll("IDLE");
			#endif
			
			SetRollerFlags(iRollerMine, ROLLERMINE_SE_CLEAR);
		}
		case STATE_CLOSED:
		{
			SetEntityModel(iRollerMine, "models/roller.mdl");

			StopSound(iRollerMine, SNDCHAN_AUTO, "npc/roller/mine/rmine_seek_loop2.wav");
			StopSound(iRollerMine, SNDCHAN_AUTO, "npc/roller/mine/rmine_moveslow_loop1.wav");
			StopSound(iRollerMine, SNDCHAN_AUTO, "npc/roller/mine/rmine_movefast_loop1.wav");
			
			EmitSoundToAll("npc/roller/mine/rmine_moveslow_loop1.wav", iRollerMine);
			
			switch(GetRandomInt(1, 3))
			{
				case 1: EmitSoundToAll("npc/roller/mine/rmine_blades_in1.wav", iRollerMine, _, _, _, _, GetRandomInt(90, 110));
				case 2: EmitSoundToAll("npc/roller/mine/rmine_blades_in2.wav", iRollerMine, _, _, _, _, GetRandomInt(90, 110));
				case 3: EmitSoundToAll("npc/roller/mine/rmine_blades_in3.wav", iRollerMine, _, _, _, _, GetRandomInt(90, 110));
			}
			
			#if defined DEBUG
			PrintToChatAll("CLOSED");
			#endif
			
			SetRollerFlags(iRollerMine, ROLLERMINE_SE_CLEAR);
		}
		case STATE_OPEN:
		{
			SetEntityModel(iRollerMine, "models/roller_spikes.mdl");
			
			StopSound(iRollerMine, SNDCHAN_AUTO, "npc/roller/mine/rmine_seek_loop2.wav");
			StopSound(iRollerMine, SNDCHAN_AUTO, "npc/roller/mine/rmine_moveslow_loop1.wav");
			StopSound(iRollerMine, SNDCHAN_AUTO, "npc/roller/mine/rmine_movefast_loop1.wav");
			
			EmitSoundToAll("npc/roller/mine/rmine_moveslow_loop1.wav", iRollerMine);
			EmitSoundToAll("npc/roller/mine/rmine_movefast_loop1.wav", iRollerMine);
			
			switch(GetRandomInt(1, 3))
			{
				case 1: EmitSoundToAll("npc/roller/mine/rmine_blades_out1.wav", iRollerMine, _, _, _, _, GetRandomInt(90, 110));
				case 2: EmitSoundToAll("npc/roller/mine/rmine_blades_out2.wav", iRollerMine, _, _, _, _, GetRandomInt(90, 110));
				case 3: EmitSoundToAll("npc/roller/mine/rmine_blades_out3.wav", iRollerMine, _, _, _, _, GetRandomInt(90, 110));
			}
			
			#if defined DEBUG
			PrintToChatAll("OPEN");
			#endif
		}
		case STATE_STUNNED:
		{
			SetEntityModel(iRollerMine, "models/roller_spikes.mdl");

			StopSound(iRollerMine, SNDCHAN_AUTO, "npc/roller/mine/rmine_seek_loop2.wav");
			StopSound(iRollerMine, SNDCHAN_AUTO, "npc/roller/mine/rmine_moveslow_loop1.wav");
			StopSound(iRollerMine, SNDCHAN_AUTO, "npc/roller/mine/rmine_movefast_loop1.wav");
			
			EmitSoundToAll("npc/roller/mine/rmine_seek_loop2.wav", iRollerMine);

			#if defined DEBUG
			PrintToChatAll("STUNNED");
			#endif
			
			SetRollerFlags(iRollerMine, ROLLERMINE_SE_CLEAR);
		}
	}
	
	SetEntProp(iRollerMine, Prop_Data, "m_nBody", iState);
}

stock int GetRollerState(int iRollerMine)
{
	return GetEntProp(iRollerMine, Prop_Data, "m_nBody");
}

stock void ShockTarget(int iRollermine, int iTarget)
{
/*	float flEntPos[3];
	GetEntPropVector(iRollermine, Prop_Data, "m_vecAbsOrigin", flEntPos);

	float flTargetPos[3];
	GetClientEyePosition(iTarget, flTargetPos);*/
	
	TE_SetupBeamLaser(iRollermine, iTarget, g_iShockIndex, g_iShockHaloIndex, 0, 1, 0.5, 16.0, 16.0, 300, 16.0, {255, 255, 255, 255}, 1);
	TE_SendToAll();
}

stock int Entity_GetClosestClient(int iEnt)
{
	float flPos1[3];
	GetEntPropVector(iEnt, Prop_Send, "m_vecOrigin", flPos1);
	
	int iBestTarget = -1;
	float flBestLength = float(ROLLERMINE_MAX_ATTACK_DIST);
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && Entity_Cansee(iEnt, i) && IsPlayerAlive(i))
		{
			float flPos2[3];
			GetClientEyePosition(i, flPos2);
			
			float flDistance = GetVectorDistance(flPos1, flPos2);

			if(flDistance < flBestLength)
			{
				iBestTarget = i;
				flBestLength = flDistance;
			}
		}
	}
	
	if(iBestTarget > 0 && iBestTarget <= MaxClients && IsClientInGame(iBestTarget))
	{
		return iBestTarget;
	}
	
	return iBestTarget;
}

stock bool Entity_Cansee(int iEnt, int iClient)
{
	if(TF2_IsPlayerInCondition(iClient, TFCond_Disguised) || TF2_IsPlayerInCondition(iClient, TFCond_Cloaked)
	|| TF2_IsPlayerInCondition(iClient, TFCond_Stealthed) || TF2_IsPlayerInCondition(iClient, TFCond_CloakFlicker)
	|| TF2_IsPlayerInCondition(iClient, TFCond_DeadRingered) || TF2_GetClientTeam(iClient) == TFTeam_Spectator)
		return false;
	
	float flStart[3], flEnd[3];
	GetClientEyePosition(iClient, flEnd);
	GetEntPropVector(iEnt, Prop_Send, "m_vecOrigin", flStart);
	
	flStart[2] += 10.0;
	
	bool bSee = true;
	Handle hTrace = TR_TraceRayFilterEx(flStart, flEnd, MASK_SOLID, RayType_EndPoint, TraceFilterSelf, iEnt);
	if(hTrace != INVALID_HANDLE)
	{
		if(TR_DidHit(hTrace))
			bSee = false;
			
		CloseHandle(hTrace);
	}
	
	return bSee;
}

public bool TraceFilterSelf(int entity, int contentsMask, any iPumpking)
{
	if(entity == iPumpking || entity > MaxClients || (entity >= 1 && entity <= MaxClients))
		return false;
	
	return true;
}