#import "TPView.h"
#import "TPModel.h"
#import "TPModelSync.h"
#import "TPModelReport.h"
#import "TPData.h"
#import "TPCompat.h"
#import "TPOptionsPO.h"
#import "TPUtil.h"

#import <QuartzCore/QuartzCore.h>

//------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------
@implementation TPOptionsPO

- (id) initWithViewDelegate:(TPView *)delegate {
	
	self = [super init];
	if (self != nil) {
		
		viewDelegate = delegate;
		
		[self setContentSizeForViewInPopover:CGSizeMake(viewDelegate.optionsPOViewWidth, viewDelegate.optionsPOViewHeight)];
		
		// row captions for options PO
        //buttonList = [[NSMutableArray alloc] initWithObjects: @"Sync", @"Preferences", @"Camera", @"Logout", nil];
        buttonList = [[NSMutableArray alloc] initWithObjects: @"Sync", @"Preferences", @"Logout", nil]; //jxi;
		self.tableView.scrollEnabled = FALSE;
        
        backButton = [[UIBarButtonItem alloc] initWithTitle:@"  Options  " style:UIBarButtonItemStylePlain target:nil action:nil];
        self.navigationItem.backBarButtonItem = backButton;
	}
	return self;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

// --------------------------------------------------------------------------------------
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [buttonList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString *CellIdentifier = [NSString stringWithFormat:@"%d/%d/%@", viewDelegate.model.appstate.user_id,
                                [indexPath row], [buttonList objectAtIndex:[indexPath row]]];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: CellIdentifier];
	
    if (cell == nil) {
        // cell = [[[UITableViewCell alloc] initWithFrame: CGRectZero reuseIdentifier: CellIdentifier] autorelease]; // Deprecated
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        cell.textLabel.text = [buttonList objectAtIndex:[indexPath row]];
		UIFont *font = [UIFont fontWithName: @"Helvetica" size: 18.0 ];
	    cell.textLabel.font = font;
		
		if ([indexPath row] == 0 || [indexPath row] == 1) {
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		}
		else {
			cell.accessoryType = UITableViewCellAccessoryNone;
		}
		
		if ([indexPath row] == 3)
		{
			// long press of logout button functions as debug
			UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(debug:)];
			longPress.minimumPressDuration = 4;
			longPress.numberOfTouchesRequired = 1;
			[cell addGestureRecognizer:longPress];
			[longPress release];
		}
    }
	
    return cell;
}

// --------------------------------------------------------------------------------------
- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
	switch ([indexPath row]) {
		case 0:
			// sync
			[self sync];
			break;
		case 1:
			// preferences button
			[self preferences];
			break;
        case 5: //jxi;
		//case 2:
			// camera button
            if (![TPUtil isCameraAvailableOnTheDevice]) {
                UIAlertView *nocameraAlert = [[UIAlertView alloc] initWithTitle:@""
                                                                        message:@"\nThere is no camera on your device.\n\n"
                                                                       delegate:self
                                                              cancelButtonTitle:@"OK"
                                                              otherButtonTitles: nil];
                [nocameraAlert show];
                [nocameraAlert release];
                [tableView deselectRowAtIndexPath:indexPath animated:YES];
                break;
            }
            TPUser *targetUser = [viewDelegate.model getCurrentTarget];
            if (targetUser.permission != TP_PERMISSION_VIEW_AND_RECORD && targetUser.permission != TP_PERMISSION_RECORD) {
                UIAlertView *nocameraAlert = [[UIAlertView alloc] initWithTitle:@""
                                                                        message:@"\nYou don't have permission to record for the selected user.\n\n"
                                                                       delegate:self
                                                              cancelButtonTitle:@"OK"
                                                              otherButtonTitles: nil];
                [nocameraAlert show];
                [nocameraAlert release];
                [tableView deselectRowAtIndexPath:indexPath animated:YES];
                break;
            }
            [self camera];
			break;
		case 2:
			// logout
			[self logout];
			break;
		default:
			break;
	}
	
}

//------------------------------------------------------------------------------------------------
- (void) preferences {
    [viewDelegate pushPreferences];
}

- (void) camera {
    [viewDelegate pushCamera];
}

- (void) sync {
	[viewDelegate pushSync];
}

- (void) logout {
    [viewDelegate hideoptions];
    [viewDelegate logout: TRUE];
}

