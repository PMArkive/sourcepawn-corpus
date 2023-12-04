/**
// ====================================================================================================
Change Log:

1.0.6 (10-July-2021)
    - Fixed particles displaying to observer while on First Person mode. (thanks "Voevoda" for reporting)
    - Added cvar to control how often should refire the particle.
    - Added cvar and detection check for clients changing models.

1.0.5 (04-June-2021)
    - Added selfie mode.
    - Fixed command access check.

1.0.4 (31-May-2021)
    - Added support to tanks on L4D2.
    - Fixed attachment position for boomer models. (boomette and L4D1 TLS modelname)

1.0.3 (30-May-2021)
    - Fixed cookies preferences not working sometimes. (thanks "Voevoda" for reporting)
    - Splitted default particle cvar into left and right eye cvars.
    - Added new particle to eyes (FIRE).
    - Added support to commons. (thanks "Maur0" for requesting)
    - Added support to witches.
    - Added support to SI. (except: Hunter on L4D1 and Tank on L4D2)

1.0.2 (17-May-2021)
    - Fixed client not in game error on SetTransmit. (thanks "weffer" for reporting)
    - Added Hungarian (hu) translation. (thanks to "KasperH")
    - Added Norwegian (no) translation. (thanks to "Tegh")
    - Added Russian (ru) translation. (thanks to "KRUTIK")

1.0.1 (09-May-2021)
    - release.

1.0.0 (05-January-2020)
    - Private release.

// ====================================================================================================
*/

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[L4D1 & L4D2] Survivor Eyes"
#define PLUGIN_AUTHOR                 "Mart"
#define PLUGIN_DESCRIPTION            "Adds a particle effect to survivor eyes"
#define PLUGIN_VERSION                "1.0.6"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?t=332388"

// ====================================================================================================
// Plugin Info
// ====================================================================================================
public Plugin myinfo =
{
    name        = PLUGIN_NAME,
    author      = PLUGIN_AUTHOR,
    description = PLUGIN_DESCRIPTION,
    version     = PLUGIN_VERSION,
    url         = PLUGIN_URL
}

// ====================================================================================================
// Includes
// ====================================================================================================
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <clientprefs>

// ====================================================================================================
// Pragmas
// ====================================================================================================
#pragma semicolon 1
#pragma newdecls required

// ====================================================================================================
// Cvar Flags
// ====================================================================================================
#define CVAR_FLAGS                    FCVAR_NOTIFY
#define CVAR_FLAGS_PLUGIN_VERSION     FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_SPONLY

// ====================================================================================================
// Filenames
// ====================================================================================================
#define CONFIG_FILENAME               "l4d_survivor_eyes"
#define TRANSLATION_FILENAME          "l4d_survivor_eyes.phrases"

// ====================================================================================================
// Defines
// ====================================================================================================
#define TEAM_SURVIVOR                 2
#define TEAM_INFECTED                 3
#define TEAM_HOLDOUT                  4

#define CHAR_UNKNOWN                  0
#define CHAR_BILL                     1
#define CHAR_ZOEY                     2
#define CHAR_FRANCIS                  3
#define CHAR_LOUIS                    4
#define CHAR_NICK                     5
#define CHAR_ROCHELLE                 6
#define CHAR_COACH                    7
#define CHAR_ELLIS                    8
#define CHAR_SMOKER                   9
#define CHAR_BOOMER                   10
#define CHAR_HUNTER                   11
#define CHAR_SPITTER                  12
#define CHAR_JOCKEY                   13
#define CHAR_CHARGER                  14
#define CHAR_TANK                     15
#define CHAR_BOOMETTE                 16
#define CHAR_BOOMER_L4D1              17

#define MAXENTITIES                   2048

#define PARTICLE1                     "witch_eye_glow"
#define PARTICLE2                     "weapon_pipebomb_fuse"
#define PARTICLE3                     "weapon_molotov_fp_fire"

#define EYE_LEFT                      1
#define EYE_RIGHT                     2
#define EYE_BOTH                      3

#define TYPE_CLIENT                   1
#define TYPE_COMMON                   2
#define TYPE_WITCH                    3

#define L4D2_ZOMBIECLASS_SMOKER       1
#define L4D2_ZOMBIECLASS_BOOMER       2
#define L4D2_ZOMBIECLASS_HUNTER       3
#define L4D2_ZOMBIECLASS_SPITTER      4
#define L4D2_ZOMBIECLASS_JOCKEY       5
#define L4D2_ZOMBIECLASS_CHARGER      6
#define L4D2_ZOMBIECLASS_TANK         8

#define L4D1_ZOMBIECLASS_SMOKER       1
#define L4D1_ZOMBIECLASS_BOOMER       2
#define L4D1_ZOMBIECLASS_HUNTER       3
#define L4D1_ZOMBIECLASS_TANK         5

#define MAXENTITIES                   2048

#define SPECMODE_FIRSTPERSON          4

#define CMD_EYES                      "sm_eyes"

// ====================================================================================================
// Plugin Cvars
// ====================================================================================================
ConVar g_hCvar_Enabled;
ConVar g_hCvar_Cookies;
ConVar g_hCvar_Detect;
ConVar g_hCvar_DetectModel;
ConVar g_hCvar_Interval;
ConVar g_hCvar_SelfieFOV;
ConVar g_hCvar_SurvivorLeftParticle;
ConVar g_hCvar_SurvivorRightParticle;
ConVar g_hCvar_SmokerLeftParticle;
ConVar g_hCvar_SmokerRightParticle;
ConVar g_hCvar_BoomerLeftParticle;
ConVar g_hCvar_BoomerRightParticle;
ConVar g_hCvar_HunterLeftParticle;
ConVar g_hCvar_HunterRightParticle;
ConVar g_hCvar_SpitterLeftParticle;
ConVar g_hCvar_SpitterRightParticle;
ConVar g_hCvar_JockeyLeftParticle;
ConVar g_hCvar_JockeyRightParticle;
ConVar g_hCvar_ChargerLeftParticle;
ConVar g_hCvar_ChargerRightParticle;
ConVar g_hCvar_TankLeftParticle;
ConVar g_hCvar_TankRightParticle;
ConVar g_hCvar_CommonLeftParticle;
ConVar g_hCvar_CommonRightParticle;
ConVar g_hCvar_WitchLeftParticle;
ConVar g_hCvar_WitchRightParticle;

// ====================================================================================================
// bool - Plugin Variables
// ====================================================================================================
bool g_bL4D2;
bool g_bEventsHooked;
bool g_bCvar_Enabled;
bool g_bCvar_Cookies;
bool g_bCvar_Detect;
bool g_bCvar_DetectModel;
bool g_bCvar_Interval;
bool g_bCvar_SelfieFOV;

// ====================================================================================================
// int - Plugin Variables
// ====================================================================================================
int g_iCvar_SelfieFOV;
int g_iCvar_SurvivorLeftParticle;
int g_iCvar_SurvivorRightParticle;
int g_iCvar_SmokerLeftParticle;
int g_iCvar_SmokerRightParticle;
int g_iCvar_BoomerLeftParticle;
int g_iCvar_BoomerRightParticle;
int g_iCvar_HunterLeftParticle;
int g_iCvar_HunterRightParticle;
int g_iCvar_SpitterLeftParticle;
int g_iCvar_SpitterRightParticle;
int g_iCvar_JockeyLeftParticle;
int g_iCvar_JockeyRightParticle;
int g_iCvar_ChargerLeftParticle;
int g_iCvar_ChargerRightParticle;
int g_iCvar_TankLeftParticle;
int g_iCvar_TankRightParticle;
int g_iCvar_CommonLeftParticle;
int g_iCvar_CommonRightParticle;
int g_iCvar_WitchLeftParticle;
int g_iCvar_WitchRightParticle;

// ====================================================================================================
// float - Plugin Variables
// ====================================================================================================
float g_fvPosLeftCommon[3];
float g_fvPosRightCommon[3];
float g_fvAngCommon[3];
float g_fvPosLeft[18][3];
float g_fvPosRight[18][3];
float g_fvAngles[18][3];
float g_fCvar_Detect;
float g_fCvar_DetectModel;
float g_fCvar_Interval;

// ====================================================================================================
// string - Plugin Variables
// ====================================================================================================
char g_sParticles[4][47] = { "", PARTICLE1, PARTICLE2, PARTICLE3 };
char g_sParticlesNames[4][47] = { "NONE", "WITCH", "PIPEBOMB", "FIRE" };
char g_sAttachmentParticle[18][8];
char g_sStopInput[50];
char g_sFireUser2Input[50];

// ====================================================================================================
// client - Plugin Variables
// ====================================================================================================
bool gc_bThirdPerson[MAXPLAYERS+1];
int gc_iLastCharacterNumber[MAXPLAYERS+1];
int gc_iEyeOption[MAXPLAYERS+1];
int gc_iLeftEyeEntRef[MAXPLAYERS+1] = { INVALID_ENT_REFERENCE, ... };
int gc_iLeftEyeParticle[MAXPLAYERS+1];
int gc_iRightEyeEntRef[MAXPLAYERS+1] = { INVALID_ENT_REFERENCE, ... };
int gc_iRightEyeParticle[MAXPLAYERS+1];
int gc_iCameraEntRef[MAXPLAYERS+1] = { INVALID_ENT_REFERENCE, ... };

// ====================================================================================================
// entity - Plugin Variables
// ====================================================================================================
int ge_iOwner[MAXENTITIES+1];
int ge_iLeftEyeEntRef[MAXENTITIES+1] = { INVALID_ENT_REFERENCE, ... };
int ge_iRightEyeEntRef[MAXENTITIES+1] = { INVALID_ENT_REFERENCE, ... };

