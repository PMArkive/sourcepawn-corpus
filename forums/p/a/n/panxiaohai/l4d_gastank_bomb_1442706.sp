/* Plugin Template generated by Pawn Studio */

#include <sourcemod>
#include <sdktools>
#include <sdktools_functions> 
#include <sdkhooks>
#define SOUND_PIPEBOMB  "weapons/hegrenade/beep.wav"
#define SOUND_BLIP		"UI/Beep07.wav"
new ItemEnt[ MAXPLAYERS+1];
new Handle:Timer[MAXPLAYERS+1];
new Float:Energe[MAXPLAYERS+1];
new bool:ready[MAXPLAYERS+1];
 
new g_destory_ent=0;
new g_create_ent=0;
public Plugin:myinfo = 
{
	name = "Gas tank bomb", //����
	author = "XiaoHai",  //����
	description = "<- Description ->",
	version = "1.1",
	url = "<- URL ->"
}
new Handle:l4d_bomb_enable;
new Handle:l4d_bomb_delay;
new Handle:l4d_bomb_set_time;
new Handle:l4d_bomb_attract_infected;

new Handle:l4d_bomb_damage;
new Handle:l4d_bomb_radius;
new Handle:l4d_bomb_pushforce;
public OnPluginStart()
{
	CreateConVar("l4d_bomb_version", "1.1", "",FCVAR_PLUGIN);
	l4d_bomb_enable = CreateConVar("l4d_bomb_enable", "1", "{0,1}", FCVAR_PLUGIN);
	l4d_bomb_delay = CreateConVar("l4d_bomb_explode_delay", "3.0", "seconds", FCVAR_PLUGIN);
	l4d_bomb_set_time = CreateConVar("l4d_bomb_set_time", "7.0", "seconds", FCVAR_PLUGIN);
	l4d_bomb_attract_infected = CreateConVar("l4d_bomb_attract_infected", "1", "{0, 1}", FCVAR_PLUGIN);
	
	l4d_bomb_damage  = CreateConVar("l4d_bomb_damage", "1000", "damage for bomb", FCVAR_PLUGIN);
	l4d_bomb_radius  = CreateConVar("l4d_bomb_radius", "450", "radius for bomb", FCVAR_PLUGIN);
	l4d_bomb_pushforce  = CreateConVar("l4d_bomb_pushforce", "1500", "pushforce for bomb", FCVAR_PLUGIN);
	 
	HookEvent("player_use", player_use);
	HookEvent("round_start", RoundStart);
	for (new i=1;i<=MaxClients;i++)
	{
		Timer[i]=INVALID_HANDLE;
		Energe[i]=0.0;
		 
		g_destory_ent=0;
		g_create_ent=0;
	}
	AutoExecConfig(true, "l4d_bomb_v11");
}
public OnMapStart()
{
	InitPrecache();
}
InitPrecache()
{
	PrecacheSound(SOUND_PIPEBOMB, true) ;
	PrecacheSound(SOUND_BLIP, true);
	PrecacheModel("models/props_junk/propanecanister001a.mdl", true);
 
	PrecacheParticle("gas_explosion_pump");
	PrecacheParticle("gas_explosion_main");
}
public Action:RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i=1;i<=MaxClients;i++)
	{
		g_destory_ent=0;
		g_create_ent=0;
		StopTimer(i);
	}
	 
}
public Action:player_use(Handle:hEvent, const String:strName[], bool:DontBroadcast)
{
	if(GetConVarInt(l4d_bomb_enable)>0)
	{
		new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
		new ent=GetEventInt(hEvent, "targetid");
		if(client > 0 && ent>0 && IsValidEdict(ent) && IsValidEntity(ent))
		{
			decl String:name[100];
			GetClientWeapon(client, name, 100);
			//PrintToChatAll("%N use %s", client ,name);
			if(ItemOk(name))
			{
				StopTimer(client);
				ItemEnt[client]=g_create_ent;
				ready[client]=false;
				Timer[client]=CreateTimer(0.5, checkitem, client, TIMER_REPEAT);
			}
		}
	}
 
	return Plugin_Continue;
}

