/*
*
*	Hangman by RedSMURF
*
*
*	Description:
*
*	Cvars:
*		None
*
*	Commands:
*       say /hangman [name]             "Opens the Hangman menu or hangs the specified player."
*       say_team /hangman [name]        "Opens the Hangman menu or hangs the specified player."
*       hangman_reload                  "Reloads the configuration file."
*
*	Changelog:
*       v1.0: Initial release.
*
*/

#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <engine>
#include <fakemeta>
#include <fun>
#include <hamsandwich>
#include <xs>

#if !defined MAX_PLAYERS
    #define MAX_PLAYERS 32
#endif

#if !defined MAX_VALUE_LENGTH
    #define MAX_VALUE_LENGTH 64
#endif

#if !defined MAX_RESOURCE_PATH_LENGTH
    #define MAX_RESOURCE_PATH_LENGTH 128
#endif

#if !defined MAX_FILE_CELL_SIZE
    #define MAX_FILE_CELL_SIZE 192
#endif

#if !defined MAX_PLATFORM_PATH_LENGTH
    #define MAX_PLATFORM_PATH_LENGTH 256
#endif

#define MAX_ENT                         32
#define ADMIN_ACCESS                    ADMIN_RCON
#define PDATA_NEXT_ATTACK               83
#define XO_CBASEPLAYER                  5
#define XO_CBASEPLAYERWEAPON            4
#define CORPSEGORE_KEY                  981222
#define HANGMAN_KEY                     658812
#define HANGMAN_ARRAY_ITEM              pev_iuser1
#define HANGMAN_OWNER                   pev_iuser2
#define HANG_BONE                       6
#define SEQ                             105
#define SEQ_FRAME                       50.0
#define SEQ_FRAME_NUM                   54.0
#define CORPSE_PITCH_OFFSET             90.0
#define CORPSE_YAW_OFFSET               90.0
#define VIEW_FORWARD_OFFSET             192.0
#define VIEW_RIGHT_OFFSET               64.0
#define VIEW_UP_OFFSET                  32.0
#define CORPSE_HALF_WIDTH               15.0
#define CORPSE_UP                       2.0
#define CORPSE_DOWN                     72.0
#define SOUND_NAV                       "buttons/blip1.wav"
#define SOUND_REMOVE                    "buttons/button10.wav"
#define SOUND_ALERT                     "buttons/bell1.wav"

new const PLUGIN_VERSION[]          = "1.0"
new const Float:DELAY_ON_LOAD       = 2.0
new const ERROR_FILE[]              = "Hangman_ERRORS.log"

enum
{
    SECTION_NONE,
    SECTION_MAIN_SETTINGS,
    SECTION_HANGMAN
}

enum
{
    DTYPE_INT,
    DTYPE_FLOAT,
    DTYPE_FLAGS,
    DTYPE_ARRAY_STRING,
    DTYPE_ARRAY_SOUND,
    DTYPE_STRING_MODEL,
    DTYPE_STRING_SOUND,
    DTYPE_STRING_MODEL_ID
}

enum
{
    FLAG_SHOW               = (1 << 0),
    FLAG_GHOST              = (1 << 1),
    FLAG_GROUND             = (1 << 2),
    FLAG_ACTIVE             = (1 << 3),
    FLAG_USED               = (1 << 4)
}

enum
{
    TEAM_NONE,
    TEAM_T,
    TEAM_CT,
    TEAM_BOTH
}

enum
{
    TARGET_GHOST,
    TARGET_SELECT,
    TARGET_HIDE,
    TARGET_CLEAR
}

enum _:MAIN_SETTINGS
{
    SETTING_DEFAULT_MODEL[MAX_RESOURCE_PATH_LENGTH],
    Array:SETTING_DEFAULT_SOUND,
    Array:SETTING_DEFAULT_MESSAGE,
    Array:SETTING_DEFAULT_MESSAGE_FORCED,
    SETTING_DEFAULT_FLAGS,
    SETTING_DEFAULT_TEAM,
    SETTING_DEFAULT_HOLD_DURATION[2],
    Float:SETTING_DEFAULT_COOLDOWN[2],
    bool:SETTING_CORPSE_CAN_GIB,
    bool:SETTING_PLAY_SOUND_ON_DEATH,
    bool:SETTING_WRITE_MESSAGE_ON_DEATH,

    Float:SETTING_HUD_X,
    Float:SETTING_HUD_Y,
    SETTING_HUD_COLOR[3],
    SETTING_HUD_EFFECT,
    Float:SETTING_HUD_FXTIME,
    Float:SETTING_HUD_HOLDTIME,
    Float:SETTING_HUD_FADEIN,
    Float:SETTING_HUD_FADEOUT,

    Float:SETTING_MINS[3],
    Float:SETTING_MAXS[3],

    bool:SETTING_HANGMAN_LOAD,
    Float:SETTING_HANGMAN_CHECK,
    Float:SETTING_HANGMAN_TASK,
    Float:SETTING_OFFSET_BASE,
    Float:SETTING_OFFSET[2],
    Float:SETTING_OFFSET_STEP,
    SETTING_GHOST_ALPHA,
    Float:SETTING_ROTATION_STEP
}

enum _:HANGMAN
{
    HANGMAN_ID,
    HANGMAN_ITEM,
    HANGMAN_FLAGS,
    HANGMAN_TEAM,
    HANGMAN_CORPSE,
    HANGMAN_NAME[MAX_VALUE_LENGTH],
    HANGMAN_MODEL[MAX_RESOURCE_PATH_LENGTH],
    Float:HANGMAN_COOLDOWN[2],

    Float:HANGMAN_ORIGIN[3],
    Float:HANGMAN_ANGLES[3],
    Float:HANGMAN_ORIGIN_VIEW[3],
    Float:HANGMAN_ANGLES_VIEW[3],
    Float:HANGMAN_MINS[3],
    Float:HANGMAN_MAXS[3],

    Float:HANGMAN_NEXT_ACTIVE
}

enum _:PLAYER_DATA
{
    PDATA_HANGMAN_GHOST,
    PDATA_HANGMAN_MENU,
    bool:PDATA_HANGMAN_ACTION,
    PDATA_HANGMAN_ID,
    Float:PDATA_OFFSET,
    Float:PDATA_NEXT_OFFSET,

    PDATA_MENU_TYPE,
    bool:PDATA_MENU_TRACE,

    Float:PDATA_NEXT_HANG,
    Float:PDATA_NEXT_CHECK
}

enum
{
    SOUND_MENU_NAV,
    SOUND_MENU_REMOVE,
    SOUND_MENU_ALERT,
    SOUND_HANGMAN
}

enum
{
    MENU_ROOT,
    MENU_CREATE,
    MENU_EDIT,
    MENU_REMOVE,
    MENU_SHOW,
    MENU_STATUS,
    MENU_ROTATE
}

enum
{
    ROOT_CREATE,
    ROOT_EDIT,
    ROOT_REMOVE,
    ROOT_SAVE,

    ROOT_NOCLIP = 5,
    ROOT_GODMODE
}

enum
{
    EDIT_SHOW,
    EDIT_STATUS
}

enum
{
    REMOVE_NEXT,
    REMOVE_BACK,

    REMOVE_CURRENT = 3,
    REMOVE_ALL
}

enum
{
    SHOW_NEXT,
    SHOW_BACK,

    SHOW_CURRENT = 3,
    SHOW_ALL_SHOW,
    SHOW_ALL_HIDE
}

enum
{
    STATUS_NEXT,
    STATUS_BACK,

    STATUS_CURRENT = 3,
    STATUS_ALL_ENABLE,
    STATUS_ALL_DISABLE
}

enum
{
    ROTATE_UP,
    ROTATE_DOWN,

    ROTATE_GROUND = 3,
    ROTATE_PLACE
}

new Float:g_fDirections[][] =
{
    {-1.0, 0.0, 0.0},
    {1.0, 0.0, 0.0},
    {0.0, -1.0, 0.0},
    {0.0, 1.0, 0.0},
    {0.0, 0.0, -1.0},
    {0.0, 0.0, 1.0}
}

new g_szMenuHandler[][MAX_VALUE_LENGTH] =
{
    "menuHandlerRoot",
    "menuHandlerCreate",
    "menuHandlerEdit",
    "menuHandlerRemove",
    "menuHandlerShow",
    "menuHandlerStatus",
    "menuHandlerRotate"
}

new g_szCN[] = "hangman"

new Array:g_aHangman,
    Array:g_aHangmanConfig,
    g_eSettings[MAIN_SETTINGS],
    g_ePlayerData[MAX_PLAYERS + 1][PLAYER_DATA],
    bool:g_bFileWasRead, g_iActivePlayers,
    g_iFwdEmitSound, HamHook:g_iFwdUse, HamHook:g_iFwdObjectCaps, HamHook:g_iFwdPreThink,
    g_iHangman, g_iHangmanConfig, g_iBarTime, Float:g_iHudCurrentY,
    g_iMaxPlayers, g_iSilentVictim

new const g_iColorActive[] = { 0, 255, 0 }
new const g_iColorInactive[] = { 255, 0, 0 }
new Float:g_fHangOffset[] = { -59.75, -1.0, -94.0 }
native Float:corpsegore_get_corpse_health()

public plugin_init()
{
    register_plugin("Hangman", PLUGIN_VERSION, "RedSMURF")
    register_cvar("RedSMURF_Hangman", PLUGIN_VERSION, ADMIN_ACCESS)

    register_clcmd("say /hangman",       "cmdMenu", ADMIN_ACCESS, "-- Opens the Hangman menu.")
    register_clcmd("say_team /hangman",  "cmdMenu", ADMIN_ACCESS, "-- Opens the Hangman menu.")
    register_concmd("hangman_reload",  "cmdReload", ADMIN_ACCESS, "-- Reloads the configuration file")
    register_dictionary("Hangman.txt")

    g_iFwdEmitSound = register_forward(FM_EmitSound, "fwdEmitSound")
    g_iFwdUse = RegisterHam(Ham_Use, "info_target", "fwdUse")
    g_iFwdObjectCaps = RegisterHam(Ham_ObjectCaps, "info_target", "fwdObjectCaps")
    g_iFwdPreThink = RegisterHam(Ham_Player_PreThink, "player", "fwdPreThink")
    RegisterHam(Ham_Killed, "player", "fwdKilled", 1)
    g_iBarTime = get_user_msgid("BarTime")
    register_logevent("eventRoundStart", 2, "1=Round_Start")
    DisableForward()
    DisableHangman()

    hangmanInit()
    g_iMaxPlayers = get_maxplayers()
}

public plugin_precache()
{
    g_aHangman = ArrayCreate(HANGMAN)
    g_aHangmanConfig = ArrayCreate(HANGMAN)
    g_eSettings[SETTING_DEFAULT_SOUND] = ArrayCreate(MAX_RESOURCE_PATH_LENGTH)
    g_eSettings[SETTING_DEFAULT_MESSAGE] = ArrayCreate(MAX_RESOURCE_PATH_LENGTH)
    g_eSettings[SETTING_DEFAULT_MESSAGE_FORCED] = ArrayCreate(MAX_RESOURCE_PATH_LENGTH)

    ReadFile()
}

public plugin_end()
{
    ArrayDestroy(g_aHangman)
    ArrayDestroy(g_aHangmanConfig)
    ArrayDestroy(g_eSettings[SETTING_DEFAULT_SOUND])
    ArrayDestroy(g_eSettings[SETTING_DEFAULT_MESSAGE])
    ArrayDestroy(g_eSettings[SETTING_DEFAULT_MESSAGE_FORCED])
}

public plugin_natives()
{
    set_native_filter("native_filter")
}

