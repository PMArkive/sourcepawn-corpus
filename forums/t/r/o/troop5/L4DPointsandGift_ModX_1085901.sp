//Index
//1: Variables
//2: Setup Convars
//3: Event Hooks
//4: Points Reminder System
//5: Receiving Points
//6: Admin Functions
//7: Points Menu
//8: Item Cost
//9: Repeat Buy
//10: Item Buying Menu Setup
//11: Item Buying Menus

//1: Variables
#define PLAYERS 20

#pragma semicolon 1
#include <sourcemod>
#undef REQUIRE_PLUGIN
#include <sdktools>
#include <adminmenu>
#define PLUGIN_VERSION "1.351 Modified"
#define CVAR_FLAGS FCVAR_PLUGIN
#define SURVIVORTEAM 2
#define INFECTEDTEAM 3

public Plugin:myinfo = 
{
    name = "[L4D2] Points and Gift System",
    author = "Drakcol - Fixed by AXIS_ASAKI",
    description = "An item buying system for Left 4 Dead 2 that is based on (-DR-)GrammerNatzi's Left 4 Dead 1 item buying system. This plug-in allows clients to gain points through various accomplishments and use them to buy items and health/ammo refills. It also allows admins to gift the same things to players and grant them god mode. Both use menus, no less.",
    version = PLUGIN_VERSION,
    url = ""
}

/*Some Important Variables*/
new godon[PLAYERS + 1];
new points[PLAYERS + 1];
new pointskillcount[PLAYERS + 1];
new pointsteam[PLAYERS + 1];
new numtanks;
new numwitches;
new tankonfire[PLAYERS + 25];
new buyitem[PLAYERS + 5];
new pointsremindtimer;
new pointsremindnumtimer;
new pointstimer;
new bool:pointson;
new numrounds;
new pointshurtcount[PLAYERS + 1];

/*Convar Variables*/
new Handle:pointsoncvar;
new Handle:pointsinfected;
new Handle:pointsspecial;
new Handle:pointsheal;
new Handle:pointsrevive;
new Handle:pointsonversus;
new Handle:pointsonrealism;
new Handle:pointsonsurvival;
new Handle:pointsontscavenge;
new Handle:pointsontversus;
new Handle:pointsoncoop;
new Handle:pointsonscavenger;
new Handle:pointsadvertising;
new Handle:pointsnumreminder;
new Handle:pointswitchinsta;
new Handle:pointswitch;
new Handle:pointstankburn;
new Handle:pointstankkill;
new Handle:pointshurt;
new Handle:pointsminigun;
new Handle:pointsheadshot;
new Handle:pointsinfectednum;
new Handle:pointsgrab;
new Handle:pointspounce;
new Handle:pointsincapacitate;
new Handle:pointsvomit;
new Handle:pointsadvertisingticks;
new Handle:pointsremindticks;
new Handle:pointsresetround;
new Handle:pointsresetrounds;


/*Item-Related Convars*/
new Handle:tanklimit;
new Handle:witchlimit;

/*Price Convars*/
new Handle:shotpoints;
new Handle:smgpoints;
new Handle:riflepoints;
new Handle:autopoints;
new Handle:huntingpoints;
new Handle:pipepoints;
new Handle:molopoints;
new Handle:pillspoints;
new Handle:medpoints;
new Handle:pistolpoints;
new Handle:refillpoints;
new Handle:healpoints;

/*Melee Weapon Convars*/
new Handle:baseballbatpoints;
new Handle:riotshieldpoints;
new Handle:guitarpoints;
new Handle:fryingpanpoints;
new Handle:machetepoints;
new Handle:tonfapoints;
new Handle:fireaxepoints;
new Handle:crowbarpoints;
new Handle:cricketbatpoints;
new Handle:katanapoints;
new Handle:knifepoints;

/*L4D2 Price Convars*/
new Handle:adrenalinepoints;
new Handle:defibpoints;
new Handle:spasshotpoints;
new Handle:chromeshotpoints;
new Handle:magnumpoints;
new Handle:ak47points;
new Handle:desertpoints;
new Handle:sg552points;
new Handle:silencedsmgpoints;
new Handle:mp5points;
new Handle:awppoints;
new Handle:militarypoints;
new Handle:scoutpoints;
new Handle:grenadepoints;
new Handle:fireworkpoints;
new Handle:vomitjarpoints;
new Handle:oxygenpoints;
new Handle:propanepoints;
new Handle:explosivepoints;
new Handle:explosivepackpoints;
new Handle:chainsawpoints;
new Handle:gascanpoints;
new Handle:laserpoints;

/*Disable Whole Weapon Categories*/
new Handle:healthcat;
new Handle:meleecat;
new Handle:weaponscat;
new Handle:smgcat;
new Handle:riflecat;
new Handle:snipercat;
new Handle:shotguncat;
new Handle:pistolcat;
new Handle:explosivescat;
new Handle:ammocat;

/*Infected Price Convars*/
new Handle:suicidepoints;
new Handle:ihealpoints;
new Handle:boomerpoints;
new Handle:hunterpoints;
new Handle:smokerpoints;
new Handle:tankpoints;
new Handle:wwitchpoints;
new Handle:panicpoints;
new Handle:mobpoints;
new Handle:spitterpoints;
new Handle:chargerpoints;
new Handle:jockeypoints;

/*Special Price Convars*/
new Handle:burnpoints;
new Handle:burnpackpoints;

