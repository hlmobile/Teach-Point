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

#import <UIKit/UIKit.h>
#import "TPImagePreviewDelegate.h"
#import "TPPreview.h"
#import "TPVideoPreview.h"

//-----------------------------------------------------------------
// TPCamraVC - view with camera video output
//-----------------------------------------------------------------
@class AVCamCaptureManager, AVCamPreviewView, AVCaptureVideoPreviewLayer;

@interface TPVideoVC : UIViewController<TPPreviewDelegate, TPVideoPreviewDelegate> {
    
	TPView *viewDelegate;
    
    UIToolbar *toolBar;
    UIBarButtonItem *captureButton, *doneButton, *switchCameraButton;
    UISwitch *videocameraSwitch;
    
	BOOL flagVideoImage;
	UIBackgroundTaskIdentifier backgroundRecordingID;
    
    TPImage *capturedImageObject;
	UIImage *capturedImage;

    TPVideo *capturedVideoObject;
    NSURL *capturedVideo;
    
    NSDate *captureDate;
}

@property (nonatomic,retain) AVCamCaptureManager *captureManager;
@property (nonatomic,retain) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;
@property (nonatomic,retain) IBOutlet UILabel *focusModeLabel;

- (void) startRecording;
- (void) stopRecording;
- (id)initWithView:(TPView *)mainView image:(UIImage *)anImage;
- (void)initCapture;

@end
