#include <a_samp>
#include <sscanf2>
#include <zcmd>
#include <streamer>
#include <YSI\y_iterate>

#include <mapandreas> 
#include <FCNPC.inc> 

/*
	This code was originally written in lithuanian language, so i tried to explain as much as i can.

	the whole system works on prerecorded paths. There are 3 scenarios with 3 different paths for each scenario. When one path is completed it chooses one from other 2 and will go like that forever.
	All paths end in the same location, so the change of pathes(teleportation) isn't seen.
	Bank robbing scenario has 2 bots on top of the vehicle(surfing) that shoots police officers around them
	store robbing has 1 surfing bot
	hit and run has only the driver.
*/

#define ARESTINE_POS 0.0,0.0,0.0 // Jail (where to drag your fugitive to destroy it) position
#define BEGLIAI_LAUNCH_MINUTES 15 // time in minutes to create new fugitives



#define f(%0) (format(globalStringas, 256, %0), globalStringas)
#define Error(%1,%2) SendClientMessage(%1,0xF06666FF,f("× {EE8787}%s",%2))
#define Info(%1,%2) SendClientMessage(%1,0xDFEE32FF,f("o {D4E5C5}%s",%2))
#define COL_WHITE "{FFFFFF}"
#define Success(%1,%2) SendClientMessage(%1,0x47AB3FFF,f("+ %s", %2))

// spalvos
#define COL_WHITE "{FFFFFF}"
#define GREEN1 "{52CE48}"
#define RACIJA1 "{19d3da}"

forward Float:GetDistance(Float:x11,Float:y11,Float:z11, Float:x22,Float:y22,Float:z22);

new globalStringas[256]; // for message macros
new vilkimo_busena[MAX_PLAYERS]; // assign drag to player

enum BegliaiEnum
{
	npcidas, // driver npc id
	bbusena, 
	BeglioCar, // vehicleid
	KurisPathas, // path ids 1-3 bank robbing, 4-6 hit and run, 7-9 store robbing
	Text3D:BLabelis, // label
	Float:BGyvybes, // car health
	SurfBotai[2], // surfing bots npc ids
	Text3D:SurfBotulabel[2], // surfing bots label
	BotTim, // timer
}

new Begliai[BegliaiEnum]; 

new BeglysLaunchTime; // launch time to caunt minutes until launching the fugitives


public OnFilterScriptInit()
{
	SetTimer("MinuteTimer",60000,true);
	SetTimer("checkdrag",1000,true);
	
	// set npc accucary
	FCNPC_SetWeaponDefaultInfo(29, -1, 1, -1, 0.05);
	FCNPC_SetWeaponDefaultInfo(30, -1, 1, -1, 0.05);
	for(new i = 0;i<MAX_PLAYERS;i++)
	    vilkimo_busena[i] = -1;
	return 1;
}

CMD:testfugitive(playerid)
{
	Info(playerid,"Trying to launch");
	launchbeglys();
	return 1;
}

stock launchbeglys() // create fugitives
{
	if(!Begliai[bbusena]) 
	{
		BeglysLaunchTime = 0;
		return StartBeglys();
	}
	return 1;
}

