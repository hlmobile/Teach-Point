#import "TPData.h"
#import "TPView.h"
#import "TPModel.h"
#import "TPModelSync.h"
#import "TPLoginVC.h"
#import "TPTimeoutVC.h"
#import "TPMaster.h"
#import "TPRubricList.h"
#import "TPRubrics.h"
#import "TPInfo.h"
#import "TPReportList.h"
#import "TPReports.h"
#import "TPDatabase.h"
#import "TPSyncManager.h"
#import "TPOptionsPO.h"
#import "TPGradePO.h"
#import "TPProgressVC.h"
#import "TPCamera.h"
#import "TPUtil.h" //jxi;
#import "TPVideo.h"

// --------------------------------------------------------------------------------------
@implementation TPView

@synthesize model;
@synthesize viewControl;
@synthesize rubricVC;
@synthesize rubriclistVC;
@synthesize cameraVC;
@synthesize videoVC; //jxi;
@synthesize optionsPOC;
@synthesize gradePOC;
@synthesize optionsPOViewHeight;
@synthesize optionsPOViewWidth;
@synthesize optionsPOViewWidthExpanded;
@synthesize cameraButtonClickedState; //jxi;
@synthesize currentViewState; //jxi;
@synthesize preview_container_state; //jxi;
// --------------------------------------------------------------------------------------
- (id) initWithModel:(TPModel *)some_model {
	
    if (debugView) NSLog(@"TPView initWithModel");
    
	self = [ super init ];
	if (self != nil) {
		
		model = some_model;
				
        sync_type = SYNC_TYPE_USER;
                
        // Create window
        window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        
        // Create options popover
		optionsPOViewHeight = 176;
		// due to popover positioning issues after resizing, setting widths to same values for now
		optionsPOViewWidth = 320;
		optionsPOViewWidthExpanded = 320; 
        optionsPO = [[TPOptionsPO alloc] initWithViewDelegate:self];
		optionsNC = [[UINavigationController alloc] initWithRootViewController:optionsPO];
        optionsPOC = [[UIPopoverController alloc] initWithContentViewController:optionsNC];
        
		// Create sync popover
		syncPO = [[TPSyncPO alloc] initWithViewDelegate:self];
		
		// Create preferences popover
		preferencesPO = [[TPPreferencesPO alloc] initWithViewDelegate:self];
		
        // Create help popover
        helpPO = [[TPHelpPO alloc] initWithViewDelegate:self];
        
        // Create timeout popover
        timeoutVC = [[TPTimeoutVC alloc] initWithView: self];
        timeoutVC.wantsFullScreenLayout = YES;
        timeoutNC = [[UINavigationController alloc] initWithRootViewController:timeoutVC];
        
        // Create login screen
        loginVC = [[TPLoginVC alloc] initWithView: self];
        loginVC.wantsFullScreenLayout = YES;
		loginNC = [[UINavigationController alloc] initWithRootViewController:loginVC];
        
        // Create main split view screen
        splitVC = [[UISplitViewController alloc] init];
        splitVC.wantsFullScreenLayout = YES;
        
        // Create master view
        teacherlistVC = [[TPMasterVC alloc] initWithView:self];
        masterNC = [[UINavigationController alloc] initWithRootViewController:teacherlistVC];
                
        // Create detail view
        rubriclistVC = [[TPRubricListVC alloc] initWithView:self];
        rubricVC = [[TPRubricVC alloc] initWithView:self];
        infoVC = [[TPInfoVC alloc] initWithView:self];
        reportlistVC = [[TPReportListVC alloc] initWithView:self];
        reportVC = [[TPReportVC alloc] initWithView:self];
        detailNC = [[UINavigationController alloc] initWithRootViewController:rubriclistVC];
        currentViewState = TP_VIEW_STATE_RUBRICS;
		
        // Create progress screen
        progressVC = [[TPProgressVC alloc] initWithView:self];
        progressVC.wantsFullScreenLayout = YES;
        progressNC = [[UINavigationController alloc] initWithRootViewController:progressVC]; 
        
        // Create camera viewer
        cameraVC = [[TPCameraVC alloc] initWithView:self image:nil];
        cameraVC.wantsFullScreenLayout = YES;
        cameraNC = [[UINavigationController alloc] initWithRootViewController:cameraVC];
        cameraNC.navigationBarHidden = YES;
        cameraNC.toolbarHidden = NO;
        cameraNC.toolbar.barStyle = UIBarStyleBlack;
        cameraNC.toolbar.translucent = YES;
        
        // Create video viewer //jxi;
        videoVC = [[TPVideoVC alloc] initWithView:self image:nil];
        videoVC.wantsFullScreenLayout = YES;
        videoNC = [[UINavigationController alloc] initWithRootViewController:videoVC];
        videoNC.navigationBarHidden = YES;
        videoNC.toolbarHidden = NO;
        videoNC.toolbar.barStyle = UIBarStyleBlack;
        videoNC.toolbar.translucent = YES;
        
        // Add master and detail view controllers to the split view
        splitVC.viewControllers = [NSArray arrayWithObjects:masterNC, detailNC, nil];
        splitVC.delegate = self;
        
        // Create a generic alert
		confirmalert = [[UIAlertView alloc]
						initWithTitle:@""
						message:@""
						delegate:self
						cancelButtonTitle: @"OK"
						otherButtonTitles: @"Cancel", nil];
		[confirmalert dismissWithClickedButtonIndex:0 animated:NO];
		[confirmalert dismissWithClickedButtonIndex:1 animated:NO];
        
        generalalert = [[UIAlertView alloc]
                        initWithTitle:@""
                        message:@""
                        delegate:self
                        cancelButtonTitle: nil
                        otherButtonTitles: @"OK", nil];
        [generalalert dismissWithClickedButtonIndex:0 animated:NO];
        
        if ([model.publicstate.state isEqualToString:@"install"]) {
            [self gotologinscreen];
		} else {
            window.rootViewController = splitVC;
        }
        
        [self setSyncStatus];
		[window makeKeyAndVisible];
	}
	return self;
}

