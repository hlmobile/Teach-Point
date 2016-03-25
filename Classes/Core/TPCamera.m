#import "TPView.h"
#import "TPModel.h"
#import "TPUtil.h"
#import "TPCamera.h"
#import "TPData.h"
#import "TPDatabase.h"
#import "TPRubricList.h"
#import "TPRoundRect.h"
#import "TPCompat.h"

#import <QuartzCore/QuartzCore.h>

@implementation TPCameraVC

// --------------------------------------------------------------------------------------
- (id)initWithView:(TPView *)mainView image:(UIImage *)anImage {
    
    if (debugCamera) NSLog(@"TPCameraVC initWithView");
	self = [super init];
    if (self) {

		viewDelegate = mainView;
		captureStatus = CAMERA_STATUS_UNINITIALIZED;
        capturedImage = nil;
        capturedImageObject = nil;
        doCapture = FALSE;
        [self.view setBackgroundColor:[UIColor whiteColor]];
		[self initCapture];	
        
        // toolbar with buttons
        toolBar = [[UIToolbar alloc] init];
        toolBar.barStyle = UIBarStyleBlack;
        toolBar.translucent = YES;

        NSMutableArray *toolbarItems = [NSMutableArray array];

        if ([TPUtil isCameraAvailableOnTheDevice]) {
            switchCameraButton = [[[UIBarButtonItem alloc] initWithTitle:@"Switch camera" style:UIBarButtonItemStyleBordered target:self action:@selector(doSwitchCameras)] autorelease];
            [toolbarItems addObject:switchCameraButton];
        }

        UIBarButtonItem *flexibleSpace1 = [[[UIBarButtonItem alloc] 
                                           initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace 
                                                                target:nil 
                                                                action:nil] autorelease];
        captureButton = [[[UIBarButtonItem alloc] initWithTitle:@"Capture image" 
                                                         style:UIBarButtonItemStyleBordered 
                                                        target:self 
                                                        action:@selector(doCaptureImage)] autorelease];
        UIBarButtonItem *flexibleSpace2 = [[[UIBarButtonItem alloc] 
                                           initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace 
                                                                target:nil 
                                                                action:nil] autorelease];
        doneButton = [[[UIBarButtonItem alloc] initWithTitle:@"Done" 
                                                      style:UIBarButtonItemStyleBordered  
                                                     target:self
                                                     action:@selector(doReturn)] autorelease];
                
        [toolbarItems addObject:flexibleSpace1];
        [toolbarItems addObject:captureButton];
        [toolbarItems addObject:flexibleSpace2];
        [toolbarItems addObject:doneButton];
        self.toolbarItems = toolbarItems;
    }
        
    return self;
}

// --------------------------------------------------------------------------------------
-(void) dealloc {
    
    if (debugCamera) NSLog(@"TPCameraVC dealloc");
    
    [emptyButton release];
    [captureButton release];
    [doneButton release];
    [captureSession release];
    [switchCameraButton release];
    [capturedImage release];
    [capturedImageObject release];
    [captureDate release];
    [super dealloc];
}