stock StartBeglys() // Start fugitives
{
	Begliai[npcidas]=FCNPC_Create("Nusikaltelis"); //creating an npc on default coordinates with a random skin
	FCNPC_Spawn(Begliai[npcidas], random(300), 0.0,0.0,0.0);



 	// choosing the vehicle model.
	new modelis;

	new rand = random(8);

	switch(rand)
	{
		case 0: modelis = 401;
		case 1: modelis = 402;
		case 2: modelis = 412;
		case 3: modelis = 419;
		case 4: modelis = 426;
		case 5: modelis = 429;
		case 6: modelis = 439;
		case 7: modelis = 451;
	}


	Begliai[BLabelis]=CreateDynamic3DTextLabel(f("Fugitive (%i)",Begliai[npcidas]), 0xFFFFFFFF, 0.0,0.0,0.5, 25.0,Begliai[npcidas]);

	Begliai[BeglioCar]=CreateVehicle(modelis, 2128.7295,-1111.9586,24.7631, 0.0, random(50), random(50),0,0);

	FCNPC_PutInVehicle(Begliai[npcidas], Begliai[BeglioCar], 0); // placing the driver in the drivers seat

	new recording[20];
	new idas = PickNpcID();

	Begliai[KurisPathas]=idas;
	switch(idas)
	{
		case 1:recording = "swedbank1";
		case 2:recording = "swedbank2";
		case 3:recording = "swedbank3";
		case 4:recording = "nutrenke1";
		case 5:recording = "nutrenke2";
		case 6:recording = "nutrenke3";
		case 7:recording = "apiplese1";
		case 8:recording = "apiplese2";
		case 9:recording = "apiplese3";
	}


	if(idas <= 3 && idas >=1){ // swedbank
		new Float:vehx,Float:vehy,Float:vehz;
		GetVehicleModelInfo(GetVehicleModel(Begliai[BeglioCar]), VEHICLE_MODEL_INFO_SIZE, vehx, vehy, vehz); 


		Begliai[SurfBotai][0]=FCNPC_Create("SurfBotas0");
		FCNPC_Spawn(Begliai[SurfBotai][0], random(300), 0.0,0.0,0.0);
		Begliai[SurfBotulabel][0]=CreateDynamic3DTextLabel(f("Fugitive (%i)",Begliai[SurfBotai][0]), 0xFFFFFFFF, 0.0,0.0,0.5, 25.0,Begliai[SurfBotai][0]);

		// setting the weapons and offsets for surfing bots
		FCNPC_SetWeapon(Begliai[SurfBotai][0], 30);
		FCNPC_SetAmmo(Begliai[SurfBotai][0],2000);
		SetPlayerColor(Begliai[SurfBotai][0], 0x0000FFFF);
		FCNPC_SetSurfingOffsets(Begliai[SurfBotai][0],0.7,0.0,vehz+0.1);
		FCNPC_SetSurfingVehicle(Begliai[SurfBotai][0], Begliai[BeglioCar]);


		Begliai[SurfBotai][1]=FCNPC_Create("SurfBotas1");
		FCNPC_Spawn(Begliai[SurfBotai][1], random(300), 0.0,0.0,0.0);
		Begliai[SurfBotulabel][1]=CreateDynamic3DTextLabel(f("Fugitive (%i)",Begliai[SurfBotai][1]), 0xFFFFFFFF, 0.0,0.0,0.5, 25.0,Begliai[SurfBotai][1]);

		FCNPC_SetWeapon(Begliai[SurfBotai][1], 29);
		FCNPC_SetAmmo(Begliai[SurfBotai][1],2000);
		SetPlayerColor(Begliai[SurfBotai][1], 0x0000FFFF);
		FCNPC_SetSurfingOffsets(Begliai[SurfBotai][1],-0.7,0.0,vehz+0.1);
		FCNPC_SetSurfingVehicle(Begliai[SurfBotai][1], Begliai[BeglioCar]);

		// sending the message to all police officers
		foreach(new i : Player){
			if(IsPoliceOffer(i)){ 
			
				SendClientMessage(i, 0x32CD32FF, "DISPATCHER : "COL_WHITE"It has been reported that a 3 fugitives heve robbed a bank and are on the run.");
				SendClientMessage(i, 0x32CD32FF, "DISPATCHER : "COL_WHITE"The have been marked on the map. Go and catch them.");
				SetPlayerMarkerForPlayer(i, Begliai[npcidas], 0x3399FFFF);
				SetPlayerMarkerForPlayer(i, Begliai[SurfBotai][0], 0x3399FFFF);
				SetPlayerMarkerForPlayer(i, Begliai[SurfBotai][1], 0x3399FFFF);
			}
		}

		// paleidþiamas update timeris.
		Begliai[BotTim]=SetTimer("BeglioTimeris", 2000, true);
	}
	else if(idas <= 6){ // no surfing bots. hit and run scenario
	
		foreach(new i : Player){
			if(IsPoliceOffer(i)){ 
				SendClientMessage(i, 0x32CD32FF, "DISPATCHER : "COL_WHITE"It has been reported that a fugitive has hit a man and is on the run.");
				SendClientMessage(i, 0x32CD32FF, "DISPATCHER : "COL_WHITE"The have been marked on the map. Go and catch them.");
				SetPlayerMarkerForPlayer(i, Begliai[npcidas], 0x3399FFFF);
			}
		}
	}
	else if(idas <= 9){ // store robbing scenario - 1 bot
	


		new Float:vehx,Float:vehy,Float:vehz;
		GetVehicleModelInfo(GetVehicleModel(Begliai[BeglioCar]), VEHICLE_MODEL_INFO_SIZE, vehx, vehy, vehz); 

		Begliai[SurfBotai][0]=FCNPC_Create("SurfBotas0");
		FCNPC_Spawn(Begliai[SurfBotai][0], random(300), 0.0,0.0,0.0);
		Begliai[SurfBotulabel][0]=CreateDynamic3DTextLabel(f("Fugitive (%i)",Begliai[SurfBotai][0]), 0xFFFFFFFF, 0.0,0.0,0.5, 25.0,Begliai[SurfBotai][0]);

		
		FCNPC_SetSurfingOffsets(Begliai[SurfBotai][0],0.0,0.0,vehz+0.1);
		FCNPC_SetSurfingVehicle(Begliai[SurfBotai][0], Begliai[BeglioCar]);
		FCNPC_SetWeapon(Begliai[SurfBotai][0], 29);
		FCNPC_SetAmmo(Begliai[SurfBotai][0],2000);
		SetPlayerColor(Begliai[SurfBotai][0], 0x0000FFAA);


		foreach(new i : Player)
		{
			if(IsPoliceOffer(i)) 
			{
				SendClientMessage(i, 0x32CD32FF, "DISPATCHER : "COL_WHITE"It has been reported that 2 fugitives have robbed a store and are on the run.");
				SendClientMessage(i, 0x32CD32FF, "DISPATCHER : "COL_WHITE"The have been marked on the map. Go and catch them.");
				SetPlayerMarkerForPlayer(i, Begliai[npcidas], 0x3399FFFF);
				SetPlayerMarkerForPlayer(i, Begliai[SurfBotai][0], 0x3399FFFF);
			}
		}

		Begliai[BotTim]=SetTimer("BeglioTimeris", 3000, true);
	}
	Begliai[BGyvybes]=1000; // setting the vehicle health


	FCNPC_StartPlayingPlayback(Begliai[npcidas], recording); // path is set on the driver.

	Begliai[bbusena]=1;
	return 1;
}




