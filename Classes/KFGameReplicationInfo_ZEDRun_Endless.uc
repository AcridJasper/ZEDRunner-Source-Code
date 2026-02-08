class KFGameReplicationInfo_ZEDRun_Endless extends KFGameReplicationInfo_Endless;

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

DefaultProperties
{
	bEndlessMode=True
	CurrentWeeklyMode=INDEX_NONE
	CurrentSpecialMode=INDEX_NONE

	bTradersEnabled=FALSE // most traders are closed but one
	UpdatePickupInfoInterval=9999999999999
	bAllowSwitchTeam=false
    bAllowGrenadePurchase=false
	bIsBrokenTrader=true // scavange
	bIsWeeklyMode=false
	bForceShowSkipTrader=true
	bAllowSeasonalSkins=false
	WeeklySelectorIndex=-1
	SeasonalSkinsIndex=-1
	bForceSkipTraderUI=true // false
}