//2: Setup Convars
public OnPluginStart()
{
	/*Commands*/
	RegAdminCmd("laser", Laser, ADMFLAG_KICK);
	RegAdminCmd("fammo", FAmmo, ADMFLAG_KICK);
	RegAdminCmd("eammo", EAmmo, ADMFLAG_KICK);
	RegAdminCmd("refill", Refill, ADMFLAG_KICK);
	RegAdminCmd("heal", Heal, ADMFLAG_KICK);
	RegConsoleCmd("debugteamid",TeamID);
	RegConsoleCmd("points", ShowPoints);
	RegConsoleCmd("repeatbuy",RepeatBuy);
	RegAdminCmd("fakegod",FakeGod, ADMFLAG_KICK);
	RegConsoleCmd("itempointshelp", PointsHelp);
	RegConsoleCmd("usepoints", PointsMenu);
	RegConsoleCmd("usepointsspecial", PointsSpecialMenu);
	RegConsoleCmd("pointsmenu1health", PointsMenu1Health);
	RegConsoleCmd("pointsmenu1melee", PointsMenu1Melee);
	RegConsoleCmd("pointsmenu1weapons", PointsMenu1Weapons);
	RegConsoleCmd("pointsmenu1smgs", PointsMenu1Smgs);
	RegConsoleCmd("pointsmenu1rifles", PointsMenu1Rifles);
	RegConsoleCmd("pointsmenu1snipers", PointsMenu1Snipers);
	RegConsoleCmd("pointsmenu1shotguns", PointsMenu1Shotguns);
	RegConsoleCmd("pointsmenu1pistols", PointsMenu1Pistols);
	RegConsoleCmd("pointsmenu1explosive", PointsMenu1Explosives);
	RegConsoleCmd("pointsconfirm", PointsConfirm);
	RegAdminCmd("sm_clientsetpoints",Command_SetPoints,ADMFLAG_KICK,"sm_clientsetpoints <#userid|name> [number of points]");
	RegAdminCmd("sm_clientgivepoints",Command_GivePoints,ADMFLAG_KICK,"sm_clientgivepoints <#userid|name> [number of points]");
	//this signals that the plugin is on on this server
	CreateConVar("points_gift_on", PLUGIN_VERSION, "Points_Gift_On", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	/* Values for Convars*/
	pointsoncvar = CreateConVar("points_on","1","Point system on or off?",CVAR_FLAGS, true, 0.0);
	pointsinfected = CreateConVar("points_amount_infected","2","How many points for killing a certain number of infected.",CVAR_FLAGS, true, 0.0);
	pointsspecial = CreateConVar("points_amount_specialinfected","1","How many points for killing a special infected.",CVAR_FLAGS, true, 0.0);
	pointsheal = CreateConVar("points_amount_heal","5","How many points for healing someone.",CVAR_FLAGS, true, 0.0);
	pointsrevive = CreateConVar("points_amount_revive","3","How many points for reviving someone.",CVAR_FLAGS, true, 0.0);
	pointsonversus = CreateConVar("points_on_versus","1","Points spending on or off in versus mode?",CVAR_FLAGS, true, 0.0);
	pointsonrealism = CreateConVar("points_on_realism","1","Points spending on or off in realism mode?",CVAR_FLAGS, true, 0.0);
	pointsoncoop = CreateConVar("points_on_coop","1","Points spending on or off in coop mode?",CVAR_FLAGS, true, 0.0);
	pointsonscavenger = CreateConVar("points_on_scavenger","1","Points spending on or off in scavenger mode?",CVAR_FLAGS, true, 0.0);
	pointsonsurvival = CreateConVar("points_on_survival","1","Points spending on or off in survival mode?",CVAR_FLAGS, true, 0.0);
	pointsontscavenge = CreateConVar("points_on_survival","1","Points spending on or off in team survival mode?",CVAR_FLAGS, true, 0.0);
	pointsontversus = CreateConVar("points_on_survival","1","Points spending on or off in team versus mode?",CVAR_FLAGS, true, 0.0);
	pointsadvertising = CreateConVar("points_advertising","1","Do we want the plugin to advertise itself? 1 chat box message, 2 hint text message, 0 for none.",CVAR_FLAGS, true, 0.0);
	pointsnumreminder = CreateConVar("points_advertising_remind","0","Reminds the players how to get their number keys to properly work. 1 for yes, 0 for no.",CVAR_FLAGS,true,0.0);
	pointswitch = CreateConVar("points_amount_witch","5","How many points you get for killing a witch.",CVAR_FLAGS,true,0.0);
	pointswitchinsta = CreateConVar("points_amount_witch_instakill","3","How many extra points you get for killing a witch in one shot.",CVAR_FLAGS,true,0.0);
	pointstankburn = CreateConVar("points_amount_tank_burn","2","How many points you get for burning a tank.",CVAR_FLAGS,true,0.0);
	pointstankkill = CreateConVar("points_amount_tank","2","How many additional points you get for killing a tank.",CVAR_FLAGS,true,0.0);
	pointshurt = CreateConVar("points_amount_infected_hurt","2","How many points infected get for hurting survivors a number of times.",CVAR_FLAGS,true,0.0);
	pointsinfectednum = CreateConVar("points_amount_infectednum","25","How many killed infected does it take to earn points? Headshot and minigun kills can be used to rank up extra kills.",CVAR_FLAGS,true,0.0);
	pointsheadshot = CreateConVar("points_amount_extra_headshotkills","1","How many extra kills are survivors awarded for scoring headshots? 0 = None.",CVAR_FLAGS,true, 0.0);
	pointsminigun = CreateConVar("points_amount_extra_minigunkills","1","How many extra kills are survivors awarded for scoring minigun kills? 0 = None.",CVAR_FLAGS,true, 0.0);
	pointsincapacitate = CreateConVar("points_amount_infected_incapacitation","5","How many points you get for incapacitating a survivor",CVAR_FLAGS,true,0.0);
	//pointsvson = CreateConVar("points_on_infected","1","Do infected in versus get points or not?",CVAR_FLAGS,true,0.0);
	pointsgrab = CreateConVar("points_amount_infected_pull","1","How many points you get [as a smoker] when you pull a survivor.",CVAR_FLAGS,true,0.0);
	pointspounce = CreateConVar("points_amount_infected_pounce","1","How many points you get [as a hunter] when you pounce a survivor.",CVAR_FLAGS,true,0.0);
	pointsvomit = CreateConVar("points_amount_infected_vomit","1","How many points you get [as a boomer] when you vomit/explode on a survivor.",CVAR_FLAGS,true,0.0);
	pointsadvertisingticks = CreateConVar("points_advertising_ticks","80","How many seconds before the optional advertisement is displayed again.",CVAR_FLAGS,true,0.0);
	pointsremindticks = CreateConVar("points_advertising_remind_ticks","60","How many seconds before the optional gamepad reminder is displayed again.",CVAR_FLAGS,true,0.0);
	pointsresetround = CreateConVar("points_reset_round","0","Reset points when a certain amount of rounds end? Resets at end of campaign in coop, a defined amount rounds in versus, and every round in survival.",CVAR_FLAGS, true, 0.0);
	pointsresetrounds = CreateConVar("points_reset_round_amount","2","How many rounds until reset in versus?",CVAR_FLAGS, true, 0.0);
	
	/*Price Convars*/
	shotpoints = CreateConVar("points_price_shotgun","5","How many points a shotgun costs.",CVAR_FLAGS, true, -1.0);
	smgpoints = CreateConVar("points_price_smg","5","How many points a smg costs.",CVAR_FLAGS, true, -1.0);
	riflepoints = CreateConVar("points_price_rifle","10","How many points a rifle costs.",CVAR_FLAGS, true, -1.0);
	huntingpoints = CreateConVar("points_price_huntingrifle","15","How many points a hunting rifle costs.",CVAR_FLAGS, true, -1.0);
	autopoints = CreateConVar("points_price_autoshotgun","15","How many points an auto-shotgun costs.",CVAR_FLAGS, true, -1.0);
	pipepoints = CreateConVar("points_price_pipebomb","3","How many points a pipe-bomb costs.",CVAR_FLAGS, true, -1.0);
	molopoints = CreateConVar("points_price_molotov","4","How many points a molotov costs.",CVAR_FLAGS, true, -1.0);
	pistolpoints = CreateConVar("points_price_pistol","5","How many points an extra pistol costs.",CVAR_FLAGS, true, -1.0);
	pillspoints = CreateConVar("points_price_painpills","5","How many points a bottle of pills costs.",CVAR_FLAGS, true, -1.0);
	medpoints = CreateConVar("points_price_medkit","10","How many points a medkit costs.",CVAR_FLAGS, true, -1.0);
	refillpoints = CreateConVar("points_price_refill","5","How many points an ammo refill costs.",CVAR_FLAGS, true, -1.0);
	healpoints = CreateConVar("points_price_heal","20","How many points a heal costs.",CVAR_FLAGS, true, -1.0);

	/*Melee Weapon Price Convars*/
	baseballbatpoints = CreateConVar("points_baseballbat","5","How many points a baseball bat costs.",CVAR_FLAGS, true, -1.0);
	riotshieldpoints = CreateConVar("points_riotshield","5","How many points a riot shield costs.",CVAR_FLAGS, true, -1.0);
	guitarpoints = CreateConVar("points_guitar","5","How many points an electric guitar costs.",CVAR_FLAGS, true, -1.0);
	fryingpanpoints = CreateConVar("points_fryingpan","5","How many points a frying pan costs.",CVAR_FLAGS, true, -1.0);
	machetepoints = CreateConVar("points_machete","5","How many points a machete costs.",CVAR_FLAGS, true, -1.0);
	tonfapoints = CreateConVar("points_tonfa","5","How many points a tonfa costs.",CVAR_FLAGS, true, -1.0);
	fireaxepoints = CreateConVar("points_fireaxe","5","How many points a fireaxe costs.",CVAR_FLAGS, true, -1.0);
	crowbarpoints = CreateConVar("points_crowbar","5","How many points a crowbar costs.",CVAR_FLAGS, true, -1.0);
	cricketbatpoints = CreateConVar("points_cricketbat","5","How many points a cricket bat costs.",CVAR_FLAGS, true, -1.0);
	katanapoints = CreateConVar("points_katana","5","How many points a katana costs.",CVAR_FLAGS, true, -1.0);
	knifepoints = CreateConVar("points_knife","5","How many points a knife costs.",CVAR_FLAGS, true, -1.0);
	
	/*L4D2 Price Convars*/
	adrenalinepoints = CreateConVar("points_price_adrenaline","15","How many points a shot costs.",CVAR_FLAGS, true, -1.0); 
	defibpoints = CreateConVar("points_price_defib","8","How many points a defib costs.",CVAR_FLAGS, true, -1.0);
	spasshotpoints = CreateConVar("points_price_spasshot","12","How many points a Spas Shotgun costs.",CVAR_FLAGS, true, -1.0);
	chromeshotpoints = CreateConVar("points_price_chromeshot","12","How many points a chrome shotgun costs.",CVAR_FLAGS, true, -1.0);
	magnumpoints = CreateConVar("points_price_magnum","8","How many points a Magnum costs.",CVAR_FLAGS, true, -1.0);
	ak47points = CreateConVar("points_price_ak47","10","How many points an AK47 costs.",CVAR_FLAGS, true, -1.0);
	desertpoints = CreateConVar("points_price_desert","10","How many points a desert rifle costs.",CVAR_FLAGS, true, -1.0);
	sg552points = CreateConVar("points_price_sg552","15","How many points a SG552 rifle costs.",CVAR_FLAGS, true, -1.0);
	silencedsmgpoints = CreateConVar("points_price_silencedsmg","5","How many points a Silenced SMG costs.",CVAR_FLAGS, true, -1.0);
	mp5points = CreateConVar("points_price_mp5","10","How many points a MP5 SMG costs.",CVAR_FLAGS, true, -1.0);
	awppoints = CreateConVar("points_price_awp","12","How many points an AWP sniper rifle costs.",CVAR_FLAGS, true, -1.0);
	militarypoints = CreateConVar("points_price_military","15","How many points a military sniper rifle costs.",CVAR_FLAGS, true, -1.0);
	scoutpoints = CreateConVar("points_price_scout","12","How many points a scout sniper rifle costs.",CVAR_FLAGS, true, -1.0);
	grenadepoints = CreateConVar("points_price_grenade","20","How many points a grenade launcher costs.",CVAR_FLAGS, true, -1.0);
	fireworkpoints = CreateConVar("points_price_firework","5","How many points a fireworks crate costs.",CVAR_FLAGS, true, -1.0);
	vomitjarpoints = CreateConVar("points_price_vomitjar","5","How many points a vomitjar costs.",CVAR_FLAGS, true, -1.0);
	oxygenpoints = CreateConVar("points_price_oxygen","5","How many points an oxygen tank costs.",CVAR_FLAGS, true, -1.0);
	propanepoints = CreateConVar("points_price_propane","5","How many points a propane tank costs.",CVAR_FLAGS, true, -1.0);
	explosivepoints = CreateConVar("points_price_explosive","10","How many points the explosive bullets upgade costs.",CVAR_FLAGS, true, -1.0);  
	explosivepackpoints = CreateConVar("points_price_explosivepack","10","How many points a pack of explosive bullets upgade costs.",CVAR_FLAGS, true, -1.0);  
	chainsawpoints = CreateConVar("points_price_chainsaw","20","How many points the chainsaw costs.",CVAR_FLAGS, true, -1.0);
	gascanpoints = CreateConVar("points_price_gascan","20","How many points the gascan costs.",CVAR_FLAGS, true, -1.0);
	laserpoints = CreateConVar("points_price_laser","5","How many points a laser sight costs.",CVAR_FLAGS, true, -1.0);

	/*Disable Weapon Categories*/
	healthcat = CreateConVar("cat_health","1","The Health category of items. -1 to disable 1 to enable",CVAR_FLAGS, true, -1.0);
	meleecat = CreateConVar("cat_melee","1","The Melee category of items. -1 to disable 1 to enable",CVAR_FLAGS, true, -1.0);
	weaponscat = CreateConVar("cat_weapons","1","The Weapons category of items. -1 to disable 1 to enable",CVAR_FLAGS, true, -1.0);
	smgcat = CreateConVar("cat_smg","1","The SMGs category of items. -1 to disable 1 to enable",CVAR_FLAGS, true, -1.0);
	riflecat = CreateConVar("cat_rifle","1","The Rifles category of items. -1 to disable 1 to enable",CVAR_FLAGS, true, -1.0);
	snipercat = CreateConVar("cat_sniper","1","The Sniper Rifles category of items. -1 to disable 1 to enable",CVAR_FLAGS, true, -1.0);
	shotguncat = CreateConVar("cat_shotgun","1","The Shotguns category of items. -1 to disable 1 to enable",CVAR_FLAGS, true, -1.0);
	pistolcat = CreateConVar("cat_pistol","1","The Pistols category of items. -1 to disable 1 to enable",CVAR_FLAGS, true, -1.0);
	explosivescat = CreateConVar("cat_explosives","1","The Explosives category of items. -1 to disable 1 to enable",CVAR_FLAGS, true, -1.0);
	ammocat = CreateConVar("cat_ammo","1","The Ammo category of items. -1 to disable 1 to enable",CVAR_FLAGS, true, -1.0);
	
	/*Infected Price Convars*/
	suicidepoints = CreateConVar("points_price_infected_suicide","4","How many points it takes to end it all.",CVAR_FLAGS, true, -1.0);
	ihealpoints = CreateConVar("points_price_infected_heal","5","How many points a heal costs (for infected).",CVAR_FLAGS, true, -1.0);
	boomerpoints = CreateConVar("points_price_infected_boomer","10","How many points a boomer costs.",CVAR_FLAGS, true, -1.0);
	hunterpoints = CreateConVar("points_price_infected_hunter","5","How many points a hunter costs.",CVAR_FLAGS, true, -1.0);
	smokerpoints = CreateConVar("points_price_infected_smoker","7","How many points a smoker costs.",CVAR_FLAGS, true, -1.0);
	spitterpoints = CreateConVar("points_price_infected_spitter","7","How many points a spitter costs.",CVAR_FLAGS, true, -1.0);
	chargerpoints = CreateConVar("points_price_infected_charger","7","How many points a charger costs.",CVAR_FLAGS, true, -1.0);
	jockeypoints = CreateConVar("points_price_infected_jockey","7","How many points a jockey costs.",CVAR_FLAGS, true, -1.0);
	tankpoints = CreateConVar("points_price_infected_tank","35","How many points a tank costs.",CVAR_FLAGS, true, -1.0);
	wwitchpoints = CreateConVar("points_price_infected_witch","25","How many points a witch costs.",CVAR_FLAGS, true, -1.0);
	mobpoints = CreateConVar("points_price_infected_mob","18","How many points a mini-event/mob costs.",CVAR_FLAGS, true, -1.0);
	panicpoints = CreateConVar("points_price_infected_mob_mega","23","How many points a mega mob costs.",CVAR_FLAGS, true, -1.0);
	
	/*Special Price Convars*/
	burnpoints = CreateConVar("points_price_special_burn","10","How many points does incendiary ammo cost?",CVAR_FLAGS,true,-1.0);
	burnpackpoints = CreateConVar("points_price_special_burn_super","20","How many points does a pack of incendiary ammo cost?",CVAR_FLAGS,true,-1.0);	

	/*Item-Related Convars*/
	tanklimit = CreateConVar("points_limit_tanks","1","How many tanks can be spawned in a round.",CVAR_FLAGS,true,0.0);
	witchlimit = CreateConVar("points_limit_witches","2","How many witches can be spawned in a round.",CVAR_FLAGS,true,0.0);
	
	/*Bug Prevention*/
	pointsremindtimer = 1;
	pointsremindnumtimer = 1;

//3: Event Hooks
	/*Event Hooks*/
	HookEvent("player_death", InfectedKill);
	HookEvent("round_end", RoundEnd, EventHookMode_Pre);
	//HookEvent("round_start", RoundStart, EventHookMode_PostNoCopy);
	//HookEvent("rescue_door_open", RescuePoints);
	HookEvent("heal_success", HealPoints);
	//HookEvent("entity_shoved", MeleeShove);
	HookEvent("revive_success", RevivePoints);
	HookEvent("infected_death", KillPoints);
	HookEvent("player_team", ResetPoints);
	HookEvent("witch_killed", WitchPoints);
	HookEvent("zombie_ignited", TankBurnPoints);
	HookEvent("tank_killed", TankKill);
	HookEvent("player_hurt",HurtPoints);
	HookEvent("player_incapacitated",IncapacitatePoints);
	HookEvent("tongue_grab",GrabPoints);
	HookEvent("lunge_pounce",PouncePoints);
	HookEvent("player_now_it",VomitPoints);
	//HookEvent("tank_spawn",TankCheck);
	//CreateTimer(80.0, PointsReminder, _, TIMER_REPEAT);
	//CreateTimer(60.0,PointsNumReminder, _,TIMER_REPEAT);
	CreateTimer(1.0,TimerUpdate, _, TIMER_REPEAT);

	/* Config Creation*/
	AutoExecConfig(true,"L4DPoints");
}
//4: Points Reminder System
public Action:TimerUpdate(Handle:timer)
{
	new advertising;
	new Handle:gamemodevar = FindConVar("mp_gamemode");
	new String:gamemode[25];
	GetConVarString(gamemodevar,gamemode,sizeof(gamemode));
	if (StrEqual(gamemode,"survival",true))
	{
		if (GetConVarInt(pointsonsurvival) < 1)
		{
			pointson = GetConVarBool(pointsonsurvival);
		}
		else
		{
			pointson = GetConVarBool(pointsoncvar);
		}
	}
	else if (StrEqual(gamemode,"coop",true))
	{
		if (GetConVarInt(pointsoncoop) < 1)
		{
			pointson = GetConVarBool(pointsoncoop);
		}
		else
		{
			pointson = GetConVarBool(pointsoncvar);
		}
	}
	else if (StrEqual(gamemode,"scavenge",true))
	{
		if (GetConVarInt(pointsonscavenger) < 1)
		{
			pointson = GetConVarBool(pointsonscavenger);
		}
		else
		{
			pointson = GetConVarBool(pointsoncvar);
		}
	}
	else if (StrEqual(gamemode,"realism",true))
	{
		if (GetConVarInt(pointsonrealism) < 1)
		{
			pointson = GetConVarBool(pointsonrealism);
		}
		else
		{
			pointson = GetConVarBool(pointsoncvar);
		}
	}
	else if (StrEqual(gamemode,"versus",true))
	{
		if (GetConVarInt(pointsonversus) < 1)
		{
			pointson = GetConVarBool(pointsonversus);
		}
		else
		{
			pointson = GetConVarBool(pointsoncvar);
		}
	}
	else if (StrEqual(gamemode,"teamversus",true))
	{
		if (GetConVarInt(pointsontversus) < 1)
		{
			pointson = GetConVarBool(pointsontversus);
		}
		else
		{
			pointson = GetConVarBool(pointsoncvar);
		}
	}
	
	else if (StrEqual(gamemode,"teamscavenge",true))
	{
		if (GetConVarInt(pointsontscavenge) < 1)
		{
			pointson = GetConVarBool(pointsontscavenge);
		}
		else
		{
			pointson = GetConVarBool(pointsoncvar);
		}
	}
	else
	{
		pointson = GetConVarBool(pointsoncvar);
	}
	pointstimer += 1;
	if(pointson)
	{
		if (pointstimer >= GetConVarInt(pointsadvertisingticks) * pointsremindtimer)
		{
			advertising = GetConVarInt(pointsadvertising);
			pointsremindtimer += 1;
			if(advertising == 2)
			{
				PrintToChatAll("\x05[SM]\x01 You can get item points in this server to buy items. Type \x03!points\x01 to see how many you have. Type \x03!usepoints\x01 to spend them.");
			}
			else if(advertising == 1)
			{
				PrintToChatAll("\x05[SM]\x01 Type \x03!usepoints\x01 to spend your item points.");
			}
		}
		if (pointstimer >= GetConVarInt(pointsremindticks) * pointsremindnumtimer)
		{
			advertising = GetConVarInt(pointsnumreminder);
			pointsremindnumtimer += 1;
			if(advertising >= 1)
			{
				PrintToChatAll("\x05[SM]\x01 If you are having trouble pressing numbers 6, 7, 8, 9, and 0 in the points menu, try enabling and disabling gamepad.");
			}
		}
	}
}
public Action:PointsHelp(client,args)
{
	if(pointson)
	{
		PrintToChat(client, "\x05[SM]\x01 Item points can be earned by performing acts of teamwork. Type \x03!usepoints\x01 to spend them, and \x03!points\x01 to find out how many you have.");
	}
}
public Action:ShowPoints(client,args)
{
	if(pointson)
	{
		ShowPointsFunc(client);
	}
	return Plugin_Handled;
}
public Action:TeamID(client,args)
{
	if(pointson)
	{
		TeamIDFunc(client);
	}
	return Plugin_Handled;
}
public Action:TeamIDFunc(client)
{
	PrintToChat(client, "\x05[SM]\x01 You are on team \x03%d\x01.",pointsteam[client]);
	
	return Plugin_Handled;
}
public Action:ShowPointsFunc(client)
{
	PrintToChat(client, "\x05[SM]\x01 You currently have \x03%d\x01 item points.",points[client]);
	
	return Plugin_Handled;
}
public Action:InfectedKill(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (attacker > 0 && attacker < PLAYERS + 1)
	{
		if (client > 0 && client < PLAYERS + 1)
		{
			if (pointsteam[attacker] == SURVIVORTEAM)
			{
				if (pointsteam[client] != SURVIVORTEAM)
				{
					if(pointson)
					{
						PrintToChat(attacker, "\x05[SM]\x01 Killed Special Infected: \x03%d\x01 Point(s)",GetConVarInt(pointsspecial));
						points[attacker] += GetConVarInt(pointsspecial);
					}
				}
			}
		}
	}
}
public Action:RoundEnd(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new Handle:gamemodevar = FindConVar("mp_gamemode");
	new String:gamemode[25];
	GetConVarString(gamemodevar,gamemode,sizeof(gamemode));
	numtanks = 0;
	numwitches = 0;
	numrounds += 1;
	if (GetConVarBool(pointsresetround))
	{
		if (StrEqual(gamemode,"versus",false))
		{
			if (numrounds >= GetConVarInt(pointsresetrounds))
			{
				for (new i; i <= PLAYERS + 1; i++)
				{
					points[i] = 0;
				}
				numrounds = 0;
			}
		}
		else
		{
			for (new i; i < PLAYERS + 1; i++)
			{
				points[i] = 0;
			}
			numrounds = 0;
		}
	}
}
//5: Receiving Points
public Action:IncapacitatePoints(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (attacker > 0 && attacker < PLAYERS + 1)
	{
		if (pointsteam[attacker] == INFECTEDTEAM)
		{
			if (client > 0 && client < PLAYERS + 1)
			{
				if(pointson)
				{
					PrintToChat(attacker, "\x05[SM]\x01 Incapacitated Survivor: \x03%d\x01 Point(s)",GetConVarInt(pointsincapacitate));
					points[attacker] += GetConVarInt(pointsincapacitate);
				}
			}
		}
	}
}
public Action:GrabPoints(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client > 0 && client < PLAYERS + 1)
	{
		if (pointsteam[client] != SURVIVORTEAM)
		{
			if(pointson)
			{
				PrintToChat(client, "\x05[SM]\x01 Pulled Survivor: \x03%d\x01 Point(s)",GetConVarInt(pointsgrab));
				points[client] += GetConVarInt(pointsgrab);
			}
		}
	}
}
public Action:PouncePoints(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client > 0 && client < PLAYERS + 1)
	{
		if (pointsteam[client] != SURVIVORTEAM)
		{
			if(pointson)
			{
				PrintToChat(client, "\x05[SM]\x01 Pounced Survivor: \x03%d\x01 Point(s)",GetConVarInt(pointspounce));
				points[client] += GetConVarInt(pointspounce);
			}
		}
	}
}
public Action:VomitPoints(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (client > 0 && client < PLAYERS + 1)
	{
		if (pointsteam[client] != SURVIVORTEAM)
		{
			if(pointson)
			{
				PrintToChat(client, "\x05[SM]\x01 'Tagged' Survivor: \x03%d\x01 Point(s)",GetConVarInt(pointsvomit));
				points[client] += GetConVarInt(pointsvomit);
			}
		}
	}
}
public Action:HurtPoints(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (attacker > 0 && attacker < PLAYERS + 1)
	{
		if (client > 0 && client < PLAYERS + 1)
		{
			if (pointsteam[attacker] != SURVIVORTEAM)
			{
				if (pointsteam[client] == SURVIVORTEAM)
				{
					if(pointson)
					{
                				pointshurtcount[attacker] += 1;
               					if (GetEntProp(attacker, Prop_Send, "m_zombieClass") == 4)  //is it a spitter?
                				{
                    					if(pointshurtcount[attacker] >= 8)
                    					{
                        					PrintToChat(attacker, "\x05[SM]\x01 Spitter Bath Damage! + \x05%d\x01 Point(s)",GetConVarInt(pointshurt));
                       	 					points[attacker] += GetConVarInt(pointshurt);
                        					pointshurtcount[attacker] -= 8;
                    					}
                				}    
                				else  // Any SI but Spitter
                				{
                    					if(pointshurtcount[attacker] >= 3)
                    					{
                        					PrintToChat(attacker, "\x05[SM]\x01 Multiple damage! + %d\x01 Point(s)",GetConVarInt(pointshurt));
                        					points[attacker] += GetConVarInt(pointshurt);
                        					pointshurtcount[attacker] -= 3;
                    					}
                				}
					}
				}
			}
		}
	}
}
public Action:TankKill(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (attacker > 0 && attacker < PLAYERS + 1)
	{
		if(pointson)
		{
			PrintToChat(attacker, "\x05[SM]\x01 Tank Killed: \x03%d\x01 Point(s)",GetConVarInt(pointstankkill));
			points[attacker] += GetConVarInt(pointstankkill);
			for (new i = 0;i <= PLAYERS + 7;i++)
			{
				tankonfire[i] = 0;
			}
		}
	}
}
public Action:WitchPoints(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new instakill = GetEventBool(event, "oneshot");
	if (client > 0 && client < PLAYERS + 1)
	{
		if(pointsteam[client] == SURVIVORTEAM)
		{
			if(pointson)
			{
				PrintToChat(client, "\x01[SM]\x01 Witch Killed: \x03%d\x01 Point(s)",GetConVarInt(pointswitch));
				points[client] += GetConVarInt(pointswitch);
				if (instakill)
				{
					PrintToChat(client, "\x05[SM]\x01 Witch Crown: \x03%d\x01 Point(s)",GetConVarInt(pointswitchinsta));
					points[client] += GetConVarInt(pointswitchinsta);
				}
			}
		}
	}
}
public Action:TankBurnPoints(Handle:event, String:event_name[], bool:dontBroadcast)
{
	decl String:victim[64];
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	GetEventString(event, "victimname", victim, sizeof(victim));
	//new target = GetEventInt(event,"clientid");
	if (client > 0 && client < PLAYERS + 1)
	{
		if (StrEqual(victim,"Tank",false))
		{
			if(tankonfire[client] != 1)
			{
				if(pointson)
				{
					PrintToChat(client, "\x05[SM]\x01 Tank burned: \x03%d\x01 Point(s)",GetConVarInt(pointstankburn));
					points[client] += GetConVarInt(pointstankburn);
					tankonfire[client] = 1;
				}
			}
		}
	}
}
public Action:ResetPoints(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new disconnect = GetEventBool(event, "disconnect");
	new teamid = GetEventInt(event,"team");
	
	if (client > 0 && client < PLAYERS + 1)
	{
		if (disconnect)
		{
			points[client] = 0;
		}
		pointsteam[client] = teamid;
	}
}
public Action:HealPoints(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new target = GetClientOfUserId(GetEventInt(event, "subject"));
	if (client > 0 && client < PLAYERS + 1)
	{
		if (client != target)
		{
			if(pointson)
			{
				if(pointson)
				{
					points[client] += GetConVarInt(pointsheal);
					PrintToChat(client, "\x05[SM]\x01 Healed Teammate: \x03%d\x01 Point(s).", GetConVarInt(pointsheal));
				}
			}
		}
	}
}
public Action:KillPoints(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "attacker"));
	new headshot = GetEventBool(event, "headshot");
	new minigun = GetEventBool(event, "minigun");
	if (client > 0 && client < PLAYERS + 1)
	{
		pointskillcount[client] += 1;
		if (headshot)
		{
			pointskillcount[client] += GetConVarInt(pointsheadshot);
		}
		if (minigun)
		{
			pointskillcount[client] += GetConVarInt(pointsminigun);
		}
		if (pointskillcount[client] >= GetConVarInt(pointsinfectednum))
		{
			if(pointson)
			{
				points[client] += GetConVarInt(pointsinfected);
				PrintToChat(client, "\x05[SM]\x01 Infected Killing Spree: \x03%d\x01 Point(s)",GetConVarInt(pointsinfected));
			}
			pointskillcount[client] -= GetConVarInt(pointsinfectednum);
		}
	}
}
public Action:RevivePoints(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new target = GetClientOfUserId(GetEventInt(event, "subject"));
	if (client > 0 && client < PLAYERS + 1)
	{
		if (client != target)
		{
			if(pointson)
			{
				points[client] += GetConVarInt(pointsrevive);
				PrintToChat(client, "\x05[SM]\x01 Revived Teammate: \x03%d\x01 Point(s)",GetConVarInt(pointsrevive));
			}
		}
	}
}
//6: Admin Functions
public Action:Command_GivePoints(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "\x05[SM]\x01 Usage: sm_clientgivepoints <#userid|name> [number of points]");
		return Plugin_Handled;
	}

	decl String:arg[MAX_NAME_LENGTH], String:arg2[8];
	GetCmdArg(1, arg, sizeof(arg));

	if (args > 1)
	{
		GetCmdArg(2, arg2, sizeof(arg2));
	}
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	
	new targetclient;
	
	if ((target_count = ProcessTargetString(
			arg,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) > 0)
	{
		for (new i = 0; i < target_count; i++)
		{
			targetclient = target_list[i];
			points[targetclient] += StringToInt(arg2);
		}
	}
	else
	{
		ReplyToTargetError(client, target_count);
	}
	return Plugin_Handled;
}
public Action:Command_SetPoints(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "\x05[SM]\x01 Usage: sm_clientsetpoints <#userid|name> [number of points]");
		return Plugin_Handled;
	}

	decl String:arg[MAX_NAME_LENGTH], String:arg2[8];
	GetCmdArg(1, arg, sizeof(arg));

	if (args > 1)
	{
		GetCmdArg(2, arg2, sizeof(arg2));
	}
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	
	new targetclient;
	
	if ((target_count = ProcessTargetString(
			arg,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) > 0)
	{
		for (new i = 0; i < target_count; i++)
		{
			targetclient = target_list[i];
			points[targetclient] = StringToInt(arg2);
		}
	}
	else
	{
		ReplyToTargetError(client, target_count);
	}
	return Plugin_Handled;
}


