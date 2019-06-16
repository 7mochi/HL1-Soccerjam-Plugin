/*
	SoccerJam por FlyingCat
    
    Informacion:
    1. Jugabilidad:
        Este modo de juego consiste en 2 equipos enfrentandose por ser
        el primero en llegar a 15 goles (Configurable). Cuando entras al servidor tu
        comienzas con 0 mejoras. Obtienes experiencia a través de distintos
        esfuerzos para mejorar tu personaje y convertirlo en un mejor
        jugador de futbol. (Aun no disponible) Puedes matar a tus oponentes, marcar goles desde
        distancias increíbles, robar el balón, ayudar a tus compañeros de
        equipos para lograr hacer un gol.
        Este plugin ha sido inspirado en el SoccerJam del CS 1.6.
        Link del plugin de CS 1.6: https://forums.alliedmods.net/showthread.php?t=41447

        Los controles son sencillos de aprender. Todas las teclas son las
        predeterminadas. Si tienes mas dudas, escribe /help cuando estes
        en el juego y lee el mensaje de ayuda para aprender todo sobre el 
        juego.
    
    2. Mejoras: (Aun no disponible)
        - Resistencia/Stamina: Incrementa la vida.
        - Fuerza/Strength: Incrementa la fuerza de tiro de la pelota.
        - AgiliEntityPlayerad/Agility: Incrementa la velocidad al correr.
        - Destreza/Dexterity: Aumenta la oportunidad de atrapar la pelota cuando
          alguien lo patea.
        - Power Play/Esfuerzo de equipo: Incrementa la Fuerza y Agilidad. Este es
          producido cuando pasas la pelota a 3 o mas jugadores de tu equipo. 
          Mientras mas pases la pelota mas PP ganarás y la pelota se encenderá de
          fuego.

    3. Instalacion:
    3.1. Inslalacion del plugin:
        - Descargar hl_soccerjam.rar.
        - De la carpeta plugins hl_soccerjam.amxx y ponerlo dentro de la carpeta
        addons/amxmodx/plugins. 
        - En caso de que desees compilarlo por ti mismo descargar:
        hl_soccerjam_scripting.rar | Aca estarán los includes necesarios para la
        compilacion del plugin
        - Abrir el fichero plugins.ini ubicado dentro de addons/amxmodx/config
        y agregar al final de todo el fichero hl_soccerjam.amxx y guardar los
        cambios.
        - Luego pasar al paso 3.2

    3.2 Instalacion de recursos:
        - Descargar el archivo comprimido hl_soccerjam_resources.rar y extraerlo
        todo dentro de valve
        - Por ultimo, iniciar el servidor y a jugar.

    5. Agradecimientos:
        - OneEyed: Por su SoccerJam para CS 1.6
        - Gabe Iggy: Sistema de rondas
        - TheHirowe: Beta Tester
        - Frank Lee: Beta Tester
        - K3NS4N: Beta Tester
    
    Contacto: flyingcatdm@gmail.com
*/

// **************************************************************************
// ***************************** CUSTOMIZACION ******************************
// **************************************************************************

// --------------------------------- Models ---------------------------------
#define MDL_BALL            "models/hlsoccerjam/ball.mdl"
#define MDL_GOALNET         "models/hlsoccerjam/chick.mdl"
#define MDL_TEAM_A          "peruano"
#define MDL_TEAM_B          "germany"
#define MDL_MASCOT_TEAM_A   "models/kingpin.mdl"
#define MDL_MASCOT_TEAM_B   "models/garg.mdl"

// --------------------------------- Sonidos --------------------------------
#define SND_BALL_BOUNCE     "hlsoccerjam/bounce.wav"
#define SND_BALL_KICKED     "hlsoccerjam/kicked.wav"
#define SND_BALL_PICKED_UP  "hlsoccerjam/gotball.wav"
#define SND_GOAL_SCORED     "hlsoccerjam/distress.wav"
#define SND_ROUND_START     "hlsoccerjam/prepare.wav"

// --------------------------------- Colores --------------------------------
#define CLR_TEAM_A_RED      250
#define CLR_TEAM_A_GREEN    10
#define CLR_TEAM_A_BLUE     10

#define CLR_TEAM_B_RED      10
#define CLR_TEAM_B_GREEN    10
#define CLR_TEAM_B_BLUE     250

#define CLR_HUD_MATCH_RED   10
#define CLR_HUD_MATCH_GREEN 250
#define CLR_HUD_MATCH_BLUE  10

// ---------------------------------- Otros ---------------------------------
#define TEAMNAME_TEAM_A     "Peru"
#define TEAMNAME_TEAM_B     "Alemania"
#define DIST_BTW_PLYR_BALL  55.0
#define FRAGS_PER_GOAL      10
#define GOALS_NEEDED_WIN    10
#define GOALS_DISTANCE_SAFE 650
#define MAX_GOALS           10

// **************************************************************************
// ************************ FIN DE CUSTOMIZACION ****************************
// ****************** No modificar nada a partir de aqui ********************
// **************************************************************************

#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fun>
#include <hamsandwich>
#include <hlstocks>

#define PLUGIN_NAME		"SoccerJam"
#define PLUGIN_VER		"1.0b"
#define PLUGIN_AUTHOR	"FlyingCat"

#define SPR_FIRE        "sprites/shockwave.spr"
#define SPR_SMOKE       "sprites/steam1.spr"
#define SPR_BEAM        "sprites/lgtning.spr"

// PDatas
const m_afButtonPressed  =   246;
const m_afButtonReleased =   247;

#pragma semicolon 1

// TaskID
enum (+=150) {
	TASK_SENDVICTIMTOSPEC = 6966,
	TASK_ROUND_CHECK,
	TASK_FREEZE_TIME,
	TASK_ROUND_TIME,
	TASK_SPAWN_POST,
	TASK_ROUND_END,
	TASK_SPEC_ON_JOIN,
	TASK_UNFREEZE,
    TASK_STATUS_MATCH,
    TASK_NET_TEAM
};

// Game team master
#define SJ_GTM_TEAM_A           1
#define SJ_GTM_TEAM_B           2

// Entidades a limpiar
new const gClearFieldEntsClass[][] = {
	"bolt",
	"monster_snark",
	"monster_satchel",
	"monster_tripmine",
	"beam",
	"weaponbox",
};

// Rebote realista
new const gEntitiesTouchWorld[][] = {
    "worldspawn",
    "func_wall",
    "func_door",
    "func_door_rotating",
    "func_wall_toggle",
    "func_breakable",
    "Blocker"
};