- (void) debug:(UILongPressGestureRecognizer*)sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
        [viewDelegate hideoptions];
        [viewDelegate debug];
    }
}

@end


//------------------------------------------------------------------------------------------------
@implementation TPSyncPO

- (id) initWithViewDelegate:(TPView *)delegate {
	
	self = [super init];
	if (self != nil) {
		
		viewDelegate = delegate;
		currentSyncType = SYNC_ERROR_OK;
		wasSyncedAfterPODisplayed = FALSE;
		currentUnsyncCount = 0;
		totalUnsyncCount = 0;

		[self setContentSizeForViewInPopover:CGSizeMake(viewDelegate.optionsPOViewWidthExpanded, viewDelegate.optionsPOViewHeight)];
		
		lastSyncLabel = [[[UILabel alloc] initWithFrame:CGRectMake(10, 15, 290, 20)] autorelease];
		lastSyncLabel.text = [NSString stringWithString:[self lastSyncString]];
		lastSyncLabel.font = [UIFont fontWithName:@"Helvetica" size:16.0];
        lastSyncLabel.textAlignment = TPTextAlignmentCenter;
		
		unsyncedLabel = [[[UILabel alloc] initWithFrame:CGRectMake(10, 50, 290, 20)] autorelease];
		unsyncedLabel.text = [NSString stringWithString:[self unsyncedString]];
		unsyncedLabel.font = [UIFont fontWithName:@"Helvetica" size:16.0];
        unsyncedLabel.textAlignment = TPTextAlignmentCenter;
		
		syncStatusLabel = [[[UILabel alloc] initWithFrame:CGRectMake(10, 85, 290, 20)] autorelease];
		syncStatusLabel.text = [NSString stringWithString:[self syncStatusString]];
		syncStatusLabel.font = [UIFont fontWithName:@"Helvetica" size:16.0];
        syncStatusLabel.textAlignment = TPTextAlignmentCenter;
		
		syncButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
		[syncButton setFrame:CGRectMake(90, 125, 140, 30)];
		[syncButton addTarget:self action:@selector(syncAction:) forControlEvents:UIControlEventTouchUpInside];
		[syncButton setTitle:@"Sync Now" forState:UIControlStateNormal];
		[syncButton setTitle:@"Sync in progress" forState:UIControlStateDisabled];

		syncWarningIcon = [[UIImageView alloc] initWithFrame:CGRectMake(10, 83, 27, 24)];
		syncWarningIcon.image = [UIImage imageNamed:@"warning.png"];
		
		//syncWirelessIcon = [[UIImageView alloc] initWithFrame:CGRectMake(10, 83, 27, 24)];
		//syncWirelessIcon.image = [UIImage imageNamed:@"wireless.png"];
		
		[self.view addSubview:lastSyncLabel];
		[self.view addSubview:unsyncedLabel];
		[self.view addSubview:syncStatusLabel];
		[self.view addSubview:syncButton];
		[self.view addSubview:syncWarningIcon];
		//[self.view addSubview:syncWirelessIcon];
		[self.view setBackgroundColor:[UIColor whiteColor]];
        
        //self.navigationItem.title = @"Sync";
	}
	return self;
}

- (void) viewWillAppear:(BOOL)animated {
    //NSLog(@"TPSyncPO viewWillAppear");
	[super viewWillAppear:animated];
	wasSyncedAfterPODisplayed = FALSE;
    //NSLog(@"register options callback");
    [viewDelegate.model registerSyncStatusCallback:self :@selector(updateSyncStatusCallback:)];
	[self clearStatusUI:NO];
}

- (void) viewDidDisappear:(BOOL)animated {
    //NSLog(@"TPSyncPO viewDidDisappear");
    [super viewDidDisappear:(BOOL)animated];
    //[viewDelegate.model unregisterSyncStatusCallback];
}

