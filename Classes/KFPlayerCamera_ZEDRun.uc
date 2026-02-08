class KFPlayerCamera_ZEDRun extends KFPlayerCamera; //KFPlayerCamera_Versus

// Implements zed waiting camera
var(Camera) editinline transient KFPlayerZedWaitingCamera			PlayerZedWaitingCam;
// Class to use for zed waiting camera
var(Camera) protected const  class<KFPlayerZedWaitingCamera>      	PlayerZedWaitingCameraClass;

function PostBeginPlay()
{
	super.PostBeginPlay();

	// Setup camera modes
	if ( (PlayerZedWaitingCam == None) && (PlayerZedWaitingCameraClass != None) )
	{
		PlayerZedWaitingCam = KFPlayerZedWaitingCamera( CreateCamera(PlayerZedWaitingCameraClass) );
	}
}

protected function GameCameraBase FindBestCameraType(Actor CameraTarget)
{
	if (CameraStyle == 'ThirdPerson')
	{
		return ThirdPersonCam;
	}
	else if (CameraStyle == 'Boss')
	{
		return BossCam; //boss teatrics i think
	}
	else if (CameraStyle == 'Customization')
	{
		return PlayerZedWaitingCam;
	}
	else if( CameraStyle == 'FirstPerson' )
	{
		return ThirdPersonCam; //turns your character invisible
	}
	else if( CameraStyle == 'Emote' )
	{
		return PlayerZedWaitingCam;
	}

	return Super.FindBestCameraType(CameraTarget);
}

DefaultProperties
{
	// Our default FOV is in 16:9, and then scaled based on the aspect ratio
    DefaultFOV=92.0.f //90
	FreeCamOffset=(X=0,Y=0,Z=68)
	ThirdPersonCameraClass=class'KFThirdPersonCamera_Versus'
	PlayerZedWaitingCameraClass=class'KFPlayerZedWaitingCamera'

	// CustomizationCameraClass=class'KFCustomizationCamera'
	// BossCameraClass=class'KFBossCamera'
	// FirstPersonCameraClass=class'KFFirstPersonCamera'
	// EmoteCameraClass=class'KFEmoteCamera'
}