// --------------------------------------------------------------------------------------
- (void) dealloc {
    if (debugView) NSLog(@"TPView dealloc");
    [confirmalert release];
    [generalalert release];
    [loginVC release];
	[loginNC release];
    [timeoutVC release];
    [timeoutNC release];
    [splitVC release];
	[window release];
    if (cameraVC != nil) [cameraVC release];
	[super dealloc];
}

// --------------------------------------------------------------------------------------
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration {
    if (debugRotate) NSLog(@"TPView willRotateToInterfaceOrientation");
}

- (BOOL)shouldAutorotate {
    if (debugRotate) NSLog(@"TPView shouldAutorotate");
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
    if (debugRotate) NSLog(@"TPView supportedInterfaceOrientations");
    return UIInterfaceOrientationMaskAll;
}

- (void)viewWillLayoutSubviews {
    if (debugRotate) NSLog(@"TPView viewWillLayoutSubviews");
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    if (debugRotate) NSLog(@"TPView shouldAutorotateToInterfaceOrientation");
    return YES;
}

// --------------------------------------------------------------------------------------
- (void)viewWillAppear:(BOOL)animated {
    if (debugView) NSLog(@"TPView viewWillAppear %d", animated);
}

// --------------------------------------------------------------------------------------
- (void) pushSync {
    [syncPO updateStatusUI];
	[optionsNC pushViewController:syncPO animated:YES];
}

- (void) registerSyncPopupForSyncStatusCallback {
    [syncPO registerForSyncStatusCallback];
}

- (void) clearSyncPopupStatus:(BOOL)forced {
    [syncPO clearStatusUI:forced];
}

// --------------------------------------------------------------------------------------
- (void) pushPreferences {
	[optionsNC pushViewController:preferencesPO animated:YES];
}