forward FCNPC_OnDeath(npcid, killerid, reason);
public FCNPC_OnDeath(npcid, killerid, reason)
{
	// On death the guns are taken away
	FCNPC_SetWeapon(npcid, 0);
	FCNPC_Respawn(npcid);
	
	return 1;
}

forward FCNPC_OnWeaponShot(npcid, weaponid, hittype, hitid, Float:fX, Float:fY, Float:fZ);
public FCNPC_OnWeaponShot(npcid, weaponid, hittype, hitid, Float:fX, Float:fY, Float:fZ)
{
	if(hittype == BULLET_HIT_TYPE_PLAYER)
	{
		if(FCNPC_IsValid(hitid) && hitid == Begliai[npcidas])
		{
			FCNPC_SetHealth(hitid,100); // This makes so that you cant shoot the driver, you have to destroy the vehicle first.
		}
	}
	return 1;
}

forward FCNPC_OnDestroy(npcid);
public FCNPC_OnDestroy(npcid)
{

	// If the npc is jailed the icons are removed and if all of them have been jailed the state is changed.
	new suc;

	if(npcid == Begliai[npcidas])
	{
		foreach(new playerid : Player)
		{
			if(IsPoliceOffer(playerid))RemovePlayerMapIcon(playerid, 72);
		}
	}
	else if(!FCNPC_IsSpawned(Begliai[npcidas]))suc++;



	for(new j = 0;j<=1;j++)
	{
		if(Begliai[SurfBotai][j] == npcid)
		{
			suc++;
			foreach(new playerid : Player)
			{
				if(IsPoliceOffer(playerid))RemovePlayerMapIcon(playerid, 70+j);
			}
		}
		else if(!FCNPC_IsSpawned(Begliai[SurfBotai][j]))suc++;
		if(suc == 3)
		{
			Begliai[bbusena]=0;
			Begliai[KurisPathas]=0;
		}
	}
	return 1;
}