// Classnames
new const INFO_SJ_PLAYER_TEAM_A[] = "info_player_start";
new const INFO_SJ_PLAYER_TEAM_B[] = "info_player_deathmatch";
new const INFO_SJ_GOAL_NET[] = "soccerjam_goalnet";
new const INFO_SJ_BALL[] = "info_sj_ball";
new const INFO_SJ_BALL_SPAWN[] = "soccerjam_ballspawn";
new const INFO_SJ_MASCOT[] = "mascot";

// Color del glow de los jugadores por equipo
new gSJTeamColors[][] = {
    {0, 0, 0}, 
    {CLR_TEAM_A_RED, CLR_TEAM_A_GREEN, CLR_TEAM_A_BLUE}, 
    {CLR_TEAM_B_RED, CLR_TEAM_B_GREEN, CLR_TEAM_B_BLUE}
};

// Nombre de cada equipo
new gSJTeamNames[][] = {
    "",
    TEAMNAME_TEAM_A,
    TEAMNAME_TEAM_B,
    ""
};

// Model de la mascota de cada equipo (Encargados de matar al que entre al area)
new gSJTeamMascots[][] = {
    "",
    MDL_MASCOT_TEAM_A,
    MDL_MASCOT_TEAM_B,
};

// Contador de goles
new gSJGoalsCounter[] = {
    0,
    0, // Team A
    0, // Team B,
    0
};

// mp_teamlist "teamA;teamB"
new gSJOptimalTeam[32];

// Sistema de rondas
new gPlayerHasJoined[MAX_PLAYERS + 1];
new gCvarSJRoundTime, gCvarSJFreezeTime;
new gRoundStarted;
new gRoundTime;
new gRoundFreezeTime;
new gSJGoalEnt[3];

// Estado de la partida
new gSJMatchHUDSync;
new gSJRoundTimeHUDSync;
new gSJStatusMessage[128] = "";

// Lista de jugadores
new gPlayers[MAX_PLAYERS];

// Contadores de jugadores
new gNumPlayers;
new gNumTeamA;
new gNumTeamB;

// Estado del jugador
new gPlayerStatus[MAX_PLAYERS + 1];

// Pelota de futbol
new Float:gSJIdkOrigin[3];
new Float:gSJIdkVelocity[3];
new Float:gSJBallSpawnOrigin[3];
new gSJDistanceOrigRecorder[2][3];
new gSJBall;
new gSJBallOwner = 0;
new gSJBallKicker = 0;
new gSJBallisLosed = 0;
new gSJBallTeamTemp, gSJBallOwnNickTemp[64];
new gSJGoalHasBeenScored = 0;

// Mascotas
new gSJMascots[3];
new Float:gSJMascotsSpawnOrigins[3];
new Float:gSJMascotsSpawnAngles[3];

// Sprites del efecto al meter gol
new gSJFireSprite;
new gSJSmokeSprite;
new gSJBeamSprite;

public plugin_init() {
    register_plugin(PLUGIN_NAME, PLUGIN_VER, PLUGIN_AUTHOR); 

    // Registrando Cvars
    gCvarSJRoundTime = create_cvar("sj_round_time", "240");
    gCvarSJFreezeTime = create_cvar("sj_round_freeze_time", "5");

    gSJMatchHUDSync = CreateHudSyncObj();
    gSJRoundTimeHUDSync = CreateHudSyncObj();
}

public plugin_precache() {
    precache_model(MDL_BALL);
    precache_model(MDL_GOALNET);

    precache_sound(SND_BALL_PICKED_UP);
    precache_sound(SND_BALL_BOUNCE);
    precache_sound(SND_BALL_KICKED);
    precache_sound(SND_BALL_PICKED_UP);
    precache_sound(SND_GOAL_SCORED);
    precache_sound(SND_ROUND_START);

    for (new i = 1; i < (sizeof gSJTeamMascots); i++) {
        precache_model(gSJTeamMascots[i]);
    }

    gSJFireSprite = precache_model(SPR_FIRE);
    gSJSmokeSprite = precache_model(SPR_SMOKE);
    gSJBeamSprite = precache_model(SPR_BEAM);
    
    new model[128];
    formatex(model, charsmax(model), "models/player/%s/%s.mdl", MDL_TEAM_A, MDL_TEAM_A);
    precache_model(model);
    formatex(model, charsmax(model), "models/player/%s/%s.mdl", MDL_TEAM_B, MDL_TEAM_B);
    precache_model(model);
}

public plugin_cfg() {
    new buff[32];
    get_cvar_string("mp_teamlist", buff, charsmax(buff));
    formatex(gSJOptimalTeam, charsmax(gSJOptimalTeam), "%s;%s", MDL_TEAM_A, MDL_TEAM_B);
    if(!equali(buff, gSJOptimalTeam)) {
        server_print("ERROR: mp_teamlist no es '%s;%s'. Este modo de juego necesita esta teamlist para funcionar.",
                        MDL_TEAM_A, MDL_TEAM_B);
        set_fail_state("mp_teamlist no es '%s;%s'", MDL_TEAM_A, MDL_TEAM_B);
        return;
    }

    createGoalNets();

    register_forward(FM_GetGameDescription, "gameDesc");
    register_forward(FM_CmdStart, "fwdActionWithBall");

    register_touch(INFO_SJ_BALL, "player", "fwdTouchPlayer");
    register_touch(INFO_SJ_BALL, INFO_SJ_GOAL_NET, "fwdTouchNet");
    
    for (new i = 0; i < (sizeof gEntitiesTouchWorld); i++) {
        register_touch(INFO_SJ_BALL, gEntitiesTouchWorld[i], "fwdTouchWorld");
    }

    register_touch(INFO_SJ_BALL, "Blocker", "fwdTouchBlocker");

    register_think(INFO_SJ_BALL, "ballThink");
    register_think(INFO_SJ_MASCOT, "mascotThink");

    RegisterHam(Ham_Spawn, "player", "playerSpawnPre");
    RegisterHam(Ham_Spawn, "player", "playerSpawnPost", 1);
        
    register_clcmd("spectate", "cmdSpectate");
    register_clcmd("jointeam", "cmdJoinTeam");
    register_clcmd("changeteam", "cmdChangeTeam");

    removeNotSJSpawns();

    createGameTeamMaster("team_A", SJ_GTM_TEAM_A);
    createGameTeamMaster("team_B", SJ_GTM_TEAM_B);

    set_task(1.0, "roundChecker", TASK_ROUND_CHECK, "", 0, "b");
}

