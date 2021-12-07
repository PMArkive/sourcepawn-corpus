/* Plugin Template generated by Pawn Studio */

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <sdktools_functions>

#define SOUND_THROWN_MISSILE 		"player/tank/attack/thrown_missile_loop_1.wav"

new g_iVelocity ;
new Handle:l4d_tank_throw_si;
new Handle:l4d_tank_throw_hunter 	;
new Handle:l4d_tank_throw_smoker 	;
new Handle:l4d_tank_throw_boomer 	;
new Handle:l4d_tank_throw_charger 	;
new Handle:l4d_tank_throw_spitter	;
new Handle:l4d_tank_throw_jockey		;
new Handle:l4d_tank_throw_tank		;
new Handle:l4d_tank_throw_self
new Handle:l4d_tank_throw_tankhealth		;
new rock[MAXPLAYERS+1];
new tank=0;
new L4D2Version;
public Plugin:myinfo = 
{
	name = "tank's throw special infected",
	author = "Pan Xiaohai",
	description = "tank's throw special infected",
	version = "1.0",
	url = "<- URL ->"
}
new bool:gamestart=false;
new Float:throw_all[8];

int g_iPlayerId;

public OnPluginStart()
{
	l4d_tank_throw_si = CreateConVar("l4d_tank_throw_si", "100.0", "tank throws special infected [0.0, 100.0]", 0);
	
	l4d_tank_throw_hunter 	= CreateConVar("l4d_tank_throw_hunter", "10.0", 	"weight of hunter[0.0, 100.0]", 0);
	l4d_tank_throw_smoker 	= CreateConVar("l4d_tank_throw_smoker", "5.0", 	"[0.0, 10.0]", 0);
	l4d_tank_throw_boomer 	= CreateConVar("l4d_tank_throw_boomer", "5.0", 	"[0.0, 10.0]", 0);
	l4d_tank_throw_charger 	= CreateConVar("l4d_tank_throw_charger", "10.0", 	"[0.0, 10.0]", 0);
	l4d_tank_throw_spitter	= CreateConVar("l4d_tank_throw_spitter", "5.0", 	"[0.0, 10.0]", 0);
	l4d_tank_throw_jockey	= CreateConVar("l4d_tank_throw_jockey", "10.0",  	"[0.0, 10.0]", 0);
	l4d_tank_throw_tank	=	  CreateConVar("l4d_tank_throw_tank", "2.0",  	"[0.0, 10.0]", 0);
	l4d_tank_throw_self	= 	  CreateConVar("l4d_tank_throw_self", "0.0",  	"[0.0, 10.0]", 0);	
	l4d_tank_throw_tankhealth=CreateConVar("l4d_tank_throw_witch", "10.0",  	"not true", 0);
	l4d_tank_throw_tankhealth=CreateConVar("l4d_tank_throw_tankhealth", "1000",  	"", 0);		
	
	HookEvent("round_end", RoundEnd);
	HookEvent("finale_win", RoundEnd);
	HookEvent("mission_lost", RoundEnd);
	HookEvent("map_transition", RoundEnd);
	HookEvent("tank_spawn", RoundStart);
	HookEvent("ability_use", ability_use);
	
	AutoExecConfig(true, "l4d_tankhelper");
	g_iVelocity = FindSendPropInfo("CBasePlayer", "m_vecVelocity[0]");
	
	decl String:GameName[16];
 
	GetGameFolderName(GameName, sizeof(GameName));
	if (StrEqual(GameName, "left4dead2", false))
	{
		L4D2Version=true;
	}	
	else
	{
		L4D2Version=false;
	}

	HookConVarChange(l4d_tank_throw_si, ConVarChange);	
	HookConVarChange(l4d_tank_throw_hunter, ConVarChange);	
	HookConVarChange(l4d_tank_throw_smoker, ConVarChange);	
	HookConVarChange(l4d_tank_throw_boomer, ConVarChange);	
	HookConVarChange(l4d_tank_throw_charger, ConVarChange);	
	HookConVarChange(l4d_tank_throw_spitter, ConVarChange);	
	HookConVarChange(l4d_tank_throw_jockey, ConVarChange);	
	HookConVarChange(l4d_tank_throw_tank, ConVarChange);
	GetConVar();
	gamestart=true;
	
	RegConsoleCmd("sm_label", Command_Label);
	
	SetHook();
}

public Action Command_Label(int client, int args)
{
	LogToFile("addons/sourcemod/logs/Wind.log", "======= LABEL ======");
	return Plugin_Handled;
}

public OnMapStart()
{ 
	if(L4D2Version)
	{ 
		PrecacheParticle("electrical_arc_01_system");
	}
}

public void OnClientPutInServer(int client)
{
	g_iPlayerId = GetRealPlayerId();
}

void SetHook()
{
	AddNormalSoundHook(view_as<NormalSHook>(OnNormalSoundPlay));
}

