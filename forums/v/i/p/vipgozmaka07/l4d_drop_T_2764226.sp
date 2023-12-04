/* Plugin Template generated by Pawn Studio */

#include <sourcemod>
#include <sdktools>

new bool:CanPlayerDrop[MAXPLAYERS+1];
new Handle:h_ClientTimer[MAXPLAYERS+1] = INVALID_HANDLE;
new bool:l4d2=false;

new IMPULS_SPRAY 					= 201;

public Plugin:myinfo = 
{
	name = "L4D & L4D2 item drop",
	author = "Pan Xiaohai & Frustian & kwski43",
	description = "<- Description ->",
	version = "1.1",
	url = "<- URL ->"
}

public OnPluginStart()
{
	decl String:GameName[16];
	GetGameFolderName(GameName, sizeof(GameName));
	if (StrEqual(GameName, "left4dead2", false))
	{
		l4d2=true;
	}
	else
	{
		l4d2=false;
	}
	
	RegConsoleCmd("sm_drop", Command_Drop);
}

public OnClientPutInServer(client)
{
	CanPlayerDrop[client] = true;
}

public OnClientDisconnect(client)
{
	if(h_ClientTimer[client] != INVALID_HANDLE)
	{
		KillTimer(h_ClientTimer[client]);
		h_ClientTimer[client] = INVALID_HANDLE;
	}
}

public Action:OnPlayerRunCmd(client, &buttons, &impuls, Float:vel[3], Float:angles[3], &weapon)
{
	if(CanPlayerDrop[client] == false && buttons & IN_SPEED && impuls==IMPULS_SPRAY)
	{
		impuls &= ~IMPULS_SPRAY;
		return Plugin_Continue;
	}
	
	if(GetClientTeam(client) == 2 && !IsFakeClient(client) && IsPlayerAlive(client) && (buttons & IN_SPEED) && (impuls==IMPULS_SPRAY) && h_ClientTimer[client] == INVALID_HANDLE)
	{
		impuls &= ~IMPULS_SPRAY;
		CanPlayerDrop[client] = false;
		h_ClientTimer[client] = CreateTimer(0.1, Timer_CanPlayerDrop_Reset, client);
	}
	
	return Plugin_Continue;
}

public Action:Timer_CanPlayerDrop_Reset(Handle:timer, any:client)
{
	h_ClientTimer[client] = INVALID_HANDLE;
	
	CanPlayerDrop[client] = false;
	CreateTimer(0.5, ResetDelay, client);
	Command_Drop(client, 0);
}

public Action:ResetDelay(Handle:timer, any:client)
{
	CanPlayerDrop[client] = true;
}

public Action:Command_Drop(client, args)
{
	if (client == 0 || GetClientTeam(client) != 2 || !IsPlayerAlive(client))return Plugin_Handled;
	
	Drop(client, true, 0,true);
	return Plugin_Handled;
}

