//
//  TPCamera.h
//  teachpoint
//
//  Created by Doroshenko Dmitriy on 12.03.12.
//  Copyright 2011 QArea. All rights reserved.
//

@class TPView;
@class TPImage;
@class TPRoundRectView;

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreMedia/CoreMedia.h>

#import "TPImagePreviewDelegate.h"
#import "TPPreview.h"

//-----------------------------------------------------------------
typedef enum {
	CAMERA_STATUS_UNINITIALIZED = -1,
	CAMERA_STATUS_NO_CAMERA = 0,
	CAMERA_STATUS_BACK = 1,
	CAMERA_STATUS_FRONT = 2
} TPCameraCaptureStatus;


//-----------------------------------------------------------------
// TPCamraVC - view with camera video output
//-----------------------------------------------------------------
@interface TPCameraVC : UIViewController<AVCaptureVideoDataOutputSampleBufferDelegate, TPPreviewDelegate> {
    
	TPView *viewDelegate;
	
	AVCaptureSession* captureSession;
	AVCaptureVideoPreviewLayer* previewLayer;
    
    UIBarButtonItem *captureButton, *doneButton, *emptyButton, *switchCameraButton;
    UIToolbar *toolBar;
    
	int captureStatus;
    
    TPImage *capturedImageObject;
	UIImage *capturedImage;
    NSDate *captureDate;
    BOOL doCapture;
    
    id passImageDelegate;
    SEL passImageSelector;
}

- (id)initWithView:(TPView *)mainView image:(UIImage *)anImage;
- (void)initCapture;
- (AVCaptureDevice *)cameraIfAvailable :(int)cameraPosition;

// buttons actions
- (void)doReturn;
- (void)doSwitchCameras;
- (void)doCaptureImage;

- (void)startCapture;
- (void)stopCapture;

- (void) updateUIWithInterfaceOrientation:(UIInterfaceOrientation) orientation;

@end