public native_filter(const szName[], iNative, iTrap)
{
    if ( equal(szName, "corpsegore_get_corpse_health") )
        return PLUGIN_HANDLED

    return PLUGIN_CONTINUE
}

public cmdMenu(id, iLevel, iCmd)
{
    if ( !cmd_access(id, iLevel, iCmd, 1) )
        return PLUGIN_HANDLED

    new szTarget[64]
    read_argv(2, szTarget, charsmax(szTarget))
    remove_quotes(szTarget)
    if ( !szTarget[0] )
    {
        hangmanSound(id, SOUND_MENU_NAV)
        hangmanMenu(id, MENU_ROOT)
        return PLUGIN_HANDLED
    }

    new iTarget = cmd_target(id, szTarget, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF)
    if ( !iTarget )
        return PLUGIN_HANDLED   // cmd_target already printed the reason

    if ( !is_user_alive(iTarget) )
    {
        client_print_color(id, id, "%L %L", id, "HANGMAN_CHAT_TAG", id, "HANGMAN_CHAT_NOT_ALIVE")
        return PLUGIN_HANDLED
    }

    new eHangman[HANGMAN], Float:fCurrentTime = get_gametime()
    for ( new iItem = 0; iItem < g_iHangman; iItem++ )
    {
        ArrayGetArray(g_aHangman, iItem, eHangman)

        if ( eHangman[HANGMAN_FLAGS] & FLAG_USED )
            continue

        hangmanHang(eHangman, iTarget, true)
        eHangman[HANGMAN_FLAGS] |= FLAG_USED
        eHangman[HANGMAN_NEXT_ACTIVE] = fCurrentTime + random_float(eHangman[HANGMAN_COOLDOWN][0], eHangman[HANGMAN_COOLDOWN][1])
        ArraySetArray(g_aHangman, iItem, eHangman)
        return PLUGIN_HANDLED
    }

    client_print_color(id, id, "%L %L", id, "HANGMAN_CHAT_TAG", id, "HANGMAN_CHAT_NO_GALLOWS")
    return PLUGIN_HANDLED
}

public cmdReload(id, iLevel, iCmd)
{
    if ( !cmd_access(id, iLevel, iCmd, 1) )
        return PLUGIN_HANDLED

    ReadFile()
    console_print(id, "The configuration file has been reloaded successfully !")

    return PLUGIN_HANDLED
}

public eventRoundStart()
{
    hangmanReset()
}

ReadFile()
{
    if ( g_bFileWasRead )
    {
        ArrayClear(g_aHangmanConfig)
        g_iHangmanConfig = 0
    }

    new szFile[MAX_RESOURCE_PATH_LENGTH], iFile
    get_configsdir(szFile, charsmax(szFile))
    add(szFile, charsmax(szFile), "/Hangman.ini")
    iFile = fopen(szFile, "rt")

    if ( !iFile )
    {
        set_fail_state("An error occured during the opening of the configuration file !")
    }

    new szData[MAX_FILE_CELL_SIZE],
        szKey[MAX_VALUE_LENGTH], szValue[MAX_VALUE_LENGTH],
        eHangman[HANGMAN], iSection = SECTION_NONE, iLine, iPos

    while( !feof(iFile) )
    {
        iLine ++
        fgets(iFile, szData, charsmax(szData))
        trim(szData)

        switch( szData[0] )
        {
            case EOS, ';', '#':
            {
                continue
            }
            case '[':
            {
                if ( szData[strlen(szData) - 1] == ']' )
                {
                    replace(szData, charsmax(szData), "[", "")
                    replace(szData, charsmax(szData), "]", "")
                    trim(szData)

                    if ( equali(szData, "Main Settings") )
                    {
                        iSection = SECTION_MAIN_SETTINGS
                    }
                    else
                    {
                        if ( g_iHangmanConfig )
                            ArrayPushArray(g_aHangmanConfig, eHangman)

                        copy(eHangman[HANGMAN_NAME], charsmax(eHangman[HANGMAN_NAME]), szData)
                        eHangman[HANGMAN_FLAGS]                     = g_eSettings[SETTING_DEFAULT_FLAGS]
                        eHangman[HANGMAN_TEAM]                      = g_eSettings[SETTING_DEFAULT_TEAM]
                        eHangman[HANGMAN_COOLDOWN][0]               = g_eSettings[SETTING_DEFAULT_COOLDOWN][0]
                        eHangman[HANGMAN_COOLDOWN][1]               = g_eSettings[SETTING_DEFAULT_COOLDOWN][1]

                        iSection = SECTION_HANGMAN
                        g_iHangmanConfig ++
                    }
                }
                else
                {
                    LogConfigError(iLine, "Unclosed section name: %s", szData)
                    iSection = SECTION_NONE
                }
            }
            default:
            {
                strtok(szData, szKey, charsmax(szKey), szValue, charsmax(szValue), '=')
                iPos = contain(szValue, "#")
                if ( iPos != -1 )
                    szValue[iPos] = EOS

                trim(szKey)
                trim(szValue)

                switch( iSection )
                {
                    case SECTION_NONE:
                    {
                        LogConfigError(iLine, "Data is not in any defined section: %s", szData)
                    }
                    case SECTION_MAIN_SETTINGS:
                    {
                        if ( equali(szKey, "SETTING_DEFAULT_MODEL") )
                            parseSetting(DTYPE_STRING_MODEL, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_MODEL], charsmax(g_eSettings[SETTING_DEFAULT_MODEL]))
                        else if ( equali(szKey, "SETTING_DEFAULT_SOUND") )
                            parseSetting(DTYPE_ARRAY_SOUND, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_SOUND], charsmax(g_eSettings[SETTING_DEFAULT_SOUND]))
                        else if ( equali(szKey, "SETTING_DEFAULT_MESSAGE") )
                            parseSetting(DTYPE_ARRAY_STRING, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_MESSAGE], charsmax(g_eSettings[SETTING_DEFAULT_MESSAGE]))
                        else if ( equali(szKey, "SETTING_DEFAULT_MESSAGE_FORCED") )
                            parseSetting(DTYPE_ARRAY_STRING, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_MESSAGE_FORCED], charsmax(g_eSettings[SETTING_DEFAULT_MESSAGE_FORCED]))
                        else if ( equali(szKey, "SETTING_DEFAULT_FLAGS") )
                            parseSetting(DTYPE_FLAGS, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_FLAGS], charsmax(g_eSettings[SETTING_DEFAULT_FLAGS]))
                        else if ( equali(szKey, "SETTING_DEFAULT_TEAM") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_TEAM], charsmax(g_eSettings[SETTING_DEFAULT_TEAM]))
                        else if ( equali(szKey, "SETTING_DEFAULT_HOLD_DURATION") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_HOLD_DURATION], charsmax(g_eSettings[SETTING_DEFAULT_HOLD_DURATION]))
                        else if ( equali(szKey, "SETTING_DEFAULT_COOLDOWN") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_COOLDOWN], charsmax(g_eSettings[SETTING_DEFAULT_COOLDOWN]))
                        else if ( equali(szKey, "SETTING_CORPSE_CAN_GIB") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_CORPSE_CAN_GIB], charsmax(g_eSettings[SETTING_CORPSE_CAN_GIB]))
                        else if ( equali(szKey, "SETTING_PLAY_SOUND_ON_DEATH") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_PLAY_SOUND_ON_DEATH], charsmax(g_eSettings[SETTING_PLAY_SOUND_ON_DEATH]))
                        else if ( equali(szKey, "SETTING_WRITE_MESSAGE_ON_DEATH") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_WRITE_MESSAGE_ON_DEATH], charsmax(g_eSettings[SETTING_WRITE_MESSAGE_ON_DEATH]))
                        else if ( equali(szKey, "SETTING_HUD_X") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_HUD_X], charsmax(g_eSettings[SETTING_HUD_X]))
                        else if ( equali(szKey, "SETTING_HUD_Y") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_HUD_Y], charsmax(g_eSettings[SETTING_HUD_Y]))
                        else if ( equali(szKey, "SETTING_HUD_COLOR") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_HUD_COLOR], charsmax(g_eSettings[SETTING_HUD_COLOR]))
                        else if ( equali(szKey, "SETTING_HUD_EFFECT") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_HUD_EFFECT], charsmax(g_eSettings[SETTING_HUD_EFFECT]))
                        else if ( equali(szKey, "SETTING_HUD_FXTIME") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_HUD_FXTIME], charsmax(g_eSettings[SETTING_HUD_FXTIME]))
                        else if ( equali(szKey, "SETTING_HUD_HOLDTIME") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_HUD_HOLDTIME], charsmax(g_eSettings[SETTING_HUD_HOLDTIME]))
                        else if ( equali(szKey, "SETTING_HUD_FADEIN") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_HUD_FADEIN], charsmax(g_eSettings[SETTING_HUD_FADEIN]))
                        else if ( equali(szKey, "SETTING_HUD_FADEOUT") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_HUD_FADEOUT], charsmax(g_eSettings[SETTING_HUD_FADEOUT]))
                        else if ( equali(szKey, "SETTING_MINS") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_MINS], charsmax(g_eSettings[SETTING_MINS]))
                        else if ( equali(szKey, "SETTING_MAXS") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_MAXS], charsmax(g_eSettings[SETTING_MAXS]))
                        else if ( equali(szKey, "SETTING_HANGMAN_LOAD") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_HANGMAN_LOAD], charsmax(g_eSettings[SETTING_HANGMAN_LOAD]))
                        else if ( equali(szKey, "SETTING_HANGMAN_CHECK") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_HANGMAN_CHECK], charsmax(g_eSettings[SETTING_HANGMAN_CHECK]))
                        else if ( equali(szKey, "SETTING_HANGMAN_TASK") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_HANGMAN_TASK], charsmax(g_eSettings[SETTING_HANGMAN_TASK]))
                        else if ( equali(szKey, "SETTING_OFFSET_BASE") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_OFFSET_BASE], charsmax(g_eSettings[SETTING_OFFSET_BASE]))
                        else if ( equali(szKey, "SETTING_OFFSET") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_OFFSET], charsmax(g_eSettings[SETTING_OFFSET]))
                        else if ( equali(szKey, "SETTING_OFFSET_STEP") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_OFFSET_STEP], charsmax(g_eSettings[SETTING_OFFSET_STEP]))
                        else if ( equali(szKey, "SETTING_GHOST_ALPHA") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_GHOST_ALPHA], charsmax(g_eSettings[SETTING_GHOST_ALPHA]))
                        else if ( equali(szKey, "SETTING_ROTATION_STEP") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_ROTATION_STEP], charsmax(g_eSettings[SETTING_ROTATION_STEP]))
                    }
                    case SECTION_HANGMAN:
                    {
                        if ( equali(szKey, "HANGMAN_FLAGS") )
                            parseSetting(DTYPE_FLAGS, szValue, charsmax(szValue), eHangman[HANGMAN_FLAGS], charsmax(eHangman[HANGMAN_FLAGS]))
                        else if ( equali(szKey, "HANGMAN_TEAM") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), eHangman[HANGMAN_TEAM], charsmax(eHangman[HANGMAN_TEAM]))
                        else if ( equali(szKey, "HANGMAN_COOLDOWN") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), eHangman[HANGMAN_COOLDOWN], charsmax(eHangman[HANGMAN_COOLDOWN]))
                    }
                }
            }
        }
    }

    if ( g_iHangmanConfig )
        ArrayPushArray(g_aHangmanConfig, eHangman)
    else
        set_fail_state("No hangmans were found in the configuration file.")

    g_bFileWasRead = true
    fclose(iFile)
}