// ====================================================================================================
// Cookies - Plugin Variables
// ====================================================================================================
Cookie g_csLeftEyeParticle;
Cookie g_csRightEyeParticle;

// ====================================================================================================
// Timer - Plugin Variables
// ====================================================================================================
Handle g_tDetect;
Handle g_tDetectModel;

// ====================================================================================================
// Plugin Start
// ====================================================================================================
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    EngineVersion engine = GetEngineVersion();

    if (engine != Engine_Left4Dead && engine != Engine_Left4Dead2)
    {
        strcopy(error, err_max, "This plugin only runs in \"Left 4 Dead\" and \"Left 4 Dead 2\" game");
        return APLRes_SilentFailure;
    }

    g_bL4D2 = (engine == Engine_Left4Dead2);

    return APLRes_Success;
}

/****************************************************************************************************/

public void OnPluginStart()
{
    // Translations
    LoadPluginTranslations();
    LoadTranslations("common.phrases");

    LoadCharacterPositions();

    CreateConVar("l4d_survivor_eyes_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
    g_hCvar_Enabled                  = CreateConVar("l4d_survivor_eyes_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Cookies                  = CreateConVar("l4d_survivor_eyes_cookies", "1", "Allow cookies for storing client preferences.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Detect                   = CreateConVar("l4d_survivor_eyes_detect", "0.5", "How often the plugin checks for thirdperson view.\n0 = OFF.", CVAR_FLAGS, true, 0.0);
    g_hCvar_DetectModel              = CreateConVar("l4d_survivor_eyes_detect_model", "1.0", "How often the plugin checks if player changed modelname.\n0 = OFF.", CVAR_FLAGS, true, 0.0);
    g_hCvar_Interval                 = CreateConVar("l4d_survivor_eyes_interval", "5.0", "How often (in seconds) should restart the eyes particle to prevent the particles disappearing.\n0 = OFF", CVAR_FLAGS, true, 0.0);
    g_hCvar_SelfieFOV                = CreateConVar("l4d_survivor_eyes_selfie_fov", "50", "Enable selfie view mode with this distance while using the particle menu.\n0 = OFF.", CVAR_FLAGS, true, 0.0);
    g_hCvar_SurvivorLeftParticle     = CreateConVar("l4d_survivor_eyes_survivor_left_particle", "1", "Apply a default particle to the Survivor's left eye.\nNote: This setting is replaced by the client cookies.\n0 = OFF, 1 = WITCH, 2 = PIPEBOMB, 3 = FIRE.", CVAR_FLAGS, true, 0.0, true, 3.0);
    g_hCvar_SurvivorRightParticle    = CreateConVar("l4d_survivor_eyes_survivor_right_particle", "1", "Apply a default particle to the Survivor's right eye.\nNote: This setting is replaced by the client cookies.\n0 = OFF, 1 = WITCH, 2 = PIPEBOMB, 3 = FIRE.", CVAR_FLAGS, true, 0.0, true, 3.0);
    g_hCvar_SmokerLeftParticle       = CreateConVar("l4d_survivor_eyes_smoker_left_particle", "1", "Apply a default particle to the Smoker's left eye.\n0 = OFF, 1 = WITCH, 2 = PIPEBOMB, 3 = FIRE.", CVAR_FLAGS, true, 0.0, true, 3.0);
    g_hCvar_SmokerRightParticle      = CreateConVar("l4d_survivor_eyes_smoker_right_particle", "1", "Apply a default particle to the Smoker's right eye.\n0 = OFF, 1 = WITCH, 2 = PIPEBOMB, 3 = FIRE.", CVAR_FLAGS, true, 0.0, true, 3.0);
    g_hCvar_BoomerLeftParticle       = CreateConVar("l4d_survivor_eyes_boomer_left_particle", "1", "Apply a default particle to the Boomer's left eye.\n0 = OFF, 1 = WITCH, 2 = PIPEBOMB, 3 = FIRE.", CVAR_FLAGS, true, 0.0, true, 3.0);
    g_hCvar_BoomerRightParticle      = CreateConVar("l4d_survivor_eyes_smoker_right_particle", "1", "Apply a default particle to the Boomer's right eye.\n0 = OFF, 1 = WITCH, 2 = PIPEBOMB, 3 = FIRE.", CVAR_FLAGS, true, 0.0, true, 3.0);
    if (g_bL4D2)
    {
        g_hCvar_HunterLeftParticle   = CreateConVar("l4d_survivor_eyes_hunter_left_particle", "1", "(L4D2 only) Apply a default particle to the Hunter's left eye.\n0 = OFF, 1 = WITCH, 2 = PIPEBOMB, 3 = FIRE.", CVAR_FLAGS, true, 0.0, true, 3.0);
        g_hCvar_HunterRightParticle  = CreateConVar("l4d_survivor_eyes_hunter_right_particle", "1", "(L4D2 only) Apply a default particle to the Hunter's right eye.\n0 = OFF, 1 = WITCH, 2 = PIPEBOMB, 3 = FIRE.", CVAR_FLAGS, true, 0.0, true, 3.0);
        g_hCvar_SpitterLeftParticle  = CreateConVar("l4d_survivor_eyes_spitter_left_particle", "1", "(L4D2 only) Apply a default particle to the Spitter's left eye.\n0 = OFF, 1 = WITCH, 2 = PIPEBOMB, 3 = FIRE.", CVAR_FLAGS, true, 0.0, true, 3.0);
        g_hCvar_SpitterRightParticle = CreateConVar("l4d_survivor_eyes_spitter_right_particle", "1", "(L4D2 only) Apply a default particle to the Spitter's right eye.\n0 = OFF, 1 = WITCH, 2 = PIPEBOMB, 3 = FIRE.", CVAR_FLAGS, true, 0.0, true, 3.0);
        g_hCvar_JockeyLeftParticle   = CreateConVar("l4d_survivor_eyes_jockey_left_particle", "1", "(L4D2 only) Apply a default particle to the Jockey's left eye.\n0 = OFF, 1 = WITCH, 2 = PIPEBOMB, 3 = FIRE.", CVAR_FLAGS, true, 0.0, true, 3.0);
        g_hCvar_JockeyRightParticle  = CreateConVar("l4d_survivor_eyes_jockey_right_particle", "1", "(L4D2 only) Apply a default particle to the Jockey's right eye.\n0 = OFF, 1 = WITCH, 2 = PIPEBOMB, 3 = FIRE.", CVAR_FLAGS, true, 0.0, true, 3.0);
        g_hCvar_ChargerLeftParticle  = CreateConVar("l4d_survivor_eyes_charger_left_particle", "1", "(L4D2 only) Apply a default particle to the Charger's left eye.\n0 = OFF, 1 = WITCH, 2 = PIPEBOMB, 3 = FIRE.", CVAR_FLAGS, true, 0.0, true, 3.0);
        g_hCvar_ChargerRightParticle = CreateConVar("l4d_survivor_eyes_charger_right_particle", "1", "(L4D2 only) Apply a default particle to the Charger's right eye.\n0 = OFF, 1 = WITCH, 2 = PIPEBOMB, 3 = FIRE.", CVAR_FLAGS, true, 0.0, true, 3.0);
    }
    g_hCvar_TankLeftParticle         = CreateConVar("l4d_survivor_eyes_tank_left_particle", "1", "Apply a default particle to the Tank's left eye.\n0 = OFF, 1 = WITCH, 2 = PIPEBOMB, 3 = FIRE.", CVAR_FLAGS, true, 0.0, true, 3.0);
    g_hCvar_TankRightParticle        = CreateConVar("l4d_survivor_eyes_tank_right_particle", "1", "Apply a default particle to the Tank's right eye.\n0 = OFF, 1 = WITCH, 2 = PIPEBOMB, 3 = FIRE.", CVAR_FLAGS, true, 0.0, true, 3.0);
    g_hCvar_CommonLeftParticle       = CreateConVar("l4d_survivor_eyes_common_left_particle", "1", "Apply a default particle to the Common's left eye.\n0 = OFF, 1 = WITCH, 2 = PIPEBOMB, 3 = FIRE.", CVAR_FLAGS, true, 0.0, true, 3.0);
    g_hCvar_CommonRightParticle      = CreateConVar("l4d_survivor_eyes_common_right_particle", "1", "Apply a default particle to the Common''s right eye.\n0 = OFF, 1 = WITCH, 2 = PIPEBOMB, 3 = FIRE.", CVAR_FLAGS, true, 0.0, true, 3.0);
    g_hCvar_WitchLeftParticle        = CreateConVar("l4d_survivor_eyes_witch_left_particle", "2", "Apply a default particle to the Witch's left eye.\n0 = OFF, 1 = WITCH, 2 = PIPEBOMB, 3 = FIRE.", CVAR_FLAGS, true, 0.0, true, 3.0);
    g_hCvar_WitchRightParticle       = CreateConVar("l4d_survivor_eyes_witch_right_particle", "2", "Apply a default particle to the Witch''s right eye.\n0 = OFF, 1 = WITCH, 2 = PIPEBOMB, 3 = FIRE.", CVAR_FLAGS, true, 0.0, true, 3.0);

    g_hCvar_Enabled.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Cookies.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Detect.AddChangeHook(Event_ConVarChanged);
    g_hCvar_DetectModel.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Interval.AddChangeHook(Event_ConVarChanged);
    g_hCvar_SelfieFOV.AddChangeHook(Event_ConVarChanged);
    g_hCvar_SurvivorLeftParticle.AddChangeHook(Event_ConVarChanged);
    g_hCvar_SurvivorRightParticle.AddChangeHook(Event_ConVarChanged);
    g_hCvar_SmokerLeftParticle.AddChangeHook(Event_ConVarChanged);
    g_hCvar_SmokerRightParticle.AddChangeHook(Event_ConVarChanged);
    g_hCvar_BoomerLeftParticle.AddChangeHook(Event_ConVarChanged);
    g_hCvar_BoomerRightParticle.AddChangeHook(Event_ConVarChanged);
    if (g_bL4D2)
    {
        g_hCvar_HunterLeftParticle.AddChangeHook(Event_ConVarChanged);
        g_hCvar_HunterRightParticle.AddChangeHook(Event_ConVarChanged);
        g_hCvar_SpitterLeftParticle.AddChangeHook(Event_ConVarChanged);
        g_hCvar_SpitterRightParticle.AddChangeHook(Event_ConVarChanged);
        g_hCvar_JockeyLeftParticle.AddChangeHook(Event_ConVarChanged);
        g_hCvar_JockeyRightParticle.AddChangeHook(Event_ConVarChanged);
        g_hCvar_ChargerLeftParticle.AddChangeHook(Event_ConVarChanged);
        g_hCvar_ChargerRightParticle.AddChangeHook(Event_ConVarChanged);
    }
    g_hCvar_TankLeftParticle.AddChangeHook(Event_ConVarChanged);
    g_hCvar_TankRightParticle.AddChangeHook(Event_ConVarChanged);
    g_hCvar_CommonLeftParticle.AddChangeHook(Event_ConVarChanged);
    g_hCvar_CommonRightParticle.AddChangeHook(Event_ConVarChanged);
    g_hCvar_WitchLeftParticle.AddChangeHook(Event_ConVarChanged);
    g_hCvar_WitchRightParticle.AddChangeHook(Event_ConVarChanged);

    // Load plugin configs from .cfg
    AutoExecConfig(true, CONFIG_FILENAME);

    // Cookies
    g_csLeftEyeParticle = new Cookie("l4d_survivor_eyes_left_eye", "Survivor Eyes - Left Eye Particle", CookieAccess_Protected);
    g_csRightEyeParticle = new Cookie("l4d_survivor_eyes_right_eye", "Survivor Eyes - Right Eye Particle", CookieAccess_Protected);

    // Commands
    RegConsoleCmd(CMD_EYES, CmdEyes, "Opens a menu to select the eye and particle to apply.");

    // Admin Commands
    RegAdminCmd("sm_eyesclient", CmdEyesClient, ADMFLAG_ROOT, "Set the client eye particle. Usage: sm_eyesclient <target> <pos:1=left|2=right|3=both> <particle:0=none|1=witch|2=pipebomb|3=fire>");
    RegAdminCmd("sm_print_cvars_l4d_survivor_eyes", CmdPrintCvars, ADMFLAG_ROOT, "Print the plugin related cvars and their respective values to the console.");
}

/****************************************************************************************************/

void LoadPluginTranslations()
{
    char path[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, path, PLATFORM_MAX_PATH, "translations/%s.txt", TRANSLATION_FILENAME);
    if (FileExists(path))
        LoadTranslations(TRANSLATION_FILENAME);
    else
        SetFailState("Missing required translation file on \"translations/%s.txt\", please re-download.", TRANSLATION_FILENAME);
}

/****************************************************************************************************/

void LoadCharacterPositions()
{
    g_fvAngCommon = view_as<float>({ 0.0, 270.0, 270.0 });
    g_fvPosLeftCommon = (g_bL4D2 ? view_as<float>({ 3.0, -3.3, 1.3 }) : view_as<float>({ 8.5, -0.5, 1.3 }));
    g_fvPosRightCommon = (g_bL4D2 ? view_as<float>({ 3.0, -3.3, -1.3 }) : view_as<float>({ 8.5, -0.5, -1.3 }));

    g_fvAngles[CHAR_BILL] = view_as<float>({ 0.0, 0.0, 0.0 });
    g_fvPosLeft[CHAR_BILL] = view_as<float>({ 0.6, 1.3, -0.3 });
    g_fvPosRight[CHAR_BILL] = view_as<float>({ 0.6, -1.2, -0.3 });
    g_sAttachmentParticle[CHAR_BILL] = "eyes";

    g_fvAngles[CHAR_ZOEY] = view_as<float>({ 0.0, 0.0, 0.0 });
    g_fvPosLeft[CHAR_ZOEY] = view_as<float>({ 0.6, 1.2, -0.6 });
    g_fvPosRight[CHAR_ZOEY] = view_as<float>({ 0.6, -1.2, -0.6 });
    g_sAttachmentParticle[CHAR_ZOEY] = "eyes";

    g_fvAngles[CHAR_FRANCIS] = view_as<float>({ 0.0, 0.0, 0.0 });
    g_fvPosLeft[CHAR_FRANCIS] = view_as<float>({ 0.6, 1.4, 0.0 });
    g_fvPosRight[CHAR_FRANCIS] = view_as<float>({ 0.6, -1.2, 0.0 });
    g_sAttachmentParticle[CHAR_FRANCIS] = "eyes";

    g_fvAngles[CHAR_LOUIS] = view_as<float>({ 0.0, 0.0, 0.0 });
    g_fvPosLeft[CHAR_LOUIS] = view_as<float>({ 0.5, 1.25, -0.25 });
    g_fvPosRight[CHAR_LOUIS] = view_as<float>({ 0.5, -1.2, -0.25 });
    g_sAttachmentParticle[CHAR_LOUIS] = "eyes";

    g_fvAngles[CHAR_NICK] = view_as<float>({ 0.0, 0.0, 0.0 });
    g_fvPosLeft[CHAR_NICK] = view_as<float>({ 2.0, 1.2, -0.1 });
    g_fvPosRight[CHAR_NICK] = view_as<float>({ 2.0, -1.2, -0.1 });
    g_sAttachmentParticle[CHAR_NICK] = "eyes";

    g_fvAngles[CHAR_ROCHELLE] = view_as<float>({ 0.0, 0.0, 0.0 });
    g_fvPosLeft[CHAR_ROCHELLE] = view_as<float>({ -0.2, 1.4, -0.5 });
    g_fvPosRight[CHAR_ROCHELLE] = view_as<float>({ -0.2, -1.3, -0.5 });
    g_sAttachmentParticle[CHAR_ROCHELLE] = "eyes";

    g_fvAngles[CHAR_COACH] = view_as<float>({ 0.0, 0.0, 0.0 });
    g_fvPosLeft[CHAR_COACH] = view_as<float>({ 0.6, 1.3, 0.05 });
    g_fvPosRight[CHAR_COACH] = view_as<float>({ 0.6, -1.3, 0.05 });
    g_sAttachmentParticle[CHAR_COACH] = "eyes";

    g_fvAngles[CHAR_ELLIS] = view_as<float>({ 0.0, 0.0, 0.0 });
    g_fvPosLeft[CHAR_ELLIS] = view_as<float>({ 0.8, 1.2, 0.7 });
    g_fvPosRight[CHAR_ELLIS] = view_as<float>({ 0.8, -1.2, 0.7 });
    g_sAttachmentParticle[CHAR_ELLIS] = "eyes";

    g_fvAngles[CHAR_SMOKER] = view_as<float>({ 0.0, 0.0, 0.0 });
    g_fvPosLeft[CHAR_SMOKER] = view_as<float>({ 0.0, 1.5, 0.3 });
    g_fvPosRight[CHAR_SMOKER] = view_as<float>({ 0.0, -1.5, 0.3 });
    g_sAttachmentParticle[CHAR_SMOKER] = "forward";

    g_fvAngles[CHAR_BOOMER] = view_as<float>({ 0.0, 0.0, 0.0 });
    g_fvPosLeft[CHAR_BOOMER] = (g_bL4D2 ? view_as<float>({ 0.5, 1.5, 0.3 }) : view_as<float>({ 0.0, 1.5, 2.75 }));
    g_fvPosRight[CHAR_BOOMER] = (g_bL4D2 ? view_as<float>({ 0.5, -1.5, 0.3 }) : view_as<float>({ 0.0, -1.5, 2.75 }));
    g_sAttachmentParticle[CHAR_BOOMER] = (g_bL4D2 ? "forward" : "mouth");

    g_fvAngles[CHAR_HUNTER] = view_as<float>({ 0.0, 0.0, 0.0 });
    g_fvPosLeft[CHAR_HUNTER] = view_as<float>({ 0.5, 1.2, 0.3 });
    g_fvPosRight[CHAR_HUNTER] = view_as<float>({ 0.5, -1.2, 0.3 });
    g_sAttachmentParticle[CHAR_HUNTER] = "forward";

    g_fvAngles[CHAR_SPITTER] = view_as<float>({ 0.0, 0.0, 0.0 });
    g_fvPosLeft[CHAR_SPITTER] = view_as<float>({ 0.1, 1.2, -0.5 });
    g_fvPosRight[CHAR_SPITTER] = view_as<float>({ 0.1, -1.2, -0.5 });
    g_sAttachmentParticle[CHAR_SPITTER] = "forward";

    g_fvAngles[CHAR_JOCKEY] = view_as<float>({ 0.0, 0.0, 0.0 });
    g_fvPosLeft[CHAR_JOCKEY] = view_as<float>({ 0.5, 1.4, 0.0 });
    g_fvPosRight[CHAR_JOCKEY] = view_as<float>({ 0.5, -1.4, 0.0 });
    g_sAttachmentParticle[CHAR_JOCKEY] = "forward";

    g_fvAngles[CHAR_CHARGER] = view_as<float>({ 0.0, 0.0, 0.0 });
    g_fvPosLeft[CHAR_CHARGER] = view_as<float>({ 0.5, 1.2, 0.3 });
    g_fvPosRight[CHAR_CHARGER] = view_as<float>({ 0.5, -1.5, 0.5 });
    g_sAttachmentParticle[CHAR_CHARGER] = "forward";

    g_fvAngles[CHAR_TANK] = (g_bL4D2 ? view_as<float>({ 270.0, 270.0, 0.0 }) : view_as<float>({ 0.0, 0.0, 0.0 }));
    g_fvPosLeft[CHAR_TANK] = (g_bL4D2 ? view_as<float>({ 1.4, 4.3, 1.4 }) : view_as<float>({ -0.5, 3.8, 1.4 }));
    g_fvPosRight[CHAR_TANK] = (g_bL4D2 ? view_as<float>({ -1.5, 4.3, 1.5 }) : view_as<float>({ -0.5, 3.8, -1.5 }));
    g_sAttachmentParticle[CHAR_TANK] = "mouth";

    g_fvAngles[CHAR_BOOMETTE] = view_as<float>({ 0.0, 0.0, 0.0 });
    g_fvPosLeft[CHAR_BOOMETTE] = view_as<float>({ 0.9, 1.85, -0.6 });
    g_fvPosRight[CHAR_BOOMETTE] = view_as<float>({ 0.9, -1.85, -0.6 });
    g_sAttachmentParticle[CHAR_BOOMETTE] = "forward";

    g_fvAngles[CHAR_BOOMER_L4D1] = view_as<float>({ 0.0, 0.0, 0.0 });
    g_fvPosLeft[CHAR_BOOMER_L4D1] = view_as<float>({ 0.0, 1.5, 2.75 });
    g_fvPosRight[CHAR_BOOMER_L4D1] = view_as<float>({ 0.0, -1.5, 2.75 });
    g_sAttachmentParticle[CHAR_BOOMER_L4D1] = "mouth";
}

/****************************************************************************************************/

public void OnMapStart()
{
    PrecacheParticle(PARTICLE1);
    PrecacheParticle(PARTICLE2);
    PrecacheParticle(PARTICLE3);
}

/****************************************************************************************************/

public void OnConfigsExecuted()
{
    GetCvars();

    LateLoad();

    HookEvents();

    delete g_tDetect;
    if (g_bCvar_Detect)
        g_tDetect = CreateTimer(g_fCvar_Detect, TimerDetect, _, TIMER_REPEAT);

    delete g_tDetectModel;
    if (g_bCvar_DetectModel)
        g_tDetectModel = CreateTimer(g_fCvar_DetectModel, TimerDetectModel, _, TIMER_REPEAT);
}

/****************************************************************************************************/

void Event_ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    GetCvars();

    HookEvents();

    delete g_tDetect;
    if (g_bCvar_Detect)
        g_tDetect = CreateTimer(g_fCvar_Detect, TimerDetect, _, TIMER_REPEAT);

    delete g_tDetectModel;
    if (g_bCvar_DetectModel)
        g_tDetectModel = CreateTimer(g_fCvar_DetectModel, TimerDetectModel, _, TIMER_REPEAT);
}

/****************************************************************************************************/

void GetCvars()
{
    g_bCvar_Enabled = g_hCvar_Enabled.BoolValue;
    g_bCvar_Cookies = g_hCvar_Cookies.BoolValue;
    g_fCvar_Detect = g_hCvar_Detect.FloatValue;
    g_bCvar_Detect = (g_fCvar_Detect > 0.0);
    g_fCvar_DetectModel = g_hCvar_DetectModel.FloatValue;
    g_bCvar_DetectModel = (g_fCvar_DetectModel > 0.0);
    g_fCvar_Interval = g_hCvar_Interval.FloatValue;
    g_bCvar_Interval = (g_fCvar_Interval > 0.0);
    g_iCvar_SelfieFOV = g_hCvar_SelfieFOV.IntValue;
    g_bCvar_SelfieFOV = (g_iCvar_SelfieFOV > 0);
    g_iCvar_SurvivorLeftParticle = g_hCvar_SurvivorLeftParticle.IntValue;
    g_iCvar_SurvivorRightParticle = g_hCvar_SurvivorRightParticle.IntValue;
    g_iCvar_SmokerLeftParticle = g_hCvar_SmokerLeftParticle.IntValue;
    g_iCvar_SmokerRightParticle = g_hCvar_SmokerRightParticle.IntValue;
    g_iCvar_BoomerLeftParticle = g_hCvar_BoomerLeftParticle.IntValue;
    g_iCvar_BoomerRightParticle = g_hCvar_BoomerRightParticle.IntValue;
    if (g_bL4D2)
    {
        g_iCvar_HunterLeftParticle = g_hCvar_HunterLeftParticle.IntValue;
        g_iCvar_HunterRightParticle = g_hCvar_HunterRightParticle.IntValue;
        g_iCvar_SpitterLeftParticle = g_hCvar_SpitterLeftParticle.IntValue;
        g_iCvar_SpitterRightParticle = g_hCvar_SpitterRightParticle.IntValue;
        g_iCvar_JockeyLeftParticle = g_hCvar_JockeyLeftParticle.IntValue;
        g_iCvar_JockeyRightParticle = g_hCvar_JockeyRightParticle.IntValue;
        g_iCvar_ChargerLeftParticle = g_hCvar_ChargerLeftParticle.IntValue;
        g_iCvar_ChargerRightParticle = g_hCvar_ChargerRightParticle.IntValue;
    }
    g_iCvar_TankLeftParticle = g_hCvar_TankLeftParticle.IntValue;
    g_iCvar_TankRightParticle = g_hCvar_TankRightParticle.IntValue;
    g_iCvar_CommonLeftParticle = g_hCvar_CommonLeftParticle.IntValue;
    g_iCvar_CommonRightParticle = g_hCvar_CommonRightParticle.IntValue;
    g_iCvar_WitchLeftParticle = g_hCvar_WitchLeftParticle.IntValue;
    g_iCvar_WitchRightParticle = g_hCvar_WitchRightParticle.IntValue;

    FormatEx(g_sStopInput, sizeof(g_sStopInput), "OnUser1 !self:Stop::%.1f:-1", g_fCvar_Interval);
    FormatEx(g_sFireUser2Input, sizeof(g_sFireUser2Input), "OnUser1 !self:FireUser2::%.1f:-1", g_fCvar_Interval + 0.1);
}

/****************************************************************************************************/

void LateLoad()
{
    for (int client = 1; client <= MaxClients; client++)
    {
        if (!IsClientInGame(client))
            continue;

        if (AreClientCookiesCached(client))
            OnClientCookiesCached(client);
    }

    int entity;

    entity = INVALID_ENT_REFERENCE;
    while ((entity = FindEntityByClassname(entity, "infected")) != INVALID_ENT_REFERENCE)
    {
        OnSpawnPostCommon(entity);
    }

    entity = INVALID_ENT_REFERENCE;
    while ((entity = FindEntityByClassname(entity, "witch")) != INVALID_ENT_REFERENCE)
    {
        OnSpawnPostWitch(entity);
    }
}

/****************************************************************************************************/

public void OnClientDisconnect(int client)
{
    gc_bThirdPerson[client] = false;
    gc_iLastCharacterNumber[client] = CHAR_UNKNOWN;
    gc_iEyeOption[client] = 0;
    gc_iLeftEyeEntRef[client] = INVALID_ENT_REFERENCE;
    gc_iLeftEyeParticle[client] = 0;
    gc_iRightEyeEntRef[client] = INVALID_ENT_REFERENCE;
    gc_iRightEyeParticle[client] = 0;
    gc_iCameraEntRef[client] = INVALID_ENT_REFERENCE;
}

/****************************************************************************************************/

public void OnClientCookiesCached(int client)
{
    gc_iLeftEyeParticle[client] = g_iCvar_SurvivorLeftParticle;
    gc_iRightEyeParticle[client] = g_iCvar_SurvivorRightParticle;

    if (g_bCvar_Cookies && !IsFakeClient(client))
    {
        char value[3];

        g_csLeftEyeParticle.Get(client, value, sizeof(value));
        if (value[0] != 0)
            gc_iLeftEyeParticle[client] = StringToInt(value);

        g_csRightEyeParticle.Get(client, value, sizeof(value));
        if (value[0] != 0)
            gc_iRightEyeParticle[client] = StringToInt(value);
    }

    CreatePlayerEyes(client);
}

/****************************************************************************************************/

void HookEvents()
{
    if (g_bCvar_Enabled && !g_bEventsHooked)
    {
        g_bEventsHooked = true;

        HookEvent("player_spawn", Event_PlayerSpawn);
        HookEvent("player_death", Event_PlayerDeath);

        return;
    }

    if (!g_bCvar_Enabled && g_bEventsHooked)
    {
        g_bEventsHooked = false;

        UnhookEvent("player_spawn", Event_PlayerSpawn);
        UnhookEvent("player_death", Event_PlayerDeath);

        return;
    }
}

/****************************************************************************************************/

public void OnPluginEnd()
{
    int entity;

    for (int client = 1; client <= MaxClients; client++)
    {
        if (gc_iLeftEyeEntRef[client] != INVALID_ENT_REFERENCE)
        {
            entity = EntRefToEntIndex(gc_iLeftEyeEntRef[client]);

            if (entity != INVALID_ENT_REFERENCE)
                AcceptEntityInput(entity, "Kill");

            gc_iLeftEyeEntRef[client] = INVALID_ENT_REFERENCE;
        }

        if (gc_iRightEyeEntRef[client] != INVALID_ENT_REFERENCE)
        {
            entity = EntRefToEntIndex(gc_iRightEyeEntRef[client]);

            if (entity != INVALID_ENT_REFERENCE)
                AcceptEntityInput(entity, "Kill");

            gc_iRightEyeEntRef[client] = INVALID_ENT_REFERENCE;
        }

        if (gc_iCameraEntRef[client] != INVALID_ENT_REFERENCE)
        {
            entity = EntRefToEntIndex(gc_iCameraEntRef[client]);

            if (entity != INVALID_ENT_REFERENCE)
            {
                AcceptEntityInput(entity, "Disable");
                AcceptEntityInput(entity, "Kill");
            }

            gc_iCameraEntRef[client] = INVALID_ENT_REFERENCE;
        }
    }

    for (int target = MaxClients+1; target <= MAXENTITIES; target++)
    {
        if (ge_iLeftEyeEntRef[target] != INVALID_ENT_REFERENCE)
        {
            entity = EntRefToEntIndex(ge_iLeftEyeEntRef[target]);

            if (entity != INVALID_ENT_REFERENCE)
            {
                ge_iLeftEyeEntRef[entity] = INVALID_ENT_REFERENCE;
                AcceptEntityInput(entity, "Kill");
            }
        }

        if (ge_iRightEyeEntRef[target] != INVALID_ENT_REFERENCE)
        {
            entity = EntRefToEntIndex(ge_iRightEyeEntRef[target]);

            if (entity != INVALID_ENT_REFERENCE)
            {
                ge_iRightEyeEntRef[entity] = INVALID_ENT_REFERENCE;
                AcceptEntityInput(entity, "Kill");
            }
        }
    }
}

/****************************************************************************************************/

public void OnEntityDestroyed(int entity)
{
    if (entity < 0)
        return;

    ge_iOwner[entity] = 0;
    ge_iLeftEyeEntRef[entity] = INVALID_ENT_REFERENCE;
    ge_iRightEyeEntRef[entity] = INVALID_ENT_REFERENCE;
}

/****************************************************************************************************/

public void OnEntityCreated(int entity, const char[] classname)
{
    if (!g_bCvar_Enabled)
        return;

    if (entity < 0)
        return;

    switch (classname[0])
    {
        case 'i':
        {
            if (StrEqual(classname, "infected"))
                SDKHook(entity, SDKHook_SpawnPost, OnSpawnPostCommon);
        }
        case 'w':
        {
            if (classname[1] != 'i')
                return;

            if (StrEqual(classname, "witch"))
                SDKHook(entity, SDKHook_SpawnPost, OnSpawnPostWitch);
        }
    }
}

/****************************************************************************************************/

void OnSpawnPostCommon(int entity)
{
    CreateEyeParticle(entity, EYE_LEFT, TYPE_COMMON);
    CreateEyeParticle(entity, EYE_RIGHT, TYPE_COMMON);
}

/****************************************************************************************************/

void OnSpawnPostWitch(int entity)
{
    CreateEyeParticle(entity, EYE_LEFT, TYPE_WITCH);
    CreateEyeParticle(entity, EYE_RIGHT, TYPE_WITCH);
}

/****************************************************************************************************/

void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    int target = event.GetInt("entityid");

    if (client != 0)
    {
        int entity;

        if (gc_iLeftEyeEntRef[client] != INVALID_ENT_REFERENCE)
        {
            entity = EntRefToEntIndex(gc_iLeftEyeEntRef[client]);

            if (entity != INVALID_ENT_REFERENCE)
                AcceptEntityInput(entity, "Kill");

            gc_iLeftEyeEntRef[client] = INVALID_ENT_REFERENCE;
        }

        if (gc_iRightEyeEntRef[client] != INVALID_ENT_REFERENCE)
        {
            entity = EntRefToEntIndex(gc_iRightEyeEntRef[client]);

            if (entity != INVALID_ENT_REFERENCE)
                AcceptEntityInput(entity, "Kill");

            gc_iRightEyeEntRef[client] = INVALID_ENT_REFERENCE;
        }

        if (gc_iCameraEntRef[client] != INVALID_ENT_REFERENCE)
        {
            entity = EntRefToEntIndex(gc_iCameraEntRef[client]);

            if (entity != INVALID_ENT_REFERENCE)
            {
                AcceptEntityInput(entity, "Disable");
                AcceptEntityInput(entity, "Kill");
            }

            gc_iCameraEntRef[client] = INVALID_ENT_REFERENCE;
        }

        return;
    }

    if (target > 0)
    {
        int entity;

        if (ge_iLeftEyeEntRef[target] != INVALID_ENT_REFERENCE)
        {
            entity = EntRefToEntIndex(ge_iLeftEyeEntRef[target]);

            if (entity != INVALID_ENT_REFERENCE)
            {
                ge_iLeftEyeEntRef[entity] = INVALID_ENT_REFERENCE;
                AcceptEntityInput(entity, "Kill");
            }
        }

        if (ge_iRightEyeEntRef[target] != INVALID_ENT_REFERENCE)
        {
            entity = EntRefToEntIndex(ge_iRightEyeEntRef[target]);

            if (entity != INVALID_ENT_REFERENCE)
            {
                ge_iRightEyeEntRef[entity] = INVALID_ENT_REFERENCE;
                AcceptEntityInput(entity, "Kill");
            }
        }

        return;
    }
}

