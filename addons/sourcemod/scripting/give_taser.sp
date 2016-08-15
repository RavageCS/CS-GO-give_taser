#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

Handle g_h_enabled = INVALID_HANDLE;
Handle g_h_max_round_gives = INVALID_HANDLE;
Handle g_h_max_life_gives = INVALID_HANDLE;
Handle g_h_admin_flag = INVALID_HANDLE;

new bool:g_enabled;
int g_max_round_gives;
int g_max_life_gives;
new String:g_s_admin_flag[32];
bool g_error;			//Global if cvar is a valid flag
int g_num_round_gives[MAXPLAYERS+1];
int g_num_life_gives[MAXPLAYERS+1];


public Plugin myinfo = 
{
    name = "[CS:GO] Give Taser",
    author = "Gdk",
    description = "Allows admins or all players to receive a taser",
    version = "1.1.0",
    url = "https://github.com/RavageCS/CS-GO-give_taser"
};

public void OnPluginStart() 
{
	g_h_enabled = CreateConVar("sm_gt_enabled",    "1", "Whether the plugin is enabled");
	g_h_max_round_gives =   CreateConVar("sm_gt_max_round", "1", "Number of tasers players can receive per round. \nUse -1 for infinite");
	g_h_max_life_gives =    CreateConVar("sm_gt_max_life", "-1", "Number of tasers players can receive per life. \nUse -1 for infinite");
	g_h_admin_flag =    CreateConVar("sm_gt_admin_flag", "any", "Required admin flag to receive a taser. \nUse \"none\" for no admin flag needed \nUse \"any\" for any admin flag \nValid flags: abcdefghijkmnzop");

	HookConVarChange(g_h_enabled, OnConVarChange);
	HookConVarChange(g_h_max_round_gives, OnConVarChange);
	HookConVarChange(g_h_max_life_gives, OnConVarChange);
	HookConVarChange(g_h_admin_flag, OnConVarChange);

	HookEvent("player_death", EventPlayerDeath, EventHookMode_Post);
	HookEvent("round_start", EventRoundStart, EventHookMode_Post);

	LoadTranslations("core.phrases");

	AutoExecConfig(true, "give_taser");
}

public void OnConfigsExecuted()
{
	g_enabled = GetConVarBool(g_h_enabled);
	g_max_round_gives = GetConVarInt(g_h_max_round_gives);
	g_max_life_gives = GetConVarInt(g_h_max_life_gives);
	GetConVarString(g_h_admin_flag, g_s_admin_flag, 32);
	g_error = false;
	RegConsoleCmd("sm_taser", Command_Taser, "Gives admins or anyone a taser");	
	
}

public void OnClientCookiesCached(int client) 
{
	g_num_round_gives[client] = 0;
	g_num_life_gives[client] = 0;
}

public Action Command_Taser(int client, int args) 
{
	if(g_enabled && !g_error && IsPlayerAlive(client))
	{
		if(StrEqual(g_s_admin_flag, "none", false) || StrEqual(g_s_admin_flag, "no", false))
		{
			GiveTaser(client);
		}
		else if(StrEqual(g_s_admin_flag, "any", false))
		{
			if(GetUserAdmin(client) != INVALID_ADMIN_ID)
			{
				GiveTaser(client);
			}
			else
			{
				ReplyToCommand(client, "[SM] %t", "No Access");
			}
		}
		else
		{
			bool taser_given = false;
			g_error = true;
			new String:myFlags[17] = "abcdefghijkmnzop";
			int flags = ReadFlagString(myFlags);

			if (GetUserFlagBits(client) & flags == flags)
			{
				GiveTaser(client);
				g_error = false;
				taser_given = true;
			}

			for(int i=0; i < sizeof(myFlags); i++)
			{
				if (FindCharInString(g_s_admin_flag, myFlags[i], false))
				{
					g_error = false;
				}
			}

			if(!g_error && !taser_given)
			{
				ReplyToCommand(client, "[SM] %t", "No Access");
			}
		}
		if(g_error) 
		{
			LogError("[give_taser]: Invalid admin flag: %s", g_s_admin_flag);
		}
	}

	return Plugin_Handled;
}

public void GiveTaser(int client)
{
	new String:weaponName[50];
	new ent = GetPlayerWeaponSlot(client, 2);
	if(IsValidEntity(ent))
	{
		GetEntityClassname(ent, weaponName, sizeof(weaponName));

		if(StrEqual(weaponName, "weapon_knife", false))
		{
			RemoveEdict(ent);
			ent = GetPlayerWeaponSlot(client, 2);

			if(IsValidEntity(ent))
			{
				RemoveEdict(ent);

				if (GetClientTeam(client) == 2)
				{
					GivePlayerItem(client, "weapon_knife_t");
				}
				else
				{
					GivePlayerItem(client, "weapon_knife");
				}
				GivePlayerItem(client, "weapon_taser");
				FakeClientCommand(client, "use weapon_taser");
			}

			else if( (g_max_round_gives == -1 && g_num_life_gives[client] < g_max_life_gives) || (g_max_life_gives == -1 && g_num_round_gives[client] < g_max_round_gives) || (g_num_round_gives[client] < g_max_round_gives && g_num_life_gives[client] < g_max_life_gives) )
			{
				if (GetClientTeam(client) == 2)
				{
					GivePlayerItem(client, "weapon_knife_t");
				}
				else
				{
					GivePlayerItem(client, "weapon_knife");
				}
				GivePlayerItem(client, "weapon_taser");
				FakeClientCommand(client, "use weapon_taser");
				g_num_round_gives[client]++;
				g_num_life_gives[client]++;
			}

			else
			{
				if (GetClientTeam(client) == 2)
				{
					GivePlayerItem(client, "weapon_knife_t");
				}
				else
				{
					GivePlayerItem(client, "weapon_knife");
				}
			}
		}
		
		else if(StrEqual(weaponName, "weapon_taser", false))
		{
			FakeClientCommand(client, "use weapon_taser");			
		}
	}

	else if( (g_max_round_gives == -1 && g_num_life_gives[client] < g_max_life_gives) || (g_max_life_gives == -1 && g_num_round_gives[client] < g_max_round_gives) || (g_num_round_gives[client] < g_max_round_gives && g_num_life_gives[client] < g_max_life_gives))
	{
		GivePlayerItem(client, "weapon_taser");
		FakeClientCommand(client, "use weapon_taser");
		g_num_round_gives[client]++;
		g_num_life_gives[client]++;
	}		
}

public EventPlayerDeath(Handle:event, const String:name[],bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	g_num_life_gives[client] = 0;
}

public EventRoundStart(Handle:event, const String:name[],bool:dontBroadcast)
{
	for(int i; i < MAXPLAYERS+1; i++)
	{
		g_num_round_gives[i] = 0;
	}
}

public OnConVarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(convar == g_h_enabled)
	{
		if(newValue[0] == '1')
		{
			g_enabled = true;
			g_error = false;
		}
		else if(newValue[0] == '0')
		{
			g_enabled = false;
		}
	}

	else if(convar == g_h_max_round_gives)
	{
		g_max_round_gives = StringToInt(newValue);
	}

	else if(convar == g_h_max_life_gives)
	{
		g_max_life_gives = StringToInt(newValue);
	}

	else if(convar == g_h_admin_flag)
	{
		strcopy(g_s_admin_flag, sizeof(g_s_admin_flag), newValue);
		g_error = false;
	}
}