createGoalNets() {
    new endZone;
    new Float:origin[3];
    new Float:minBox[3], Float:maxBox[3];

    for (new x=1; x < 3; x++) {
        endZone = create_entity("info_target");
        if (endZone) {
            entity_set_string(endZone, EV_SZ_classname, INFO_SJ_GOAL_NET);
            entity_set_model(endZone, MDL_GOALNET);
            entity_set_int(endZone, EV_INT_solid, SOLID_BBOX);
            entity_set_int(endZone, EV_INT_movetype, MOVETYPE_NONE);

            minBox[0] = -25.0;
            minBox[1] = -145.0;
            minBox[2] = -36.0;
            maxBox[0] =  25.0;
            maxBox[1] =  145.0;
            maxBox[2] =  70.0;

            entity_set_size(endZone, minBox, maxBox);

            switch(x) {
                case 1: {
					origin[0] = 2110.0;
					origin[1] = 0.0;
					origin[2] = 1604.0;
				}
				case 2: {
					origin[0] = -2550.0;
					origin[1] = 0.0;
					origin[2] = 1604.0;
				}
            }
            entity_set_origin(endZone, origin);
            entity_set_int(endZone, EV_INT_team, x);
            set_entity_visibility(endZone, 0);
            gSJGoalEnt[x] = endZone;
        }
    }
}

public client_putinserver(iEntityPlayer) {
    if (!gRoundStarted) {
        gPlayerStatus[iEntityPlayer] = 1;
    } else {
        gPlayerStatus[iEntityPlayer] = 0;
    }
    set_task(0.1, "taskPutInServer", iEntityPlayer);
}

public taskPutInServer(iEntityPlayer) {
    taskShowMatchStatus(iEntityPlayer + TASK_STATUS_MATCH);
    hl_set_teamnames(iEntityPlayer, TEAMNAME_TEAM_A, TEAMNAME_TEAM_B);
}

public taskShowMatchStatus(taskID) {
    new iEntityPlayer = taskID - TASK_STATUS_MATCH;
    showMatchStatus(iEntityPlayer);
    set_task(0.5, "taskShowMatchStatus", taskID);
}

stock showMatchStatus(iEntityPlayer) {
    if (!is_user_connected(iEntityPlayer) || is_user_bot(iEntityPlayer))
        return;
    
    if (gSJBallOwner == 0 && !gSJBallisLosed && !gSJGoalHasBeenScored) {
        formatex(gSJStatusMessage, charsmax(gSJStatusMessage), "%s v%s^n%s^n[%s] %d | %d [%s]", PLUGIN_NAME, PLUGIN_VER, "Nadie tiene la pelota.", 
                    gSJTeamNames[SJ_GTM_TEAM_A], gSJGoalsCounter[SJ_GTM_TEAM_A], gSJGoalsCounter[SJ_GTM_TEAM_B], gSJTeamNames[SJ_GTM_TEAM_B]);
    } else if (gSJBallOwner == 0 && gSJBallisLosed == 0 && gSJGoalHasBeenScored == 1) {
        new playerNickname[64];
        get_user_name(gSJBallKicker, playerNickname, charsmax(playerNickname));
        formatex(gSJStatusMessage, charsmax(gSJStatusMessage), "%s v%s^n%s (%s) metio alto gol^n[%s] %d | %d [%s]", PLUGIN_NAME, PLUGIN_VER, 
                    playerNickname, gSJTeamNames[gSJBallTeamTemp], gSJTeamNames[SJ_GTM_TEAM_A], gSJGoalsCounter[SJ_GTM_TEAM_A], gSJGoalsCounter[SJ_GTM_TEAM_B], 
                    gSJTeamNames[SJ_GTM_TEAM_B]);
    } else if (gSJBallOwner == 0 && gSJBallisLosed && !gSJGoalHasBeenScored) {
        formatex(gSJStatusMessage, charsmax(gSJStatusMessage), "%s v%s^n%s (%s) perdio la pelota^n[%s] %d | %d [%s]", PLUGIN_NAME, PLUGIN_VER, 
                    gSJBallOwnNickTemp, gSJTeamNames[gSJBallTeamTemp], gSJTeamNames[SJ_GTM_TEAM_A], gSJGoalsCounter[SJ_GTM_TEAM_A], gSJGoalsCounter[SJ_GTM_TEAM_B], 
                    gSJTeamNames[SJ_GTM_TEAM_B]);
    } else if (gSJBallOwner > 0) {
        new playerNickname[64];
        get_user_name(gSJBallOwner, playerNickname, charsmax(playerNickname));
        formatex(gSJStatusMessage, charsmax(gSJStatusMessage), "%s v%s^n%s (%s) tiene la pelota^n[%s] %d | %d [%s]", PLUGIN_NAME, PLUGIN_VER, 
                    playerNickname, gSJTeamNames[hl_get_user_team(gSJBallOwner)], gSJTeamNames[SJ_GTM_TEAM_A], gSJGoalsCounter[SJ_GTM_TEAM_A], 
                    gSJGoalsCounter[SJ_GTM_TEAM_B], gSJTeamNames[SJ_GTM_TEAM_B]);
        
    }
    set_hudmessage(CLR_HUD_MATCH_RED, CLR_HUD_MATCH_GREEN, CLR_HUD_MATCH_BLUE, 0.01, 0.1, 
                    0, 6.0, 120.0, 0.0, 0.0);
    ShowSyncHudMsg(iEntityPlayer, gSJMatchHUDSync, "%s", gSJStatusMessage);
}

public client_disconnected(iEntityPlayer) {
    gPlayerHasJoined[iEntityPlayer] = 0;
    gPlayerStatus[iEntityPlayer] = 0;
    remove_task(iEntityPlayer + TASK_STATUS_MATCH);
    remove_task(iEntityPlayer + TASK_SPEC_ON_JOIN);
    if (!task_exists(TASK_ROUND_END) && !task_exists(TASK_FREEZE_TIME)) {
        sjGetPlayersPerTeam(gNumTeamA, SJ_GTM_TEAM_A);
        sjGetPlayersPerTeam(gNumTeamB, SJ_GTM_TEAM_B);
        if (gNumTeamA < 1 || gNumTeamB < 1) {
            finishRound(3);
        }
    }
}

public gameDesc() { 
    new gamename[32];
    formatex(gamename, charsmax(gamename), "%s v%s", PLUGIN_NAME, PLUGIN_VER);
    forward_return(FMV_STRING, gamename); 
    return FMRES_SUPERCEDE; 
}