public Action:Laser(client,args)
{
	LaserFunc(client);
	
	return Plugin_Handled;
}

public Action:LaserFunc(clientId)
{
	new flags4 = GetCommandFlags("upgrade_add");
	SetCommandFlags("upgrade_add", flags4 & ~FCVAR_CHEAT);
	
	//Give player the laser sight
	FakeClientCommand(clientId, "upgrade_add LASER_SIGHT");
	
	SetCommandFlags("upgrade_add", flags4|FCVAR_CHEAT);
	
	return Plugin_Handled;
}

public Action:FAmmo(client,args)
{
	FAmmoFunc(client);
	
	return Plugin_Handled;
}

public Action:FAmmoFunc(clientId)
{
	new flags5 = GetCommandFlags("upgrade_add");
	SetCommandFlags("upgrade_add", flags5 & ~FCVAR_CHEAT);
	
	//Give player incendiary ammo
	FakeClientCommand(clientId, "upgrade_add INCENDIARY_AMMO");
	
	SetCommandFlags("upgrade_add", flags5|FCVAR_CHEAT);
	
	return Plugin_Handled;
}

public Action:EAmmo(client,args)
{
	EAmmoFunc(client);
	
	return Plugin_Handled;
}

public Action:EAmmoFunc(clientId)
{
	new flags6 = GetCommandFlags("upgrade_add");
	SetCommandFlags("upgrade_add", flags6 & ~FCVAR_CHEAT);
	
	//Give player explosive ammo
	FakeClientCommand(clientId, "upgrade_add EXPLOSIVE_AMMO");
	
	SetCommandFlags("upgrade_add", flags6|FCVAR_CHEAT);
	
	return Plugin_Handled;
}

public Action:Refill(client,args)
{
	RefillFunc(client);
	
	return Plugin_Handled;
}

public Action:RefillFunc(clientId)
{
	new flags3 = GetCommandFlags("give");
	SetCommandFlags("give", flags3 & ~FCVAR_CHEAT);
	
	//Give player ammo
	FakeClientCommand(clientId, "give ammo");
	
	SetCommandFlags("give", flags3|FCVAR_CHEAT);
	
	return Plugin_Handled;
}

public Action:Heal(client,args)
{
	HealFunc(client);
	
	return Plugin_Handled;
}

public Action:HealFunc(clientId)
{
	new flags2 = GetCommandFlags("give");
	SetCommandFlags("give", flags2 & ~FCVAR_CHEAT);
	
	//Give player health
	FakeClientCommand(clientId, "give health");
	
	SetCommandFlags("give", flags2|FCVAR_CHEAT);
	
	return Plugin_Handled;
}

public Action:FakeGod(client,args)
{
	FakeGodFunc(client);
	
	return Plugin_Handled;
}

public Action:FakeGodFunc(client)
{
	if (godon[client] <= 0)
	{
		godon[client] = 1;
		SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
	}
	else
	{
		godon[client] = 0;
		SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);  
	}
	
	return Plugin_Handled;
}

//7: Points Menu

public Action:PointsMenu(client,args)
{
	if(pointson)
	{
		if(pointsteam[client] != SURVIVORTEAM)
		{
			InfectedPointsMenuFunc(client);
		}
		else
		{
			PointsMenuFunc(client);
		}
	}
    
	return Plugin_Handled;
}

public Action:PointsSpecialMenu(client,args)
{
	if(pointson)
	{
		if(pointsteam[client] != SURVIVORTEAM)
		{
			PrintToChat(client,"Sorry! Not available for non-survivors yet!");
		}
		else
		{
			PointsSpecialMenuFunc(client);
		}
	}
    
	return Plugin_Handled;
}

public Action:PointsMenu1Health(client,args)
{
	if(pointson)
	{
			PointsMenuHealth(client);
	}
    
	return Plugin_Handled;
}

public Action:PointsMenu1Melee(client,args)
{
	if(pointson)
	{
			PointsMenuMelee(client);
	}
    
	return Plugin_Handled;
}

public Action:PointsMenu1Weapons(client,args)
{
	if(pointson)
	{
			PointsMenuWeapons(client);
	}
    
	return Plugin_Handled;
}

public Action:PointsMenu1Smgs(client,args)
{
	if(pointson)
	{
			PointsMenuSmgs(client);
	}

	return Plugin_Handled;
}

public Action:PointsMenu1Rifles(client,args)
{
	if(pointson)
	{
			PointsMenuRifles(client);
	}

	return Plugin_Handled;
}

public Action:PointsMenu1Snipers(client,args)
{
	if(pointson)
	{
			PointsMenuSnipers(client);
	}

	return Plugin_Handled;
}

public Action:PointsMenu1Shotguns(client,args)
{
	if(pointson)
	{
			PointsMenuShotguns(client);
	}

	return Plugin_Handled;
}

public Action:PointsMenu1Pistols(client,args)
{
	if(pointson)
	{
			PointsMenuPistols(client);
	}

	return Plugin_Handled;
}

public Action:PointsMenu1Explosives(client,args)
{
	if(pointson)
	{
			PointsMenuExplosive(client);
	}

	return Plugin_Handled;
}

public Action:PointsConfirm(client,args)
{
	if(pointson)
	{
		PointsConfirmFunc(client);
	}
    
	return Plugin_Handled;
}

public Action:PointsMenuFunc(clientId) {
	if (clientId > 0 && clientId < PLAYERS + 1)
	{
		new Handle:menu = CreateMenu(PointsMenuHandler);
		SetMenuTitle(menu, "Points: %d", points[clientId]);
		if ( GetConVarInt(healthcat) > -1 )
		{
		AddMenuItem(menu, "option1", "Health Menu");
		}
		if ( GetConVarInt(meleecat) > -1 )
		{
		AddMenuItem(menu, "option2", "Melee Menu");
		}
		if ( GetConVarInt(weaponscat) > -1 )
		{
		AddMenuItem(menu, "option3", "Weapons Menu");
		}
		if ( GetConVarInt(explosivescat) > -1 )
		{
		AddMenuItem(menu, "option4", "Explosives Menu");
		}
		if ( GetConVarInt(ammocat) > -1 )
		{
		AddMenuItem(menu, "option5", "Ammo Menu");
		}
		SetMenuExitButton(menu, true);
		DisplayMenu(menu, clientId, MENU_TIME_FOREVER);

	}

	return Plugin_Handled;
}

public Action:PointsSpecialMenuFunc(clientId) {
	new Handle:menu = CreateMenu(PointsSpecialMenuHandler);
	SetMenuTitle(menu, "Points: %d", points[clientId]);
	if ( GetConVarInt(burnpoints) > -1 )
	{
	AddMenuItem(menu, "option1", "Incendiary Ammo");
	}
	if ( GetConVarInt(burnpackpoints) > -1 )
	{
	AddMenuItem(menu, "option2", "Incendiary Ammo Pack");
	}
	if ( GetConVarInt(explosivepackpoints) > -1 )
	{
	AddMenuItem(menu, "option3", "Explosive Ammo Pack");
	}
	if ( GetConVarInt(explosivepoints) > -1 )
	{
	AddMenuItem(menu, "option4", "Explosive Ammo");
	}
	if ( GetConVarInt(refillpoints) > -1 )
	{
	AddMenuItem(menu, "option5", "Refill");
	}
	if ( GetConVarInt(laserpoints) > -1 )
	{
	AddMenuItem(menu, "option6", "Laser Sight");
	}
	AddMenuItem(menu, "option7", "Back");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, clientId, MENU_TIME_FOREVER);

	return Plugin_Handled;
}

public Action:PointsMenuHealth(clientId) {
	new Handle:menu = CreateMenu(PointsMenuHandlerHealth);
	SetMenuTitle(menu, "Points: %d", points[clientId]);
	if ( GetConVarInt(adrenalinepoints) > -1 )
	{
	AddMenuItem(menu, "option1", "Adrenaline");
	}
	if ( GetConVarInt(medpoints) > -1 )
	{
	AddMenuItem(menu, "option2", "Medkit");
	}
	if ( GetConVarInt(pillspoints) > -1 )
	{
	AddMenuItem(menu, "option3", "Pain Pills");
	}
	if ( GetConVarInt(defibpoints) > -1 )
	{
	AddMenuItem(menu, "option4", "Defib");
	}
	if ( GetConVarInt(healpoints) > -1 )
	{
	AddMenuItem(menu, "option5", "Full Health");
	}
	AddMenuItem(menu, "option6", "Back");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, clientId, MENU_TIME_FOREVER);
    
	return Plugin_Handled;
}

public Action:PointsMenuMelee(clientId) {
	new Handle:menu = CreateMenu(PointsMenuHandlerMelee);
	SetMenuTitle(menu, "Points: %d", points[clientId]);
	if ( GetConVarInt(baseballbatpoints) > -1 )
	{
	AddMenuItem(menu, "option1", "Baseball Bat");
	}
	if ( GetConVarInt(riotshieldpoints) > -1 )
	{
	AddMenuItem(menu, "option2", "Riot Shield");
	}
	if ( GetConVarInt(guitarpoints) > -1 )
	{
	AddMenuItem(menu, "option3", "Electric Guitar");
	}
	if ( GetConVarInt(fryingpanpoints) > -1 )
	{
	AddMenuItem(menu, "option4", "Frying Pan");
	}
	if ( GetConVarInt(machetepoints) > -1 )
	{
	AddMenuItem(menu, "option5", "Machete");
	}
	if ( GetConVarInt(tonfapoints) > -1 )
	{
	AddMenuItem(menu, "option6", "Tonfa");
	}
	if ( GetConVarInt(fireaxepoints) > -1 )
	{
	AddMenuItem(menu, "option7", "Fireaxe");
	}
	if ( GetConVarInt(crowbarpoints) > -1 )
	{
	AddMenuItem(menu, "option8", "Crowbar");
	}
	if ( GetConVarInt(cricketbatpoints) > -1 )
	{
	AddMenuItem(menu, "option9", "Cricket Bat");
	}
	if ( GetConVarInt(katanapoints) > -1 )
	{
	AddMenuItem(menu, "option10", "Katana");
	}
	if ( GetConVarInt(knifepoints) > -1 )
	{
	AddMenuItem(menu, "option11", "Knife");
	}
	AddMenuItem(menu, "option12", "Back");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, clientId, MENU_TIME_FOREVER);
    
	return Plugin_Handled;
}

public Action:PointsMenuWeapons(clientId) {
	new Handle:menu = CreateMenu(PointsMenuHandlerWeapons);
	SetMenuTitle(menu, "Points: %d", points[clientId]);
	if ( GetConVarInt(smgcat) > -1 )
	{
	AddMenuItem(menu, "option1", "SMGs");
	}
	if ( GetConVarInt(riflecat) > -1 )
	{
	AddMenuItem(menu, "option2", "Rifles");
	}
	if ( GetConVarInt(snipercat) > -1 )
	{
	AddMenuItem(menu, "option3", "Sniper Rifles");
	}
	if ( GetConVarInt(shotguncat) > -1 )
	{
	AddMenuItem(menu, "option4", "Shotguns");
	}
	if ( GetConVarInt(pistolcat) > -1 )
	{
	AddMenuItem(menu, "option5", "Pistols ETC");
	}
	AddMenuItem(menu, "option6", "Back");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, clientId, MENU_TIME_FOREVER);
    
	return Plugin_Handled;
}