forward FCNPC_OnRespawn(npcid);
public  FCNPC_OnRespawn(npcid)
{

	// On spawn the guns are taken away, stops the shooting and applies an animation
	FCNPC_StopAim(npcid);
	FCNPC_StopAttack(npcid);

	if(FCNPC_GetSurfingVehicle(npcid) >0)
	{
		new Float:jx,Float:jy,Float:jz;
		FCNPC_GetPosition(npcid, jx, jy, jz);
		FCNPC_SetPosition(npcid, jx,jy,jz-0.5);
	}
	FCNPC_StopSurfing(npcid);

	FCNPC_ApplyAnimation(npcid, "CRACK", "crckdeth2", 4.0, 1, 0, 0, 1, 0);	

	if(npcid == Begliai[npcidas])Begliai[bbusena]=2;
}


forward FCNPC_OnFinishPlayback(npcid);
public FCNPC_OnFinishPlayback(npcid)
{
	// èia baigus pathà yra parenkamas naujas ir uþdedamas jam vaþiuot.

	if(npcid == Begliai[npcidas])
	{

		if(Begliai[BGyvybes]>10)
		{
			new recording[20];
			new idas = PickNpcID();

			Begliai[KurisPathas]=idas;
			switch(idas)
			{
				case 1:recording = "swedbank1";
				case 2:recording = "swedbank2";
				case 3:recording = "swedbank3";
				case 4:recording = "nutrenke1";
				case 5:recording = "nutrenke2";
				case 6:recording = "nutrenke3";
				case 7:recording = "apiplese1";
				case 8:recording = "apiplese2";
				case 9:recording = "apiplese3";
			}
			FCNPC_StartPlayingPlayback(Begliai[npcidas], recording);
		}
		
	}
	return 1;

}

stock PickNpcID()
{
	new idas;
	new randpick = random(2)+1;

	// choosing a new path that isn't the same. Quite a bad code, i know. I really don't want to rewrite it.
	switch(Begliai[KurisPathas])
	{
		case 0:idas = random(9)+1;
		case 1:
		{
			if(randpick == 1)idas = 2;
			else if(randpick == 2)idas = 3;
		}
		case 2:
		{
			if(randpick == 1)idas = 1;
			else if(randpick == 2)idas = 3;
		}
		case 3:
		{
			if(randpick == 1)idas = 1;
			else if(randpick == 2)idas = 2;
		}
		case 4:
		{
			if(randpick == 1)idas = 5;
			else if(randpick == 2)idas = 6;
		}
		case 5:
		{
			if(randpick == 1)idas = 4;
			else if(randpick == 2)idas = 6;
		}
		case 6:
		{
			if(randpick == 1)idas = 4;
			else if(randpick == 2)idas = 5;
		}
		case 7:
		{
			if(randpick == 1)idas = 8;
			else if(randpick == 2)idas = 9;
		}
		case 8:
		{
			if(randpick == 1)idas = 7;
			else if(randpick == 2)idas = 9;
		}
		case 9:
		{
			if(randpick == 1)idas = 7;
			else if(randpick == 2)idas = 8;
		}
	}
	return idas;

}




stock StopFugitive() 
{
	SetVehicleHealth(Begliai[BeglioCar], 0);
	FCNPC_StopPlayingPlayback(Begliai[npcidas]);
	FCNPC_RemoveFromVehicle(Begliai[npcidas]);
	return 1;
}

hook OnVehicleDeath(vehicleid, killerid)
{
	// When the vehicle dies, the driver gets thrown out and the vehicle destroyed
	if(Begliai[BeglioCar]==vehicleid)
	{
		KillTimer(Begliai[BotTim]);
		DestroyVehicle(vehicleid);
		Begliai[BeglioCar]=-1;
	}
}


