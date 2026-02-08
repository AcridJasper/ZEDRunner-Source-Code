class KFPawn_ZEDRunner extends KFPawn_ZedFleshPound_Versus;

var localized string Laser;

var protected KFGameExplosion DeathNukeExplosionTemplate;

/** Current phase of battle */
var int CurrentPhase;
/** Min phase at which the rage explosions can occur */
var const int RageExplosionMinPhase;
/** Explosion templates for our rage pound */
var protected KFGameExplosion RagePoundExplosionTemplate, RagePoundFinalExplosionTemplate;

/** Additional chest plate/lighting/FX settings for beam attack state */
var const LinearColor BeamAttackGlowColor;
var transient PointLightComponent BattlePhaseLightTemplateBlue;
/** Component used by the beam special move to play a hit location sound effect */
var AkComponent BeamHitAC;

replication
{
    if (bNetDirty)
        CurrentPhase;
}

simulated function PostBeginPlay()
{
	// body size
    IntendedBodyScale=0.95f;
    super.PostBeginPlay();
}

// ********************* RAGE POUND *********************

/** Do our radial stumble on the first few pounds */
simulated function ANIMNOTIFY_RagePoundLeft()
{
	local vector ExploLocation;

    if (CurrentPhase < RageExplosionMinPhase)
    {
        return;
    }

	Mesh.GetSocketWorldLocationAndRotation( 'FX_Root', ExploLocation );
	TriggerRagePoundExplosion( ExploLocation );
}

/** Do our radial stumble on the first few pounds */
simulated function ANIMNOTIFY_RagePoundRight()
{
	local vector ExploLocation;

    if (CurrentPhase < RageExplosionMinPhase)
    {
        return;
    }

	Mesh.GetSocketWorldLocationAndRotation( 'FX_Root', ExploLocation );
	TriggerRagePoundExplosion( ExploLocation );
}

/** Do our radial knockdown on the final pound */
simulated function ANIMNOTIFY_RagePoundRightFinal()
{
	local vector ExploLocation;

    if (CurrentPhase < RageExplosionMinPhase)
    {
        return;
    }

	Mesh.GetSocketWorldLocationAndRotation( 'FX_Root', ExploLocation );
	TriggerRagePoundExplosion( ExploLocation, true );
}

simulated function TriggerRagePoundExplosion( vector ExploLocation, optional bool bIsFinalPound=false )
{
	local KFExplosionActor ExploActor;

	// Boom
	ExploActor = Spawn( class'KFExplosionActor', self,, ExploLocation );
	ExploActor.InstigatorController = Controller;
	ExploActor.Instigator = self;
	ExploActor.Explode( bIsFinalPound ? RagePoundFinalExplosionTemplate : RagePoundExplosionTemplate, vect(0,0,1) );
}

// ********************* CHEST BEAM *********************

// Turns the chest beam ON
simulated function ANIMNOTIFY_ChestBeamStart()
{
    ToggleSMBeam( true );
}

// Turns the chest beam OFF
simulated function ANIMNOTIFY_ChestBeamEnd()
{
	ToggleSMBeam( false );
}

// Toggles chest beam while special move active
simulated function ToggleSMBeam( bool bEnable )
{
	local KFSM_ZEDRunner_Beam BeamSM;

	if( SpecialMove != SM_PlayerZedMove_G ) //SM_HoseWeaponAttack
	{
		return;
	}

	BeamSM = KFSM_ZEDRunner_Beam( SpecialMoves[SpecialMove] );
	if( BeamSM != none )
	{
		BeamSM.ToggleBeam( bEnable );
	}
}

// ********************* DEATH NUKE *********************