public Action:PointsMenuSmgs(clientId) {
	new Handle:menu = CreateMenu(PointsMenuHandlerSmgs);
	SetMenuTitle(menu, "Points: %d", points[clientId]);
	if ( GetConVarInt(smgpoints) > -1 )
	{
	AddMenuItem(menu, "option1", "SMG");
	}
	if ( GetConVarInt(silencedsmgpoints) > -1 )
	{
	AddMenuItem(menu, "option2", "Silenced SMG");
	}
	if ( GetConVarInt(mp5points) > -1 )
	{
	AddMenuItem(menu, "option3", "MP5 SMG");
	}
	AddMenuItem(menu, "option4", "Back");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, clientId, MENU_TIME_FOREVER);
    
	return Plugin_Handled;
}

public Action:PointsMenuRifles(clientId) {
	new Handle:menu = CreateMenu(PointsMenuHandlerRifles);
	SetMenuTitle(menu, "Points: %d", points[clientId]);
	if ( GetConVarInt(riflepoints) > -1 )
	{
	AddMenuItem(menu, "option1", "M4 Assualt Rifle");
	}
	if ( GetConVarInt(desertpoints) > -1 )
	{
	AddMenuItem(menu, "option2", "Desert Rifle");
	}
	if ( GetConVarInt(ak47points) > -1 )
	{
	AddMenuItem(menu, "option3", "AK47");
	}
	if ( GetConVarInt(sg552points) > -1 )
	{
	AddMenuItem(menu, "option4", "SG552");
	}
	AddMenuItem(menu, "option5", "Back");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, clientId, MENU_TIME_FOREVER);
    
	return Plugin_Handled;
}

public Action:PointsMenuSnipers(clientId) {
	new Handle:menu = CreateMenu(PointsMenuHandlerSnipers);
	SetMenuTitle(menu, "Points: %d", points[clientId]);
	if ( GetConVarInt(huntingpoints) > -1 )
	{
	AddMenuItem(menu, "option1", "Hunting Rifle");
	}
	if ( GetConVarInt(awppoints) > -1 )
	{
	AddMenuItem(menu, "option2", "AWP Sniper");
	}
	if ( GetConVarInt(militarypoints) > -1 )
	{
	AddMenuItem(menu, "option3", "Military Sniper");
	}
	if ( GetConVarInt(scoutpoints) > -1 )
	{
	AddMenuItem(menu, "option4", "Scout Sniper");
	}
	AddMenuItem(menu, "option5", "Back");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, clientId, MENU_TIME_FOREVER);
    
	return Plugin_Handled;
}

public Action:PointsMenuShotguns(clientId) {
	new Handle:menu = CreateMenu(PointsMenuHandlerShotguns);
	SetMenuTitle(menu, "Points: %d", points[clientId]);
	if ( GetConVarInt(shotpoints) > -1 )
	{
	AddMenuItem(menu, "option1", "Pump Shotgun");
	}
	if ( GetConVarInt(chromeshotpoints) > -1 )
	{
	AddMenuItem(menu, "option2", "Chrome Shotgun");
	}
	if ( GetConVarInt(autopoints) > -1 )
	{
	AddMenuItem(menu, "option3", "Auto Shotgun");
	}
	if ( GetConVarInt(spasshotpoints) > -1 )
	{
	AddMenuItem(menu, "option4", "Spas Shotgun");
	}
	AddMenuItem(menu, "option5", "Back");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, clientId, MENU_TIME_FOREVER);
    
	return Plugin_Handled;
}

public Action:PointsMenuPistols(clientId) {
	new Handle:menu = CreateMenu(PointsMenuHandlerPistols);
	SetMenuTitle(menu, "Points: %d", points[clientId]);
	if ( GetConVarInt(pistolpoints) > -1 )
	{
	AddMenuItem(menu, "option1", "Pistol");
	}
	if ( GetConVarInt(magnumpoints) > -1 )
	{
	AddMenuItem(menu, "option2", "Magnum");
	}
	if ( GetConVarInt(grenadepoints) > -1 )
	{
	AddMenuItem(menu, "option3", "Grenade Launcher");
	}
	if ( GetConVarInt(chainsawpoints) > -1 )
	{
	AddMenuItem(menu, "option4", "Chainsaw");
	}
	AddMenuItem(menu, "option5", "Back");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, clientId, MENU_TIME_FOREVER);
    
	return Plugin_Handled;
}

public Action:PointsMenuExplosive(clientId) {
	new Handle:menu = CreateMenu(PointsMenuHandlerExplosive);
	SetMenuTitle(menu, "Points: %d", points[clientId]);
	if ( GetConVarInt(pipepoints) > -1 )
	{
	AddMenuItem(menu, "option1", "Pipebomb");
	}
	if ( GetConVarInt(molopoints) > -1 )
	{
	AddMenuItem(menu, "option2", "Molotov");
	}
	if ( GetConVarInt(vomitjarpoints) > -1 )
	{
	AddMenuItem(menu, "option3", "Vomitjar");
	}
	if ( GetConVarInt(gascanpoints) > -1 )
	{
	AddMenuItem(menu, "option4", "Gascan");
	}
	if ( GetConVarInt(propanepoints) > -1 )
	{
	AddMenuItem(menu, "option5", "Propane Tank");
	}
	if ( GetConVarInt(fireworkpoints) > -1 )
	{
	AddMenuItem(menu, "option6", "Fireworks Crate");
	}
	if ( GetConVarInt(oxygenpoints) > -1 )
	{
	AddMenuItem(menu, "option7", "Oxygen Tank");
	}
	AddMenuItem(menu, "option8", "Back");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, clientId, MENU_TIME_FOREVER);
    
	return Plugin_Handled;
}

public Action:InfectedPointsMenuFunc(clientId) {
	new Handle:menu = CreateMenu(InfectedPointsMenuHandler);
	SetMenuTitle(menu, "Points: %d", points[clientId]);
	if ( GetConVarInt(suicidepoints) > -1 )
	{
	AddMenuItem(menu, "option1", "Suicide");
	}
	if ( GetConVarInt(ihealpoints) > -1 )
	{
	AddMenuItem(menu, "option2", "Heal");
	}
	if ( GetConVarInt(boomerpoints) > -1 )
	{
	AddMenuItem(menu, "option3", "Spawn Boomer");
	}
	if ( GetConVarInt(hunterpoints) > -1 )
	{
	AddMenuItem(menu, "option4", "Spawn Hunter");
	}
	if ( GetConVarInt(smokerpoints) > -1 )
	{
	AddMenuItem(menu, "option5", "Spawn Smoker");
	}
	if ( GetConVarInt(tankpoints) > -1 )
	{
	AddMenuItem(menu, "option6", "Spawn Tank");
	}
	if ( GetConVarInt(wwitchpoints) > -1 )
	{
    	AddMenuItem(menu, "option7", "Spawn Witch");
	}
	if ( GetConVarInt(mobpoints) > -1 )
	{
    	AddMenuItem(menu, "option8", "Spawn Mob");
	}
	if ( GetConVarInt(panicpoints) > -1 )
	{
    	AddMenuItem(menu, "option9", "Spawn Mega Mob");
	}
	if ( GetConVarInt(spitterpoints) > -1 )
	{
    	AddMenuItem(menu, "option10", "Spawn Spitter");
	}
	if ( GetConVarInt(chargerpoints) > -1 )
	{
    	AddMenuItem(menu, "option11", "Spawn Charger");
	}
	if ( GetConVarInt(jockeypoints) > -1 )
	{
    	AddMenuItem(menu, "option12", "Spawn Jockey");
	}
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, clientId, MENU_TIME_FOREVER);
    
	return Plugin_Handled;
}

//8: Item Cost
public Action:PointsConfirmFunc(clientId) 
{
	new cost;
	switch (buyitem[clientId])
		{
		case 0: //shotgun
		{
			cost = GetConVarInt(shotpoints);
		}
		case 1: //smg
        	{
			cost = GetConVarInt(smgpoints);
        	}
		case 2: //rifle
        	{
            		cost = GetConVarInt(riflepoints);
        	}
		case 3: //hunting rifle
		{
			cost = GetConVarInt(huntingpoints);
		}
		case 4: //auto shotgun
		{
			cost = GetConVarInt(autopoints);
		}
		case 5: //pipe bomb
		{
			cost = GetConVarInt(pipepoints);
		}
		case 6: //molotov
		{
			cost = GetConVarInt(molopoints);
		}
		case 7: //extra pistol
		{
			cost = GetConVarInt(pistolpoints);
		}
		case 8: //pills
		{
			cost = GetConVarInt(pillspoints);
		}
		case 9: //medkit
		{
			cost = GetConVarInt(medpoints);
		}
		case 10: //refill
		{
			cost = GetConVarInt(refillpoints);
		}
		case 11: //heal
		{
			cost = GetConVarInt(healpoints);
		}
		case 12: //suicide
		{
			cost = GetConVarInt(suicidepoints);
		}
		case 13: //iheal
		{
			cost = GetConVarInt(ihealpoints);
		}
		case 14: //boomer
		{
			cost = GetConVarInt(boomerpoints);
		}
		case 15: //hunter
		{
			cost = GetConVarInt(hunterpoints);
		}
		case 16: //smoker
		{
			cost = GetConVarInt(smokerpoints);
		}
		case 17: //tank
		{
			cost = GetConVarInt(tankpoints);
		}
		case 18: //witch
		{
			cost = GetConVarInt(wwitchpoints);
		}
		case 19: //mob
		{
			cost = GetConVarInt(mobpoints);
		}
		case 20: //panic
		{
			cost = GetConVarInt(panicpoints);
		}
		case 21: //incendiary
		{
			cost = GetConVarInt(burnpoints);
		}
		case 22: //incendiary pack
		{
			cost = GetConVarInt(burnpackpoints);
		}
		case 23: //adrenaline
		{
			cost = GetConVarInt(adrenalinepoints);
		}
		case 24: //defib
		{
			cost = GetConVarInt(defibpoints);
		}
		case 25: //spas shotgun
		{
			cost = GetConVarInt(spasshotpoints);
		}
		case 26: //chrome shotgun
		{
			cost = GetConVarInt(chromeshotpoints);
		}
		case 27: //magnum
		{
			cost = GetConVarInt(magnumpoints);
		}
		case 28: //ak47
		{
			cost = GetConVarInt(ak47points);
		}
		case 29: //desert rifle
		{
			cost = GetConVarInt(desertpoints);
		}
		case 30: //sg552
		{
			cost = GetConVarInt(sg552points);
		}
		case 31: //silenced smg
		{
			cost = GetConVarInt(silencedsmgpoints);
		}
		case 32: //mp5
		{
			cost = GetConVarInt(mp5points);
		}
		case 33: //awp
		{
			cost = GetConVarInt(awppoints);
		}
		case 34: //military sniper
		{
			cost = GetConVarInt(militarypoints);
		}
		case 35: //scout sniper
		{
			cost = GetConVarInt(scoutpoints);
		}
		case 36: //grenade launcher
		{
			cost = GetConVarInt(grenadepoints);
		}
		case 37: //firework crate
		{
			cost = GetConVarInt(fireworkpoints);
		}
		case 38: //vomitjar
		{
			cost = GetConVarInt(vomitjarpoints);
		}
		case 39: //oxygen tank
		{
			cost = GetConVarInt(oxygenpoints);
		}
		case 40: //propane tank
		{
			cost = GetConVarInt(propanepoints);
		}
		case 41: //explosive pack
		{
			cost = GetConVarInt(explosivepackpoints);
		}
		case 42: //chainsaw
		{
			cost = GetConVarInt(chainsawpoints);
		}
		case 43: //gascan
		{
			cost = GetConVarInt(gascanpoints);
		}
		case 44: //spitter
		{
			cost = GetConVarInt(spitterpoints);
		}
		case 45: //charger
		{
			cost = GetConVarInt(chargerpoints);
		}
		case 46: //jockey
		{
			cost = GetConVarInt(jockeypoints);
		}
		case 47: //explosive
		{
			cost = GetConVarInt(explosivepoints);
		}
		
		case 48: //laser upgrade
		{
			cost = GetConVarInt(laserpoints);
		}
		case 49: //baseballbat
		{
			cost = GetConVarInt(baseballbatpoints);
		}
		case 50: //riotshield
		{
			cost = GetConVarInt(riotshieldpoints);
		}
		case 51: //guitar
		{
			cost = GetConVarInt(guitarpoints);
		}
		case 52: //fryingpan
		{
			cost = GetConVarInt(fryingpanpoints);
		}
		case 53: //machete
		{
			cost = GetConVarInt(machetepoints);
		}
		case 54: //tonfa
		{
			cost = GetConVarInt(tonfapoints);
		}
		case 55: //fireaxe
		{
			cost = GetConVarInt(fireaxepoints);
		}
		case 56: //crowbar
		{
			cost = GetConVarInt(crowbarpoints);
		}
		case 57: //cricketbat
		{
			cost = GetConVarInt(cricketbatpoints);
		}
		case 58: //katana
		{
			cost = GetConVarInt(katanapoints);
		}
		case 59: //knife
		{
			cost = GetConVarInt(knifepoints);
		}
	}
	new Handle:menu = CreateMenu(PointsConfirmHandler);
	SetMenuTitle(menu, "Cost: %d", cost);
	AddMenuItem(menu, "option1", "Yes");
	AddMenuItem(menu, "option2", "No");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, clientId, MENU_TIME_FOREVER);

	return Plugin_Handled;
}