CMD:telenpc(playerid)
{
	new Float:x,Float:y,Float:z;
	FCNPC_GetPosition(Begliai[npcidas], x, y, z);
	SetPlayerPos(playerid, x, y, z);
	return 1;
}


forward BeglioTimeris(); // fugitive timer
public BeglioTimeris()
{

	new Float:pxz,Float:pyz,Float:pzz;
	new Float:ppx,Float:ppy,Float:ppz;

	GetVehiclePos(Begliai[BeglioCar], pxz,pyz,pzz);

	new Float:dist=5000;
	new att=-1;
	new Float:laikdist;

	new Float:BegPos[3][3];


	if(FCNPC_IsSpawned(Begliai[SurfBotai][0]))FCNPC_GetPosition(Begliai[SurfBotai][0], BegPos[0][0],BegPos[0][1],BegPos[0][2]);
	if(FCNPC_IsSpawned(Begliai[SurfBotai][1]))FCNPC_GetPosition(Begliai[SurfBotai][1], BegPos[1][0],BegPos[1][1],BegPos[1][2]);
	if(FCNPC_IsSpawned(Begliai[npcidas]))FCNPC_GetPosition(Begliai[npcidas], BegPos[2][0],BegPos[2][1],BegPos[2][2]);


	// updating icons for police officers
	foreach(new i : Player)
	{
		if(IsPoliceOffer(i)) 
		{
			GetPlayerPos(i, ppx, ppy, ppz);
			laikdist = GetDistance(ppx,ppy,ppz,pxz,pyz,pzz);
			if(laikdist < dist)
			{
				att = i;
				dist = laikdist;
			}
			if(BegPos[0][0]!=0.0)SetPlayerMapIcon(i, 70, BegPos[0][0],BegPos[0][1],BegPos[0][2], 0, 0x00FF00FF, MAPICON_GLOBAL);
			if(BegPos[1][0]!=0.0)SetPlayerMapIcon(i, 71, BegPos[1][0],BegPos[1][1],BegPos[1][2], 0, 0x00FF00FF, MAPICON_GLOBAL);
			if(BegPos[2][0]!=0.0)SetPlayerMapIcon(i, 72, BegPos[2][0],BegPos[2][1],BegPos[2][2], 0, 0x00FF00FF, MAPICON_GLOBAL);
		}
	}

	// code aboe checks if the nearest player is a police officer. Below it checks if the npc is on a vehicle(surfing) and then it orders it to shoot. 
	if(FCNPC_GetSurfingVehicle(Begliai[SurfBotai][0]) <= 0 && FCNPC_GetSurfingVehicle(Begliai[SurfBotai][1]) <= 0)return 1;

	new nulinis = Begliai[SurfBotai][0];
	new pirminis = Begliai[SurfBotai][1];	

	if(IsPlayerInRangeOfPoint(att, 50.0, pxz, pyz, pzz))
	{

		if(FCNPC_GetSurfingVehicle(nulinis > 0))
		{
			if(FCNPC_GetAimingPlayer(nulinis) != att)FCNPC_AimAtPlayer(nulinis, att, true);
			
		}
		if(FCNPC_GetSurfingVehicle(pirminis > 0))
		{
			if(FCNPC_GetAimingPlayer(pirminis) != att)FCNPC_AimAtPlayer(pirminis, att, true);
		}

	}
	else
	{
		if(FCNPC_GetSurfingVehicle(Begliai[SurfBotai][0] > 0))FCNPC_StopAim(Begliai[SurfBotai][0]);
		if(FCNPC_GetSurfingVehicle(Begliai[SurfBotai][1] > 0))FCNPC_StopAim(Begliai[SurfBotai][1]);
	}
	return 1;
}

