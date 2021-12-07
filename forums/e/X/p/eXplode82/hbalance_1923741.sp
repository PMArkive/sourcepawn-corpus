#pragma semicolon 1
/*
						
*/

#include <sourcemod>
#include <sdktools>
#undef REQUIRE_EXTENSIONS
#include <cstrike>
#include <colors>

#define PLUGIN_VERSION "1.4"
#define TRANSLATION_FILE "hbalance.phrases"

#define MIN_DAMPING 3
#define _DEBUG 1

#define LOG_NEVER 0
#define LOG_ONACTION 0
#define LOG_ALWAYS 0

new Handle:s_activatePlugin = INVALID_HANDLE;
new Handle:s_dampingFactor = INVALID_HANDLE;
new Handle:s_logLevel = INVALID_HANDLE;
new Handle:s_roundRestartDelay = INVALID_HANDLE;
new Handle:s_warmupTime = INVALID_HANDLE;
new bool:s_isWarmup=false;

public Plugin:myinfo = 
{
	name = "H-Balance",
	author = "red!",
	description = "Generic Team balancer (supporting CS:GO)",
	version = PLUGIN_VERSION,
	url = "http://www.hanse-clan.de"
};


// globals
new s_streak[4]={0, 0, 0, 0};
new bool:s_isCstrike=true;
new s_lastSwitch[MAXPLAYERS+1];
new s_minGracePeriod = 3;
new s_teamCountCT=0;
new s_teamCountT=0;
new Handle:s_teamTableCT = INVALID_HANDLE;
new Handle:s_teamTableT = INVALID_HANDLE;


public OnPluginStart(){

	new String:GameType[10];
	GetGameFolderName(GameType, sizeof(GameType));
	
	if (StrEqual(GameType, "cstrike", false) || StrEqual(GameType, "csgo", false)) {
		s_isCstrike = true; 
		LogMessage("hbalance is running in counter strike mode");
	} else {
		s_isCstrike = false; 
		LogMessage("hbalance is running in generic game mode");
	}

	LoadTranslations(TRANSLATION_FILE);
	CreateConVar("hbalance_version", PLUGIN_VERSION, "Version of [HANSE] Team Balance", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_SPONLY);
	s_teamTableCT = CreateArray(2,MAXPLAYERS);
	s_teamTableT = CreateArray(2,MAXPLAYERS);
	
	// register commands & events
	RegAdminCmd("sm_hbalance_dbg", consoleDbgCmd, ADMFLAG_GENERIC);
	RegAdminCmd("sm_force_balance", consoleForceBalance, ADMFLAG_CHANGEMAP | ADMFLAG_KICK ); 
	s_activatePlugin= CreateConVar("sm_teambalance", "1", "Activate H-Balance team balancer",0, true, 0.0, true, 1.0);
	s_dampingFactor = CreateConVar("sm_balanceDamping", "2", "The higher the value, the slower the plugin reacts", 0, true, 0.0);
	s_roundRestartDelay = FindConVar("mp_round_restart_delay");
	s_warmupTime = FindConVar("mp_warmuptime");
	s_logLevel= CreateConVar("sm_balance_log_level", "2", "Amount of logging (0=off, 1=on balance, 2=always)",0, true, 0.0, true, 2.0);
	
	AutoExecConfig(true, "hbalance");
	
	HookEvent("round_end", 			EventRoundEnd,EventHookMode_PostNoCopy);
	HookEvent("round_start", 		EventRoundStart,EventHookMode_PostNoCopy);
}

public OnClientPutInServer(client)
{
	s_lastSwitch[client]=0;
}

public OnMapStart() 
{
	s_streak[CS_TEAM_CT]=0; 
	s_streak[CS_TEAM_T]=0; 
	
	new Float:warmupTime = 0.0;
	if (s_warmupTime !=INVALID_HANDLE) {
		warmupTime=GetConVarFloat(s_warmupTime);
	}
	if (warmupTime>0.0) {
		s_isWarmup=true;
		if (CreateTimer(warmupTime, Timer_WarmupEnd, 0, TIMER_FLAG_NO_MAPCHANGE)==INVALID_HANDLE) {
			s_isWarmup=false;
		}			
	}
}