// --------------------------------------------------------------------------------------
- (void)updateUIWithInterfaceOrientation:(UIInterfaceOrientation) orientation {
    
    if (debugRotate) NSLog(@"TPCameraVC updateUIWithInterfaceOrientation %d", orientation);
    if (debugRotate) NSLog(@"frame %f %f", self.view.frame.size.width, self.view.frame.size.height);
    
    if (orientation == UIInterfaceOrientationPortrait ||
        orientation == UIInterfaceOrientationPortraitUpsideDown) {
        if (debugRotate) NSLog(@"portrait");
        [previewLayer setFrame:CGRectMake(0, 0, 768.0, 1024.0)];
    } else {
        if (debugRotate) NSLog(@"landscape");
        [previewLayer setFrame:CGRectMake(0, 0, 1024.0, 768.0)];
    }
    
    // Set preview orientation
    [TPCompat setCameraOrientation:previewLayer orientation:orientation];
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
-(void)doCaptureImage {
    // take an image from camera
    doCapture = TRUE;
}

// --------------------------------------------------------------------------------------
-(void)doReturn {
    if (debugCamera) NSLog(@"TPCameraVC doReturn");
    [viewDelegate cameraDoneCapture];
}

// --------------------------------------------------------------------------------------
- (void)doShowPreview:(NSString *)userdata_id {
    if (debugCamera) NSLog(@"TPCameraVC doShowPreview");
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
    [self stopCapture];
    [previewVC release];
}

// --------------------------------------------------------------------------------------
- (UIView *) videoPreviewWithFrame:(CGRect) frame captureSession:(AVCaptureSession *) session {
    
    AVCaptureVideoPreviewLayer *tempPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
    [tempPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    tempPreviewLayer.frame = frame;
    
    UIView* tempView = [[UIView alloc] init];
    [tempView.layer addSublayer:tempPreviewLayer];
    tempView.frame = frame;
    
    [tempPreviewLayer autorelease];
    [tempView autorelease];
    return tempView;
}

// --------------------------------------------------------------------------------------
// Setting up the input
- (void)initCapture {
    
	// Back camera as capture device if available
	AVCaptureDevice *captureDevice = [self cameraIfAvailable: AVCaptureDevicePositionBack];
    
	// Create a capture input 
	if (captureDevice) {
        
		AVCaptureDeviceInput *captureInput = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:NULL];
        
		// Create a capture output 
		AVCaptureVideoDataOutput *captureOutput = [[AVCaptureVideoDataOutput alloc] init]; 
		[captureOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
        
		// Set the video output to store frame in BGRA 
		NSString* key = (NSString*)kCVPixelBufferPixelFormatTypeKey; 
		NSNumber* value = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA]; 
		NSDictionary* videoSettings = [NSDictionary dictionaryWithObject:value forKey:key]; 
		[captureOutput setVideoSettings:videoSettings];
        
		// Create a capture Session 
		captureSession = [[AVCaptureSession alloc] init];
        
		// Add to CaptureSession input and output 
		[captureSession addInput:captureInput]; 
		[captureSession addOutput:captureOutput]; 
		
		// Initialize preview layer
        previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:captureSession];
        [previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
        [previewLayer setFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
		[self.view.layer addSublayer:previewLayer];
        
		// Configure CaptureSession 
		[captureSession beginConfiguration]; 
		[captureSession setSessionPreset:AVCaptureSessionPresetPhoto]; 
		[captureSession commitConfiguration]; 
	}
}

// --------------------------------------------------------------------------------------
- (AVCaptureDevice *)cameraIfAvailable :(int)cameraPosition {
    
    //  look at all the video devices and get the first one that's on the front
    NSArray *videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    AVCaptureDevice *captureDevice = nil;
    
    for (AVCaptureDevice *device in videoDevices) {
		if (cameraPosition) {
			if (device.position == cameraPosition) {
				captureDevice = device;
				captureStatus = device.position;
				break;
			}
		}
		else {
			captureDevice = device;
			captureStatus = device.position;
			break;
		}
    }
	
    //  couldn't find front camera
    if (!captureDevice) {
		captureStatus = CAMERA_STATUS_NO_CAMERA;
    }
	
    return captureDevice;
}

// --------------------------------------------------------------------------------------
- (void)doSwitchCameras {
    int captureDevicePosition;
    
    if (captureStatus == CAMERA_STATUS_FRONT) {
        captureDevicePosition = CAMERA_STATUS_BACK;
    } else {
        if (captureStatus == CAMERA_STATUS_BACK) {
            captureDevicePosition = CAMERA_STATUS_FRONT;
        } else {
            return;
        }
    }
    
    AVCaptureDevice *captureDevice = [self cameraIfAvailable: captureDevicePosition];
	// Create a capture input 
	if (captureDevice) {
		AVCaptureDeviceInput *captureInput = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:NULL];
        
        [captureSession removeInput:[captureSession.inputs objectAtIndex:0]];
        [captureSession addInput:captureInput];
    }
}

// --------------------------------------------------------------------------------------
- (void)startCapture {
    [captureSession startRunning];
}

// --------------------------------------------------------------------------------------
- (void)stopCapture {
    [captureSession stopRunning];
}

// --------------------------------------------------------------------------------------
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection { 
    
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer); 
    //Locking the image buffer
    CVPixelBufferLockBaseAddress(imageBuffer,0); 
    //Getting information about the image
    uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(imageBuffer); 
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer); 
    size_t width = CVPixelBufferGetWidth(imageBuffer); 
    size_t height = CVPixelBufferGetHeight(imageBuffer); 
    
    //Create a CGImageRef from the CVImageBufferRef
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB(); 
    CGContextRef newContext = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst); 
    CGImageRef newImage = CGBitmapContextCreateImage(newContext); 
	//Unlocking the  image buffer
	CVPixelBufferUnlockBaseAddress(imageBuffer,0);
	
    //Releasing some components
    CGContextRelease(newContext); 
    CGColorSpaceRelease(colorSpace);

	//Converting result to UIImage
	if (doCapture) {
        UIImage *tempImage = nil;
        int currentOrientation = [[UIApplication sharedApplication] statusBarOrientation];
        if (currentOrientation == UIInterfaceOrientationLandscapeRight) {
            tempImage = [TPUtil imageRotatedByDegrees:[UIImage imageWithCGImage:newImage] 
                                                     :(90 - 90)
                                                     :(captureStatus == CAMERA_STATUS_FRONT)];

        } else if (currentOrientation == UIInterfaceOrientationLandscapeLeft) {
            tempImage = [TPUtil imageRotatedByDegrees:[UIImage imageWithCGImage:newImage] 
                                                     :(90 + 90)
                                                     :(captureStatus == CAMERA_STATUS_FRONT)];
        
        } else if (currentOrientation == UIInterfaceOrientationPortraitUpsideDown) {
            tempImage = [TPUtil imageRotatedByDegrees:[UIImage imageWithCGImage:newImage] 
                                                     :(90 + 180)
                                                     :(captureStatus == CAMERA_STATUS_FRONT)];
        
        } else {
            tempImage = [TPUtil imageRotatedByDegrees:[UIImage imageWithCGImage:newImage] 
                                                     :90 
                                                     :(captureStatus == CAMERA_STATUS_FRONT)];
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
        
        doCapture = FALSE;
        
        // DB changes
        NSString *capturedImageUserdataID = [NSString stringWithString:[self saveCapturedImage]];
        [self doShowPreview:capturedImageUserdataID];
    }
    
    //Releasing the CGImageRef
	CGImageRelease(newImage);
    
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
    
    // Create userdata object
    /*
     TPUserData *imageUserData = [[TPUserData alloc] initWithModel:viewDelegate.model
                                                       userdataID:capturedImageObject.userdata_id 
                                                             name:@"Photo" 
                                                            share:0 
                                                      description:@"" 
                                                     creationDate:captureDate];*/
    // Create userdata object
    TPUserData *imageUserData = [[TPUserData alloc] initWithModel:viewDelegate.model
                                                       userdataID:capturedImageObject.userdata_id
                                                             name:@"Photo"
                                                            share:0
                                                      description:@""
                                                     creationDate:captureDate type:TP_USERDATA_TYPE_IMAGE];
    
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
    
    [viewDelegate.model setNeedSyncStatus:NEEDSYNC_STATUS_NOTSYNCED forced:YES];
    [viewDelegate setSyncStatus];

    return capturedImageUserdataID;
}