public fwdTouchPlayer(iEntityBall, iEntityPlayer) {
    if (!is_user_alive(iEntityPlayer))
        return PLUGIN_HANDLED;

    // Si la pelota no tiene "duenio"
    if (gSJBallOwner == 0) {
        catchBall(iEntityPlayer, iEntityBall);
    }  
    return PLUGIN_CONTINUE;
}

public fwdTouchNet(iEntityBall, iEntityNet) {
    if (!is_user_connected(gSJBallKicker)) {
        return;
    }
    new goalEnt = gSJGoalEnt[hl_get_user_team(gSJBallKicker)];
    // Workaround
    if (iEntityNet == goalEnt) {
        new playerNickname[64];
        new Float:netOrigin[3];
        new netOrigin2[3];
        entity_get_vector(iEntityBall, EV_VEC_origin, netOrigin);
        for (new x = 0; x < 3; x++) {
            netOrigin2[x] = floatround(netOrigin[x]);
        }
        flameWave(netOrigin2);
        get_user_name(gSJBallKicker, playerNickname, charsmax(playerNickname));
        hl_set_user_frags(gSJBallKicker, (get_user_frags(gSJBallKicker) + (FRAGS_PER_GOAL)));
        gSJGoalsCounter[hl_get_user_team(gSJBallKicker)]++;
        gSJGoalHasBeenScored = 1;
        get_user_name(gSJBallKicker, gSJBallOwnNickTemp, charsmax(gSJBallOwnNickTemp));
        playWav(0, SND_GOAL_SCORED);
        remove_entity(gSJBall);
        finishRound(gSJBallTeamTemp);
    }
}

public fwdTouchWorld() {
    if (get_speed(gSJBall) > 10) {
        new Float:velocity[3];
        entity_get_vector(gSJBall, EV_VEC_velocity, velocity);
        velocity[0] = (velocity[0] * 0.85);
        velocity[1] = (velocity[1] * 0.85);
        velocity[2] = (velocity[2] * 0.85);
        entity_set_vector(gSJBall, EV_VEC_velocity, velocity);
        emit_sound(gSJBall, CHAN_ITEM, SND_BALL_BOUNCE, 1.0, ATTN_NORM, 0, PITCH_NORM);
    }
    return PLUGIN_HANDLED;
}

public fwdTouchBlocker(iEntityBall, blocker) {
	new Float:origin[3] = {2234.0, 1614.0, 1604.0};
	entity_set_origin(iEntityBall, origin);
}

public ballThink(iEntityBall) {
    // Si tiene duenio
    if (gSJBallOwner > 0) {
        gSJBallTeamTemp = hl_get_user_team(gSJBallOwner);
        if (!is_user_alive(gSJBallOwner)) {
            // Perdio la pelota al morir
            removeGlowPlayer(gSJBallKicker);
            get_user_name(gSJBallOwner, gSJBallOwnNickTemp, charsmax(gSJBallOwnNickTemp));
            gSJBallOwner = 0;
            gSJBallisLosed = 1;
            gSJBallKicker = 0;
            gSJGoalHasBeenScored = 0;

            gSJIdkOrigin[2] += 5;
            entity_set_origin(gSJBall, gSJIdkOrigin);

            new Float:velocity[3];
            for (new x = 0; x < 3; x++) {
                velocity[x] = 1.0;
            }
            entity_set_vector(gSJBall, EV_VEC_velocity, velocity);
            entity_set_float(iEntityBall, EV_FL_nextthink, halflife_time() + 0.05);
            return PLUGIN_HANDLED;
        }
        // Hacer que la pelota siga al que la toco
        ballInFront(gSJBallOwner, DIST_BTW_PLYR_BALL);
        for (new i = 0; i < 3; i++) {
            gSJIdkVelocity[i] = 0.0;
        }
        new flags = entity_get_int(gSJBallOwner, EV_INT_flags);
        if (flags & FL_DUCKING) {
            gSJIdkOrigin[2] -= 10;
        } else {
            gSJIdkOrigin[2] -= 30;
        }
        entity_set_vector(iEntityBall, EV_VEC_velocity, gSJIdkVelocity);
        entity_set_origin(iEntityBall, gSJIdkOrigin);
    }
    entity_set_float(iEntityBall, EV_FL_nextthink, halflife_time() + 0.05);
    return PLUGIN_HANDLED;
}

public catchBall(iEntityPlayer, iEntityBall) {
    gSJBallOwner = iEntityPlayer;
    gSJBallisLosed = 0;
    gSJBallKicker = 0;
    gSJGoalHasBeenScored = 0;
    //giveGlowToPlayer(iEntityPlayer);
    emit_sound(iEntityBall, CHAN_ITEM, SND_BALL_PICKED_UP, 1.0, ATTN_NORM, 0, PITCH_NORM);
}

public ballInFront(ballOwner, Float:dist) {
    new Float:nOrigin[3];
    new Float:vAngles[3];
    new Float:vReturn[3];

    entity_get_vector(gSJBall, EV_VEC_origin, gSJIdkOrigin);
    entity_get_vector(ballOwner, EV_VEC_origin, nOrigin);
    entity_get_vector(ballOwner, EV_VEC_v_angle, vAngles);

    vReturn[0] = floatcos(vAngles[1], degrees) * dist;
    vReturn[1] = floatsin(vAngles[1], degrees) * dist;

    vReturn[0] += nOrigin[0];
    vReturn[1] += nOrigin[1];

    gSJIdkOrigin[0] = vReturn[0];
    gSJIdkOrigin[1] = vReturn[1];
    gSJIdkOrigin[2] = nOrigin[2];
}

public giveGlowToPlayer(iEntityPlayer) {
    new team = hl_get_user_team(iEntityPlayer);
    set_rendering(iEntityPlayer, kRenderFxGlowShell, gSJTeamColors[team][0], gSJTeamColors[team][1], 
                gSJTeamColors[team][2], kRenderNormal, 255);
}

public removeGlowPlayer(iEntityPlayer) {
    set_rendering(iEntityPlayer, kRenderFxNone, gSJTeamColors[0][0], gSJTeamColors[0][1], 
                gSJTeamColors[0][2], kRenderNormal, 16);
}

public fwdActionWithBall(iEntityPlayer, handle) {
    if (!is_user_alive(iEntityPlayer))
        return FMRES_IGNORED;
    
    static oldButtons[33], buttons;
    buttons = get_uc(handle, UC_Buttons);
        
    if(buttons & IN_USE && ~oldButtons[iEntityPlayer] & IN_USE) {
        if (gSJBallOwner == iEntityPlayer) {
            kickBall(gSJBallOwner, 0);
        }
    }
    oldButtons[iEntityPlayer] = buttons;
    return FMRES_IGNORED;
}

