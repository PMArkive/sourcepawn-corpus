/* Plugin Template generated by Pawn Studio */

#include <sourcemod>
#include <tf2>

#define VERSION "1.0.1"

new Handle:g_Cvar_Enabled = INVALID_HANDLE;
new Handle:g_Maplist = INVALID_HANDLE;
new g_Maplist_Serial = -1;

public Plugin:myinfo = 
{
	name = "TF Force Halloween",
	author = "Powerlord",
	description = "Enables Halloween mode on specific maps",
	version = VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=165587"
}

public OnPluginStart()
{
	CreateConVar("tfh_version", VERSION, "TF Forve Halloween verison", FCVAR_REPLICATED | FCVAR_DONTRECORD | FCVAR_SPONLY);
	g_Cvar_Enabled = CreateConVar("tfh_enabled", "1.0", "Enable TF Force Halloween", FCVAR_NONE, true, 0.0, true, 1.0);
	
	g_Maplist = CreateArray(ByteCountToCells(33));

	// Bind the map list file to the "halloween" map list
	decl String:mapListPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, mapListPath, sizeof(mapListPath), "configs/halloween_maps.txt");
	SetMapListCompatBind("halloween", mapListPath);
}

public OnMapStart()
{
	if (ReadMapList(g_Maplist,
	g_Maplist_Serial,
	"halloween",
	MAPLIST_FLAG_CLEARARRAY|MAPLIST_FLAG_NO_DEFAULT)
	!= INVALID_HANDLE)
	{
		LogMessage("Loaded/Updated Halloween map list");
	}
	// Check if the map list was ever loaded
	else if (g_Maplist_Serial == -1)
	{
		SetFailState("Halloween map list can't be loaded,");
	}
}

public Action:TF2_OnGetHoliday(&TFHoliday:holiday)
{
	if (GetConVarBool(g_Cvar_Enabled) && holiday != TFHoliday_Halloween)
	{
		decl String:mapname[32];
		GetCurrentMap(mapname, sizeof(mapname));
		if (IsHalloweenMap(mapname))
		{
			LogMessage("Halloween map detected: %s", mapname);
			holiday = TFHoliday_Halloween;
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

stock bool:IsHalloweenMap(const String:mapname[])
{
	new mapIndex = FindStringInArray(g_Maplist, mapname);
	return (mapIndex > -1);
}