// ============================= TPPreviewDelegate ======================================

// --------------------------------------------------------------------------------------
- (void)trashPreviewWithDeviceOrientation:(UIDeviceOrientation) orientation {

    if (debugCamera) NSLog(@"TPCameraVC trashPreviewWithDeviceOrientation");
    
    [self dismissViewControllerAnimated:YES completion:nil];
    [viewDelegate.model deleteUserData:capturedImageObject.userdata_id includingImages:YES];
    
    [self startCapture];
    [capturedImage release];
    capturedImage = nil;
}

// --------------------------------------------------------------------------------------
- (void)donePreviewWithDeviceOrientation:(UIDeviceOrientation)orientation {
    
    if (debugCamera) NSLog(@"TPCameraVC donePreviewWithDeviceOrientation");
    
    [self dismissViewControllerAnimated:YES completion:nil];
    [self startCapture];
}

// --------------------------------------------------------------------------------------
- (void)savePreviewWithDeviceOrientation:(UIDeviceOrientation) orientation
                               imageName:(NSString *)aName
                                   share:(int)aShare
                             description:(NSString *)aDescription
                                 dismiss:(BOOL)dismiss {
    
    if (debugCamera) NSLog(@"TPCameraVC savePreviewWithDeviceOrientation");
    
    // save userdata to database
    /*
    TPUserData *imageUserData = [[TPUserData alloc] initWithModel:viewDelegate.model
                                                       userdataID:capturedImageObject.userdata_id
                                                             name:aName 
                                                            share:aShare
                                                      description:aDescription 
                                                     creationDate:captureDate];
    */
    TPUserData *imageUserData = [[TPUserData alloc] initWithModel:viewDelegate.model
                                                       userdataID:capturedImageObject.userdata_id
                                                             name:aName
                                                            share:aShare
                                                      description:aDescription
                                                     creationDate:captureDate type:TP_USERDATA_TYPE_IMAGE];
    
    
    // If user is owner then update
    if (viewDelegate.model.appstate.user_id == imageUserData.user_id) {
        [viewDelegate.model updateUserData:imageUserData setModified:YES];
    }
    [imageUserData release];

    [viewDelegate reloadUserdataList];
    [viewDelegate.model setNeedSyncStatus:NEEDSYNC_STATUS_NOTSYNCED forced:YES];
    [viewDelegate setSyncStatus];
}

@end