// Copied directly from KFPawn
simulated function PlayRagdollDeath(class<DamageType> DamageType, vector HitLoc)
{
	local vector ExploLocation;

	local TraceHitInfo HitInfo;
	local vector HitDirection;

    if (bReinitPhysAssetOnDeath && CharacterArch != none && CharacterArch.PhysAsset != none)
    {
        Mesh.SetPhysicsAsset(CharacterArch.PhysAsset, , true);
    }

	PrepareRagdoll();

	if ( InitRagdoll() )
	{
		// Switch to a good RigidBody TickGroup to fix projectiles passing through the mesh
		// https://udn.unrealengine.com/questions/190581/projectile-touch-not-called.html
		Mesh.SetTickGroup(TG_PostAsyncWork);
		SetTickGroup(TG_PostAsyncWork);

		// Allow all ragdoll bodies to collide with all physics objects (ie allow collision with things marked RigidBodyIgnorePawns)
		Mesh.SetRBChannel(RBCC_DeadPawn);
		Mesh.SetRBCollidesWithChannel(RBCC_DeadPawn, ShouldCorpseCollideWithDead());
		// ignore blocking volumes, this is important for volumes that don't always block (e.g. PawnBlockingVolume)
		Mesh.SetRBCollidesWithChannel(RBCC_BlockingVolume, FALSE);

		// Call CheckHitInfo to give us a valid BoneName
		HitDirection = Normal(TearOffMomentum);
    	CheckHitInfo(HitInfo, Mesh, HitDirection, HitLoc);

		// Play ragdoll death animation (bSkipReplication=TRUE)
		if( bAllowDeathSM && CanDoSpecialMove(SM_DeathAnim) && ClassIsChildOf(DamageType, class'KFDamageType') )
		{
			DoSpecialMove(SM_DeathAnim, TRUE,,,TRUE);
			KFSM_DeathAnim(SpecialMoves[SM_DeathAnim]).PlayDeathAnimation(DamageType, HitDirection, HitInfo.BoneName);
		}
		else
		{
			StopAllAnimations(); // stops non-RBbones from animating (fingers)
		}
	}

	Mesh.GetSocketWorldLocationAndRotation( 'FX_Root', ExploLocation );
	DeathNukeExplosion( ExploLocation );
}

simulated function DeathNukeExplosion( vector ExploLocation )
{
	local KFExplosionActor ExploActor;

	// Boom
	ExploActor = Spawn( class'KFExplosionActor', self,, ExploLocation );
	ExploActor.InstigatorController = Controller;
	ExploActor.Instigator = self;
	ExploActor.Explode( DeathNukeExplosionTemplate, vect(0,0,1) );
}

// ********************* MISC *********************

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

// Ends rage mode 10 seconds after melee damage is done (KFPawn_ZedFleshPound_Versus)
function NotifyMeleeDamageDealt()
{
	if( !IsTimerActive(nameOf(EndRage)) )
	{
		SetTimer( 10.f, false, nameOf(EndRage) );
	}
}

