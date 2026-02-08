class KFPawn_ZEDRunner_PAT extends KFPawn_ZedPatriarch;

/** Cached controller */
var KFPlayerController MyKFPC;
/** The local player controller viewing this pawn */
var KFPlayerController ViewerPlayer;

/** The threshold at which to display a low health warning */
var float LowHealthThreshold;
/** Whether we've already warned of low health this phase */
var bool bWarnedLowHealthThisPhase;
/** used to keep track of heal message */
var bool bIsQuickHealMessageShowing;

/** Percentage of max health to allow healing at */
var private float HealThreshold;
/** Health threshold to perform an autoheal at */
var private float AutoHealThreshold;
/** Whether the Patriarch autohealed this phase or not */
var private bool bAutoHealed;

/** Number of charges left on our cloak */
var private repnotify byte CloakCharges;

/** Localized strings */
var localized string LowHealthMsg;
var localized string NoHealsRemainingMsg;
var localized string NoMortarTargetsMsg;

replication
{
	if( bNetOwner && bNetDirty )
		MyKFPC;

	if( bNetDirty )
		CloakCharges;
}

simulated event ReplicatedEvent( name VarName )
{
	if( VarName == nameOf(CloakCharges) )
	{
		if( IsLocallyControlled() )
		{
			UpdateCloakCharges();
		}
		return;
	}

	super.ReplicatedEvent( VarName );
}

function PossessedBy( Controller C, bool bVehicleTransition )
{
	super.PossessedBy(C, bVehicleTransition);

	MyKFPC = KFPlayerController(C);

	// Start the cloak timer
	SetTimer( 2.f + fRand(), false, nameOf(Timer_EnableCloak) );
}

/** Update our barrel spin skel control */
simulated event Tick( float DeltaTime )
{
	if( WorldInfo.NetMode != NM_DedicatedServer )
	{
		// Cache off our viewer player
		if( ViewerPlayer == none )
		{
			ViewerPlayer = KFPlayerController( WorldInfo.GetALocalPlayerController() );
		}

		UpdateHealAvailable();
		UpdateCloakIconState();
	}

	super.Tick( DeltaTime );
}

/** Increment Patriarch to the next battle phase */
function IncrementBattlePhase()
{
	super.IncrementBattlePhase();
}

// ************************************************************
//						Missle / Aiming
// ************************************************************

/** Updates our gun tracking skeletal control */
simulated function UpdateGunTrackingSkelCtrl( float DeltaTime )
{
	local rotator ViewRot;

	// Track the player with the gun arm
	if( GunTrackingSkelCtrl != none )
	{
		if( bGunTracking )
		{
			ViewRot = GetViewRotation();
			if( Role < ROLE_Authority && !IsLocallyControlled() )
			{
				ViewRot.Pitch = NormalizeRotAxis( RemoteViewPitch << 8 );
			}
			GunTrackingSkelCtrl.DesiredTargetLocation = GetPawnViewLocation() + vector(ViewRot) * 5000.f;
			GunTrackingSkelCtrl.InterpolateTargetLocation( DeltaTime );
		}
		else
		{
			GunTrackingSkelCtrl.SetSkelControlActive( false );
		}
	}
}

/** Retrieves the aim direction and target location for each missile. Called from SpecialMove */
function GetMissileAimDirAndTargetLoc( int MissileNum, vector MissileLoc, rotator MissileRot, out vector AimDir, out vector TargetLoc )
{
    local PlayerController PC;
	local vector HitLocation, HitNormal;
    local vector TraceStart, TraceEnd;
    local Actor HitActor;

    PC = PlayerController(Controller);
    if( PC == none )
    {
        return;
    }

    TraceStart = PC.PlayerCamera.CameraCache.POV.Location;
    TraceEnd = PC.PlayerCamera.CameraCache.POV.Location + vector(PC.PlayerCamera.CameraCache.POV.Rotation)*10000.f;

    HitActor = Trace( HitLocation, HitNormal, TraceEnd, TraceStart, TRUE,,, TRACEFLAG_Bullet );

    if( HitActor != none )
    {
        AimDir = Normal(HitLocation - MissileLoc);
        TargetLoc = HitLocation;
    }
    else
    {
		AimDir = Normal( TraceEnd - MissileLoc);
		TargetLoc = TraceEnd;
	}
}

// ************************************************************
//							Mortar
// ************************************************************

