#import "TPView.h"
#import "TPModel.h"
#import "TPUtil.h"
#import "TPVideo.h"
#import "TPData.h"
#import "TPDatabase.h"
#import "TPRubricList.h"
#import "TPRoundRect.h"
#import "TPCompat.h"
#import "TPRubrics.h" //jxi;
#import "TPAttachListVC.h" //jxi;

#import <QuartzCore/QuartzCore.h>
#import "AVCamCaptureManager.h"
#import "AVCamRecorder.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

static void *AVCamFocusModeObserverContext = &AVCamFocusModeObserverContext;

@interface TPVideoVC () <UIGestureRecognizerDelegate>
@end

@interface TPVideoVC (InternalMethods)
- (CGPoint)convertToPointOfInterestFromViewCoordinates:(CGPoint)viewCoordinates;
- (void)tapToAutoFocus:(UIGestureRecognizer *)gestureRecognizer;
- (void)tapToContinouslyAutoFocus:(UIGestureRecognizer *)gestureRecognizer;
- (void)updateButtonStates;
@end

@interface TPVideoVC (AVCamCaptureManagerDelegate) <AVCamCaptureManagerDelegate>
@end

// --------------------------------------------------------------------------------------
@implementation TPVideoVC

@synthesize captureManager, captureVideoPreviewLayer, focusModeLabel;

// --------------------------------------------------------------------------------------
- (id)initWithView:(TPView *)mainView image:(UIImage *)anImage {
    
    if (debugCamera) NSLog(@"TPVideoVC initWithView");
	self = [super init];
    if (self) {
		viewDelegate = mainView;
        flagVideoImage = TRUE; //if TRUE, video. else image;
        self.captureManager = nil;
        [self.view setBackgroundColor:[UIColor whiteColor]];
		[self initCapture];
        
        // toolbar with buttons
        toolBar = [[UIToolbar alloc] init];
        toolBar.barStyle = UIBarStyleBlack;
        toolBar.translucent = YES;
        
        capturedImage = nil;
        capturedImageObject = nil;

        capturedVideo = nil;
        capturedVideoObject = nil;
        
        NSMutableArray *toolbarItems = [NSMutableArray array];
        
        if ([TPUtil isCameraAvailableOnTheDevice]) {
            switchCameraButton = [[[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:self action:@selector(doSwitchCameras)] autorelease];
            
            [switchCameraButton setWidth:70];
            
            UIImage *img1 = [[UIImage imageNamed:@"cam_front_rear.png"] retain];
            [switchCameraButton setImage:img1];
            [switchCameraButton setImageInsets:UIEdgeInsetsMake(5, 0, -5, 0)];
            
            [toolbarItems addObject:switchCameraButton];
        }
        
        UIBarButtonItem *flexibleSpace1 = [[[UIBarButtonItem alloc]
                                            initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                            target:nil
                                            action:nil] autorelease];
        captureButton = [[[UIBarButtonItem alloc] initWithTitle:@"Record"
                                                          style:UIBarButtonSystemItemCamera
                                                         target:self
                                                         action:@selector(doCaptureVideo)] autorelease];
        
        UIBarButtonItem *flexibleSpace2 = [[[UIBarButtonItem alloc]
                                            initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                            target:nil
                                            action:nil] autorelease];
        
        UIBarButtonItem *flexibleSpace3 = [[[UIBarButtonItem alloc]
                                            initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                            target:nil
                                            action:nil] autorelease];
        
        doneButton = [[[UIBarButtonItem alloc] initWithTitle:@"Done"
                                                       style:UIBarButtonItemStyleBordered
                                                      target:self
                                                      action:@selector(doReturn)] autorelease];
        
        videocameraSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(50, 2, 100, 37)]; //jxi;
        [videocameraSwitch addTarget: self action: @selector(doSwitchMode) forControlEvents: UIControlEventValueChanged]; //jxi;
        UIImage *img4 = [[UIImage imageNamed:@"icon_camera.png"] retain];
        UIImage *img5 = [[UIImage imageNamed:@"icon_video.png"] retain];
        [videocameraSwitch setOnImage:img4];
        [videocameraSwitch setOffImage:img5];
        UIBarButtonItem *switchButton = [[[UIBarButtonItem alloc]initWithCustomView:videocameraSwitch] autorelease];
        
        [toolbarItems addObject:switchButton]; //jxi;
        [toolbarItems addObject:flexibleSpace1];
        [toolbarItems addObject:flexibleSpace2];
        [toolbarItems addObject:flexibleSpace3];
        [toolbarItems addObject:captureButton];
        [toolbarItems addObject:doneButton];
        self.toolbarItems = toolbarItems;
    }
    
    return self;
}