/****************************************************************************************************/

void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));

    if (client == 0)
        return;

    CreatePlayerEyes(client);
}

/****************************************************************************************************/

Action TimerDetect(Handle timer)
{
    for (int client = 1; client <= MaxClients; client++)
    {
        if (!IsClientInGame(client))
            continue;

        if (!IsPlayerAlive(client))
            continue;

        gc_bThirdPerson[client] = IsSurvivorThirdPerson(client);
    }

    return Plugin_Continue;
}

/****************************************************************************************************/

Action TimerDetectModel(Handle timer)
{
    for (int client = 1; client <= MaxClients; client++)
    {
        if (!IsClientInGame(client))
            continue;

        if (!IsPlayerAlive(client))
            continue;

        int currentChar = GetCharacterNumber(client);
        if (currentChar != gc_iLastCharacterNumber[client])
        {
            gc_iLastCharacterNumber[client] = currentChar;
            CreatePlayerEyes(client);
        }
    }

    return Plugin_Continue;
}

/****************************************************************************************************/

void CreatePlayerEyes(int client)
{
    if (!g_bCvar_Enabled)
        return;

    if (!IsValidClient(client))
        return;

    if (!CheckCommandAccess(client, CMD_EYES, 0))
        return;

    CreateEyeParticle(client, EYE_LEFT, TYPE_CLIENT);
    CreateEyeParticle(client, EYE_RIGHT, TYPE_CLIENT);
}

