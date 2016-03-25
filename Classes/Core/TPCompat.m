//
//  TPCompat.m
//  teachpoint
//
//  Created by Chris Dunn on 10/7/12.
//
//  Used to handle compatibility across multiple iOS versions when code becomes deprecated
//
//

#import "TPCompat.h"
#import "TPData.h"

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@implementation TPCompat

// --------------------------------------------------------------------------------------
+ (BOOL) isVersion5 {
    NSString *version = [[UIDevice currentDevice] systemVersion];
    if ([[version substringToIndex:1] isEqualToString:@"5"]) {
        return YES;
    } else {
        return NO;
    }
}

// --------------------------------------------------------------------------------------
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
+ (NSString *) getUdid {
    UIDevice *device = [UIDevice currentDevice];
    if ([device respondsToSelector:@selector(uniqueIdentifier)]) {
      return [device uniqueIdentifier];
    } else {
        return @"";
    }
}
#pragma GCC diagnostic warning "-Wdeprecated-declarations"

// --------------------------------------------------------------------------------------
+ (void) setCameraOrientation:(AVCaptureVideoPreviewLayer *)previewLayer orientation:(UIInterfaceOrientation)orientation {
    
    if (debugRotate) NSLog(@"TPCompat setCameraOrientation orientation=%d", orientation);
    
    if ([TPCompat isVersion5]) {
        
        if ([previewLayer isOrientationSupported]) {
            if (orientation == UIInterfaceOrientationPortrait) {
                AVCaptureVideoOrientation orientation = AVCaptureVideoOrientationPortrait;
                [previewLayer setOrientation:orientation];
            } else if (orientation == UIInterfaceOrientationPortraitUpsideDown) {
                AVCaptureVideoOrientation orientation = AVCaptureVideoOrientationPortraitUpsideDown;
                [previewLayer setOrientation:orientation];
            } else if (orientation == UIInterfaceOrientationLandscapeLeft) {
                AVCaptureVideoOrientation orientation = AVCaptureVideoOrientationLandscapeLeft;
                [previewLayer setOrientation:orientation];
            } else if (orientation == UIInterfaceOrientationLandscapeRight) {
                AVCaptureVideoOrientation orientation = AVCaptureVideoOrientationLandscapeRight;
                [previewLayer setOrientation:orientation];
            }
        }
        
    } else {
        
        if ([[previewLayer connection] isVideoOrientationSupported]) {
            if (orientation == UIInterfaceOrientationPortrait) {
                [[previewLayer connection] setVideoOrientation:AVCaptureVideoOrientationPortrait];
            } else if (orientation == UIInterfaceOrientationPortraitUpsideDown) {
                [[previewLayer connection] setVideoOrientation:AVCaptureVideoOrientationPortraitUpsideDown];
            } else if (orientation == UIInterfaceOrientationLandscapeLeft) {
                [[previewLayer connection] setVideoOrientation:AVCaptureVideoOrientationLandscapeLeft];
            } else if (orientation == UIInterfaceOrientationLandscapeRight) {
                [[previewLayer connection] setVideoOrientation:AVCaptureVideoOrientationLandscapeRight];
            }
        }
    }
}

@end