GetCurrentWeaponSlot(client)
{
	new slot=-1; 
	
	decl String:weapon[32];
	GetClientWeapon(client,weapon , 32);
	//PrintToChatAll("%s",weapon);
	
	if (StrEqual(weapon, "weapon_pumpshotgun") || StrEqual(weapon, "weapon_autoshotgun") || StrEqual(weapon, "weapon_rifle") || StrEqual(weapon, "weapon_smg") || StrEqual(weapon, "weapon_hunting_rifle") || StrEqual(weapon, "weapon_sniper_scout") || StrEqual(weapon, "weapon_sniper_military") || StrEqual(weapon, "weapon_sniper_awp") || StrEqual(weapon, "weapon_smg_silenced") || StrEqual(weapon, "weapon_smg_mp5") || StrEqual(weapon, "weapon_shotgun_spas") || StrEqual(weapon, "weapon_shotgun_chrome") || StrEqual(weapon, "weapon_rifle_sg552") || StrEqual(weapon, "weapon_rifle_desert") || StrEqual(weapon, "weapon_rifle_ak47") || StrEqual(weapon, "weapon_grenade_launcher") || StrEqual(weapon, "weapon_rifle_m60"))
		slot=0;
	else if (StrEqual(weapon, "weapon_pistol") || StrEqual(weapon, "weapon_pistol_magnum") || StrEqual(weapon, "weapon_chainsaw") || StrEqual(weapon, "weapon_melee"))
		slot=1;
	else if (StrEqual(weapon, "weapon_pipe_bomb") || StrEqual(weapon, "weapon_molotov") || StrEqual(weapon, "weapon_vomitjar"))
		slot=2;
	else if (StrEqual(weapon, "weapon_first_aid_kit") || StrEqual(weapon, "weapon_defibrillator") || StrEqual(weapon, "weapon_upgradepack_explosive") || StrEqual(weapon, "weapon_upgradepack_incendiary"))
		slot=3;
	else if (StrEqual(weapon, "weapon_pain_pills") || StrEqual(weapon, "weapon_adrenaline"))
		slot=4;

	if(slot	<0)
	{
	 
		for(new i=0; i<5; i++)
		{
			new s=GetPlayerWeaponSlot(client, i);
			if(s>0)
			{
				slot=i;
				break;
			}
		} 
	}
	return slot;
}

Drop(client, bool:dropcurrent, count, bool:drop)
{
	if(dropcurrent)
	{
		new s=GetCurrentWeaponSlot(client);
		if(s>=0)
		{
			DropSlot2(client, s, drop); 
		}
	}
	if(count==0 && !dropcurrent)count=1;
	if(count>0)
	{
		new slot[5];
		new m=0;
		for(new i=0; i<5; i++)
		{
			if (GetPlayerWeaponSlot(client, i) > 0)
			{
				slot[m++]=i;
			}
		}
		if(m<=count)count=m;
		for(new i=0; i<count && m>0; i++)
		{
			new r=GetRandomInt(0, m-1);
			DropSlot2(client, slot[r], drop);
			slot[r]=slot[m-1];
			m--;
		}
	}
}

DropSlot2(client, slot, bool:drop=false)
{
	if(l4d2)DropSlot_l4d2(client, slot, drop);
	//else DropSlot_l4d1(client, slot, drop,receiver);
}

#define MODEL_V_FIREAXE "models/weapons/melee/v_fireaxe.mdl"
#define MODEL_V_FRYING_PAN "models/weapons/melee/v_frying_pan.mdl"
#define MODEL_V_MACHETE "models/weapons/melee/v_machete.mdl"
#define MODEL_V_BASEBALL_BAT "models/weapons/melee/v_bat.mdl"
#define MODEL_V_CROWBAR "models/weapons/melee/v_crowbar.mdl"
#define MODEL_V_CRICKET_BAT "models/weapons/melee/v_cricket_bat.mdl"
#define MODEL_V_TONFA "models/weapons/melee/v_tonfa.mdl"
#define MODEL_V_KATANA "models/weapons/melee/v_katana.mdl"
#define MODEL_V_ELECTRIC_GUITAR "models/weapons/melee/v_electric_guitar.mdl"
#define MODEL_V_GOLFCLUB "models/weapons/melee/v_golfclub.mdl"
#define MODEL_V_SHIELD "models/weapons/melee/v_riotshield.mdl"
#define MODEL_V_KNIFE "models/v_models/v_knife_t.mdl"