DefaultProperties
{
	// ************************* ZED *************************

	LocalizationKey=KFPawn_ZEDRunner
	MonsterArchPath="ZEDRun_ARCH.ZED_ZEDRunner_FP_N_Archetype"
	//ZED_ARCH.ZED_FleshpoundKing_Archetype - default
	//ZEDRun_ARCH.ZED_ZEDRunner_FP_N_Archetype - normal
	//ZEDRun_ARCH.ZED_ZEDRunner_FP_Archetype - halloween
	PawnAnimInfo=KFPawnAnimInfo'ZED_Fleshpound_ANIM.King_Fleshpound_AnimGroup'
	bVersusZed=true
	TeammateCollisionRadiusPercent=0.30

	// Gameplay
    bCanRage=true
	bCanMeleeAttack=true
    ShrinkEffectModifier=0.0
    VortexAttracionModifier=0.0
	ParryResistance=99999999999999999
	bCanBePinned=false
    bCanBeKilledByShrinking=false
	bIsFleshpoundClass=true
    // DrawScale3D=(X=1.25,Y=1.25,Z=1.25)
	Health=20000 //22000

	bNeedsCrosshair=true
	
	// Melee attacking
	Begin Object Name=MeleeHelper_0
		BaseDamage=190 //240 290
		MaxHitRange=250.f
		MomentumTransfer=2000.f
		MyDamageType=class'KFDT_Bludgeon_ZEDRunner'
		MeleeImpactCamScale=0.45
		PlayerDoorDamageMultiplier=5.f
	End Object
	MeleeAttackHelper=MeleeHelper_0

	// Movement speeds
	GroundSpeed=320 //500
    SprintSpeed=620 //720 //750
    RageSprintSpeed=1100 //920
    SprintStrafeSpeed=450

	// Camera
	ThirdPersonViewOffset={(
		OffsetHigh=(X=-175,Y=60,Z=60),
		OffsetLow=(X=-220,Y=100,Z=50),
		OffsetMid=(X=-160,Y=50,Z=30),
	)}

	// Rage
    RageExplosionMinPhase=0
	RageBumpDamage=4 //6
	RageBumpRadius=240.f
	RageBumpMomentum=550.f //500

    // Blocking higher values = less resistance
	MinBlockFOV=0.f

	// ************************* NORMAL/BATTLE LIGHTS *************************

	EnragedGlowColor=(R=2.0,G=0.0)
	DefaultGlowColor=(R=0.01,G=0.13,B=0.78)
	DeadGlowColor=(R=0.0f,G=0.0f)

    // normal lights
    Begin Object Name=PointLightComponent1
        Brightness=1.f
        Radius=128.f
        FalloffExponent=4.f
        LightColor=(R=0,G=128,B=200,A=255)
        CastShadows=false
        LightingChannels=(Indoor=true,Outdoor=true,bInitialized=TRUE)
    End Object
    BattlePhaseLightTemplateYellow=PointLightComponent1
    
    // enraged lights
    Begin Object Name=PointLightComponent2
        Brightness=1.f
        Radius=128.f
        FalloffExponent=4.f
        LightColor=(R=255,G=64,B=0,A=255)
        CastShadows=false
        LightingChannels=(Indoor=true,Outdoor=true,bInitialized=TRUE)
    End Object
    BattlePhaseLightTemplateRed=PointLightComponent2

	// ************************* CHEST BEAM *************************

	BeamAttackGlowColor=(R=2.0f,G=0.0f,B=0.0f)

	Begin Object Class=PointLightComponent Name=PointLightComponent3
        Brightness=2.f
        Radius=128.f
        FalloffExponent=4.f
        LightColor=(R=255,G=0,B=0,A=255)
        CastShadows=false
        LightingChannels=(Indoor=true,Outdoor=true,bInitialized=TRUE)
    End Object
    BattlePhaseLightTemplateBlue=PointLightComponent3

    Begin Object Class=AkComponent name=BeamHitAC0
        bStopWhenOwnerDestroyed=true
    End Object
    FootstepAkComponent= BeamHitAC0
    Components.Add(BeamHitAC0)
    BeamHitAC=BeamHitAC0

	// ************************* RAGE EXPLOSIONS *************************

	Begin Object Class=PointLightComponent Name=HITExplosionPointLight
	    LightColor=(R=128,G=0,B=0,A=255)
		Brightness=4.f
		Radius=500.f
		FalloffExponent=10.f
		CastShadows=False
		CastStaticShadows=FALSE
		CastDynamicShadows=True
		bEnabled=FALSE
		LightingChannels=(Indoor=TRUE,Outdoor=TRUE,bInitialized=TRUE)
	End Object

	Begin Object Class=KFGameExplosion Name=ExploTemplate0
		Damage=130 //90
		DamageRadius=500 //700
		DamageFalloffExponent=2.f
		DamageDelay=0.f
		MyDamageType=class'KFDT_Explosive_FleshpoundKingRage_Light'

        ActorClassToIgnoreForDamage=class'KFPawn_ZEDRunner'

		// Damage Effects
		KnockDownStrength=0
		FractureMeshRadius=200.0
		FracturePartVel=500.0
		ExplosionEffects=KFImpactEffectInfo'ZED_Fleshpound_King_EMIT.King_Pound_Explosion_Light'
		ExplosionSound=AkEvent'ww_zed_fleshpound_2.Play_King_FP_Rage_Hit'

        // Dynamic Light
        ExploLight=HITExplosionPointLight
        ExploLightStartFadeOutTime=0.0
        ExploLightFadeOutTime=0.2

		// Camera Shake
		CamShake=CameraShake'FX_CameraShake_Arch.Grenades.Default_Grenade'
		CamShakeInnerRadius=200
		CamShakeOuterRadius=1200 //900
		CamShakeFalloff=1.5f
		bOrientCameraShakeTowardsEpicenter=true
	End Object
	RagePoundExplosionTemplate=ExploTemplate0

	Begin Object Class=KFGameExplosion Name=ExploTemplate1
		Damage=130 //90
		DamageRadius=500 //700
		DamageFalloffExponent=2.f
		DamageDelay=0.f
		MyDamageType=class'KFDT_Explosive_FleshpoundKingRage_Heavy'

        ActorClassToIgnoreForDamage=class'KFPawn_ZEDRunner'

		// Damage Effects
		KnockDownStrength=0
		FractureMeshRadius=200.0
		FracturePartVel=500.0
		ExplosionEffects=KFImpactEffectInfo'ZED_Fleshpound_King_EMIT.King_Pound_Explosion_Heavy'
		ExplosionSound=AkEvent'ww_zed_fleshpound_2.Play_King_FP_Rage_Hit'

        // Dynamic Light
        ExploLight=HITExplosionPointLight
        ExploLightStartFadeOutTime=0.0
        ExploLightFadeOutTime=0.2

		// Camera Shake
		CamShake=CameraShake'FX_CameraShake_Arch.Grenades.Default_Grenade'
		CamShakeInnerRadius=200
		CamShakeOuterRadius=1200 //900
		CamShakeFalloff=1.5f
		bOrientCameraShakeTowardsEpicenter=true
	End Object
	RagePoundFinalExplosionTemplate=ExploTemplate1

	// ************************* SUICIDE NUKE *************************

	// Death explosion light
	Begin Object Class=PointLightComponent Name=ExplosionPointLight
	    LightColor=(R=252,G=218,B=171,A=255)
		Brightness=4.f
		Radius=2000.f
		FalloffExponent=10.f
		CastShadows=False
		CastStaticShadows=FALSE
		CastDynamicShadows=False
		bCastPerObjectShadows=false
		bEnabled=FALSE
		LightingChannels=(Indoor=TRUE,Outdoor=TRUE,bInitialized=TRUE)
	End Object

	// Death explosion template
    Begin Object Class=KFGameExplosion Name=ExploTemplate3
		Damage=1200
		DamageRadius=1000    //1000 //250
		DamageFalloffExponent=2  //3
		DamageDelay=0.f
		MyDamageType=class'KFDT_Toxic_DemoNuke'

		MomentumTransferScale=1.f
		
		// Damage Effects
		KnockDownStrength=0
		FractureMeshRadius=200.0
		FracturePartVel=500.0
		ExplosionEffects=KFImpactEffectInfo'FX_Impacts_ARCH.Explosions.Nuke_Explosion'
		ExplosionSound=AkEvent'WW_GLO_Runtime.Play_WEP_Nuke_Explo'

        // Dynamic Light
        ExploLight=ExplosionPointLight
        ExploLightStartFadeOutTime=0.0
        ExploLightFadeOutTime=0.2

		// Camera Shake
		CamShake=CameraShake'FX_CameraShake_Arch.Misc_Explosions.Light_Explosion_Rumble'
		CamShakeInnerRadius=200
		CamShakeOuterRadius=900
		CamShakeFalloff=1.5f
		bOrientCameraShakeTowardsEpicenter=true
    End Object
    DeathNukeExplosionTemplate=ExploTemplate3

	// ************************* ABILITIES *************************

	Begin Object Name=SpecialMoveHandler_0
		SpecialMoveClasses(SM_PlayerZedMove_LMB)=class'KFSM_PlayerFleshpound_Melee'
		SpecialMoveClasses(SM_PlayerZedMove_RMB)=class'KFSM_PlayerFleshpound_Melee2'
		SpecialMoveClasses(SM_PlayerZedMove_V)=class'KFSM_ZEDRunner_Rage'
		SpecialMoveClasses(SM_PlayerZedMove_MMB)=class'KFSM_ZEDRunnerFP_EMPBlast'
		SpecialMoveClasses(SM_PlayerZedMove_G)=class'KFSM_ZEDRunner_Beam'
		// SpecialMoveClasses(SM_PlayerZedMove_Q)=class'KFSM_ZEDRunner_Orb'
		// SpecialMoveClasses(SM_Taunt)=class''
	End Object

	// Gamepad
	MoveListGamepadScheme(ZGM_Melee_Square)=SM_PlayerZedMove_LMB
	MoveListGamepadScheme(ZGM_Melee_Triangle)=SM_PlayerZedMove_RMB
	MoveListGamepadScheme(ZGM_Special_R3)=SM_PlayerZedMove_V
	MoveListGamepadScheme(ZGM_Block_R1)=SM_PlayerZedMove_MMB
	MoveListGamepadScheme(ZGM_Explosive_Ll)=SM_PlayerZedMove_G

	SpecialMoveCooldowns(0)=(SMHandle=SM_PlayerZedMove_LMB,		CooldownTime=0.3f,	SpecialMoveIcon=Texture2D'ZED_Fleshpound_UI.ZED-VS_Icons_Fleshpound-LightAttack', NameLocalizationKey="Light")
	SpecialMoveCooldowns(1)=(SMHandle=SM_PlayerZedMove_RMB,		CooldownTime=0.3f,	SpecialMoveIcon=Texture2D'ZED_Fleshpound_UI.ZED-VS_Icons_Fleshpound-HeavyAttack', NameLocalizationKey="Heavy")
	SpecialMoveCooldowns(2)=(SMHandle=SM_Taunt,					CooldownTime=0.0f,	bShowOnHud=false)
	SpecialMoveCooldowns(3)=(SMHandle=SM_PlayerZedMove_V,		CooldownTime=7.0f,	SpecialMoveIcon=Texture2D'ZED_Fleshpound_UI.ZED-VS_Icons_Fleshpound-Rage', NameLocalizationKey="Rage")
	SpecialMoveCooldowns(4)=(SMHandle=SM_PlayerZedMove_MMB,		CooldownTime=10.0,	SpecialMoveIcon=Texture2D'ZEDRun_MAT.ZED_EMPBlast_Icon', NameLocalizationKey="Block") //SummerSideShow_UI.UI_Objectives_SS_Generator
	SpecialMoveCooldowns(5)=(SMHandle=SM_PlayerZedMove_G,		CooldownTime=20.0,	SpecialMoveIcon=Texture2D'ZEDRun_MAT.ZED_Lazer_Icon', bShowOnHud=true, NameLocalizationKey="Lazer")
	// SpecialMoveCooldowns(6)=(SMHandle=SM_PlayerZedMove_Q,		CooldownTime=10.0,	SpecialMoveIcon=Texture2D'ZEDRun_MAT.ZED_Lazer_Icon', bShowOnHud=true, NameLocalizationKey="Orb")
	SpecialMoveCooldowns.Add((SMHandle=SM_Jump,					CooldownTime=1.25f,	SpecialMoveIcon=Texture2D'ZED_Fleshpound_UI.ZED-VS_Icons_Fleshpound-Jump', bShowOnHud=false)) // Jump always at end of array

	// ************************* DAMAGE TYPES *************************

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