hook OnPlayerWeaponShot(playerid, weaponid, hittype, hitid, Float:fX, Float:fY, Float:fZ)
{
	if(hittype == 2)
	{
		if(hitid == Begliai[BeglioCar])
		{
			new Float:dmg;
			switch(weaponid)
			{
				case WEAPON_COLT45: dmg=25 * 0.33; //8.25
				case WEAPON_SILENCED: dmg=40 * 0.33; //13.200012
				case WEAPON_DEAGLE: dmg=140 * 0.33; //46.200013
				case WEAPON_SHOTGUN: dmg=10 * 0.33; //30.0 (probably because of pellets)
				case WEAPON_SAWEDOFF: dmg=10 * 0.33; //30.0 (probably because of pellets)
				case WEAPON_SHOTGSPA: dmg=15 * 0.33; //30.0 (probably because of pellets)
				case WEAPON_UZI:dmg= 20 * 0.33; //6.599976
				case WEAPON_TEC9: dmg=20 * 0.33;//6.599976
				case WEAPON_MP5: dmg=25 * 0.33; //8.25
				case WEAPON_AK47: dmg=30 * 0.33; //9.900024
				case WEAPON_M4: dmg=30 * 0.33; //9.900024
				case WEAPON_RIFLE: dmg=75 * 0.33; //24.799987
				case WEAPON_SNIPER: dmg=125 * 0.33; //41.299987
				case WEAPON_MINIGUN: dmg=140 * 0.33; //46.200013
			}
			Begliai[BGyvybes]-=dmg;
			if(Begliai[BGyvybes]<10)StopFugitive();
		}
	}
}

CMD:cuff(playerid,params[])
{
    if(IsPlayerInAnyVehicle(playerid))return Error(playerid, "Transporto priemonëje surakinti negalima.");
    new id, Float:playerPos[ 3 ];
	
    if(IsNumeric(params)){ // 
		sscanf(params,"i",id);
		if(IsPlayerNPC(id)){

			if(id == Begliai[npcidas]){

				FCNPC_GetPosition(id, playerPos[ 0 ], playerPos[ 1 ], playerPos[ 2 ]);
		    	if(!IsPlayerInRangeOfPoint(playerid, 5.0, playerPos[ 0 ], playerPos[ 1 ], playerPos[ 2 ])) return Error(playerid, "Fugitive is too far away");

				if(FCNPC_GetSpecialAction(id) == SPECIAL_ACTION_CUFFED)return Error(playerid,"Fugitive is already cuffed");

				FCNPC_ClearAnimations(id);
				FCNPC_SetSpecialAction(id, SPECIAL_ACTION_CUFFED);
				Success(playerid,"Fugitive sucessfully handcuffed.");
				
				return 1;
			}
			for(new j = 0; j<=1;j++){
				if(id == Begliai[SurfBotai][j])
				{
					if(FCNPC_GetSurfingVehicle(id)>0)return Error(playerid,"You can't handcuff fugitive while he's on a vehicle");
					FCNPC_GetPosition(id, playerPos[ 0 ], playerPos[ 1 ], playerPos[ 2 ]);
			    	if(!IsPlayerInRangeOfPoint(playerid, 5.0, playerPos[ 0 ], playerPos[ 1 ], playerPos[ 2 ])) return Error(playerid, "Fugitive is too far away.");

					if(FCNPC_GetSpecialAction(id) == SPECIAL_ACTION_CUFFED)return Error(playerid,"Fugitive is already cuffed");

					FCNPC_ClearAnimations(id);
					FCNPC_SetSpecialAction(id, SPECIAL_ACTION_CUFFED);
					Success(playerid,"Fugitive sucessfully handcuffed.");
					return 1;
				}
			}
			return 1;
		}
	}
	return 1;
}



