//
//  TPRubricList.m
//  teachpoint
//
//  Created by Chris Dunn on 4/6/11.
//  Copyright 2011 Clear Pond Technologies, Inc. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "TPData.h"
#import "TPView.h"
#import "TPModel.h"
#import "TPModelSync.h"
#import "TPDatabase.h"
#import "TPRubricList.h"
#import "TPNewPO.h"
#import "TPUtil.h"
#import "TPCompat.h"
#import "TPPreview.h"
#import "TPVideoPreview.h" //jxi;
#import <MediaPlayer/MediaPlayer.h> //jxi;

#define TP_ATTACH_STATUS_WIDTH_LANDSCAPE        500
#define TP_ATTACH_STATUS_WIDTH_PORTRAIT         560

#define TP_THUMBNAIL_LEFT_MARGIN                400
#define TP_THUMBNAIL_BOTTOM_MARGIN                8

// --------------------------------------------------------------------------------------
// TPRubricListVC - renders list of userdata for selected user
// --------------------------------------------------------------------------------------
@implementation TPRubricListVC

@synthesize imagePreviewVC;
@synthesize videoPreviewVC; //jxi;
@synthesize videoVC; //jxi;
@synthesize previewVC;
@synthesize preview_userdataid;

// --------------------------------------------------------------------------------------
- (id)initWithView:(TPView *)mainview {
    if (debugRubricList) NSLog(@"TPRubricList initWithView");
    self = [super init];
    if (self != nil) {
        
        viewDelegate = mainview;
        self.preview_userdataid = nil;
        
        formDataArrays = [[NSMutableArray alloc] init]; //jxi;

        imagePreviewVC = nil;
        previewVC = nil;
        
        // left button
        leftNewButton = [[UIBarButtonItem alloc] 
                      initWithTitle:@"New Form" 
                      style: UIBarButtonItemStyleBordered
                      target: self 
                      action: @selector(shownew)];
        [self.navigationItem setLeftBarButtonItem:leftNewButton];
        
        // right button
        rightbutton = [[UIBarButtonItem alloc]
                       initWithTitle:@"Options" 
                       style: UIBarButtonItemStylePlain
                       target: self 
                       action: @selector(showoptions)];
		//self.navigationItem.rightBarButtonItem = rightbutton;
             
        //Create popovers and controllers
		newPO = [[TPNewPO alloc] initWithViewDelegate:viewDelegate parent:self];
		newPOC = [[UIPopoverController alloc] initWithContentViewController:newPO];
        [newPOC setPopoverContentSize:CGSizeMake(500, 640)];
        
        // Create view control button (segmented)
        viewControl = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"Forms", @"Info", @"Reports", nil]];
        viewControl.segmentedControlStyle = UISegmentedControlStyleBar;
        viewControl.frame = CGRectMake(10, 10, 280, 30);
		viewControl.selectedSegmentIndex = 0;
        [viewControl addTarget:self action:@selector(switchView) forControlEvents:UIControlEventValueChanged];
        
        //self.navigationItem.titleView = viewControl; //jxi; modified
        
        //jxi; Create a label for title
        CGRect frame = CGRectMake(0, 0, 400, 44);
        titleLabel = [[UILabel alloc] initWithFrame:frame];
        titleLabel.backgroundColor = [UIColor clearColor];
        titleLabel.font = [UIFont boldSystemFontOfSize:12.0];
        titleLabel.textAlignment = UITextAlignmentCenter;
        titleLabel.textColor = [UIColor blackColor];
        self.navigationItem.titleView = titleLabel;
        
        [self resetPrompt];
    }
    return self;
}

// --------------------------------------------------------------------------------------
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.preview_userdataid = nil;
    [leftNewButton release];
    [rightbutton release];
    [titleLabel release]; //jxi;
    [self release];
    [super dealloc];
}

// --------------------------------------------------------------------------------------
- (void)loadView {
    if (debugRubricList) NSLog(@"TPRubricList loadView");
    [super loadView];
}

// --------------------------------------------------------------------------------------
- (void)viewDidLoad {
    if (debugRubricList) NSLog(@"TPRubricList viewDidLoad");
    // Add observer to the notification center to dismiss model camera view 
    // when application goes to the background
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(goToBackground) name:UIApplicationWillResignActiveNotification object:nil];
}

// --------------------------------------------------------------------------------------
- (void)viewWillAppear:(BOOL)animated {
    if (debugRubricList) NSLog(@"TPRubricList viewWillAppear");
    [self resetPrompt];
}

// --------------------------------------------------------------------------------------
- (void)viewDidAppear:(BOOL)animated {
    if (debugRubricList) NSLog(@"TPRubricList viewDidAppear");
    viewDelegate.model.currentMainViewState = @"rubriclist";
}

// --------------------------------------------------------------------------------------
- (void)viewDidUnload {
    if (debugRubricList) NSLog(@"TPRubricList viewDidUnload");
    [super viewDidUnload];
}

