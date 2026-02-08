class KFGameReplicationInfo_ZEDRun extends KFGameReplicationInfo;

// this "fixes" were boss theatrics place player ZED camera to firstperson
// Disabled boss spawn cam
simulated function bool ShouldSetBossCamOnBossSpawn()
{
	return false;
}

// Disabled boss death cam
simulated function bool ShouldSetBossCamOnBossDeath()
{
	return false;
}

/*
simulated function SetTeam( int Index, TeamInfo TI )
{
	if(Index == 255)
	{
		// No!!!
		Index = 1;
	}

	Super.SetTeam(Index, TI);
}

function Reset()
{
	WaveNum = 0;
	super.Reset();
}
*/

defaultproperties
{
	TraderItemsPath="GP_Trader_ARCH.DefaultTraderItems"
	TraderDialogManagerClass=class'KFGame.KFTraderDialogManager'
    bTradersEnabled=FALSE // most traders are closed but one
	VoteCollectorClass=class'KFGame.KFVoteCollector'
	UpdateZedInfoInterval=0.5
	UpdateHumanInfoInterval=0.5
	UpdatePickupInfoInterval=9999999999999
	WaveMax=255
	bAllowSwitchTeam=false
    GameAmmoCostScale=1.0
    bAllowGrenadePurchase=false
    MaxPerkLevel=4
	BossIndex=255
	PreviousObjectiveResult=-1
	PreviousObjectiveVoshResult=-1
	PreviousObjectiveXPResult=-1
	bIsBrokenTrader=true // scavange
	bIsWeeklyMode=false
	bForceShowSkipTrader=true
	bAllowSeasonalSkins=false
	WeeklySelectorIndex=-1
	SeasonalSkinsIndex=-1
	bForceSkipTraderUI=true // false
	GunGameWavesCurrent=1
	bWaveGunGameIsFinal=false
	VIPRepCurrentHealth=0
	VIPRepMaxHealth=0
	VIPRepPlayer=none
}