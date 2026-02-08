class ZEDRunPT_Endless extends KFGameInfo_Endless;

function BossDied(Controller Killer, optional bool bCheckWaveEnded = true)
{
	local KFPawn_Monster AIP;
	// local KFPlayerController KFPC;

	// super.BossDied(Killer, bCheckWaveEnded);

	// KFPC = KFPlayerController(Killer);
	// `RecordBossMurderer(KFPC);

 	// Extended zed time for an extra dramatic event
 	DramaticEvent( 1, 6.f );

	foreach WorldInfo.AllPawns(class'KFPawn_Monster', AIP)
	{
		if (AIP.Health > 0)
		{
			return; //AIP.Died(none, none, AIP.Location);
		}
	}

	if (KFAISpawnManager_Endless(SpawnManager) != none)
	{
		KFAISpawnManager_Endless(SpawnManager).OnBossDied();
	}

	IncrementDifficulty();

	SetBossIndex();

	if (bCheckWaveEnded)
	{
		CheckWaveEnd(true);
	}
}

static function bool HasCustomTraderVoiceGroup()
{
	return true;
}

defaultproperties
{
	bIsEndlessGame=true
	bIsInHoePlus=false

	HUDType=class'ZEDRun.KFGFXHudWrapper_ZEDRun'
	PlayerControllerClass=class'ZEDRun.KFPlayerControllerZEDRun' //custom controller
	SpawnManagerClasses(0)=class'KFGameContent.KFAISpawnManager_Endless'
	GameReplicationInfoClass=class'ZEDRun.KFGameReplicationInfo_ZEDRun_Endless'
	OutbreakEventClass=class'KFOutbreakEvent_Endless'
	TraderVoiceGroupClass=class'KFGameContent.KFTraderVoiceGroup_Patriarch' //plays patty VO for trader
	DefaultPawnClass=class'ZEDRun.KFPawn_ZEDRunner_PAT' //custom starting pawn so that we can play as custom ZED
	DifficultyInfoClass=class'KFGameDifficulty_Endless'
	DifficultyInfoConsoleClass=class'KFGameDifficulty_Endless_Console'
}