- (void) updateStatusUI {
    if (debugSyncStatus) NSLog(@"TPSyncPO updateStatusUI");
	[self setUnsyncCounts];
	
	if (syncWarningIcon) {
		[syncWarningIcon setHidden:(currentSyncType != SYNC_ERROR_GENERAL && 
								  currentSyncType != SYNC_ERROR_LOGIN && 
								  currentSyncType != SYNC_ERROR_TIMEOUT)];
		if (currentSyncType == SYNC_ERROR_GENERAL) {
			[syncWarningIcon setFrame:CGRectMake(10, 83, 27, 24)];
		} else if (currentSyncType == SYNC_ERROR_LOGIN) {
			[syncWarningIcon setFrame:CGRectMake(82, 83, 27, 24)];
		} else if (currentSyncType == SYNC_ERROR_TIMEOUT) {
			[syncWarningIcon setFrame:CGRectMake(55, 83, 27, 24)];
		}
	}
	
	//if (syncWirelessIcon) {
	//	[syncWirelessIcon setHidden:(currentSyncType != SYNC_ERROR_WIFI)];
	//}
	
	if (syncButton) {
		// disabling sync button while sync is active
		[syncButton setEnabled:(currentSyncType == SYNC_ERROR_OK || 
								currentSyncType == SYNC_ERROR_GENERAL ||
								currentSyncType == SYNC_ERROR_LOGIN ||
								currentSyncType == SYNC_ERROR_TIMEOUT ||
								currentSyncType == SYNC_ERROR_WIFI)];
	}
	
	if (lastSyncLabel) {
		lastSyncLabel.text = [NSString stringWithString:[self lastSyncString]];
	}
	if (unsyncedLabel) {
		unsyncedLabel.text = [NSString stringWithString:[self unsyncedString]];
	}
	if (syncStatusLabel) {
        //NSLog(@"set status label");
		syncStatusLabel.text = [NSString stringWithString:[self syncStatusString]];
	}
}

- (void) clearStatusUI:(BOOL)forced {
    if (debugSyncStatus) NSLog(@"TPSyncPO clearStatusUI %d", forced);
    // If last sync was completed successfully or cancelled then clear status line
    if (currentSyncType == SYNC_ERROR_OK || forced) {
        [syncWarningIcon setHidden:YES];
        if (syncStatusLabel) { syncStatusLabel.text = @""; }
        if (forced) currentSyncType = SYNC_ERROR_OK;
    }
}

- (void) registerForSyncStatusCallback {
    //NSLog(@"register options 2 callback");
    [viewDelegate.model registerSyncStatusCallback:self :@selector(updateSyncStatusCallback:)];
}
	
- (void) setUnsyncCounts {
    if (debugSyncStatus) NSLog(@"TPSyncPO setUnsyncCounts");
	currentUnsyncCount = [viewDelegate.model getUnsyncedCount];
	if (currentSyncType == SYNC_ERROR_OK || 
		currentSyncType == SYNC_ERROR_GENERAL ||
		currentSyncType == SYNC_ERROR_LOGIN ||
		currentSyncType == SYNC_ERROR_TIMEOUT ||
		currentSyncType == SYNC_ERROR_WIFI) {
		// sync is complete
		totalUnsyncCount = currentUnsyncCount;
	} else {
		// sync in progress, skipping update of unsync value for status purposes
	}
}

// Formatting proper last sync description string
- (NSString *) lastSyncString {	
	NSDate *lastsync = viewDelegate.model.appstate.last_sync_completed;
	
	if (lastsync == NULL) {
		return @"Unknown date of last sync";
	}
	
	NSCalendar *calendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	NSDateComponents *components = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit|NSHourCalendarUnit|NSMinuteCalendarUnit|NSSecondCalendarUnit
											   fromDate:lastsync
												 toDate:[NSDate date]
												options:0];
	
	if ([components year])
		return [NSString stringWithFormat:@"Last sync %d years ago", [components year]];
	
	if ([components month])
		return [NSString stringWithFormat:@"Last sync %d months ago", [components month]];
	
	if ([components day])
		return [NSString stringWithFormat:@"Last sync %d days ago", [components day]];
	
	if ([components hour])
		return [NSString stringWithFormat:@"Last sync %d hours ago", [components hour]];
	
	if ([components minute])
		return [NSString stringWithFormat:@"Last sync %d minutes ago", [components minute]];
	
	if ([components second])
		return [NSString stringWithFormat:@"Last sync %d seconds ago", [components second]];
	else
		return @"Last sync seconds ago";
}

// Formatting proper unsynced items string
- (NSString *) unsyncedString {
	[self setUnsyncCounts];
	if (currentUnsyncCount) {
		return [NSString stringWithFormat:@"%d forms to be synced", currentUnsyncCount];
	} else {
		return @"No forms to be synced";
	}
}