public Action:Timer_WarmupEnd(Handle:timer, any:param)
{
	s_isWarmup=false;
}

public EventRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	for ( new i = 1; i <= MaxClients ; i++ ) {
        if ( IsClientInGame(i)) {
			s_lastSwitch[i]++;
        }
    }
}

public EventRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!s_isWarmup) 
	{
		new winner = GetEventInt(event, "winner");
		if (winner==CS_TEAM_T) {
			s_streak[CS_TEAM_T]++; 
			s_streak[CS_TEAM_CT]=0; 
		}
		if (winner==CS_TEAM_CT) { 
			s_streak[CS_TEAM_CT]++; 
			s_streak[CS_TEAM_T]=0; 
		}
		
		new Float:restartDelay=1.0;

		if (s_roundRestartDelay !=INVALID_HANDLE) {
			restartDelay=GetConVarFloat(s_roundRestartDelay)-1.0;
			if (restartDelay<0.0) { restartDelay=0.0; }
		}	
		
		if (isPluginActive()) {		
			CreateTimer(restartDelay, Timer_Balance, winner, TIMER_FLAG_NO_MAPCHANGE); 
		}
	}
}
public Action:Timer_Balance(Handle:timer, any:winner)
{
	refreshRanking();
	#if defined DEBUG
	LogMessage("score %d:%d, score weight %d:%d, team weight %d:%d, team members %d:%d, imbalance %d:%d", GetTeamScore(CS_TEAM_CT), GetTeamScore(CS_TEAM_T),s_streak[CS_TEAM_CT], s_streak[CS_TEAM_T], getTeamWeight(CS_TEAM_CT), getTeamWeight(CS_TEAM_T),	s_teamCountCT, s_teamCountT, getImbalanceRating(CS_TEAM_CT),getImbalanceRating(CS_TEAM_T));
	#endif
	
	
	new bool:balanced=false;
	new largerTeam=-1;
	if (s_teamCountT >(s_teamCountCT+1)) { largerTeam=CS_TEAM_T; }
	if (s_teamCountCT>(s_teamCountT +1)) { largerTeam=CS_TEAM_CT; }
	if (largerTeam!=-1) {
		balanceByMove(largerTeam, false);
		balanced=true;
	}
	
	if ((s_teamCountCT+s_teamCountT)>2) {
		if ((getImbalanceRating(CS_TEAM_CT)-getImbalanceRating(CS_TEAM_T)) >= getDampingFactor()) {
			balanceTeam(CS_TEAM_CT, false);
			balanced=true;
		} else if ((getImbalanceRating(CS_TEAM_T)-getImbalanceRating(CS_TEAM_CT)) >= getDampingFactor()) {
			balanceTeam(CS_TEAM_T, false);
			balanced=true;
		} 
	}
	
	if (balanced) 
	{
		if (GetConVarInt(s_logLevel)!=LOG_NEVER) { CPrintToChatAll("%T", "Teams have been balanced", LANG_SERVER); }
		#if defined DEBUG
		new leadingTeamWeight  = getTeamWeight(winner); 
		new inferiorTeamWeight = getTeamWeight(getOpposingTeamOf(winner));
		LogMessage("debug: difference %d:%d (%d)", leadingTeamWeight, inferiorTeamWeight, inferiorTeamWeight - leadingTeamWeight);
		#endif	
	} else {
		if (GetConVarInt(s_logLevel)==LOG_ALWAYS) { CPrintToChatAll("%T", "No team balancing necessary", LANG_SERVER); }
	}
}