/****************************************************************************************************/

void CreateEyeParticle(int target, int pos, int type)
{
    int entity;

    switch (type)
    {
        case TYPE_CLIENT:
        {
            int client = target;
            int charIndex = GetCharacterNumber(client);

            if (charIndex == CHAR_UNKNOWN)
                return;

            switch (pos)
            {
                case EYE_LEFT:
                {
                    if (gc_iLeftEyeEntRef[client] != INVALID_ENT_REFERENCE)
                    {
                        entity = EntRefToEntIndex(gc_iLeftEyeEntRef[client]);

                        if (entity != INVALID_ENT_REFERENCE)
                        {
                            gc_iLeftEyeEntRef[client] = INVALID_ENT_REFERENCE;
                            AcceptEntityInput(entity, "Kill");
                        }
                    }

                    if (gc_iLeftEyeParticle[client] > 0 && gc_iLeftEyeParticle[client] < sizeof(g_sParticles))
                    {
                        entity = CreateParticle(g_sParticles[gc_iLeftEyeParticle[client]], g_fvPosLeft[charIndex], g_fvAngles[charIndex], client, g_sAttachmentParticle[charIndex]);
                        gc_iLeftEyeEntRef[client] = EntIndexToEntRef(entity);
                        ge_iOwner[entity] = client;
                    }
                }
                case EYE_RIGHT:
                {
                    if (gc_iRightEyeEntRef[client] != INVALID_ENT_REFERENCE)
                    {
                        entity = EntRefToEntIndex(gc_iRightEyeEntRef[client]);

                        if (entity != INVALID_ENT_REFERENCE)
                        {
                            gc_iRightEyeEntRef[client] = INVALID_ENT_REFERENCE;
                            AcceptEntityInput(entity, "Kill");
                        }
                    }

                    if (gc_iRightEyeParticle[client] > 0 && gc_iRightEyeParticle[client] < sizeof(g_sParticles))
                    {
                        entity = CreateParticle(g_sParticles[gc_iRightEyeParticle[client]], g_fvPosRight[charIndex], g_fvAngles[charIndex], client, g_sAttachmentParticle[charIndex]);
                        gc_iRightEyeEntRef[client] = EntIndexToEntRef(entity);
                        ge_iOwner[entity] = client;
                    }
                }
            }
        }
        case TYPE_COMMON:
        {
            switch (pos)
            {
                case EYE_LEFT:
                {
                    if (g_iCvar_WitchLeftParticle > 0)
                    {
                        entity = CreateParticle(g_sParticles[g_iCvar_CommonLeftParticle], g_fvPosLeftCommon, g_fvAngCommon, target, "head");
                        ge_iLeftEyeEntRef[target] = EntIndexToEntRef(entity);
                    }
                }
                case EYE_RIGHT:
                {
                    if (g_iCvar_WitchRightParticle > 0)
                    {
                        entity = CreateParticle(g_sParticles[g_iCvar_CommonRightParticle], g_fvPosRightCommon, g_fvAngCommon, target, "head");
                        ge_iRightEyeEntRef[target] = EntIndexToEntRef(entity);
                    }
                }
            }
        }
        case TYPE_WITCH:
        {
            switch (pos)
            {
                case EYE_LEFT:
                {
                    if (g_iCvar_CommonLeftParticle > 0)
                    {
                        entity = CreateParticle(g_sParticles[g_iCvar_WitchLeftParticle], NULL_VECTOR, NULL_VECTOR, target, "leye");
                        ge_iLeftEyeEntRef[target] = EntIndexToEntRef(entity);
                    }
                }
                case EYE_RIGHT:
                {
                    if (g_iCvar_CommonRightParticle > 0)
                    {
                        entity = CreateParticle(g_sParticles[g_iCvar_WitchRightParticle], NULL_VECTOR, NULL_VECTOR, target, "reye");
                        ge_iRightEyeEntRef[target] = EntIndexToEntRef(entity);
                    }
                }
            }
        }
    }
}