public kickBall(iEntityPlayer, velType) {
    gSJBallKicker = iEntityPlayer;
    gSJBallisLosed = 0;
    ballInFront(iEntityPlayer, DIST_BTW_PLYR_BALL);
    gSJIdkOrigin[2] += 10;

    new Float:tempOrigin[3], Float:returned[3];
    new Float:dist2;

    entity_get_vector(iEntityPlayer, EV_VEC_origin, tempOrigin);
    new tempEnt = trace_line(iEntityPlayer, tempOrigin, gSJIdkOrigin, returned);

    dist2 = get_distance_f(gSJIdkOrigin, returned);

    if (point_contents(gSJIdkOrigin) != CONTENTS_EMPTY 
        || (!is_user_connected(tempEnt) && dist2)) {
            return PLUGIN_HANDLED;
    } else {
        new Float:ballF[3], Float:ballR[3], Float:ballL[3];
        new Float:ballB[3], Float:ballTR[3], Float:ballTL[3];
        new Float:ballBL[3], Float:ballBR[3];

        for (new x = 0; x < 3; x++) {
            ballF[x] = gSJIdkOrigin[x];
            ballR[x] = gSJIdkOrigin[x];
            ballL[x] = gSJIdkOrigin[x];
            ballB[x] = gSJIdkOrigin[x];
            ballTR[x] = gSJIdkOrigin[x];
            ballTL[x] = gSJIdkOrigin[x];
            ballBL[x] = gSJIdkOrigin[x];	
            ballBR[x] = gSJIdkOrigin[x];
        }

        for (new y=1; y <= 6; y++) {
            ballF[1] += 3.0;	
            ballB[1] -= 3.0;
            ballR[0] += 3.0;
            ballL[0] -= 3.0;
            ballTL[0] -= 3.0;
            ballTL[1] += 3.0;
            ballTR[0] += 3.0;
            ballTR[1] += 3.0;
            ballBL[0] -= 3.0;
            ballBL[1] -= 3.0;
            ballBR[0] += 3.0;
            ballBR[1] -= 3.0;

            if(point_contents(ballF) != CONTENTS_EMPTY || point_contents(ballR) != CONTENTS_EMPTY ||
			    point_contents(ballL) != CONTENTS_EMPTY || point_contents(ballB) != CONTENTS_EMPTY ||
			    point_contents(ballTR) != CONTENTS_EMPTY || point_contents(ballTL) != CONTENTS_EMPTY ||
			    point_contents(ballBL) != CONTENTS_EMPTY || point_contents(ballBR) != CONTENTS_EMPTY)
					return PLUGIN_HANDLED;
        }

        new ent = -1;
        gSJIdkOrigin[2] += 35.0;
        while ((ent = find_ent_in_sphere(ent, gSJIdkOrigin, 35.0)) != 0) {
            if (ent > MaxClients) {
                new classname[32];
                entity_get_string(ent, EV_SZ_classname, classname, charsmax(classname));
                if((contain(classname, "goalnet") != -1 || contain(classname, "func_") != -1) &&
					!equal(classname, "func_water") && !equal(classname, "func_illusionary"))
					return PLUGIN_HANDLED;
            }
        }
        gSJIdkOrigin[2] -= 35.0;

        new kickVel;
        if (!velType) {
            kickVel = random_num(100, 600);
        } else {
            kickVel = random_num(100, 600);
        }
        new Float:tempOrigin[3];
        entity_get_vector(iEntityPlayer, EV_VEC_origin, tempOrigin);
        for (new x = 0; x < 3; x++) {
            gSJDistanceOrigRecorder[0][x] = floatround(tempOrigin[x]);
        }
        velocity_by_aim(iEntityPlayer, kickVel, gSJIdkVelocity);
        for (new x = 0; x < 3; x++) {
            gSJDistanceOrigRecorder[0][x] = floatround(tempOrigin[x]);
        }
        gSJBallOwner = 0;
        entity_set_origin(gSJBall, gSJIdkOrigin);
        entity_set_vector(gSJBall, EV_VEC_velocity, gSJIdkVelocity);
        emit_sound(gSJBall, CHAN_ITEM, SND_BALL_KICKED, 1.0, ATTN_NORM, 0, PITCH_NORM);
        return PLUGIN_HANDLED;
    }
}

public mascotThink(iEntityMascot) {
    new team = entity_get_int(iEntityMascot, EV_INT_team);
    new inDist[32], inNum, chosen;
    new playerTeam, dist;
    for (new id = 1; id <= MaxClients; id++) {
        if (is_user_connected(id)) {
            playerTeam = hl_get_user_team(id);
            // Lo mismo que los arcos, workaround para hacerlo funcionar
            // porque soy un weon y no encuentro el error ._.XD
            if (playerTeam == team) {
                if (!chosen) {
                    dist = get_entity_distance(id, iEntityMascot);
                    if (dist < GOALS_DISTANCE_SAFE) {
                        // Workaround
                        if (id != gSJBallOwner) {
                            chosen = id;
                        } else {
                            inDist[inNum++] = id;
                        }
                    }
                }
            }
        }
    }
    if (!chosen) {
        new random = random_num(0, (inNum - 1));
        chosen = inDist[random];
    }
    if (chosen) {
        ripPlayer(chosen, iEntityMascot, team, (gSJBallOwner == chosen ? 230.0 : random_float(5.0, 15.0)));
    }
    entity_set_float(iEntityMascot, EV_FL_nextthink, halflife_time() + 1.0);
}

ripPlayer(id, mascot, team, Float:dmg) {
    new origin[3], Float:mascotOrigin[3], iMOrigin[3];
    get_user_origin(id, origin);
    entity_get_vector(mascot, EV_VEC_origin, mascotOrigin);
    for (new x = 0; x < 3; x++) {
        iMOrigin[x] = floatround(mascotOrigin[x]);
    }
    fakedamage(id, "Terminator", dmg, 1);
    new loc = (team == SJ_GTM_TEAM_A ? 100 : 140);
    message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
    write_byte(0);
    write_coord(iMOrigin[0]);
    write_coord(iMOrigin[1]);
    write_coord(iMOrigin[2] + loc);
    write_coord(origin[0]);
    write_coord(origin[1]);
    write_coord(origin[2]);
    write_short(gSJBeamSprite);
    write_byte(0);
    write_byte(0);
    write_byte(7);
    write_byte(120);
    write_byte(25);
    write_byte(250);
    write_byte(0);
    write_byte(0);
    write_byte(220);
    write_byte(1);
    message_end();
}

