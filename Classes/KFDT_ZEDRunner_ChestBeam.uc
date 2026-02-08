class KFDT_ZEDRunner_ChestBeam extends KFDT_EMP
	abstract
	hidedropdown;

// Test obliterate conditions when taking damage
static function bool CheckObliterate(Pawn P, int Damage)
{
	return default.bCanObliterate;
}

defaultproperties
{
    bArmorStops=true

	RadialDamageImpulse=2000
	KDeathUpKick=500
	KDeathVel=300

	EffectGroup=255 //None
	bCanObliterate=true
	bCanGib=true

	KnockdownPower=50
	EMPPower=80
}