// --------------------------------------------------------------------------------------
- (void)didReceiveMemoryWarning {
    if (debugRubricList) NSLog(@"TPRubricList didReceiveMemoryWarning");
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

// --------------------------------------------------------------------------------------
- (void)goToBackground {
    [self dismissViewControllerAnimated:NO completion:nil]; // No need to animate
}

// --------------------------------------------------------------------------------------

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration {
    if (debugRotate) NSLog(@"TPRubricList willRotateToInterfaceOrientation");
}

- (void)viewWillLayoutSubviews {
    if (debugRotate) NSLog(@"TPRubricList viewWillLayoutSubviews");
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration {
    if (debugRotate) NSLog(@"TPRubricList willAnimateRotationToInterfaceOrientation");
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    if (debugRotate) NSLog(@"TPRubricList didRotateFromInterfaceOrientation");
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    if (debugRotate) NSLog(@"TPRubricList shouldAutorotateToInterfaceOrientation");
    return YES;
}

// --------------------------------------------------------------------------------------
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

// --------------------------------------------------------------------------------------
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (debugRubricList) NSLog(@"TPRubricList numberOfRowsInSection %d", [viewDelegate.model.userdata_list count]);
	//return [viewDelegate.model.userdata_list count];
    return [formDataArrays count]; //jxi
}

// --------------------------------------------------------------------------------------
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (debugRubricList) NSLog(@"TPRubricList cellForRowAtIndexPath %d %d", [indexPath row], [viewDelegate.model.userdata_list count]);
    
	//TPUserData *userdata = [viewDelegate.model.userdata_list objectAtIndex:[indexPath row]];
    TPUserData *userdata = [formDataArrays objectAtIndex:[indexPath row]]; //jxi
    
    NSString *CellIdentifier = [NSString stringWithFormat:@"%d/%@", viewDelegate.model.appstate.user_id, userdata.userdata_id];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: CellIdentifier];
	
    if (cell == nil) {
        cell = [[[TPRubricListCell alloc] initWithView:viewDelegate
                                                 style:UITableViewCellStyleDefault
                                       reuseIdentifier:CellIdentifier
                                              userdata:userdata] autorelease];
    } else {
        [(TPRubricListCell*)cell updateContent];
        [(TPRubricListCell*)cell updateStatus];
        [(TPRubricListCell*)cell updateCellGeometryForInterfaceOrientation:[[UIDevice currentDevice] orientation]];
    }
    
    return cell;
}

// --------------------------------------------------------------------------------------
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    //TPUserData *userdata = [viewDelegate.model.userdata_list objectAtIndex:[indexPath row]];
    TPUserData *userdata = [formDataArrays objectAtIndex:[indexPath row]]; //jxi
    
    return [TPRubricListCell cellHeightForCellWithUserdata:userdata mainView:viewDelegate];
}

// --------------------------------------------------------------------------------------
- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (debugRubricList) NSLog(@"TPRubricList didSelectRowAtIndexPath %d", [indexPath row]);
    
    if ([viewDelegate.model tryLock:viewDelegate.model.uiSyncLock]) {
        
        
        TPRubricListCell *selectedCell = (TPRubricListCell *)[tableView cellForRowAtIndexPath:indexPath];
        
        if ([selectedCell getContentType] == TP_USERDATA_TYPE_IMAGE) {
            
            // Set current preview userdata_id
            self.preview_userdataid = [selectedCell getUserdataID];
            
            // Get image
            TPImage *selectedImage = [viewDelegate.model getImageFromListById:preview_userdataid type:TP_IMAGE_TYPE_FULL];
            
            //TPUserData *userdata = [viewDelegate.model.userdata_list objectAtIndex:[indexPath row]];
            TPUserData *userdata = [formDataArrays objectAtIndex:[indexPath row]]; //jxi
            [viewDelegate.model setUserData:userdata];
            
            // If no image in memory then sync
            if (selectedImage == nil) {
                if ([viewDelegate.model syncIsSupended]) {
                    // If syncing is suspended (currently executing another sync) then no action
                    [tableView deselectRowAtIndexPath:indexPath animated:NO];
                    return;
                } else {
                    // Otherwise sync image
                    viewDelegate.model.remoteImageIDToSync = userdata.userdata_id;
                    [viewDelegate syncNow:SYNC_TYPE_IMAGEDATA];
                }
            }
            // Display image
            [self showImagePreview:preview_userdataid];
            
        } else if([selectedCell getContentType] == TP_USERDATA_TYPE_VIDEO)
        {
            // Set current preview userdata_id
            self.preview_userdataid = [selectedCell getUserdataID];
            
            // Get video
            TPVideo *selectedVideo = [viewDelegate.model getVideoFromListById:preview_userdataid];
            
            //TPUserData *userdata = [viewDelegate.model.userdata_list objectAtIndex:[indexPath row]];
            TPUserData *userdata = [formDataArrays objectAtIndex:[indexPath row]]; //jxi
            [viewDelegate.model setUserData:userdata];
            
            // If no video in memory then sync
            if (selectedVideo == nil) {
                if ([viewDelegate.model syncIsSupended]) {
                    // If syncing is suspended (currently executing another sync) then no action
                    [tableView deselectRowAtIndexPath:indexPath animated:NO];
                    return;
                } else {
                    // Otherwise sync image
                    viewDelegate.model.remoteVideoIDToSync = userdata.userdata_id;
                    [viewDelegate syncNow:SYNC_TYPE_VIDEODATA];
                }
            }
            // Display video
            [self showVideoPreview:preview_userdataid];
        } else if ([(TPRubricListCell *)[tableView cellForRowAtIndexPath:indexPath] getContentType] == TP_USERDATA_TYPE_FORM) {
            if (debugRubricList) NSLog(@"TPRubricList didSelectRowAtIndexPath form");
            //TPUserData *userdata = [viewDelegate.model.userdata_list objectAtIndex:[indexPath row]];
            TPUserData *userdata = [formDataArrays objectAtIndex:[indexPath row]]; //jxi
            
            //jxi; If the selected userdata has nodata state, then start on-demand syncing for the formdata
            if (userdata.state == TP_USERDATA_NODATA_STATE) {
                if ([viewDelegate.model syncIsSupended]) {
                    // If syncing is suspended (currently executing another sync) then no action
                    [tableView deselectRowAtIndexPath:indexPath animated:NO];
                    return;
                } else {
                    // Otherwise sync form data
                    viewDelegate.model.remoteFormIDToSync = userdata.userdata_id;
                    [viewDelegate syncNow:SYNC_TYPE_FORMDATA];
                }
            }
            
            [viewDelegate setUserData:userdata];
        }
        
        [viewDelegate.model freeLock:viewDelegate.model.uiSyncLock];
        
    } else {
        // Otherwise UI locked, so deselect row and ignore
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
    }
}