/** Retrieves the aim direction and target location for each mortar. Called from SpecialMove */
function GetMortarAimDirAndTargetLoc( int MissileNum, vector MissileLoc, rotator MissileRot, out vector AimDir, out vector TargetLoc, out float MissileSpeed )
{
	local Patriarch_MortarTarget MissileTarget;
	local vector X,Y,Z;

	GetAxes( MissileRot, X,Y,Z );

	// Each missile can possibly target a separate player
	MissileTarget = GetMortarTarget(MissileNum);

	// Aim at the feet
	TargetLoc = MissileTarget.TargetPawn.Location + (vect(0,0,-1)*MissileTarget.TargetPawn.GetCollisionHeight());

	// Nudge the spread a tiny bit to make the missiles less concentrated on a single point
	AimDir = Normal( vect(0,0,1) + Normal(MissileTarget.TargetVelocity) );

	// Set the missile speed
	MissileSpeed = VSize( MissileTarget.TargetVelocity );
}

/** Allows pawn to do any pre-mortar attack prep */
function PreMortarAttack()
{
	ClearMortarTargets();
	CollectMortarTargets( true, true );
	CollectMortarTargets();
}

/** Tries to set our mortar targets */
function bool CollectMortarTargets( optional bool bInitialTarget, optional bool bForceInitialTarget )
{
	local int NumTargets;
	local KFPawn_Monster KFP;
	local float TargetDistSQ;
	local vector MortarVelocity, MortarStartLoc, TargetLoc, TargetProjection;

   	MortarStartLoc = Location + vect(0,0,1)*GetCollisionHeight();
    NumTargets = bInitialTarget ? 0 : 1;
    foreach WorldInfo.AllPawns( class'KFPawn_Monster', KFP )
	{
		if( !KFP.IsAliveAndWell() || MortarTargets.Find('TargetPawn', KFP) != INDEX_NONE )
		{
			continue;
		}

		// Make sure target is in range
		TargetLoc = KFP.Location + (vect(0,0,-1)*(KFP.GetCollisionHeight()*0.8f));
		TargetProjection = MortarStartLoc - TargetLoc;
		TargetDistSQ = VSizeSQ( TargetProjection );
		if( TargetDistSQ > MinMortarRangeSQ && TargetDistSQ < MaxMortarRangeSQ )
		{
			TargetLoc += Normal(TargetProjection)*KFP.GetCollisionRadius();
			if( SuggestTossVelocity(MortarVelocity, TargetLoc, MortarStartLoc, MortarProjectileClass.default.Speed, 500.f, 1.f, vect(0,0,0),, GetGravityZ()*0.8f) )
			{
				// Make sure upward arc path is clear
				if( !FastTrace(MortarStartLoc + (Normal(vect(0,0,1) + (Normal(TargetLoc - MortarStartLoc)*0.9f))*fMax(VSize(MortarVelocity)*0.55f, 800.f)), MortarStartLoc,, true) )
				{
					continue;
				}

				MortarTargets.Insert( NumTargets, 1 );
				MortarTargets[NumTargets].TargetPawn = KFP;
				MortarTargets[NumTargets].TargetVelocity = MortarVelocity;

				if( bInitialTarget || NumTargets == 8 )
				{
					return true;
				}

				NumTargets++;
			}
		}
	}

	return false;
}

/** Clears mortar targets */
function ClearMortarTargets()
{
	MortarTargets.Length = 0;
}

// ************************************************************
//							Cloaking
// ************************************************************

/** Toggle cloaking material */
function SetCloaked(bool bNewCloaking)
{
	if( bNewCloaking && (IsDoingSpecialMove() || CloakCharges == 0) )
	{
		return;
	}

	super.SetCloaked(bNewCloaking);

	UpdateCloakedTimer();

	if( WorldInfo.NetMode != NM_DedicatedServer )
	{
		UpdateCloakCharges();
	}
}

/** Starts or stops our cloaking timer */
function UpdateCloakedTimer()
{
	if( CloakCharges == 0 || !bIsCloaking )
	{
		if( IsTimerActive(nameOf(Timer_UpdateCloakCharge)) )
		{
			ClearTimer( nameOf(Timer_UpdateCloakCharge) );
		}
		return;
	}

	if( bIsCloaking )
	{
		if( !IsTimerActive(nameOf(Timer_UpdateCloakCharge)) )
		{
			SetTimer( 1.f, true, nameOf(Timer_UpdateCloakCharge) );
		}
	}
}

