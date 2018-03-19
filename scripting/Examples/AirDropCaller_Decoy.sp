#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <hexstocks>
#include <airdrop>

//Compiler options
#pragma semicolon 1
#pragma newdecls required

//Arrays
ArrayList Array_BoxEnt;

//Booleans
bool bPressed[MAXPLAYERS + 1];

char g_sValidWeapons[][] = //VALID WEAPON NAMES HERE
{
     //"defuser", "c4", "knife", "knifegg", "taser", "healthshot", //misc
     /*"decoy",*/ "flashbang", "hegrenade", "molotov", "incgrenade", "smokegrenade", "tagrenade", //grenades
     //"usp_silencer", "glock", "tec9", "p250", "hkp2000", "cz75a", "deagle", "revolver", "fiveseven", "elite", //pistoles
     "nova", "xm1014", "sawedoff", "mag7", "m249", "negev", //heavy weapons
     "mp9", "mp7", "ump45", "p90", "bizon", "mac10", //smgs
     "ak47", "aug", "famas", "sg556", "galilar", "m4a1", "m4a1_silencer", //rifles
     "awp", "ssg08", "scar20", "g3sg1" //snipers
};

#define PLUGIN_AUTHOR "Hexah"
#define PLUGIN_VERSION "1.00"

//Plugin invos
public Plugin myinfo = 
{
	name = "CallAirDrop with Decoy", 
	author = PLUGIN_AUTHOR, 
	description = "", 
	version = PLUGIN_VERSION, 
	url = "csitajb.it"
};

public void OnPluginStart()
{
	//Create Array
	Array_BoxEnt = new ArrayList(64);
	
	//Hook Events
	HookEvent("round_start", Event_RoundStart);
	HookEvent("decoy_detonate", Event_DecoyStarted);
}

public void OnMapStart()
{
	CreateTimer(60.0, Timer_GiveDecoy, _, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
}

public Action Timer_GiveDecoy(Handle timer)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			if(IsPlayerAlive(i) && GetClientTeam(i) > 1)
			{
				GivePlayerItem(i, "weapon_decoy");
			}
		}
	}
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	//Clear BoxEnt Array every round start
	Array_BoxEnt.Clear();
}
public void Event_DecoyStarted(Event event, const char[] name, bool dontBroadcast)
{
	//Get the BoxOrigin
	float vBoxOrigin[3];
	vBoxOrigin[0] = event.GetFloat("x");
	vBoxOrigin[1] = event.GetFloat("y");
	vBoxOrigin[2] = event.GetFloat("z");
	
	int iBoxEnt = AirDrop_Call(vBoxOrigin); //Call AirDrop
	
	Array_BoxEnt.Push(iBoxEnt); //Push the BoxEnt to our Array (Yse EntRef to be safe)
}

public void AirDrop_BoxUsed(int client, int iEnt) //Called when pressing +use on the AirDropBox
{
	if (GetArraySize(Array_BoxEnt) == 0) //Check for not void array
		return;
	
	for (int i = 0; i <= GetArraySize(Array_BoxEnt) - 1; i++)
	{
		int iBoxEnt = Array_BoxEnt.Get(i); //Get BoxEnt (Convert EntRef to Index)
		
		if (iBoxEnt == INVALID_ENT_REFERENCE) //Check for valid ent
		{
			Array_BoxEnt.Erase(i); //Remove Invalid EntRef from the array
			return;
		}
		
		if (iBoxEnt == iEnt) //Check if BoxEnt is the 'pressed' Ent
		{
			if (bPressed[client])
				return;
			
			char weapon[PLATFORM_MAX_PATH];
			Format(weapon, sizeof(weapon), "weapon_%s", g_sValidWeapons[GetRandomInt(0, sizeof(g_sValidWeapons))]);
			GivePlayerItem(client, weapon);
			
			bPressed[client] = true;
			AcceptEntityInput(iEnt, "kill", 0, 0);
			Array_BoxEnt.Erase(i);
			CreateTimer(2.0, Timer_Pressed, GetClientUserId(client)); //Create Timer to avoid spamming
		}
	}
}

public Action Timer_Pressed(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	
	if (!client) //Client disconnected
		return;
	
	bPressed[client] = false;
} 
