#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#undef REQUIRE_EXTENSIONS
#include <clientprefs>

#define PLUGIN_VERSION			"0.3.0"

public Plugin:myinfo = {
	name = "[TF2] Drowning Modifications",
	author = "nosoop",
	description = "Overrides drowning mechanism, adding overlay disabling and prevention on heals.",
	version = PLUGIN_VERSION,
	url = "http://github.com/nosoop"
}

new bool:g_bCPrefsLoaded = false;

// Overlay preferences
new Handle:g_hOverlayPref = INVALID_HANDLE;
new bool:g_rgbOverlay[MAXPLAYERS + 1];

// Heal settings
new Handle:g_hCEnableOxygen = INVALID_HANDLE,
	Handle:g_hCAllowOverlayPref = INVALID_HANDLE;

public OnPluginStart() {
	// TODO Identify heal sources and add cvars to choose oxygen sources
	g_hCEnableOxygen = CreateConVar("sm_drown_enableoxyheal", "0", "Prevent clients from drowning when near a healing source.", FCVAR_PLUGIN | FCVAR_NOTIFY | FCVAR_SPONLY, true, 0.0, true, 1.0);
	
	g_hCAllowOverlayPref = CreateConVar("sm_drown_allowoverlaypref", "0", "Allow clients to disable the drowning overlay and sound effects via clientprefs.", FCVAR_PLUGIN | FCVAR_NOTIFY | FCVAR_SPONLY, true, 0.0, true, 1.0);
	HookConVarChange(g_hCAllowOverlayPref, OnAllowOverlayPrefChanged);
	
	for (new i = MaxClients; i > 0; --i) {
		if (IsClientInGame(i)) {
			OnClientPutInServer(i);
		}
	}
	
	AutoExecConfig();
}

public OnClientPutInServer(client) {
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage_Drowning);
}

public OnClientCookiesCached(client) {
	decl String:sValue[8];
	if (g_bCPrefsLoaded && !IsFakeClient(client)) {
		GetClientCookie(client, g_hOverlayPref, sValue, sizeof(sValue));
	}
    
	// Enabled by default
	g_rgbOverlay[client] = sValue[0] != '\0' ? StringToInt(sValue) == 1 : true;
}

public Cookie_OverlayPrefUpdated(client, CookieMenuAction:action, any:info, String:buffer[], maxlen) {
	switch (action) {
		case CookieMenuAction_DisplayOption: {
		}
		case CookieMenuAction_SelectOption:	{
			OnClientCookiesCached(client);
		}
	}
}


/**
 * Overrides drowning.  Drowning prevention by Bacardi of AlliedModders:
 * https://forums.alliedmods.net/showpost.php?p=1698121&postcount=2
 */
public Action:OnTakeDamage_Drowning(victim, &attacker, &inflictor, &Float:damage, &damagetype) {
	if (damagetype & DMG_DROWN) {
		if (GetConVarBool(g_hCEnableOxygen) && IsNotDrowningByHeals(victim)) {
			// If heals are preventing drowning, nullify damage completely.
			return Plugin_Handled;
		} else if (!g_rgbOverlay[victim] && FloatCompare(damage, float(GetClientHealth(victim))) < 0) {
			// If the client has disabled the overlay and the damage is non-fatal, strip the drowning tag.
			damagetype &= ~DMG_DROWN;
			return Plugin_Changed;
		}
		
	}
	return Plugin_Continue;
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

/**
 * Standard library checking functionality.
 */
public OnAllowOverlayPrefChanged(Handle:hCvar, const String:oldValue[], const String:newValue[]) {
	if (GetConVarBool(g_hCAllowOverlayPref)) {
		OnAllPluginsLoaded();
	}
}

public OnAllPluginsLoaded() {
	new bool:bLastState = g_bCPrefsLoaded;
	g_bCPrefsLoaded = LibraryExists("clientprefs");
	
	OnCPrefsStateCheck(g_bCPrefsLoaded != bLastState);
}

public OnLibraryRemoved(const String:name[]) {
	new bool:bLastState = g_bCPrefsLoaded;
	g_bCPrefsLoaded &= !StrEqual(name, "clientprefs");
	
	OnCPrefsStateCheck(g_bCPrefsLoaded != bLastState);
}

public OnLibraryAdded(const String:name[]) {
	new bool:bLastState = g_bCPrefsLoaded;
	g_bCPrefsLoaded |= StrEqual(name, "clientprefs");
	
	OnCPrefsStateCheck(g_bCPrefsLoaded != bLastState);
}

public OnCPrefsStateCheck(bHasChanged) {
	if (GetConVarBool(g_hCAllowOverlayPref) && bHasChanged) {
		if (g_bCPrefsLoaded) {
			g_hOverlayPref = RegClientCookie("DrowningOverlay", "Whether or not drowning damage triggers the overlay effect.", CookieAccess_Protected);
			SetCookiePrefabMenu(g_hOverlayPref, CookieMenu_OnOff_Int, "Drowning Overlay", Cookie_OverlayPrefUpdated);
			
			for (new i = MaxClients; i > 0; --i) {
				if (IsClientInGame(i)) {
					if (AreClientCookiesCached(i)) {
						OnClientCookiesCached(i);
					}
				}
			}
		}
	}
}