// --------------------------------------------------------------------------------------
- (NSString *)stringForFocusMode:(AVCaptureFocusMode)focusMode
{
	NSString *focusString = @"";
	
	switch (focusMode) {
		case AVCaptureFocusModeLocked:
			focusString = @"locked";
			break;
		case AVCaptureFocusModeAutoFocus:
			focusString = @"auto";
			break;
		case AVCaptureFocusModeContinuousAutoFocus:
			focusString = @"continuous";
			break;
	}
	
	return focusString;
}

// --------------------------------------------------------------------------------------
-(void) dealloc {
    [self removeObserver:self forKeyPath:@"captureManager.videoInput.device.focusMode"];

    if (debugCamera) NSLog(@"TPCameraVC dealloc");
    
    [videocameraSwitch release]; //jxi;
    [captureButton release];
    [doneButton release];
    [switchCameraButton release];
    
    [capturedImage release];
    [capturedImageObject release];

    [capturedVideo release];
    [capturedVideoObject release];
    
    [captureManager release];
	[captureVideoPreviewLayer release];
	[focusModeLabel release];

    [super dealloc];
}

// --------------------------------------------------------------------------------------
- (void)updateUIWithInterfaceOrientation:(UIInterfaceOrientation) orientation {
    
    if (debugRotate) NSLog(@"TPCameraVC updateUIWithInterfaceOrientation %d", orientation);
    if (debugRotate) NSLog(@"frame %f %f", self.view.frame.size.width, self.view.frame.size.height);
    
    if (orientation == UIInterfaceOrientationPortrait ||
        orientation == UIInterfaceOrientationPortraitUpsideDown) {
        if (debugRotate) NSLog(@"portrait");
        [self.captureVideoPreviewLayer setFrame:CGRectMake(0, 0, 768.0, 1024.0)];
    } else {
        if (debugRotate) NSLog(@"landscape");
        [self.captureVideoPreviewLayer setFrame:CGRectMake(0, 0, 1024.0, 768.0)];
    }
    
    // Set preview orientation
    [TPCompat setCameraOrientation:self.captureVideoPreviewLayer orientation:orientation];
}

// --------------------------------------------------------------------------------------
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    if (debugRotate) NSLog(@"TPCameraVC shouldAutorotateToInterfaceOrientation %d", interfaceOrientation);
    return YES;
}

// --------------------------------------------------------------------------------------
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration {
    if (debugRotate) NSLog(@"TPCameraVC willRotateToInterfaceOrientation %d", interfaceOrientation);
    [self updateUIWithInterfaceOrientation:interfaceOrientation];
}

// --------------------------------------------------------------------------------------
- (void) viewWillAppear:(BOOL)animated {
    if (debugCamera) NSLog(@"TPCameraVC viewWillAppear");
    [self updateUIWithInterfaceOrientation:[UIApplication sharedApplication].statusBarOrientation];
}

// --------------------------------------------------------------------------------------
// Setting up the input
// --------------------------------------------------------------------------------------
- (void)initCapture {
    
    if ([self captureManager] == nil) {
		AVCamCaptureManager *manager = [[AVCamCaptureManager alloc] init];
		[self setCaptureManager:manager];
		[manager release];
		
		[[self captureManager] setDelegate:self];
        
		if ([[self captureManager] setupSession]) {
            // Create video preview layer and add it to the UI
			AVCaptureVideoPreviewLayer *newCaptureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:[[self captureManager] session]];
			[newCaptureVideoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
            [newCaptureVideoPreviewLayer setFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
            [self.view.layer addSublayer:newCaptureVideoPreviewLayer];
            
			[self setCaptureVideoPreviewLayer:newCaptureVideoPreviewLayer];
            [newCaptureVideoPreviewLayer release];
			
            // Start the session. This is done asychronously since -startRunning doesn't return until the session is running.
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
				[[[self captureManager] session] startRunning];
			});
			
            [self updateButtonStates];
			
            // Create the focus mode UI overlay
			UILabel *newFocusModeLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 50, newCaptureVideoPreviewLayer.bounds.size.width - 20, 20)];
			[newFocusModeLabel setBackgroundColor:[UIColor clearColor]];
			[newFocusModeLabel setTextColor:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.50]];
			AVCaptureFocusMode initialFocusMode = [[[captureManager videoInput] device] focusMode];
			[newFocusModeLabel setText:[NSString stringWithFormat:@"focus: %@", [self stringForFocusMode:initialFocusMode]]];
			[self.view addSubview:newFocusModeLabel];
			[self addObserver:self forKeyPath:@"captureManager.videoInput.device.focusMode" options:NSKeyValueObservingOptionNew context:AVCamFocusModeObserverContext];
			[self setFocusModeLabel:newFocusModeLabel];
            [newFocusModeLabel release];
            
            // Add a single tap gesture to focus on the point tapped, then lock focus
			UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapToAutoFocus:)];
			[singleTap setDelegate:self];
			[singleTap setNumberOfTapsRequired:1];
			[self.view addGestureRecognizer:singleTap];
			
            // Add a double tap gesture to reset the focus mode to continuous auto focus
			UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapToContinouslyAutoFocus:)];
			[doubleTap setDelegate:self];
			[doubleTap setNumberOfTapsRequired:2];
			[singleTap requireGestureRecognizerToFail:doubleTap];
			[self.view addGestureRecognizer:doubleTap];
			
			[doubleTap release];
			[singleTap release];
		}
	}
	
}