//9: Repeat Buy
public Action:RepeatBuy(client, args)
{
	new giveflags = GetCommandFlags("give");
	new killflags = GetCommandFlags("kill");
	new upgradeflags = GetCommandFlags("upgrade_add");
	new spawnflags = GetCommandFlags("z_spawn");
	new panicflags = GetCommandFlags("director_force_panic_event");
	SetCommandFlags("give", giveflags & ~FCVAR_CHEAT);
	SetCommandFlags("upgrade_add", upgradeflags & ~FCVAR_CHEAT);
	SetCommandFlags("kill", killflags & ~FCVAR_CHEAT);
	SetCommandFlags("z_spawn", spawnflags & ~FCVAR_CHEAT);
	SetCommandFlags("director_force_panic_event", panicflags & ~FCVAR_CHEAT);
	switch(buyitem[client])
	{
		case 0: //shotgun
		{
			if (points[client] >= GetConVarInt(shotpoints))
			{
				//Give the player a shotgun
				FakeClientCommand(client, "give pumpshotgun");
				points[client] -= GetConVarInt(shotpoints);
			}
			else
			{
				PrintToChat(client,"\x05[SM]\x01 Not enough points!");
			}
		}
		case 1: //smg
		{
			if (points[client] >= GetConVarInt(smgpoints))
			{
				//Give the player an SMG
				FakeClientCommand(client, "give smg");
				points[client] -= GetConVarInt(smgpoints);
			}
			else
			{
				PrintToChat(client,"\x05[SM]\x01 Not enough points!");
			}
		}
		case 2: //rifle
		{
			if (points[client] >= GetConVarInt(riflepoints))
			{
				//Give the player a rifle
				FakeClientCommand(client, "give rifle");
				points[client] -= GetConVarInt(riflepoints);
			}
			else
			{
				PrintToChat(client,"\x05[SM]\x01 Not enough points!");
			}
		}
		case 3: //hunting rifle
		{
			if (points[client] >= GetConVarInt(huntingpoints))
			{
				//Give the player a hunting rifle
				FakeClientCommand(client, "give hunting_rifle");
				points[client] -= GetConVarInt(huntingpoints);
			}
			else
			{
				PrintToChat(client,"\x05[SM]\x01 Not enough points!");
			}
		}
		case 4: //auto shotgun
		{
			if (points[client] >= GetConVarInt(autopoints))
			{
				//Give the player an auto shotgun
				FakeClientCommand(client, "give autoshotgun");
				points[client] -= GetConVarInt(autopoints);
			}
			else
			{
				PrintToChat(client,"\x05[SM]\x01 Not enough points!");
			}
		}
		case 5: //pipe bomb
		{
			if (points[client] >= GetConVarInt(pipepoints))
			{
				//Give the player a pipebomb
				FakeClientCommand(client, "give pipe_bomb");
				points[client] -= GetConVarInt(pipepoints);
			}
			else
			{
				PrintToChat(client,"\x05[SM]\x01 Not enough points!");
			}
		}
		case 6: //molotov
		{
			if (points[client] >= GetConVarInt(molopoints))
			{
				//Give the player a molotov
				FakeClientCommand(client, "give molotov");
				points[client] -= GetConVarInt(molopoints);
			}
			else
			{
				PrintToChat(client,"\x05[SM]\x01 Not enough points!");
			}
		}
		case 7: //pistol
		{
			if (points[client] >= GetConVarInt(pistolpoints))
			{
				//Give the player a pistol
				FakeClientCommand(client, "give pistol");
				points[client] -= GetConVarInt(pistolpoints);
			}
			else
			{
				PrintToChat(client,"\x05[SM]\x01 Not enough points!");
			}
		}
		case 8: //pills
		{
		   if (points[client] >= GetConVarInt(pillspoints))
			{
				//Give the player pain pills
				FakeClientCommand(client, "give pain_pills");
				points[client] -= GetConVarInt(pillspoints);
			}
			else
			{
				PrintToChat(client,"\x05[SM]\x01 Not enough points!");
			}
		}
		case 9: //medkit
		{
			if (points[client] >= GetConVarInt(medpoints))
			{
				//Give the player a medkit
				FakeClientCommand(client, "give first_aid_kit");
				points[client] -= GetConVarInt(medpoints);
			}
			else
			{
				PrintToChat(client,"\x05[SM]\x01 Not enough points!");
			}
		}
		case 10: //refill
		{
			if (points[client] >= GetConVarInt(refillpoints))
			{
				//Refill ammo
				FakeClientCommand(client, "give ammo");
				points[client] -= GetConVarInt(refillpoints);
			}
			else
			{
				PrintToChat(client,"\x05[SM]\x01 Not enough points!");
			}
		}
		case 11: //heal
		{
			if (points[client] >= GetConVarInt(healpoints))
			{
				//Heal player
				FakeClientCommand(client, "give health");
				points[client] -= GetConVarInt(healpoints);
			}
			else
			{
				PrintToChat(client,"\x05[SM]\x01 Not enough points!");
			}
		}
		case 12: //suicide
		{
			if (points[client] >= GetConVarInt(suicidepoints))
			{
				//Kill yourself (for boomers)
				FakeClientCommand(client, "kill");
				points[client] -= GetConVarInt(suicidepoints);
			}
			else
			{
				PrintToChat(client,"\x05[SM]\x01 Not enough points!");
			}
		}
		case 13: //heal
		{
			if (points[client] >= GetConVarInt(ihealpoints))
			{
				//Give the player health
				FakeClientCommand(client, "give health");
				points[client] -= GetConVarInt(ihealpoints);
			}
			else
			{
				PrintToChat(client,"\x05[SM]\x01 Not enough points!");
			}
		}
		case 14: //boomer
		{
			if (points[client] >= GetConVarInt(boomerpoints))
			{
				//Make the player a boomer
				FakeClientCommand(client, "z_spawn boomer auto");
				points[client] -= GetConVarInt(boomerpoints);
			}
			else
			{
				PrintToChat(client,"\x05[SM]\x01 Not enough points!");
			}
		}
		case 15: //hunter
		{
			if (points[client] >= GetConVarInt(hunterpoints))
			{
				//Make the player a hunter
				FakeClientCommand(client, "z_spawn hunter auto");
				points[client] -= GetConVarInt(hunterpoints);
			}
			else
			{
				PrintToChat(client,"\x05[SM]\x01 Not enough points!");
			}
		}
		case 16: //smoker
		{
			if (points[client] >= GetConVarInt(smokerpoints))
			{
				//Make the player a smoker
				FakeClientCommand(client, "z_spawn smoker auto");
				points[client] -= GetConVarInt(smokerpoints);
			}
			else
			{
				PrintToChat(client,"\x05[SM]\x01 Not enough points!");
			}
		}
		case 17: //tank
		{
			if (points[client] >= GetConVarInt(tankpoints))
			{
				numtanks += 1;
				if (numtanks < GetConVarInt(tanklimit) + 1)
				{
					//Make the player a tank
					FakeClientCommand(client, "z_spawn tank auto");
					points[client] -= GetConVarInt(tankpoints);
				}
				else
				{
					PrintToChat(client,"\x05[SM]\x01 Tank limit for the round has been reached!");
				}
			}
			else
			{
				PrintToChat(client,"\x05[SM]\x01 Not enough points!");
			}
		}
		case 18: //spawn witch
		{
			if (points[client] >= GetConVarInt(wwitchpoints))
			{
				numwitches += 1;
				if (numwitches < GetConVarInt(witchlimit) + 1)
				{
					//Spawn a witch
					FakeClientCommand(client, "z_spawn witch auto");
					points[client] -= GetConVarInt(wwitchpoints);
				}
				else
				{
					PrintToChat(client,"\x05[SM]\x01 Witch limit for the round has been reached!");
				}
			}
			else
			{
				PrintToChat(client,"\x05[SM]\x01 Not enough points!");
			}
		}
		case 19: //spawn mob
		{
			if (points[client] >= GetConVarInt(mobpoints))
			{
				//Spawn a mob
				FakeClientCommand(client, "z_spawn mob");
				points[client] -= GetConVarInt(mobpoints);
			}
			else
			{
				PrintToChat(client,"\x05[SM]\x01 Not enough points!");
			}
		}
		case 20: //create panic event
		{
			if (points[client] >= GetConVarInt(panicpoints))
			{
				//Spawn a mob
				FakeClientCommand(client, "director_force_panic_event");
				points[client] -= GetConVarInt(panicpoints);
			}
			else
			{
				PrintToChat(client,"\x05[SM]\x01 Not enough points!");
			}
		}
		case 21: //incendiary
		{
			if (points[client] >= GetConVarInt(burnpoints))
			{
				//Give Incendiary Ammo
				FakeClientCommand(client, "upgrade_add INCENDIARY_AMMO");
				points[client] -= GetConVarInt(burnpoints);
			}
			else
			{
				PrintToChat(client,"\x05[SM]\x01 Not enough points!");
			}
		}
		case 22: //super incendiary
		{
			if (points[client] >= GetConVarInt(burnpackpoints))
			{
				//Give Super Incendiary
				FakeClientCommand(client, "give upgradepack_incendiary");
				points[client] -= GetConVarInt(burnpackpoints);
			}
			else
			{
				PrintToChat(client,"\x05[SM]\x01 Not enough points!");
			}
		}
		case 23: //adrenaline
		{
		   if (points[client] >= GetConVarInt(adrenalinepoints))
			{
				//Give the player an adrenaline shot
				FakeClientCommand(client, "give adrenaline");
				points[client] -= GetConVarInt(adrenalinepoints);
			}
			else
			{
				PrintToChat(client,"\x05[SM]\x01 Not enough points!");
			}
		}
		case 24: //defib
		{
		   if (points[client] >= GetConVarInt(defibpoints))
			{
				//Give the player a defib
				FakeClientCommand(client, "give defibrillator");
				points[client] -= GetConVarInt(defibpoints);
			}
			else
			{
				PrintToChat(client,"\x05[SM]\x01 Not enough points!");
			}
		}
		case 25: //spas shotty
		{
		   if (points[client] >= GetConVarInt(spasshotpoints))
			{
				//Give the player a spas shotty
				FakeClientCommand(client, "give shotgun_spas");
				points[client] -= GetConVarInt(spasshotpoints);
			}
			else
			{
				PrintToChat(client,"\x05[SM]\x01 Not enough points!");
			}
		}
		case 26: //chrome shotty
		{
		   if (points[client] >= GetConVarInt(chromeshotpoints))
			{
				//Give the player a chrome shotty
				FakeClientCommand(client, "give shotgun_chrome");
				points[client] -= GetConVarInt(chromeshotpoints);
			}
			else
			{
				PrintToChat(client,"\x05[SM]\x01 Not enough points!");
			}
		}
		case 27: //magnum
		{
		   if (points[client] >= GetConVarInt(magnumpoints))
			{
				//Give the player a magnum
				FakeClientCommand(client, "give pistol_magnum");
				points[client] -= GetConVarInt(magnumpoints);
			}
			else
			{
				PrintToChat(client,"\x05[SM]\x01 Not enough points!");
			}
		}
		case 28: //ak47
		{
		   if (points[client] >= GetConVarInt(ak47points))
			{
				//Give the player an ak47
				FakeClientCommand(client, "give rifle_ak47");
				points[client] -= GetConVarInt(ak47points);
					}
			else
			{
				PrintToChat(client,"\x05[SM]\x01 Not enough points!");
			}
		}
		case 29: //desert
		{
		   if (points[client] >= GetConVarInt(desertpoints))
			{
				//Give the player a desert rifle
				FakeClientCommand(client, "give rifle_desert");
				points[client] -= GetConVarInt(desertpoints);
			}
			else
			{
				PrintToChat(client,"\x05[SM]\x01 Not enough points!");
			}
		}
		case 30: //sg552
		{
		   if (points[client] >= GetConVarInt(sg552points))
			{
				//Give the player a sg552
				FakeClientCommand(client, "give rifle_sg552");
				points[client] -= GetConVarInt(sg552points);
			}
			else
			{
				PrintToChat(client,"\x05[SM]\x01 Not enough points!");
			}
		}
		case 31: //silenced smg
		{
		   if (points[client] >= GetConVarInt(silencedsmgpoints))
			{
				//Give the player a silenced smg
				FakeClientCommand(client, "give smg_silenced");
				points[client] -= GetConVarInt(silencedsmgpoints);
			}
			else
			{
				PrintToChat(client,"\x05[SM]\x01 Not enough points!");
			}
		}
		case 32: //mp5
		{
		   if (points[client] >= GetConVarInt(mp5points))
			{
				//Give the player a mp5
				FakeClientCommand(client, "give smg_mp5");
				points[client] -= GetConVarInt(mp5points);
			}
			else
			{
				PrintToChat(client,"\x05[SM]\x01 Not enough points!");
			}
		}
		case 33: //awp sniper
		{
		   if (points[client] >= GetConVarInt(awppoints))
			{
				//Give the player pain pills
				FakeClientCommand(client, "give sniper_awp");
				points[client] -= GetConVarInt(awppoints);
			}
			else
			{
				PrintToChat(client,"\x05[SM]\x01 Not enough points!");
			}
		}
		case 34: //military sniper
		{
		   if (points[client] >= GetConVarInt(militarypoints))
			{
				//Give the player pain a military sniper
				FakeClientCommand(client, "give sniper_military");
				points[client] -= GetConVarInt(militarypoints);
			}
			else
			{
				PrintToChat(client,"\x05[SM]\x01 Not enough points!");
			}
		}
		case 35: //scout sniper
		{
		   if (points[client] >= GetConVarInt(scoutpoints))
			{
				//Give the player a scount sniper
				FakeClientCommand(client, "give sniper_scout");
				points[client] -= GetConVarInt(scoutpoints);
			}
			else
			{
				PrintToChat(client,"\x05[SM]\x01 Not enough points!");
			}
		}
		case 36: //grenade launcher
		{
		   if (points[client] >= GetConVarInt(grenadepoints))
			{
				//Give the player a grenade launcher
				FakeClientCommand(client, "give grenade_launcher");
				points[client] -= GetConVarInt(grenadepoints);
			}
			else
			{
				PrintToChat(client,"\x05[SM]\x01 Not enough points!");
			}
		}
		case 37: //vomitjar
		{
		   if (points[client] >= GetConVarInt(vomitjarpoints))
			{
				//Give the player a vomitjar
				FakeClientCommand(client, "give vomitjar");
				points[client] -= GetConVarInt(vomitjarpoints);
			}
			else
			{
				PrintToChat(client,"\x05[SM]\x01 Not enough points!");
			}
		}
		case 38: //firework crate
		{
		   if (points[client] >= GetConVarInt(fireworkpoints))
			{
				//Give the player a firework crate
				FakeClientCommand(client, "give fireworkcrate");
				points[client] -= GetConVarInt(fireworkpoints);
			}
			else
			{
				PrintToChat(client,"\x05[SM]\x01 Not enough points!");
			}
		}
		case 39: //oxygentank
		{
		   if (points[client] >= GetConVarInt(oxygenpoints))
			{
				//Give the player an oxygentank
				FakeClientCommand(client, "give oxygentank");
				points[client] -= GetConVarInt(oxygenpoints);
			}
			else
			{
				PrintToChat(client,"\x05[SM]\x01 Not enough points!");
			}
		}
		case 40: //propane tank
		{
		   if (points[client] >= GetConVarInt(propanepoints))
			{
				//Give the player a propane tank
				FakeClientCommand(client, "give propanetank");
				points[client] -= GetConVarInt(propanepoints);
			}
			else
			{
				PrintToChat(client,"\x05[SM]\x01 Not enough points!");
			}
		}
		case 41: //explosive ammo pack
		{
		   if (points[client] >= GetConVarInt(explosivepackpoints))
			{
				//Give the player explosive ammo
				FakeClientCommand(client, "give upgradepack_explosive");
				points[client] -= GetConVarInt(explosivepackpoints);
			}
			else
			{
				PrintToChat(client,"\x05[SM]\x01 Not enough points!");
			}
		}
		case 42: //chainsaw
		{
		   if (points[client] >= GetConVarInt(chainsawpoints))
			{
				//Give the player chainsaw
				FakeClientCommand(client, "give chainsaw");
				points[client] -= GetConVarInt(chainsawpoints);
			}
			else
			{
				PrintToChat(client,"\x05[SM]\x01 Not enough points!");
			}
		} 
		case 43: //gascan
		{
		   if (points[client] >= GetConVarInt(gascanpoints))
			{
				//Give the player gascan
				FakeClientCommand(client, "give gascan");
				points[client] -= GetConVarInt(gascanpoints);
			}
			else
			{
				PrintToChat(client,"\x05[SM]\x01 Not enough points!");
			}
		}
		case 44: //spitter
			{
			if (points[client] >= GetConVarInt(spitterpoints))
			{
				//Make the player a smoker
				FakeClientCommand(client, "z_spawn spitter auto");
				points[client] -= GetConVarInt(spitterpoints);
			}
			else
			{
				PrintToChat(client,"\x05[SM]\x01 Not enough points!");
			}
		}
		case 45: //charger
		{
			if (points[client] >= GetConVarInt(chargerpoints))
			{
				//Make the player a charger
				FakeClientCommand(client, "z_spawn charger auto");
				points[client] -= GetConVarInt(chargerpoints);
			}
			else
			{
				PrintToChat(client,"\x05[SM]\x01 Not enough points!");
			}
		}
		case 46: //jockey
		{
			if (points[client] >= GetConVarInt(jockeypoints))
			{
				//Make the player a smoker
				FakeClientCommand(client, "z_spawn jockey auto");
				points[client] -= GetConVarInt(jockeypoints);
			}
			else
			{
				PrintToChat(client,"\x05[SM]\x01 Not enough points!");
			}
		}
		case 47: //explosive
		{
			if (points[client] >= GetConVarInt(explosivepoints))
			{
				//Give Incendiary Ammo
				FakeClientCommand(client, "upgrade_add EXPLOSIVE_AMMO");
				points[client] -= GetConVarInt(explosivepoints);
			}
			else
			{
				PrintToChat(client,"\x05[SM]\x01 Not enough points!");
			}
		}
		case 48: //laser
		{
			if (points[client] >= GetConVarInt(laserpoints))
			{
				//Give Incendiary Ammo
				FakeClientCommand(client, "upgrade_add LASER_SIGHT");
				points[client] -= GetConVarInt(laserpoints);
			}
			else
			{
				PrintToChat(client,"\x05[SM]\x01 Not enough points!");
			}
		}
		case 49: //baseballbat
		{
			if (points[client] >= GetConVarInt(baseballbatpoints))
			{
				//give baseball bat
				FakeClientCommand(client, "give bat");
				points[client] -= GetConVarInt(baseballbatpoints);
			}
			else
			{
				PrintToChat(client,"\x05[SM]\x01 Not enough points!");
			}
		}
		case 50: //riotshield
		{
			if (points[client] >= GetConVarInt(riotshieldpoints))
			{
				//give riot shield
				FakeClientCommand(client, "give riotshield");
				points[client] -= GetConVarInt(riotshieldpoints);
			}
			else
			{
				PrintToChat(client,"\x05[SM]\x01 Not enough points!");
			}
		}
		case 51: //guitar
		{
			if (points[client] >= GetConVarInt(guitarpoints))
			{
				//give electric guitar
				FakeClientCommand(client, "give electric_guitar");
				points[client] -= GetConVarInt(guitarpoints);
			}
			else
			{
				PrintToChat(client,"\x05[SM]\x01 Not enough points!");
			}
		}
		case 52: //fryingpan
		{
			if (points[client] >= GetConVarInt(fryingpanpoints))
			{
				//give frying pan
				FakeClientCommand(client, "give frying_pan");
				points[client] -= GetConVarInt(fryingpanpoints);
			}
			else
			{
				PrintToChat(client,"\x05[SM]\x01 Not enough points!");
			}
		}
		case 53: //machete
		{
			if (points[client] >= GetConVarInt(machetepoints))
			{
				//give machete
				FakeClientCommand(client, "give machete");
				points[client] -= GetConVarInt(machetepoints);
			}
			else
			{
				PrintToChat(client,"\x05[SM]\x01 Not enough points!");
			}
		}
		case 54: //tonfa
		{
			if (points[client] >= GetConVarInt(tonfapoints))
			{
				//give tonfa
				FakeClientCommand(client, "give tonfa");
				points[client] -= GetConVarInt(tonfapoints);
			}
			else
			{
				PrintToChat(client,"\x05[SM]\x01 Not enough points!");
			}
		}
		case 55: //fireaxe
		{
			if (points[client] >= GetConVarInt(fireaxepoints))
			{
				//give fireaxe
				FakeClientCommand(client, "give fireaxe");
				points[client] -= GetConVarInt(fireaxepoints);
			}
			else
			{
				PrintToChat(client,"\x05[SM]\x01 Not enough points!");
			}
		}
		case 56: //crowbar
		{
			if (points[client] >= GetConVarInt(crowbarpoints))
			{
				//Give Incendiary Ammo
				FakeClientCommand(client, "give crowbar");
				points[client] -= GetConVarInt(crowbarpoints);
			}
			else
			{
				PrintToChat(client,"\x05[SM]\x01 Not enough points!");
			}
		}
		case 57: //cricketbat
		{
			if (points[client] >= GetConVarInt(cricketbatpoints))
			{
				//give cricket bat
				FakeClientCommand(client, "give cricket_bat");
				points[client] -= GetConVarInt(cricketbatpoints);
			}
			else
			{
				PrintToChat(client,"\x05[SM]\x01 Not enough points!");
			}
		}
		case 58: //katana
		{
			if (points[client] >= GetConVarInt(katanapoints))
			{
				//give katana
				FakeClientCommand(client, "give katana");
				points[client] -= GetConVarInt(katanapoints);
			}
			else
			{
				PrintToChat(client,"\x05[SM]\x01 Not enough points!");
			}
		}
		case 59: //knife
		{
			if (points[client] >= GetConVarInt(knifepoints))
			{
				//give knife
				FakeClientCommand(client, "give hunting_knife");
				points[client] -= GetConVarInt(knifepoints);
			}
			else
			{
				PrintToChat(client,"\x05[SM]\x01 Not enough points!");
			}
		}	
    }
	SetCommandFlags("give", giveflags|FCVAR_CHEAT);
	SetCommandFlags("kill", killflags|FCVAR_CHEAT);
	SetCommandFlags("z_spawn", spawnflags|FCVAR_CHEAT);
	SetCommandFlags("upgrade_add", upgradeflags|FCVAR_CHEAT);
	SetCommandFlags("director_force_panic_event", panicflags|FCVAR_CHEAT);
	
	return Plugin_Handled;
}