// Formatting proper last sync status string
- (NSString *) syncStatusString {
    
	float uploadPercentage;
	
	switch (currentSyncType) {
		case SYNC_TYPE_USER:
			//return @"Syncing users: 0% complete";
            return @"0% complete(syncing users)";
			break;
		case SYNC_TYPE_INFO:
			//return @"Syncing user info: 16% complete";
            return @"16% complete (syncing user info)";
			break;
		case SYNC_TYPE_CATEGORY:
			//return @"Syncing categories: 32% complete";
            return @"32% complete (syncing categories)";
			break;
		case SYNC_TYPE_RUBRIC:
			//return @"Syncing forms: 48% complete";
            return @"48% complete (syncing forms)";
			break;
		case SYNC_TYPE_CLIENTDATA:
			uploadPercentage = (float)(totalUnsyncCount - currentUnsyncCount)/totalUnsyncCount*16;
			//return [NSString stringWithFormat:@"Uploading Data: %i%% complete", (int)(totalUnsyncCount?(64 + uploadPercentage):0)];
            return [NSString stringWithFormat:@"%i%% complete (upload data)", (int)(totalUnsyncCount?(64 + uploadPercentage):0)];
			break;
		case SYNC_TYPE_DATA:
			//return @"Downloading Data: 84% complete";
            return @"84% complete (download data)";
			break;
		case SYNC_ERROR_GENERAL:
			return wasSyncedAfterPODisplayed?@"An error occurred while syncing":@"";
			break;
		case SYNC_ERROR_WIFI:
			return wasSyncedAfterPODisplayed?@"WiFi connection error":@"";
			break;
		case SYNC_ERROR_TIMEOUT:
			return wasSyncedAfterPODisplayed?@"Connection timeout":@"";
			break;
		case SYNC_ERROR_LOGIN:
			return wasSyncedAfterPODisplayed?@"Login failed":@"";
			break;
		case SYNC_ERROR_OK:
			return wasSyncedAfterPODisplayed?@"Done: 100% complete":@"";
		default:
			return @"";
			break;
	}	
}

- (void) updateSyncStatusCallback:(int) syncType {
    if (debugSyncStatus) NSLog(@"TPSyncPO updateSyncStatusCallback %d", syncType);
	currentSyncType = syncType;
	wasSyncedAfterPODisplayed = TRUE;
	[self updateStatusUI];
}
	
- (void)syncAction:(id)sender {
    
	// Warn demo users
    if (viewDelegate.model.publicstate.is_demo == 1) {
        UIAlertView *waitAlert = [[UIAlertView alloc] initWithTitle:@""
                                                            message:@"Syncing the demo account will reset the account and erase your recorded data"
                                                           delegate:self
                                                  cancelButtonTitle:@"Sync Now"
                                                  otherButtonTitles:@"Cancel", nil];
        [waitAlert show];
        [waitAlert release];
        return;
    }
    
	[syncButton setEnabled:FALSE];
    [viewDelegate syncNow:SYNC_TYPE_USER];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    // Ignore if not logged in or in timeout
    // WARNING we shouldn't need this.  We should dismiss all alerts before entering background
    if ([viewDelegate.model.publicstate.state isEqualToString:@"install"] ||
        [viewDelegate.model.publicstate.state isEqualToString:@"timeout"]) return;
    
    // If user chooses to sync from alert popup then sync
    if (buttonIndex == 0) {
        [syncButton setEnabled:FALSE];
        [viewDelegate syncNow:SYNC_TYPE_USER];
    }
}

- (void) dealloc {
	[self release];
    [super dealloc];
}

@end


//------------------------------------------------------------------------------------------------
@implementation TPPreferencesPO