// --------------------------------------------------------------------------------------
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == AVCamFocusModeObserverContext) {
        // Update the focus UI overlay string when the focus mode changes
		[focusModeLabel setText:[NSString stringWithFormat:@"focus: %@", [self stringForFocusMode:(AVCaptureFocusMode)[[change objectForKey:NSKeyValueChangeNewKey] integerValue]]]];
	} else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

// --------------------------------------------------------------------------------------
- (void) startRecording
{
    [[[self captureManager] session]startRunning];
}

// --------------------------------------------------------------------------------------
- (void) stopRecording
{
    [[[self captureManager] session]stopRunning];
}

// --------------------------------------------------------------------------------------
- (void)doCaptureVideo
{
    if( debugCamera ) NSLog(@"TPVideoVC doCaptureVideo");
    // Start recording if there isn't a recording running. Stop recording if there is.
    if( flagVideoImage == TRUE )
    {
        [captureButton setEnabled:NO];
        if (![[[self captureManager] recorder] isRecording])
            [[self captureManager] startRecording];
        else
            [[self captureManager] stopRecording];
    }
    else
    {
        // Capture a still image
        [captureButton setEnabled:NO];
        [[self captureManager] captureStillImage];
        
        // Flash the screen white and fade it out to give UI feedback that a still image was taken
        UIView *flashView = [[UIView alloc] initWithFrame:[self.view frame]];
        [flashView setBackgroundColor:[UIColor whiteColor]];
        [[[self view] window] addSubview:flashView];
        
        [UIView animateWithDuration:.4f
                         animations:^{
                             [flashView setAlpha:0.f];
                         }
                         completion:^(BOOL finished){
                             [flashView removeFromSuperview];
                             [flashView release];
                         }
         ];
    }
}

// --------------------------------------------------------------------------------------
-(void)doReturn {
    if (debugCamera) NSLog(@"TPCameraVC doReturn");
    [viewDelegate videoDoneCapture];
}

// --------------------------------------------------------------------------------------
- (void)doShowPreview:(NSString *)userdata_id {
    if (debugCamera) NSLog(@"TPVideoVC doShowPreview");
    TPImage *image = [viewDelegate.model getImageFromListById:userdata_id type:TP_IMAGE_TYPE_FULL];
    TPUserData *imageUserdata = [viewDelegate.model getUserDataFromListById:image.userdata_id];
    TPPreviewVC *previewVC = [[TPPreviewVC alloc]
                              initWithViewDelegate:viewDelegate
                              userdata:imageUserdata
                              image:image.image
                              name:imageUserdata.name
                              share:imageUserdata.share
                              description:imageUserdata.description
                              userdataID:userdata_id
                              imageOrigin:image.origin
                              newImage:YES];
    [previewVC setPreviewDelegate:self];
    [self presentViewController:previewVC animated:YES completion:nil];
    [previewVC release];
}

// --------------------------------------------------------------------------------------
- (void)doShowVideoPreview:(NSString *)userdata_id {
    if (debugCamera) NSLog(@"TPVideoVC doShowVideoPreview");
    
    MPMoviePlayerController *player = [[MPMoviePlayerController alloc] initWithContentURL:capturedVideo];
     
     UIImage *newImage = [player thumbnailImageAtTime:1.0 timeOption:MPMovieTimeOptionNearestKeyFrame];
     
     //Player autoplays audio on init
     [player stop];
     [player release];
    
    TPVideo *video = [viewDelegate.model getVideoFromListById:userdata_id];
    
    TPUserData *imageUserdata = [viewDelegate.model getUserDataFromListById:video.userdata_id];
    TPVideoPreviewVC *previewVC = [[TPVideoPreviewVC alloc]
                              initWithViewDelegate:viewDelegate
                              userdata:imageUserdata
                              image:newImage
                              name:imageUserdata.name
                              share:imageUserdata.share
                              description:imageUserdata.description
                              userdataID:userdata_id
                              imageOrigin:0
                              newImage:YES
                              videoURL:capturedVideo
                            modified:video.modified
                                   ];
    [previewVC setPreviewDelegate:self];
    [self presentViewController:previewVC animated:YES completion:nil];
    [previewVC release];
}


// --------------------------------------------------------------------------------------
- (void)doSwitchMode
{
    flagVideoImage = !flagVideoImage;
    if( flagVideoImage == TRUE)
    {
        CFRunLoopPerformBlock(CFRunLoopGetMain(), kCFRunLoopCommonModes, ^(void) {
        [captureButton setTitle:@"Record"];
        [captureButton setEnabled:YES];
        });
    }
    else
    {
        CFRunLoopPerformBlock(CFRunLoopGetMain(), kCFRunLoopCommonModes, ^(void) {
            [captureButton setTitle:@"Capture"];
            [captureButton setEnabled:YES];
        });
    }
}