public client_disconnected(id)
{
    new eHangman[HANGMAN], iItem
    if ( g_ePlayerData[id][PDATA_HANGMAN_GHOST]
    && (iItem = hangmanGet(eHangman, g_ePlayerData[id][PDATA_HANGMAN_GHOST])) != -1 )
    {
        hangmanKill(eHangman[HANGMAN_ID])
        hangmanRemove(iItem)
    }

    DisableAction(id)
    g_ePlayerData[id][PDATA_HANGMAN_GHOST]  = 0
    g_ePlayerData[id][PDATA_HANGMAN_MENU]   = 0
}

stock hangmanInit()
{
    g_iHudCurrentY = g_eSettings[SETTING_HUD_Y]
    if ( g_eSettings[SETTING_HANGMAN_LOAD] )
        set_task(DELAY_ON_LOAD, "loadData")
}

stock hangmanTerminate()
{
    new eHangman[HANGMAN]
    for ( new i = 0; i < g_iHangman; i ++ )
    {
        ArrayGetArray(g_aHangman, i, eHangman)
        eHangman[HANGMAN_FLAGS] &= ~FLAG_USED
        ArraySetArray(g_aHangman, i, eHangman)
    }
}

stock hangmanMenu(id, iType)
{
    if ( !is_user_connected(id) )
        return PLUGIN_HANDLED

    new szData[256], iMenu
    formatex(szData, charsmax(szData), "%L", id, "HANGMAN_MENU_TITLE", PLUGIN_VERSION)
    iMenu = menu_create(szData, g_szMenuHandler[iType])
    switch( iType )
    {
        case MENU_ROOT:             { menuRoot(id, iMenu); }
        case MENU_CREATE:           { menuCreate(iMenu);            format(szData, charsmax(szData), "%s^n%L", szData, id, "HANGMAN_ROOT_CREATE"); }
        case MENU_EDIT:             { menuEdit(id, iMenu);          format(szData, charsmax(szData), "%s^n%L", szData, id, "HANGMAN_ROOT_EDIT"); }
        case MENU_REMOVE:           { menuRemove(id, iMenu);        format(szData, charsmax(szData), "%s^n%L", szData, id, "HANGMAN_ROOT_REMOVE"); }
        case MENU_SHOW:             { menuShow(id, iMenu);          format(szData, charsmax(szData), "%s^n%L", szData, id, "HANGMAN_ROOT_SHOW"); }
        case MENU_STATUS:           { menuStatus(id, iMenu);        format(szData, charsmax(szData), "%s^n%L", szData, id, "HANGMAN_ROOT_STATUS"); }
        case MENU_ROTATE:           { menuRotate(id, iMenu);        format(szData, charsmax(szData), "%s^n%L", szData, id, "HANGMAN_ROOT_ROTATE"); }
    }

    if ( menu_pages(iMenu) > 1 )
        format(szData, charsmax(szData), "%s^n%L", szData, id, "HANGMAN_MENU_TITLE_PAGE")

    menu_setprop(iMenu, MPROP_TITLE, szData)
    menu_setprop(iMenu, MPROP_EXIT, MEXIT_ALL)
    menu_setprop(iMenu, MPROP_NUMBER_COLOR, "\r")

    menu_display(id, iMenu)
    return PLUGIN_HANDLED
}

stock menuNav(id, iMenu)
{
    new szItem[64]
    formatex(szItem, charsmax(szItem), "%L", id, "HANGMAN_NAV_NEXT")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "HANGMAN_NAV_BACK")
    menu_additem(iMenu, szItem)

    menu_addblank2(iMenu)
}

public menuRoot(id, iMenu)
{
    new szItem[64]
    formatex(szItem, charsmax(szItem), "%L", id, "HANGMAN_ROOT_CREATE")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "HANGMAN_ROOT_EDIT")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "HANGMAN_ROOT_REMOVE")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "HANGMAN_ROOT_SAVE")
    menu_additem(iMenu, szItem)

    menu_addblank2(iMenu)

    formatex(szItem, charsmax(szItem), "%L", id, "HANGMAN_ROOT_NOCLIP", id, get_user_noclip(id) ? "HANGMAN_ON" : "HANGMAN_OFF")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "HANGMAN_ROOT_GODMODE", id, get_user_godmode(id) ? "HANGMAN_ON" : "HANGMAN_OFF")
    menu_additem(iMenu, szItem)
}