- (id) initWithViewDelegate:(TPView *)delegate {
	
	self = [super init];
	if (self != nil) {
		
		viewDelegate = delegate;
		
		[self setContentSizeForViewInPopover:CGSizeMake(viewDelegate.optionsPOViewWidthExpanded, viewDelegate.optionsPOViewHeight)];
		
		autoScrollingSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(230, 15, 100, 30)];
		[autoScrollingSwitch addTarget:self action:@selector(setAutoScrollingAction:) forControlEvents:UIControlEventValueChanged];
		
		autoScrollingLabel = [[[UILabel alloc] initWithFrame:CGRectMake(10, 15, 205, 30)] autorelease];
		autoScrollingLabel.text = @"Autoscroll questions";
		autoScrollingLabel.font = [UIFont fontWithName:@"Helvetica" size:15.0];
			
		autoCompressionSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(230, 55, 100, 30)];
		[autoCompressionSwitch addTarget:self action:@selector(setAutoCompressionAction:) forControlEvents:UIControlEventValueChanged];
		
		autoCompressionLabel = [[[UILabel alloc] initWithFrame:CGRectMake(10, 55, 205, 30)] autorelease];
		autoCompressionLabel.text = @"Autocompress questions";
		autoCompressionLabel.font = [UIFont fontWithName:@"Helvetica" size:15.0];
		
		useOwnDataSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(230, 95, 100, 30)];
		[useOwnDataSwitch addTarget:self action:@selector(setUseOwnDataAction:) forControlEvents:UIControlEventValueChanged];
		
		useOwnDataLabel = [[[UILabel alloc] initWithFrame:CGRectMake(10, 95, 205, 30)] autorelease];
		useOwnDataLabel.text = @"Only use own data";
		useOwnDataLabel.font = [UIFont fontWithName:@"Helvetica" size:15.0];
	
        showStatusSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(230, 135, 100, 30)];
		[showStatusSwitch addTarget:self action:@selector(setShowStatusAction:) forControlEvents:UIControlEventValueChanged];
		
		showStatusLabel = [[[UILabel alloc] initWithFrame:CGRectMake(10, 135, 215, 30)] autorelease];
		showStatusLabel.text = @"Show user form status";
		showStatusLabel.font = [UIFont fontWithName:@"Helvetica" size:15.0];
        
		[self.view addSubview:useOwnDataLabel];
		[self.view addSubview:useOwnDataSwitch];
		[self.view addSubview:autoScrollingLabel];
		[self.view addSubview:autoScrollingSwitch];
		[self.view addSubview:autoCompressionLabel];
		[self.view addSubview:autoCompressionSwitch];
        [self.view addSubview:showStatusSwitch];
		[self.view addSubview:showStatusLabel];
		[self.view setBackgroundColor:[UIColor whiteColor]];
        
        //self.navigationItem.title = @"Preferences";
	}
	return self;
}

- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[useOwnDataSwitch setOn:[viewDelegate.model useOwnData] animated:FALSE];
	[autoScrollingSwitch setOn:[viewDelegate.model autoScrolling] animated:FALSE];
	[autoCompressionSwitch setOn:[viewDelegate.model autoCompression] animated:FALSE];
    [showStatusSwitch setOn:[viewDelegate.model showStatus] animated:FALSE];
}

-(void) setUseOwnDataAction:(id)sender {
	[viewDelegate.model setUseOwnData:useOwnDataSwitch.on];
	[viewDelegate reloadReportList];
    [viewDelegate reloadUserdataList];
    [viewDelegate.model deriveUserDataInfo];
    [viewDelegate reloadUserList];
}

-(void) setAutoCompressionAction:(id)sender {
	[viewDelegate.model setAutoCompression:autoCompressionSwitch.on];
}

-(void) setAutoScrollingAction:(id)sender {
	[viewDelegate.model setAutoScrolling:autoScrollingSwitch.on];
}

-(void) setShowStatusAction:(id)sender {
	[viewDelegate.model setShowStatus:showStatusSwitch.on];
    [viewDelegate reloadUserList];
}

- (void) dealloc {
	[self release];
    [super dealloc];
}

@end

//------------------------------------------------------------------------------------------------


//------------------------------------------------------------------------------------------------
@implementation TPHelpPO

- (id) initWithViewDelegate:(TPView *)delegate {
	
	self = [super init];
	if (self != nil) {
		
        viewDelegate = delegate;
        
		[self setContentSizeForViewInPopover:CGSizeMake(viewDelegate.optionsPOViewWidthExpanded, viewDelegate.optionsPOViewHeight)];
		
		helpLabel = [[[UILabel alloc] initWithFrame:CGRectMake(10, 50, 290, 70)] autorelease];
		[helpLabel setText:@"Please visit our website for help resources, or to submit a support question."];
		[helpLabel setFont:[UIFont fontWithName:@"Helvetica" size:16.0]];
        [helpLabel setNumberOfLines:0];
        [helpLabel setTextAlignment:TPTextAlignmentCenter];
        [helpLabel setLineBreakMode:TPLineBreakByWordWrapping];
        
		[self.view addSubview:helpLabel];
		[self.view setBackgroundColor:[UIColor whiteColor]];
        
        //self.navigationItem.title = @"Help";
	}
	return self;
}

- (void) dealloc {
	[self release];
    [super dealloc];
}

@end

//------------------------------------------------------------------------------------------------