// --------------------------------------------------------------------------------------
- (void)doSwitchCameras {
    // Toggle between cameras when there is more than one
    [[self captureManager] toggleCamera];
    
    // Do an initial focus
    [[self captureManager] continuousFocusAtPoint:CGPointMake(.5f, .5f)];
}
@end

// --------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------
@implementation TPVideoVC (InternalMethods)

// --------------------------------------------------------------------------------------
// Convert from view coordinates to camera coordinates, where {0,0} represents the top
// left of the picture area, and {1,1} represents the bottom right in landscape mode with
// the home button on the right.
// --------------------------------------------------------------------------------------
- (CGPoint)convertToPointOfInterestFromViewCoordinates:(CGPoint)viewCoordinates
{
    CGPoint pointOfInterest = CGPointMake(.5f, .5f);
    CGSize frameSize = [self.view frame].size;
    
    if ([captureVideoPreviewLayer isMirrored]) {
        viewCoordinates.x = frameSize.width - viewCoordinates.x;
    }
    
    if ( [[captureVideoPreviewLayer videoGravity] isEqualToString:AVLayerVideoGravityResize] ) {
		// Scale, switch x and y, and reverse x
        pointOfInterest = CGPointMake(viewCoordinates.y / frameSize.height, 1.f - (viewCoordinates.x / frameSize.width));
    } else {
        CGRect cleanAperture;
        for (AVCaptureInputPort *port in [[[self captureManager] videoInput] ports]) {
            if ([port mediaType] == AVMediaTypeVideo) {
                cleanAperture = CMVideoFormatDescriptionGetCleanAperture([port formatDescription], YES);
                CGSize apertureSize = cleanAperture.size;
                CGPoint point = viewCoordinates;
                
                CGFloat apertureRatio = apertureSize.height / apertureSize.width;
                CGFloat viewRatio = frameSize.width / frameSize.height;
                CGFloat xc = .5f;
                CGFloat yc = .5f;
                
                if ( [[captureVideoPreviewLayer videoGravity] isEqualToString:AVLayerVideoGravityResizeAspect] ) {
                    if (viewRatio > apertureRatio) {
                        CGFloat y2 = frameSize.height;
                        CGFloat x2 = frameSize.height * apertureRatio;
                        CGFloat x1 = frameSize.width;
                        CGFloat blackBar = (x1 - x2) / 2;
						// If point is inside letterboxed area, do coordinate conversion; otherwise, don't change the default value returned (.5,.5)
                        if (point.x >= blackBar && point.x <= blackBar + x2) {
							// Scale (accounting for the letterboxing on the left and right of the video preview), switch x and y, and reverse x
                            xc = point.y / y2;
                            yc = 1.f - ((point.x - blackBar) / x2);
                        }
                    } else {
                        CGFloat y2 = frameSize.width / apertureRatio;
                        CGFloat y1 = frameSize.height;
                        CGFloat x2 = frameSize.width;
                        CGFloat blackBar = (y1 - y2) / 2;
						// If point is inside letterboxed area, do coordinate conversion. Otherwise, don't change the default value returned (.5,.5)
                        if (point.y >= blackBar && point.y <= blackBar + y2) {
							// Scale (accounting for the letterboxing on the top and bottom of the video preview), switch x and y, and reverse x
                            xc = ((point.y - blackBar) / y2);
                            yc = 1.f - (point.x / x2);
                        }
                    }
                } else if ([[captureVideoPreviewLayer videoGravity] isEqualToString:AVLayerVideoGravityResizeAspectFill]) {
					// Scale, switch x and y, and reverse x
                    if (viewRatio > apertureRatio) {
                        CGFloat y2 = apertureSize.width * (frameSize.width / apertureSize.height);
                        xc = (point.y + ((y2 - frameSize.height) / 2.f)) / y2; // Account for cropped height
                        yc = (frameSize.width - point.x) / frameSize.width;
                    } else {
                        CGFloat x2 = apertureSize.height * (frameSize.height / apertureSize.width);
                        yc = 1.f - ((point.x + ((x2 - frameSize.width) / 2)) / x2); // Account for cropped width
                        xc = point.y / frameSize.height;
                    }
                }
                
                pointOfInterest = CGPointMake(xc, yc);
                break;
            }
        }
    }
    
    return pointOfInterest;
}

// --------------------------------------------------------------------------------------
// Auto focus at a particular point. The focus mode will change to locked once the auto
// focus happens.
// --------------------------------------------------------------------------------------
- (void)tapToAutoFocus:(UIGestureRecognizer *)gestureRecognizer
{
    if ([[[captureManager videoInput] device] isFocusPointOfInterestSupported]) {
        CGPoint tapPoint = [gestureRecognizer locationInView:self.view];
        CGPoint convertedFocusPoint = [self convertToPointOfInterestFromViewCoordinates:tapPoint];
        [captureManager autoFocusAtPoint:convertedFocusPoint];
    }
}

