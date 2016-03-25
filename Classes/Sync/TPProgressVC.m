//
//  TPProgressVC.m
//  teachpoint
//
//  Created by Dmitriy Doroshenko on 17.11.11.
//  Copyright (c) 2011 QArea. All rights reserved.
//

#import "TPData.h"
#import "TPModel.h"
#import "TPModelSync.h"
#import "TPView.h"
#import "TPRoundRect.h"
#import "TPProgressVC.h"
#import "TPCompat.h"

@implementation TPProgressVC

- (id) initWithView:(TPView *)delegate {
	
	self = [ super init ];
	if (self != nil) {
        
		viewDelegate = delegate;
        currentSyncType = SYNC_ERROR_OK;
        cleanState = TRUE;
		currentUnprocessedCount = 0;
		totalUnprocessedCount = 0;
        
        UIImage *logoImage = [UIImage imageNamed:@"logo.png"];
        UIImageView *logoView = [[[UIImageView alloc] initWithImage:logoImage] autorelease];
        self.navigationItem.titleView = logoView;
        
		wholeview = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 768, 600)];
        wholeview.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        
        roundrect = [[[TPRoundRectView alloc] initWithFrame:CGRectMake(234, 120, 300, 220)] autorelease];
		roundrect.rectColor = [UIColor colorWithWhite:0.1 alpha:0.6];
		roundrect.strokeColor = [UIColor clearColor];
		roundrect.cornerRadius = 20.0;
        [wholeview addSubview:roundrect];
        
		userLabel = [[[UILabel alloc] initWithFrame:CGRectMake(239, 150, 290, 30)] autorelease];
		userLabel.text = @"";
		userLabel.textColor = [UIColor whiteColor];
		userLabel.backgroundColor = [UIColor clearColor];
		userLabel.font = [UIFont fontWithName:@"Helvetica" size:20.0];
		userLabel.textAlignment = TPTextAlignmentCenter;
        [wholeview addSubview:userLabel];
		
		statusLabel = [[[UILabel alloc] initWithFrame:CGRectMake(239, 190, 290, 30)] autorelease];
		statusLabel.text = [self syncStatusString];
		statusLabel.textColor = [UIColor whiteColor];
		statusLabel.backgroundColor = [UIColor clearColor];
		statusLabel.font = [UIFont fontWithName:@"Helvetica" size:20.0];
		statusLabel.textAlignment = TPTextAlignmentCenter;
        [wholeview addSubview:statusLabel];
        
        UIActivityIndicatorView *spinner = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge] autorelease];
        [spinner setFrame:CGRectMake(365, 213, 37, 37)];
        [spinner startAnimating];
        [wholeview addSubview:spinner];
		
		cancelButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
		cancelButton.frame = CGRectMake(324, 280, 120, 30);
		[cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
		[cancelButton addTarget:self action:@selector(cancelLogin) forControlEvents:UIControlEventTouchUpInside];
        [wholeview addSubview:cancelButton];
	}
	return self;
}

- (void) dealloc {
	[wholeview release];
    [super dealloc];
}

- (void) cancelLogin {
    [viewDelegate.model cancelSync];
    [viewDelegate returnToLoginScreen];
}

- (void) loadView {
	[super loadView];
    [self.view addSubview:wholeview];
	self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"linen.png"]]; 
}

- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
    //NSLog(@"register progress callback");
    [viewDelegate.model registerSyncStatusCallback:self :@selector(updateSyncStatusCallback:)];
	[self updateStatusUI];
}

- (void) viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:(BOOL)animated];
    //[viewDelegate.model unregisterSyncStatusCallback];
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

//------------------------------------------------------------------------------------------------
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration {
    if (debugRotate) NSLog(@"TPProgressVC willRotateToInterfaceOrientation");
}

- (void)viewWillLayoutSubviews {
    if (debugRotate) NSLog(@"TPProgressVC viewWillLayoutSubviews");
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration {
    if (debugRotate) NSLog(@"TPProgressVC willAnimateRotationToInterfaceOrientation");
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    if (debugRotate) NSLog(@"TPProgressVC didRotateFromInterfaceOrientation");
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    if (debugRotate) NSLog(@"TPProgressVC shouldAutorotateToInterfaceOrientation");
    return YES;
}

//------------------------------------------------------------------------------------------------
- (void) updateSyncStatusCallback:(int) syncType {
	currentSyncType = syncType;
    cleanState = FALSE;
	[self updateStatusUI];
}

//------------------------------------------------------------------------------------------------
- (void) updateStatusUI {
	[self setUnprocessedCounts];
    if (userLabel) {
        userLabel.text = [NSString stringWithFormat:@"Syncing user... %@", viewDelegate.model.appstate.login];
    }
    if (statusLabel) {
        statusLabel.text = [NSString stringWithString:[self syncStatusString]];
    }
}

- (void) setUnprocessedCounts {
	totalUnprocessedCount = [[viewDelegate.model tmp_userdata_array] count];
    currentUnprocessedCount = [viewDelegate.model getUnprocessedCount];
}

// Formatting proper last sync status string
- (NSString *) syncStatusString {
    return @"";
    // disabled due to switching to main screen after first sync step is complete
    /* float processingPercentage;
    
	switch (currentSyncType) {
		case SYNC_TYPE_USER:
			return @"Step 1 of 6";
			break;
		case SYNC_TYPE_INFO:
			return @"Step 2 of 6";
			break;
		case SYNC_TYPE_CATEGORY:
			return @"Step 3 of 6";
			break;
		case SYNC_TYPE_RUBRIC:
			return @"Step 4 of 6";
			break;
		case SYNC_TYPE_CLIENTDATA:
            return @"Step 5 of 6";
		case SYNC_TYPE_DATA:
            processingPercentage = (float)(totalUnprocessedCount - currentUnprocessedCount)/totalUnprocessedCount*100;
            if (currentUnprocessedCount)
            {
                return [NSString stringWithFormat:@"Step 6 of 6, %i%% done", (int)(totalUnprocessedCount?processingPercentage:0)];
            }
            else
            {
                return [NSString stringWithFormat:@"Step 6 of 6"];
            }
			break;
		case SYNC_ERROR_GENERAL:
			return cleanState?@"":@"An error occurred while syncing";
			break;
		case SYNC_ERROR_WIFI:
			return cleanState?@"":@"WiFi connection error";
			break;
		case SYNC_ERROR_TIMEOUT:
			return cleanState?@"":@"Connection timeout";
			break;
		case SYNC_ERROR_LOGIN:
			return cleanState?@"":@"Login failed";
			break;
		case SYNC_ERROR_OK:
			return cleanState?@"Step 1 of 6":@"Sync complete";
		default:
			return @"";
			break;
	}	*/
}

@end
