#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>

#define PLUGIN_VERSION			"0.0.0"		// Plugin version.

public Plugin:myinfo = {
	name = "[TF2] Oxygen Dispenser",
	author = "nosoop",
	description = "Prevents drowning while near a dispenser.",
	version = PLUGIN_VERSION,
	url = "localhost"
}

new bool:g_rgbPlayerHealing[MAXPLAYERS+1];

public OnPluginStart() {
	for (new i = MaxClients; i > 0; --i) {
		if (IsClientInGame(i)) {
			OnClientPutInServer(i);
		}
	}
	
	HookEvent("object_destroyed", Event_ObjectDestroyed);
}

public OnMapStart() {
	for (new i = MaxClients; i > 0; --i) {
		g_rgbPlayerHealing[i] = false;
	}
}

public OnClientPutInServer(client) {
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype) {
	if (g_rgbPlayerHealing[victim] && damagetype & DMG_DROWN) {
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:Event_ObjectDestroyed(Handle:hEvent, const String:name[], bool:dontBroadcast) {
	new iType = GetEventInt(hEvent, "objecttype");
	PrintToServer("Destroyed %d", iType);
}

/**
 * Dispenser healing detection code from adapted from Bacardi of AlliedModders:
 * https://forums.alliedmods.net/showpost.php?p=2128273&postcount=6
 */
public OnEntityCreated(entity, const String:classname[]) {
	if (StrEqual(classname, "dispenser_touch_trigger", false)) {
		RequestFrame(Frame_HookDispenserTriggers, entity);
	}
}

// TODO ensure dispenser count

public Frame_HookDispenserTriggers(any:entity) {
	SDKHookEx(entity, SDKHook_StartTouchPost, OnDispenserHealStart);
	SDKHookEx(entity, SDKHook_EndTouchPost, OnDispenserHealEnd); 
}

public OnDispenserHealStart(entity, client) {
	if (0 < client <= MaxClients) {
		new ent = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
		new team = GetEntProp(ent, Prop_Send, "m_iTeamNum");

		if (team == GetClientTeam(client)) {
			g_rgbPlayerHealing[client] = true;
		}
	}
}

public OnDispenserHealEnd(entity, client) {
	if (0 < client <= MaxClients) {
		g_rgbPlayerHealing[client] = false;
	}
}  