/** Runs every second to tick off our cloak charges */
function Timer_UpdateCloakCharge()
{
	CloakCharges = Max( CloakCharges - 1, 0 );

	if( CloakCharges == 0 )
	{
		SetCloaked( false );
		ClearTimer( nameOf(Timer_UpdateCloakCharge) );
	}

	if( WorldInfo.NetMode != NM_DedicatedServer )
	{
		UpdateCloakCharges();
	}
}

/** Updates the number of cloak charges for UI */
private function UpdateCloakCharges()
{
	SpecialMoveCooldowns[7].Charges = CloakCharges;
}

/** Turns on the cloak after a specified amount of time */
function Timer_EnableCloak()
{
	SetCloaked( true );
}

/** Gets the minimum cloaked amount based on the viewer */
simulated protected function float GetMinCloakPct()
{
	if( ViewerPlayer != none && (ViewerPlayer.GetTeamNum() == GetTeamNum() || ViewerPlayer.PlayerReplicationInfo.bOnlySpectator) )
	{
		return 0.4f;
	}

	return super.GetMinCloakPct();
}

/** Updates the state of the cloaking icon */
private function UpdateCloakIconState()
{
	if( SpecialMoveCooldowns[7].Charges == 0 )
	{
		SpecialMoveCooldowns[7].LastUsedTime = WorldInfo.TimeSeconds;
	}
	else
	{
		SpecialMoveCooldowns[7].LastUsedTime = 0;
	}
}

/** Called from KFSpecialMove::SpecialMoveEnded */
simulated function NotifySpecialMoveEnded( KFSpecialMove FinishedMove, ESpecialMove SMHandle )
{
	super.NotifySpecialMoveEnded( FinishedMove, SMHandle );

	if( Role == ROLE_Authority )
	{
		SetTimer( 2.f + fRand(), false, nameOf(Timer_EnableCloak) );
	}
}

// ************************************************************
//						Health checking
// ************************************************************

/** Updates the HUD interaction message and heal icon to show current heal capability */
private function UpdateHealAvailable()
{
	if( !IsHealAllowed() )
	{
		//extend the cooldown of heal here
		SpecialMoveCooldowns[5].LastUsedTime = WorldInfo.TimeSeconds;
	}
}

/** If true, we have enough heal charges remaining to execute a heal */
private function bool IsHealAllowed()
{
	return (GetHealthPercentage() < HealThreshold && SpecialMoveCooldowns[5].Charges > 0);
}

/** Overriden to set the Patriarch to feel mode when his health passes a certain threshold */
function NotifyTakeHit(Controller InstigatedBy, vector HitLocation, int Damage, class<DamageType> DamageType, vector Momentum, Actor DamageCauser)
{
	Super.NotifyTakeHit(InstigatedBy, HitLocation, Damage, DamageType, Momentum, DamageCauser);

	CheckHealth();
}

/** Check health percentage to see if we should summon children or allow healing */
private function CheckHealth()
{
	local float HealthPct;

	HealthPct = GetHealthPercentage();

	if( HealthPct < HealThreshold )
	{
		if( Role == ROLE_Authority )
		{
			// Perform an autoheal if necessary
			if( SpecialMoveCooldowns[5].Charges > 0 && HealthPct <= AutoHealThreshold )
			{
				if( IsDoingSpecialMove() && !IsDoingSpecialMove(SM_PlayerZedMove_Q) )
				{
					EndSpecialMove();
				}
				bAutoHealed = true;
				DoSpecialMove( SM_PlayerZedMove_Q, true );
			}
		}

		if( !bWarnedLowHealthThisPhase && IsLocallyControlled() && MyKFPC.MyGFxHUD != none && HealthPct <= LowHealthThreshold && SpecialMoveCooldowns[5].Charges > 0 )
		{
			bWarnedLowHealthThisPhase = true;
			MyKFPC.MyGFxHUD.ShowNonCriticalMessage( LowHealthMsg );
		}
	}
}

/** Notification from the heal specialmove that we performed a successful heal */
function NotifyHealed()
{
	// Reset low health warning
	bWarnedLowHealthThisPhase = false;

	// Reduce our number of heals by 1
	--SpecialMoveCooldowns[5].Charges;

	// Reset our cloak charges
	CloakCharges = bAutoHealed ? byte( float(default.CloakCharges) * 0.75f ) : default.CloakCharges;
	SpecialMoveCooldowns[7].Charges = CloakCharges;

	// Reset autoheal status
	bAutoHealed = false;
}