/****************************************************************************************************/

int CreateParticle(char[] particle, float vPos[3], float vAng[3], int target, const char[] attachment)
{
    int entity = CreateEntityByName("info_particle_system");

    DispatchKeyValue(entity, "targetname", "l4d_survivor_eyes");
    DispatchKeyValue(entity, "effect_name", particle);
    DispatchKeyValue(entity, "start_active", "1");
    DispatchSpawn(entity);

    SetVariantString("!activator");
    AcceptEntityInput(entity, "SetParent", target);

    if (attachment[0] != 0)
    {
        SetVariantString(attachment);
        AcceptEntityInput(entity, "SetParentAttachment");
    }

    TeleportEntity(entity, vPos, vAng, NULL_VECTOR);

    if (IsValidClientIndex(target))
    {
        SetEdictAlways(entity);
        SDKHook(entity, SDKHook_SetTransmit, OnSetTransmit);
    }

    // Fix particles disappearing
    if (g_bCvar_Interval)
    {
        SetVariantString(g_sStopInput);
        AcceptEntityInput(entity, "AddOutput");
        SetVariantString(g_sFireUser2Input);
        AcceptEntityInput(entity, "AddOutput");
        AcceptEntityInput(entity, "FireUser1");

        SetVariantString("OnUser2 !self:Start::0:-1");
        AcceptEntityInput(entity, "AddOutput");
        SetVariantString("OnUser2 !self:FireUser1::0:-1");
        AcceptEntityInput(entity, "AddOutput");
    }

    return entity;
}

