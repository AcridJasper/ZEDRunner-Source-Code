class KFPerk_ZEDRunner extends KFPerk;

/*
simulated event PostBeginPlay()
{
	local KFPlayerReplicationInfo KFPRI;
	
	super.PostBeginPlay();

	if( Owner == none )
	{
		return;
	}

	KFPRI = KFPlayerReplicationInfo(KFPlayerController(Owner).PlayerReplicationInfo);
	if( KFPRI != none )
	{
		KFPRI.bExtraFireRange = false;
		KFPRI.bSplashActive = false;
		KFPRI.bNukeActive = false;
		KFPRI.bConcussiveActive = false;
		KFPRI.PerkSupplyLevel = 0;
	}
}
*/

DefaultProperties
{
	PerkIcon=Texture2D'UI_PerkIcons_TEX.UI_PerkIcon_ZED' // UI_PerkIcons_TEX.UI_Horzine_H_Logo
	ProgressStatID=INDEX_NONE
   	PerkBuildStatID=INDEX_NONE
}