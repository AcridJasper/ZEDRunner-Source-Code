class ZEDRunFP extends KFGameInfo_Survival;

function BossDied(Controller Killer, optional bool bCheckWaveEnded = true)
{
	local KFPawn_Monster AIP;
	local KFGameReplicationInfo KFGRI;

	// super.BossDied(Killer, bCheckWaveEnded);

	KFGRI = KFGameReplicationInfo(WorldInfo.GRI);
	if( KFGRI != none && !KFGRI.IsBossWave() )
	{
		return;
	}

    EndOfMatch( true ); // just end my life bros
	GotoState('MatchEnded');

 	// Extended zed time for an extra dramatic event
 	DramaticEvent( 1, 6.f );

	// Do not kill all active zeds when the game ends (so that player ZED doesn't die)
	foreach WorldInfo.AllPawns(class'KFPawn_Monster', AIP)
	{
		if( AIP.Health > 0 )
		{
			return; //AIP.Died(none , none, AIP.Location);
		}
	}
	if(bCheckWaveEnded)
	{
		CheckWaveEnd( true );
	}

/*
	if(KilledPawn.IsA('KFPawn_ZedBloatKing')
		&& KilledPawn.IsA('KFPawn_ZedBloatKing_SantasWorkshop')
		&& KilledPawn.IsA('KFPawn_ZedFleshpoundKing')
		&& KilledPawn.IsA('KFPawn_ZedHans')
		&& KilledPawn.IsA('KFPawn_ZedMatriarch')
		&& KilledPawn.IsA('KFPawn_ZedPatriarch'))
	{
    	EndOfMatch( true ); // just end my life bros
		GotoState('MatchEnded');
	}
*/
}

/*
function Killed(Controller Killer, Controller KilledPlayer, Pawn KilledPawn, class<DamageType> damageType)
{
	local Sequence GameSeq;
	local array<SequenceObject> AllWaveProgressEvents;
	local KFSeqEvent_WaveProgress WaveProgressEvt;
	local int i;
	local KFInterface_MapObjective MapObj;

	super.Killed(Killer, KilledPlayer, KilledPawn, damageType);

	if(KilledPawn.IsA('KFPawn_ZedBloatKing')
		&& KilledPawn.IsA('KFPawn_ZedBloatKing_SantasWorkshop')
		&& KilledPawn.IsA('KFPawn_ZedFleshpoundKing')
		&& KilledPawn.IsA('KFPawn_ZedHans')
		&& KilledPawn.IsA('KFPawn_ZedMatriarch')
		&& KilledPawn.IsA('KFPawn_ZedPatriarch'))
	{
    	EndOfMatch( true ); // just end my life bros
		GotoState('MatchEnded');
	}

	// tell objectives (ie dosh hold and exterminate) when something dies
	if (KilledPawn.IsA('KFPawn_Monster'))
	{
		MapObj = KFInterface_MapObjective(MyKFGRI.CurrentObjective);
		if (MapObj != none)
		{
			MapObj.NotifyZedKilled(Killer, KilledPawn, KFInterface_MonsterBoss(KilledPawn) != none);
		}
	}

	// if not boss wave or endless wave, play progress update trader dialog
	if( !MyKFGRI.IsBossWave() && !MyKFGRI.IsEndlessWave() && KilledPawn.IsA('KFPawn_Monster') )
    {
    	// no KFTraderDialogManager object on dedicated server, so use static function
    	class'KFTraderDialogManager'.static.PlayGlobalWaveProgressDialog( MyKFGRI.AIRemaining, MyKFGRI.WaveTotalAICount, WorldInfo );

		// Get the gameplay sequence.
		GameSeq = WorldInfo.GetGameSequence();

		if (GameSeq != none)
		{
			GameSeq.FindSeqObjectsByClass(class'KFSeqEvent_WaveProgress', TRUE, AllWaveProgressEvents);

			for (i = 0; i < AllWaveProgressEvents.Length; i++)
			{
				WaveProgressEvt = KFSeqEvent_WaveProgress(AllWaveProgressEvents[i]);

				if (WaveProgressEvt != None)
				{
					WaveProgressEvt.SetWaveProgress(MyKFGRI.AIRemaining, MyKFGRI.WaveTotalAICount, self);
				}
			}
		}
	}

    //If a human died to a non-suicide
    if (KilledPawn.IsA('KFPawn_Human') && DamageType != class'DmgType_Suicided')
    {
        bHumanDeathsLastWave = true;
    }

	// BossDied will handle the end of wave.
	if(!(KFPawn_Monster(KilledPawn) != none && KFPawn_Monster(KilledPawn).IsABoss()))
	{
		CheckWaveEnd();
	}
}
*/

static function bool HasCustomTraderVoiceGroup()
{
	return true;
}

DefaultProperties
{
	TimeBetweenWaves=5
	EndCinematicDelay=2

	HUDType=class'ZEDRun.KFGFXHudWrapper_ZEDRun'
	PlayerControllerClass=class'ZEDRun.KFPlayerControllerZEDRun' //custom controller
	PlayerReplicationInfoClass=class'KFGame.KFPlayerReplicationInfo'
	GameReplicationInfoClass=class'ZEDRun.KFGameReplicationInfo_ZEDRun'
	TraderVoiceGroupClass=class'KFGameContent.KFTraderVoiceGroup_Patriarch' //plays patty VO for trader
	DefaultPawnClass=class'ZEDRun.KFPawn_ZEDRunner' //custom starting pawn so that we can play as custom ZED
	DifficultyInfoClass=class'KFGameDifficulty_Survival'
	DifficultyInfoConsoleClass=class'KFGameDifficulty_Versus_Console'
}