public Action:checkitem(Handle:timer, any:client)
{
 
	 if (IsClientInGame(client) && IsPlayerAlive(client) )
	 {
		  
		  new b=GetClientButtons(client);
		 
		  if(ready[client])
		  {
		  		if(b & IN_ZOOM)
				{
					PrepareBomb(client, ItemEnt[client]);
					return StopTimer(client); 				
				}
		  }
		  decl String:name[100];
		  GetClientWeapon(client, name, 100);
		  if(ItemOk(name))
		  {
				if(b & IN_ATTACK2)
				{
					Energe[client]+=0.5;
					if(Energe[client]<=GetConVarFloat(l4d_bomb_set_time))
					{						
						decl Float:pos[3];
						GetClientEyePosition(client, pos); 
						//EmitAmbientSound(SOUND_BLIP, pos, client, SNDLEVEL_RAIDSIREN);	
						EmitSoundToAll(SOUND_BLIP, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, pos, NULL_VECTOR, false, 0.0);
					}
					
				}
				if(Energe[client]>GetConVarFloat(l4d_bomb_set_time))
				{
					PrintHintText(client, "bomb set sucessfully, now drop it and press middle button");					
				}
				else
				{
					if(Energe[client]==0.0)PrintHintText(client, "press right button to set bomb");
					else PrintHintText(client, "set bomb progress %d%%", RoundFloat(Energe[client]/GetConVarFloat(l4d_bomb_set_time)*100.0));
					//ShowBar(client, "bomb progress", Energe[client], GetConVarFloat(l4d_bomb_set_time));
				}
		  }
		  else if(Energe[client]>GetConVarFloat(l4d_bomb_set_time))
		  {
			   ready[client]=true;
			   return Plugin_Continue;
		  }
		  else 
		  {
				return StopTimer(client);
		  }
	 }
	 else 
	 {
	 	return StopTimer(client);
	 }
	 return Plugin_Continue;
}
PrepareBomb(client, ent)
{
	if(EntOk(ent))
	{
		new chase=0;
		new particle=0;
		if(GetConVarInt(l4d_bomb_attract_infected)>0)
		{
		 
			decl Float:pos[3];
			GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
	 
			decl String:tName[128];
			Format(tName, sizeof(tName), "bomb%i", ent);
			DispatchKeyValue(ent, "targetname", tName);
			 

			chase = CreateEntityByName("info_goal_infected_chase");
			decl String:chase_name[128];
			Format(chase_name, sizeof(chase_name), "chase%i", chase);
			DispatchKeyValue(chase,"targetname", chase_name);
			DispatchKeyValue(chase, "parentname", tName);
		 
			DispatchSpawn(chase);
			TeleportEntity(chase, pos, NULL_VECTOR, NULL_VECTOR);
			SetVariantString(tName);
			AcceptEntityInput(chase, "SetParent", chase, chase, 0);
			SetVariantString("forward");
			AcceptEntityInput(chase, "Enable");

			particle=AttachParticle(chase, "weapon_pipebomb_blinking_light", pos);
 
		}
		new Handle:data = CreateDataPack();
		WritePackCell(data, client);
		WritePackCell(data, ItemEnt[client]);
		WritePackFloat(data,GetEngineTime());
		WritePackFloat(data,GetEngineTime()+GetConVarFloat(l4d_bomb_delay));
		WritePackCell(data, chase);
		WritePackCell(data, particle);
		CreateTimer(0.5, ShowEffect, data, TIMER_REPEAT);
	}
}
public Action:ShowEffect(Handle:timer, Handle:data)
{
	ResetPack(data);
 	new client=ReadPackCell(data);
	new ent=ReadPackCell(data);
	new Float:starttime=ReadPackFloat(data);
	new Float:endtime=ReadPackFloat(data);
	new chase=ReadPackCell(data);
	new particle=ReadPackCell(data);
	new Float:time=GetEngineTime();
	if(EntOk(ent))
	{
		if(time<endtime)
		{
			if(IsClientInGame(client))PrintHintText(client, "time left %d",  RoundFloat(endtime-time));
		 	decl Float:pos[3];
			GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
			EmitSoundToAll(SOUND_PIPEBOMB, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, pos, NULL_VECTOR, false, 0.0);
			return Plugin_Continue;
		}
		else
		{
			DeleteParticles(INVALID_HANDLE, particle);
			SafeDeleteEntity(chase, "info_goal_infected_chase");
			if(EntOk(ent))
			{
				ExplodeBomb(client, ent);
				if(IsClientInGame(client))PrintHintText(client, "bomb exploded");
			}
			CloseHandle(data);
			return Plugin_Stop;
		}
	}
	else
	{
		CloseHandle(data);
		return Plugin_Stop;
	}
}
ExplodeBomb(client, ent1)
{
	decl Float:pos[3];
	GetEntPropVector(ent1, Prop_Send, "m_vecOrigin", pos);
	new ent2=CreateEntityByName("prop_physics"); 
	SetEntPropEnt(ent2, Prop_Data, "m_hOwnerEntity", client)	;	
	DispatchKeyValue(ent2, "model", "models/props_junk/propanecanister001a.mdl"); 
	DispatchSpawn(ent2); 
	TeleportEntity(ent2, pos, NULL_VECTOR, NULL_VECTOR);
	ActivateEntity(ent2);
	SetEntityRenderMode(ent2, RenderMode:3);
	SetEntityRenderColor(ent2, 0, 0, 0, 0);
	AcceptEntityInput(ent2, "Ignite", client, client);

	new ent3=CreateEntityByName("prop_physics"); 
	SetEntPropEnt(ent3, Prop_Data, "m_hOwnerEntity", client)	;	
	DispatchKeyValue(ent3, "model", "models/props_junk/propanecanister001a.mdl"); 
	DispatchSpawn(ent3); 
	TeleportEntity(ent3, pos, NULL_VECTOR, NULL_VECTOR);
	ActivateEntity(ent3);
	SetEntityRenderMode(ent3, RenderMode:3);
	SetEntityRenderColor(ent3, 0, 0, 0, 0);
	AcceptEntityInput(ent3, "Ignite", client, client);
	
	new Handle:h=CreateDataPack();

	WritePackCell(h, client);
	WritePackCell(h, ent1);
	WritePackCell(h, ent2);
	WritePackCell(h, ent3);
	
	WritePackFloat(h, GetConVarFloat(l4d_bomb_damage));
	WritePackFloat(h, GetConVarFloat(l4d_bomb_radius));
	WritePackFloat(h, GetConVarFloat(l4d_bomb_pushforce));
	
	CreateTimer(0.01, ExplodeTnT, h);
}
public Action:ExplodeTnT(Handle:timer, Handle:h)
{
	ResetPack(h);
 	new userid=ReadPackCell(h);
	new ent1=ReadPackCell(h);
	new ent2=ReadPackCell(h);
	new ent3=ReadPackCell(h);
	new Float:damage=ReadPackFloat(h);
	new Float:radius=ReadPackFloat(h);
	new Float:force=ReadPackFloat(h);
	CloseHandle(h);
	decl Float:pos[3];
 	if(ent1>0 && IsValidEntity(ent1) && IsValidEdict(ent1))
	{
		
		GetEntPropVector(ent1, Prop_Send, "m_vecOrigin", pos)
 
		 
 		AcceptEntityInput(ent1, "break", userid);
		RemoveEdict(ent1);
 		if(ent2>0 && IsValidEntity(ent2))
		{
			AcceptEntityInput(ent2, "break",  userid);
			RemoveEdict(ent2);
		}
		if(ent3>0 && IsValidEntity(ent3))
		{
			AcceptEntityInput(ent3, "break",  userid);
			RemoveEdict(ent3);
		}
		
	}else return;
 
	ShowParticle(pos, "gas_explosion_main", 1.0);	
 	new pointHurt = CreateEntityByName("point_hurt");   
 	DispatchKeyValueFloat(pointHurt, "Damage", damage);        
	DispatchKeyValueFloat(pointHurt, "DamageRadius", radius);     
 	DispatchKeyValue(pointHurt, "DamageDelay", "0.0");     
	DispatchSpawn(pointHurt);
	TeleportEntity(pointHurt, pos, NULL_VECTOR, NULL_VECTOR);  
	AcceptEntityInput(pointHurt, "Hurt", userid);    
	CreateTimer(0.1, DeletePointHurt, pointHurt); 
  
	new push = CreateEntityByName("point_push");         
	DispatchKeyValueFloat (push, "magnitude", force);                     
	DispatchKeyValueFloat (push, "radius", radius*1.0);                     
	SetVariantString("spawnflags 24");                             
	AcceptEntityInput(push, "AddOutput");
	DispatchSpawn(push);   
	TeleportEntity(push, pos, NULL_VECTOR, NULL_VECTOR);  
	AcceptEntityInput(push, "Enable", userid, userid);
	CreateTimer(0.5, DeletePushForce, push);
 
	return;
}  
public Action:StopTimer(client)
{
	Energe[client]=0.0;
 		
	if(Timer[client]!=INVALID_HANDLE)
	{
		KillTimer(Timer[client]);
	}
	Timer[client]=INVALID_HANDLE;
	return Plugin_Stop;
}
EntOk(ent)
{
	if(ent>0 && IsValidEdict(ent) &&  IsValidEntity(ent))
	{
		decl String:m_ModelName[PLATFORM_MAX_PATH];
		GetEntPropString(ent, Prop_Data, "m_ModelName", m_ModelName, sizeof(m_ModelName));
		return ItemModelOk(m_ModelName);
	}
	return 0;
}
ItemOk(const String:strName[])
{
	if(StrEqual(strName, "weapon_oxygentank") )	return 1;
	else if(StrEqual(strName, "weapon_propanetank") )	return 1;
	else return 0;
}
ItemModelOk(const String:strName[])
{
	if(StrContains(strName, "oxygentank01")!=-1)	return 1;
	else if(StrContains(strName, "propanecanister001a.mdl")!=-1)	return 1;
	else return 0;
}