balanceTeam(leadingTeam, bool:slay) {
	new leadingTeamWeight  = getTeamWeight(leadingTeam); 
	new inferiorTeamWeight = getTeamWeight(getOpposingTeamOf(leadingTeam));
	
	new deltaRef = inferiorTeamWeight - leadingTeamWeight;
	new result = deltaRef;
	
	if (getTeamTableSize(leadingTeam) > getTeamTableSize(getOpposingTeamOf(leadingTeam))) {
		result = balanceByMove(leadingTeam, slay);
	} else {
		result = balanceBySwap(leadingTeam, true, slay);
	} 
	
	// optional second stage
	if (((s_teamCountCT+s_teamCountT)>=(3+getDampingFactor())) && ((result<0) || (result>(100 + (getDampingFactor()*10))))) {
		LogMessage("balance result before stage2 from team balance difference %d to %d", deltaRef, result);
		result =  balanceBySwap(leadingTeam, false, slay);
	}
	
	LogMessage("balanced from team balance difference %d to %d", deltaRef, result);
	
	s_streak[leadingTeam] = s_streak[leadingTeam] / 2;
}

balanceByMove(leadingTeam, bool:slay) {

	new leadingTeamWeight  = getTeamWeight(leadingTeam); 
	new inferiorTeamWeight = getTeamWeight(getOpposingTeamOf(leadingTeam));
	
	new deltaRef = inferiorTeamWeight - leadingTeamWeight;
	new deltaBestGuess = deltaRef;
	
	new bestGuess = -1;		
	
	for (new i=0;i<getTeamTableSize(leadingTeam);i++) {
		if (s_lastSwitch[GetArrayCell(getTeamTable(leadingTeam) , i, 1)]>=s_minGracePeriod) {
			new ldscore=GetArrayCell(getTeamTable(leadingTeam), i, 0);
			new deltaThis = (inferiorTeamWeight+ldscore) - (leadingTeamWeight-ldscore);
			if (((deltaBestGuess<0) && (deltaThis>deltaBestGuess)) ||
				((deltaBestGuess>0) && (deltaThis>0) && (deltaThis<deltaBestGuess))) {
				bestGuess = i;
				deltaBestGuess = deltaThis;
			}
		}
	}
	if (bestGuess<0) {
		bestGuess=GetRandomInt(0, getTeamTableSize(leadingTeam)-1);
		new ldscore=GetArrayCell(getTeamTable(leadingTeam), bestGuess, 0);
		deltaBestGuess = (inferiorTeamWeight+ldscore) - (leadingTeamWeight-ldscore);
		LogMessage("move; no adequate target found, using random target"); 
	}
		
	movePlayerToTeam(GetArrayCell(getTeamTable(leadingTeam) , bestGuess, 1), getOpposingTeamOf(leadingTeam), slay);
	return deltaBestGuess;
}

