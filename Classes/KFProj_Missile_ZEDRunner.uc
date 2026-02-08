class KFProj_Missile_ZEDRunner extends KFProj_Missile_Patriarch;

DefaultProperties
{
	//defaults
	FlockRadius=5.f
	FlockMaxForce=200.f
	FlockCurlForce=1200.f
	WobbleForce=90.f

	Damage=800

	// explosion
	Begin Object Name=ExploTemplate0
		Damage=500
		DamageRadius=950
		DamageFalloffExponent=2.f
	End Object
}