// --------------------------------------------------------------------------------------
// Change to continuous auto focus. The camera will constantly focus at the point choosen
// --------------------------------------------------------------------------------------
- (void)tapToContinouslyAutoFocus:(UIGestureRecognizer *)gestureRecognizer
{
    if ([[[captureManager videoInput] device] isFocusPointOfInterestSupported])
        [captureManager continuousFocusAtPoint:CGPointMake(.5f, .5f)];
}

// --------------------------------------------------------------------------------------
// Update button states based on the number of available cameras and mics
// --------------------------------------------------------------------------------------
- (void)updateButtonStates
{
	NSUInteger cameraCount = [[self captureManager] cameraCount];
	NSUInteger micCount = [[self captureManager] micCount];
    
    CFRunLoopPerformBlock(CFRunLoopGetMain(), kCFRunLoopCommonModes, ^(void) {
        if (cameraCount < 2) {
            [switchCameraButton setEnabled:NO];
            
            if (cameraCount < 1) {
                /*[[self stillButton] setEnabled:NO]*/;
                
                if (micCount < 1)
                    [captureButton setEnabled:NO];
                else
                    [captureButton setEnabled:YES];
            } else {
                /*[[self stillButton] setEnabled:YES]*/;
                [captureButton setEnabled:YES];
            }
        } else {
            [switchCameraButton setEnabled:YES];
            /*[[self stillButton] setEnabled:YES]*/;
            [captureButton setEnabled:YES];
        }
    });
}

@end

// --------------------------------------------------------------------------------------
@implementation TPVideoVC (AVCamCaptureManagerDelegate)

// --------------------------------------------------------------------------------------
- (void)captureManager:(AVCamCaptureManager *)captureManager didFailWithError:(NSError *)error
{
    CFRunLoopPerformBlock(CFRunLoopGetMain(), kCFRunLoopCommonModes, ^(void) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[error localizedDescription]
                                                            message:[error localizedFailureReason]
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedString(@"OK", @"OK button title")
                                                  otherButtonTitles:nil];
        [alertView show];
        [alertView release];
    });
}

// --------------------------------------------------------------------------------------
- (void)captureManagerRecordingBegan:(AVCamCaptureManager *)captureManager
{
    CFRunLoopPerformBlock(CFRunLoopGetMain(), kCFRunLoopCommonModes, ^(void) {
        [captureButton setTitle:NSLocalizedString(@"Stop", @"Toggle recording button stop title")];
        [videocameraSwitch setEnabled:NO]; //jxi;
        [doneButton setEnabled:NO];
        [captureButton setEnabled:YES];
    });
}

// --------------------------------------------------------------------------------------
- (void)captureManagerRecordingFinished:/*(AVCamCaptureManager *)captureManager*/(NSURL *)outputFileURL
{
    CFRunLoopPerformBlock(CFRunLoopGetMain(), kCFRunLoopCommonModes, ^(void) {
        [captureButton setTitle:NSLocalizedString(@"Record", @"Toggle recording button record title")];
        /*----------------------------------------*/
        capturedVideo = [outputFileURL retain];
        
/*        MPMoviePlayerController *player = [[MPMoviePlayerController alloc] initWithContentURL:videoURL];
        
        UIImage *newImage = [player thumbnailImageAtTime:1.0 timeOption:MPMovieTimeOptionNearestKeyFrame];
        
        //Player autoplays audio on init
        [player stop];
        [player release];
*/        
        // DB changes
        NSString *capturedImageUserdataID = [NSString stringWithString:[self saveCapturedVideo]];
        [self doShowVideoPreview:capturedImageUserdataID];
                
        [videocameraSwitch setEnabled:YES]; //jxi;
        [doneButton setEnabled:YES];
        [captureButton setEnabled:YES];
    });
}