public OnEntityDestroyed(entity)
{
	if(entity>0 && IsValidEdict(entity) &&  IsValidEntity(entity))
	{
		decl String:g_classname[20];
		GetEdictClassname(entity, g_classname, 20);	
		decl String:m_ModelName[PLATFORM_MAX_PATH];
		GetEntPropString(entity, Prop_Data, "m_ModelName", m_ModelName, sizeof(m_ModelName));
		//PrintToChatAll("destory %s %d ", m_ModelName, entity);
		if(ItemModelOk(m_ModelName))
		{
			
			
			g_destory_ent=entity;
			new find=0;
			for (new i=1;i<=MaxClients;i++)
			{
				if(entity==ItemEnt[i])
				{
					find=i;
					break;
				}
			}
			if(find)
			{				
				//PrintToChatAll(" find %d -> %d", ItemEnt[find], g_create_ent);
				ItemEnt[find]=g_create_ent;
			}
		}
	}
	
}
public OnEntityCreated(entity, const String:classname[])
{
	if(entity>0 && IsValidEdict(entity) &&  IsValidEntity(entity))
	{
		if(ItemOk(classname))
		{
			g_create_ent=entity;
			//PrintToChatAll("created  %s %d", classname,   entity);
		}
		else if(StrEqual(classname, "physics_prop"))
		{
			//PrintToChatAll("created  %s %d", classname, entity);
			g_create_ent=entity;
		}
	}
}
new String:Gauge1[2] = "-";
new String:Gauge3[2] = "#";
ShowBar(client, String:msg[], Float:pos, Float:max) 
{
	new i ;
	new String:ChargeBar[100];
	Format(ChargeBar, sizeof(ChargeBar), "");
 
	new Float:GaugeNum = pos/max*100;
	if(GaugeNum > 100.0)
		GaugeNum = 100.0;
	if(GaugeNum<0.0)
		GaugeNum = 0.0;
 	for(i=0; i<100; i++)
		ChargeBar[i] = Gauge1[0];
	new p=RoundFloat( GaugeNum);
	 
	if(p>=0 && p<100)ChargeBar[p] = Gauge3[0]; 
 	/* Display gauge */
	PrintCenterText(client, "%s  %3.0f %\n<< %s >>", msg, GaugeNum, ChargeBar);
}
public AttachParticle(i_Ent, String:s_Effect[], Float:f_Origin[3])
{
	decl i_Particle, String:s_TargetName[32];
	
	i_Particle = CreateEntityByName("info_particle_system");
	
	if(i_Particle>0 && IsValidEdict(i_Particle) &&  IsValidEntity(i_Particle))
	{
	 
		f_Origin[2] -= 7.5;
		TeleportEntity(i_Particle, f_Origin, NULL_VECTOR, NULL_VECTOR)
		FormatEx(s_TargetName, sizeof(s_TargetName), "particle%d", i_Ent)
		DispatchKeyValue(i_Particle, "targetname", s_TargetName)
		GetEntPropString(i_Ent, Prop_Data, "m_iName", s_TargetName, sizeof(s_TargetName))
		DispatchKeyValue(i_Particle, "parentname", s_TargetName)
		DispatchKeyValue(i_Particle, "effect_name", s_Effect)
		DispatchSpawn(i_Particle)
		SetVariantString(s_TargetName)
		AcceptEntityInput(i_Particle, "SetParent", i_Particle, i_Particle, 0)
		ActivateEntity(i_Particle)
		AcceptEntityInput(i_Particle, "Start")
	}
	else i_Particle=0;
	return i_Particle
}
public Action:DeleteParticles(Handle:timer, any:particle)
{
	 if(particle>0 && IsValidEdict(particle) &&  IsValidEntity(particle))
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
 
public SafeDeleteEntity(any:ent, String:name[])
{
	 if( ent>0 && IsValidEdict(ent) &&  IsValidEntity(ent))
	 {
		 decl String:classname[64];
		 GetEdictClassname(ent, classname, sizeof(classname));
		 if (StrEqual(classname, name, false))
		 {
			AcceptEntityInput(ent, "Kill"); 
			RemoveEdict(ent);
		 }
	 }
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
		CreateTimer(time, DeleteParticles, particle);
 } 
}
 
public Action:DeletePointHurt(Handle:timer, any:ent)
{
	 if (IsValidEntity(ent))
	 {
		 decl String:classname[64];
		 GetEdictClassname(ent, classname, sizeof(classname));
		 if (StrEqual(classname, "point_hurt", false))
				{
					AcceptEntityInput(ent, "Kill"); 
					RemoveEdict(ent);
				}
		 }

}
public Action:DeletePushForce(Handle:timer, any:ent)
{
	 if (IsValidEntity(ent))
	 {
		 decl String:classname[64];
		 GetEdictClassname(ent, classname, sizeof(classname));
		 if (StrEqual(classname, "point_push", false))
				{
 					AcceptEntityInput(ent, "Disable");
					AcceptEntityInput(ent, "Kill"); 
					RemoveEdict(ent);
				}
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
		CreateTimer(0.01, DeleteParticles, particle);
 } 
}