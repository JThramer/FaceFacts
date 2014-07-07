//
//  ViewController.m
//  FaceFacts
//
//  Created by Jerrad Thramer on 5/12/14.
//  Copyright (c) 2014 JerradThramer. All rights reserved.
//

#import "AVCameraViewController.h"
#import "FaceFactsAPIController.h"


@interface AVCameraViewController ()

@end

@implementation AVCameraViewController

//Most of this class is Apple Code, pulled straight from the AVCam Sample Project.
#pragma mark Apple Boiler Plate

- (BOOL)isSessionRunningAndDeviceAuthorized
{
	return [[self session] isRunning] && [self isDeviceAuthorized];
}
//------------------------------------------------------------------------------------------
+ (NSSet *)keyPathsForValuesAffectingSessionRunningAndDeviceAuthorized
{
	return [NSSet setWithObjects:@"session.running", @"deviceAuthorized", nil];
}
//------------------------------------------------------------------------------------------
- (void)viewDidLoad
{
	[super viewDidLoad];
	[self setResultsDict:nil];
	// Create the AVCaptureSession
	AVCaptureSession *session = [[AVCaptureSession alloc] init];
	[self setSession:session];
	
	// Setup the preview view
	[[self previewView] setSession:session];
	
	// Check for device authorization
	[self checkDeviceAuthorizationStatus];
	
	// In general it is not safe to mutate an AVCaptureSession or any of its inputs, outputs, or connections from multiple threads at the same time.
	// Why not do all of this on the main queue?
	// -[AVCaptureSession startRunning] is a blocking call which can take a long time. We dispatch session setup to the sessionQueue so that the main queue isn't blocked (which keeps the UI responsive).
	
	dispatch_queue_t sessionQueue = dispatch_queue_create("session queue", DISPATCH_QUEUE_SERIAL);
	[self setSessionQueue:sessionQueue];
	
	dispatch_async(sessionQueue, ^{
		[self setBackgroundRecordingID:UIBackgroundTaskInvalid];
		
		NSError *error = nil;
		
		AVCaptureDevice *videoDevice = [AVCameraViewController deviceWithMediaType:AVMediaTypeVideo preferringPosition:AVCaptureDevicePositionFront];
		AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
		
		if (error)
		{
			NSLog(@"%@", error);
		}
		
		if ([session canAddInput:videoDeviceInput])
		{
			[session addInput:videoDeviceInput];
			[self setVideoDeviceInput:videoDeviceInput];
            
			dispatch_async(dispatch_get_main_queue(), ^{
				// Why are we dispatching this to the main queue?
				// Because AVCaptureVideoPreviewLayer is the backing layer for AVCamPreviewView and UIView can only be manipulated on main thread.
				// Note: As an exception to the above rule, it is not necessary to serialize video orientation changes on the AVCaptureVideoPreviewLayer’s connection with other session manipulation.
                
				[[(AVCaptureVideoPreviewLayer *)[[self previewView] layer] connection] setVideoOrientation:(AVCaptureVideoOrientation)[self interfaceOrientation]];
			});
		}
        
		AVCaptureStillImageOutput *stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
		if ([session canAddOutput:stillImageOutput])
		{
			[stillImageOutput setOutputSettings:@{AVVideoCodecKey : AVVideoCodecJPEG}];
			[session addOutput:stillImageOutput];
			[self setStillImageOutput:stillImageOutput];
		}
	});
}
//------------------------------------------------------------------------------------------
- (void)viewWillAppear:(BOOL)animated
{
	dispatch_async([self sessionQueue], ^{
		[self addObserver:self forKeyPath:@"sessionRunningAndDeviceAuthorized" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:SessionRunningAndDeviceAuthorizedContext];
		[self addObserver:self forKeyPath:@"stillImageOutput.capturingStillImage" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:CapturingStillImageContext];
		[self addObserver:self forKeyPath:@"movieFileOutput.recording" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:RecordingContext];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subjectAreaDidChange:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:[[self videoDeviceInput] device]];
		
		__weak AVCameraViewController *weakSelf = self;
		[self setRuntimeErrorHandlingObserver:[[NSNotificationCenter defaultCenter] addObserverForName:AVCaptureSessionRuntimeErrorNotification object:[self session] queue:nil usingBlock:^(NSNotification *note) {
			AVCameraViewController *strongSelf = weakSelf;
			dispatch_async([strongSelf sessionQueue], ^{
				// Manually restarting the session since it must have been stopped due to an error.
				[[strongSelf session] startRunning];
			});
		}]];
		[[self session] startRunning];
	});
}
//------------------------------------------------------------------------------------------
- (void)viewDidDisappear:(BOOL)animated
{
	dispatch_async([self sessionQueue], ^{
		[[self session] stopRunning];
		
		[[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureDeviceSubjectAreaDidChangeNotification object:[[self videoDeviceInput] device]];
		[[NSNotificationCenter defaultCenter] removeObserver:[self runtimeErrorHandlingObserver]];
		
		[self removeObserver:self forKeyPath:@"sessionRunningAndDeviceAuthorized" context:SessionRunningAndDeviceAuthorizedContext];
		[self removeObserver:self forKeyPath:@"stillImageOutput.capturingStillImage" context:CapturingStillImageContext];
		[self removeObserver:self forKeyPath:@"movieFileOutput.recording" context:RecordingContext];
	});
}
//------------------------------------------------------------------------------------------
+ (AVCaptureDevice *)deviceWithMediaType:(NSString *)mediaType preferringPosition:(AVCaptureDevicePosition)position
{
	NSArray *devices = [AVCaptureDevice devicesWithMediaType:mediaType];
	AVCaptureDevice *captureDevice = [devices firstObject];
	
	for (AVCaptureDevice *device in devices)
	{
		if ([device position] == position)
		{
			captureDevice = device;
			break;
		}
	}
	
	return captureDevice;
}
//------------------------------------------------------------------------------------------
- (void)checkDeviceAuthorizationStatus
{
	NSString *mediaType = AVMediaTypeVideo;
	
	[AVCaptureDevice requestAccessForMediaType:mediaType completionHandler:^(BOOL granted) {
		if (granted)
		{
			//Granted access to mediaType
			[self setDeviceAuthorized:YES];
		}
		else
		{
			//Not granted access to mediaType
			dispatch_async(dispatch_get_main_queue(), ^{
				[[[UIAlertView alloc] initWithTitle:@"FaceFacts is sad."
											message:@"FaceFacts doesn't have permission to use Camera, please change privacy settings"
										   delegate:self
								  cancelButtonTitle:@"OK"
								  otherButtonTitles:nil] show];
				[self setDeviceAuthorized:NO];
			});
		}
	}];
}
//------------------------------------------------------------------------------------------
- (void)runStillImageCaptureAnimation
{
	dispatch_async(dispatch_get_main_queue(), ^{
		[[[self previewView] layer] setOpacity:0.0];
		[UIView animateWithDuration:.25 animations:^{
			[[[self previewView] layer] setOpacity:1.0];
		}];
	});
}
//------------------------------------------------------------------------------------------
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (context == CapturingStillImageContext)
	{
		BOOL isCapturingStillImage = [change[NSKeyValueChangeNewKey] boolValue];
		
		if (isCapturingStillImage)
		{
			[self runStillImageCaptureAnimation];
		}
	}
	else if (context == SessionRunningAndDeviceAuthorizedContext)
	{
        //do nothing
	}
	else
	{
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}
//------------------------------------------------------------------------------------------
- (IBAction)focusAndExposeTap:(UIGestureRecognizer *)gestureRecognizer
{
	CGPoint devicePoint = [(AVCaptureVideoPreviewLayer *)[[self previewView] layer] captureDevicePointOfInterestForPoint:[gestureRecognizer locationInView:[gestureRecognizer view]]];
	[self focusWithMode:AVCaptureFocusModeAutoFocus exposeWithMode:AVCaptureExposureModeAutoExpose atDevicePoint:devicePoint monitorSubjectAreaChange:YES];
}
//------------------------------------------------------------------------------------------
- (void)subjectAreaDidChange:(NSNotification *)notification
{
	CGPoint devicePoint = CGPointMake(.5, .5);
	[self focusWithMode:AVCaptureFocusModeContinuousAutoFocus exposeWithMode:AVCaptureExposureModeContinuousAutoExposure atDevicePoint:devicePoint monitorSubjectAreaChange:NO];
}
//------------------------------------------------------------------------------------------
- (void)focusWithMode:(AVCaptureFocusMode)focusMode exposeWithMode:(AVCaptureExposureMode)exposureMode atDevicePoint:(CGPoint)point monitorSubjectAreaChange:(BOOL)monitorSubjectAreaChange
{
	dispatch_async([self sessionQueue], ^{
		AVCaptureDevice *device = [[self videoDeviceInput] device];
		NSError *error = nil;
		if ([device lockForConfiguration:&error])
		{
			if ([device isFocusPointOfInterestSupported] && [device isFocusModeSupported:focusMode])
			{
				[device setFocusMode:focusMode];
				[device setFocusPointOfInterest:point];
			}
			if ([device isExposurePointOfInterestSupported] && [device isExposureModeSupported:exposureMode])
			{
				[device setExposureMode:exposureMode];
				[device setExposurePointOfInterest:point];
			}
			[device setSubjectAreaChangeMonitoringEnabled:monitorSubjectAreaChange];
			[device unlockForConfiguration];
		}
		else
		{
			NSLog(@"%@", error);
		}
	});
}
//------------------------------------------------------------------------------------------
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	[[(AVCaptureVideoPreviewLayer *)[[self previewView] layer] connection] setVideoOrientation:(AVCaptureVideoOrientation)toInterfaceOrientation];
}
//------------------------------------------------------------------------------------------
+ (void)setFlashMode:(AVCaptureFlashMode)flashMode forDevice:(AVCaptureDevice *)device
{
	if ([device hasFlash] && [device isFlashModeSupported:flashMode])
	{
		NSError *error = nil;
		if ([device lockForConfiguration:&error])
		{
			[device setFlashMode:flashMode];
			[device unlockForConfiguration];
		}
		else
		{
			NSLog(@"%@", error);
		}
	}
}
#pragma mark - Jerrad's methods
//------------------------------------------------------------------------------------------
- (IBAction)captureAndSendImage:(id)sender
{
    dispatch_async([self sessionQueue], ^{
		// Update the orientation on the still image output video connection before capturing.
		[[[self stillImageOutput] connectionWithMediaType:AVMediaTypeVideo] setVideoOrientation:[[(AVCaptureVideoPreviewLayer *)[[self previewView] layer] connection] videoOrientation]];
		
		// Flash set to Auto for Still Capture
		[AVCameraViewController setFlashMode:AVCaptureFlashModeAuto forDevice:[[self videoDeviceInput] device]];
		
		// Capture a still image.
		[[self stillImageOutput] captureStillImageAsynchronouslyFromConnection:[[self stillImageOutput] connectionWithMediaType:AVMediaTypeVideo] completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
			
			if (imageDataSampleBuffer)
			{
				NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
				UIImage *image = [[UIImage alloc] initWithData:imageData];
				NSLog (@"Capture Made!");
               
				[[[ALAssetsLibrary alloc] init] writeImageToSavedPhotosAlbum:[image CGImage] orientation:(ALAssetOrientation)[image imageOrientation] completionBlock:nil];
                //hacky time!
                FaceFactsAPIController *apiController = [[FaceFactsAPIController alloc] initWithDelegate:self];
                [apiController sendImage:image];
                
			}
		}];
	});

}
#pragma mark Delegate methods
//------------------------------------------------------------------------------------------
- (void)apiController:(id)controller willUploadPicture:(UIImage *)pic
{
    [DejalBezelActivityView activityViewForView:[self view] withLabel:@"Uploading Selfie to Imgur..."];
}
//------------------------------------------------------------------------------------------
- (void)apiController:(id)controller didSucessfullyUploadPicture:(UIImage *)pic
{
    [DejalBezelActivityView activityViewForView:[self view] withLabel:@"Reticulating Splines..."];
}
//------------------------------------------------------------------------------------------
- (void)apiController:(id)controller didRecieveReplyFromFPP:(NSDictionary *)reply
{
    [DejalBezelActivityView removeView];
    NSLog(@"reply dict: %@", reply);
    [self setResultsDict:reply];
    [self performSegueWithIdentifier:@"resultsSegue" sender:self];
}
//------------------------------------------------------------------------------------------
- (void)apiController:(id)controller didFailToUploadPictureWithError:(NSError *)error
{
    [DejalBezelActivityView removeView];
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Uh Oh!" message:@"Something went wrong, and FaceFacts could not upload the picture to Imgur." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
    [alertView show];
}
//------------------------------------------------------------------------------------------
- (void)apiController:(id)controller didFailToRecieveReplyFromFPPWithError:(FaceppError *)error
{
    [DejalBezelActivityView removeView];
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Uh Oh!" message:@"Something went wrong, and FaceFacts did not recieve a reply from FPP." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
    [alertView show];
}
//------------------------------------------------------------------------------------------
- (void)apiControllerDidFailToFindFace:(id)controller
{
    [DejalBezelActivityView removeView];
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Uh, we need a face." message:@"It's not called a selfie if you don't take a picture of yourself. Please try again." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
    [alertView show];
}
//------------------------------------------------------------------------------------------
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"resultsSegue"])
    {
        if ([self resultsDict])
        {
            [[segue destinationViewController] setResultsDict:[self resultsDict]];
        }
        else
        {
            assert(0); //this should never happen
        }
    }
    else
    {
        assert(0); //this should never happen
    }
    
}



//------------------------------------------------------------------------------------------


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