// --------------------------------------------------------------------------------------
- (void)captureManagerStillImageCaptured:/*(AVCamCaptureManager *)captureManager*/ (NSData *)imageData
{
    CFRunLoopPerformBlock(CFRunLoopGetMain(), kCFRunLoopCommonModes, ^(void) {
        UIImage *newImage = [[UIImage alloc] initWithData:imageData];
        UIImage *tempImage = nil;
        int currentOrientation = [[UIApplication sharedApplication] statusBarOrientation];
        if (currentOrientation == UIInterfaceOrientationLandscapeRight) {
            tempImage = [TPUtil imageRotatedByDegrees:newImage
                                                     :(90 - 90)
                                                     :FALSE];
            
        } else if (currentOrientation == UIInterfaceOrientationLandscapeLeft) {
            tempImage = [TPUtil imageRotatedByDegrees:newImage
                                                     :(90 + 90)
                                                     :(FALSE)];
            
        } else if (currentOrientation == UIInterfaceOrientationPortraitUpsideDown) {
            tempImage = [TPUtil imageRotatedByDegrees:newImage
                                                     :(90 + 180)
                                                     :(FALSE)];
            
        } else {
            tempImage = [TPUtil imageRotatedByDegrees:newImage
                                                     :90
                                                     :(FALSE)];
        }
        
        int imageBigSize   = 1024;
        int imageSmallSize = 768;
        if (tempImage.size.width > tempImage.size.height) {
            [capturedImage release];
            capturedImage = [[TPUtil thumbnailFromImage:[[[UIImage alloc] initWithCGImage:[tempImage CGImage]] autorelease]
                                           scaledToSize:CGSizeMake(imageBigSize, imageSmallSize)] retain];
        } else {
            [capturedImage release];
            capturedImage = [[TPUtil thumbnailFromImage:[[[UIImage alloc] initWithCGImage:[tempImage CGImage]] autorelease]
                                           scaledToSize:CGSizeMake(imageSmallSize, imageBigSize)] retain];
        }
        
        // DB changes
        NSString *capturedImageUserdataID = [NSString stringWithString:[self saveCapturedImage]];
        [self doShowPreview:capturedImageUserdataID];
        
        [newImage release];
        [captureButton setEnabled:YES];
    });
}

// --------------------------------------------------------------------------------------
// jxi; Create userdata object for a captured image or video
// --------------------------------------------------------------------------------------
-(TPUserData *)createUserDataWithAttachInfo:(NSString *)capturedMedia_userdataid {
    
    // Initialize the rubric's userdata id and question id
    // Where captured image/video to be attached
    NSString *aud_id = @"";
    int aq_id = 0;
    
    // Check from where the camera button clicked.
    // Decide userdata_id/question_id of the parent userdata
    if (viewDelegate.cameraButtonClickedState == TP_CAMERA_FROM_TAB) {
        
    } else {
        
        aud_id = viewDelegate.rubricVC.cur_attachlistVC.aud_id;
        
        if (viewDelegate.cameraButtonClickedState == TP_CAMERA_FROM_QUESTION ) {
            
            aq_id = viewDelegate.rubricVC.cur_attachlistVC.aq_id;
        }
    }
    
    TPUserData *mediaUserData;
    
    if (videocameraSwitch.on == NO) {
        // If it is video capturing mode then create userdata object of video type
        mediaUserData = [[TPUserData alloc] initWithModel:viewDelegate.model
                               userdataID:capturedMedia_userdataid
                                     name:@"Video"
                                    share:0
                              description:@""
                             creationDate:captureDate
                                     type:TP_USERDATA_TYPE_VIDEO
                                  aAud_id:aud_id aAq_id:aq_id];
    } else {
        // If it is image capturing mode then create userdata object of image type
        mediaUserData = [[TPUserData alloc] initWithModel:viewDelegate.model
                               userdataID:capturedMedia_userdataid
                                     name:@"Photo"
                                    share:0
                              description:@""
                             creationDate:captureDate
                                     type:TP_USERDATA_TYPE_IMAGE
                                  aAud_id:aud_id aAq_id:aq_id];
    }
    
    return mediaUserData;
}