public playerSpawnPre(iEntityPlayer) {
    if (!gPlayerHasJoined[iEntityPlayer]) {
        return HAM_IGNORED;
    }
    
    if (task_exists(TASK_ROUND_TIME)) {
        if (!gPlayerStatus[iEntityPlayer]) {
            return HAM_SUPERCEDE;
        }
    }
    return HAM_IGNORED;
}

public playerSpawnPost(iEntityPlayer) {
    if (!gPlayerHasJoined[iEntityPlayer]) {
        gPlayerHasJoined[iEntityPlayer] = 1;
        if (gRoundStarted) {
            if (!gPlayerStatus[iEntityPlayer]) {
                set_task(0.1, "sendPlayerToSpecOnJoin", TASK_SPEC_ON_JOIN + iEntityPlayer);
                return;
            }
        }
    }
    set_task(0.1, "playerSpawnPostAfter", TASK_SPAWN_POST + iEntityPlayer);
}

public sendPlayerToSpecOnJoin(taskID) {
    new iEntityPlayer = taskID - TASK_SPEC_ON_JOIN;
    if (!task_exists(TASK_FREEZE_TIME)) {
        hl_set_user_spectator(iEntityPlayer, true);
    }
}

public playerSpawnPostAfter(taskID) {
    new iEntityPlayer = taskID - TASK_SPAWN_POST;
    if (is_user_alive(iEntityPlayer)) {
        if (!gRoundStarted) {
            freezePlayer(iEntityPlayer);
        }
        strip_user_weapons(iEntityPlayer);
        give_item(iEntityPlayer, "weapon_crowbar");
    }
}

public roundChecker(taskiEntityPlayer) {
    if (gSJGoalsCounter[SJ_GTM_TEAM_A] == MAX_GOALS || gSJGoalsCounter[SJ_GTM_TEAM_B] == MAX_GOALS) 
        startIntermissionMode();
    
    sjGetPlayersPerTeam(gNumTeamA, SJ_GTM_TEAM_A);
    sjGetPlayersPerTeam(gNumTeamB, SJ_GTM_TEAM_B);
    // Si hay menos de 1 jugador por equipo
    if (gNumTeamA < 1 || gNumTeamB < 1) {
        remove_entity_name(INFO_SJ_BALL);
        gSJBall = 0;
        gSJBallOwner = 0;
        gSJBallKicker = 0;

        remove_task(TASK_FREEZE_TIME);
        remove_task(TASK_ROUND_TIME);
        remove_task(TASK_SPAWN_POST);
        remove_task(TASK_ROUND_END);
        remove_task(TASK_SPEC_ON_JOIN);

        client_print(0, print_center, "No hay suficientes jugadores.");        
        // Si la ronda esta iniciada la terminamos
        if (gRoundStarted) {
            gRoundStarted = 0;
        }
    } else { // Pero si hay mas de 2 jugadores
        if (!task_exists(TASK_ROUND_END)) {
            // Si una ronda ya se inicio
            if (gRoundStarted) {
                gRoundTime -= 1;
                                
                new hud[125];
                new min = gRoundTime / 60;
                new hrs = min / 60;
                new sec = gRoundTime - min * 60;
                if (hrs) {
                    formatex(hud, charsmax(hud), "%d:%02d:%02d", hrs, min, sec);
                } else {
                    formatex(hud, charsmax(hud), "%d:%02d", min, sec);
                }

                // Colores dependiendo del tiempo
                new r, g, b;
                if (gRoundTime >= 120) { // Color verde
                    r = 0;
                    g = 255;
                    b = 0;
                } else if (gRoundTime >= 60) { // Color marron
                    r = 250;
                    b = 170;
                    b = 0;
                } else { // Color rojo
                    r = 255;
                    g = 50;
                    b = 50;
                }
                sjGetPlayers(gPlayers, gNumPlayers);
                for (new i = 0; i < gNumPlayers; i++) {
                    if (is_user_connected(gPlayers[i])) {
                        set_hudmessage(r, g, b, -1.0, 0.02, 0, 5.0, 5.0, 0.0, 0.0, 4);
                        ShowSyncHudMsg(gPlayers[i], gSJRoundTimeHUDSync, "Tiempo ronda: %s", hud);
                    }
                }
            } else {
                gRoundFreezeTime -= 1;
            }
        }
        
        if (!gRoundStarted && !task_exists(TASK_FREEZE_TIME)) {
            roundPreStart();
        }        
    }
}

public roundPreStart() {
    remove_entity_name(INFO_SJ_BALL);
    clearCorpses();
    clearField();
    gSJBallOwner = 0;
    gSJBallKicker = 0;
    gSJBallTeamTemp = 0;
    gSJBallisLosed = 0;
    gSJGoalHasBeenScored = 0;
    
    sjGetPlayers(gPlayers, gNumPlayers);
    for (new i = 0; i < gNumPlayers; i++) {
        gPlayerStatus[i] = 1;
    }
    spawnEntity(1, Float:gSJBallSpawnOrigin);
    remove_task(TASK_ROUND_END);
    remove_task(TASK_ROUND_TIME);
    
    playWav(0, SND_ROUND_START);
    for (new i = 0; i < gNumPlayers; i++) {
        if (hl_get_user_spectator(gPlayers[i])) {
            hl_set_user_spectator(gPlayers[i], bool:false);
        }
        hl_user_spawn(gPlayers[i]);
    }   
    gRoundFreezeTime = get_pcvar_num(gCvarSJFreezeTime);
    set_task(Float:float(get_pcvar_num(gCvarSJFreezeTime)), "roundPostStart", TASK_FREEZE_TIME);
}

public startIntermissionMode() {
    new ent = create_entity("game_end");
    if (is_valid_ent(ent)) {
        ExecuteHamB(Ham_Use, ent, 0, 0, 1.0, 0.0);
    }
}

stock clearCorpses() {
    new iEntity;
    while ((iEntity = find_ent_by_class(iEntity, "bodyque")))
        entity_set_origin(iEntity, Float:{4096.0, 4096.0, 4096.0});
}

stock clearField() {
    for (new i; i < sizeof gClearFieldEntsClass; i++) {
        remove_entity_name(gClearFieldEntsClass[i]);
    }
    new entiEntityPlayer;
    while ((entiEntityPlayer = find_ent_by_class(entiEntityPlayer, "rpg_rocket")))
        set_pev(entiEntityPlayer, pev_dmg, 0);
        
    entiEntityPlayer = 0;
    while ((entiEntityPlayer = find_ent_by_class(entiEntityPlayer, "grenade")))
        set_pev(entiEntityPlayer, pev_dmg, 0);
}