// --------------------------------------------------------------------------------------
- (void) popOptionsPO {
	[optionsNC popViewControllerAnimated:YES];
}

// --------------------------------------------------------------------------------------
- (void) doSync {
    [self.model setNeedSyncStatus:NEEDSYNC_STATUS_SYNCING forced:NO];
	[self pushProgress];
    if (sync_type == SYNC_TYPE_CLIENTDATA) [model clientDataSyncPrep];
    [model doSync:sync_type];
    sync_type = SYNC_TYPE_USER; // Reset sync type
}

// --------------------------------------------------------------------------------------
- (void) finishSuspendedSync {
    [self.model setNeedSyncStatus:NEEDSYNC_STATUS_SYNCING forced:NO];
	[self pushProgress];
    if (sync_type == SYNC_TYPE_CLIENTDATA) [model clientDataSyncPrep];
    [self syncNow:[model getSyncType]];
}

// --------------------------------------------------------------------------------------
- (void) syncNow:(int)syncType {
    sync_type = syncType;
    [model immediateSync];
}

// --------------------------------------------------------------------------------------
- (void)setSyncStatus {
    // Reset indicator
    [teacherlistVC setNeedSyncButtonStateForStatus:[model needSyncStatus]];
}

// --------------------------------------------------------------------------------------
- (void) syncfailed:(NSString *)title poptostart:(NSInteger)poptostart {
	if (poptostart) {
        [self gotologinscreen];
	}
    [self popProgress];
	UIAlertView *alert = [[UIAlertView alloc]
						  initWithTitle:title
						  message:model.appstate.sync_message
						  delegate:nil
						  cancelButtonTitle: nil
						  otherButtonTitles: @"OK", nil];
	[alert show];
    [alert release];
}

- (void) syncwarning:(NSString *)title {
	UIAlertView *alert = [[UIAlertView alloc]
						  initWithTitle:title
						  message:model.appstate.sync_message
						  delegate:self
						  cancelButtonTitle: nil
						  otherButtonTitles: @"OK", nil];
	[alert show];
    [alert release];
}


- (void) urlfailed:(NSError *)error {
	[self popProgress];
	NSString *message = [NSString stringWithFormat:@"Network failure - %@", [error localizedDescription]];
	UIAlertView *loginalert = [[UIAlertView alloc]
							   initWithTitle:@"Network Problem"
							   message:message
							   delegate:self
							   cancelButtonTitle: nil
							   otherButtonTitles: @"OK", nil];
	[loginalert show];
    [loginalert release];
}

- (void) badnumeric {
	UIAlertView *numberalert = [[UIAlertView alloc]
							   initWithTitle:@"Invalid Response"
							   message:@"Your answer needs to be a number between the minimum and maximum value shown."
							   delegate:self
							   cancelButtonTitle: nil
							   otherButtonTitles: @"OK", nil];
	[numberalert show];
    [numberalert release];
}

- (void) syncwarning {
	UIAlertView *syncalert = [[UIAlertView alloc]
							   initWithTitle:@"Warning"
							   message:@"Please sync recorded data before clearing user account."
							   delegate:self
							   cancelButtonTitle: nil
							   otherButtonTitles: @"OK", nil];
	[syncalert show];
    [syncalert release];
}

- (void) generalAlert:(NSString *)title message:(NSString *)message poptostart:(NSInteger)poptostart {
    [self popProgress];
	if (poptostart) {
        [self gotologinscreen];
	}
    generalalert.title = title;
    generalalert.message = message;
	[generalalert show];
}

// --------------------------------------------------------------------------------------
- (void) confirm_abortlog {
	[self confirmAlert:@"Abort Log" message:@"This will delete reponses recorded for the current log?"];
}

