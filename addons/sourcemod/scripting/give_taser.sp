#include <sourcemod>
#include <sdktools>
#include <smlib>
#include <cstrike>

#pragma semicolon 1

Handle g_h_enabled = INVALID_HANDLE;
Handle g_h_public_enabled = INVALID_HANDLE;
Handle g_h_max_admin_round_gives = INVALID_HANDLE;
Handle g_h_max_admin_life_gives = INVALID_HANDLE;
Handle g_h_max_admin_map_gives = INVALID_HANDLE;
Handle g_h_max_public_round_gives = INVALID_HANDLE;
Handle g_h_max_public_life_gives = INVALID_HANDLE;
Handle g_h_max_public_map_gives = INVALID_HANDLE;
Handle g_h_admin_flag = INVALID_HANDLE;
Handle g_h_track_buys = INVALID_HANDLE;
Handle g_h_track_money = INVALID_HANDLE;
Handle g_h_admin_cooldown = INVALID_HANDLE;
Handle g_h_public_cooldown = INVALID_HANDLE;

new String:g_s_admin_flag[32];
bool g_error;			//Global if cvar is a valid flag

int g_num_round_gives[MAXPLAYERS+1];
int g_num_life_gives[MAXPLAYERS+1];
int g_num_map_gives[MAXPLAYERS+1];

int g_taser_price = 200;
new g_taser_time[MAXPLAYERS+1];

public Plugin myinfo = 
{
    	name = "[CS:GO] Give Taser",
    	author = "Gdk",
    	description = "Allows admins or all players to receive a taser",
    	version = "2.2.1",
    	url = "https://github.com/RavageCS/CS-GO-give_taser"
};

public void OnPluginStart() 
{
	g_h_enabled = 			CreateConVar("sm_gt_enabled",    "1", "Whether the plugin is enabled");
	g_h_public_enabled = 		CreateConVar("sm_gt_public_enabled",    "1", "Whether non admins can receive a taser");
	
	g_h_max_admin_round_gives =   	CreateConVar("sm_gt_max_admin_round", "1", "Number of tasers admins can receive per round \nUse -1 for infinite");
	g_h_max_admin_life_gives =    	CreateConVar("sm_gt_max_admin_life", "-1", "Number of tasers admins can receive per life \nUse -1 for infinite");
	g_h_max_admin_map_gives =    	CreateConVar("sm_gt_max_admin_map", "-1", "Number of tasers admins can receive per map \nUse -1 for infinite");
	g_h_admin_cooldown = 		CreateConVar("sm_gt_admin_cooldown", "120", "Number of seconds to wait between giving admins a taser\n0 to disable, time starts when fired");	

	g_h_max_public_round_gives =   	CreateConVar("sm_gt_max_public_round", "1", "Number of tasers non admins can receive per round \nUse -1 for infinite");
	g_h_max_public_life_gives =    	CreateConVar("sm_gt_max_public_life", "-1", "Number of tasers non admins can receive per life \nUse -1 for infinite");
	g_h_max_public_map_gives =    	CreateConVar("sm_gt_max_public_map", "1", "Number of tasers non admins can receive per map \nUse -1 for infinite");
	g_h_public_cooldown = 		CreateConVar("sm_gt_public_cooldown", "240", "Number of seconds to wait between giving non admins a taser\n0 to disable, time starts when fired");

	g_h_admin_flag =    		CreateConVar("sm_gt_admin_flag", "any", "Required admin flag to receive a taser. \nUse \"any\" for any admin flag \nValid flags: abcdefghijkmnzop");
	g_h_track_buys =    		CreateConVar("sm_gt_track_buys", "1", "Should plugin count tasers purchased from buy menu");
	g_h_track_money = 		CreateConVar("sm_gt_track_money", "0", "Require player to pay $200 to receive a taser");

	HookConVarChange(g_h_admin_flag, OnConVarChange);

	HookEvent("player_death", EventPlayerDeath, EventHookMode_Post);
	HookEvent("round_start", EventRoundStart, EventHookMode_Post);
	HookEvent("weapon_fire", EventWeaponFire, EventHookMode_Post);

	LoadTranslations("core.phrases");
	LoadTranslations("give_taser.phrases");

	RegConsoleCmd("sm_taser", Command_Taser, "Gives a taser");

	AutoExecConfig(true, "give_taser");
}

public void OnConfigsExecuted()
{
	GetConVarString(g_h_admin_flag, g_s_admin_flag, 32);

	g_error = false;	
}

public void OnClientCookiesCached(int client) 
{
	g_num_round_gives[client] = 0;
	g_num_life_gives[client] = 0;
	g_num_map_gives[client] = 0;
}