balanceBySwap(leadingTeam, bool:force, bool:slay) {
	new leadingTeamWeight  = getTeamWeight(leadingTeam); 
	new inferiorTeamWeight = getTeamWeight(getOpposingTeamOf(leadingTeam));
	
	new deltaRef = inferiorTeamWeight - leadingTeamWeight;
	new deltaBestGuess = deltaRef;
	
	new bestGuessLT = -1;
	new bestGuessIT = -1;
	
	for (new i=0;i<getTeamTableSize(leadingTeam);i++) {
		new ldscore=GetArrayCell(getTeamTable(leadingTeam), i, 0);
		for (new j=0;j<getTeamTableSize(getOpposingTeamOf(leadingTeam));j++) {
			if ((s_lastSwitch[GetArrayCell(getTeamTable(leadingTeam) , i, 1)]>=s_minGracePeriod) && (s_lastSwitch[GetArrayCell(getTeamTable(getOpposingTeamOf(leadingTeam)) , j, 1)]>=s_minGracePeriod)) {
				new ifScore = GetArrayCell(getTeamTable(getOpposingTeamOf(leadingTeam)), j, 0);
				new deltaThis = (inferiorTeamWeight-ifScore+ldscore) - (leadingTeamWeight+ifScore-ldscore);
				if (((deltaBestGuess<0) && (deltaThis>deltaBestGuess)) ||
					((deltaBestGuess>0) && (deltaThis<deltaBestGuess) && (deltaThis>0))) {
					bestGuessLT = i;
					bestGuessIT = j;
					deltaBestGuess = deltaThis;
				}
			} 
		}
	}
	if ((bestGuessLT<0) ||(bestGuessIT<0)) {
		if (force) {
			bestGuessLT=0;
			bestGuessIT=getTeamTableSize(getOpposingTeamOf(leadingTeam))-1;
			new ldscore=GetArrayCell(getTeamTable(leadingTeam), bestGuessLT, 0);
			new ifScore = GetArrayCell(getTeamTable(getOpposingTeamOf(leadingTeam)), bestGuessIT, 0);
			deltaBestGuess = (inferiorTeamWeight-ifScore+ldscore) - (leadingTeamWeight+ifScore-ldscore);
			LogMessage("swap; no adequate targets found, using best and worst in force mode"); 
		} else {
			LogMessage("swap; no adequate targets found, doing nothing when not forced"); 
			return deltaRef;
		}
	} 
	
	new clientLT = GetArrayCell(getTeamTable(leadingTeam), bestGuessLT, 1);
	new clientIT = GetArrayCell(getTeamTable(getOpposingTeamOf(leadingTeam)), bestGuessIT, 1);
	movePlayerToTeam(clientLT, getOpposingTeamOf(leadingTeam), slay);
	movePlayerToTeam(clientIT, leadingTeam, slay);
	
	return deltaBestGuess;
}

movePlayerToTeam(client, targetTeam, bool:slay) {
	if ((client > 0) && (client <= MaxClients ) && IsClientInGame(client)) {
		
		new id; new score;
		new bool:success=false;
		for (new i=0;i<getTeamTableSize(getOpposingTeamOf(targetTeam));i++) {
			id = GetArrayCell(getTeamTable(getOpposingTeamOf(targetTeam)), i, 1);
			if (id==client) {
				// move in player tables
				score = GetArrayCell(getTeamTable(getOpposingTeamOf(targetTeam)), i, 0);
				SetArrayCell(getTeamTable(targetTeam), getTeamTableSize(targetTeam), score, 0); 
				SetArrayCell(getTeamTable(targetTeam), getTeamTableSize(targetTeam), id, 1); 
				setTeamTableSize(targetTeam, getTeamTableSize(targetTeam)+1);
				SetArrayCell(getTeamTable(getOpposingTeamOf(targetTeam)), i, 0, 0); 
				SetArrayCell(getTeamTable(getOpposingTeamOf(targetTeam)), i, 0, 1); 
				setTeamTableSize(getOpposingTeamOf(targetTeam), getTeamTableSize(getOpposingTeamOf(targetTeam))-1);
				SortADTArray(s_teamTableCT,Sort_Descending, Sort_Integer);
				SortADTArray(s_teamTableT ,Sort_Descending, Sort_Integer);
				
				// trigger team change
				new String:name[20] = ""; GetClientName(client, name, 20);
				LogMessage("moving player %s to team %s", name, (targetTeam==CS_TEAM_T) ? "Team1" : "Team2" );
				 
				new Handle:pack = CreateDataPack();
				WritePackCell(pack, client);
				WritePackCell(pack, targetTeam);
				WritePackCell(pack, (slay) ? 1:0);
				PrintCenterText(client, "%T", "You have been moved", client);
				CreateTimer(0.5, Timer_ChangeClientTeam, pack, TIMER_FLAG_NO_MAPCHANGE);
				success=true;
				s_lastSwitch[client]=0;
			}
		}
		if (!success) { LogMessage("failed moving player %d to team %s (not in source list)", client, (targetTeam==CS_TEAM_T) ? "Team1" : "Team2" ); }

	} else {
		LogMessage("trying to move invalid player %d to team %s", client, (targetTeam==CS_TEAM_T) ? "Team1" : "Team2" );
	}
}