/****************************************************************************************************/

Action OnSetTransmit(int entity, int client)
{
    SetEdictAlways(entity);

    if (IsFakeClient(client))
        return Plugin_Handled;

    int owner = ge_iOwner[entity];

    if (GetEntProp(client, Prop_Send, "m_iObserverMode") == SPECMODE_FIRSTPERSON)
    {
        if (GetEntPropEnt(client, Prop_Send, "m_hObserverTarget") == owner)
            return Plugin_Handled;
        else
            return Plugin_Continue;
    }

    if (client != owner)
        return Plugin_Continue;

    if (gc_bThirdPerson[owner])
        return Plugin_Continue;

    return Plugin_Handled;
}

/****************************************************************************************************/

void SetEdictAlways(int edict)
{
    if (GetEdictFlags(edict) & FL_EDICT_ALWAYS)
        SetEdictFlags(edict, (GetEdictFlags(edict) ^ FL_EDICT_ALWAYS));
}

// ====================================================================================================
// Menus
// ====================================================================================================
void CreateEyesMenu(int client)
{
    Menu menu = new Menu(HandleEyesMenu);
    menu.SetTitle("%T", "Select an eye option", client);

    menu.AddItem("3", Translate(client, "%t", "Both eyes"));
    menu.AddItem("1", Translate(client, "%t", "Left eye"));
    menu.AddItem("2", Translate(client, "%t", "Right eye"));

    menu.Display(client, MENU_TIME_FOREVER);
}

/****************************************************************************************************/

int HandleEyesMenu(Menu menu, MenuAction action, int param1, int param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            int client = param1;

            char eyes[2];
            menu.GetItem(param2, eyes, sizeof(eyes));

            gc_iEyeOption[client] = StringToInt(eyes);

            CreateParticleMenu(client);
        }
        case MenuAction_End:
        {
            delete menu;
        }
    }

    return 0;
}

/****************************************************************************************************/

void CreateParticleMenu(int client)
{
    CreateCamera(client);

    Menu menu = new Menu(HandleParticleMenu);
    menu.SetTitle("%T", "Select a particle", client);
    menu.ExitBackButton = true;

    char text[32];
    int clientParticle;

    switch (gc_iEyeOption[client])
    {
        case EYE_BOTH:
        {
            if (gc_iLeftEyeParticle[client] ==  gc_iRightEyeParticle[client])
                clientParticle = gc_iLeftEyeParticle[client];
            else
                clientParticle = -1;
        }
        case EYE_LEFT: clientParticle = gc_iLeftEyeParticle[client];
        case EYE_RIGHT: clientParticle = gc_iRightEyeParticle[client];
    }

    FormatEx(text, sizeof(text), "%s %s", clientParticle == 1 ? "☑" : "☐", Translate(client, "%t", "Particle 1"));
    menu.AddItem("1", text);

    FormatEx(text, sizeof(text), "%s %s", clientParticle == 2 ? "☑" : "☐", Translate(client, "%t", "Particle 2"));
    menu.AddItem("2", text);

    FormatEx(text, sizeof(text), "%s %s", clientParticle == 3 ? "☑" : "☐", Translate(client, "%t", "Particle 3"));
    menu.AddItem("3", text);

    FormatEx(text, sizeof(text), "%s %s", clientParticle == 0 ? "☑" : "☐", Translate(client, "%t", "Particle 0"));
    menu.AddItem("0", text);

    menu.Display(client, MENU_TIME_FOREVER);
}

/****************************************************************************************************/

int HandleParticleMenu(Menu menu, MenuAction action, int param1, int param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            int client = param1;

            char sArgs[3];
            menu.GetItem(param2, sArgs, sizeof(sArgs));

            int particle = StringToInt(sArgs);

            if (gc_iEyeOption[client] & EYE_LEFT)
            {
                g_csLeftEyeParticle.Set(client, sArgs);
                gc_iLeftEyeParticle[client] = particle;

                CreateEyeParticle(client, EYE_LEFT, TYPE_CLIENT);
            }

            if (gc_iEyeOption[client] & EYE_RIGHT)
            {
                g_csRightEyeParticle.Set(client, sArgs);
                gc_iRightEyeParticle[client] = particle;

                CreateEyeParticle(client, EYE_RIGHT, TYPE_CLIENT);
            }

            CreateParticleMenu(client);
        }
        case MenuAction_Cancel:
        {
            int client = param1;

            if (param2 == MenuCancel_ExitBack)
                CreateEyesMenu(client);
        }
        case MenuAction_End:
        {
            delete menu;
        }
    }

    return 0;
}

/****************************************************************************************************/

void CreateCamera(int client)
{
    if (!g_bCvar_SelfieFOV)
        return;

    gc_bThirdPerson[client] = true;

    int entity;
    if (gc_iCameraEntRef[client] != INVALID_ENT_REFERENCE)
    {
        entity = EntRefToEntIndex(gc_iCameraEntRef[client]);

        if (entity != INVALID_ENT_REFERENCE)
        {
            AcceptEntityInput(entity, "Disable");
            AcceptEntityInput(entity, "Kill");
        }

        gc_iCameraEntRef[client] = INVALID_ENT_REFERENCE;
    }
    else
    {
        float vAng[3];
        GetClientEyeAngles(client, vAng);
        vAng[0] = 0.0;
        vAng[2] = 0.0;

        TeleportEntity(client, NULL_VECTOR, vAng, NULL_VECTOR);
    }

    entity = CreateEntityByName("point_viewcontrol");
    gc_iCameraEntRef[client] = EntIndexToEntRef(entity);
    DispatchKeyValue(entity, "targetname", "l4d_survivor_eyes");
    DispatchSpawn(entity);

    AcceptEntityInput(entity, "Enable", client);
}

/****************************************************************************************************/

public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2])
{
    if (!IsValidClientIndex(client))
        return;

    if (gc_iCameraEntRef[client] == INVALID_ENT_REFERENCE)
        return;

    if (buttons == 0)
    {
        if (!g_bCvar_SelfieFOV)
            return;

        if (gc_iCameraEntRef[client] != INVALID_ENT_REFERENCE)
        {
            int entity = EntRefToEntIndex(gc_iCameraEntRef[client]);

            if (entity != INVALID_ENT_REFERENCE)
            {
                float vPos[3];
                GetClientEyePosition(client, vPos);

                float vDir[3];
                GetClientEyeAngles(client, vDir);

                float vAng[3];
                GetAngleVectors(vDir, vAng, NULL_VECTOR, NULL_VECTOR);
                NormalizeVector(vAng, vAng);

                vPos[0] += (vAng[0] * g_iCvar_SelfieFOV);
                vPos[1] += (vAng[1] * g_iCvar_SelfieFOV);
                vPos[2] += (vAng[2] * g_iCvar_SelfieFOV);

                vDir[0] *= -1.0;
                vDir[1] += 180.0;
                vDir[2] = 0.0;

                TeleportEntity(entity, vPos, vDir, NULL_VECTOR);
            }
        }
    }
    else
    {
        int entity = EntRefToEntIndex(gc_iCameraEntRef[client]);

        if (entity != INVALID_ENT_REFERENCE)
        {
            AcceptEntityInput(entity, "Disable");
            AcceptEntityInput(entity, "Kill");
            gc_bThirdPerson[client] = false;
        }

        gc_iCameraEntRef[client] = INVALID_ENT_REFERENCE;
    }
}