// code from kwski43 [L4D2] Caught Item Drop http://forums.alliedmods.net/showthread.php?t=133610
DropSlot_l4d2(client, slot, bool:drop=false)
{
	new oldweapon=GetPlayerWeaponSlot(client, slot);
	if (oldweapon > 0)
	{
		new String:weapon[32];
		new ammo;
		new clip;
		new upgrade;
		new upammo;
		new ammoOffset = FindSendPropInfo("CTerrorPlayer", "m_iAmmo");
		GetEdictClassname(oldweapon, weapon, 32);

		if (slot == 0)
		{
			clip = GetEntProp(oldweapon, Prop_Send, "m_iClip1");
			upgrade = GetEntProp(oldweapon, Prop_Send, "m_upgradeBitVec");
			upammo = GetEntProp(oldweapon, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded");
			if (StrEqual(weapon, "weapon_rifle") || StrEqual(weapon, "weapon_rifle_sg552") || StrEqual(weapon, "weapon_rifle_desert") || StrEqual(weapon, "weapon_rifle_ak47"))
			{
				ammo = GetEntData(client, ammoOffset+(12));
				SetEntData(client, ammoOffset+(12), 0);
			}
			else if (StrEqual(weapon, "weapon_smg") || StrEqual(weapon, "weapon_smg_silenced") || StrEqual(weapon, "weapon_smg_mp5"))
			{
				ammo = GetEntData(client, ammoOffset+(20));
				SetEntData(client, ammoOffset+(20), 0);
			}
			else if (StrEqual(weapon, "weapon_pumpshotgun") || StrEqual(weapon, "weapon_shotgun_chrome"))
			{
				ammo = GetEntData(client, ammoOffset+(28));
				SetEntData(client, ammoOffset+(28), 0);
			}
			else if (StrEqual(weapon, "weapon_autoshotgun") || StrEqual(weapon, "weapon_shotgun_spas"))
			{
				ammo = GetEntData(client, ammoOffset+(32));
				SetEntData(client, ammoOffset+(32), 0);
			}
			else if (StrEqual(weapon, "weapon_hunting_rifle"))
			{
				ammo = GetEntData(client, ammoOffset+(36));
				SetEntData(client, ammoOffset+(36), 0);
			}
			else if (StrEqual(weapon, "weapon_sniper_scout") || StrEqual(weapon, "weapon_sniper_military") || StrEqual(weapon, "weapon_sniper_awp"))
			{
				ammo = GetEntData(client, ammoOffset+(40));
				SetEntData(client, ammoOffset+(40), 0);
			}
			else if (StrEqual(weapon, "weapon_grenade_launcher"))
			{
				ammo = GetEntData(client, ammoOffset+(68));
				SetEntData(client, ammoOffset+(68), 0);
			}
			else return;
		}
		new index = CreateEntityByName(weapon); 
		//index=oldweapon;
		new bool:dual=false;
		if (slot == 1)
		{
			if (StrEqual(weapon, "weapon_melee"))
			{
				new String:item[150];
				GetEntPropString(oldweapon , Prop_Data, "m_ModelName", item, sizeof(item));
				//PrintToChat(client, "%s", item);
				if (StrEqual(item, MODEL_V_FIREAXE))
				{
					//DispatchKeyValue(index, "model", MODEL_V_FIREAXE);
					DispatchKeyValue(index, "melee_script_name", "fireaxe");
				}
				else if (StrEqual(item, MODEL_V_FRYING_PAN))
				{
					//DispatchKeyValue(index, "model", MODEL_V_FRYING_PAN);
					DispatchKeyValue(index, "melee_script_name", "frying_pan");
				}
				else if (StrEqual(item, MODEL_V_MACHETE))
				{
					//DispatchKeyValue(index, "model", MODEL_V_MACHETE);
					DispatchKeyValue(index, "melee_script_name", "machete");
				}
				else if (StrEqual(item, MODEL_V_BASEBALL_BAT))
				{
					//DispatchKeyValue(index, "model", MODEL_V_BASEBALL_BAT);
					DispatchKeyValue(index, "melee_script_name", "baseball_bat");
				}
				else if (StrEqual(item, MODEL_V_CROWBAR))
				{
					//DispatchKeyValue(index, "model", MODEL_V_CROWBAR);
					DispatchKeyValue(index, "melee_script_name", "crowbar");
				}
				else if (StrEqual(item, MODEL_V_CRICKET_BAT))
				{
					//DispatchKeyValue(index, "model", MODEL_V_CRICKET_BAT);
					DispatchKeyValue(index, "melee_script_name", "cricket_bat");
				}
				else if (StrEqual(item, MODEL_V_TONFA))
				{
					//DispatchKeyValue(index, "model", MODEL_V_TONFA);
					DispatchKeyValue(index, "melee_script_name", "tonfa");
				}
				else if (StrEqual(item, MODEL_V_KATANA))
				{
					//DispatchKeyValue(index, "model", MODEL_V_KATANA);
					DispatchKeyValue(index, "melee_script_name", "katana");
				}
				else if (StrEqual(item, MODEL_V_ELECTRIC_GUITAR))
				{
					//DispatchKeyValue(index, "model", MODEL_V_ELECTRIC_GUITAR);
					DispatchKeyValue(index, "melee_script_name", "electric_guitar");
				}
				else if (StrEqual(item, MODEL_V_GOLFCLUB))
				{
					//DispatchKeyValue(index, "model", MODEL_V_GOLFCLUB);
					DispatchKeyValue(index, "melee_script_name", "golfclub");
				}
				else if (StrEqual(item, MODEL_V_SHIELD))
				{
					//DispatchKeyValue(index, "model", MODEL_V_GOLFCLUB);
					DispatchKeyValue(index, "melee_script_name", "riotshield");
				}
				else if (StrEqual(item, MODEL_V_KNIFE))
				{
					//DispatchKeyValue(index, "model", MODEL_V_GOLFCLUB);
					DispatchKeyValue(index, "melee_script_name", "knife");
				}
				else return;
			}
			else if (StrEqual(weapon, "weapon_chainsaw"))
			{
				clip = GetEntProp(oldweapon, Prop_Send, "m_iClip1");
			}
			else if (StrEqual(weapon, "weapon_pistol"))
			{
				clip = GetEntProp(oldweapon, Prop_Send, "m_iClip1");
				dual=GetEntProp(oldweapon, Prop_Send, "m_hasDualWeapons"); 
				if(dual)clip=0;
			}
			else if (StrEqual(weapon, "weapon_pistol_magnum"))
			{
				clip = GetEntProp(oldweapon, Prop_Send, "m_iClip1");
			}
			else return;
		}
		
		RemovePlayerItem(client, oldweapon);
		
		new Float:origin[3];
		new Float:ang[3];
		GetClientEyePosition(client,origin);
		GetClientEyeAngles(client, ang);
		GetAngleVectors(ang, ang, NULL_VECTOR,NULL_VECTOR);
		NormalizeVector(ang,ang);
		if(drop)ScaleVector(ang, 500.0);
		else ScaleVector(ang, 300.0);
		
		DispatchSpawn(index);
		TeleportEntity(index, origin, NULL_VECTOR, ang);
		ActivateEntity(index); 

		if (slot == 0)
		{
			SetEntProp(index, Prop_Send, "m_iExtraPrimaryAmmo", ammo);
			SetEntProp(index, Prop_Send, "m_iClip1", clip);
			SetEntProp(index, Prop_Send, "m_upgradeBitVec", upgrade);
			SetEntProp(index, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", upammo);
		}

		if (slot == 1)
		{
			if (StrEqual(weapon, "weapon_chainsaw") || StrEqual(weapon, "weapon_pistol"))
			{
				SetEntProp(index, Prop_Send, "m_iClip1", clip);
			}
			if(dual)
			{
				SetCommandFlags("give", GetCommandFlags("give") & ~FCVAR_CHEAT);
				FakeClientCommand(client, "give pistol");
				SetCommandFlags("give", GetCommandFlags("give") | FCVAR_CHEAT);
			}
		}
	}
}