//10: Item Buying Menu Setup
public PointsConfirmHandler(Handle:menu, MenuAction:action, client, itemNum)
{
	new flags = GetCommandFlags("give");
	new flags2 = GetCommandFlags("kill");
	new upgradeflags = GetCommandFlags("upgrade_add");
	new flags3 = GetCommandFlags("z_spawn");
	new flags4 = GetCommandFlags("director_force_panic_event");
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);
	SetCommandFlags("upgrade_add", upgradeflags & ~FCVAR_CHEAT);
	SetCommandFlags("kill", flags2 & ~FCVAR_CHEAT);
	SetCommandFlags("z_spawn", flags3 & ~FCVAR_CHEAT);
	SetCommandFlags("director_force_panic_event", flags4 & ~FCVAR_CHEAT);
    
	if ( action == MenuAction_Select ) {
        
        if(itemNum == 0)
		{
			switch(buyitem[client])
			{
				case 0: //shotgun
				{
					if (points[client] >= GetConVarInt(shotpoints))
					{
						//Give the player a shotgun
						FakeClientCommand(client, "give pumpshotgun");
						points[client] -= GetConVarInt(shotpoints);
					}
					else
					{
						PrintToChat(client,"\x05[SM]\x01 Not enough points!");
					}
				}
				case 1: //smg
				{
					if (points[client] >= GetConVarInt(smgpoints))
					{
						//Give the player an SMG
						FakeClientCommand(client, "give smg");
						points[client] -= GetConVarInt(smgpoints);
					}
					else
					{
					PrintToChat(client,"\x05[SM]\x01 Not enough points!");
					}
				}
				case 2: //rifle
				{
					if (points[client] >= GetConVarInt(riflepoints))
					{
						//Give the player a rifle
						FakeClientCommand(client, "give rifle");
						points[client] -= GetConVarInt(riflepoints);
					}
					else
					{
						PrintToChat(client,"\x05[SM]\x01 Not enough points!");
					}
				}
				case 3: //hunting rifle
				{
					if (points[client] >= GetConVarInt(huntingpoints))
					{
						//Give the player a hunting rifle
						FakeClientCommand(client, "give hunting_rifle");
						points[client] -= GetConVarInt(huntingpoints);
					}
					else
					{
						PrintToChat(client,"\x05[SM]\x01 Not enough points!");
					}
				}
				case 4: //auto shotgun
				{
					if (points[client] >= GetConVarInt(autopoints))
					{
						//Give the player an auto shotgun
						FakeClientCommand(client, "give autoshotgun");
						points[client] -= GetConVarInt(autopoints);
					}
					else
					{
						PrintToChat(client,"\x05[SM]\x01 Not enough points!");
					}
				}
				case 5: //pipe bomb
				{
					if (points[client] >= GetConVarInt(pipepoints))
					{
						//Give the player a pipebomb
						FakeClientCommand(client, "give pipe_bomb");
						points[client] -= GetConVarInt(pipepoints);
					}
					else
					{
						PrintToChat(client,"\x05[SM]\x01 Not enough points!");
					}
				}
				case 6: //molotov
				{
					if (points[client] >= GetConVarInt(molopoints))
					{
						//Give the player a molotov
						FakeClientCommand(client, "give molotov");
						points[client] -= GetConVarInt(molopoints);
					}
					else
					{
						PrintToChat(client,"\x05[SM]\x01 Not enough points!");
					}
				}
				case 7: //pistol
				{
					if (points[client] >= GetConVarInt(pistolpoints))
					{
						//Give the player a pistol
						FakeClientCommand(client, "give pistol");
						points[client] -= GetConVarInt(pistolpoints);
					}
					else
					{
						PrintToChat(client,"\x05[SM]\x01 Not enough points!");
					}
				}
				case 8: //pills
				{
				   if (points[client] >= GetConVarInt(pillspoints))
					{
						//Give the player pain pills
						FakeClientCommand(client, "give pain_pills");
						points[client] -= GetConVarInt(pillspoints);
					}
					else
					{
						PrintToChat(client,"\x05[SM]\x01 Not enough points!");
					}
				}
				case 9: //medkit
				{
					if (points[client] >= GetConVarInt(medpoints))
					{
						//Give the player a medkit
						FakeClientCommand(client, "give first_aid_kit");
						points[client] -= GetConVarInt(medpoints);
					}
					else
					{
						PrintToChat(client,"\x05[SM]\x01 Not enough points!");
					}
				}
				case 10: //refill
				{
					if (points[client] >= GetConVarInt(refillpoints))
					{
						//Refill ammo
						FakeClientCommand(client, "give ammo");
						points[client] -= GetConVarInt(refillpoints);
					}
					else
					{
						PrintToChat(client,"\x05[SM]\x01 Not enough points!");
					}
				}
				case 11: //heal
				{
					if (points[client] >= GetConVarInt(healpoints))
					{
						//Heal player
						FakeClientCommand(client, "give health");
						points[client] -= GetConVarInt(healpoints);
					}
					else
					{
						PrintToChat(client,"\x05[SM]\x01 Not enough points!");
					}
				}
				case 12: //suicide
				{
					if (points[client] >= GetConVarInt(suicidepoints))
					{
						//Kill yourself (for boomers)
						FakeClientCommand(client, "kill");
						points[client] -= GetConVarInt(suicidepoints);
					}
					else
					{
						PrintToChat(client,"\x05[SM]\x01 Not enough points!");
					}
				}
				case 13: //heal
				{
					if (points[client] >= GetConVarInt(ihealpoints))
					{
						//Give the player health
						FakeClientCommand(client, "give health");
						points[client] -= GetConVarInt(ihealpoints);
					}
					else
					{
						PrintToChat(client,"\x05[SM]\x01 Not enough points!");
					}
				}
				case 14: //boomer
				{
					if (points[client] >= GetConVarInt(boomerpoints))
					{
						//Make the player a boomer
						FakeClientCommand(client, "z_spawn boomer auto");
						points[client] -= GetConVarInt(boomerpoints);
					}
					else
					{
						PrintToChat(client,"\x05[SM]\x01 Not enough points!");
					}
				}
				case 15: //hunter
				{
					if (points[client] >= GetConVarInt(hunterpoints))
					{
						//Make the player a hunter
						FakeClientCommand(client, "z_spawn hunter auto");
						points[client] -= GetConVarInt(hunterpoints);
					}
					else
					{
						PrintToChat(client,"\x05[SM]\x01 Not enough points!");
					}
				}
				case 16: //smoker
				{
					if (points[client] >= GetConVarInt(smokerpoints))
					{
						//Make the player a smoker
						FakeClientCommand(client, "z_spawn smoker auto");
						points[client] -= GetConVarInt(smokerpoints);
					}
					else
					{
						PrintToChat(client,"\x05[SM]\x01 Not enough points!");
					}
				}
				case 17: //tank
				{
					if (points[client] >= GetConVarInt(tankpoints))
					{
						numtanks += 1;
						if (numtanks < GetConVarInt(tanklimit) + 1)
						{
							//Make the player a tank
							FakeClientCommand(client, "z_spawn tank auto");
							points[client] -= GetConVarInt(tankpoints);
						}
						else
						{
							PrintToChat(client,"\x05[SM]\x01 Tank limit for the round has been reached!");
						}
					}
					else
					{
						PrintToChat(client,"\x05[SM]\x01 Not enough points!");
					}
				}
				case 18: //spawn witch
				{
					if (points[client] >= GetConVarInt(wwitchpoints))
					{
						numwitches += 1;
						if (numwitches < GetConVarInt(witchlimit) + 1)
						{
							//Spawn a witch
							FakeClientCommand(client, "z_spawn witch auto");
							points[client] -= GetConVarInt(wwitchpoints);
						}
						else
						{
							PrintToChat(client,"\x05[SM]\x01 Witch limit for the round has been reached!");
						}
					}
					else
					{
						PrintToChat(client,"\x05[SM]\x01 Not enough points!");
					}
				}
				case 19: //spawn mob
				{
					if (points[client] >= GetConVarInt(mobpoints))
					{
						//Spawn a mob
						FakeClientCommand(client, "z_spawn mob");
						points[client] -= GetConVarInt(mobpoints);
					}
					else
					{
						PrintToChat(client,"\x05[SM]\x01 Not enough points!");
					}
				}
				case 20: //spawn mega mob
				{
					if (points[client] >= GetConVarInt(panicpoints))
					{
						//Spawn a mob
						FakeClientCommand(client, "director_force_panic_event");
						points[client] -= GetConVarInt(panicpoints);
					}
					else
					{
						PrintToChat(client,"\x05[SM]\x01 Not enough points!");
					}
				}
				case 21: //incendiary
				{
					if (points[client] >= GetConVarInt(burnpoints))
					{
						//Give Incendiary Ammo
						FakeClientCommand(client, "upgrade_add INCENDIARY_AMMO");
						points[client] -= GetConVarInt(burnpoints);
					}
					else
					{
						PrintToChat(client,"\x05[SM]\x01 Not enough points!");
					}
				}
				case 22: //super incendiary
				{
					if (points[client] >= GetConVarInt(burnpackpoints))
					{
						//Give Super Incendiary
						FakeClientCommand(client, "give upgradepack_incendiary");
						points[client] -= GetConVarInt(burnpackpoints);
					}
					else
					{
						PrintToChat(client,"\x05[SM]\x01 Not enough points!");
					}
				}
				case 23: //adrenaline
				{
				   if (points[client] >= GetConVarInt(adrenalinepoints))
					{
						//Give the player an adrenaline shot
						FakeClientCommand(client, "give adrenaline");
						points[client] -= GetConVarInt(adrenalinepoints);
					}
					else
					{
						PrintToChat(client,"\x05[SM]\x01 Not enough points!");
					}
				}
				case 24: //defib
				{
				   if (points[client] >= GetConVarInt(defibpoints))
					{
						//Give the player a defib
						FakeClientCommand(client, "give defibrillator");
						points[client] -= GetConVarInt(defibpoints);
					}
					else
					{
						PrintToChat(client,"\x05[SM]\x01 Not enough points!");
					}
				}
				case 25: //spas shotty
				{
				   if (points[client] >= GetConVarInt(spasshotpoints))
					{
						//Give the player a spas shotty
						FakeClientCommand(client, "give shotgun_spas");
						points[client] -= GetConVarInt(spasshotpoints);
					}
					else
					{
						PrintToChat(client,"\x05[SM]\x01 Not enough points!");
					}
				}
				case 26: //chrome shotty
				{
				   if (points[client] >= GetConVarInt(chromeshotpoints))
					{
						//Give the player a chrome shotty
						FakeClientCommand(client, "give shotgun_chrome");
						points[client] -= GetConVarInt(chromeshotpoints);
					}
					else
					{
						PrintToChat(client,"\x05[SM]\x01 Not enough points!");
					}
				}
				case 27: //magnum
				{
				   if (points[client] >= GetConVarInt(magnumpoints))
					{
						//Give the player a magnum
						FakeClientCommand(client, "give pistol_magnum");
						points[client] -= GetConVarInt(magnumpoints);
					}
					else
					{
						PrintToChat(client,"\x05[SM]\x01 Not enough points!");
					}
				}
				case 28: //ak47
				{
				   if (points[client] >= GetConVarInt(ak47points))
					{
						//Give the player an ak47
						FakeClientCommand(client, "give rifle_ak47");
						points[client] -= GetConVarInt(ak47points);
					}
					else
					{
						PrintToChat(client,"\x05[SM]\x01 Not enough points!");
					}
				}
				case 29: //desert
				{
				   if (points[client] >= GetConVarInt(desertpoints))
					{
						//Give the player a desert rifle
						FakeClientCommand(client, "give rifle_desert");
						points[client] -= GetConVarInt(desertpoints);
					}
					else
					{
						PrintToChat(client,"\x05[SM]\x01 Not enough points!");
					}
				}
				case 30: //sg552
				{
				   if (points[client] >= GetConVarInt(sg552points))
					{
						//Give the player a sg552
						FakeClientCommand(client, "give rifle_sg552");
						points[client] -= GetConVarInt(sg552points);
					}
					else
					{
						PrintToChat(client,"\x05[SM]\x01 Not enough points!");
					}
				}
				case 31: //silenced smg
				{
				   if (points[client] >= GetConVarInt(silencedsmgpoints))
					{
						//Give the player a silenced smg
						FakeClientCommand(client, "give smg_silenced");
						points[client] -= GetConVarInt(silencedsmgpoints);
					}
					else
					{
						PrintToChat(client,"\x05[SM]\x01 Not enough points!");
					}
				}
				case 32: //mp5
				{
				   if (points[client] >= GetConVarInt(mp5points))
					{
						//Give the player a mp5
						FakeClientCommand(client, "give smg_mp5");
						points[client] -= GetConVarInt(mp5points);
					}
					else
					{
						PrintToChat(client,"\x05[SM]\x01 Not enough points!");
					}
				}
				case 33: //awp sniper
				{
				   if (points[client] >= GetConVarInt(awppoints))
					{
						//Give the player pain pills
						FakeClientCommand(client, "give sniper_awp");
						points[client] -= GetConVarInt(awppoints);
					}
					else
					{
						PrintToChat(client,"\x05[SM]\x01 Not enough points!");
					}
				}
				case 34: //military sniper
				{
				   if (points[client] >= GetConVarInt(militarypoints))
					{
						//Give the player pain a military sniper
						FakeClientCommand(client, "give sniper_military");
						points[client] -= GetConVarInt(militarypoints);
					}
					else
					{
						PrintToChat(client,"\x05[SM]\x01 Not enough points!");
					}
				}
				case 35: //scout sniper
				{
				   if (points[client] >= GetConVarInt(scoutpoints))
					{
						//Give the player a scount sniper
						FakeClientCommand(client, "give sniper_scout");
						points[client] -= GetConVarInt(scoutpoints);
					}
					else
					{
						PrintToChat(client,"\x05[SM]\x01 Not enough points!");
					}
				}
				case 36: //grenade launcher
				{
				   if (points[client] >= GetConVarInt(grenadepoints))
					{
						//Give the player a grenade launcher
						FakeClientCommand(client, "give grenade_launcher");
						points[client] -= GetConVarInt(grenadepoints);
					}
					else
					{
						PrintToChat(client,"\x05[SM]\x01 Not enough points!");
					}
				}
				case 37: //vomitjar
				{
				   if (points[client] >= GetConVarInt(vomitjarpoints))
					{
						//Give the player a vomitjar
						FakeClientCommand(client, "give vomitjar");
						points[client] -= GetConVarInt(vomitjarpoints);
					}
					else
					{
						PrintToChat(client,"\x05[SM]\x01 Not enough points!");
					}
				}
				case 38: //firework crate
				{
				   if (points[client] >= GetConVarInt(fireworkpoints))
					{
						//Give the player a firework crate
						FakeClientCommand(client, "give fireworkcrate");
						points[client] -= GetConVarInt(fireworkpoints);
					}
					else
					{
						PrintToChat(client,"\x05[SM]\x01 Not enough points!");
					}
				}
				case 39: //oxygentank
				{
					if (points[client] >= GetConVarInt(oxygenpoints))
					{
						//Give the player an oxygentank
						FakeClientCommand(client, "give oxygentank");
						points[client] -= GetConVarInt(oxygenpoints);
					}
					else
					{
						PrintToChat(client,"\x05[SM]\x01 Not enough points!");
					}
				}
				case 40: //propane tank
				{
				   if (points[client] >= GetConVarInt(propanepoints))
					{
						//Give the player a propane tank
						FakeClientCommand(client, "give propanetank");
						points[client] -= GetConVarInt(propanepoints);
					}
					else
					{
						PrintToChat(client,"\x05[SM]\x01 Not enough points!");
					}
				}
				case 41: //explosive ammo
				{
				   if (points[client] >= GetConVarInt(explosivepackpoints))
					{
						//Give the player explosive ammo
						FakeClientCommand(client, "give upgradepack_explosive");
						points[client] -= GetConVarInt(explosivepackpoints);
					}
					else
					{
						PrintToChat(client,"\x05[SM]\x01 Not enough points!");
					}
				}
				case 42: //chainsaw
				{
				   if (points[client] >= GetConVarInt(chainsawpoints))
					{
						//Give the player chainsaw
						FakeClientCommand(client, "give chainsaw");
						points[client] -= GetConVarInt(chainsawpoints);
					}
					else
					{
						PrintToChat(client,"\x05[SM]\x01 Not enough points!");
					}
				}
				case 43: //gascan
				{
				   if (points[client] >= GetConVarInt(gascanpoints))
					{
						//Give the player gascan
						FakeClientCommand(client, "give gascan");
						points[client] -= GetConVarInt(gascanpoints);
					}
					else
					{
						PrintToChat(client,"\x05[SM]\x01 Not enough points!");
					}
				}
				case 44: //spitter
				{
					if (points[client] >= GetConVarInt(spitterpoints))
					{
						//Make the player a smoker
						FakeClientCommand(client, "z_spawn spitter auto");
						points[client] -= GetConVarInt(spitterpoints);
					}
					else
					{
						PrintToChat(client,"\x05[SM]\x01 Not enough points!");
					}
				}
				case 45: //charger
				{
					if (points[client] >= GetConVarInt(chargerpoints))
					{
						//Make the player a charger
						FakeClientCommand(client, "z_spawn charger auto");
						points[client] -= GetConVarInt(chargerpoints);
					}
					else
					{
						PrintToChat(client,"\x05[SM]\x01 Not enough points!");
					}
				}
				case 46: //jockey
				{
					if (points[client] >= GetConVarInt(jockeypoints))
					{
						//Make the player a smoker
						FakeClientCommand(client, "z_spawn jockey auto");
						points[client] -= GetConVarInt(jockeypoints);
					}
					else
					{
						PrintToChat(client,"\x05[SM]\x01 Not enough points!");
					}
				}
				case 47: //explosive
				{
					if (points[client] >= GetConVarInt(explosivepoints))
					{
						//Give Incendiary Ammo
						FakeClientCommand(client, "upgrade_add EXPLOSIVE_AMMO");
						points[client] -= GetConVarInt(explosivepoints);
					}
					else
					{
						PrintToChat(client,"\x05[SM]\x01 Not enough points!");
					}
				}
				case 48: //laser
				{
					if (points[client] >= GetConVarInt(laserpoints))
					{
						//Give Incendiary Ammo
						FakeClientCommand(client, "upgrade_add LASER_SIGHT");
						points[client] -= GetConVarInt(laserpoints);
					}
					else
					{
						PrintToChat(client,"\x05[SM]\x01 Not enough points!");
					}
				}
				case 49: //baseballbat
				{
					if (points[client] >= GetConVarInt(baseballbatpoints))
					{
						//give baseball bat
						FakeClientCommand(client, "give bat");
						points[client] -= GetConVarInt(baseballbatpoints);
					}
					else
					{
						PrintToChat(client,"\x05[SM]\x01 Not enough points!");
					}
				}
				case 50: //riotshield
				{
					if (points[client] >= GetConVarInt(riotshieldpoints))
					{
						//give riot shield
						FakeClientCommand(client, "give riotshield");
						points[client] -= GetConVarInt(riotshieldpoints);
					}
					else
					{
						PrintToChat(client,"\x05[SM]\x01 Not enough points!");
					}
				}
				case 51: //guitar
				{
					if (points[client] >= GetConVarInt(guitarpoints))
					{
						//give electric guitar
						FakeClientCommand(client, "give electric_guitar");
						points[client] -= GetConVarInt(guitarpoints);
					}
					else
					{
						PrintToChat(client,"\x05[SM]\x01 Not enough points!");
					}
				}
				case 52: //fryingpan
				{
					if (points[client] >= GetConVarInt(fryingpanpoints))
					{
						//give frying pan
						FakeClientCommand(client, "give frying_pan");
						points[client] -= GetConVarInt(fryingpanpoints);
					}
					else
					{
						PrintToChat(client,"\x05[SM]\x01 Not enough points!");
					}
				}
				case 53: //machete
				{
					if (points[client] >= GetConVarInt(machetepoints))
					{
						//give machete
						FakeClientCommand(client, "give machete");
						points[client] -= GetConVarInt(machetepoints);
					}
					else
					{
						PrintToChat(client,"\x05[SM]\x01 Not enough points!");
					}
				}
				case 54: //tonfa
				{
					if (points[client] >= GetConVarInt(tonfapoints))
					{
						//give tonfa
						FakeClientCommand(client, "give tonfa");
						points[client] -= GetConVarInt(tonfapoints);
					}
					else
					{
						PrintToChat(client,"\x05[SM]\x01 Not enough points!");
					}
				}
				case 55: //fireaxe
				{
					if (points[client] >= GetConVarInt(fireaxepoints))
					{
						//give fireaxe
						FakeClientCommand(client, "give fireaxe");
						points[client] -= GetConVarInt(fireaxepoints);
					}
					else
					{
						PrintToChat(client,"\x05[SM]\x01 Not enough points!");
					}
				}
				case 56: //crowbar
				{
					if (points[client] >= GetConVarInt(crowbarpoints))
					{
						//Give Incendiary Ammo
						FakeClientCommand(client, "give crowbar");
						points[client] -= GetConVarInt(crowbarpoints);
					}
					else
					{
						PrintToChat(client,"\x05[SM]\x01 Not enough points!");
					}
				}
				case 57: //cricketbat
				{
					if (points[client] >= GetConVarInt(cricketbatpoints))
					{
						//give cricket bat
						FakeClientCommand(client, "give cricket_bat");
						points[client] -= GetConVarInt(cricketbatpoints);
					}
					else
					{
						PrintToChat(client,"\x05[SM]\x01 Not enough points!");
					}
				}
				case 58: //katana
				{
					if (points[client] >= GetConVarInt(katanapoints))
					{
						//give katana
						FakeClientCommand(client, "give katana");
						points[client] -= GetConVarInt(katanapoints);
					}
					else
					{
						PrintToChat(client,"\x05[SM]\x01 Not enough points!");
					}
				}
				case 59: //knife
				{
					if (points[client] >= GetConVarInt(knifepoints))
					{
						//give knife
						FakeClientCommand(client, "give hunting_knife");
						points[client] -= GetConVarInt(knifepoints);
					}
					else
					{
						PrintToChat(client,"\x05[SM]\x01 Not enough points!");
					}
				}
			}
		}
    }
	SetCommandFlags("give", flags|FCVAR_CHEAT);
	SetCommandFlags("kill", flags2|FCVAR_CHEAT);
	SetCommandFlags("z_spawn", flags3|FCVAR_CHEAT);
	SetCommandFlags("upgrade_add", upgradeflags|FCVAR_CHEAT);
	SetCommandFlags("director_force_panic_event", flags4|FCVAR_CHEAT);
}