CMD:drag(playerid,params[])
{
    if(IsPlayerInAnyVehicle(playerid))return Error(playerid, "Cannot be used while in a vehicle");
    new id, Float: playerPos[ 3 ];
	if(IsNumeric(params)){ // same as with /cuff
		sscanf(params, "i", id);
		if(IsPlayerNPC(id)){
			if(id == Begliai[npcidas]){
				FCNPC_GetPosition(id, playerPos[ 0 ], playerPos[ 1 ], playerPos[ 2 ]);
	    		if(!IsPlayerInRangeOfPoint(playerid, 5.0, playerPos[ 0 ], playerPos[ 1 ], playerPos[ 2 ])) return Error(playerid, "Fugitive is too far away");

				if(vilkimo_busena[id] > -1){
					if(vilkimo_busena[id] != playerid)return Error(playerid, "Fugitive is already being dragged by someone else.");
					vilkimo_busena[id]=-1;
					return Success(playerid, "Fugitive dragging stopped.");
				}

				if(FCNPC_GetSpecialAction(id) != SPECIAL_ACTION_CUFFED)return Error(playerid,"Fugitive must be handcuffed.");
				vilkimo_busena[id]=playerid;
				vilkimo_busena[playerid]=id;
				Info(playerid,"You have started dragging the fugitive");
				return 1;
			}

			for(new j = 0;j<=1;j++){
				if(id == Begliai[SurfBotai][j]){
					FCNPC_GetPosition(id, playerPos[ 0 ], playerPos[ 1 ], playerPos[ 2 ]);
		    		if(!IsPlayerInRangeOfPoint(playerid, 5.0, playerPos[ 0 ], playerPos[ 1 ], playerPos[ 2 ])) return Error(playerid, "Fugitive is too far away");


					if(vilkimo_busena[id] > -1){
						if(vilkimo_busena[id] != playerid)return Error(playerid, "Fugitive is already being dragged by someone else.");
						vilkimo_busena[id]=-1;
						return Success(playerid, "Fugitive dragging stopped.");
					}

					if(FCNPC_GetSpecialAction(id) != SPECIAL_ACTION_CUFFED)return Error(playerid,"Fugitive must be handcuffed.");
					vilkimo_busena[id]=playerid;
					vilkimo_busena[playerid]=id;
					Info(playerid,"You have started dragging the fugitive");
					return 1;
				}
			}

			return 1;
		}
	}
	return 1;
}

forward checkdrag();
public checkdrag()
{
	new Float:begx,Float:begy,Float:begz;
	new player;
	foreach(new i : NPC)
	{
		player = vilkimo_busena[i];
		if(player > -1){
			if(!IsPlayerInAnyVehicle(player))
			{
				if(FCNPC_GetVehicleID(i)>0)FCNPC_RemoveFromVehicle(i);
				GetXYBehindPlayer(player,begx,begy,begz,1.0);
				FCNPC_SetVirtualWorld(i, GetPlayerVirtualWorld(player));
				FCNPC_SetPosition(i, begx,begy,begz);
			}
			if(IsPlayerInRangeOfPoint(player, 5.0, ARESTINE_POS))
			{
				new xps = random(2)+2;
				new pingai = random(200)+600;
				new msg[140];

				format(msg,sizeof(msg),"Fugitive has been sucessfully locked up. You earned "GREEN1"%i €, %i XP.",pingai,xps);
				Success(player, msg);

				FCNPC_Destroy(i);

				vilkimo_busena[i]=-1;
				vilkimo_busena[player]=-1;
			}
		}
	}
}


forward MinuteTimer();
public MinuteTimer()
{
	if(!Begliai[bbusena]){
		BeglysLaunchTime++;
		if(BeglysLaunchTime == BEGLIAI_LAUNCH_MINUTES){
			launchbeglys();
		}
	}
}


// Change to your way of checking if player is a police officer or not.
IsPoliceOffer(playerid)
{
	return true;
}

public Float:GetDistance(Float:x11,Float:y11,Float:z11, Float:x22,Float:y22,Float:z22)
{
	new Float:v = floatsqroot(floatpower(floatabs(floatsub(x22,x11)),2)+floatpower(floatabs(floatsub(y22,y11)),2)+floatpower(floatabs(floatsub(z22,z11)),2));
	return v;
}

stock IsNumeric(const string[])
{
    new laik;
	if(sscanf(string,"i",laik))return 0;
    return 1;
}

GetXYBehindPlayer(playerid, &Float:q, &Float:w,&Float:z, Float:distance)
{
    new Float:a;
    GetPlayerPos(playerid, q, w, z);
    GetPlayerFacingAngle(playerid, a);
    q += (distance * -floatsin(-a, degrees));
    w += (distance * -floatcos(-a, degrees));
}