public roundPostStart() {
    sjGetPlayers(gPlayers, gNumPlayers);
    for (new i = 0; i < gNumPlayers; i++) {
        if (!is_user_alive(gPlayers[i]))
            hl_user_spawn(gPlayers[i]);
        
        set_task(0.2, "unfreezePlayer", TASK_UNFREEZE + gPlayers[i]);
    }
    gRoundStarted = 1;
    gRoundTime = get_pcvar_num(gCvarSJRoundTime);
    // Si termina el tiempo quiere decir que nadie metio gol en esta ronda
    set_task(Float:float(get_pcvar_num(gCvarSJRoundTime)), "roundTimeOut", TASK_ROUND_TIME);
}

public freezePlayer(iEntityPlayer) {
    entity_set_float(iEntityPlayer, EV_FL_maxspeed, -1.0);
}

public unfreezePlayer(taskiD) {
    new iEntity = taskiD - TASK_UNFREEZE;
    entity_set_float(iEntity, EV_FL_maxspeed, Float:float(get_cvar_num("sv_maxspeed")));
}

public roundTimeOut() {
    if (!task_exists(TASK_ROUND_END)) {
        finishRound(3);
    }
}

public finishRound(winCondition) {
    switch (winCondition) {
        // Equipo A mete gol
        case 1: {
            client_print(0, print_center, "Equipo %s metio gol", TEAMNAME_TEAM_A);
        }

        // Equipo B mete gol
        case 2: {
            client_print(0, print_center, "Equipo %s metio gol", TEAMNAME_TEAM_B);
        }

        default: {
            client_print(0, print_center, "Nadie metio gol");
        }
    }
    set_task(5.0, "roundEnd", TASK_ROUND_END);
}

public roundEnd(taskiEntityPlayer) {
    gRoundStarted = 0;
    roundPreStart();
}

public cmdSpectate(iEntityPlayer) {
	client_print(iEntityPlayer, print_console, "* You can't use this command.");
	return PLUGIN_HANDLED;
}

public cmdJoinTeam(iEntityPlayer) {
	client_print(iEntityPlayer, print_console, "* You can't use this command.");
	return PLUGIN_HANDLED;
}

public cmdChangeTeam(iEntityPlayer) {
	client_print(iEntityPlayer, print_console, "* You can't use this command.");
	return PLUGIN_HANDLED;
}

public spawnEntity(type, Float:origin[3]){
    new iEntity = create_entity("info_target");
    switch(type) {
        // Pelota de futbol
        case 1: {
            entity_set_string(iEntity, EV_SZ_classname, INFO_SJ_BALL);
            entity_set_vector(iEntity, EV_VEC_origin, origin);
            entity_set_model(iEntity, MDL_BALL);
            new Float:minBall[3];
            new Float:maxBall[3];
            minBall[0] = -15.0;
            minBall[1] = -15.0;
            minBall[2] = 0.0;
            maxBall[0] = 15.0;
            maxBall[1] = 15.0;
            maxBall[2] = 12.0;
            entity_set_size(iEntity, minBall, maxBall);            
            entity_set_int(iEntity, EV_INT_solid, SOLID_BBOX);
            entity_set_int(iEntity, EV_INT_movetype, MOVETYPE_BOUNCE);
            set_rendering(iEntity, kRenderFxGlowShell, random_num(50 , 255), random_num(50 , 255), 
                random_num(50 , 255), kRenderNormal, 255);
            entity_set_float(iEntity, EV_FL_renderamt, 1.0);
            drop_to_floor(iEntity);
            gSJBall = iEntity;
            entity_set_float(iEntity, EV_FL_nextthink, halflife_time() + 0.05);
        }
    }    
}

public pfn_keyvalue(iEntity) {
    new classname[32], key[32], value[32];
    copy_keyvalue(classname, charsmax(classname), key, charsmax(key), 
                    value, charsmax(value));

    new tempOrigins[3][10], team;
    new tempAngles[3][10];
    
    new Float:vector[3];
    strToVec(value, vector);
    static spawn;

    if (equal(classname, INFO_SJ_BALL_SPAWN)) {
        if (equal(key, "origin")) {
            parse(value, tempOrigins[0], 9, tempOrigins[1], 9, tempOrigins[2], 9);
            gSJBallSpawnOrigin[0] = floatstr(tempOrigins[0]);
            gSJBallSpawnOrigin[1] = floatstr(tempOrigins[1]);
            gSJBallSpawnOrigin[2] = floatstr(tempOrigins[2]);
            
        }
    } else if (equal(classname, INFO_SJ_PLAYER_TEAM_A)) { // info_player_start
        if (equal(key, "origin")) {
            spawn = create_entity(INFO_SJ_PLAYER_TEAM_B);
            entity_set_origin(spawn, vector);
            entity_set_string(spawn, EV_SZ_netname, "team_A");
        } else if (equal(key, "angles")) {
            entity_set_vector(spawn, EV_VEC_angles, vector);
        }
    } else if (equal(classname, INFO_SJ_PLAYER_TEAM_B)) { // Ya son info_player_deathmatch
        if (equal(key, "origin")) {
            spawn = create_entity(INFO_SJ_PLAYER_TEAM_B);
            entity_set_origin(spawn, vector);
            entity_set_string(spawn, EV_SZ_netname, "team_B");
        } else if (equal(key, "angles")) {
            entity_set_vector(spawn, EV_VEC_angles, vector);
            set_pev(spawn, pev_angles, vector);
        }
    } else if (equal(key, "classname") && (equal(classname, "func_wall") || equal(classname, INFO_SJ_GOAL_NET) 
                || equal(value, INFO_SJ_GOAL_NET))) {
        if (equal(key, "team")) {
            team = str_to_num(value);
            if (team == SJ_GTM_TEAM_A || team == SJ_GTM_TEAM_B) {
                gSJGoalEnt[team] = iEntity;
                set_task(1.0, "finalizeGoalNet", TASK_NET_TEAM);
            }
        }
    } else if (equal(classname, "soccerjam_mascot")) {
        if (equal(key, "team")) {
            team = str_to_num(value);
            createMascot(team);
        } else if (equal(key, "origin")) {
            parse(value, tempOrigins[0], 9, tempOrigins[1], 9, tempOrigins[2], 9);
            for (new x = 0; x < 3; x++) {
                gSJMascotsSpawnOrigins[x] = floatstr(tempOrigins[x]);
            }
        } else if (equal(key, "angles")) {
            parse(value, tempAngles[0], 9, tempAngles[1], 9, tempAngles[2], 9);
            for (new x = 0; x < 3; x++) {
                gSJMascotsSpawnAngles[x] = floatstr(tempAngles[x]);
            }
        }
    }
}