//11: Item Buying Menus
public PointsMenuHandler(Handle:menu, MenuAction:action, client, itemNum)
{
    	new Handle:gamemodevar = FindConVar("mp_gamemode");
    	new String:gamemode[25];
    	GetConVarString(gamemodevar,gamemode,sizeof(gamemode));
    	if ( action == MenuAction_Select ) {
        
        switch (itemNum)
        {
            	case 0: //health
            	{
			FakeClientCommand(client, "pointsmenu1health");
		}
           	case 1: //melee
            	{
			FakeClientCommand(client, "pointsmenu1melee");
		}
            	case 2: //weapons
            	{
			FakeClientCommand(client, "pointsmenu1weapons");
            	}
		case 3: //explosives
		{
			FakeClientCommand(client, "pointsmenu1explosive");
		}
		case 4: //Ammo
		{
			FakeClientCommand(client, "usepointsspecial");
		}
        }
    }
}

public PointsMenuHandlerHealth(Handle:menu, MenuAction:action, client, itemNum)
{
    
    if ( action == MenuAction_Select ) {
        
        switch (itemNum)
        {
            case 0: //adrenaline
            {
				if (GetConVarInt(adrenalinepoints) < 0)
				{
					PrintToChat(client,"\x05[SM]\x01 Sorry! The server has this purchasable disabled.");
				}
				else
				{
					//Give the player a adrenaline shot
					buyitem[client] = 23;
					FakeClientCommand(client, "pointsconfirm");
				}
			}
            case 1: //medkit
            {
				if (GetConVarInt(medpoints) < 0)
				{
					PrintToChat(client,"\x05[SM]\x01 Sorry! The server has this purchasable disabled.");
				}
				else
				{
					buyitem[client] = 9;
					FakeClientCommand(client, "pointsconfirm");
				}
            }
            case 2: //pain pills
            {
				if (GetConVarInt(pillspoints) < 0)
				{
					PrintToChat(client,"\x05[SM]\x01 Sorry! The server has this purchasable disabled.");
				}
				else
				{
					buyitem[client] = 8;
					FakeClientCommand(client, "pointsconfirm");
				}
            }
		case 3: //defib
            {
				if (GetConVarInt(defibpoints) < 0)
				{
					PrintToChat(client,"\x05[SM]\x01 Sorry! The server has this purchasable disabled.");
				}
				else
				{
					buyitem[client] = 24;
					FakeClientCommand(client, "pointsconfirm");
				}
            }
		case 4: //full health
            {
				if (GetConVarInt(healpoints) < 0)
				{
					PrintToChat(client,"\x05[SM]\x01 Sorry! The server has this purchasable disabled.");
				}
				else
				{
					buyitem[client] = 11;
					FakeClientCommand(client, "pointsconfirm");
				}
            }
		case 5: //back
		{
				//Go back
				FakeClientCommand(client, "usepoints");
		}
        }
    }
}

public PointsMenuHandlerMelee(Handle:menu, MenuAction:action, client, itemNum)
{
    
    	if ( action == MenuAction_Select ) {
        switch (itemNum)
        {
        	case 0: //baseballbat
        	{
			if (GetConVarInt(baseballbatpoints) < 0)
			{
				PrintToChat(client,"\x05[SM]\x01 Sorry! The server has this purchasable disabled.");
			}
			else
			{
				//give baseball bat
				buyitem[client] = 49;
				FakeClientCommand(client, "pointsconfirm");
			}
		}
            	case 1: //riotshield
            	{
			if (GetConVarInt(riotshieldpoints) < 0)
			{
				PrintToChat(client,"\x05[SM]\x01 Sorry! The server has this purchasable disabled.");
			}
			else
			{
				buyitem[client] = 50;
				FakeClientCommand(client, "pointsconfirm");
			}
            	}
            	case 2: //guitar
            	{
			if (GetConVarInt(guitarpoints) < 0)
			{
				PrintToChat(client,"\x05[SM]\x01 Sorry! The server has this purchasable disabled.");
			}
			else
			{
				buyitem[client] = 51;
				FakeClientCommand(client, "pointsconfirm");
			}
            	}
		case 3: //fryingpan
            	{
			if (GetConVarInt(fryingpanpoints) < 0)
			{
				PrintToChat(client,"\x05[SM]\x01 Sorry! The server has this purchasable disabled.");
			}
			else
			{
				buyitem[client] = 52;
				FakeClientCommand(client, "pointsconfirm");
			}
            	}
		case 4: //machete
            	{
			if (GetConVarInt(machetepoints) < 0)
			{
				PrintToChat(client,"\x05[SM]\x01 Sorry! The server has this purchasable disabled.");
			}
			else
			{
				buyitem[client] = 53;
				FakeClientCommand(client, "pointsconfirm");
			}
            	}
		case 5: //tonfa
           	{
			if (GetConVarInt(tonfapoints) < 0)
			{
				PrintToChat(client,"\x05[SM]\x01 Sorry! The server has this purchasable disabled.");
			}
			else
			{
				buyitem[client] = 54;
				FakeClientCommand(client, "pointsconfirm");
			}
            	}
		case 6: //fireaxe
            	{
			if (GetConVarInt(fireaxepoints) < 0)
			{
				PrintToChat(client,"\x05[SM]\x01 Sorry! The server has this purchasable disabled.");
			}
			else
			{
				buyitem[client] = 55;
				FakeClientCommand(client, "pointsconfirm");
			}
            	}
		case 7: //crowbar
            	{
			if (GetConVarInt(crowbarpoints) < 0)
			{
				PrintToChat(client,"\x05[SM]\x01 Sorry! The server has this purchasable disabled.");
			}
			else
			{
				buyitem[client] = 56;
				FakeClientCommand(client, "pointsconfirm");
			}
            	}
		case 8: //cricketbat
            	{
			if (GetConVarInt(cricketbatpoints) < 0)
			{
				PrintToChat(client,"\x05[SM]\x01 Sorry! The server has this purchasable disabled.");
			}
			else
			{
				buyitem[client] = 57;
				FakeClientCommand(client, "pointsconfirm");
				}
            	}
		case 9: //katana
            	{
			if (GetConVarInt(katanapoints) < 0)
			{
				PrintToChat(client,"\x05[SM]\x01 Sorry! The server has this purchasable disabled.");
			}
			else
			{
				buyitem[client] = 58;
				FakeClientCommand(client, "pointsconfirm");
			}
            	}
		case 10: //knife
            	{
			if (GetConVarInt(knifepoints) < 0)
			{
				PrintToChat(client,"\x05[SM]\x01 Sorry! The server has this purchasable disabled.");
			}
			else
			{
				buyitem[client] = 59;
				FakeClientCommand(client, "pointsconfirm");
			}
            	}
		case 11: //back
		{
				//Go back
				FakeClientCommand(client, "usepoints");
			}
        	}
   	}
}

public PointsMenuHandlerWeapons(Handle:menu, MenuAction:action, client, itemNum)
{
    
   	if ( action == MenuAction_Select ) {
        
        switch (itemNum)
        {
            	case 0: //smgs
            	{
			FakeClientCommand(client, "pointsmenu1smgs");
		}
            	case 1: //rifles
            	{
			FakeClientCommand(client, "pointsmenu1rifles");
            	}
            	case 2: //snipers
            	{
			FakeClientCommand(client, "pointsmenu1snipers");
            	}
		case 3: //shotguns
           	{
			FakeClientCommand(client, "pointsmenu1shotguns");
            	}
		case 4: //pistols
            	{
			FakeClientCommand(client, "pointsmenu1pistols");
            	}
		case 5: //back
		{
			//Go back
			FakeClientCommand(client, "usepoints");
        		}
		}
	}
}

