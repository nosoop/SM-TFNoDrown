#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>

#define PLUGIN_VERSION			"0.1.0"		// Plugin version.

public Plugin:myinfo = {
	name = "[TF2] No Drowning on Heals",
	author = "nosoop",
	description = "Prevents drowning while being healed.",
	version = PLUGIN_VERSION,
	url = "http://github.com/nosoop"
}

public OnPluginStart() {
	// TODO Identify heal sources and add cvars to choose oxygen sources

	for (new i = MaxClients; i > 0; --i) {
		if (IsClientInGame(i)) {
			OnClientPutInServer(i);
		}
	}
}

public OnClientPutInServer(client) {
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage_Drowning);
}

/**
 * Overrides drowning.  Drowning prevention by Bacardi of AlliedModders:
 * https://forums.alliedmods.net/showpost.php?p=1698121&postcount=2
 */
public Action:OnTakeDamage_Drowning(victim, &attacker, &inflictor, &Float:damage, &damagetype) {
	if (damagetype & DMG_DROWN && IsVictimPlayer(victim) && IsClientInGame(victim) && IsNotDrowningByHeals(victim)) {
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

bool:IsVictimPlayer(i) {
	return (i > 0) && (i <= MaxClients);
}

/**
 * Checks if the player is not drowning due to being healed by a dispenser or Medic.
 */
bool:IsNotDrowningByHeals(iClient) {
	// Currently all sources of heals will prevent drowning.
	return IsBeingHealed(iClient);
}

/**
 * Checks if the client has at least one source of continuous healing (dispenser, medic).
 */
bool:IsBeingHealed(iClient) {
	return GetEntProp(iClient, Prop_Send, "m_nNumHealers") > 0;
}
