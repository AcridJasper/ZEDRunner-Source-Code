class KFPlayerControllerZEDRun extends KFPlayerController;

// var string BossName;

/*
event PlayerTick( float DeltaTime )
{
	super.PlayerTick(DeltaTime);

	if( ViewTarget == self )
	{
		SetCameraMode( 'ThirdPerson' );
	}

	if( PlayerCamera.CameraStyle != 'FirstPerson' )
	{
		ServerCamera('ThirdPerson');
	}
}
*/

/*
simulated event PostBeginPlay()
{
	super.PostBeginPlay();

	if ( WorldInfo.NetMode == NM_Client )
	{
		AddCheats(true);
	}
}
*/

function Restart(bool bVehicleTransition)
{
	super.Restart( bVehicleTransition );

	if( GetTeamNum() == 0 )
	{
	    KFThirdPersonCamera(KFPlayerCamera(PlayerCamera).ThirdPersonCam).SetViewOffset( KFPawn_Monster(Pawn).ThirdPersonViewOffset );

		if( PlayerCamera.CameraStyle != 'Boss' )
		{
			ServerCamera('ThirdPerson');
		}
	}
}

reliable client function ClientRestart(Pawn NewPawn)
{
	Super.ClientRestart(NewPawn);

	if(NewPawn == none)
	{
		return;
	}

	if( Role < ROLE_Authority && GetTeamNum() == 0 )
	{
	    KFThirdPersonCamera(KFPlayerCamera(PlayerCamera).ThirdPersonCam).SetViewOffset( KFPawn_Monster(Pawn).ThirdPersonViewOffset );

		if( PlayerCamera.CameraStyle != 'Boss' )
		{
			SetCameraMode('ThirdPerson');
		}
	}
}

// GBA_SwitchAltFire
exec function StartAltFire(optional Byte FireModeNum )
{
	if( Pawn != none && (Pawn.Weapon == none || Pawn.Weapon.ShouldWeaponIgnoreStartFire()) )
	{
		Pawn.StartFire(4);
		return;
	}

	super.StartAltFire();
}

// GBA_SwitchAltFire
// Weapons that override AltFireMode (e.g. welder) and call StartFire also need to call StopFire. For most weapons this is unnecessary.
exec function StopAltFire(optional Byte FireModeNum )
{
	if( Pawn != none && (Pawn.Weapon == none || Pawn.Weapon.ShouldWeaponIgnoreStartFire()) )
	{
		Pawn.StopFire(4);
		return;
	}

	super.StopAltFire();
}

// TRUE if any of the gameplay post process effects have a strength greater than 0. Append to this list if additional effects are added
function bool ShouldDisplayGameplayPostProcessFX()
{
    // Overridden because the zeds health vary so much, it needs to be a percentage of max health - Ramm
	return super.ShouldDisplayGameplayPostProcessFX()
			|| (GetTeamNum() == 0 && Pawn != none && (Pawn.Health / float(Pawn.HealthMax)) * 100.f <= default.LowHealthThreshold);
}

state Dead
{
	event BeginState(Name PreviousStateName)
	{
		super.BeginState( PreviousStateName );

		// Reset camera offset
		if( GetTeamNum() == 0 )
		{
		    KFThirdPersonCamera(KFPlayerCamera(PlayerCamera).ThirdPersonCam).SetViewOffset( class'KFThirdPersonCameraMode'.static.GetDefaultOffset() );
		}
	}
}

// Called when view target is changed while in spectating state
function NotifyChangeSpectateViewTarget()
{
	local KFPawn_Monster KFPM;

	super.NotifyChangeSpectateViewTarget();

	KFPM = KFPawn_Monster( ViewTarget );
	if( KFPM != none )
	{
	    KFThirdPersonCamera(KFPlayerCamera(PlayerCamera).ThirdPersonCam).SetViewOffset( KFPM.default.ThirdPersonViewOffset );
	}
}

// Level was reset without reloading
function Reset()
{
	// Only reset active players!
	if( CanRestartPlayer() )
	{
		SetViewTarget( self );
	    ResetCameraMode();
	    FixFOV();

	 	// This is necessary because the server will try to synchronize pawns with the client when the client
	 	// is in the middle of trying to clean its pawn reference up. The ClientRestart() function sends the
	 	// client into a state (WaitingForPawn) where it thinks the server is about to replicate a new pawn,
	 	// but it isn't, so the client gets stuck there forever.
	    AcknowledgedPawn = none;

		// PlayerZedSpawnInfo.PendingZedPawnClass = none;
		// PlayerZedSpawnInfo.PendingZedSpawnLocation = vect( 0,0,0 );
	}
}