public Action:Timer_ChangeClientTeam(Handle:timer, any:pack) {
	ResetPack(pack);
	new client = ReadPackCell(pack);
	new team = ReadPackCell(pack);
	new bool:slay = (ReadPackCell(pack)==1) ? true:false;
	CloseHandle(pack);
	if ((client > 0) && (client <= MaxClients) && IsClientInGame(client) && (GetClientTeam(client)==getOpposingTeamOf(team))) {
		if (slay && IsPlayerAlive(client)) { ForcePlayerSuicide(client); }
		if (s_isCstrike) {
			CS_SwitchTeam(client, team);
		} else {
			ChangeClientTeam(client, team);
		}
		PrintCenterText(client, "%T", "You have been moved", client);
	} else {
		LogMessage("failed on moving invalid player %d to team %s", client, (team==CS_TEAM_T) ? "Team1" : "Team2" );
	}
}

getOpposingTeamOf(team) {
	return(team==CS_TEAM_T) ? CS_TEAM_CT  : CS_TEAM_T;
}


refreshRanking() {
	s_teamCountCT=0;
	s_teamCountT=0;
	for ( new i = 1; i <= MaxClients; i++ )
    {
        if ( IsClientInGame(i) )
        {
			new team=GetClientTeam(i);
			if (team==CS_TEAM_T) {
				SetArrayCell(s_teamTableT, s_teamCountT, getPlayerScore(i), 0); 
				SetArrayCell(s_teamTableT, s_teamCountT, i, 1); 
				s_teamCountT++;
			} else if (team==CS_TEAM_CT) {
				SetArrayCell(s_teamTableCT, s_teamCountCT, getPlayerScore(i), 0); 
				SetArrayCell(s_teamTableCT, s_teamCountCT, i, 1); 
				s_teamCountCT++;
			}
        }
    }
	// pad table with zeros and sort.
	for ( new i = s_teamCountT; i < MAXPLAYERS; i++ ) {
		SetArrayCell(s_teamTableT, i, 0, 0); 
		SetArrayCell(s_teamTableT, i, 0, 1); 
	}
	for ( new j = s_teamCountCT; j < MAXPLAYERS; j++ ) {
		SetArrayCell(s_teamTableCT, j, 0, 0); 
		SetArrayCell(s_teamTableCT, j, 0, 1); 
	}
	SortADTArray(s_teamTableCT,Sort_Descending, Sort_Integer);
	SortADTArray(s_teamTableT ,Sort_Descending, Sort_Integer);
}


#define DEFAULT_SCORE 100

getPlayerScore(client) {
	new score = 50+(10*getDampingFactor());
	if ( IsClientInGame(client) )
    {
		new kills = GetClientFrags(client);
		new deaths = GetClientDeaths(client);
		if (kills==0) {kills=1;}
		if (deaths==0) {deaths=1;}
		new kdscore = DEFAULT_SCORE * kills / deaths;
		new kds = 10 - (kills + deaths);
		if (kds>0) { 
			score = (score + (DEFAULT_SCORE * kds)) / (kds+1); 
		}
		score += kdscore;
	}
	return score;
}

getTeamWeight(team) {
	return getTeamWeightInt(getTeamTable(team), getTeamTableSize(team));
}
getTeamWeightInt(Handle:scoreTable, size) {
	new score = 0;
	for (new i=0;i<size;i++) {
		score+=GetArrayCell(scoreTable, i, 0);
	}
	return score;
}


Handle:getTeamTable(team) {
	return (team==CS_TEAM_T) ? s_teamTableT  : s_teamTableCT;
}
getTeamTableSize(team) {
	return (team==CS_TEAM_T) ? s_teamCountT  : s_teamCountCT;
}
setTeamTableSize(team, size) {
	if (team==CS_TEAM_T)  {
		s_teamCountT=size;
	} else {
		s_teamCountCT=size;
	}
}

getImbalanceRating(team) {	
	if (s_streak[team]==0) {
		return 0;
	} else {
		new weightTeam     = getTeamWeight(team);
		new weightOpponent = getTeamWeight(getOpposingTeamOf(team));
		if (weightOpponent==0) {weightOpponent=1;} 
		return s_streak[team] * weightTeam / weightOpponent;
	}	
}