public menuHandlerRoot(id, menu, item)
{
    if ( item == MENU_EXIT )
    {
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }

    switch( item )
    {
        case ROOT_CREATE:
        {
            if ( g_iHangman >= MAX_ENT )
            {
                client_print_color(id, id, "%L %L", id, "HANGMAN_CHAT_TAG", id, "HANGMAN_CHAT_LIMIT", MAX_ENT)

                hangmanSound(id, SOUND_MENU_REMOVE)
                hangmanMenu(id, MENU_ROOT)
            }
            else
            {
                hangmanSound(id, SOUND_MENU_NAV)
                hangmanMenu(id, MENU_CREATE)
            }
        }
        case ROOT_EDIT:
        {
            if ( !g_iHangman )
            {
                client_print_color(id, id, "%L %L", id, "HANGMAN_CHAT_TAG", id, "HANGMAN_CHAT_NO_HANGMAN")

                hangmanSound(id, SOUND_MENU_REMOVE)
                hangmanMenu(id, MENU_ROOT)
            }
            else
            {
                hangmanSound(id, SOUND_MENU_NAV)
                hangmanMenu(id, MENU_EDIT)
            }
        }
        case ROOT_REMOVE:
        {
            if ( !g_iHangman )
            {
                client_print_color(id, id, "%L %L", id, "HANGMAN_CHAT_TAG", id, "HANGMAN_CHAT_NO_HANGMAN")

                hangmanSound(id, SOUND_MENU_REMOVE)
                hangmanMenu(id, MENU_ROOT)
            }
            else
            {
                hangmanSound(id, SOUND_MENU_REMOVE)
                hangmanMenu(id, MENU_REMOVE)
            }
        }
        case ROOT_SAVE:
        {
            saveData(id)
        }
        case ROOT_NOCLIP:
        {
            hangmanNoClip(id)
        }
        case ROOT_GODMODE:
        {
            hangmanGodMode(id)
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuCreate(iMenu)
{
    new eHangman[HANGMAN], szItem[64]
    for ( new i = 0; i < g_iHangmanConfig; i ++ )
    {
        ArrayGetArray(g_aHangmanConfig, i, eHangman)

        copy(szItem, charsmax(szItem), eHangman[HANGMAN_NAME])
        menu_additem(iMenu, szItem)
    }
}

public menuHandlerCreate(id, menu, item)
{
    if ( !is_user_alive(id) )
    {
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }
    else if ( item == MENU_EXIT )
    {
        hangmanSound(id, SOUND_MENU_NAV)
        hangmanMenu(id, MENU_ROOT)

        menu_destroy(menu)
        return PLUGIN_HANDLED
    }

    hangmanCreate(id, item)
    hangmanSound(id, SOUND_MENU_NAV)
    hangmanMenu(id, MENU_ROTATE)

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuEdit(id, iMenu)
{
    new szItem[64]
    formatex(szItem, charsmax(szItem), "%L", id, "HANGMAN_EDIT_SHOW")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "HANGMAN_EDIT_STATUS")
    menu_additem(iMenu, szItem)
}

public menuHandlerEdit(id, menu, item)
{
    switch( item )
    {
        case EDIT_SHOW:
        {
            hangmanSound(id, SOUND_MENU_NAV)
            hangmanMenu(id, MENU_SHOW)
        }
        case EDIT_STATUS:
        {
            hangmanSound(id, SOUND_MENU_NAV)
            hangmanMenu(id, MENU_STATUS)
        }
        case MENU_EXIT:
        {
            hangmanSound(id, SOUND_MENU_NAV)
            hangmanMenu(id, MENU_ROOT)
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuRemove(id, iMenu)
{
    new szItem[64], eHangman[HANGMAN]
    menuNav(id, iMenu)
    ArrayGetArray(g_aHangman, g_ePlayerData[id][PDATA_HANGMAN_MENU], eHangman)

    formatex(szItem, charsmax(szItem), "%L", id, "HANGMAN_REMOVE_CURRENT", eHangman[HANGMAN_NAME])
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "HANGMAN_REMOVE_ALL")
    menu_additem(iMenu, szItem)

    EnableAction(id)
    hangmanSelect(eHangman, TARGET_SELECT)
    g_ePlayerData[id][PDATA_MENU_TYPE] = MENU_REMOVE
    ArraySetArray(g_aHangman, g_ePlayerData[id][PDATA_HANGMAN_MENU], eHangman)
}

public menuHandlerRemove(id, menu, item)
{
    new eHangman[HANGMAN]
    ArrayGetArray(g_aHangman, g_ePlayerData[id][PDATA_HANGMAN_MENU], eHangman)
    if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
        hangmanSelect(eHangman, eHangman[HANGMAN_FLAGS] & FLAG_SHOW ? TARGET_CLEAR : TARGET_GHOST)

    switch( item )
    {
        case REMOVE_NEXT:
        {
            if ( g_ePlayerData[id][PDATA_HANGMAN_MENU] >= g_iHangman - 1 )
                g_ePlayerData[id][PDATA_HANGMAN_MENU] = 0
            else
                g_ePlayerData[id][PDATA_HANGMAN_MENU] ++

            hangmanSound(id, SOUND_MENU_NAV)
            hangmanMenu(id, MENU_REMOVE)
        }
        case REMOVE_BACK:
        {
            if ( g_ePlayerData[id][PDATA_HANGMAN_MENU] <= 0 )
                g_ePlayerData[id][PDATA_HANGMAN_MENU] = g_iHangman - 1
            else
                g_ePlayerData[id][PDATA_HANGMAN_MENU] --

            hangmanSound(id, SOUND_MENU_NAV)
            hangmanMenu(id, MENU_REMOVE)
        }
        case REMOVE_CURRENT:
        {
            eHangman[HANGMAN_FLAGS] &= ~FLAG_ACTIVE
            hangmanSetState(eHangman)
            hangmanKill(eHangman[HANGMAN_ID])
            hangmanKill(eHangman[HANGMAN_CORPSE])
            hangmanRemove(g_ePlayerData[id][PDATA_HANGMAN_MENU])

            client_print_color(id, id, "%L %L", id, "HANGMAN_CHAT_TAG", id, "HANGMAN_CHAT_REMOVE_CURRENT", eHangman[HANGMAN_NAME])
            g_ePlayerData[id][PDATA_HANGMAN_MENU] = 0

            hangmanSound(id, g_iHangman > 0 ? SOUND_MENU_REMOVE : SOUND_MENU_NAV)
            hangmanMenu(id, g_iHangman > 0 ? MENU_REMOVE : MENU_ROOT)
        }
        case REMOVE_ALL:
        {
            while( g_iHangman )
            {
                ArrayGetArray(g_aHangman, 0, eHangman)
                eHangman[HANGMAN_FLAGS] &= ~FLAG_ACTIVE

                hangmanSetState(eHangman)
                hangmanKill(eHangman[HANGMAN_ID])
                hangmanKill(eHangman[HANGMAN_CORPSE])
                hangmanRemove(0)
            }

            client_print_color(id, id, "%L %L", id, "HANGMAN_CHAT_TAG", id, "HANGMAN_CHAT_REMOVE_ALL")
            g_ePlayerData[id][PDATA_HANGMAN_MENU] = 0

            hangmanSound(id, SOUND_MENU_ALERT)
            hangmanMenu(id, MENU_ROOT)
        }
        case MENU_EXIT:
        {
            if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
            {
                hangmanSound(id, SOUND_MENU_NAV)
                hangmanMenu(id, MENU_ROOT)

                DisableAction(id)
                g_ePlayerData[id][PDATA_HANGMAN_MENU] = 0
            }

            g_ePlayerData[id][PDATA_MENU_TRACE] = false
        }
        default:
        {
            DisableAction(id)
            g_ePlayerData[id][PDATA_HANGMAN_MENU] = 0
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuShow(id, iMenu)
{
    new szItem[64], eHangman[HANGMAN]
    menuNav(id, iMenu)
    ArrayGetArray(g_aHangman, g_ePlayerData[id][PDATA_HANGMAN_MENU], eHangman)

    formatex(szItem, charsmax(szItem), "%L", id, "HANGMAN_SHOW_CURRENT",
    eHangman[HANGMAN_FLAGS] & FLAG_SHOW ? "\y" : "\r", eHangman[HANGMAN_NAME], id, eHangman[HANGMAN_FLAGS] & FLAG_SHOW ? "HANGMAN_SHOWN" : "HANGMAN_HIDDEN")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "HANGMAN_SHOW_ALL_SHOW")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "HANGMAN_SHOW_ALL_HIDE")
    menu_additem(iMenu, szItem)

    EnableAction(id)
    hangmanSelect(eHangman, TARGET_SELECT)
    g_ePlayerData[id][PDATA_MENU_TYPE] = MENU_SHOW
    ArraySetArray(g_aHangman, g_ePlayerData[id][PDATA_HANGMAN_MENU], eHangman)
}

public menuHandlerShow(id, menu, item)
{
    new eHangman[HANGMAN]
    ArrayGetArray(g_aHangman, g_ePlayerData[id][PDATA_HANGMAN_MENU], eHangman)
    if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
        hangmanSelect(eHangman, eHangman[HANGMAN_FLAGS] & FLAG_SHOW ? TARGET_CLEAR : TARGET_GHOST)

    switch( item )
    {
        case SHOW_NEXT:
        {
            if ( g_ePlayerData[id][PDATA_HANGMAN_MENU] >= g_iHangman - 1 )
                g_ePlayerData[id][PDATA_HANGMAN_MENU] = 0
            else
                g_ePlayerData[id][PDATA_HANGMAN_MENU] ++

            hangmanSound(id, SOUND_MENU_NAV)
            hangmanMenu(id, MENU_SHOW)
        }
        case SHOW_BACK:
        {
            if ( g_ePlayerData[id][PDATA_HANGMAN_MENU] <= 0 )
                g_ePlayerData[id][PDATA_HANGMAN_MENU] = g_iHangman - 1
            else
                g_ePlayerData[id][PDATA_HANGMAN_MENU] --

            hangmanSound(id, SOUND_MENU_NAV)
            hangmanMenu(id, MENU_SHOW)
        }
        case SHOW_CURRENT:
        {
            eHangman[HANGMAN_FLAGS] ^= FLAG_SHOW
            if ( eHangman[HANGMAN_FLAGS] & FLAG_SHOW )
                eHangman[HANGMAN_FLAGS] |= FLAG_ACTIVE
            else
                eHangman[HANGMAN_FLAGS] &= ~FLAG_ACTIVE
            hangmanSetState(eHangman)

            client_print_color(id, id, "%L %L", id, "HANGMAN_CHAT_TAG", id, "HANGMAN_CHAT_SHOW_CURRENT",
            eHangman[HANGMAN_NAME], id, eHangman[HANGMAN_FLAGS] & FLAG_SHOW ? "HANGMAN_CHAT_SHOWN" : "HANGMAN_CHAT_HIDDEN")
            ArraySetArray(g_aHangman, g_ePlayerData[id][PDATA_HANGMAN_MENU], eHangman)

            hangmanSound(id, SOUND_MENU_NAV)
            hangmanMenu(id, MENU_SHOW)
        }
        case SHOW_ALL_SHOW:
        {
            for ( new i = 0; i < g_iHangman; i ++ )
            {
                ArrayGetArray(g_aHangman, i, eHangman)
                eHangman[HANGMAN_FLAGS] |= (FLAG_SHOW | FLAG_ACTIVE)
                hangmanSetState(eHangman)

                ArraySetArray(g_aHangman, i, eHangman)
            }

            client_print_color(id, id, "%L %L", id, "HANGMAN_CHAT_TAG", id, "HANGMAN_CHAT_SHOW_ALL_SHOWN")
            hangmanSound(id, SOUND_MENU_ALERT)
            hangmanMenu(id, MENU_SHOW)
        }
        case SHOW_ALL_HIDE:
        {
            for ( new i = 0; i < g_iHangman; i ++ )
            {
                ArrayGetArray(g_aHangman, i, eHangman)
                eHangman[HANGMAN_FLAGS] &= ~(FLAG_SHOW | FLAG_ACTIVE)
                hangmanSetState(eHangman)

                ArraySetArray(g_aHangman, i, eHangman)
            }

            client_print_color(id, id, "%L %L", id, "HANGMAN_CHAT_TAG", id, "HANGMAN_CHAT_SHOW_ALL_HIDDEN")
            hangmanSound(id, SOUND_MENU_ALERT)
            hangmanMenu(id, MENU_SHOW)
        }
        case MENU_EXIT:
        {
            if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
            {
                hangmanSound(id, SOUND_MENU_NAV)
                hangmanMenu(id, MENU_ROOT)

                DisableAction(id)
                g_ePlayerData[id][PDATA_HANGMAN_MENU] = 0
            }

            g_ePlayerData[id][PDATA_MENU_TRACE] = false
        }
        default:
        {
            DisableAction(id)
            g_ePlayerData[id][PDATA_HANGMAN_MENU] = 0
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuStatus(id, iMenu)
{
    new szItem[64], eHangman[HANGMAN]
    menuNav(id, iMenu)
    ArrayGetArray(g_aHangman, g_ePlayerData[id][PDATA_HANGMAN_MENU], eHangman)

    formatex(szItem, charsmax(szItem), "%L", id, "HANGMAN_STATUS_CURRENT",
    eHangman[HANGMAN_FLAGS] & FLAG_ACTIVE ? "\y" : "\r", eHangman[HANGMAN_NAME], id, eHangman[HANGMAN_FLAGS] & FLAG_ACTIVE ? "HANGMAN_ENABLED" : "HANGMAN_DISABLED")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "HANGMAN_STATUS_ALL_ENABLE")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "HANGMAN_STATUS_ALL_DISABLE")
    menu_additem(iMenu, szItem)

    EnableAction(id)
    hangmanSelect(eHangman, TARGET_SELECT)
    g_ePlayerData[id][PDATA_MENU_TYPE] = MENU_STATUS
    ArraySetArray(g_aHangman, g_ePlayerData[id][PDATA_HANGMAN_MENU], eHangman)
}

public menuHandlerStatus(id, menu, item)
{
    new eHangman[HANGMAN]
    ArrayGetArray(g_aHangman, g_ePlayerData[id][PDATA_HANGMAN_MENU], eHangman)
    if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
        hangmanSelect(eHangman, eHangman[HANGMAN_FLAGS] & FLAG_SHOW ? TARGET_CLEAR : TARGET_GHOST)

    switch( item )
    {
        case STATUS_NEXT:
        {
            if ( g_ePlayerData[id][PDATA_HANGMAN_MENU] >= g_iHangman - 1 )
                g_ePlayerData[id][PDATA_HANGMAN_MENU] = 0
            else
                g_ePlayerData[id][PDATA_HANGMAN_MENU] ++

            hangmanSound(id, SOUND_MENU_NAV)
            hangmanMenu(id, MENU_STATUS)
        }
        case STATUS_BACK:
        {
            if ( g_ePlayerData[id][PDATA_HANGMAN_MENU] <= 0 )
                g_ePlayerData[id][PDATA_HANGMAN_MENU] = g_iHangman - 1
            else
                g_ePlayerData[id][PDATA_HANGMAN_MENU] --

            hangmanSound(id, SOUND_MENU_NAV)
            hangmanMenu(id, MENU_STATUS)
        }
        case STATUS_CURRENT:
        {
            eHangman[HANGMAN_FLAGS] ^= FLAG_ACTIVE
            hangmanSetState(eHangman)

            client_print_color(id, id, "%L %L", id, "HANGMAN_CHAT_TAG", id, "HANGMAN_CHAT_STATUS_CURRENT",
            eHangman[HANGMAN_NAME], id, eHangman[HANGMAN_FLAGS] & FLAG_ACTIVE ? "HANGMAN_CHAT_ENABLED" : "HANGMAN_CHAT_DISABLED")
            ArraySetArray(g_aHangman, g_ePlayerData[id][PDATA_HANGMAN_MENU], eHangman)

            hangmanSound(id, SOUND_MENU_NAV)
            hangmanMenu(id, MENU_STATUS)
        }
        case STATUS_ALL_ENABLE:
        {
            for ( new i = 0; i < g_iHangman; i ++ )
            {
                ArrayGetArray(g_aHangman, i, eHangman)
                eHangman[HANGMAN_FLAGS] |= FLAG_ACTIVE
                hangmanSetState(eHangman)

                ArraySetArray(g_aHangman, i, eHangman)
            }

            client_print_color(id, id, "%L %L", id, "HANGMAN_CHAT_TAG", id, "HANGMAN_CHAT_STATUS_ALL_ENABLED")
            hangmanSound(id, SOUND_MENU_ALERT)
            hangmanMenu(id, MENU_STATUS)
        }
        case STATUS_ALL_DISABLE:
        {
            for ( new i = 0; i < g_iHangman; i ++ )
            {
                ArrayGetArray(g_aHangman, i, eHangman)
                eHangman[HANGMAN_FLAGS] &= ~FLAG_ACTIVE
                hangmanSetState(eHangman)

                ArraySetArray(g_aHangman, i, eHangman)
            }

            client_print_color(id, id, "%L %L", id, "HANGMAN_CHAT_TAG", id, "HANGMAN_CHAT_STATUS_ALL_DISABLED")
            hangmanSound(id, SOUND_MENU_ALERT)
            hangmanMenu(id, MENU_STATUS)
        }
        case MENU_EXIT:
        {
            if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
            {
                hangmanSound(id, SOUND_MENU_NAV)
                hangmanMenu(id, MENU_ROOT)

                DisableAction(id)
                g_ePlayerData[id][PDATA_HANGMAN_MENU] = 0
            }

            g_ePlayerData[id][PDATA_MENU_TRACE] = false
        }
        default:
        {
            DisableAction(id)
            g_ePlayerData[id][PDATA_HANGMAN_MENU] = 0
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuRotate(id, iMenu)
{
    new szItem[64], eHangman[HANGMAN]
    if ( hangmanGet(eHangman, g_ePlayerData[id][PDATA_HANGMAN_GHOST]) == -1 )
    {
        menu_destroy(iMenu)
        return
    }

    formatex(szItem, charsmax(szItem), "%L", id, "HANGMAN_ROTATE_UP")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "HANGMAN_ROTATE_DOWN")
    menu_additem(iMenu, szItem)

    menu_addblank2(iMenu)

    formatex(szItem, charsmax(szItem), "%L", id, "HANGMAN_ROTATE_GROUND",
    id, eHangman[HANGMAN_FLAGS] & FLAG_GROUND ? "HANGMAN_ON" : "HANGMAN_OFF")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "HANGMAN_ROTATE_PLACE")
    menu_additem(iMenu, szItem)
}

public menuHandlerRotate(id, menu, item)
{
    new eHangman[HANGMAN], iItem
    if ( (iItem = hangmanGet(eHangman, g_ePlayerData[id][PDATA_HANGMAN_GHOST])) == -1 )
    {
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }

    switch( item )
    {
        case ROTATE_UP:
        {
            pev(eHangman[HANGMAN_ID], pev_angles, eHangman[HANGMAN_ANGLES])
            eHangman[HANGMAN_ANGLES][1] -= g_eSettings[SETTING_ROTATION_STEP]
            if ( eHangman[HANGMAN_ANGLES][1] < -180.0 ) eHangman[HANGMAN_ANGLES][1] += 360.0

            set_pev(eHangman[HANGMAN_ID], pev_angles, eHangman[HANGMAN_ANGLES])
            ArraySetArray(g_aHangman, iItem, eHangman)

            hangmanSound(id, SOUND_MENU_NAV)
            hangmanMenu(id, MENU_ROTATE)
        }
        case ROTATE_DOWN:
        {
            pev(eHangman[HANGMAN_ID], pev_angles, eHangman[HANGMAN_ANGLES])
            eHangman[HANGMAN_ANGLES][1] += g_eSettings[SETTING_ROTATION_STEP]
            if ( eHangman[HANGMAN_ANGLES][1] > 180.0 ) eHangman[HANGMAN_ANGLES][1] -= 360.0

            set_pev(eHangman[HANGMAN_ID], pev_angles, eHangman[HANGMAN_ANGLES])
            ArraySetArray(g_aHangman, iItem, eHangman)

            hangmanSound(id, SOUND_MENU_NAV)
            hangmanMenu(id, MENU_ROTATE)
        }
        case ROTATE_GROUND:
        {
            eHangman[HANGMAN_FLAGS] ^= FLAG_GROUND
            ArraySetArray(g_aHangman, iItem, eHangman)

            hangmanSound(id, SOUND_MENU_NAV)
            hangmanMenu(id, MENU_ROTATE)
        }
        case ROTATE_PLACE:
        {
            hangmanTrace(eHangman, id)
            DisableAction(id)
            set_pdata_float(id, PDATA_NEXT_ATTACK, 0.0, XO_CBASEPLAYER, XO_CBASEPLAYER)
            g_ePlayerData[id][PDATA_HANGMAN_GHOST] = 0

            eHangman[HANGMAN_FLAGS] &= ~FLAG_GHOST
            eHangman[HANGMAN_FLAGS] |= (FLAG_SHOW | FLAG_ACTIVE)
            eHangman[HANGMAN_ANGLES][0] = -eHangman[HANGMAN_ANGLES][0]
            hangmanSetSize(eHangman)
            hangmanSetState(eHangman)
            client_print_color(id, id, "%L %L", id, "HANGMAN_CHAT_TAG", id, "HANGMAN_CHAT_CREATE_NEW", eHangman[HANGMAN_NAME])

            ArraySetArray(g_aHangman, iItem, eHangman)
            hangmanSound(id, SOUND_MENU_NAV)
            hangmanMenu(id, MENU_CREATE)
        }
        case MENU_EXIT:
        {
            hangmanKill(eHangman[HANGMAN_ID])
            hangmanRemove(iItem)
            DisableAction(id)
            set_pdata_float(id, PDATA_NEXT_ATTACK, 0.0, XO_CBASEPLAYER, XO_CBASEPLAYER)
            g_ePlayerData[id][PDATA_HANGMAN_GHOST] = 0

            hangmanSound(id, SOUND_MENU_NAV)
            hangmanMenu(id, MENU_CREATE)
        }
        default:
        {
            hangmanKill(eHangman[HANGMAN_ID])
            hangmanRemove(iItem)
            DisableAction(id)
            set_pdata_float(id, PDATA_NEXT_ATTACK, 0.0, XO_CBASEPLAYER, XO_CBASEPLAYER)
            g_ePlayerData[id][PDATA_HANGMAN_GHOST] = 0
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public hangmanTask()
{
    new eHangman[HANGMAN], iItem, bool:bModified, Float:fCurrentTime
    fCurrentTime = get_gametime()

    for ( new id = 1; id <= g_iMaxPlayers; id ++ )
    {
        if ( !is_user_alive(id) )
            continue

        if ( g_ePlayerData[id][PDATA_NEXT_HANG] )
        {
            if ( fCurrentTime >= g_ePlayerData[id][PDATA_NEXT_HANG] )
            {
                if ( (iItem = hangmanGet(eHangman, g_ePlayerData[id][PDATA_HANGMAN_ID])) != -1 )
                {
                    g_ePlayerData[id][PDATA_HANGMAN_ID] = 0
                    g_ePlayerData[id][PDATA_NEXT_HANG] = 0.0

                    hangmanHang(eHangman, id)
                    eHangman[HANGMAN_FLAGS] |= FLAG_USED
                    eHangman[HANGMAN_NEXT_ACTIVE] = fCurrentTime + random_float(eHangman[HANGMAN_COOLDOWN][0], eHangman[HANGMAN_COOLDOWN][1])
                    ArraySetArray(g_aHangman, iItem, eHangman)
                }
            }
            else if ( fCurrentTime - g_ePlayerData[id][PDATA_NEXT_CHECK] > 0.1 )
            {
                hangmanBar(id, 0)
                g_ePlayerData[id][PDATA_HANGMAN_ID] = 0
                g_ePlayerData[id][PDATA_NEXT_HANG] = 0.0
            }
        }
    }

    for ( new i = 0; i < g_iHangman; i ++ )
    {
        ArrayGetArray(g_aHangman, i, eHangman)
        bModified = false

        if ( eHangman[HANGMAN_FLAGS] & FLAG_USED )
        {
            if ( fCurrentTime >= eHangman[HANGMAN_NEXT_ACTIVE] )
            {
                hangmanKill(eHangman[HANGMAN_CORPSE])
                eHangman[HANGMAN_CORPSE] = 0
                eHangman[HANGMAN_FLAGS] &= ~FLAG_USED
                eHangman[HANGMAN_NEXT_ACTIVE] = 0.0

                bModified = true
            }
        }

        if ( bModified )
            ArraySetArray(g_aHangman, i, eHangman)
    }
}

stock hangmanCreate(id, iItem)
{
    new iEnt = cs_create_entity("info_target")
    if ( !pev_valid(iEnt) )
        return

    new eHangman[HANGMAN]
    ArrayGetArray(g_aHangmanConfig, iItem, eHangman)
    eHangman[HANGMAN_ID] = iEnt
    eHangman[HANGMAN_ITEM] = iItem
    if ( id )
    {
        EnableAction(id)
        g_ePlayerData[id][PDATA_HANGMAN_GHOST] = eHangman[HANGMAN_ID]
        g_ePlayerData[id][PDATA_OFFSET] = g_eSettings[SETTING_OFFSET_BASE]

        eHangman[HANGMAN_FLAGS] |= FLAG_GHOST
    }

    hangmanSelect(eHangman, TARGET_GHOST)
    set_pev(iEnt, pev_classname, g_szCN)
    set_pev(iEnt, pev_impulse, HANGMAN_KEY)
    set_pev(iEnt, HANGMAN_ARRAY_ITEM, g_iHangman)
    dllfunc(DLLFunc_Spawn, iEnt)
    set_pev(iEnt, pev_solid, SOLID_NOT)
    set_pev(iEnt, pev_movetype, MOVETYPE_FLY)
    engfunc(EngFunc_SetModel, iEnt, g_eSettings[SETTING_DEFAULT_MODEL])

    ArrayPushArray(g_aHangman, eHangman)
    if ( ++ g_iHangman == 1 )
    {
        set_task(g_eSettings[SETTING_HANGMAN_TASK], "hangmanTask", HANGMAN_KEY, .flags = "b")
        EnableHangman()
    }
}

stock hangmanCreateView(eHangman[HANGMAN])
{
    new Float:fForward[3], Float:fRight[3], Float:fDirection[3], Float:fFrac
    engfunc(EngFunc_AngleVectors, eHangman[HANGMAN_ANGLES], fForward, fRight, NULL_VECTOR)

    xs_vec_copy(eHangman[HANGMAN_ORIGIN], eHangman[HANGMAN_ORIGIN_VIEW])
    xs_vec_mul_scalar(fRight, -VIEW_FORWARD_OFFSET, fRight)
    xs_vec_mul_scalar(fForward, VIEW_RIGHT_OFFSET, fForward)
    xs_vec_add(eHangman[HANGMAN_ORIGIN_VIEW], fRight, eHangman[HANGMAN_ORIGIN_VIEW])
    xs_vec_add(eHangman[HANGMAN_ORIGIN_VIEW], fForward, eHangman[HANGMAN_ORIGIN_VIEW])
    eHangman[HANGMAN_ORIGIN_VIEW][2] += VIEW_UP_OFFSET

    engfunc(EngFunc_TraceLine, eHangman[HANGMAN_ORIGIN], eHangman[HANGMAN_ORIGIN_VIEW], IGNORE_MONSTERS, eHangman[HANGMAN_ID], 0)
    get_tr2(0, TR_flFraction, fFrac)
    if ( fFrac < 1.0 )
        get_tr2(0, TR_vecEndPos, eHangman[HANGMAN_ORIGIN_VIEW])

    xs_vec_sub(eHangman[HANGMAN_ORIGIN], eHangman[HANGMAN_ORIGIN_VIEW], fDirection)
    engfunc(EngFunc_VecToAngles, fDirection, eHangman[HANGMAN_ANGLES_VIEW])
}

public hangmanRemove(iItem)
{
    new eHangman[HANGMAN]
    ArrayDeleteItem(g_aHangman, iItem)

    if ( -- g_iHangman == 0 )
    {
        remove_task(HANGMAN_KEY)
        DisableHangman()
    }

    for ( new i = iItem; i < g_iHangman; i ++ )
    {
        ArrayGetArray(g_aHangman, i, eHangman)
        set_pev(eHangman[HANGMAN_ID], HANGMAN_ARRAY_ITEM, i)
    }
}

public saveData(id)
{
    new eHangman[HANGMAN],
        szFile[128], iFile,
        szData[64]

    get_mapname(szFile, charsmax(szFile))
    format(szFile, charsmax(szFile), "maps/%s_Hangman.ini", szFile)

    iFile = fopen(szFile, "wt")
    if ( !iFile )
        return PLUGIN_HANDLED

    hangmanTerminate()
    for ( new i = 0; i < g_iHangman; i ++ )
    {
        ArrayGetArray(g_aHangman, i, eHangman)

        formatex(szData, charsmax(szData), "[%d]^n", i)
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "item = %d^n", eHangman[HANGMAN_ITEM])
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "flags = %d^n", eHangman[HANGMAN_FLAGS])
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "origin = %.2f %.2f %.2f^n",
        eHangman[HANGMAN_ORIGIN][0], eHangman[HANGMAN_ORIGIN][1], eHangman[HANGMAN_ORIGIN][2])
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "angles = %.2f %.2f %.2f^n",
        eHangman[HANGMAN_ANGLES][0], eHangman[HANGMAN_ANGLES][1], eHangman[HANGMAN_ANGLES][2])
        fputs(iFile, szData)
    }

    client_print_color(id, id, "%L %L", id, "HANGMAN_CHAT_TAG", id, "HANGMAN_CHAT_SAVE", szFile)
    fclose(iFile)

    hangmanSound(id, SOUND_MENU_NAV)
    hangmanMenu(id, MENU_ROOT)
    return PLUGIN_HANDLED
}

public loadData()
{
    new szFile[128], iFile,
        szData[64], szKey[32], szValue[32],
        Float:fOrigin[3], Float:fAngles[3], iItem, iFlags, iCount = -1

    get_mapname(szFile, charsmax(szFile))
    format(szFile, charsmax(szFile), "maps/%s_Hangman.ini", szFile)

    iFile = fopen(szFile, "rt")
    if ( !iFile )
        return

    while( !feof(iFile) )
    {
        fgets(iFile, szData, charsmax(szData))

        if ( szData[0] == '[' )
        {
            if ( iCount != -1 )
                LoadDataHangman(iItem, iFlags, fOrigin, fAngles, iCount)

            iCount ++
        }
        else
        {
            strtok(szData, szKey, charsmax( szKey ), szValue, charsmax( szValue ), '=')
            trim(szKey)
            trim(szValue)

            if ( equal(szKey, "item") )
            {
                iItem = str_to_num(szValue)
            }
            else if ( equal(szKey, "flags") )
            {
                iFlags = str_to_num(szValue)
            }
            else if ( equal(szKey, "origin") )
            {
                strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                fOrigin[0] = str_to_float(szKey)

                strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                fOrigin[1] = str_to_float(szKey)
                fOrigin[2] = str_to_float(szValue)
            }
            else if ( equal(szKey, "angles") )
            {
                strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                fAngles[0] = str_to_float(szKey)

                strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                fAngles[1] = str_to_float(szKey)
                fAngles[2] = str_to_float(szValue)
            }
        }
    }

    if ( iCount != -1 )
        LoadDataHangman(iItem, iFlags, fOrigin, fAngles, iCount)

    fclose(iFile)
}

stock LoadDataHangman(iItem, iFlags, Float:fOrigin[3], Float:fAngles[3], iCount)
{
    new eHangman[HANGMAN]
    hangmanCreate(0, iItem)
    ArrayGetArray(g_aHangman, iCount, eHangman)

    eHangman[HANGMAN_FLAGS] = iFlags
    fAngles[0] = -fAngles[0]
    xs_vec_copy(fOrigin, eHangman[HANGMAN_ORIGIN])
    xs_vec_copy(fAngles, eHangman[HANGMAN_ANGLES])

    hangmanSetBox(eHangman)
    hangmanSetSize(eHangman)
    hangmanSetState(eHangman)
    ArraySetArray(g_aHangman, iCount, eHangman)
}

public hangmanNoClip(id)
{
    set_user_noclip(id, !get_user_noclip(id))

    hangmanSound(id, SOUND_MENU_NAV)
    hangmanMenu(id, MENU_ROOT)
}

public hangmanGodMode(id)
{
    set_user_godmode(id, !get_user_godmode(id))

    hangmanSound(id, SOUND_MENU_NAV)
    hangmanMenu(id, MENU_ROOT)
}

public fwdEmitSound(iEnt, iChannel, const szSample[])
{
    if ( g_iSilentVictim && iEnt == g_iSilentVictim )
        return FMRES_SUPERCEDE

    return FMRES_IGNORED
}

public fwdUse(iEnt, iCaller, iActivator, iType, Float:fValue)
{
    if ( !isHangman(iEnt)
    || !is_user_alive(iActivator) )
        return HAM_IGNORED

    new eHangman[HANGMAN]
    if ( hangmanGet(eHangman, iEnt) == -1 )
        return HAM_IGNORED

    new Float:fCurrentTime = get_gametime()
    if ( !(eHangman[HANGMAN_FLAGS] & FLAG_ACTIVE)
    || eHangman[HANGMAN_FLAGS] & FLAG_USED
    || !(CsTeams:eHangman[HANGMAN_TEAM] & cs_get_user_team(iActivator))
    || fCurrentTime < eHangman[HANGMAN_NEXT_ACTIVE] )
        return HAM_IGNORED

    g_ePlayerData[iActivator][PDATA_NEXT_CHECK] = fCurrentTime
    if ( !g_ePlayerData[iActivator][PDATA_NEXT_HANG] )
    {
        new iDuration
        iDuration = random_num(g_eSettings[SETTING_DEFAULT_HOLD_DURATION][0], g_eSettings[SETTING_DEFAULT_HOLD_DURATION][1])

        hangmanBar(iActivator, iDuration)
        g_ePlayerData[iActivator][PDATA_HANGMAN_ID] = iEnt
        g_ePlayerData[iActivator][PDATA_NEXT_HANG] = fCurrentTime + iDuration
    }
    else if ( !fValue )
    {
        hangmanBar(iActivator, 0)
        g_ePlayerData[iActivator][PDATA_HANGMAN_ID] = 0
        g_ePlayerData[iActivator][PDATA_NEXT_HANG] = 0.0
    }

    return HAM_IGNORED
}

public fwdObjectCaps(iEnt)
{
    if ( !isHangman(iEnt) )
        return HAM_IGNORED

    SetHamReturnInteger(FCAP_CONTINUOUS_USE | FCAP_ONOFF_USE)
    return HAM_SUPERCEDE
}

public fwdPreThink(id)
{
    if ( !is_user_alive(id) )
        return HAM_IGNORED

    static eHangman[HANGMAN], iButton, Float:fCurrentTime
    iButton = pev(id, pev_button)
    fCurrentTime = get_gametime()

    if ( hangmanGet(eHangman, g_ePlayerData[id][PDATA_HANGMAN_GHOST]) != -1 )
    {
        if ( g_ePlayerData[id][PDATA_HANGMAN_GHOST] )
        {
            if ( fCurrentTime > g_ePlayerData[id][PDATA_NEXT_OFFSET] )
            {
                if ( iButton & IN_ATTACK )
                {
                    g_ePlayerData[id][PDATA_OFFSET]      += g_eSettings[SETTING_OFFSET_STEP]
                    g_ePlayerData[id][PDATA_OFFSET]      = floatclamp(g_ePlayerData[id][PDATA_OFFSET], g_eSettings[SETTING_OFFSET][0], g_eSettings[SETTING_OFFSET][1])
                    g_ePlayerData[id][PDATA_NEXT_OFFSET] = fCurrentTime + 0.1
                }
                else if ( iButton & IN_ATTACK2 )
                {
                    g_ePlayerData[id][PDATA_OFFSET]      -= g_eSettings[SETTING_OFFSET_STEP]
                    g_ePlayerData[id][PDATA_OFFSET]      = floatclamp(g_ePlayerData[id][PDATA_OFFSET], g_eSettings[SETTING_OFFSET][0], g_eSettings[SETTING_OFFSET][1])
                    g_ePlayerData[id][PDATA_NEXT_OFFSET] = fCurrentTime + 0.1
                }
            }

            set_pdata_float(id, PDATA_NEXT_ATTACK, fCurrentTime + 0.1, XO_CBASEPLAYER, XO_CBASEPLAYER)
            iButton &= ~(IN_ATTACK | IN_ATTACK2)
            set_pev(id, pev_button, iButton)

            hangmanTrace(eHangman, id)
        }
    }
    else if ( g_ePlayerData[id][PDATA_HANGMAN_ACTION] )
    {
        hangmanCheck(id)
    }

    return HAM_IGNORED
}

public fwdKilled(id, iAttacker, bGib)
{
    DisableAction(id)
    g_ePlayerData[id][PDATA_HANGMAN_MENU] = 0
    if ( g_ePlayerData[id][PDATA_HANGMAN_GHOST] )
    {
        new eHangman[HANGMAN], iItem
        if ( (iItem = hangmanGet(eHangman, g_ePlayerData[id][PDATA_HANGMAN_GHOST])) != -1 )
        {
            hangmanKill(eHangman[HANGMAN_ID])
            hangmanRemove(iItem)
        }

        g_ePlayerData[id][PDATA_HANGMAN_GHOST] = 0
    }

    if ( id == g_iSilentVictim )
    {
        set_pev(id, pev_deadflag, DEAD_DISCARDBODY)
        g_iSilentVictim = 0
    }
}

stock hangmanTrace(eHangman[HANGMAN], id)
{
    new Float:fVec1[3]
    pev(id, pev_origin, eHangman[HANGMAN_ORIGIN])
    pev(id, pev_v_angle, fVec1)
    engfunc(EngFunc_MakeVectors, fVec1)
    global_get(glb_v_forward, fVec1)

    xs_vec_mul_scalar(fVec1, g_ePlayerData[id][PDATA_OFFSET], fVec1)
    xs_vec_add(fVec1, eHangman[HANGMAN_ORIGIN], fVec1)

    engfunc(EngFunc_TraceLine, eHangman[HANGMAN_ORIGIN], fVec1, DONT_IGNORE_MONSTERS, id, 0)
    get_tr2(0, TR_vecEndPos, eHangman[HANGMAN_ORIGIN])

    hangmanSetBox(eHangman)
    hangmanSetOffset(eHangman)
    set_pev(eHangman[HANGMAN_ID], pev_origin, eHangman[HANGMAN_ORIGIN])
}

stock hangmanCheck(id)
{
    new eHangman[HANGMAN], Float:fVec1[3], Float:fVec2[3], Float:fVec3[3], Float:fMins[3], Float:fMaxs[3], Float:fNearest[3]
    new iBest, Float:fBestDist, Float:fDot, Float:fDist

    pev(id, pev_origin, fVec1)
    pev(id, pev_view_ofs, fVec2)
    xs_vec_add(fVec1, fVec2, fVec1)

    pev(id, pev_v_angle, fVec2)
    engfunc(EngFunc_MakeVectors, fVec2)
    global_get(glb_v_forward, fVec2)

    iBest = -1
    fBestDist = g_eSettings[SETTING_HANGMAN_CHECK]
    for ( new i = 0; i < g_iHangman; i ++ )
    {
        ArrayGetArray(g_aHangman, i, eHangman)
        xs_vec_sub(eHangman[HANGMAN_ORIGIN], fVec1, fVec3)
        fDot = xs_vec_dot(fVec2, fVec3)

        if ( fDot < 0.0 )
            continue

        pev(eHangman[HANGMAN_ID], pev_absmin, fMins)
        pev(eHangman[HANGMAN_ID], pev_absmax, fMaxs)
        xs_vec_mul_scalar(fVec2, fDot, fVec3)
        xs_vec_add(fVec3, fVec1, fVec3)

        fNearest[0] = floatclamp(fVec3[0], fMins[0], fMaxs[0])
        fNearest[1] = floatclamp(fVec3[1], fMins[1], fMaxs[1])
        fNearest[2] = floatclamp(fVec3[2], fMins[2], fMaxs[2])
        fDist = get_distance_f(fVec3, fNearest)
        if ( fDist < fBestDist )
        {
            fBestDist = fDist
            iBest = i
        }
    }

    if ( iBest != -1
    && g_ePlayerData[id][PDATA_HANGMAN_MENU] != iBest )
    {
        ArrayGetArray(g_aHangman, g_ePlayerData[id][PDATA_HANGMAN_MENU], eHangman)
        hangmanSelect(eHangman, eHangman[HANGMAN_FLAGS] & FLAG_SHOW ? TARGET_CLEAR : TARGET_GHOST)

        g_ePlayerData[id][PDATA_MENU_TRACE] = true
        g_ePlayerData[id][PDATA_HANGMAN_MENU] = iBest
        hangmanMenu(id, g_ePlayerData[id][PDATA_MENU_TYPE])
    }
}

stock hangmanSetBox(eHangman[HANGMAN])
{
    new Float:fMins[3], Float:fMaxs[3],
        Float:fForward[3], Float:fRight[3], Float:fUp[3],
        Float:fCorners[8][3]

    eHangman[HANGMAN_ANGLES][0] = -eHangman[HANGMAN_ANGLES][0]
    engfunc(EngFunc_AngleVectors, eHangman[HANGMAN_ANGLES], fForward, fRight, fUp)
    xs_vec_copy(g_eSettings[SETTING_MINS], fMins)
    xs_vec_copy(g_eSettings[SETTING_MAXS], fMaxs)

    for ( new i = 0; i < 8; i ++ )
    {
        fCorners[i][0] = (i & 1) ? fMaxs[0] : fMins[0]
        fCorners[i][1] = (i & 2) ? fMaxs[1] : fMins[1]
        fCorners[i][2] = (i & 4) ? fMaxs[2] : fMins[2]

        boxRotate(fCorners[i], fForward, fRight, fUp)
    }

    xs_vec_copy(fCorners[0], fMins)
    xs_vec_copy(fCorners[0], fMaxs)
    for ( new i = 1; i < 8; i ++ )
    {
        fMins[0] = floatmin(fMins[0], fCorners[i][0])
        fMins[1] = floatmin(fMins[1], fCorners[i][1])
        fMins[2] = floatmin(fMins[2], fCorners[i][2])

        fMaxs[0] = floatmax(fMaxs[0], fCorners[i][0])
        fMaxs[1] = floatmax(fMaxs[1], fCorners[i][1])
        fMaxs[2] = floatmax(fMaxs[2], fCorners[i][2])
    }

    xs_vec_copy(fMins, eHangman[HANGMAN_MINS])
    xs_vec_copy(fMaxs, eHangman[HANGMAN_MAXS])
}

stock boxRotate(Float:fLocal[3], Float:fForward[3], Float:fRight[3], Float:fUp[3])
{
    new Float:fOut[3]
    fOut[0] = fLocal[0] * fForward[0] - fLocal[1] * fRight[0] + fLocal[2] * fUp[0]
    fOut[1] = fLocal[0] * fForward[1] - fLocal[1] * fRight[1] + fLocal[2] * fUp[1]
    fOut[2] = fLocal[0] * fForward[2] - fLocal[1] * fRight[2] + fLocal[2] * fUp[2]

    xs_vec_copy(fOut, fLocal)
}

stock hangmanSetOffset(eHangman[HANGMAN])
{
    new Float:fGaps[6], Float:fVec1[3], Float:fCurrentGap
    fGaps[0] = -eHangman[HANGMAN_MINS][0]
    fGaps[1] = eHangman[HANGMAN_MAXS][0]
    fGaps[2] = -eHangman[HANGMAN_MINS][1]
    fGaps[3] = eHangman[HANGMAN_MAXS][1]
    fGaps[4] = -eHangman[HANGMAN_MINS][2]
    fGaps[5] = eHangman[HANGMAN_MAXS][2]

    if ( eHangman[HANGMAN_FLAGS] & FLAG_GROUND )
    {
        xs_vec_sub(eHangman[HANGMAN_ORIGIN], Float:{0.0, 0.0, 9999.9}, fVec1)
        engfunc(EngFunc_TraceLine, eHangman[HANGMAN_ORIGIN], fVec1, DONT_IGNORE_MONSTERS, eHangman[HANGMAN_ID], 0)
        get_tr2(0, TR_vecEndPos, eHangman[HANGMAN_ORIGIN])
    }

    for ( new i = 5; i >= 0; i -- )
    {
        xs_vec_mul_scalar(g_fDirections[i], 9999.9, fVec1)
        xs_vec_add(fVec1, eHangman[HANGMAN_ORIGIN], fVec1)
        engfunc(EngFunc_TraceLine, eHangman[HANGMAN_ORIGIN], fVec1, DONT_IGNORE_MONSTERS, eHangman[HANGMAN_ID], 0)
        get_tr2(0, TR_vecEndPos, fVec1)
        fCurrentGap = xs_vec_distance(eHangman[HANGMAN_ORIGIN], fVec1)

        if ( fCurrentGap < fGaps[i] )
        {
            get_tr2(0, TR_vecPlaneNormal, fVec1)
            xs_vec_mul_scalar(fVec1, fGaps[i] - fCurrentGap, fVec1)
            xs_vec_add(eHangman[HANGMAN_ORIGIN], fVec1, eHangman[HANGMAN_ORIGIN])
        }
    }
}

stock hangmanSetSize(eHangman[HANGMAN])
{
    hangmanSelect(eHangman, TARGET_CLEAR)
    engfunc(EngFunc_SetOrigin, eHangman[HANGMAN_ID], eHangman[HANGMAN_ORIGIN])
    set_pev(eHangman[HANGMAN_ID], pev_angles, eHangman[HANGMAN_ANGLES])
    set_pev(eHangman[HANGMAN_ID], pev_solid, eHangman[HANGMAN_FLAGS] & FLAG_SHOW ? SOLID_BBOX : SOLID_NOT)
    set_pev(eHangman[HANGMAN_ID], pev_movetype, MOVETYPE_NONE)

    engfunc(EngFunc_SetSize, eHangman[HANGMAN_ID], eHangman[HANGMAN_MINS], eHangman[HANGMAN_MAXS])
    hangmanCreateView(eHangman)
}

stock hangmanSetState(eHangman[HANGMAN])
{
    if ( eHangman[HANGMAN_FLAGS] & FLAG_SHOW )
    {
        set_pev(eHangman[HANGMAN_ID], pev_solid, SOLID_BBOX)
        if ( pev_valid(eHangman[HANGMAN_CORPSE] ) )
        {
            set_pev(eHangman[HANGMAN_CORPSE], pev_solid, SOLID_BBOX)
            set_pev(eHangman[HANGMAN_CORPSE], pev_takedamage, DAMAGE_YES)
        }

        hangmanSelect(eHangman, TARGET_CLEAR)
    }
    else
    {
        set_pev(eHangman[HANGMAN_ID], pev_solid, SOLID_NOT)
        if ( pev_valid(eHangman[HANGMAN_CORPSE] ) )
        {
            set_pev(eHangman[HANGMAN_CORPSE], pev_solid, SOLID_NOT)
            set_pev(eHangman[HANGMAN_CORPSE], pev_takedamage, DAMAGE_YES)
        }

        hangmanSelect(eHangman, TARGET_HIDE)
    }
}

stock hangmanHangOffset(iCorpse, Float:fOrigin[3])
{
    new Float:fAng[3], Float:fFwd[3], Float:fRight[3]
    pev(iCorpse, pev_angles, fAng)
    fAng[0] = 0.0
    fAng[2] = 0.0
    engfunc(EngFunc_AngleVectors, fAng, fFwd, fRight, NULL_VECTOR)

    xs_vec_add_scaled(fOrigin, fFwd, g_fHangOffset[0], fOrigin)
    xs_vec_add_scaled(fOrigin, fRight, g_fHangOffset[1], fOrigin)
    fOrigin[2] += g_fHangOffset[2]

    engfunc(EngFunc_SetOrigin, iCorpse, fOrigin)
}

stock hangmanCorpseFit(iEnt, Float:fOrigin[3], Float:fHang[3])
{
    new Float:fRel[3], Float:fMins[3], Float:fMaxs[3]
    xs_vec_sub(fHang, fOrigin, fRel)

    fMins[0] = fRel[0] - CORPSE_HALF_WIDTH
    fMins[1] = fRel[1] - CORPSE_HALF_WIDTH
    fMins[2] = fRel[2] - CORPSE_DOWN
    fMaxs[0] = fRel[0] + CORPSE_HALF_WIDTH
    fMaxs[1] = fRel[1] + CORPSE_HALF_WIDTH
    fMaxs[2] = fRel[2] + CORPSE_UP
    engfunc(EngFunc_SetSize, iEnt, fMins, fMaxs)
    engfunc(EngFunc_SetOrigin, iEnt, fOrigin)
}

stock hangmanStrip(id)
{
    new iWeapons[32], iNum, szName[32], iEnt
    get_user_weapons(id, iWeapons, iNum)
    for ( new i; i < iNum; i ++ )
    {
        if ( !get_weaponname(iWeapons[i], szName, charsmax(szName)) )
            continue

        iEnt = -1
        while ( (iEnt = engfunc(EngFunc_FindEntityByString, iEnt, "classname", szName)) > 0 )
        {
            if ( pev(iEnt, pev_owner) != id )
                continue

            ExecuteHam(Ham_RemovePlayerItem, id, iEnt)
            user_has_weapon(id, iWeapons[i], 0)
            ExecuteHamB(Ham_Item_Kill, iEnt)
            break
        }
    }
}

stock hangmanHang(eHangman[HANGMAN], id, bool:bForced = false)
{
    new iCorpse = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
    if ( !pev_valid(iCorpse) )
        return

    new szModel[32], szPath[96]
    new Float:fHang[3], Float:fBone[3], Float:fOrigin[3], Float:fAngles[3]
    cs_get_user_model(id, szModel, charsmax(szModel))
    formatex(szPath, charsmax(szPath), "models/player/%s/%s.mdl", szModel, szModel)

    xs_vec_copy(eHangman[HANGMAN_ANGLES], fAngles)
    fAngles[0] = CORPSE_PITCH_OFFSET
    fAngles[1] += CORPSE_YAW_OFFSET
    if ( fAngles[1] > 180.0 )
        fAngles[1] -= 360.0

    engfunc(EngFunc_GetAttachment, eHangman[HANGMAN_ID], 0, fHang, NULL_VECTOR)
    set_pev(iCorpse, pev_classname, g_szCN)
    set_pev(iCorpse, pev_impulse, CORPSEGORE_KEY)
    dllfunc(DLLFunc_Spawn, iCorpse)
    engfunc(EngFunc_SetOrigin, iCorpse, fHang)
    set_pev(iCorpse, pev_angles, fAngles)
    set_pev(iCorpse, pev_solid, SOLID_BBOX)
    set_pev(iCorpse, pev_movetype, MOVETYPE_NONE)
    set_pev(iCorpse, pev_takedamage, DAMAGE_YES)
    engfunc(EngFunc_SetModel, iCorpse, szPath)
    set_pev(iCorpse, pev_skin, pev(id, pev_skin))
    if ( LibraryExists("corpsegore", LibType_Library) )
        set_pev(iCorpse, pev_health, corpsegore_get_corpse_health())

    set_pev(iCorpse, pev_frame, SEQ_FRAME / (SEQ_FRAME_NUM - 1.0) * 255.0)
    set_pev(iCorpse, pev_sequence, SEQ)
    set_pev(iCorpse, pev_framerate, 0.0)
    set_pev(iCorpse, pev_animtime, get_gametime())

    engfunc(EngFunc_GetBonePosition, iCorpse, HANG_BONE, fBone, NULL_VECTOR)
    for ( new i; i < 3; i ++ )
        fOrigin[i] = fHang[i] * 2.0 - fBone[i]

    hangmanHangOffset(iCorpse, fOrigin)
    hangmanCorpseFit(iCorpse, fOrigin, fHang)

    g_iSilentVictim = id
    eHangman[HANGMAN_CORPSE] = iCorpse
    set_pev(iCorpse, HANGMAN_OWNER, eHangman[HANGMAN_ID])
    engfunc(EngFunc_SetOrigin, id, eHangman[HANGMAN_ORIGIN_VIEW])
    set_pev(id, pev_v_angle, eHangman[HANGMAN_ANGLES_VIEW])
    set_pev(id, pev_angles, eHangman[HANGMAN_ANGLES_VIEW])
    set_pev(id, pev_effects, pev(id, pev_effects) | EF_NODRAW)

    hangmanStrip(id)
    ExecuteHamB(Ham_Killed, id, id, GIB_NEVER)
    set_pev(id, pev_iuser1, OBS_ROAMING)
    set_pev(id, pev_iuser2, 0)

    if ( g_eSettings[SETTING_WRITE_MESSAGE_ON_DEATH] )
        hangmanMessage(id, bForced)

    if ( g_eSettings[SETTING_PLAY_SOUND_ON_DEATH] )
        for ( new i = 1; i <= g_iMaxPlayers; i ++ )
            hangmanSound(i, SOUND_HANGMAN)
}

stock hangmanBar(id, iDuration)
{
    message_begin_f(MSG_ONE_UNRELIABLE, g_iBarTime, .player = id)
    write_short(iDuration)
    message_end()
}

stock hangmanSelect(eHangman[HANGMAN], iAction)
{
    new iRenderColor[3]
    if ( iAction == TARGET_SELECT )
    {
        if ( eHangman[HANGMAN_FLAGS] & FLAG_ACTIVE )    { iRenderColor[0] = g_iColorActive[0];    iRenderColor[1] = g_iColorActive[1];    iRenderColor[2] = g_iColorActive[2]; }
        else                                            { iRenderColor[0] = g_iColorInactive[0];  iRenderColor[1] = g_iColorInactive[1];  iRenderColor[2] = g_iColorInactive[2]; }

        set_ent_rendering(eHangman[HANGMAN_ID], kRenderFxGlowShell, iRenderColor[0], iRenderColor[1], iRenderColor[2], kRenderTransAlpha, 16)
        if ( pev_valid(eHangman[HANGMAN_CORPSE]) )
            set_ent_rendering(eHangman[HANGMAN_CORPSE], kRenderFxGlowShell, iRenderColor[0], iRenderColor[1], iRenderColor[2], kRenderTransAlpha, 16)
    }
    else if ( iAction == TARGET_GHOST )
    {
        set_ent_rendering(eHangman[HANGMAN_ID], kRenderFxNone, 255, 255, 255, kRenderTransAlpha, g_eSettings[SETTING_GHOST_ALPHA])
        if ( pev_valid(eHangman[HANGMAN_CORPSE]) )
            set_ent_rendering(eHangman[HANGMAN_CORPSE], kRenderFxNone, 255, 255, 255, kRenderTransAlpha, g_eSettings[SETTING_GHOST_ALPHA])
    }
    else if ( iAction == TARGET_HIDE )
    {
        set_ent_rendering(eHangman[HANGMAN_ID], kRenderFxNone, 255, 255, 255, kRenderTransAlpha, 0)
        if ( pev_valid(eHangman[HANGMAN_CORPSE]) )
            set_ent_rendering(eHangman[HANGMAN_CORPSE], kRenderFxNone, 255, 255, 255, kRenderTransAlpha, 0)
    }
    else if ( iAction == TARGET_CLEAR )
    {
        set_ent_rendering(eHangman[HANGMAN_ID], kRenderFxNone, 255, 255, 255, kRenderNormal, 255)
        if ( pev_valid(eHangman[HANGMAN_CORPSE]) )
            set_ent_rendering(eHangman[HANGMAN_CORPSE], kRenderFxNone, 255, 255, 255, kRenderNormal, 255)
    }
}

stock hangmanMessage(id, bool:bForced = false)
{
    new szName[MAX_NAME_LENGTH], szMessage[128]
    get_user_name(id, szName, charsmax(szName))

    if ( bForced )
        ArrayGetString(g_eSettings[SETTING_DEFAULT_MESSAGE_FORCED], random(ArraySize(g_eSettings[SETTING_DEFAULT_MESSAGE_FORCED])), szMessage, charsmax(szMessage))
    else
        ArrayGetString(g_eSettings[SETTING_DEFAULT_MESSAGE], random(ArraySize(g_eSettings[SETTING_DEFAULT_MESSAGE])), szMessage, charsmax(szMessage))

    set_hudmessage(g_eSettings[SETTING_HUD_COLOR][0], g_eSettings[SETTING_HUD_COLOR][1], g_eSettings[SETTING_HUD_COLOR][2], g_eSettings[SETTING_HUD_X], g_iHudCurrentY,
    g_eSettings[SETTING_HUD_EFFECT], g_eSettings[SETTING_HUD_FXTIME], g_eSettings[SETTING_HUD_HOLDTIME], g_eSettings[SETTING_HUD_FADEIN], g_eSettings[SETTING_HUD_FADEOUT])
    show_hudmessage(0, "%s%s", szName, szMessage)
    g_iHudCurrentY += 0.025
    if ( g_iHudCurrentY >= 0.7 )
        g_iHudCurrentY = g_eSettings[SETTING_HUD_Y]
}

stock hangmanSound(iEnt, iSound, bool:bPlayer = true)
{
    new szSample[64]
    switch( iSound )
    {
        case SOUND_MENU_NAV:    copy(szSample, charsmax(szSample), SOUND_NAV)
        case SOUND_MENU_REMOVE: copy(szSample, charsmax(szSample), SOUND_REMOVE)
        case SOUND_MENU_ALERT:  copy(szSample, charsmax(szSample), SOUND_ALERT)
        case SOUND_HANGMAN:     ArrayGetString(g_eSettings[SETTING_DEFAULT_SOUND], random(ArraySize(g_eSettings[SETTING_DEFAULT_SOUND])), szSample, charsmax(szSample))
    }

    if ( bPlayer )
        client_cmd(iEnt, "spk %s", szSample)
    else
        engfunc(EngFunc_EmitSound, iEnt, CHAN_VOICE, szSample, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
}

stock hangmanReset()
{
    new eHangman[HANGMAN]
    for ( new i = 0; i < g_iHangman; i ++ )
    {
        ArrayGetArray(g_aHangman, i, eHangman)
        eHangman[HANGMAN_NEXT_ACTIVE] = 0.0
        ArraySetArray(g_aHangman, i, eHangman)
    }

    for ( new id = 1; id <= g_iMaxPlayers; id ++ )
    {
        g_ePlayerData[id][PDATA_HANGMAN_ID] = 0
        g_ePlayerData[id][PDATA_NEXT_HANG] = 0.0
        g_ePlayerData[id][PDATA_NEXT_CHECK] = 0.0
    }
}

stock hangmanGet(eHangman[HANGMAN], iEnt)
{
    if ( !isHangman(iEnt) )
        return -1

    new iItem
    iItem = pev(iEnt, HANGMAN_ARRAY_ITEM)
    if ( iItem < 0 || iItem >= g_iHangman )
        return -1

    ArrayGetArray(g_aHangman, iItem, eHangman)
    return iItem
}

stock bool:isHangman(iEnt)
{
    return pev_valid(iEnt) && pev(iEnt, pev_impulse) == HANGMAN_KEY
}

stock hangmanKill(iEnt)
{
    if ( pev_valid(iEnt) )
        set_pev(iEnt, pev_flags, pev(iEnt, pev_flags) | FL_KILLME)
}

stock parseSetting(iType, szValue[], iValueLen, any:aOutput[], iOutputLength)
{
    switch ( iType )
    {
        case DTYPE_INT:
        {
            new szTok[MAX_VALUE_LENGTH], szTmp[MAX_VALUE_LENGTH], iCounter
            copy(szTmp, charsmax(szTmp), szValue)

            strtok(szTmp, szTok, charsmax(szTok), szTmp, charsmax(szTmp), ' ')
            trim(szTok)
            while ( szTok[0] )
            {
                aOutput[iCounter ++] = str_to_num(szTok)

                strtok(szTmp, szTok, charsmax(szTok), szTmp, charsmax(szTmp), ' ')
                trim(szTok)
            }
        }
        case DTYPE_FLOAT:
        {
            new szTok[MAX_VALUE_LENGTH], szTmp[MAX_VALUE_LENGTH], iCounter
            copy(szTmp, charsmax(szTmp), szValue)

            strtok(szTmp, szTok, charsmax(szTok), szTmp, charsmax(szTmp), ' ')
            trim(szTok)
            while ( szTok[0] )
            {
                aOutput[iCounter ++] = str_to_float(szTok)

                strtok(szTmp, szTok, charsmax(szTok), szTmp, charsmax(szTmp), ' ')
                trim(szTok)
            }
        }
        case DTYPE_FLAGS:
        {
            aOutput[0] = read_flags(szValue)
        }
        case DTYPE_ARRAY_STRING:
        {
            replace_all(szValue, iValueLen, "^"", " ")
            replace_all(szValue, iValueLen, "^^n", "^n")
            ArrayPushString(aOutput[0], szValue)
        }
        case DTYPE_ARRAY_SOUND:
        {
            ArrayPushString(aOutput[0], szValue)
            if ( !g_bFileWasRead ) precache_sound(szValue)
        }
        case DTYPE_STRING_MODEL:
        {
            copy(aOutput, iOutputLength, szValue)
            if ( !g_bFileWasRead ) precache_model(szValue)
        }
        case DTYPE_STRING_SOUND:
        {
            copy(aOutput, iOutputLength, szValue)
            if ( !g_bFileWasRead ) precache_sound(szValue)
        }
        case DTYPE_STRING_MODEL_ID:
        {
            if ( !g_bFileWasRead )
                aOutput[0] = precache_model(szValue)
        }
    }
}

public CorpseGore_CanGib(iEnt, iOffset[1])
{
    new eHangman[HANGMAN], iItem
    if ( (iItem = hangmanGet(eHangman, pev(iEnt, HANGMAN_OWNER))) == -1 )
        return PLUGIN_CONTINUE

    iOffset[0] = 32
    if ( !g_eSettings[SETTING_CORPSE_CAN_GIB] )
        return PLUGIN_HANDLED

    eHangman[HANGMAN_NEXT_ACTIVE] = 0.0
    ArraySetArray(g_aHangman, iItem, eHangman)
    return PLUGIN_CONTINUE
}

stock EnableAction(id)
{
    if ( !g_ePlayerData[id][PDATA_HANGMAN_ACTION] )
    {
        new eHangman[HANGMAN]
        for ( new i = 0; i < g_iHangman; i ++ )
        {
            ArrayGetArray(g_aHangman, i, eHangman)
            if ( eHangman[HANGMAN_FLAGS] & FLAG_SHOW )
                continue

            hangmanSelect(eHangman, TARGET_GHOST)
        }

        g_ePlayerData[id][PDATA_HANGMAN_ACTION] = true
        if ( ++ g_iActivePlayers == 1 )
            EnableForward()
    }
}

stock DisableAction(id)
{
    if ( g_ePlayerData[id][PDATA_HANGMAN_ACTION] )
    {
        new eHangman[HANGMAN]
        for ( new i = 0; i < g_iHangman; i ++ )
        {
            ArrayGetArray(g_aHangman, i, eHangman)
            if ( eHangman[HANGMAN_FLAGS] & FLAG_SHOW )
                continue

            hangmanSelect(eHangman, TARGET_HIDE)
        }

        g_ePlayerData[id][PDATA_HANGMAN_ACTION] = false
        if ( -- g_iActivePlayers == 0 )
            DisableForward()
    }
}

stock EnableForward()
{
    EnableHamForward(g_iFwdPreThink)
}

stock DisableForward()
{
    DisableHamForward(g_iFwdPreThink)
}

stock EnableHangman()
{
    g_iFwdEmitSound = register_forward(FM_EmitSound, "fwdEmitSound")
    EnableHamForward(g_iFwdUse)
    EnableHamForward(g_iFwdObjectCaps)
}

stock DisableHangman()
{
    unregister_forward(FM_EmitSound, g_iFwdEmitSound)
    DisableHamForward(g_iFwdUse)
    DisableHamForward(g_iFwdObjectCaps)
}

stock LogConfigError(const iLine, const szText[], any:...)
{
    new szError[MAX_PLATFORM_PATH_LENGTH]
    vformat(szError, charsmax(szError), szText, 3)

    log_to_file(ERROR_FILE, "^nLine %d: %s", iLine, szError)
}