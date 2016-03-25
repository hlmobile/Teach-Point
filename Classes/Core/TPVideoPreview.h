//
//  TPVideoPreview.h
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
#import <MediaPlayer/MediaPlayer.h>

#import "TPImagePreviewDelegate.h"

//-----------------------------------------------------------------
@protocol TPVideoPreviewDelegate <NSObject>

@optional
- (void) trashVideoPreviewWithDeviceOrientation:(UIDeviceOrientation)orientation;
- (void) doneVideoPreviewWithDeviceOrientation:(UIDeviceOrientation)orientation;
- (void) saveVideoPreviewWithDeviceOrientation:(UIDeviceOrientation)orientation imageName:(NSString *)aName share:(int)aShare description:(NSString *)aDescription dismiss:(BOOL)dismiss;

@end

//-----------------------------------------------------------------
// TPVideoPreview - preview of the captured image
//-----------------------------------------------------------------
@interface TPVideoPreviewVC : UIViewController <UITextFieldDelegate, UITextViewDelegate, TPImagePreviewDelegate> {
    
    TPView *viewDelegate;
    id<TPVideoPreviewDelegate> previewDelegate;
    NSString *videoDescription;
    NSString *userdata_id;
    BOOL newImage;
    
    // main veiw
    UIToolbar *toolbar;
    UIBarButtonItem *trashBButton;
    UITextField *nameTextField;
    UISwitch *shareSwitch;
    UIImageView *mainImageView;
    UIImageView *playImageView;
    UIActivityIndicatorView *imageLoadingIndicator;
    UIViewController *parentController;
    BOOL toolbarVisible;
    CGRect visibleToolbarFrame;
    CGRect invisibleToolbarFrame;
    
    // slider veiw
    TPRoundRectView *detailsSliderView;
    UILabel *nameSliderLabel, *shareSliderLabel, *descriptionSliderLabel, *descriptionVideo;
    UITextField *nameSliderTextField;
    UISwitch *shareSliderSwitch;
    UITextView *descriptionSliderTextView;
    UIButton *doneDescriptionButton;
    BOOL isDetailsViewVisible;
    CGRect hiddenSliderFrame;
    CGRect visibleSliderFrame;
    
    UIPopoverController *deletePopoverVC;
}

@property (nonatomic, retain) id<TPVideoPreviewDelegate> previewDelegate;
@property (nonatomic, retain) NSString *videoDescription;
@property (nonatomic, retain) NSString *userdata_id;
@property (nonatomic, retain) NSURL *videoURL;
@property (nonatomic, retain) MPMoviePlayerViewController *movieViewController;
- (id) initWithViewDelegate:(TPView *)delegate userdata:(TPUserData *)someData image:(UIImage *)mainImage name:(NSString *)name share:(BOOL)share description:(NSString *)description userdataID:(NSString *)userdataid imageOrigin:(int)imageOrigin newImage:(BOOL)isNewImage videoURL:(NSURL*)videoURL modified:(NSDate*)modified;
- (void)doneAction;

@end