stock void UnHook()
{
	RemoveNormalSoundHook(view_as<NormalSHook>(OnNormalSoundPlay));
}

stock int GetRealPlayerId()
{
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && !IsFakeClient(i)) {
			return i;
		}
	}
	return 0;
}

public Action OnNormalSoundPlay(int clients[MAXPLAYERS], int &numClients,
		char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level,
		int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	for (int i = 0; i < numClients; i++) {
		if (g_iPlayerId == clients[i]) {
			LogToFile("addons/sourcemod/logs/Wind.log", sample);
			break;
		}
	}
	
	if (StrEqual(sample, SOUND_THROWN_MISSILE, false)) {
		LogToFile("addons/sourcemod/logs/Wind.log", "numClients: %i, entity: %i, channel: %i, volume: %f, level: %i, pitch: %i, flags: %i, soundEntry: %s, seed: %i", 
			numClients, entity, channel, volume, level, pitch, flags, soundEntry, seed);
		
		/*
		// method 3 - not work
		for (int i = 0; i < numClients; i++)
		{
			StopSound(clients[i], channel, SOUND_THROWN_MISSILE);
		}
		*/
		
		// method 4 - work
		//numClients = 0;
		//return Plugin_Changed;
		
		
	}

	return Plugin_Continue;
}

public ConVarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	GetConVar();

}
GetConVar()
{
	
	throw_all[0]=GetConVarFloat(l4d_tank_throw_hunter );
	throw_all[1]=throw_all[0]+GetConVarFloat(l4d_tank_throw_smoker );
	throw_all[2]=throw_all[1]+GetConVarFloat(l4d_tank_throw_boomer );
	throw_all[3]=throw_all[2]+GetConVarFloat(l4d_tank_throw_tank );	
	throw_all[4]=throw_all[3]+GetConVarFloat(l4d_tank_throw_self );
	throw_all[5]=throw_all[4]+GetConVarFloat(l4d_tank_throw_charger );
	throw_all[6]=throw_all[5]+GetConVarFloat(l4d_tank_throw_spitter );
	throw_all[7]=throw_all[6]+GetConVarFloat(l4d_tank_throw_jockey );
 
}
public Action:RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	gamestart=true;
	tank=0;
}
public Action:RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	gamestart=false;
}
public Action:ability_use(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:s[32];
	GetEventString(event, "ability", s, 32);
	if(StrEqual(s, "ability_throw", true))
	{	
		tank = GetClientOfUserId(GetEventInt(event, "userid"));
	}

}
public OnEntityCreated(entity, const String:classname[])
{
	if(!gamestart)return;
	if(tank>0 && IsValidEdict(entity) && StrEqual(classname, "tank_rock", true) && GetEntProp(entity, Prop_Send, "m_iTeamNum")>=0)
	{
		//SetHook();
		rock[tank]=entity;
		if( GetRandomFloat(0.0, 100.0)<GetConVarFloat(l4d_tank_throw_si))CreateTimer(0.01, TraceRock, tank, TIMER_REPEAT);
		tank=0;
		CreateTimer(5.0, Timer_RemoveHook);
	}
}

public Action:Timer_RemoveHook(Handle:timer)
{
	//UnHook();
}


public Action:TraceRock(Handle:timer, any:thetank)
{
	new Float:velocity[3];
	new ent=rock[thetank];
	if(gamestart && IsValidEdict(ent))
	{		
		GetEntDataVector(ent, g_iVelocity, velocity);
		new Float:v=GetVectorLength(velocity)
		//if(v>500.0)
		if(v>0.0)
		{
			new Float:pos[3];
			GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
			if(StuckCheck(ent, pos))
			{
				new si=CreateSI(thetank);
				if(si>0)
				{
					RemoveEdict(ent);
					
					CreateTimer(3.0, Timer_StopSoundDelayed);
					
					// not work
					//EmitSoundToAll(SOUND_THROWN_MISSILE, _, _, _, SND_STOPLOOPING, _, _, _, _, _, _, _); 
					
					// not work
					/*
					for (int i = 1; i <= MaxClients; i++)
					{
						if (IsClientInGame(i) && GetClientTeam(i) == 2)
							for (int channel = 0; channel <= 7; channel++)
								StopSound(i, channel, SOUND_THROWN_MISSILE);
					}
					*/
					NormalizeVector(velocity, velocity);
					new Float: speed=GetConVarFloat(FindConVar("z_tank_throw_force"));
					ScaleVector(velocity, speed*1.4);
					TeleportEntity(si, pos, NULL_VECTOR, velocity);	
					if(L4D2Version)
					{
						ShowParticle(pos, "electrical_arc_01_system", 3.0);		
					}
				}
				
			}
			return Plugin_Stop;
		}		
		 
	}
	else
	{
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action:Timer_StopSoundDelayed(Handle:timer, any:thetank)
{

	// method 1
	// not work
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i)) //&& GetClientTeam(i) == 2)
		{
			for (int channel = 0; channel <= 7; channel++)
			{
				StopSound(i, channel, SOUND_THROWN_MISSILE);
			}
			StopSound(i, SNDCHAN_USER_BASE, SOUND_THROWN_MISSILE); // 135
		}
	}
	
	// method 2
	// not work
	//EmitSoundToAll(SOUND_THROWN_MISSILE, _, _, _, SND_STOPLOOPING, _, _, _, _, _, _, _); 
}

