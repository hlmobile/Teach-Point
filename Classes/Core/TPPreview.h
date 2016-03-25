//
//  TPPreview.h
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

//-----------------------------------------------------------------
@protocol TPPreviewDelegate <NSObject>

@optional
- (void) trashPreviewWithDeviceOrientation:(UIDeviceOrientation)orientation;
- (void) donePreviewWithDeviceOrientation:(UIDeviceOrientation)orientation;
- (void) savePreviewWithDeviceOrientation:(UIDeviceOrientation)orientation imageName:(NSString *)aName share:(int)aShare description:(NSString *)aDescription dismiss:(BOOL)dismiss;

@end

//-----------------------------------------------------------------
// TPPreview - preview of the captured image
//-----------------------------------------------------------------
@interface TPPreviewVC : UIViewController <UITextFieldDelegate, UITextViewDelegate, TPImagePreviewDelegate> {
    
    TPView *viewDelegate;
    id<TPPreviewDelegate> previewDelegate;
    NSString *imageDescription;
    NSString *userdata_id;
    BOOL newImage;
    
    // main veiw
    UIToolbar *toolbar;
    UIBarButtonItem *trashBButton;
    UITextField *nameTextField;
    UISwitch *shareSwitch;
    UIImageView *mainImageView;
    UIActivityIndicatorView *imageLoadingIndicator;
    UIViewController *parentController;
    BOOL toolbarVisible;
    CGRect visibleToolbarFrame;
    CGRect invisibleToolbarFrame;
    
    // slider veiw
    TPRoundRectView *detailsSliderView;
    UILabel *nameSliderLabel, *shareSliderLabel, *descriptionSliderLabel;
    UITextField *nameSliderTextField;
    UISwitch *shareSliderSwitch;
    UITextView *descriptionSliderTextView;
    UIButton *doneDescriptionButton;
    BOOL isDetailsViewVisible;
    CGRect hiddenSliderFrame;
    CGRect visibleSliderFrame;
    
    UIPopoverController *deletePopoverVC;
    
}

@property (nonatomic, retain) id<TPPreviewDelegate> previewDelegate;
@property (nonatomic, retain) NSString *imageDescription;
@property (nonatomic, retain) NSString *userdata_id;

- (id) initWithViewDelegate:(TPView *)delegate userdata:(TPUserData *)someData image:(UIImage *)mainImage name:(NSString *)name share:(BOOL)share description:(NSString *)description userdataID:(NSString *)userdataid imageOrigin:(int)imageOrigin newImage:(BOOL)isNewImage;
- (void)doneAction;

@end
