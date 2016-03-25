//
//  TPCompat.h
//  teachpoint
//
//  Created by Chris Dunn on 10/7/12.
//
//  Used to handle compatibility across multiple iOS versions when code becomes deprecated
//
//

@class AVCaptureVideoPreviewLayer;

// --------------------------------------------------------------------------------------
// Compatible with UITextAlignment (deprecated in iOS 6) and NSTextAlignment (iOS 6 or later)
// --------------------------------------------------------------------------------------
#define TPTextAlignmentLeft 0
#define TPTextAlignmentCenter 1
#define TPTextAlignmentRight 2

// --------------------------------------------------------------------------------------
// Compatible with UILineBreakMode (deprecated in iOS 6) and NSLineBreakMode (iOS 6 or later)
// --------------------------------------------------------------------------------------
#define TPLineBreakByWordWrapping 0

// --------------------------------------------------------------------------------------
@interface TPCompat : NSObject {
}

+ (BOOL) isVersion5;
+ (NSString *) getUdid;
+ (void) setCameraOrientation:(AVCaptureVideoPreviewLayer *)previewLayer orientation:(UIInterfaceOrientation)orientation;

@end
