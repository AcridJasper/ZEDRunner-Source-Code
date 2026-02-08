class KFSM_ZEDRunnerPT_EMPBlast extends KFSM_PlaySingleAnim;

var const AkEvent EMPAkEvent;

var KFGameExplosion ExplosionTemplate;
var const class<GameExplosionActor> ExplosionActorClass;

// Notification called when Special Move starts
function SpecialMoveStarted(bool bForced, Name PrevMove)
{
	super.SpecialMoveStarted(bForced, PrevMove);

	//PlayFireAnim();
	PlayAnimation();

	// Play a sound
	if( KFPOwner.WorldInfo.NetMode != NM_DedicatedServer )
	{
		KFPOwner.PostAkEvent( EMPAkEvent, true, true, true );
	}
}

// Overridden to do nothing
function PlayAnimation()
{
	local KFExplosionActor ExplosionActor;

	// Zero movement
	KFPOwner.ZeroMovementVariables();

	PlaySpecialMoveAnim(AnimName, EAS_FullBody, 0.1f, 0.2f);

	// Do damage
    ExplosionActor = KFPOwner.Spawn( class'KFExplosionActor', KFPOwner,, KFPOwner.Mesh.GetBoneLocation('Root'), rotator(vect(0,0,1)));
    if (ExplosionActor != none)
    {
        ExplosionActor.Explode(ExplosionTemplate);
    }
}

/*
// Plays our fire animation, starts weapon fire
function PlayFireAnim()
{
	local KFExplosionActor ExplosionActor;

	// Zero movement
	KFPOwner.ZeroMovementVariables();

	PlaySpecialMoveAnim(AnimName, EAS_FullBody, 0.1f, 0.2f);

	// Do damage
    ExplosionActor = KFPOwner.Spawn(
		class'KFExplosionActor', KFPOwner,, KFPOwner.Mesh.GetBoneLocation('Root'), rotator(vect(0,0,1)));
    if (ExplosionActor != none)
    {
        ExplosionActor.Explode(ExplosionTemplate);
    }

    // Play our fire sound
	KFPOwner.PostAkEventOnBone( FireSound, 'Spine2', true, true );
}
*/

function SpecialMoveEnded(Name PrevMove, Name NextMove)
{
	super.SpecialMoveEnded(PrevMove, NextMove);
}

defaultproperties
{
	Handle=KFSM_ZEDRunnerPT_EMPBlast
	bDisableSteering=false
	bDisableMovement=true
	bDisableTurnInPlace=true
   	bCanBeInterrupted=false
	// bAllowFireAnims=false//true
    // bShouldDeferToPostTick=true // enables AnimEndNotify
   	bUseCustomRotationRate=true
   	CustomRotationRate=(Pitch=0,Yaw=0,Roll=0) //(Pitch=66000,Yaw=100000,Roll=66000)
   	CustomTurnInPlaceAnimRate=0.1f

	AnimName=Heal_Taunt_V2
	//AnimStance=EAS_FullBody
	
	EMPAkEvent=AkEvent'WW_ZED_Matriarch.Play_Matriarch_Storm_Attack_01'
	ExplosionActorClass=class'KFExplosionActor'

	// explosion
	Begin Object Class=KFGameExplosion Name=ExploTemplate0
        Damage=180
        DamageRadius=800
        DamageFalloffExponent=0.f
        DamageDelay=0.f
        MyDamageType=class'KFDT_EMP_EMPBlast_ZEDRunner'

        MomentumTransferScale=11000 //0
        ActorClassToIgnoreForDamage=class'KFPawn_ZEDRunner_PAT'

        // Damage Effects
        KnockDownStrength=0
        KnockDownRadius=0
        FractureMeshRadius=0
        FracturePartVel=0
        ExplosionEffects=KFImpactEffectInfo'ZEDRun_ARCH.FX_EMP_Blast'
        ExplosionSound=AkEvent'WW_ZED_Matriarch.Play_Matriarch_Storm_Attack_01'

        // Camera Shake
        CamShake=CameraShake'FX_CameraShake_Arch.Grenades.Default_Grenade'
        CamShakeInnerRadius=450
        CamShakeOuterRadius=900
        CamShakeFalloff=1.f
        bOrientCameraShakeTowardsEpicenter=true
	End Object
	ExplosionTemplate=ExploTemplate0
}