// --------------------------------------------------------------------------------------
- (void) scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (debugRubricList) NSLog(@"TPRubricList scrollViewWillBeginDragging");
}

// --------------------------------------------------------------------------------------
- (void) scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (debugRubricList) NSLog(@"TPRubricList scrollViewDidEndDecelerating");
}

// --------------------------------------------------------------------------------------
- (void) reset {
    
    if (debugRubricList) NSLog(@"TPRubricList reset");
    
    // Reset the user name and district
    [self resetPrompt];

    TPUser *subject = [viewDelegate.model getCurrentTarget];
    if (subject.permission == TP_PERMISSION_VIEW_AND_RECORD ||
        subject.permission == TP_PERMISSION_RECORD) {
        self.navigationItem.leftBarButtonItem = leftNewButton;
    } else {
        self.navigationItem.leftBarButtonItem = nil;
        self.navigationItem.hidesBackButton = YES;
    }
}

//jxi------------------------------------------------------------------------------------------------
- (void) resetFormDataArray {
    
    if (debugRubricList) NSLog(@"TPRubricList resetFormDataArray");
    
    // Empty existing arrays
    [formDataArrays removeAllObjects];
    
    // Get the non-form data list
    NSMutableArray *userdataList = [NSMutableArray arrayWithArray:viewDelegate.model.userdata_list];
    // Loop over userdata list and a list of non-form data to be attached
    for (int i = 0; i < [userdataList count]; i++) {
        
        TPUserData *userdata = [userdataList objectAtIndex:i];
        
        // type: 1=form, 2=audio, 3=image, 4=video, 5=document
        if (userdata.type == 1 || ( ([userdata.aud_id isEqual:@""] || [userdata.aud_id isEqual:@"(null)"]) && userdata.aq_id < 1)) {
            [formDataArrays addObject:userdata];
        }
    }
}

// --------------------------------------------------------------------------------------
- (void) switchView {
	[viewDelegate switchView:viewControl.selectedSegmentIndex];
}

// --------------------------------------------------------------------------------------
- (void) setSelectedView:(int)index {
    viewControl.selectedSegmentIndex = index;
}

// --------------------------------------------------------------------------------------
- (void)resetPrompt {
    //self.navigationItem.prompt = [viewDelegate.model getDetailViewPromptString];
    
    //jxi;
    titleLabel.text = [viewDelegate.model getDetailViewPromptString];
}

// --------------------------------------------------------------------------------------
- (void) shownew {
    if (debugRubricList) NSLog(@"TPRubricList shownew");
    [viewDelegate hideoptions];
	if ([newPOC isPopoverVisible]) {
		[newPOC dismissPopoverAnimated:YES];
	} else {
		[newPO reset];
		[newPOC presentPopoverFromBarButtonItem:leftNewButton
					   permittedArrowDirections:UIPopoverArrowDirectionAny
									   animated:YES];
	}
}

// --------------------------------------------------------------------------------------
- (void) hidenew {
    if (debugRubricList) NSLog(@"TPRubricList hidenew");
    [newPOC dismissPopoverAnimated:YES];
    if (previewVC != nil) {
        [previewVC doneAction];
    }
}

// --------------------------------------------------------------------------------------
- (void) showoptions {
    if (debugRubricList) NSLog(@"TPRubricList showoptions");
    [self hidenew];
	[viewDelegate popOptionsPO];
	if ([viewDelegate.optionsPOC isPopoverVisible]) {
		[viewDelegate.optionsPOC  dismissPopoverAnimated:YES];
	} else {
		[viewDelegate.optionsPOC
		 presentPopoverFromBarButtonItem:self.navigationItem.rightBarButtonItem
		 permittedArrowDirections:UIPopoverArrowDirectionAny
		 animated:YES];
	}
}

// --------------------------------------------------------------------------------------
- (void) showImageCaptureView {
    if (debugRubricList) NSLog(@"TPRubricList showImageCaptureView");
    [viewDelegate cameraBeginCapture];
}

// --------------------------------------------------------------------------------------
- (void) showImagePreview:(NSString *)userdata_id {
    if (debugRubricList) NSLog(@"TPRubricList showImagePreview");
    
    viewDelegate.preview_container_state = TP_PREVIEW_FOR_RUBRICLIST; //jxi;
    
    [viewDelegate hideoptions];
    TPUserData *userdata = [viewDelegate.model getUserDataFromListById:userdata_id];
    TPImage *image = [viewDelegate.model getImageFromListById:userdata_id type:TP_IMAGE_TYPE_FULL];
    
    previewVC = [[TPPreviewVC alloc]
                              initWithViewDelegate:viewDelegate
                              userdata:userdata
                              image:image ? image.image : nil
                              name:userdata.name
                              share:userdata.share
                              description:userdata.description
                              userdataID:userdata_id
                              imageOrigin:TP_IMAGE_ORIGIN_REMOTE
                              newImage:NO];
    [previewVC setPreviewDelegate:self];
    [self setImagePreviewVC:previewVC];
    [self presentViewController:previewVC animated:YES completion:nil];
    //[previewVC release];
}