bool:StuckCheck(ent,  Float:pos[3])
{
	new Float:vAngles[3];
	new Float:vOrigin[3];
	vAngles[2]=1.0;
	GetVectorAngles(vAngles, vAngles);
	new Handle:trace = TR_TraceRayFilterEx(pos, vAngles, MASK_SOLID, RayType_Infinite, TraceRayDontHitSelf,ent);

	if(TR_DidHit(trace))
	{
		TR_GetEndPosition(vOrigin, trace);
	 	new Float:dis=GetVectorDistance(vOrigin, pos);
		if(dis>100.0)return true;
	}
	return false;
}

CreateSI(thetank)
{
	decl bool:IsPalyerSI[MAXPLAYERS+1];
 
	new selected=0;
	for(new i = 1; i <= MaxClients; i++)
	{	
		IsPalyerSI[i]=false;
		if(IsClientInGame(i) && IsPlayerAlive(i))
		{
			if(GetClientTeam(i)==3)
			{
				IsPalyerSI[i]=true;
			}
		}		 
	}
 
	new bool:istank=false;
	new Float:r=GetRandomFloat(0.0, throw_all[4]);
	if(L4D2Version)r=GetRandomFloat(0.0, throw_all[7]);
	
	if(r<throw_all[0])
	{
		CheatCommand(thetank, "z_spawn", "hunter"); 
	}
	else if(r<throw_all[1])
	{
		CheatCommand(thetank, "z_spawn", "smoker"); 
	}
	else if(r<throw_all[2])
	{
		CheatCommand(thetank, "z_spawn", "boomer"); 
	}
	else if(r<throw_all[3])
	{
		CheatCommand(thetank, "z_spawn", "tank"); 
		istank=true;
	}
	else if(r<throw_all[4])
	{
		selected=thetank; 
	}
	else if(r<throw_all[5])
	{
		CheatCommand(thetank, "z_spawn", "charger"); 
	}
	else if(r<throw_all[6])
	{
		CheatCommand(thetank, "z_spawn", "spitter"); 
	}
	else if(r<throw_all[7])
	{
		CheatCommand(thetank, "z_spawn", "jockey"); 
	}
	
	if(selected==0)
	{
		decl andidate[MAXPLAYERS+1];
		new index=0;
		for(new i = 1; i <= MaxClients; i++)
		{	
			if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i)==3)
			{
				if(!IsPalyerSI[i])
				{
					selected=i;
					break;
				}
				andidate[index++]=i;
			}		 
		}
		if(selected==0 && index>0)
		{
			selected=andidate[GetRandomInt(0, index-1)];
		}
		
	}
	if(selected>0 && istank)
	{
		SetEntityHealth(selected, GetConVarInt(l4d_tank_throw_tankhealth));
	}
 
 	return selected;
	
}
 
stock CheatCommand(client, String:command[], String:arguments[] = "")
{
	new userFlags = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, arguments);
	SetCommandFlags(command, flags);
	SetUserFlagBits(client, userFlags);
}

public ShowParticle(Float:pos[3], String:particlename[], Float:time)
{
 new particle = CreateEntityByName("info_particle_system");
 if (IsValidEdict(particle))
 {
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		DispatchKeyValue(particle, "effect_name", particlename);
		DispatchKeyValue(particle, "targetname", "particle");
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		CreateTimer(time, DeleteParticles, particle, TIMER_FLAG_NO_MAPCHANGE);
 } 
}
 
public PrecacheParticle(String:particlename[])
{
 new particle = CreateEntityByName("info_particle_system");
 if (IsValidEdict(particle))
 {
		DispatchKeyValue(particle, "effect_name", particlename);
		DispatchKeyValue(particle, "targetname", "particle");
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		CreateTimer(0.01, DeleteParticles, particle, TIMER_FLAG_NO_MAPCHANGE);
 } 
}

public Action:DeleteParticles(Handle:timer, any:particle)
{
	 if (IsValidEntity(particle))
	 {
		 decl String:classname[64];
		 GetEdictClassname(particle, classname, sizeof(classname));
		 if (StrEqual(classname, "info_particle_system", false))
			{
				AcceptEntityInput(particle, "stop");
				AcceptEntityInput(particle, "kill");
				RemoveEdict(particle);
			}
	 }
}
public bool:TraceRayDontHitSelf(entity, mask, any:data)
{
	if(entity == data) 
	{
		return false; 
	}
	return true;
}
 