/****************************************************************************************************/

int GetCharacterNumber(int client)
{
    int team = GetClientTeam(client);

    if (g_bL4D2)
    {
        switch (team)
        {
            case TEAM_SURVIVOR, TEAM_HOLDOUT:
            {
                char modelname[PLATFORM_MAX_PATH];
                GetEntPropString(client, Prop_Data, "m_ModelName", modelname, sizeof(modelname));

                switch (CharToLower(modelname[29]))
                {
                    case 'v': return CHAR_BILL;
                    case 'n': return CHAR_ZOEY;
                    case 'e': return CHAR_FRANCIS;
                    case 'a': return CHAR_LOUIS;
                    case 'b': return CHAR_NICK;
                    case 'd': return CHAR_ROCHELLE;
                    case 'c': return CHAR_COACH;
                    case 'h': return CHAR_ELLIS;
                }
            }
            case TEAM_INFECTED:
            {
                int zombieClass = GetZombieClass(client);

                switch (zombieClass)
                {
                    case L4D2_ZOMBIECLASS_SMOKER:
                    {
                        gc_iLeftEyeParticle[client] = g_iCvar_SmokerLeftParticle;
                        gc_iRightEyeParticle[client] = g_iCvar_SmokerRightParticle;
                        return CHAR_SMOKER;
                    }
                    case L4D2_ZOMBIECLASS_BOOMER:
                    {
                        gc_iLeftEyeParticle[client] = g_iCvar_BoomerLeftParticle;
                        gc_iRightEyeParticle[client] = g_iCvar_BoomerRightParticle;

                        char modelname[PLATFORM_MAX_PATH];
                        GetEntPropString(client, Prop_Data, "m_ModelName", modelname, sizeof(modelname));

                        switch (CharToLower(modelname[22]))
                        {
                            case '.': return CHAR_BOOMER;
                            case 't': return CHAR_BOOMETTE;
                            case '_': return CHAR_BOOMER_L4D1;
                        }

                        return CHAR_UNKNOWN;
                    }
                    case L4D2_ZOMBIECLASS_HUNTER:
                    {
                        gc_iLeftEyeParticle[client] = g_iCvar_HunterLeftParticle;
                        gc_iRightEyeParticle[client] = g_iCvar_HunterRightParticle;
                        return CHAR_HUNTER;
                    }
                    case L4D2_ZOMBIECLASS_SPITTER:
                    {
                        gc_iLeftEyeParticle[client] = g_iCvar_SpitterLeftParticle;
                        gc_iRightEyeParticle[client] = g_iCvar_SpitterRightParticle;
                        return CHAR_SPITTER;
                    }
                    case L4D2_ZOMBIECLASS_JOCKEY:
                    {
                        gc_iLeftEyeParticle[client] = g_iCvar_JockeyLeftParticle;
                        gc_iRightEyeParticle[client] = g_iCvar_JockeyRightParticle;
                        return CHAR_JOCKEY;
                    }
                    case L4D2_ZOMBIECLASS_CHARGER:
                    {
                        gc_iLeftEyeParticle[client] = g_iCvar_ChargerLeftParticle;
                        gc_iRightEyeParticle[client] = g_iCvar_ChargerRightParticle;
                        return CHAR_CHARGER;
                    }
                    case L4D2_ZOMBIECLASS_TANK:
                    {
                        gc_iLeftEyeParticle[client] = g_iCvar_TankLeftParticle;
                        gc_iRightEyeParticle[client] = g_iCvar_TankRightParticle;
                        return CHAR_TANK;
                    }
                }
            }
        }
    }
    else
    {
        switch (team)
        {
            case TEAM_SURVIVOR, TEAM_HOLDOUT:
            {
                char modelname[PLATFORM_MAX_PATH];
                GetEntPropString(client, Prop_Data, "m_ModelName", modelname, sizeof(modelname));

                switch (CharToLower(modelname[29]))
                {
                    case 'v': return CHAR_BILL;
                    case 'n': return CHAR_ZOEY;
                    case 'e': return CHAR_FRANCIS;
                    case 'a': return CHAR_LOUIS;
                }
            }
            case TEAM_INFECTED:
            {
                int zombieClass = GetZombieClass(client);

                switch (zombieClass)
                {
                    case L4D1_ZOMBIECLASS_SMOKER:
                    {
                        gc_iLeftEyeParticle[client] = g_iCvar_SmokerLeftParticle;
                        gc_iRightEyeParticle[client] = g_iCvar_SmokerRightParticle;
                        return CHAR_SMOKER;
                    }
                    case L4D1_ZOMBIECLASS_BOOMER:
                    {
                        gc_iLeftEyeParticle[client] = g_iCvar_BoomerLeftParticle;
                        gc_iRightEyeParticle[client] = g_iCvar_BoomerRightParticle;
                        return CHAR_BOOMER;
                    }
                    case L4D1_ZOMBIECLASS_HUNTER:
                    {
                        //Not supported
                        return CHAR_UNKNOWN;
                    }
                    case L4D1_ZOMBIECLASS_TANK:
                    {
                        gc_iLeftEyeParticle[client] = g_iCvar_TankLeftParticle;
                        gc_iRightEyeParticle[client] = g_iCvar_TankRightParticle;
                        return CHAR_TANK;
                    }
                }
            }
        }
    }

    return CHAR_UNKNOWN;
}

// ====================================================================================================
// Commands
// ====================================================================================================
Action CmdEyes(int client, int args)
{
    if (!g_bCvar_Enabled)
        return Plugin_Handled;

    if (!IsValidClient(client))
        return Plugin_Handled;

    CreateEyesMenu(client);

    return Plugin_Handled;
}

// ====================================================================================================
// Admin Commands
// ====================================================================================================
Action CmdEyesClient(int client, int args)
{
    if (!IsValidClient(client))
        return Plugin_Handled;

    if (args < 3)
    {
        ReplyToCommand(client, "[SM] Usage: sm_eyesclient [target] [pos:1=left|2=right|3=both] [particle:0=none|1=witch|2=pipebomb|3=fire]");
        return Plugin_Handled;
    }

    char arg1[MAX_TARGET_LENGTH];
    GetCmdArg(1, arg1, sizeof(arg1));

    char arg2[2];
    GetCmdArg(2, arg2, sizeof(arg2));
    int pos = StringToInt(arg2);

    char arg3[2];
    GetCmdArg(3, arg3, sizeof(arg3));
    int particle = StringToInt(arg3);

    char target_name[MAX_TARGET_LENGTH];
    int target_list[MAXPLAYERS], target_count;
    bool tn_is_ml;

    if ((target_count = ProcessTargetString(
        arg1,
        client,
        target_list,
        MAXPLAYERS,
        COMMAND_FILTER_ALIVE,
        target_name,
        sizeof(target_name),
        tn_is_ml)) <= 0)
    {
        ReplyToTargetError(client, target_count);
        return Plugin_Handled;
    }

    int target;
    for (int i = 0; i < target_count; i++)
    {
        target = target_list[i];

        int team = GetClientTeam(target);

        if (team != TEAM_SURVIVOR && team != TEAM_HOLDOUT)
            continue;

        switch (pos)
        {
            case EYE_LEFT:
            {
                gc_iLeftEyeParticle[target] = particle;
                CreateEyeParticle(target, EYE_LEFT, TYPE_CLIENT);
            }
            case EYE_RIGHT:
            {
                gc_iRightEyeParticle[target] = particle;
                CreateEyeParticle(target, EYE_RIGHT, TYPE_CLIENT);
            }
            case EYE_BOTH:
            {
                gc_iLeftEyeParticle[target] = particle;
                gc_iRightEyeParticle[target] = particle;

                CreateEyeParticle(target, EYE_LEFT, TYPE_CLIENT);
                CreateEyeParticle(target, EYE_RIGHT, TYPE_CLIENT);
            }
        }

        PrintToChat(client, "\x04[EYES]\x05 Attached to \x03%N", target);
    }

    return Plugin_Handled;
}

/****************************************************************************************************/

