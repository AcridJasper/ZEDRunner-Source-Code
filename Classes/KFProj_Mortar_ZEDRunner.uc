class KFProj_Mortar_ZEDRunner extends KFProj_Missile_Patriarch
	hidedropdown;

function InitEx( vector AimDir, float CurlForceMultiplier, vector TargetLoc, float InitialMissileSpeed,
				float NewSeekDelay, float NewSeekForce, float NewGravForce, float NewDistToApplyGravitySQ )
{
	super.InitEx( AimDir, CurlForceMultiplier, TargetLoc, InitialMissileSpeed, NewSeekDelay, NewSeekForce, NewGravForce, NewDistToApplyGravitySQ );

	Velocity.X *= 0.2f;
	Velocity.Y *= 0.2f;
	Velocity.Z *= 1.3f;
}

defaultproperties
{
	// CollideActors=true allows detection via OverlappingActors or CollidingActors (for Siren scream)
	Begin Object Name=CollisionCylinder
		CollisionRadius=0.f
		CollisionHeight=0.f
	End Object

	Physics=PHYS_Falling
	Speed=2000.f
	AmbientSoundPlayEvent=AkEvent'WW_ZED_Patriarch.Play_Mini_Rocket_LP_Beep'
    AmbientSoundStopEvent=AkEvent'WW_ZED_Patriarch.Stop_Mini_Rocket_LP_Beep'

	Damage=1200
	MyDamageType=class'KFDT_Explosive_PatMortar'
	MomentumTransfer=1000.f

	// explosion
	Begin Object Name=ExploTemplate0
		MyDamageType=class'KFDT_Explosive_PatMortar'
		DamageRadius=1000
	End Object
}