getDampingFactor() {
	return MIN_DAMPING + GetConVarInt(s_dampingFactor);
}


public Action:consoleForceBalance(client, args)
{
	refreshRanking();
	if ((s_teamCountCT+s_teamCountT)>0) {
	
		new String:outbuf[256]="";
		
		if (s_teamCountT >(s_teamCountCT+1)) { balanceByMove(CS_TEAM_T , true); Format(outbuf, 256, "%sMoving player to team %s. ",  outbuf, (s_isCstrike) ? "CT" : "B"); }
		if (s_teamCountCT>(s_teamCountT +1)) { balanceByMove(CS_TEAM_CT, true); Format(outbuf, 256, "%sMoving player to team %s. ",  outbuf, (s_isCstrike) ? "T" : "A"); }
		
		new tTeamWeight  = getTeamWeight(CS_TEAM_T); 
		new ctTeamWeight = getTeamWeight(CS_TEAM_CT);
		
		if (tTeamWeight>(ctTeamWeight+(DEFAULT_SCORE/2))) {
			balanceTeam(CS_TEAM_T, true);
			Format(outbuf, 256, "%sStrenghened team %s from %d to %d. ", outbuf, (s_isCstrike) ? "CT" : "B", ctTeamWeight-tTeamWeight, getTeamWeight(CS_TEAM_CT)-getTeamWeight(CS_TEAM_T));
		} else if (ctTeamWeight>(tTeamWeight+(DEFAULT_SCORE/2))) {
			balanceTeam(CS_TEAM_CT, true);
			Format(outbuf, 256, "%sStrenghened team %d from %d to %d. ", outbuf, (s_isCstrike) ? "T" : "A", tTeamWeight-ctTeamWeight, getTeamWeight(CS_TEAM_T)-getTeamWeight(CS_TEAM_CT));
		} else {
			Format(outbuf, 256, "%sTeams are sufficiently balanced.", outbuf);
		}
		PrintToConsole(client, "%s", outbuf);
	} else {
		PrintToConsole(client, "%s", "No players -> no balance.");
	}
	return Plugin_Handled;
}

printScoreTable(Handle:scoreTable, size, clientConsole) {
	for (new i=0;i<size;i++) {
		new points= GetArrayCell(scoreTable, i, 0);
		new client= GetArrayCell(scoreTable, i, 1);
		if ((client > 0) && (client <= MAXPLAYERS) && IsClientInGame(client)) {
			new String:name[20] = ""; GetClientName(client, name, 20);
			PrintToConsole(clientConsole,"%d: %s (%d)", points, name, s_lastSwitch[client]);
		} else {
			PrintToConsole(clientConsole,"--- (id %d)", client);
		}
	}
}

public Action:consoleDbgCmd(client, args)
{
	refreshRanking();
	PrintToConsole(client,"Team 1:");
	printScoreTable(s_teamTableT , s_teamCountT, client );
	PrintToConsole(client,"Team 2:");
	printScoreTable(s_teamTableCT, s_teamCountCT, client);
	
	PrintToConsole(client,"1 score %d, weight %d, score weight %d, members %d, imbalance rate %d", GetTeamScore(CS_TEAM_T ), getTeamWeight(CS_TEAM_T ), s_streak[CS_TEAM_T ], s_teamCountT , getImbalanceRating(CS_TEAM_T ));
	PrintToConsole(client,"2 score %d, weight %d, score weight %d, members %d, imbalance rate %d", GetTeamScore(CS_TEAM_CT), getTeamWeight(CS_TEAM_CT), s_streak[CS_TEAM_CT], s_teamCountCT, getImbalanceRating(CS_TEAM_CT)); 
	return Plugin_Handled;
}

bool:isPluginActive()
{
	return ((GetConVarInt(s_activatePlugin)!=0) && !s_isWarmup);
}