Action CmdPrintCvars(int client, int args)
{
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");
    PrintToConsole(client, "------------------ Plugin Cvars (l4d_survivor_eyes) ------------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "l4d_survivor_eyes_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "l4d_survivor_eyes_enable : %b (%s)", g_bCvar_Enabled, g_bCvar_Enabled ? "true" : "false");
    PrintToConsole(client, "l4d_survivor_eyes_cookies : %b (%s)", g_bCvar_Cookies, g_bCvar_Cookies ? "true" : "false");
    PrintToConsole(client, "l4d_survivor_eyes_detect : %.1f (%s)", g_fCvar_Detect, g_bCvar_Detect ? "true" : "false");
    PrintToConsole(client, "l4d_survivor_eyes_detect_model : %.1f (%s)", g_fCvar_DetectModel, g_bCvar_DetectModel ? "true" : "false");
    PrintToConsole(client, "l4d_survivor_eyes_interval : %.1f (%s)", g_fCvar_Interval, g_bCvar_Interval ? "true" : "false");
    PrintToConsole(client, "l4d_survivor_eyes_selfie_fov : %i (%s)", g_iCvar_SelfieFOV, g_bCvar_SelfieFOV ? "true" : "false");
    PrintToConsole(client, "l4d_survivor_eyes_left_particle : %i (%s)", g_iCvar_SurvivorLeftParticle, g_sParticlesNames[g_iCvar_SurvivorLeftParticle]);
    PrintToConsole(client, "l4d_survivor_eyes_right_particle : %i (%s)", g_iCvar_SurvivorRightParticle, g_sParticlesNames[g_iCvar_SurvivorRightParticle]);
    PrintToConsole(client, "l4d_survivor_eyes_smoker_left_particle : %i (%s)", g_iCvar_SmokerLeftParticle, g_sParticlesNames[g_iCvar_SmokerLeftParticle]);
    PrintToConsole(client, "l4d_survivor_eyes_smoker_right_particle : %i (%s)", g_iCvar_SmokerRightParticle, g_sParticlesNames[g_iCvar_SmokerLeftParticle]);
    PrintToConsole(client, "l4d_survivor_eyes_boomer_left_particle : %i (%s)", g_iCvar_BoomerRightParticle, g_sParticlesNames[g_iCvar_BoomerLeftParticle]);
    PrintToConsole(client, "l4d_survivor_eyes_smoker_right_particle : %i (%s)", g_iCvar_BoomerRightParticle, g_sParticlesNames[g_iCvar_BoomerLeftParticle]);
    if (g_bL4D2)
    {
        PrintToConsole(client, "l4d_survivor_eyes_hunter_left_particle : %i (%s)", g_iCvar_HunterLeftParticle, g_sParticlesNames[g_iCvar_HunterLeftParticle]);
        PrintToConsole(client, "l4d_survivor_eyes_hunter_right_particle : %i (%s)", g_iCvar_HunterRightParticle, g_sParticlesNames[g_iCvar_HunterRightParticle]);
        PrintToConsole(client, "l4d_survivor_eyes_spitter_left_particle : %i (%s)", g_iCvar_SpitterLeftParticle, g_sParticlesNames[g_iCvar_SpitterLeftParticle]);
        PrintToConsole(client, "l4d_survivor_eyes_spitter_right_particle : %i (%s)", g_iCvar_SpitterRightParticle, g_sParticlesNames[g_iCvar_SpitterRightParticle]);
        PrintToConsole(client, "l4d_survivor_eyes_jockey_left_particle : %i (%s)", g_iCvar_JockeyLeftParticle, g_sParticlesNames[g_iCvar_JockeyLeftParticle]);
        PrintToConsole(client, "l4d_survivor_eyes_jockey_right_particle : %i (%s)", g_iCvar_JockeyRightParticle, g_sParticlesNames[g_iCvar_JockeyRightParticle]);
        PrintToConsole(client, "l4d_survivor_eyes_charger_left_particle : %i (%s)", g_iCvar_ChargerLeftParticle, g_sParticlesNames[g_iCvar_ChargerLeftParticle]);
        PrintToConsole(client, "l4d_survivor_eyes_charger_right_particle : %i (%s)", g_iCvar_ChargerRightParticle, g_sParticlesNames[g_iCvar_ChargerRightParticle]);
    }
    PrintToConsole(client, "l4d_survivor_eyes_tank_left_particle : %i (%s)", g_iCvar_TankLeftParticle, g_sParticlesNames[g_iCvar_TankLeftParticle]);
    PrintToConsole(client, "l4d_survivor_eyes_tank_right_particle : %i (%s)", g_iCvar_TankRightParticle, g_sParticlesNames[g_iCvar_TankRightParticle]);
    PrintToConsole(client, "l4d_survivor_eyes_common_left_particle : %i (%s)", g_iCvar_CommonLeftParticle, g_sParticlesNames[g_iCvar_CommonLeftParticle]);
    PrintToConsole(client, "l4d_survivor_eyes_common_right_particle : %i (%s)", g_iCvar_CommonRightParticle, g_sParticlesNames[g_iCvar_CommonRightParticle]);
    PrintToConsole(client, "l4d_survivor_eyes_witch_left_particle : %i (%s)", g_iCvar_WitchLeftParticle, g_sParticlesNames[g_iCvar_WitchLeftParticle]);
    PrintToConsole(client, "l4d_survivor_eyes_witch_right_particle : %i (%s)", g_iCvar_WitchRightParticle, g_sParticlesNames[g_iCvar_WitchRightParticle]);
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");

    return Plugin_Handled;
}

// ====================================================================================================
// Helpers
// ====================================================================================================
/**
 * Validates if is a valid client index.
 *
 * @param client        Client index.
 * @return              True if client index is valid, false otherwise.
 */
bool IsValidClientIndex(int client)
{
    return (1 <= client <= MaxClients);
}

/****************************************************************************************************/

/**
 * Validates if is a valid client.
 *
 * @param client        Client index.
 * @return              True if client index is valid and client is in game, false otherwise.
 */
bool IsValidClient(int client)
{
    return (IsValidClientIndex(client) && IsClientInGame(client));
}

/****************************************************************************************************/

/**
 * Gets the client L4D1/L4D2 zombie class id.
 *
 * @param client        Client index.
 * @return L4D1         1=SMOKER, 2=BOOMER, 3=HUNTER, 4=WITCH, 5=TANK, 6=NOT INFECTED
 * @return L4D2         1=SMOKER, 2=BOOMER, 3=HUNTER, 4=SPITTER, 5=JOCKEY, 6=CHARGER, 7=WITCH, 8=TANK, 9=NOT INFECTED
 */
int GetZombieClass(int client)
{
    return (GetEntProp(client, Prop_Send, "m_zombieClass"));
}

/****************************************************************************************************/

/**
 * Precaches a particle.
 *
 * @param particle      Particle name.
 */
int tableParticleEffectNames = INVALID_STRING_TABLE;
void PrecacheParticle(const char[] particle)
{
    if (tableParticleEffectNames == INVALID_STRING_TABLE)
        tableParticleEffectNames = FindStringTable("ParticleEffectNames");

    if (FindStringIndex(tableParticleEffectNames, particle) == INVALID_STRING_INDEX)
    {
        bool save = LockStringTables(false);
        AddToStringTable(tableParticleEffectNames, particle);
        LockStringTables(save);
    }
}

/****************************************************************************************************/

/**
 * Convert string to its translated value.
 *
 * @param  client          Client index. Translation based on this client index.
 * @param message          Message (formatting rules). Must have a "%t" specifier.
 * @return char[512]       Resulting string.
 */
char[] Translate(int client, const char[] message, any ...)
{
    char buffer[512];
    SetGlobalTransTarget(client);
    VFormat(buffer, sizeof(buffer), message, 3);
    return buffer;
}

/****************************************************************************************************/

bool IsSurvivorThirdPerson(int client)
{
    if (g_bL4D2)
        return IsSurvivorThirdPersonL4D2(client);
    else
        return IsSurvivorThirdPersonL4D1(client);
}

/****************************************************************************************************/

bool IsSurvivorThirdPersonL4D2(int client)
{
    if (IsFakeClient(client))
        return false;

    if (GetEntProp(client, Prop_Send, "m_isHangingFromLedge") == 1)
        return true;
    if (GetEntPropEnt(client, Prop_Send, "m_hViewEntity") != -1)
        return true;
    if (GetEntPropEnt(client, Prop_Send, "m_pounceAttacker") != -1)
        return true;
    if (GetEntPropEnt(client, Prop_Send, "m_reviveTarget") != -1)
        return true;
    if (GetEntPropFloat(client, Prop_Send, "m_staggerTimer", 1) > GetGameTime())
        return true;
    if (GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker") != -1)
        return true;
    if (GetEntPropEnt(client, Prop_Send, "m_pummelAttacker") != -1)
        return true;
    if (GetEntPropEnt(client, Prop_Send, "m_carryAttacker") != -1)
        return true;
    if (GetEntPropFloat(client, Prop_Send, "m_TimeForceExternalView") > GetGameTime())
        return true;

    switch (GetEntProp(client, Prop_Send, "m_iCurrentUseAction"))
    {
        case 1:
        {
            int target = GetEntPropEnt(client, Prop_Send, "m_useActionTarget");

            if (target == GetEntPropEnt(client, Prop_Send, "m_useActionOwner"))
                return true;
            else if (target != client)
                return true;
        }
        case 4, 5, 6, 7, 8, 9, 10:
            return true;
    }
    return false;
}

/****************************************************************************************************/

bool IsSurvivorThirdPersonL4D1(int client)
{
    if (IsFakeClient(client))
        return false;

    if (GetEntProp(client, Prop_Send, "m_isHangingFromLedge") == 1)
        return true;
    if (GetEntPropEnt(client, Prop_Send, "m_hViewEntity") != -1)
        return true;
    if (GetEntPropEnt(client, Prop_Send, "m_pounceAttacker") != -1)
        return true;
    if (GetEntPropEnt(client, Prop_Send, "m_reviveTarget") != -1)
        return true;
    if (GetEntPropEnt(client, Prop_Send, "m_healTarget") != -1)
        return true;
    if (GetEntPropFloat(client, Prop_Send, "m_staggerTimer", 1) > GetGameTime())
        return true;

    return false;
}