// ************************************************************
//						 	MISC
// ************************************************************

// Player ZED name
static function string GetLocalizedName()
{
    return "ZED Runner";
}

// Can this pawn be grabbed by Zed performing grab special move (clots & Hans's energy drain)
function bool CanBeGrabbed(KFPawn GrabbingPawn, optional bool bIgnoreFalling, optional bool bAllowSameTeamGrab)
{
	return false;
}

function CauseHeadTrauma(float BleedOutTime = 5.f)
{
    return;
}

simulated function bool PlayDismemberment(int InHitZoneIndex, class<KFDamageType> InDmgType, optional vector HitDirection)
{
    return false;
}

simulated function PlayHeadAsplode()
{
    return;
}

simulated function ApplyHeadChunkGore(class<KFDamageType> DmgType, vector HitLocation, vector HitDirection)
{
    return;
}

/** Returns TRUE if we're aiming with the husk cannon */
simulated function bool UseAdjustedControllerSensitivity()
{
	return IsDoingSpecialMove( SM_PlayerZedMove_RMB ) || IsDoingSpecialMove( SM_PlayerZedMove_MMB );
}

/** Allow humans to draw a positional icon to find us when we're uncloaked */
simulated function bool ShouldDrawBossIcon()
{
	return !(bIsCloaking);
}