// --------------------------------------------------------------------------------------
- (NSString *)saveCapturedImage {
    
    if (debugCamera) NSLog(@"TPCameraVC saveCapturedImage");
    
    captureDate = [[NSDate date] retain];
    
    // Create ID to use when storing image
    NSString *capturedImageUserdataID = [TPUserData generateUserdataIDWithModel:viewDelegate.model
                                                                   creationDate:captureDate
                                                                           type:TP_USERDATA_TYPE_IMAGE];
    // Get a file path to use when storing image
    NSString *filename = [TPDatabase imagePathWithUserdataID:capturedImageUserdataID
                                                      suffix:@"jpg"
                                                   imageType:TP_IMAGE_TYPE_FULL];
    
    // Create image object with all related info
    [capturedImageObject release];
    capturedImageObject = [[TPImage alloc] initWithImage:capturedImage
                                              districtId:viewDelegate.model.appstate.district_id
                                              userdataID:capturedImageUserdataID
                                                    type:TP_IMAGE_TYPE_FULL
                                                   width:capturedImage.size.width
                                                  height:capturedImage.size.height
                                                  format:@"jpg"
                                                encoding:@"base64"
                                                  userId:viewDelegate.model.appstate.user_id
                                                modified:captureDate
                                                filename:filename
                                                  origin:TP_IMAGE_ORIGIN_LOCAL];
    /*
    // Create userdata object
    TPUserData *imageUserData = [[TPUserData alloc] initWithModel:viewDelegate.model
                                                       userdataID:capturedImageObject.userdata_id
                                                             name:@"Photo"
                                                            share:0
                                                      description:@""
                                                     creationDate:captureDate type:TP_USERDATA_TYPE_IMAGE];
    */
    TPUserData *imageUserData = [self createUserDataWithAttachInfo:capturedImageObject.userdata_id]; //jxi;
    
    // Store userdata object in DB
    [viewDelegate.model updateUserData:imageUserData setModified:YES];
    [imageUserData release];
    
    // Store image in DB and file
    [viewDelegate.model.database updateImage:capturedImageObject];
    
    // Create and save thumbnail
    UIImage *thumbnail_image = [capturedImageObject createThumbnailImage];
    NSString *thumbnail_filename = [TPDatabase imagePathWithUserdataID:capturedImageObject.userdata_id
                                                                suffix:@"jpg"
                                                             imageType:TP_IMAGE_TYPE_THUMBNAIL];
    TPImage *thumbnail = [[TPImage alloc] initWithImage:thumbnail_image
                                             districtId:capturedImageObject.district_id
                                             userdataID:capturedImageObject.userdata_id
                                                   type:TP_IMAGE_TYPE_THUMBNAIL
                                                  width:thumbnail_image.size.width
                                                 height:thumbnail_image.size.height
                                                 format:@"jpg"
                                               encoding:@"binary"
                                                 userId:capturedImageObject.user_id
                                               modified:[NSDate date]
                                               filename:thumbnail_filename
                                                 origin:TP_IMAGE_ORIGIN_LOCAL];
    [viewDelegate.model.database updateImage:thumbnail];
    [thumbnail release];
    
    // Update userdata list with image
    [viewDelegate reloadUserdataList];
    
    //jxi;
    if (viewDelegate.cameraButtonClickedState != TP_CAMERA_FROM_TAB) {
        [viewDelegate.rubricVC.cur_attachlistVC reset];
    }
    
    [viewDelegate.model setNeedSyncStatus:NEEDSYNC_STATUS_NOTSYNCED forced:YES];
    [viewDelegate setSyncStatus];
    
    return capturedImageUserdataID;
}

// --------------------------------------------------------------------------------------
- (NSString *)saveCapturedVideo {
    
    if (debugCamera) NSLog(@"TPVideoVC saveCapturedVideo");
    
    captureDate = [[NSDate date] retain];
    
    // Create ID to use when storing image
    NSString *capturedVideoUserdataID = [TPUserData generateUserdataIDWithModel:viewDelegate.model
                                                                   creationDate:captureDate
                                                                           type:TP_USERDATA_TYPE_VIDEO];
    // Get a file path to use when storing video
    NSString *filename = [TPDatabase videoPathWithUserdataID:capturedVideoUserdataID
                                                      suffix:@"MOV"];
    
    // Create image object with all related info
    [capturedVideoObject release];
    capturedVideoObject = [[TPVideo alloc] initWithImage:capturedVideo
                                              districtId:viewDelegate.model.appstate.district_id
                                              userdataID:capturedVideoUserdataID
                                                    type:TP_IMAGE_TYPE_FULL //TP_USERDATA_TYPE_VIDEO
                                                   width:capturedImage.size.width
                                                  height:capturedImage.size.height
                                                  format:@"MOV"
                                                encoding:@"base64"
                                                  userId:viewDelegate.model.appstate.user_id
                                                modified:captureDate
                                                filename:filename
                                                  origin:TP_IMAGE_ORIGIN_LOCAL];

    TPUserData *videoUserData = [self createUserDataWithAttachInfo:capturedVideoObject.userdata_id]; //jxi;
    
    // Store userdata object in DB
    [viewDelegate.model updateUserData:videoUserData setModified:YES];
    [videoUserData release];
    
    // Store video in DB and file
    [viewDelegate.model.database updateVideo:capturedVideoObject];
    
    // Update userdata list with video
    [viewDelegate reloadUserdataList];
        
    //jxi;
    if (viewDelegate.cameraButtonClickedState != TP_CAMERA_FROM_TAB) {
        [viewDelegate.rubricVC.cur_attachlistVC reset];
    }
    
    [viewDelegate.model setNeedSyncStatus:NEEDSYNC_STATUS_NOTSYNCED forced:YES];
    [viewDelegate setSyncStatus];
    
    return capturedVideoUserdataID;
}


// --------------------------------------------------------------------------------------
- (void)captureManagerDeviceConfigurationChanged:(AVCamCaptureManager *)captureManager
{
	[self updateButtonStates];
}

// ============================= TPPreviewDelegate ======================================
// --------------------------------------------------------------------------------------
- (void)trashPreviewWithDeviceOrientation:(UIDeviceOrientation) orientation {
    
    if (debugCamera) NSLog(@"TPCameraVC trashPreviewWithDeviceOrientation");
    
    [self dismissViewControllerAnimated:YES completion:nil];
    [viewDelegate.model deleteUserData:capturedImageObject.userdata_id includingImages:YES];
    
    [[[self captureManager]session]startRunning];
    [capturedImage release];
    capturedImage = nil;
}

