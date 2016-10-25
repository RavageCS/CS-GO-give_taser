#include <sourcemod>
#include <sdktools>
#include <smlib>
#include <cstrike>

#pragma semicolon 1

Handle g_h_enabled = INVALID_HANDLE;
Handle g_h_max_round_gives = INVALID_HANDLE;
Handle g_h_max_life_gives = INVALID_HANDLE;
Handle g_h_admin_flag = INVALID_HANDLE;
Handle g_h_track_buys = INVALID_HANDLE;
Handle g_h_track_money = INVALID_HANDLE;
Handle g_h_cooldown = INVALID_HANDLE;

int g_max_round_gives;
int g_max_life_gives;
new String:g_s_admin_flag[32];
bool g_error;			//Global if cvar is a valid flag
int g_num_round_gives[MAXPLAYERS+1];
int g_num_life_gives[MAXPLAYERS+1];
int g_taser_price = 200;
new g_taser_time[MAXPLAYERS+1];

public Plugin myinfo = 
{
    	name = "[CS:GO] Give Taser",
    	author = "Gdk",
    	description = "Allows admins or all players to receive a taser",
    	version = "2.1.0",
    	url = "https://github.com/RavageCS/CS-GO-give_taser"
};

public void OnPluginStart() 
{
	g_h_enabled = 		CreateConVar("sm_gt_enabled",    "1", "Whether the plugin is enabled");
	g_h_max_round_gives =   CreateConVar("sm_gt_max_round", "1", "Number of tasers players can receive per round \nUse -1 for infinite");
	g_h_max_life_gives =    CreateConVar("sm_gt_max_life", "-1", "Number of tasers players can receive per life \nUse -1 for infinite");
	g_h_admin_flag =    	CreateConVar("sm_gt_admin_flag", "any", "Required admin flag to receive a tase. \nUse \"none\" for no admin flag needed \nUse \"any\" for any admin flag \nValid flags: abcdefghijkmnzop");
	g_h_track_buys =    	CreateConVar("sm_gt_track_buys", "1", "Should plugin count tasers purchased from buy menu");
	g_h_track_money = 	CreateConVar("sm_gt_track_money", "0", "Require player to pay $200 to receive a taser");
	g_h_cooldown = 		CreateConVar("sm_gt_cooldown", "120", "Number of seconds to wait between giving a taser\n0 to disable, time starts when fired");

	HookConVarChange(g_h_max_round_gives, OnConVarChange);
	HookConVarChange(g_h_max_life_gives, OnConVarChange);
	HookConVarChange(g_h_admin_flag, OnConVarChange);

	HookEvent("player_death", EventPlayerDeath, EventHookMode_Post);
	HookEvent("round_start", EventRoundStart, EventHookMode_Post);
	HookEvent("weapon_fire", EventWeaponFire, EventHookMode_Post);

	LoadTranslations("core.phrases");
	LoadTranslations("give_taser.phrases");

	RegConsoleCmd("sm_taser", Command_Taser, "Gives admins or anyone a taser");

	AutoExecConfig(true, "give_taser");
}

public void OnConfigsExecuted()
{
	g_max_round_gives = GetConVarInt(g_h_max_round_gives);
	g_max_life_gives = GetConVarInt(g_h_max_life_gives);
	GetConVarString(g_h_admin_flag, g_s_admin_flag, 32);

	g_error = false;	
}

public void OnClientCookiesCached(int client) 
{
	g_num_round_gives[client] = 0;
	g_num_life_gives[client] = 0;
}

public Action Command_Taser(int client, int args) 
{
	if(GetConVarBool(g_h_enabled) && !g_error && IsClientConnected(client) && IsPlayerAlive(client))
	{
		//Prevent giving taser before fire animation is complete
		if(GetTime() <= g_taser_time[client] + 1)
		{}

		else if(StrEqual(g_s_admin_flag, "none", false) || StrEqual(g_s_admin_flag, "no", false))
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
	new String:currentWeapon[32];
	new ent1 = Client_GetActiveWeaponName(client, currentWeapon, sizeof(currentWeapon));
	
	if(Client_HasWeapon(client, "weapon_taser"))
	{
		if(StrEqual(currentWeapon, "weapon_taser", false))
		{
			ClientCommand(client, "lastinv");
			RemovePlayerItem(client, ent1);
			
			g_num_round_gives[client]--;
			g_num_life_gives[client]--;
	
			if(GetConVarBool(g_h_track_money))
			{
				new Cash = GetEntProp(client, Prop_Send, "m_iAccount"); // get money
				Cash += g_taser_price;
				SetEntProp(client, Prop_Send, "m_iAccount", Cash); // change money
			}
		}
		else
		{
			ClientCommand(client, "slot3");
		}		
   	}
   	else
   	{	
		if(CanReceiveTaser(client))
		{
			GivePlayerItem(client, "weapon_taser");
			
			if(!StrEqual(currentWeapon, "weapon_knife", false) && !StrEqual(currentWeapon, "weapon_c4", false)
			   && !StrEqual(currentWeapon, "weapon_decoy", false) && !StrEqual(currentWeapon, "weapon_hegrenade", false)
			   && !StrEqual(currentWeapon, "weapon_incgrenade", false) && !StrEqual(currentWeapon, "weapon_molotov", false)
			   && !StrEqual(currentWeapon, "weapon_smokegrenade", false))
				ClientCommand(client, "slot3");
			
			g_num_round_gives[client]++;
			g_num_life_gives[client]++;
		}
   	}
}

public bool CanReceiveTaser(int client)
{
	bool give_taser = true;
	
	if(GetConVarBool(g_h_track_money))
	{	
		new Cash = GetEntProp(client, Prop_Send, "m_iAccount"); // get money
		if(Cash >= g_taser_price)
		{
			Cash -= g_taser_price;
			SetEntProp(client, Prop_Send, "m_iAccount", Cash); // change money
		}
		else
		{
			PrintToChat(client, "%t", "money");
			give_taser = false;
		}
	}

	if(g_num_round_gives[client] >= g_max_round_gives && g_max_round_gives != -1)
	{
		give_taser = false;
		PrintToChat(client, "%t", "round");
	}

	else if(g_num_life_gives[client] >= g_max_life_gives && g_max_life_gives != -1)
	{
		give_taser = false;
		PrintToChat(client, "%t", "life");
	}

	else if(GetTime() < g_taser_time[client] + GetConVarInt(g_h_cooldown))
	{
		give_taser = false;
		int cooldown_seconds = g_taser_time[client] + GetConVarInt(g_h_cooldown) - GetTime();
		PrintToChat(client, "%t", "cooldown", cooldown_seconds);
	}

	else if(g_max_round_gives == -1 && g_max_life_gives == -1)
		give_taser = true;

	return give_taser;
}

public Action CS_OnBuyCommand(int client, const char[] weapon)
{	
	if(GetConVarBool(g_h_track_buys) && StrEqual(weapon, "taser", false))
	{
		GiveTaser(client);
		return Plugin_Handled;
	}

	return Plugin_Continue;
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

public EventWeaponFire(Handle:event, const String:name[],bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new String:weaponName[32];
	GetEventString(event, "weapon", weaponName, sizeof(weaponName));

	if(StrEqual(weaponName, "weapon_taser", false))
	{
		g_taser_time[client] = GetTime();
	}
}

		
public OnConVarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(convar == g_h_max_round_gives)
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