//jxi;
// --------------------------------------------------------------------------------------
- (void)showVideoPreview:(NSString *)userdata_id {
    if (debugRubricList) NSLog(@"TPRurbricList doShowVideoPreview");
    
    viewDelegate.preview_container_state = TP_PREVIEW_FOR_RUBRICLIST; //jxi;
    
    TPVideo *video = [viewDelegate.model getVideoFromListById:userdata_id];
    UIImage *newImage; NSURL *fileURL;
    
    if( video )
    {
        
        fileURL = [NSURL fileURLWithPath:video.filename];
        
        MPMoviePlayerController *player = [[MPMoviePlayerController alloc] initWithContentURL:fileURL];
        
        newImage = [player thumbnailImageAtTime:1.0 timeOption:MPMovieTimeOptionNearestKeyFrame];
        //Player autoplays audio on init
        [player stop];
        [player release];
    }
    else{
        newImage = nil;
        fileURL = nil;
    }
    TPUserData *imageUserdata = [viewDelegate.model getUserDataFromListById:video.userdata_id];
    videoVC = [[TPVideoPreviewVC alloc]
               initWithViewDelegate:viewDelegate
               userdata:imageUserdata
               image:newImage
               name:imageUserdata.name
               share:imageUserdata.share
               description:imageUserdata.description
               userdataID:userdata_id
               imageOrigin:0
               newImage:YES
               videoURL:fileURL
               modified:video.modified
               ];
    [videoVC setPreviewDelegate :self];
    [self setVideoPreviewVC:(id)videoVC]; //jxi;id
    [self presentViewController:videoVC animated:YES completion:nil];
}

// --------------------------------------------------------------------------------------
- (void) resetPreview {
    if (debugRubricList) NSLog(@"TPRubricList resetPreview");
    if (self.presentedViewController) {
        TPUserData *userdata = [viewDelegate.model getUserDataFromListById:preview_userdataid];
        TPImage *image = [viewDelegate.model getImageFromListById:userdata.userdata_id type:TP_IMAGE_TYPE_FULL];
        [self.imagePreviewVC reloadImage:image.image name:userdata.name share:userdata.share description:userdata.description];
    }
}

//jxi;
// --------------------------------------------------------------------------------------
- (void) resetVideoPreview {
    if (debugRubricList) NSLog(@"TPRurbricList resetVideoPreview");
    if (self.presentedViewController) {
        TPUserData *userdata = [viewDelegate.model getUserDataFromListById:preview_userdataid];
        TPVideo *video = [viewDelegate.model getVideoFromListById:userdata.userdata_id];
        
        NSURL *fileURL = [NSURL fileURLWithPath:video.filename];
        
        [self.videoPreviewVC reloadVideo:fileURL name:userdata.name share:userdata.share description:userdata.description];
    }
}

// ============================ TPPreviewDelegate methods ===============================

// --------------------------------------------------------------------------------------
// donePreviewWithDeviceOrientation - call after quiting preview screen using done button
// --------------------------------------------------------------------------------------
- (void) donePreviewWithDeviceOrientation:(UIDeviceOrientation)orientation {
    if (debugRubricList) NSLog(@"TPRubricList donePreviewWithDeviceOrientation");
    self.imagePreviewVC = nil;
    [previewVC release];
    previewVC = nil;
    [self dismissViewControllerAnimated:YES completion:nil];
    [viewDelegate reloadUserdataList];
}