// --------------------------------------------------------------------------------------
- (void)donePreviewWithDeviceOrientation:(UIDeviceOrientation)orientation {
    
    if (debugCamera) NSLog(@"TPCameraVC donePreviewWithDeviceOrientation");
    
    [self dismissViewControllerAnimated:YES completion:nil];
    [[[self captureManager]session]startRunning];
    
    //jxi;
    if (viewDelegate.cameraButtonClickedState != TP_CAMERA_FROM_TAB) {
        [viewDelegate.rubricVC.cur_attachlistVC reset];
        [viewDelegate.rubricVC.cur_attachlistVC updateUI];
    }
}

// --------------------------------------------------------------------------------------
- (void)savePreviewWithDeviceOrientation:(UIDeviceOrientation) orientation
                               imageName:(NSString *)aName
                                   share:(int)aShare
                             description:(NSString *)aDescription
                                 dismiss:(BOOL)dismiss {
    
    if (debugCamera) NSLog(@"TPCameraVC savePreviewWithDeviceOrientation");
    
    TPUserData *imageUserData = [[TPUserData alloc] initWithUserData:[viewDelegate.model getUserDataFromListById:capturedImageObject.userdata_id]]; //jxi;
    
        // If info has changed then save //jxi;
        imageUserData.name = aName;
        imageUserData.description = aDescription;
        imageUserData.share = aShare;
    
    // If user is owner then update
    if (viewDelegate.model.appstate.user_id == imageUserData.user_id) {
        //[viewDelegate.model setStateToSync:imageUserData];
        [viewDelegate.model updateUserData:imageUserData setModified:YES];
    }
    [imageUserData release];
    
    if (viewDelegate.cameraButtonClickedState == TP_CAMERA_FROM_TAB) {
        
        [viewDelegate reloadUserdataList];
    } else {
        [viewDelegate.model deriveVideoList];
        [viewDelegate.model deriveImageList];
        [viewDelegate.model deriveUserDataList];
    }
     
    [viewDelegate.model setNeedSyncStatus:NEEDSYNC_STATUS_NOTSYNCED forced:YES];
    [viewDelegate setSyncStatus];
}

// ============================= TPVideoPreviewDelegate ======================================
// --------------------------------------------------------------------------------------
- (void)trashVideoPreviewWithDeviceOrientation:(UIDeviceOrientation) orientation {
    
    if (debugCamera) NSLog(@"TPCameraVC trashVideoPreviewWithDeviceOrientation");
    
    [self dismissViewControllerAnimated:YES completion:nil];
    [viewDelegate.model deleteUserData:capturedVideoObject.userdata_id includingImages:YES];
    
    [[[self captureManager]session]startRunning];
    [capturedVideo release];
    capturedVideo = nil;
}

// --------------------------------------------------------------------------------------
- (void)doneVideoPreviewWithDeviceOrientation:(UIDeviceOrientation)orientation {
    
    if (debugCamera) NSLog(@"TPCameraVC doneVideoPreviewWithDeviceOrientation");
    
    [self dismissViewControllerAnimated:YES completion:nil];
    [[[self captureManager]session]startRunning];
    
    //jxi;
    if (viewDelegate.cameraButtonClickedState != TP_CAMERA_FROM_TAB) {
        [viewDelegate.rubricVC.cur_attachlistVC reset];
        [viewDelegate.rubricVC.cur_attachlistVC updateUI];
    }
}

// --------------------------------------------------------------------------------------
- (void)saveVideoPreviewWithDeviceOrientation:(UIDeviceOrientation) orientation
                               imageName:(NSString *)aName
                                   share:(int)aShare
                             description:(NSString *)aDescription
                                 dismiss:(BOOL)dismiss {
    
    if (debugCamera) NSLog(@"TPCameraVC saveVideoPreviewWithDeviceOrientation");
    
    TPUserData *videoUserData = [[TPUserData alloc] initWithUserData:[viewDelegate.model getUserDataFromListById:capturedVideoObject.userdata_id]]; //jxi;
    
    // If info has changed then save //jxi;
    videoUserData.name = aName;
    videoUserData.description = aDescription;
    videoUserData.share = aShare;
    
    // If user is owner then update
    if (viewDelegate.model.appstate.user_id == videoUserData.user_id) {
        [viewDelegate.model updateUserData:videoUserData setModified:YES];
    }
    [videoUserData release];
    
    if (viewDelegate.cameraButtonClickedState == TP_CAMERA_FROM_TAB) {
        
        [viewDelegate reloadUserdataList];
    } else {
        [viewDelegate.model deriveVideoList];
        [viewDelegate.model deriveImageList];
        [viewDelegate.model deriveUserDataList];
    }
    
    [viewDelegate.model setNeedSyncStatus:NEEDSYNC_STATUS_NOTSYNCED forced:YES];
    [viewDelegate setSyncStatus];
}

@end