Float:strToVec(const string[], Float:vector[3]) {
	new arg[3][12];
	parse(string, arg[0], charsmax(arg[]), arg[1], charsmax(arg[]), arg[2], charsmax(arg[]));

	for (new i; i < sizeof arg; i++)
		vector[i] = str_to_float(arg[i]);
}

createMascot(mascotTeam) {
    new Float:minBox[3], Float:maxBox[3];
    new mascot = create_entity("info_target");
    if (mascot) {
        entity_set_string(mascot, EV_SZ_classname, INFO_SJ_MASCOT);
        entity_set_model(mascot, gSJTeamMascots[mascotTeam]);
        gSJMascots[mascotTeam] = mascot;
        entity_set_int(mascot, EV_INT_solid, SOLID_NOT);
        entity_set_int(mascot, EV_INT_movetype, MOVETYPE_NONE);
        entity_set_int(mascot, EV_INT_team, mascotTeam);
        minBox[0] = -16.0;
        minBox[1] = -16.0;
        minBox[2] = -72.0;
        maxBox[0] =  16.0;
        maxBox[1] =  16.0;
        maxBox[2] =  72.0;
        entity_set_size(mascot, minBox, maxBox);
        
        entity_set_origin(mascot, gSJMascotsSpawnOrigins);
        entity_set_float(mascot, EV_FL_animtime, 2.0);
        entity_set_float(mascot, EV_FL_framerate, 1.0);
        entity_set_int(mascot, EV_INT_sequence, 0);

        if (mascotTeam == SJ_GTM_TEAM_B) {
            entity_set_byte(mascot, EV_BYTE_controller1, 115);
        }
        
        entity_set_vector(mascot, EV_VEC_angles, gSJMascotsSpawnAngles);
        entity_set_float(mascot, EV_FL_nextthink, halflife_time() + 1.0);
    }
}

public finalizeGoalNet(taskID) {
    new team = TASK_NET_TEAM - taskID;
    new goalNet = gSJGoalEnt[team];
    entity_set_string(goalNet, EV_SZ_classname, INFO_SJ_GOAL_NET);
    entity_set_int(goalNet, EV_INT_team, team);
    set_entity_visibility(goalNet, 0);
}

removeNotSJSpawns() {
    new ent, master[32];
    while ((ent = find_ent_by_class(ent, INFO_SJ_PLAYER_TEAM_B))) {
        pev(ent, pev_netname, master, charsmax(master));
        if (!equal(master, "team_A") && !equal(master, "team_B")) {
            remove_entity(ent);
        }
    }
}

stock createGameTeamMaster(name[], teamID) {
	new ent = create_entity("game_team_master");
	set_pev(ent, pev_targetname, name);
	DispatchKeyValue(ent, "teamindex", fmt("%i", teamID - 1));
	return ent;
}

hl_set_teamnames(id, any:...) {
	new teamNames[10][16];
	new numTeams = clamp(numargs() - 1, 0, 10);

	for (new i; i < numTeams; i++)
		format_args(teamNames[i], charsmax(teamNames[]), 1 + i);

	message_begin(MSG_ONE, get_user_msgid("TeamNames"), _, id);
	write_byte(numTeams);
	for (new i; i < numTeams; i++)
		write_string(teamNames[i]);
	message_end();
}

sjGetPlayers(players[MAX_PLAYERS], &num) {
    num = 0;
    for (new id = 1; id <= MaxClients; id++) {
		if (!is_user_hltv(id) && is_user_connected(id)) {
			players[num++] = id;
		}
	}
}

sjGetPlayersPerTeam(&num, teamIndex) {
    num = 0;
    for (new id = 1; id <= MaxClients; id++) {
        if (is_user_connected(id) && (hl_get_user_team(id) == teamIndex)) {
            num++;
        }
    }
}

flameWave(origin[3]) {
    message_begin(MSG_BROADCAST, SVC_TEMPENTITY, origin);
    write_byte(21);
    write_coord(origin[0]);
    write_coord(origin[1]);
    write_coord(origin[2] + 16);
    write_coord(origin[0]);
    write_coord(origin[1]);
    write_coord(origin[2] + 500);
    write_short(gSJFireSprite);
    write_byte(0);
    write_byte(0);
    write_byte(15);
    write_byte(50);
    write_byte(10);
    write_byte(255);
    write_byte(0);
    write_byte(0);
    write_byte(255);
    write_byte(1/10);
    message_end();

    message_begin(MSG_BROADCAST, SVC_TEMPENTITY, origin);
    write_byte(21);
    write_coord(origin[0]);
    write_coord(origin[1]);
    write_coord(origin[2] + 16);
    write_coord(origin[0]);
    write_coord(origin[1]);
    write_coord(origin[2] + 500);
    write_short(gSJFireSprite);
    write_byte(0);
    write_byte(0);
    write_byte(10);
    write_byte(70);
    write_byte(10);
    write_byte(255);
    write_byte(50);
    write_byte(0);
    write_byte(200);
    write_byte(1/9);
    message_end();

    message_begin(MSG_BROADCAST, SVC_TEMPENTITY, origin);
    write_byte(21);
    write_coord(origin[0]);
    write_coord(origin[1]);
    write_coord(origin[2] + 16);
    write_coord(origin[0]);
    write_coord(origin[1]);
    write_coord(origin[2] + 500);
    write_short(gSJFireSprite);
    write_byte(0); 
    write_byte(0); 
    write_byte(10); 
    write_byte(90); 
    write_byte(10); 
    write_byte(255); 
    write_byte(100);
    write_byte(0); 
    write_byte(200); 
    write_byte(1/8);
    message_end();

    message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
    write_byte(12);
    write_coord(origin[0]);
    write_coord(origin[1]);
    write_coord(origin[2]);
    write_byte(80);
    write_byte(10);
    message_end();

    message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
    write_byte(3);
    write_coord(origin[0]);
    write_coord(origin[1]);
    write_coord(origin[2]);
    write_short(gSJFireSprite);
    write_byte(65);
    write_byte(10);
    write_byte(0);
    message_end();

    message_begin(MSG_BROADCAST, SVC_TEMPENTITY, origin);
    write_byte(5); 
    write_coord(origin[0]);
    write_coord(origin[1]);
    write_coord(origin[2]);
    write_short(gSJSmokeSprite);
    write_byte(50);
    write_byte(10); 
    message_end();

    return PLUGIN_HANDLED;
}

playWav(id, wav[]) {
    client_cmd(id, "spk %s", wav);
}