// --------------------------------------------------------------------------------------
- (void) savePreviewWithDeviceOrientation:(UIDeviceOrientation)orientation
                                imageName:(NSString *)aName
                                    share:(int)aShare
                              description:(NSString *)aDescription
                                  dismiss:(BOOL)dismiss {
    
    if (debugRubricList) NSLog(@"TPRubricList savePreviewWithDeviceOrientation");
    
    // update userdata
    TPUserData *newUserdata = [[TPUserData alloc] initWithUserData:[viewDelegate.model getUserDataFromListById:preview_userdataid]];
    
    // Get existing userdata
    TPUserData *userdata = [viewDelegate.model getUserDataFromListById:newUserdata.userdata_id];
    
    // If info has changed then save
    if (![userdata.name isEqualToString:aName] ||
        userdata.share != aShare ||
        ![userdata.description isEqualToString:aDescription]) {

        newUserdata.name = aName;
        newUserdata.description = aDescription;
        newUserdata.share = aShare;
        [viewDelegate.model setStateToSync:newUserdata];
        [viewDelegate.model updateUserData:newUserdata setModified:YES];
        
        [viewDelegate reloadUserdataList];
        [viewDelegate.model setNeedSyncStatus:NEEDSYNC_STATUS_NOTSYNCED forced:YES];
        [viewDelegate setSyncStatus];
    }
    [newUserdata release];
    
    // Dismiss if requested
    if (dismiss) {
        self.imagePreviewVC = nil;
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

// --------------------------------------------------------------------------------------
- (void) trashPreviewWithDeviceOrientation:(UIDeviceOrientation)orientation {
    if (debugRubricList) NSLog(@"TPRubricList trashPreviewWithDeviceOrientation");
    [viewDelegate.model.database deleteUserData:preview_userdataid includingImages:YES];
    [viewDelegate reloadUserdataList];
    self.imagePreviewVC = nil;
    [previewVC release];
    previewVC = nil;
    [self dismissViewControllerAnimated:YES completion:nil];
}


// ============================= TPVideoPreviewDelegate ======================================

// --------------------------------------------------------------------------------------
- (void)trashVideoPreviewWithDeviceOrientation:(UIDeviceOrientation) orientation {
    
    if (debugRubricList) NSLog(@"TPRubricList trashPreviewWithDeviceOrientation");
    [viewDelegate.model.database deleteUserData:preview_userdataid includingImages:YES];
    [viewDelegate reloadUserdataList];
    self.videoPreviewVC = nil;
    [videoVC release];
    videoVC = nil;
    [self dismissViewControllerAnimated:YES completion:nil];
}

// --------------------------------------------------------------------------------------
- (void)doneVideoPreviewWithDeviceOrientation:(UIDeviceOrientation)orientation {
    
    if (debugRubricList) NSLog(@"TPRubricList donePreviewWithDeviceOrientation");
    self.videoPreviewVC = nil;
    [videoVC release];
    videoVC = nil;
    [self dismissViewControllerAnimated:YES completion:nil];
    [viewDelegate reloadUserdataList];
}

// --------------------------------------------------------------------------------------
- (void)saveVideoPreviewWithDeviceOrientation:(UIDeviceOrientation) orientation
                                    imageName:(NSString *)aName
                                        share:(int)aShare
                                  description:(NSString *)aDescription
                                      dismiss:(BOOL)dismiss {
    
    if (debugRubricList) NSLog(@"TPRubricList savePreviewWithDeviceOrientation");
    
    // update userdata
    TPUserData *newUserdata = [[TPUserData alloc] initWithUserData:[viewDelegate.model getUserDataFromListById:preview_userdataid]];
    
    // Get existing userdata
    TPUserData *userdata = [viewDelegate.model getUserDataFromListById:newUserdata.userdata_id];
    
    // If info has changed then save
    if (![userdata.name isEqualToString:aName] ||
        userdata.share != aShare ||
        ![userdata.description isEqualToString:aDescription]) {
        
        newUserdata.name = aName;
        newUserdata.description = aDescription;
        newUserdata.share = aShare;
        [viewDelegate.model setStateToSync:newUserdata];
        [viewDelegate.model updateUserData:newUserdata setModified:YES];
        
        [viewDelegate reloadUserdataList];
        [viewDelegate.model setNeedSyncStatus:NEEDSYNC_STATUS_NOTSYNCED forced:YES];
        [viewDelegate setSyncStatus];
    }
    [newUserdata release];
    
    // Dismiss if requested
    if (dismiss) {
        self.videoPreviewVC = nil;
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    
}

@end


// --------------------------------------------------------------------------------------
// TPRubricListCell - return content of rubric cell for rubric
// --------------------------------------------------------------------------------------
@implementation TPRubricListCell

@synthesize userdata_id;

// --------------------------------------------------------------------------------------
- (id) initWithView:(TPView *)mainview
              style:(UITableViewCellStyle)style
    reuseIdentifier:(NSString *)reuseIdentifier
           userdata:(TPUserData *)userdata {
    
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self != nil) {
        
        viewDelegate = mainview;
        self.userdata_id = userdata.userdata_id;
        contentType = userdata.type;
        
        // Set cell properties
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        self.contentView.frame = CGRectMake(0, 0, 700, 40);
        
        // Create title
        title = [[UILabel alloc] initWithFrame:CGRectMake(5, 0, 460, 25)];
        title.text = userdata.name;
		title.backgroundColor = [UIColor clearColor];
        title.font = [UIFont fontWithName:@"Helvetica" size:17.0];
		title.textAlignment = TPTextAlignmentLeft;
        [title setAutoresizingMask:UIViewAutoresizingFlexibleRightMargin];
        [self.contentView addSubview:title];
        
        // Create status
        status = [[UILabel alloc] initWithFrame:CGRectMake(15, 25, 400, 15)];
        status.textColor = [UIColor grayColor];
        status.backgroundColor = [UIColor clearColor];
        status.font = [UIFont fontWithName:@"Helvetica-Oblique" size:14.0];
        status.textAlignment = TPTextAlignmentLeft;
        //if (userdata.user_id != viewDelegate.model.appstate.user_id) {
         status.text = [NSString stringWithFormat:@"by: %@", [viewDelegate.model getUserName:userdata.user_id]];
        [self.contentView addSubview:status];
        
        // description label for attachment cell
        description = nil;
        
        // DISABLE DESCRIPTION
        /*
        if (userdata.type == TP_USERDATA_TYPE_ATTACHMENT) {
            int descriptionwidth;
            if ([TPUtil isPortraitOrientation]) {
                descriptionwidth = TP_ATTACH_STATUS_WIDTH_PORTRAIT;
            } else {
                descriptionwidth = TP_ATTACH_STATUS_WIDTH_LANDSCAPE;
            }
            CGSize constSize = CGSizeMake(descriptionwidth, 1000);
            CGSize descriptionSize = [userdata.description sizeWithFont:[UIFont fontWithName:@"Helvetica-Oblique" size:14.0]
                                                      constrainedToSize:constSize
                                                          lineBreakMode:UILineBreakModeWordWrap];
            description = [[UILabel alloc] initWithFrame:CGRectMake(status.frame.origin.x + 10, 
                                                               status.frame.origin.y + status.frame.size.height, 
                                                               descriptionwidth, 
                                                               descriptionSize.height)];
            description.textColor = [UIColor grayColor];
            description.numberOfLines = 0;
            description.font = [UIFont fontWithName:@"Helvetica-Oblique" size:14.0];
            description.textAlignment = UITextAlignmentLeft;
            description.text = userdata.description;
            [self.contentView addSubview:description];
            
        }
        */
        
        // Place tag on cell to indicate this is a document
        itemtag = nil;
        if (userdata.type == TP_USERDATA_TYPE_ATTACHMENT) {
            itemtag = [[UILabel alloc] initWithFrame:CGRectMake(415, 25, 100, 15)];
            itemtag.text = @"DOCUMENT";
            itemtag.textColor = [UIColor darkGrayColor];
            itemtag.backgroundColor = [UIColor clearColor];
            itemtag.font = [UIFont fontWithName:@"Helvetica-Oblique" size:14.0];
            itemtag.textAlignment = TPTextAlignmentLeft;
            [itemtag setAutoresizingMask:UIViewAutoresizingFlexibleRightMargin];
            [self.contentView addSubview:itemtag];
        }
        
        // Create date
        int cell_height = [TPRubricListCell cellHeightForCellWithUserdata:userdata mainView:mainview];
        date = [[UILabel alloc] initWithFrame:CGRectMake(590, cell_height/2 - 20, 100, 40)];
        date.text = [viewDelegate.model prettyStringFromDate:userdata.created newline:TRUE];
        date.textColor = [UIColor darkGrayColor];
		date.backgroundColor = [UIColor clearColor];
        date.lineBreakMode = TPLineBreakByWordWrapping;
        date.numberOfLines = 2;
		date.font = [UIFont fontWithName:@"Helvetica-Bold" size:14.0];
		date.textAlignment = TPTextAlignmentRight;
        [date setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin];
        [self.contentView addSubview:date];
        
        if (userdata.type == TP_USERDATA_TYPE_FORM) { // rubric cell
            // shared, reflection and signature images
            shared = [[UIImageView alloc] initWithFrame:CGRectMake(470, 8, 24, 24)];
            [shared setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin];
            reflection = [[UIImageView alloc] initWithFrame:CGRectMake(500, 8, 24, 24)];
            [reflection setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin];
            signature = [[UIImageView alloc] initWithFrame:CGRectMake(530, 8, 48, 24)];
            [signature setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin];
            [self updateStatus];
            [self.contentView addSubview:shared];
            [self.contentView addSubview:reflection];
            [self.contentView addSubview:signature];
            thumbnail = nil;
            
        } else if (userdata.type == TP_USERDATA_TYPE_IMAGE) { // image cell
            // shared icon
            //shared = [[UIImageView alloc] initWithFrame:CGRectMake(550, cell_height/2 - 12, 24, 24)];
            shared = [[UIImageView alloc] initWithFrame:CGRectMake(470, cell_height/2 - 12, 24, 24)];
            [shared setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin];
            [self updateStatus];
            [self.contentView addSubview:shared];
            
            // Add thumbnail
            thumbnail = [[UIImageView alloc] init];
            TPImage *thumb = [viewDelegate.model getImageFromListById:userdata_id type:TP_IMAGE_TYPE_THUMBNAIL];
            [self updateThumbnailWithImage:thumb];
            //[thumbnail setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin];
            
            // Adjust frame to center image in 107x80 area
            /*
            CGRect newFrame = thumbnail.frame;
            newFrame.size.width = thumbnail.image.size.width;
            newFrame.size.height = thumbnail.image.size.height;
            newFrame.origin.x = TP_THUMBNAIL_LEFT_MARGIN;
            newFrame.origin.y = TP_THUMBNAIL_BOTTOM_MARGIN;
            if ([TPUtil isPortraitOrientation]) newFrame.origin.x += 70;
            if (newFrame.size.height < 80) newFrame.origin.y += (80 - newFrame.size.height) / 2;
            if (newFrame.size.width < 107) newFrame.origin.x += (107 - newFrame.size.width) / 2;
            newFrame.origin.x = 405;
            [thumbnail setFrame:newFrame];
             */
            
            //jxi;
            thumbnail.frame = CGRectMake(530, cell_height/2 - 12, 24, 24);
            [thumbnail setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin];
            [self.contentView addSubview:thumbnail];
            
        } else if (contentType == TP_USERDATA_TYPE_ATTACHMENT) { // document cell
            // shared icon
            shared = [[UIImageView alloc] initWithFrame:CGRectMake(550, cell_height/2 - 12, 24, 24)];
            [shared setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin];
            [self updateStatus];
            [self.contentView addSubview:shared];
            // cell can not be selected
            self.accessoryType = UITableViewCellAccessoryNone;
            [self setSelectionStyle:UITableViewCellSelectionStyleNone];
            [self setUserInteractionEnabled:NO];
            thumbnail = nil;
        } else if (userdata.type == TP_USERDATA_TYPE_VIDEO) { //jxi; video cell
            // shared icon
            shared = [[UIImageView alloc] initWithFrame:CGRectMake(470, cell_height/2 - 12, 24, 24)];
            [shared setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin];
            [self updateStatus];
            [self.contentView addSubview:shared];
            
            // Add thumbnail
            /*
            thumbnail = [[UIImageView alloc] init];
            if (userdata.state == TP_USERDATA_SYNCED_PARTIAL_STATE ||
                userdata.state == TP_USERDATA_SYNCED_COMPLETE_STATE) {
                
                thumbnail.image = [UIImage imageNamed:@"icon_video.png"];
                
            } else {
                
                thumbnail.image = [UIImage imageNamed:@"icon_video_gray.png"];
            } */
            thumbnail = [[UIImageView alloc] init];
            TPVideo *thumb = [viewDelegate.model getVideoFromListById:userdata_id];
            [self updateThumbnailWithVideo:thumb];
            
            thumbnail.frame = CGRectMake(530, cell_height/2 - 12, 24, 24);
            [thumbnail setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin];
            [self.contentView addSubview:thumbnail];
        }
    }
    return self;
}

// --------------------------------------------------------------------------------------
- (void) dealloc {
    self.userdata_id = nil;
    [title release];
    [status release];
    [itemtag release];
    [description release];
    [date release];
    [shared release];
    [reflection release];
    [signature release];
    [thumbnail release];
    [super dealloc];
}

// --------------------------------------------------------------------------------------
- (void) updateCellGeometryForInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    
    TPUserData *userdata = [viewDelegate.model getUserDataFromListById:userdata_id];
    
    // DISABLE DESCRIPTION DISPLAY
    /*
    if (contentType == TP_USERDATA_TYPE_ATTACHMENT) {
        int descriptionwidth;
        if (UIInterfaceOrientationIsLandscape(interfaceOrientation)) {
            descriptionwidth = TP_ATTACH_STATUS_WIDTH_LANDSCAPE;
        } else {
            descriptionwidth = TP_ATTACH_STATUS_WIDTH_PORTRAIT;
        }

        CGSize constSize = CGSizeMake(descriptionwidth, 1000);
        CGSize descriptionSize = [userdata.description sizeWithFont:[UIFont fontWithName:@"Helvetica-Oblique" size:14.0]
                                                            constrainedToSize:constSize
                                                                lineBreakMode:UILineBreakModeWordWrap];
        CGRect frame = description.frame;
        frame.size.width = descriptionwidth;
        frame.size.height = descriptionSize.height;
        description.frame = frame;
    }
    */
    
    if (contentType == TP_USERDATA_TYPE_IMAGE) {
        int cell_height = [TPRubricListCell cellHeightForCellWithUserdata:userdata mainView:viewDelegate];
        CGRect oldDateFrame = date.frame;
        [date setFrame:CGRectMake(oldDateFrame.origin.x, cell_height/2 - 20, oldDateFrame.size.width, oldDateFrame.size.height)];
        CGRect oldSharedFrame = shared.frame;
        [shared setFrame:CGRectMake(oldSharedFrame.origin.x, cell_height/2 - 12, oldSharedFrame.size.width, oldSharedFrame.size.height)];
    }
    if (contentType == TP_USERDATA_TYPE_VIDEO) {
        int cell_height = [TPRubricListCell cellHeightForCellWithUserdata:userdata mainView:viewDelegate];
        CGRect oldDateFrame = date.frame;
        [date setFrame:CGRectMake(oldDateFrame.origin.x, cell_height/2 - 20, oldDateFrame.size.width, oldDateFrame.size.height)];
        CGRect oldSharedFrame = shared.frame;
        [shared setFrame:CGRectMake(oldSharedFrame.origin.x, cell_height/2 - 12, oldSharedFrame.size.width, oldSharedFrame.size.height)];
    }
}

// --------------------------------------------------------------------------------------
- (void) updateStatus {
    
    if (debugRubricList) NSLog(@"TPRubricListCell updateStatus");
    
    TPUserData *userdata = [viewDelegate.model getUserDataFromListById:userdata_id];
    
    NSMutableArray *questionListForCurrentRubrics = [[NSMutableArray alloc] init];
	[viewDelegate.model getQuestionListByRubricId:questionListForCurrentRubrics rubricId:userdata.rubric_id];
    
    BOOL isSigned = FALSE;
    BOOL isSignedReflection = FALSE;
    BOOL isSignedThirdParty = FALSE;
    
    BOOL hasReflectionData = FALSE;
    
	for (TPQuestion *question in questionListForCurrentRubrics) {
        NSString *questionText = @"";
        
        for (TPRubricData *data in userdata.rubricdata) {
            if (question.question_id == data.question_id) {
                questionText = [data text];
            }
        }
        
        BOOL isAnswered = [questionText length] && ![questionText isEqualToString:@"(null)"];
        
        if ((TP_QUESTION_TYPE_SIGNATURE_RESTRICTED == question.type) && (TP_QUESTION_SUBTYPE_THIRDPARTY == question.subtype)) {
			isSignedThirdParty = isAnswered;
		} else {
            if (question.type == TP_QUESTION_TYPE_SIGNATURE_RESTRICTED) {
                if ([question isQuestionReflection]) {
                    isSignedReflection = isAnswered;
                } else {
                    isSigned = isAnswered;
                }
            } else {
                if ([question isQuestionReflection] && !hasReflectionData && isAnswered) {
                    hasReflectionData = TRUE;
                }
            }
        }
	}
    [questionListForCurrentRubrics release];
    
    // share icon
    if (userdata.share == 1) {
        shared.image = [UIImage imageNamed:@"icon_share.png"];
    } else {
        shared.image = NULL;
    }
    
    // reflection icon
    if (hasReflectionData) {
        reflection.image = [UIImage imageNamed:@"icon_reflection.png"];
    } else {
        reflection.image = NULL;
    }
    
    // signature icon
    if (isSigned || isSignedReflection || isSignedThirdParty) {
        signature.image = [UIImage imageNamed:[NSString stringWithFormat:@"icon_signature_%@%@%@.png",
                                               (isSigned?@"1":@""),
                                               (isSignedReflection?@"2":@""),
                                               (isSignedThirdParty?@"3":@"")]];
    } else {
        signature.image = NULL;
    }
    
}

// --------------------------------------------------------------------------------------
- (void) updateContent {
    if (debugRubricList) NSLog(@"TPRubricListCell updateContent");
    TPUserData *userdata = [viewDelegate.model getUserDataFromListById:userdata_id];
    if (userdata.type == TP_USERDATA_TYPE_IMAGE) {
        TPImage *thumb = [viewDelegate.model getImageFromListById:userdata_id type:TP_IMAGE_TYPE_THUMBNAIL];
        [self updateThumbnailWithImage:thumb];
        title.text = userdata.name;
    }
    
    if (userdata.type == TP_USERDATA_TYPE_VIDEO) {
        TPVideo *video = [viewDelegate.model getVideoFromListById:userdata_id];
        if( video )
        {
            [self updateThumbnailWithVideo:video];
        }
        
        title.text = userdata.name;
    }
}

// --------------------------------------------------------------------------------------
// jxi;
// --------------------------------------------------------------------------------------
- (void) updateThumbnailWithImage:(TPImage *)thumb {
    
    if (debugRubricList) NSLog(@"TPRubricListCell updateThumbnailWithImage");
    
    // Add image if available otherwise use icon
    if (thumb && thumb.image) {
        //thumbnail.image = thumb.image;
        thumbnail.image = [UIImage imageNamed:@"icon_picture.png"]; //jxi;
    } else {
        //thumbnail.image = [UIImage imageNamed:@"icon_image.png"];
        thumbnail.image = [UIImage imageNamed:@"icon_picture_gray.png"]; //jxi;
    }
    
    /*
    
    // Adjust frame to center image in 107x80 area //Deprecated; //jxi;
    // Icon Image Size changed into 24x24 //jxi;
    CGRect newFrame = thumbnail.frame;
    newFrame.size.width = thumbnail.image.size.width;
    newFrame.size.height = thumbnail.image.size.height;
    newFrame.origin.x = TP_THUMBNAIL_LEFT_MARGIN;
    newFrame.origin.y = TP_THUMBNAIL_BOTTOM_MARGIN;
    if ([TPUtil isPortraitOrientation]) newFrame.origin.x += 70;
//    if (newFrame.size.height < 80) newFrame.origin.y += (80 - newFrame.size.height) / 2;
//    if (newFrame.size.width < 107) newFrame.origin.x += (107 - newFrame.size.width) / 2;
    if (newFrame.size.height < 24) newFrame.origin.y += (24 - newFrame.size.height) / 2; //jxi;
    if (newFrame.size.width < 24) newFrame.origin.x += (24 - newFrame.size.width) / 2; //jxi;
    //newFrame.origin.x = 405;
    newFrame.origin.x = 530; //jxi;
    [thumbnail setFrame:newFrame];
     */
}

// --------------------------------------------------------------------------------------
// jxi;
// --------------------------------------------------------------------------------------
- (UIImage *)createThumbnailImage:(UIImage*)origin {
    
    if (debugRubricList) NSLog(@"TPRubricListCell createThumbnailImage");
    
    UIImage *thumb = nil;
    int thumbnail_width;
    int thumbnail_height;
    if (origin.size.width / origin.size.height >= 107.0 / 80.0) {
        thumbnail_width = 107;
        thumbnail_height = origin.size.height * (107 / origin.size.width);
    } else {
        thumbnail_height = 80;
        thumbnail_width = origin.size.width * (80 / origin.size.height);
    }
    if (debugData) NSLog(@"TPImage createThumbnailImage %d %d to %d %d", (int)(origin.size.width), (int)(origin.size.height), thumbnail_width, thumbnail_height);
    if (origin) {
        thumb = [TPUtil thumbnailFromImage:origin scaledToSize:CGSizeMake(thumbnail_width, thumbnail_height)];
    }
    return thumb;
}

// --------------------------------------------------------------------------------------
// jxi;
// --------------------------------------------------------------------------------------
- (void) updateThumbnailWithVideo:(TPVideo *)thumb {
    
    if (debugRubricList) NSLog(@"TPRubricListCell updateThumbnailWithVideo");
    
    /*
    if( thumb.filename )
    {
        if (thumb) {
            thumbnail.image = [self createThumbnailImage:[thumb thumbnailImage]];
        } else {
            thumbnail.image = [UIImage imageNamed:@"icon_image.png"];
        }
    }
    else
        thumbnail.image = [UIImage imageNamed:@"icon_image.png"];
    
    // Adjust frame to center image in 107x80 area
    CGRect newFrame = thumbnail.frame;
    //newFrame.size.width = thumbnail.image.size.width;
    //newFrame.size.height = newImage.size.height;
    newFrame.origin.x = TP_THUMBNAIL_LEFT_MARGIN;
    newFrame.origin.y = TP_THUMBNAIL_BOTTOM_MARGIN;
    if ([TPUtil isPortraitOrientation]) newFrame.origin.x += 70;
    if (newFrame.size.height < 80) newFrame.origin.y += (80 - newFrame.size.height) / 2;
    if (newFrame.size.width < 107) newFrame.origin.x += (107 - newFrame.size.width) / 2;
    newFrame.origin.x = 405;
    [thumbnail setFrame:newFrame];
     */
    
    //jxi;
    if( thumb.filename )
    {
        if (thumb) {
            thumbnail.image = [UIImage imageNamed:@"icon_video.png"];
        } else {
            thumbnail.image = [UIImage imageNamed:@"icon_video_gray.png"];
        }
    }
    else
        thumbnail.image = [UIImage imageNamed:@"icon_video_gray.png"];
}

// --------------------------------------------------------------------------------------
- (TPUserdataTypes) getContentType {
    return contentType;
}

// --------------------------------------------------------------------------------------
- (NSString *) getUserdataID {
    return userdata_id;
}

// --------------------------------------------------------------------------------------
+ (int) cellHeightForCellWithUserdata:(TPUserData *)aUserdata mainView:(TPView *)mainView {
    
    if (aUserdata.type == TP_USERDATA_TYPE_FORM) {
        return 44;
    
    } else if (aUserdata.type == TP_USERDATA_TYPE_IMAGE) {
        //return 96;
        return 50; //jxi;
        /*
        TPImage *image = [mainView.model getImageFromListById:aUserdata.userdata_id type:TP_IMAGE_TYPE_THUMBNAIL];
        if ([image  isPortraitImage]) {
            return 123;
        } else {
            return 96;
        }
         */
        
    } else if (aUserdata.type == TP_USERDATA_TYPE_ATTACHMENT) {
        // DISABLE DESCRIPTION DISPLAY
        return 44;
        int descriptionwidth;
        if (UIInterfaceOrientationIsLandscape([[UIDevice currentDevice] orientation])) {
            descriptionwidth = TP_ATTACH_STATUS_WIDTH_LANDSCAPE;
        } else {
            descriptionwidth = TP_ATTACH_STATUS_WIDTH_PORTRAIT;
        }
        CGSize constSize = CGSizeMake(descriptionwidth, 1000);
        CGSize descriptionSize = [aUserdata.description sizeWithFont:[UIFont fontWithName:@"Helvetica-Oblique" size:14.0]
                                                            constrainedToSize:constSize
                                                                lineBreakMode:TPLineBreakByWordWrapping];
        return ((25 + 15 + 5 + descriptionSize.height)>44) ? (25 + 15 + 5 + descriptionSize.height) : 44;
    }

    return 44;
}

@end