public void OnMapStart()
{
	for(int i; i < MAXPLAYERS+1; i++)
	{
		g_num_map_gives[i] = 0;		
	}
}

public Action Command_Taser(int client, int args) 
{
	if(GetConVarBool(g_h_enabled) && !g_error && IsClientConnected(client) && IsPlayerAlive(client))
	{		
		//Prevent giving taser before fire animation is complete
		if(GetTime() <= g_taser_time[client] + 1)
		{}

		if(CheckAdmin(client))
		{
			GiveTaser(client, true);
		}
		else
		{
			if(GetConVarInt(g_h_public_enabled))
			{
				GiveTaser(client, false);
			}	
			else
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

public bool CheckAdmin(int client)
{
	bool is_admin = false;

	if(StrEqual(g_s_admin_flag, "any", false) && GetUserAdmin(client) != INVALID_ADMIN_ID)
	{	
			is_admin = true;
	}
	else
	{	
		g_error = true;
		new String:myFlags[17] = "abcdefghijkmnzop";
		int flags = ReadFlagString(myFlags);

		if (GetUserFlagBits(client) & flags == flags)
		{
			is_admin = true;
		}

		for(int i=0; i < sizeof(myFlags); i++)
		{
			if (FindCharInString(g_s_admin_flag, myFlags[i], false))
			{
				g_error = false;
			}
		}
	}
	
	return is_admin;
}
	
		

public void GiveTaser(int client, bool is_admin)
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
			g_num_map_gives[client]--;
	
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
		if(CanReceiveTaser(client, is_admin))
		{
			GivePlayerItem(client, "weapon_taser");
			
			if(!StrEqual(currentWeapon, "weapon_knife", false) && !StrEqual(currentWeapon, "weapon_c4", false)
			   && !StrEqual(currentWeapon, "weapon_decoy", false) && !StrEqual(currentWeapon, "weapon_hegrenade", false)
			   && !StrEqual(currentWeapon, "weapon_incgrenade", false) && !StrEqual(currentWeapon, "weapon_molotov", false)
			   && !StrEqual(currentWeapon, "weapon_smokegrenade", false))
				ClientCommand(client, "slot3");
			
			g_num_round_gives[client]++;
			g_num_life_gives[client]++;
			g_num_map_gives[client]++;
		}
   	}
}

public bool CanReceiveTaser(int client, bool is_admin)
{
	bool give_taser = true;

	int max_round_gives;
	int max_life_gives;
	int max_map_gives;
	int cooldown;
	
	if(is_admin)
	{
		max_round_gives = GetConVarInt(g_h_max_admin_round_gives);
		max_life_gives = GetConVarInt(g_h_max_admin_life_gives);
		max_map_gives = GetConVarInt(g_h_max_admin_map_gives);
		cooldown = GetConVarInt(g_h_admin_cooldown);
	}

	if(!is_admin)
	{
		max_round_gives = GetConVarInt(g_h_max_public_round_gives);
		max_life_gives = GetConVarInt(g_h_max_public_life_gives);
		max_map_gives = GetConVarInt(g_h_max_public_map_gives);
		cooldown = GetConVarInt(g_h_public_cooldown);
	}

	if(g_num_map_gives[client] >= max_map_gives && max_map_gives != -1)
	{
		give_taser = false;
		PrintToChat(client, "%t", "map");
	}
	else if(g_num_round_gives[client] >= max_round_gives && max_round_gives != -1)
	{
		give_taser = false;
		PrintToChat(client, "%t", "round");
	}
	else if(g_num_life_gives[client] >= max_life_gives && max_life_gives != -1)
	{
		give_taser = false;
		PrintToChat(client, "%t", "life");
	}
	else if(GetTime() < g_taser_time[client] + cooldown)
	{
		give_taser = false;
		int cooldown_seconds = g_taser_time[client] + cooldown - GetTime();
		PrintToChat(client, "%t", "cooldown", cooldown_seconds);
	}

	if(GetConVarBool(g_h_track_money) && give_taser)
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

	return give_taser;
}

public Action CS_OnBuyCommand(int client, const char[] weapon)
{	
	if(GetConVarBool(g_h_track_buys) && StrEqual(weapon, "taser", false))
	{
		if(CheckAdmin(client))
		{
			GiveTaser(client, true);
		}
		else
		{
			GiveTaser(client, false);
		}

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
	if(convar == g_h_admin_flag)
	{
		strcopy(g_s_admin_flag, sizeof(g_s_admin_flag), newValue);
		g_error = false;
	}
}