DefaultProperties
{
	LocalizationKey=KFPawn_ZEDRunner_PAT
    MonsterArchPath="ZEDRun_ARCH.ZED_ZEDRunner_PAT_Archetype"
	CloakedBodyMaterial=MaterialInstanceConstant'ZEDRun_MAT.ZED_ZEDRunner_Pat_Mech_N_MIC'
	CloakedBodyAltMaterial=MaterialInstanceConstant'ZEDRun_MAT.ZED_ZEDRunner_Pat_N_MIC'
	SpottedMaterial=MaterialInstanceConstant'ZED_Stalker_MAT.ZED_Stalker_Visible_MAT'
	BodyMaterial=MaterialInstanceConstant'ZEDRun_MAT.ZED_ZEDRunner_Pat_Mech_N_MIC'
	BodyAltMaterial=MaterialInstanceConstant'ZEDRun_MAT.ZED_ZEDRunner_Pat_N_MIC'

	bVersusZed=true
	TeammateCollisionRadiusPercent=0.30

	// Gameplay
    bLargeZed=true
	ShrinkEffectModifier=0.f
    VortexAttracionModifier=0.0
	ParryResistance=99999999999999999
	bCanBePinned=false
    bCanBeKilledByShrinking=false
	HealThreshold=0f //0.5f // no heal, instead does something else
	AutoHealThreshold=0f //0.25f
	LowHealthThreshold=0f //0.3f
	Health=20000 //8000

	// Hook
	bCanGrabAttack=false

	bNeedsCrosshair=true
	bEnableAimOffset=true
	bUseServerSideGunTracking=true

	// Syringes
	ActiveSyringe=-1
	CurrentSyringeMeshNum=-1
	SyringeInjectTimeDuration=0.16f

	// Cloak (don't cloak, it's useless)
    bCanCloak=false //true
	CloakCharges=60
	CloakPercent=1.0f
	DeCloakSpeed=4.5f
	CloakSpeed=3.f
	CloakShimmerAmount=0.6f

	// Movement speeds
	SprintSpeed=700.f
	SprintStrafeSpeed=400.f
	GroundSpeed=260.f

	// Camera
	ThirdPersonViewOffset={(
		OffsetHigh=(X=-200,Y=90,Z=45),
		OffsetLow=(X=-220,Y=130,Z=55),
		OffsetMid=(X=-185,Y=110,Z=45),
	)}

	// Melee attacking
	Begin Object Name=MeleeHelper_0
		BaseDamage=180.f
		MaxHitRange=375.f
		MomentumTransfer=40000.f
		MyDamageType=class'KFDT_Bludgeon_Patriarch'
	End Object
	MeleeAttackHelper=MeleeHelper_0

	// ************************* MECH LIGHTS *************************

    MechColors[0]=(R=0.01,G=0.13,B=0.78)
    MechColors[1]=(R=0.01,G=0.13,B=0.78)
    MechColors[2]=(R=0.01,G=0.13,B=0.78)
    MechColors[3]=(R=0.01,G=0.13,B=0.78)
    DeadMechColor=(R=0.05,G=0.f,B=0.f)

	// ************************* INVENTORY *************************

    DefaultInventory(0)=class'KFWeap_Minigun_ZEDRunner'
	MissileProjectileClass=class'KFProj_Missile_ZEDRunner'
	MortarProjectileClass=class'KFProj_Mortar_ZEDRunner'

	MinMortarRangeSQ=160000.f
	MaxMortarRangeSQ=6250000.f

	// ************************* ABILITIES *************************

	Begin Object Name=SpecialMoveHandler_0
		SpecialMoveClasses(SM_PlayerZedMove_LMB)=class'KFSM_PlayerPatriarch_Melee'
		SpecialMoveClasses(SM_PlayerZedMove_RMB)=class'KFSM_PlayerPatriarch_MinigunBarrage'
		SpecialMoveClasses(SM_PlayerZedMove_V)=class'KFSM_ZEDRunnerPT_EMPBlast' //give anims
		SpecialMoveClasses(SM_PlayerZedMove_MMB)=class'KFSM_PlayerPatriarch_MissileAttack'
		// SpecialMoveClasses(SM_PlayerZedMove_Q)=class'KFSM_PlayerZEDRunner_Heal' // heal only works on team number ? so i guess you can't heal when you're 0 (which is human team)
		SpecialMoveClasses(SM_PlayerZedMove_G)=class'KFSM_PlayerPatriarch_MortarAttack' //lazer quick shot
		SpecialMoveClasses(SM_Taunt)=class'KFSM_Patriarch_Taunt'
	End Object

	MoveListGamepadScheme(ZGM_Attack_R2)=SM_PlayerZedMove_RMB
	MoveListGamepadScheme(ZGM_Attack_L2)=SM_PlayerZedMove_MMB
	MoveListGamepadScheme(ZGM_Melee_Square)=SM_PlayerZedMove_LMB
	MoveListGamepadScheme(ZGM_Melee_Triangle)=SM_PlayerZedMove_V
	MoveListGamepadScheme(ZGM_Block_R1)=SM_PlayerZedMove_Q
	MoveListGamepadScheme(ZGM_Explosive_Ll)=SM_PlayerZedMove_G
	MoveListGamepadScheme(ZGM_Special_R3)=SM_PlayerZedMove_V

	// Gun stance cooldowns
	SpecialMoveCooldowns(0)=(SMHandle=SM_PlayerZedMove_LMB,		CooldownTime=0.5f,	SpecialMoveIcon=Texture2D'ZED_Patriarch_UI.ZED-VS_Icons_Generic-HeavyMelee', NameLocalizationKey="Melee")
	SpecialMoveCooldowns(1)=(SMHandle=SM_PlayerZedMove_RMB,		CooldownTime=0.5f,	SpecialMoveIcon=Texture2D'ZED_Patriarch_UI.ZED-VS_Icons_Patriarch-MiniGun', NameLocalizationKey="Minigun")
	SpecialMoveCooldowns(2)=(SMHandle=SM_Taunt,					CooldownTime=0.0f,	bShowOnHud=false)
	SpecialMoveCooldowns(3)=(SMHandle=SM_PlayerZedMove_V,		CooldownTime=5.0f,	SpecialMoveIcon=Texture2D'ZEDRun_MAT.ZED_EMPBlast_Icon', NameLocalizationKey="EMP")
	SpecialMoveCooldowns(4)=(SMHandle=SM_PlayerZedMove_MMB,		CooldownTime=5.0f,	SpecialMoveIcon=Texture2D'ZED_Patriarch_UI.ZED-VS_Icons_Patriarch-Rocket', NameLocalizationKey="Rocket")
	SpecialMoveCooldowns(5)=(SMHandle=SM_PlayerZedMove_Q,		CooldownTime=6.f,	SpecialMoveIcon=Texture2D'ZED_Patriarch_UI.ZED-VS_Icons_Patriarch-Heal', Charges=3,NameLocalizationKey="Heal")
	SpecialMoveCooldowns(6)=(SMHandle=SM_PlayerZedMove_G,		CooldownTime=2.35f,	SpecialMoveIcon=Texture2D'ZED_Patriarch_UI.ZED-VS_Icons_Patriarch-MortarStrike', NameLocalizationKey="Mortar")
	SpecialMoveCooldowns(7)=(SMHandle=SM_None,					CooldownTime=9999.f,	SpecialMoveIcon=Texture2D'ZED_Patriarch_UI.ZED-VS_Icons_Generic-Cloak', Charges=60)
	SpecialMoveCooldowns.Add((SMHandle=SM_Jump,					CooldownTime=1.0f,	SpecialMoveIcon=Texture2D'ZED_Patriarch_UI.ZED-VS_Icons_Generic-Jump', bShowOnHud=false)) // Jump always at end of array


	// ************************* BATTLE PHASES / SOME PATRIARCH MUST HAVE BS *************************

	BattlePhases(0)={(HealAmounts={(1.0f)},
					  TentacleDamage=10,
					  bCanTentacleGrab=false,
					  bCanMoveWhenMinigunning={(true, true, true, true)}, // Normal,Hard,Suicidal,HoE
					  bCanSummonMinions=false)}
	BattlePhases(1)={(HealAmounts={(1.0f)},
					  TentacleDamage=10,
					  bCanTentacleGrab=false,
					  bCanMoveWhenMinigunning={(true, true, true, true)}, // Normal,Hard,Suicidal,HoE
					  bCanSummonMinions=false)}
	BattlePhases(2)={(HealAmounts={(0.9f)},
					  TentacleDamage=10,
					  bCanTentacleGrab=false,
					  bCanMoveWhenMinigunning={(true, true, true, true)}, // Normal,Hard,Suicidal,HoE
					  bCanSummonMinions=false)}
	BattlePhases(3)={(TentacleDamage=10,
					  bCanSummonMinions=false)}

	// ************************* DAMAGE TYPES *************************

	IncapSettings(AF_Snare)=	(Vulnerability=(0.7, 0.7, 1.0, 0.7),      Cooldown=8.5,  Duration=1.5)

	DamageTypeModifiers.Add((DamageType=class'KFDT_Slashing_ZedWeak', 							DamageScale=(0.5)))
    DamageTypeModifiers.Add((DamageType=class'KFDT_Bludgeon_Fleshpound', 						DamageScale=(0.5)))
    DamageTypeModifiers.Add((DamageType=class'KFDT_EMP', 	        							DamageScale=(0.75)))
    DamageTypeModifiers.Add((DamageType=class'KFDT_Explosive_FleshpoundKingRage_Light', 	    DamageScale=(0.75)))
    DamageTypeModifiers.Add((DamageType=class'KFDT_Explosive_FleshpoundKingRage_Heavy', 	    DamageScale=(0.75)))
    DamageTypeModifiers.Add((DamageType=class'KFDT_Slashing_Gorefast', 	                		DamageScale=(0.5)))
	DamageTypeModifiers.Add((DamageType=class'KFDT_Slashing_Hans', 	                			DamageScale=(0.6)))
	DamageTypeModifiers.Add((DamageType=class'KFDT_Explosive_HansHEGrenade', 	                DamageScale=(0.3)))
	DamageTypeModifiers.Add((DamageType=class'KFDT_Toxic_HansGrenade', 	                		DamageScale=(0.9)))
	DamageTypeModifiers.Add((DamageType=class'KFDT_Explosive_HuskSuicide', 	                	DamageScale=(0.8)))
	DamageTypeModifiers.Add((DamageType=class'KFDT_Bludgeon_Matriarch', 	                	DamageScale=(0.75)))
	DamageTypeModifiers.Add((DamageType=class'KFDT_HeavyZedBump', 	                    		DamageScale=(0.25)))
	DamageTypeModifiers.Add((DamageType=class'KFDT_Slashing_PatTentacle', 	                	DamageScale=(0.75)))
	DamageTypeModifiers.Add((DamageType=class'KFDT_Bludgeon_Patriarch', 	                    DamageScale=(0.25)))
	DamageTypeModifiers.Add((DamageType=class'KFDT_Slashing_Scrake', 	                		DamageScale=(0.75)))
	DamageTypeModifiers.Add((DamageType=class'KFDT_Toxic', 	                    				DamageScale=(0.25)))
	DamageTypeModifiers.Add((DamageType=class'KFDT_Piercing', 	                				DamageScale=(0.75)))
	DamageTypeModifiers.Add((DamageType=class'KFDT_Toxic', 	                    				DamageScale=(0.25)))
}