- (void) confirmAlert:(NSString *)title message:(NSString *)message {
	confirmalert.title = title;
	confirmalert.message = message;
	[confirmalert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    // Ignore if not logged in or in timeout
    // WARNING we shouldn't need this.  We should dismiss all alerts before entering background
    if ([model.publicstate.state isEqualToString:@"install"] ||
        [model.publicstate.state isEqualToString:@"timeout"]) return;
    
	// Do nothing
	if (buttonIndex == 0 && alertView.tag == 10) {
		// logout confirmed, user selected OK
		[self doLogout];
	}
}

// --------------------------------------------------------------------------------------
// updatePromptString - call this method after login to update prompt string at top
// of detail views.
// --------------------------------------------------------------------------------------
- (void) updatePromptString {
    [rubriclistVC reset];
    [infoVC reset];
    [reportlistVC reset];
    [teacherlistVC resetPrompt];
}

// --------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------
- (void) showMain {
		
    if (debugView) NSLog(@"TPView showMain");
    
	[model deriveData];
    [self reloadUserList];
	[self reloadUserdataList];
    
    [loginVC clearLoginFields];
        
    // If logging in then go to split view
    if ([model.publicstate.state isEqualToString:@"install"])  {
        [self popProgress];
        window.rootViewController = splitVC;
    }
    
    [teacherlistVC sortUsers];
    
    if ( self.model.needSyncStatus == NEEDSYNC_STATUS_SYNCED ) {
        [self.model setNeedSyncStatus:NEEDSYNC_STATUS_SYNCED forced:NO];
    }
    
    if ([model.publicstate.state isEqualToString:@"install"]) [model setState:@"synced"];
};

- (void) sortUsers {
    [teacherlistVC sortUsers];
}

// --------------------------------------------------------------------------------------
- (void) pushProgress {
    // Show a progress view
    if ([model.publicstate.state isEqualToString:@"install"]) {
        window.rootViewController = progressNC;
    }
}

- (void) popProgress {
    // Hide the progress view
    [progressNC.view removeFromSuperview];
}

// --------------------------------------------------------------------------------------
- (void) returnToLoginScreen {
    [progressNC.view removeFromSuperview]; 
    [self gotologinscreen];
}

// --------------------------------------------------------------------------------------
- (void) debug {
    [model dump];
    [model dumpDatabase];
    //[model.database dumpDatabaseShort];
}

// --------------------------------------------------------------------------------------
- (void)splitViewController:(UISplitViewController*)svc popoverController:(UIPopoverController*)pc willPresentViewController:(UIViewController *)aViewController {
    //NSLog(@"willPresentViewController");
}

- (void)splitViewController:(UISplitViewController*)svc willHideViewController:(UIViewController *)aViewController withBarButtonItem:(UIBarButtonItem*)barButtonItem forPopoverController:(UIPopoverController*)pc {
    //NSLog(@"willHideViewController");
}

- (void)splitViewController:(UISplitViewController*)svc willShowViewController:(UIViewController *)aViewController invalidatingBarButtonItem:(UIBarButtonItem *)button {
    //NSLog(@"willShowViewController");
}

// --------------------------------------------------------------------------------------
// selectTargetAtIndex - select target user from user list
// --------------------------------------------------------------------------------------
- (void) selectTargetAtIndex:(int)index {
    // Reset the rubric list screen
    [rubriclistVC reset];
    // Reset the user info screen
    [infoVC reset];
    // Reset the report list if required
    if (currentViewState == TP_VIEW_STATE_REPORTS) [reportlistVC reset];
}

// --------------------------------------------------------------------------------------
- (void) rubricBeginEditing {
    
    // Create a new rubric view and (re)set content
    if (rubricVC != nil) [rubricVC release];
    rubricVC = [[TPRubricVC alloc] initWithView:self];
    [self reloadRubric];
    
    [detailNC pushViewController:rubricVC animated:YES];
    [model setState:@"rubric"];
}

// --------------------------------------------------------------------------------------
// rubricCaptureCurrentState - save any unsaved data (e.g. text, annotation, etc.)
// --------------------------------------------------------------------------------------
- (void) rubricCaptureCurrentState {
    if (debugView) NSLog(@"TPView rubricCaptureCurrentState userdata_id %@", model.appstate.userdata_id);
    [rubricVC finalizeRubricCells:TRUE];
    // Get elapsed time
	BOOL isStarted = [rubricVC updateElapsedTime];
    if (debugView) NSLog(@"rubricCaptureCurrentState isStarted %d", isStarted);
    if (!isStarted) {
        // Purge userdata instance from DB if empty
        [model purgeUserDataIfEmpty:model.appstate.userdata_id];
        [model setNeedSyncStatusFromUnsyncedCount:NO];
    }
}

// --------------------------------------------------------------------------------------
// rubricDoneEditing - close open form and reload form list
// --------------------------------------------------------------------------------------
- (void) rubricDoneEditing {
    if (debugView) NSLog(@"TPView rubricDoneEditing");
    [self rubricCaptureCurrentState]; // Save any unsaved data (e.g. text, annotation, etc.)
    [model clearCurrentRubric]; // Clear selected rubric values in state cache
    [self reloadUserdataList];
    [detailNC popViewControllerAnimated:YES];
    [model setState:@"rubriclist"];
    [model setNeedSyncStatusFromUnsyncedCount:NO]; // this will set right color of sync icon (button)
    
    //jxi; Trigger sync action immediately after user saves an edited form
    if ([model syncIsSupended]) {
        // If syncing is suspended (currently executing another sync) then no action
        return;
    } else {
        // Otherwise sync form data
        if (model.needSyncStatus == NEEDSYNC_STATUS_NOTSYNCED) {
            //[self syncNow:SYNC_TYPE_CLIENTDATA];
            [self doSync];
        }
    }
}

// --------------------------------------------------------------------------------------
// reloadUserdataList - reload form list
// --------------------------------------------------------------------------------------
- (void) reloadUserdataList {
    if (debugView) NSLog(@"TPView reloadUserdataList");
    [model deriveVideoList]; //jxi;
    [model deriveImageList];
    [model deriveUserDataList];
    [rubriclistVC resetFormDataArray]; //jxi
    [rubriclistVC.tableView reloadData];
}

// --------------------------------------------------------------------------------------
// reloadUserList - reload user list
// --------------------------------------------------------------------------------------
- (void) reloadUserList {
    if (debugView) NSLog(@"TPView reloadUserList");
    [model deriveUserDataList];
    [teacherlistVC reloadTableData];
    [teacherlistVC highlightTargetUser];
}

// --------------------------------------------------------------------------------------
- (void) reloadRubric {
    [rubricVC reset];
}

// --------------------------------------------------------------------------------------
- (void) reloadInfo {
    [infoVC reset];
}

// --------------------------------------------------------------------------------------
- (void) reloadReport {
    //[reportVC reset];
}

// --------------------------------------------------------------------------------------
- (void) reloadReportList {
	[reportlistVC reset];
}

// --------------------------------------------------------------------------------------
// newUserData - begin viewing/editing a new rubric recording
// --------------------------------------------------------------------------------------
// Create a new rubric recording screen
- (void) newUserData:(TPRubric *)rubric {
    
    if (debugView) NSLog(@"TPView newUserData");
    
    // Create new user data
    [model newUserData:rubric];
    
    // Show rubric
    [self rubricBeginEditing];
}

// --------------------------------------------------------------------------------------
// setUserData - begin viewing/editing an existing rubric recording
// --------------------------------------------------------------------------------------
// Set rubric recording screen
- (void) setUserData:(TPUserData *)userdata {
    
    // Reload user data
    [model setUserData:userdata];
    
    // Show rubric
    [self rubricBeginEditing];
}

// --------------------------------------------------------------------------------------
// setReport - begin viewing a report
// --------------------------------------------------------------------------------------
// Set rubric recording screen
- (void) setReport:(int)reportgroup groupName:(NSString *)groupName reportId:(int)reportId reportName:(NSString *)reportName {
    
    // Show on screen
    [reportVC reset:reportgroup groupName:groupName reportId:reportId reportName:reportName];
    [self reportBeginViewing];
}

- (void) reportBeginViewing {
    [detailNC pushViewController:reportVC animated:YES];
    [model setState:@"report"];
}

- (void) reportDoneViewing {
    if (debugView) NSLog(@"TPView reportDoneViewing");
    [detailNC popViewControllerAnimated:YES];
    [model setState:@"rubriclist"];
}

// --------------------------------------------------------------------------------------
// returnFromOpenedView - return from rubric or report view if one is open
// --------------------------------------------------------------------------------------
- (void) returnFromOpenedView {
    
    if (debugView) NSLog(@"TPView returnFromOpenedView public state %@", model.publicstate.state);
    
    if ([model.publicstate.state isEqualToString:@"rubric"]) {
        [self rubricDoneEditing];
    } else if ([model.publicstate.state isEqualToString:@"report"]) {
        [self reportDoneViewing];
    }
}

// --------------------------------------------------------------------------------------
// switchView - change the detail view based on the segmented controller selection
// --------------------------------------------------------------------------------------
- (void) switchView:(int)index {
    currentViewState = index;
    switch (index) {
        case TP_VIEW_STATE_RUBRICS:
            [detailNC popToRootViewControllerAnimated:NO];
            [masterNC popToRootViewControllerAnimated:NO];
            [model setState:@"rubriclist"];
            break;
        case TP_VIEW_STATE_INFO:
            [detailNC popToRootViewControllerAnimated:NO];
            [detailNC pushViewController:infoVC animated:NO];
            [masterNC popToRootViewControllerAnimated:NO];
            [model setState:@"info"];
            break;
        case TP_VIEW_STATE_REPORTS:
            [reportlistVC reset];
            [detailNC popToRootViewControllerAnimated:NO];
            [detailNC pushViewController:reportlistVC animated:NO];
            [masterNC popToRootViewControllerAnimated:NO];
            [model setState:@"reportlist"];
            break;
        case TP_VIEW_STATE_CAMERA: //jxi;
            //[self switchToCameraView];
            [self switchToVideoView];
            break;
    }
    // Set the same selected index for all three detail views
    [rubriclistVC setSelectedView:index];
    [infoVC setSelectedView:index];
    [reportlistVC setSelectedView:index];
}

// --------------------------------------------------------------------------------------
- (void) cameraBeginCapture {
    //[rubriclistVC presentViewController:cameraVC animated:YES completion:nil];
    window.rootViewController = cameraNC;
    [cameraVC startCapture];
}

- (void) cameraDoneCapture {
    [cameraVC stopCapture];
    //[rubriclistVC dismissViewControllerAnimated:YES completion:nil];
    window.rootViewController = splitVC;
    [self reloadUserdataList];
    model.appstate.state = @"rubric";
}

// --------------------------------------------------------------------------------------
- (void) logout: (BOOL)confirmRequired {

	if (debugLogin) NSLog(@"TPView logout %d", confirmRequired);
    
    // Check that there is no unsynced data for regular accounts
    if (model.publicstate.is_demo == 0 &&
        [model getUserDataUnsyncedCount] > 0) {
        [self generalAlert:@"Warning" message:@"You have data that needs to be synced.  Please manually sync before logging out." poptostart:0];
        return;
    }
	
	if (confirmRequired){
		// tag for distinguishing this alert view from others when processing button events
		[confirmalert setTag: 10];
		[self confirmAlert:@"" message:@"\nDo you want to log out?\n\n"];
	} else {
		[self doLogout];
	}
}
	
- (void) logout {
    if (debugLogin) NSLog(@"TPView logout");
	[self logout:FALSE];
}

- (void) doLogout {
	
    if (debugLogin) NSLog(@"TPView doLogout");
    
    // Cancel sync activity
    [model cancelSync];
    
    // Clear all data
    [model clearData];
    [model clearUser];
    //[model clearDatabase]; // DB destroyed later in this method - not needed
    
    // Change to login screen
    [infoVC clearContent];
    [loginVC clearLoginFields];
    window.rootViewController = loginNC;
    
    // Clearing last sync time to stop sync manager from auto-syncing
    [model suspendSyncing];
    [model setState:@"install"];
    [model setIsApplicationFirstTimeSync:YES];
    
    // Close and destory database
    [model closeDatabase];
    [TPModel destroyDatabase];
}

// --------------------------------------------------------------------------------------
- (void) pushCamera {
    [self hideoptions];
    [self cameraBeginCapture];
}

- (void) resetPreview {
    
    if ([self preview_container_state] == TP_PREVIEW_FOR_RUBRICLIST) {
        // If the preview for an item on rubriclistVC then show its previewVC
        [self.rubriclistVC resetPreview];
    } else {
        // If the preview for an item on rubrics then show its previewVC
        [self.rubricVC resetPreview];
    }
}

// ---------------------------------------------------------------------------------------
- (void) timeoutscreen {
    //NSLog(@"timeoutscreen");
    [model suspendSyncing];
    [timeoutVC reset];
    window.rootViewController = timeoutNC;
    [model setState:@"timeout"];
}

- (void) gotologinscreen {
    // Close and destory database
    [model closeDatabase];
    [TPModel destroyDatabase];
    // Make login screen the root view
    window.rootViewController = loginNC;
}

- (void) exittimeoutscreen {
    //NSLog(@"exittimeoutscreen");
    [timeoutVC zeroStrikes];  // Reset strikes against user
    
    // Change screen to either login or regular (split) view
    //[timeoutNC.view removeFromSuperview];
    [timeoutVC reset];
    
    if ([model.publicstate.state isEqualToString:@"install"]) {
        [self gotologinscreen];
    } else {
        [model setState:@"view"];
        [self reloadUserdataList];
        [self reloadInfo];
        [self reloadReportList];
        [self highlightTargetUser];
        window.rootViewController = splitVC;
        [model restartSyncing]; // Restart syncing
    }
}

// --------------------------------------------------------------------------------------
- (void) hidenew {
    [rubriclistVC hidenew];
}

- (void) hideoptions {
    [optionsPOC dismissPopoverAnimated:YES];
	[self popOptionsPO];
}

// --------------------------------------------------------------------------------------
- (void) closeAllPopupsAndAlerts {
    if (debugView) NSLog(@"TPView closeAllPopupsAndAlerts");
    [self hidenew];
    [self hideoptions];
    // Doesn't seem to help.  Still get wait_fences message
    //[confirmalert dismissWithClickedButtonIndex:1 animated:NO];
    //[generalalert dismissWithClickedButtonIndex:0 animated:NO];
}

// --------------------------------------------------------------------------------------
- (void) highlightTargetUser {
    if (model.appstate.target_id > 0) {
        [teacherlistVC performSelector:@selector(highlightTargetUser) withObject:nil afterDelay:0.05f];
//        [teacherlistVC highlightTargetUser];
    }
}

// --------------------------------------------------------------------------------------
- (void) disableRubricListInteraction {
    rubriclistVC.tableView.scrollEnabled = NO;
    rubriclistVC.tableView.userInteractionEnabled = NO;
}

- (void) enableRubricListInteraction {
    rubriclistVC.tableView.scrollEnabled = YES;
    rubriclistVC.tableView.userInteractionEnabled = YES;
}

// ---------------------------------------------------------------------------------
// jxi; resetRubricVC
// ---------------------------------------------------------------------------------
- (void) resetRubricVC {
    if (debugView) NSLog(@"TPView resetRubricVC");
    [self.rubricVC reloadForm];
}

// ---------------------------------------------------------------------------------
// jxi; onNoRubricData
// ---------------------------------------------------------------------------------
- (void) onNoRubricData {
    if (debugView) NSLog(@"TPView onNoRubricData");
    UIAlertView *waitAlert = [[UIAlertView alloc] initWithTitle:@""
                                                        message:@"Data is not available!" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
    [waitAlert show];
    [waitAlert release];
    
    [self rubricDoneEditing];
}

// ---------------------------------------------------------------------------------
// jxi; switchToCameraView - called when camera tab item clicked
// ---------------------------------------------------------------------------------
- (void) switchToCameraView {
    if (debugView) NSLog(@"TPView switchToCameraView");
    // camera button
    if (![TPUtil isCameraAvailableOnTheDevice]) {
        UIAlertView *nocameraAlert = [[UIAlertView alloc] initWithTitle:@""
                                                                message:@"\nThere is no camera on your device.\n\n"
                                                               delegate:self
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles: nil];
        [nocameraAlert show];
        [nocameraAlert release];
        return;
    }
    TPUser *targetUser = [model getCurrentTarget];
    if (targetUser.permission != TP_PERMISSION_VIEW_AND_RECORD && targetUser.permission != TP_PERMISSION_RECORD) {
        UIAlertView *nocameraAlert = [[UIAlertView alloc] initWithTitle:@""
                                                                message:@"\nYou don't have permission to record for the selected user.\n\n"
                                                               delegate:self
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles: nil];
        [nocameraAlert show];
        [nocameraAlert release];
        return;
    }
    
    [self pushCamera];
}

// ---------------------------------------------------------------------------------
// jxi; switchToVideoView - called when camera tab item clicked
// ---------------------------------------------------------------------------------
- (void) switchToVideoView {
    if (debugView) NSLog(@"TPView switchToVideoView");
    if (![TPUtil isCameraAvailableOnTheDevice]) {
        UIAlertView *nocameraAlert = [[UIAlertView alloc] initWithTitle:@""
                                                                message:@"\nThere is no camera on your device.\n\n"
                                                               delegate:self
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles: nil];
        [nocameraAlert show];
        [nocameraAlert release];
        return;
    }
    TPUser *targetUser = [model getCurrentTarget];
    if (targetUser.permission != TP_PERMISSION_VIEW_AND_RECORD && targetUser.permission != TP_PERMISSION_RECORD) {
        UIAlertView *nocameraAlert = [[UIAlertView alloc] initWithTitle:@""
                                                                message:@"\nYou don't have permission to record for the selected user.\n\n"
                                                               delegate:self
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles: nil];
        [nocameraAlert show];
        [nocameraAlert release];
        return;
    }
    
    [self pushVideo];
}

// ---------------------------------------------------------------------------------
// jxi; videoBeginCapture
// --------------------------------------------------------------------------------------
- (void) videoBeginCapture {
    //[rubriclistVC presentViewController:cameraVC animated:YES completion:nil];
    window.rootViewController = videoNC;
    [videoVC stopRecording];
    [videoVC startRecording];
}

- (void) videoDoneCapture {
    [videoVC stopRecording];
    //[rubriclistVC dismissViewControllerAnimated:YES completion:nil];
    window.rootViewController = splitVC;
    [self reloadUserdataList];
    model.appstate.state = @"rubric";
}

// ---------------------------------------------------------------------------------
// jxi; pushVideo
// ---------------------------------------------------------------------------------
-(void)pushVideo
{
    [self hideoptions];
    [self videoBeginCapture];
}

// ---------------------------------------------------------------------------------
// jxi; resetVideoPreview
// ---------------------------------------------------------------------------------
- (void) resetVideoPreview {
    if ([self preview_container_state] == TP_PREVIEW_FOR_RUBRICLIST) {
        // If the preview for an item on rubriclistVC then show its previewVC
        [self.rubriclistVC resetVideoPreview];
    } else {
        // If the preview for an item on rubrics then show its previewVC
        [self.rubricVC resetVideoPreview];
    }
}
@end

// --------------------------------------------------------------------------------------