// Level was reset without reloading
reliable client function ClientReset()
{
	local Actor A;
	local array<Actor> BloodSplatActors;
	local int i;

	// Ensures this only runs once on listen servers
	if( !IsLocalPlayerController() )
	{
		return;
	}

	// Reset all actors (except controllers and blood splats)
	foreach AllActors( class'Actor', A )
	{
		if( A.IsA('KFPersistentBloodActor') )
		{
			BloodSplatActors.AddItem( A );
			continue;
		}

		if( WorldInfo.NetMode == NM_Client && !A.IsA('Controller') )
		{
			A.Reset();
		}
	}

	// Reset blood splat actors after everything else
	for( i = 0; i < BloodSplatActors.Length; ++i )
	{
		BloodSplatActors[i].Reset();
	}
}

// this pretty much let's you do attacks if you're ZED
// Spawn the appropriate class of PlayerInput only called for playercontrollers that belong to local players
event InitInputSystem()
{
	Super.InitInputSystem();

	KFPlayerInput(PlayerInput).bVersusInput = true;
}

/*
// Returns TRUE if player is in a state that allows them to be spawned
function bool IsReadyToPlay()
{
	return WorldInfo.Game != none ? KFGameInfo(WorldInfo.Game).IsPlayerReady( KFPlayerReplicationInfo(PlayerReplicationInfo) ) : PlayerReplicationInfo.bReadyToPlay;

	if( Role == ROLE_Authority && MonsterPerkClass != None )
	{
		if( GetTeamNum() > 0 )
		{
			ServerSelectPerk( 255, 0, 0, true );
		}
		else if( CurrentPerk != none && CurrentPerk.Class == MonsterPerkClass )
		{
			ServerSelectPerk( SavedPerkIndex, Perklist[SavedPerkIndex].PerkLevel, Perklist[SavedPerkIndex].PrestigeLevel, true );
		}
	}
}
*/

/*
// Returns TRUE if player is in a state that allows them to be spawned
//function bool IsReadyToPlay()
simulated function SetPlayerReady( bool bReady )
{
	//return WorldInfo.Game != none ? KFGameInfo(WorldInfo.Game).IsPlayerReady( KFPlayerReplicationInfo(PlayerReplicationInfo) ) : PlayerReplicationInfo.bReadyToPlay;

	if( Role == ROLE_Authority && MonsterPerkClass != None )
	{
		if( GetTeamNum() > 0 )
		{
			ServerSelectPerk( 255, 0, 0, true );
		}
		else if( CurrentPerk != none && CurrentPerk.Class == MonsterPerkClass )
		{
			ServerSelectPerk( SavedPerkIndex, Perklist[SavedPerkIndex].PerkLevel, Perklist[SavedPerkIndex].PrestigeLevel, true );
		}
	}
}
*/

/*
// Only called on locally controlled controllers. Must have an input object to run
event PlayerTick( float DeltaTime )
{
	super.PlayerTick(DeltaTime);

	if( ViewTarget == self )
	{
		SetCameraMode( 'ThirdPerson' );
	}
}
*/

DefaultProperties
{
	CameraClass=class'ZEDRun.KFPlayerCamera_ZEDRun'
	PostRoundMenuClass=class'KFGFxMoviePlayer_PostRoundMenu'
  	PurchaseHelperClass=none //class'KFAutoPurchaseHelper' // removes items from trader because you can still access it if you held E for autobuy

	PerkList.Add((PerkClass=class'KFPerk_ZEDRunner')) // perk does nothing, just for looks

	// Removes all perks
	PerkList.Remove((PerkClass=class'KFPerk_Berserker'))
	PerkList.Remove((PerkClass=class'KFPerk_Commando'))
	PerkList.Remove((PerkClass=class'KFPerk_Support'))
	PerkList.Remove((PerkClass=class'KFPerk_FieldMedic'))
	PerkList.Remove((PerkClass=class'KFPerk_Demolitionist'))
	PerkList.Remove((PerkClass=class'KFPerk_Firebug'))
	PerkList.Remove((PerkClass=class'KFPerk_Gunslinger'))
	PerkList.Remove((PerkClass=class'KFPerk_Sharpshooter'))
	PerkList.Remove((PerkClass=class'KFPerk_SWAT'))
	PerkList.Remove((PerkClass=class'KFPerk_Survivalist'))
}