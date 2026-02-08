class KFSM_ZEDRunner_Rage extends KFSM_Zed_Taunt;

/** Restrictions for doing rage taunt */
protected function bool InternalCanDoSpecialMove()
{
	local KFPawn_ZEDRunner MyFPPawn;

	MyFPPawn = KFPawn_ZEDRunner( KFPOwner );
	if( MyFPPawn != none )
	{
		return super.InternalCanDoSpecialMove() && !MyFPPawn.bIsEnraged;
	}

	// check here for cooldowns

	return super.InternalCanDoSpecialMove();
}

static function byte PackFlagsBase( KFPawn P )
{
	local byte Variant;
	local KFPawnAnimInfo PAI;

	PAI = P.PawnAnimInfo;
	Variant = Rand(PAI.TauntEnragedAnims.Length);

	if ( Variant != 255 )
	{
		return TAUNT_Enraged + (Variant << 4);
	}
	else
	{
		return 255;
	}
}

function SpecialMoveStarted(bool bForced, Name PrevMove)
{
	local KFPawn_ZEDRunner MyFPPawn;

	MyFPPawn = KFPawn_ZEDRunner( KFPOwner );
	if( MyFPPawn != none )
	{
		MyFPPawn.SetEnraged( true );
	}

	Super.SpecialMoveStarted(bForced, PrevMove);
}

defaultproperties
{

}