public PointsMenuHandlerSmgs(Handle:menu, MenuAction:action, client, itemNum)
{
    
    if ( action == MenuAction_Select ) {
        
        switch (itemNum)
        {
            case 0: //smg
            {
				if (GetConVarInt(smgpoints) < 0)
				{
					PrintToChat(client,"\x05[SM]\x01 Sorry! The server has this purchasable disabled.");
				}
				else
				{
					buyitem[client] = 1;
					FakeClientCommand(client, "pointsconfirm");
				}
			}
            case 1: //silenced smg
            {
				if (GetConVarInt(silencedsmgpoints) < 0)
				{
					PrintToChat(client,"\x05[SM]\x01 Sorry! The server has this purchasable disabled.");
				}
				else
				{
					buyitem[client] = 31;
					FakeClientCommand(client, "pointsconfirm");
				}
            }
            case 2: //mp5
            {
				if (GetConVarInt(mp5points) < 0)
				{
					PrintToChat(client,"\x05[SM]\x01 Sorry! The server has this purchasable disabled.");
				}
				else
				{
					buyitem[client] = 32;
					FakeClientCommand(client, "pointsconfirm");
				}
            }
			case 3: //back
			{
				//Go back
				FakeClientCommand(client, "pointsmenu1weapons");
			}
        }
    }
}

public PointsMenuHandlerRifles(Handle:menu, MenuAction:action, client, itemNum)
{
    
    if ( action == MenuAction_Select ) {
        
      	switch (itemNum)
        {
     		case 0: //m4 assault
           {
				if (GetConVarInt(riflepoints) < 0)
				{
					PrintToChat(client,"\x05[SM]\x01 Sorry! The server has this purchasable disabled.");
				}
				else
				{
					buyitem[client] = 2;
					FakeClientCommand(client, "pointsconfirm");
				}
			}
      		case 1: //desert rifle
            {
				if (GetConVarInt(desertpoints) < 0)
				{
					PrintToChat(client,"\x05[SM]\x01 Sorry! The server has this purchasable disabled.");
				}
				else
				{
					buyitem[client] = 29;
					FakeClientCommand(client, "pointsconfirm");
				}
            }
      		case 2: //ak47
            {
				if (GetConVarInt(ak47points) < 0)
				{
					PrintToChat(client,"\x05[SM]\x01 Sorry! The server has this purchasable disabled.");
				}
				else
				{
					buyitem[client] = 28;
					FakeClientCommand(client, "pointsconfirm");
				}
            }
		case 3: //sg552
            {
				if (GetConVarInt(sg552points) < 0)
				{
					PrintToChat(client,"\x05[SM]\x01 Sorry! The server has this purchasable disabled.");
				}
				else
				{
					buyitem[client] = 30;
					FakeClientCommand(client, "pointsconfirm");
				}
            }
		case 4: //back
			{
				//Go back
				FakeClientCommand(client, "pointsmenu1weapons");
			}
        }
    }
}

public PointsMenuHandlerSnipers(Handle:menu, MenuAction:action, client, itemNum)
{
    
    if ( action == MenuAction_Select ) {
        
        switch (itemNum)
        {
            case 0: //hunting rifle
            {
				if (GetConVarInt(huntingpoints) < 0)
				{
					PrintToChat(client,"\x05[SM]\x01 Sorry! The server has this purchasable disabled.");
				}
				else
				{
					//Give the player a adrenaline shot
					buyitem[client] = 3;
					FakeClientCommand(client, "pointsconfirm");
				}
			}
            case 1: //awp sniper
            {
				if (GetConVarInt(awppoints) < 0)
				{
					PrintToChat(client,"\x05[SM]\x01 Sorry! The server has this purchasable disabled.");
				}
				else
				{
					buyitem[client] = 33;
					FakeClientCommand(client, "pointsconfirm");
				}
            }
            case 2: //military sniper
            {
				if (GetConVarInt(militarypoints) < 0)
				{
					PrintToChat(client,"\x05[SM]\x01 Sorry! The server has this purchasable disabled.");
				}
				else
				{
					buyitem[client] = 34;
					FakeClientCommand(client, "pointsconfirm");
				}
            }
			case 3: //scout
            {
				if (GetConVarInt(scoutpoints) < 0)
				{
					PrintToChat(client,"\x05[SM]\x01 Sorry! The server has this purchasable disabled.");
				}
				else
				{
					buyitem[client] = 35;
					FakeClientCommand(client, "pointsconfirm");
				}
            }
			case 4: //back
			{
				//Go back
				FakeClientCommand(client, "pointsmenu1weapons");
			}
        }
    }
}

public PointsMenuHandlerShotguns(Handle:menu, MenuAction:action, client, itemNum)
{
    
    if ( action == MenuAction_Select ) {
        
        switch (itemNum)
        {
            case 0: //pump shotty
            {
				if (GetConVarInt(shotpoints) < 0)
				{
					PrintToChat(client,"\x05[SM]\x01 Sorry! The server has this purchasable disabled.");
				}
				else
				{
					//Give the player a adrenaline shot
					buyitem[client] = 0;
					FakeClientCommand(client, "pointsconfirm");
				}
			}
            case 1: //chrome shotty
            {
				if (GetConVarInt(chromeshotpoints) < 0)
				{
					PrintToChat(client,"\x05[SM]\x01 Sorry! The server has this purchasable disabled.");
				}
				else
				{
					buyitem[client] = 26;
					FakeClientCommand(client, "pointsconfirm");
				}
            }
            case 2: //auto shotty
            {
				if (GetConVarInt(autopoints) < 0)
				{
					PrintToChat(client,"\x05[SM]\x01 Sorry! The server has this purchasable disabled.");
				}
				else
				{
					buyitem[client] = 4;
					FakeClientCommand(client, "pointsconfirm");
				}
            }
			case 3: //spas shotty
            {
				if (GetConVarInt(spasshotpoints) < 0)
				{
					PrintToChat(client,"\x05[SM]\x01 Sorry! The server has this purchasable disabled.");
				}
				else
				{
					buyitem[client] = 25;
					FakeClientCommand(client, "pointsconfirm");
				}
            }
			case 4: //back
			{
				//Go back
				FakeClientCommand(client, "pointsmenu1weapons");
			}
        }
    }
}

public PointsMenuHandlerPistols(Handle:menu, MenuAction:action, client, itemNum)
{
    
    if ( action == MenuAction_Select ) {
        
        switch (itemNum)
        {
            case 0: //pistol
            {
				if (GetConVarInt(pistolpoints) < 0)
				{
					PrintToChat(client,"\x05[SM]\x01 Sorry! The server has this purchasable disabled.");
				}
				else
				{
					//Give the player a pistol
					buyitem[client] = 7;
					FakeClientCommand(client, "pointsconfirm");
				}
			}
            case 1: //magnum
            {
				if (GetConVarInt(magnumpoints) < 0)
				{
					PrintToChat(client,"\x05[SM]\x01 Sorry! The server has this purchasable disabled.");
				}
				else
				{
					buyitem[client] = 27;
					FakeClientCommand(client, "pointsconfirm");
				}
            }
            case 2: //grenade launcher
            {
				if (GetConVarInt(grenadepoints) < 0)
				{
					PrintToChat(client,"\x05[SM]\x01 Sorry! The server has this purchasable disabled.");
				}
				else
				{
					buyitem[client] = 36;
					FakeClientCommand(client, "pointsconfirm");
				}
            }
            case 3: //chainsaw
            {
				if (GetConVarInt(chainsawpoints) < 0)
				{
					PrintToChat(client,"\x05[SM]\x01 Sorry! The server has this purchasable disabled.");
				}
				else
				{
					buyitem[client] = 42;
					FakeClientCommand(client, "pointsconfirm");
				}
            }
			case 4: //back
			{
				//Go back
				FakeClientCommand(client, "pointsmenu1weapons");
			}
        }
    }
}

public PointsMenuHandlerExplosive(Handle:menu, MenuAction:action, client, itemNum)
{
    
    if ( action == MenuAction_Select ) {
        
        switch (itemNum)
        {
            	case 0: //pipebomb
            	{
			if (GetConVarInt(pipepoints) < 0)
			{
				PrintToChat(client,"\x05[SM]\x01 Sorry! The server has this purchasable disabled.");
			}
			else
			{
				//Give the player a pipebomb
				buyitem[client] = 5;
				FakeClientCommand(client, "pointsconfirm");
			}
		}
          	case 1: //molotov
            	{
			if (GetConVarInt(molopoints) < 0)
			{
				PrintToChat(client,"\x05[SM]\x01 Sorry! The server has this purchasable disabled.");
			}
			else
			{
				buyitem[client] = 6;
				FakeClientCommand(client, "pointsconfirm");
			}
            	}
            	case 2: //vomitjar
            	{
			if (GetConVarInt(vomitjarpoints) < 0)
			{
				PrintToChat(client,"\x05[SM]\x01 Sorry! The server has this purchasable disabled.");
			}
			else
			{
				buyitem[client] = 37;
				FakeClientCommand(client, "pointsconfirm");
			}
            	}
		case 3: //Gascan
            	{
			if (GetConVarInt(gascanpoints) < 0)
			{
				PrintToChat(client,"\x05[SM]\x01 Sorry! The server has this purchasable disabled.");
			}
				else
			{
				buyitem[client] = 43;
				FakeClientCommand(client, "pointsconfirm");
			}
            	}
		case 4: //propane tank
            	{
			if (GetConVarInt(propanepoints) < 0)
			{
				PrintToChat(client,"\x05[SM]\x01 Sorry! The server has this purchasable disabled.");
			}
			else
			{
				buyitem[client] = 40;
				FakeClientCommand(client, "pointsconfirm");
			}
            	}
		case 5: //firework crate
            	{
			if (GetConVarInt(fireworkpoints) < 0)
			{
				PrintToChat(client,"\x05[SM]\x01 Sorry! The server has this purchasable disabled.");
			}
			else
			{
				buyitem[client] = 38;
				FakeClientCommand(client, "pointsconfirm");
			}
            	}
		case 6: //oxygentank
            	{
			if (GetConVarInt(oxygenpoints) < 0)
			{
				PrintToChat(client,"\x05[SM]\x01 Sorry! The server has this purchasable disabled.");
			}
			else
			{
				buyitem[client] = 39;
				FakeClientCommand(client, "pointsconfirm");
			}
            	}
		case 7: //back
		{
			//Go back
			FakeClientCommand(client, "usepoints");
			}
        	}
    	}
}

public InfectedPointsMenuHandler(Handle:menu, MenuAction:action, client, itemNum)
{
    if ( action == MenuAction_Select ) {
        
        switch (itemNum)
        {
            case 0: //suicide
            {
				if (GetConVarInt(suicidepoints) < 0)
				{
					PrintToChat(client,"\x05[SM]\x01 Sorry! The server has this purchasable disabled.");
				}
				else
				{
					buyitem[client] = 12;
					FakeClientCommand(client, "pointsconfirm");
				}
			}
            case 1: //heal
            {
				if (GetConVarInt(ihealpoints) < 0)
				{
					PrintToChat(client,"\x05[SM]\x01 Sorry! The server has this purchasable disabled.");
				}
				else
				{
					buyitem[client] = 13;
					FakeClientCommand(client, "pointsconfirm");
				}
            }
            case 2: //boomer
            {
				if (GetConVarInt(boomerpoints) < 0)
				{
					PrintToChat(client,"\x05[SM]\x01 Sorry! The server has this purchasable disabled.");
				}
				else
				{
					buyitem[client] = 14;
					FakeClientCommand(client, "pointsconfirm");
				}
            }
			case 3: //hunter
            {
				if (GetConVarInt(hunterpoints) < 0)
				{
					PrintToChat(client,"\x05[SM]\x01 Sorry! The server has this purchasable disabled.");
				}
				else
				{
					buyitem[client] = 15;
					FakeClientCommand(client, "pointsconfirm");
				}
            }
			case 4: //smoker
            {
				if (GetConVarInt(smokerpoints) < 0)
				{
					PrintToChat(client,"\x05[SM]\x01 Sorry! The server has this purchasable disabled.");
				}
				else
				{
					buyitem[client] = 16;
					FakeClientCommand(client, "pointsconfirm");
				}
            }
			case 5: //tank
            {
				if (GetConVarInt(tankpoints) < 0)
				{
					PrintToChat(client,"\x05[SM]\x01 Sorry! The server has this purchasable disabled.");
				}
				else
				{
					buyitem[client] = 17;
					FakeClientCommand(client, "pointsconfirm");
				}
            }
            case 6: //witch
            {
				if (GetConVarInt(wwitchpoints) < 0)
				{
					PrintToChat(client,"\x05[SM]\x01 Sorry! The server has this purchasable disabled.");
				}
				else
				{
					buyitem[client] = 18;
					FakeClientCommand(client, "pointsconfirm");
				}
			}
            case 7: //mob
            {
				if (GetConVarInt(mobpoints) < 0)
				{
					PrintToChat(client,"\x05[SM]\x01 Sorry! The server has this purchasable disabled.");
				}
				else
				{
					buyitem[client] = 19;
					FakeClientCommand(client, "pointsconfirm");
				}
            }
            case 8: //mega mob
            {
				if (GetConVarInt(panicpoints) < 0)
				{
					PrintToChat(client,"\x05[SM]\x01 Sorry! The server has this purchasable disabled.");
				}
				else
				{
					buyitem[client] = 20;
					FakeClientCommand(client, "pointsconfirm");
				}
            }
            case 9: //spitter
            {
				if (GetConVarInt(spitterpoints) < 0)
				{
					PrintToChat(client,"\x05[SM]\x01 Sorry! The server has this purchasable disabled.");
				}
				else
				{
					buyitem[client] = 44;
					FakeClientCommand(client, "pointsconfirm");
				}
			}
            case 10: //charger
            {
				if (GetConVarInt(chargerpoints) < 0)
				{
					PrintToChat(client,"\x05[SM]\x01 Sorry! The server has this purchasable disabled.");
				}
				else
				{
					buyitem[client] = 45;
					FakeClientCommand(client, "pointsconfirm");
				}
			}
            case 11: //jockey
            {
				if (GetConVarInt(jockeypoints) < 0)
				{
					PrintToChat(client,"\x05[SM]\x01 Sorry! The server has this purchasable disabled.");
				}
				else
				{
					buyitem[client] = 46;
					FakeClientCommand(client, "pointsconfirm");
				}
			}
        }
    }
}

public PointsSpecialMenuHandler(Handle:menu, MenuAction:action, client, itemNum)
{
    if ( action == MenuAction_Select ) 
	{
        
        switch (itemNum)
        {
            case 0: //incendiary
            {
				if (GetConVarInt(burnpoints) < 0)
				{
					PrintToChat(client,"\x05[SM]\x01 Sorry! The server has this purchasable disabled.");
				}
				else
				{
					buyitem[client] = 21;
					FakeClientCommand(client, "pointsconfirm");
				}
			}
			case 1: //super incendiary
			{
				if (GetConVarInt(burnpackpoints) < 0)
				{
					PrintToChat(client,"\x05[SM]\x01 Sorry! The server has this purchasable disabled.");
				}
				else
				{
					buyitem[client] = 22;
					FakeClientCommand(client, "pointsconfirm");
				}
			}		
			case 2: //explosive ammo pack
			{
				if (GetConVarInt(explosivepackpoints) < 0)
				{
					PrintToChat(client,"\x05[SM]\x01 Sorry! The server has this purchasable disabled.");
				}
				else
				{
					buyitem[client] = 41;
					FakeClientCommand(client, "pointsconfirm");
				}
			}			
			case 3: //explosive ammo
			{
				if (GetConVarInt(explosivepoints) < 0)
				{
					PrintToChat(client,"\x05[SM]\x01 Sorry! The server has this purchasable disabled.");
				}
				else
				{
					buyitem[client] = 47;
					FakeClientCommand(client, "pointsconfirm");
				}
			}	
			case 4: //refill ammo
			{
				if (GetConVarInt(refillpoints) < 0)
				{
					PrintToChat(client,"\x05[SM]\x01 Sorry! The server has this purchasable disabled.");
				}
				else
				{
					buyitem[client] = 10;
					FakeClientCommand(client, "pointsconfirm");
				}
			}	
			case 5: //laser sight
			{
				if (GetConVarInt(laserpoints) < 0)
				{
					PrintToChat(client,"\x05[SM]\x01 Sorry! The server has this purchasable disabled.");
				}
				else
				{
					buyitem[client] = 48;
					FakeClientCommand(client, "pointsconfirm");
				}
			}
			case 6: //back
			{
				//Go back
				FakeClientCommand(client, "usepoints");
			}
        	}
        }
}