//
//  TPMaster.m
//  teachpoint
//
//  Created by Chris Dunn on 4/6/11.
//  Copyright 2011 Clear Pond Technologies, Inc. All rights reserved.
//

#import "TPData.h"
#import "TPView.h"
#import "TPModel.h"
#import "TPModelReport.h"
#import "TPMaster.h"
#import "TPUtil.h"
#import "TPModelSync.h"
#import "TPCompat.h"

#define STATUS_LABEL_TAG 10

@implementation TPMasterVC

// --------------------------------------------------------------------------------------
- (id)initWithView:(TPView *)mainview {
    
    self = [super init]; 
    if (self) {
        
        viewDelegate = mainview;
        
        current_cell = nil;
        
        self.title = @"";
		
        //customTable = [[UITableView alloc] initWithFrame:CGRectMake(0, 50, 320, 624) style:UITableViewStyleGrouped];
		customTable = [[UITableView alloc] initWithFrame:CGRectMake(0, 50, 320, 576) style:UITableViewStyleGrouped];
        customTable.delegate = self;
		customTable.dataSource = self;
        
        UISegmentedControl *customSortControl = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"Name", @"School", @"Grade", nil]];
        customSortControl.segmentedControlStyle = UISegmentedControlStyleBar;
        customSortControl.tintColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.9 alpha:0.3];
        customSortControl.frame = CGRectMake(10, 15, 260, 30);
        customSortControl.selectedSegmentIndex = 0;
        current_sort = TP_USER_SORT_NAME;
		[customSortControl sendActionsForControlEvents:UIControlEventValueChanged];
        [customSortControl addTarget:self action:@selector(sortUsersUIEvent) forControlEvents:UIControlEventValueChanged];
        
        UIView *backgroundView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 680)] autorelease];
        [backgroundView setBackgroundColor:[UIColor colorWithRed:226.0f/255.0f green:229.0f/255.0f blue:234.0f/255.0f alpha:1.0f]];
		[backgroundView addSubview:customTable];
        [backgroundView addSubview:customSortControl];
		
        UIImage *newButtonImage = [UIImage imageNamed:@"sync_green.png"];
        greenSyncButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [greenSyncButton setImage:newButtonImage forState:UIControlStateNormal];
        greenSyncButton.frame = CGRectMake(280.0, 15.0, newButtonImage.size.width, newButtonImage.size.height);
        [greenSyncButton addTarget:self action:@selector(syncpopup) forControlEvents:UIControlEventTouchUpInside];
        [backgroundView addSubview:greenSyncButton];
        
        newButtonImage = [UIImage imageNamed:@"sync_yellow.png"];
        yellowSyncButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [yellowSyncButton setImage:newButtonImage forState:UIControlStateNormal];
        yellowSyncButton.frame = CGRectMake(280.0, 15.0, newButtonImage.size.width, newButtonImage.size.height);
        [yellowSyncButton addTarget:self action:@selector(syncpopup) forControlEvents:UIControlEventTouchUpInside];
        [yellowSyncButton setHidden:YES];
        [backgroundView addSubview:yellowSyncButton];
        
        syncSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        syncSpinner.frame = CGRectMake(280.0, 15.0, 30.0, 30.0);
        [syncSpinner setHidden:YES];
        [backgroundView addSubview:syncSpinner];
        [syncSpinner release];
        
        table = customTable;
        sortControl = customSortControl;
        
        [self.view addSubview:backgroundView];
        
		headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 50)];
	
		UIImage *logoImage = [UIImage imageNamed:@"logo_master.png"];
        UIImageView *logoView = [[UIImageView alloc] initWithImage:logoImage];
        //logoView.frame = CGRectMake(0, -20, 260, 60);
        //[backgroundView addSubview:logoView];
        self.navigationItem.titleView = logoView;
        [logoView release];
        
        //jxi; Add tab bar
        tabControl = [[UITabBar alloc]initWithFrame:CGRectMake(0, 626, 320, 48)];
        UIImage *img1 = [[UIImage imageNamed:@"forms.png"] retain];
        UIImage *img2 = [[UIImage imageNamed:@"info.png"] retain];
        UIImage *img3 = [[UIImage imageNamed:@"reports.png"] retain];
        UIImage *img4 = [[UIImage imageNamed:@"camera.png"] retain];
        UIImage *img5 = [[UIImage imageNamed:@"cog.png"] retain];
        UITabBarItem *tab1 = [[UITabBarItem alloc] initWithTitle:@"" image:img1 tag:TP_TAB_STATE_RUBRICS];
        [tab1 setImageInsets:UIEdgeInsetsMake(6, 0, -6, 0)];
        UITabBarItem *tab2 = [[UITabBarItem alloc] initWithTitle:@"" image:img2 tag:TP_TAB_STATE_INFO];
        [tab2 setImageInsets:UIEdgeInsetsMake(6, 0, -6, 0)];
        UITabBarItem *tab3 = [[UITabBarItem alloc] initWithTitle:@"" image:img3 tag:TP_TAB_STATE_REPORTS];
        [tab3 setImageInsets:UIEdgeInsetsMake(6, 0, -6, 0)];
        UITabBarItem *tab4 = [[UITabBarItem alloc] initWithTitle:@"" image:img4 tag:TP_TAB_STATE_CAMERA];
        [tab4 setImageInsets:UIEdgeInsetsMake(6, 0, -6, 0)];
        UITabBarItem *tab5 = [[UITabBarItem alloc] initWithTitle:@"" image:img5 tag:TP_TAB_STATE_OPTIONS];
        [tab5 setImageInsets:UIEdgeInsetsMake(6, 0, -6, 0)];
        NSArray *itemsArray = [[NSArray alloc]initWithObjects:tab1,tab2,tab3,tab4,tab5,nil];
        //[tab1 setBadgeValue:@"1"];
        [tabControl setItems:itemsArray animated:YES];
        tabControl.delegate = self;
        [self.view addSubview:tabControl];
        [tabControl setSelectedItem:tab1];
        [tabControl setTintColor:[UIColor colorWithRed:0.3 green:0.3 blue:1.0 alpha:1.0]];
        prevTabItem = tab1;

        // Add sync button to display sync status
        [self resetPrompt];
                
        // Create a padlock icon image
		padlockImage = [[UIImage imageNamed:@"padlock.png"] retain];
    }
    return self;
}

// --------------------------------------------------------------------------------------
- (void)dealloc {
	[self release];
    [super dealloc];
}

- (void)loadView {
    //NSLog(@"TPMasterVC loadView");
    [super loadView];
	[self.view addSubview:headerView];
	[self.view insertSubview:table belowSubview:headerView];
}

- (void) viewDidLoad {
    //NSLog(@"TPMasterVC viewDidLoad");
    //[sortControl sendActionsForControlEvents:UIControlEventValueChanged];
    //sortControl.selectedSegmentIndex = 0;
    //[self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:YES scrollPosition:0];
}

- (void)viewDidUnload {
    //NSLog(@"TPMasterVC viewDidUnload");
    [super viewDidUnload];
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

// --------------------------------------------------------------------------------------
- (void)resetPrompt {
    self.navigationItem.prompt = [NSString stringWithFormat:@"%@ %@",
                                  viewDelegate.model.publicstate.first_name,
                                  viewDelegate.model.publicstate.last_name];
}

// --------------------------------------------------------------------------------------
// syncpopup - handle sync button press
// --------------------------------------------------------------------------------------
- (void) syncpopup {
    
    // Hide the popups
    [viewDelegate hidenew];
	if ([viewDelegate.optionsPOC isPopoverVisible]) [viewDelegate.optionsPOC  dismissPopoverAnimated:YES];
		
    // Warn demo user about losing data
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
    
    // Begin sync
    [viewDelegate syncNow:SYNC_TYPE_USER];
}

// --------------------------------------------------------------------------------------
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    // Ignore if not logged in or in timeout
    // WARNING we shouldn't need this.  We should dismiss all alerts before entering background
    if ([viewDelegate.model.publicstate.state isEqualToString:@"install"] ||
        [viewDelegate.model.publicstate.state isEqualToString:@"timeout"]) return;
    
    // If user chooses to sync from alert popup then sync
    if (buttonIndex == 0) {
        [viewDelegate syncNow:SYNC_TYPE_USER];
    }
}

// --------------------------------------------------------------------------------------
- (void) sortUsersUIEvent {
    
    if (debugMaster) NSLog(@"TPMaster sortUsersUIEvent");
    
    // Try to handle event (if not locked by sync process)
    if ([viewDelegate.model.uiSyncLock tryLock]) {
        if (debugMaster) NSLog(@"TPMaster sortUsersUIEvent EXECUTING");
        current_sort = sortControl.selectedSegmentIndex;
        [self sortUsers];
        [viewDelegate.model.uiSyncLock unlock];
    } else {
        if (debugMaster) NSLog(@"TPMaster sortUsersUIEvent BLOCKED");
        sortControl.selectedSegmentIndex = current_sort; // Reset to old value since can't respond
    }
}

// --------------------------------------------------------------------------------------
- (void) sortUsers {
    
    if (debugMaster) NSLog(@"TPMaster sortUsers");
    
    // Sort users based on segmented controler
	int index = sortControl.selectedSegmentIndex;
    //NSLog(@"sortUsers by segment %d when sort index %d", index, view.model.appstate.user_sort);
    switch (index) {
		case TP_USER_SORT_NAME:
		default:
			viewDelegate.model.appstate.user_sort = TP_USER_SORT_NAME;
			[viewDelegate.model.user_list sortUsingSelector:@selector(compareName:)];
			break;
		case TP_USER_SORT_SCHOOL:
			viewDelegate.model.appstate.user_sort = index;
			[viewDelegate.model.user_list sortUsingSelector:@selector(compareSchool:)];
			break;
		case TP_USER_SORT_GRADE:
			viewDelegate.model.appstate.user_sort = index;
			[viewDelegate.model.user_list sortUsingSelector:@selector(compareGrade:)];
			break;
    }
    
    // Deselect any cells
    NSIndexPath *indexpath = [table indexPathForSelectedRow];
	if (indexpath != nil) { [table deselectRowAtIndexPath:indexpath animated:NO]; }
    
    // Reload the table
    [table reloadData];
}

// --------------------------------------------------------------------------------------
// setNeedSyncButtonStateForStatus - 
// --------------------------------------------------------------------------------------
- (void) setNeedSyncButtonStateForStatus:(TPNeedSyncStatus)status {
    if (debugView) NSLog(@"TPMaster setNeedSyncButtonStateForStatus %d", status);
    // Set the color of the syncronisation icon
    if (status == NEEDSYNC_STATUS_SYNCED) {
        if ([syncSpinner isAnimating]) [syncSpinner stopAnimating];
        [syncSpinner setHidden:YES];
        [greenSyncButton setHidden:NO];
        [yellowSyncButton setHidden:YES];
    } else if (status == NEEDSYNC_STATUS_NOTSYNCED) {
        if ([syncSpinner isAnimating]) [syncSpinner stopAnimating];
        [syncSpinner setHidden:YES];
        [greenSyncButton setHidden:YES];
        [yellowSyncButton setHidden:NO];
    } else if (status == NEEDSYNC_STATUS_SYNCING) {
        [syncSpinner startAnimating];
        [syncSpinner setHidden:NO];
        [greenSyncButton setHidden:YES];
        [yellowSyncButton setHidden:YES];
    }
}

// --------------------------------------------------------------------------------------
- (void) reloadTableData {
    if (debugMaster) NSLog(@"TPMaster reloadTableData");
    [self sortUsers];
}

// --------------------------------------------------------------------------------------
- (int) getUserIndexFromIndexPath:(NSIndexPath *)indexPath {
	
    // Compute index of user (skip past other sections)
    int index = 0;
    if (viewDelegate.model.appstate.user_sort > 0) {
        for (int i = 0; i < [indexPath indexAtPosition:0]; i++) {
            switch (viewDelegate.model.appstate.user_sort) {
                case TP_USER_SORT_SCHOOL:
                    index += [[viewDelegate.model.school_list_lengths objectAtIndex:i] intValue];
                    break;
                case TP_USER_SORT_GRADE:
                    index += [[viewDelegate.model.grade_list_lengths objectAtIndex:i] intValue];
                    break;
            }
        }
    }
    index += [indexPath indexAtPosition:1];
    
    //NSLog(@"cell index for path %d %d is %d", [indexPath indexAtPosition:0], [indexPath indexAtPosition:1], index);
    
    return index;
}

// --------------------------------------------------------------------------------------
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration {
    if (debugRotate) NSLog(@"TPMaster willRotateToInterfaceOrientation");
}

- (void)viewWillLayoutSubviews {
    if (debugRotate) NSLog(@"TPMaster viewWillLayoutSubviews");
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration {
    if (debugRotate) NSLog(@"TPMaster willAnimateRotationToInterfaceOrientation");
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    if (debugRotate) NSLog(@"TPMaster didRotateFromInterfaceOrientation");
    if ([TPUtil isPortraitOrientation]) {
        [customTable setFrame:CGRectMake(0, 50, 320, 880)];
    } else {
        [customTable setFrame:CGRectMake(0, 50, 320, 624)];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    if (debugRotate) NSLog(@"TPMaster shouldAutorotateToInterfaceOrientation");
	return YES;
}

// ========================== UITableViewDataSource methods =============================

// --------------------------------------------------------------------------------------
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    switch (viewDelegate.model.appstate.user_sort) {
        case TP_USER_SORT_NAME:
            return 1;
        case TP_USER_SORT_SCHOOL:
            return viewDelegate.model.num_schools;
        case TP_USER_SORT_GRADE:
            return viewDelegate.model.num_grades;
    }
	return 0;
}

// --------------------------------------------------------------------------------------
- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (viewDelegate.model.appstate.user_sort) {
        case TP_USER_SORT_NAME:
            return @"All Users";
        case TP_USER_SORT_SCHOOL:
            return [viewDelegate.model.school_list objectAtIndex:section];
        case TP_USER_SORT_GRADE:
            return [viewDelegate.model.grade_list objectAtIndex:section];
    }
	return @"";
}

// --------------------------------------------------------------------------------------
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 40;
}

// --------------------------------------------------------------------------------------
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (viewDelegate.model.appstate.user_sort) {
        case TP_USER_SORT_NAME:
            return [viewDelegate.model.user_list count];
        case TP_USER_SORT_SCHOOL:
            return [[viewDelegate.model.school_list_lengths objectAtIndex:section] intValue];
        case TP_USER_SORT_GRADE:
            return [[viewDelegate.model.grade_list_lengths objectAtIndex:section] intValue];
    }
	return 0;
}

// --------------------------------------------------------------------------------------
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
    if (debugMaster) NSLog(@"TPMaster cellForRowAtIndexPath %d %d", [indexPath section], [indexPath row]);
    
    // Get a reusable cell if one exists
    int index = [self getUserIndexFromIndexPath:indexPath];
	TPUser *user = [viewDelegate.model.user_list objectAtIndex:index];
    NSString *gradeString = [user getGradeStringShort];
    
    // Identifier includes all info - this forces cell to be recreated if info changes
	NSString *CellIdentifier = [NSString stringWithFormat:@"%d/%d/%@/%@/%@/%@/%d", user.user_id, current_sort, user.first_name,
                                user.last_name, user.schools, gradeString, user.permission];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: CellIdentifier];
	    
    // Check of this cell corresponds to the current target user
    if (user.user_id == viewDelegate.model.appstate.target_id) {
        if (debugMaster) NSLog(@"TPMaster set current cell");
        [current_cell release];
        current_cell = [indexPath retain];
        [self highlightTargetUser];
    }
    
	// Otherwise create a new cell
    if (cell == nil) {
        
        //NSLog(@"new cell for user %d permission %d", user.user_id, user.permission);
        
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
		cell.textLabel.text = [user getDisplayName];
        NSString *detailString = @"";
        switch (current_sort) {
            case TP_USER_SORT_NAME:
            case TP_USER_SORT_SCHOOL:
                if (user.grade_min != 0 && user.grade_max != 0) {
                    detailString = [NSString stringWithFormat:@"%@ %@", user.schools, gradeString];
                } else {
                    detailString = [NSString stringWithFormat:@"%@ %@", user.schools, gradeString];
                }
                break;
            case TP_USER_SORT_GRADE:
                detailString = [NSString stringWithFormat:@"%@", user.schools];
                break;
            /*
            case TP_USER_SORT_SCHOOL:
                if (user.grade_min != 0 && user.grade_max != 0) {
                  detailString = [NSString stringWithFormat:@"%@", gradeString];
                }
                break;
            */
        }
        if ([detailString length] > 33) {
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@...", [detailString substringToIndex:30]];
        } else {
            cell.detailTextLabel.text = detailString;
        }
        
        // If can record for this user
        if (user.permission == TP_PERMISSION_VIEW_AND_RECORD ||
            user.permission == TP_PERMISSION_RECORD) {
            /*
			 UILabel *accLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 40, 20)];
			 accLabel.text = @"Rec";
			 accLabel.textColor = [UIColor colorWithRed:0.7 green:0.6 blue:0.0 alpha:1.0];
			 accLabel.backgroundColor = [UIColor clearColor];
			 accLabel.font = [UIFont fontWithName:@"Helvetica" size:16.0];
			 accLabel.textAlignment = UITextAlignmentRight;
			 cell.accessoryView = accLabel;
             */
            //cell.accessoryType = UITableViewCellAccessoryCheckmark;
            cell.accessoryType = UITableViewCellAccessoryNone;
            //NSLog(@"set none");
            
        // Otherwise can only view user
        } else {
            //cell.accessoryType = UITableViewCellAccessoryNone;
            UIImageView *padlock = [[UIImageView alloc] initWithImage:padlockImage];
            padlock.frame = CGRectMake(0, 0, 15, 22);
            cell.accessoryView = padlock;
            [padlock release];
            //NSLog(@"set padlock");
        }
        
		UIFont *font = [UIFont fontWithName:@"Helvetica" size:20.0];
	    cell.textLabel.font = font;
        font = [UIFont fontWithName:@"Helvetica" size:14.0];
	    cell.textLabel.font = font;
   
        UILabel *statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(205, 15, 100, 30)];
		statusLabel.text = [NSString stringWithFormat:@"%@ (%d)", [TPUtil formatElapsedTime:[user total_elapsed] :FALSE], [user total_forms]];
		statusLabel.backgroundColor = [UIColor clearColor];
		statusLabel.font = [UIFont fontWithName:@"Helvetica" size:14.0];
		statusLabel.textAlignment = TPTextAlignmentRight;
        statusLabel.highlightedTextColor = [UIColor whiteColor];
        statusLabel.tag = STATUS_LABEL_TAG;
        statusLabel.hidden = ![viewDelegate.model showStatus] || user.permission == TP_PERMISSION_VIEW;;
        [cell addSubview:statusLabel];
        [statusLabel release];
        
    } else {
        UILabel *statusLabel = (UILabel *)[cell viewWithTag:STATUS_LABEL_TAG];
        statusLabel.hidden = ![viewDelegate.model showStatus] || user.permission == TP_PERMISSION_VIEW;
        statusLabel.text = [NSString stringWithFormat:@"%@ (%d)", [TPUtil formatElapsedTime:[user total_elapsed] :FALSE], [user total_forms]];
    }

    return cell;
}

// --------------------------------------------------------------------------------------
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    //NSLog(@"willDisplayCell %d %d", [indexPath indexAtPosition:0], [indexPath indexAtPosition:1]);
}

// ========================== UITableViewDelegate methods ===============================

// --------------------------------------------------------------------------------------
- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
        
    // Try to handle event (if UI not locked by sync process)
    if ([viewDelegate.model.uiSyncLock tryLock]) {
        
        if (debugMaster) NSLog(@"TPMaster didSelectRowAtIndexPath EXECUTING");
        int index = [self getUserIndexFromIndexPath:indexPath];
        [viewDelegate returnFromOpenedView];
        viewDelegate.model.appstate.target_id = ((TPUser *)[viewDelegate.model.user_list objectAtIndex:index]).user_id;
        [viewDelegate selectTargetAtIndex:index];
        [viewDelegate reloadUserdataList];
        [current_cell release];
        current_cell = [indexPath retain];        
        [viewDelegate.model.uiSyncLock unlock];
        
    } else {
        // Otherwise deselect user since UI is locked
        if (debugMaster) NSLog(@"TPMaster didSelectRowAtIndexPath BLOCKED");
        [table deselectRowAtIndexPath:indexPath animated:NO];
    }
    
}

// --------------------------------------------------------------------------------------
// Select the cell corresponding to the subject
- (void) highlightTargetUser {
    
    if (debugMaster) NSLog(@"TPMaster highlightTargetUser");
    
    if (current_cell != nil) {
        if (debugMaster) NSLog(@"TPMaster highlightTargetUser for %d %d", [current_cell section], [current_cell row]);
        [table selectRowAtIndexPath:current_cell animated:NO scrollPosition:UITableViewScrollPositionNone];
    }
}

// ========================== UITabBarDelegate methods ==================================
// --------------------------------------------------------------------------------------
// jxi; didSelectItem - called when a tab item clicked
// --------------------------------------------------------------------------------------
- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{
    if (debugMaster) NSLog(@"TPMaster didSelectItem");
    if (item.tag == TP_TAB_STATE_OPTIONS) {
        [viewDelegate popOptionsPO];
        if ([viewDelegate.optionsPOC isPopoverVisible]) {
            [viewDelegate.optionsPOC  dismissPopoverAnimated:YES];
        } else {
            [viewDelegate.optionsPOC
             presentPopoverFromBarButtonItem:(UIBarButtonItem *)item
             permittedArrowDirections:UIPopoverArrowDirectionAny
             animated:YES];
        }
    } else {
        
        if (item.tag == TP_TAB_STATE_CAMERA) {
            viewDelegate.cameraButtonClickedState = TP_CAMERA_FROM_TAB;
        }
        [viewDelegate switchView:item.tag];
    }

    if (item.tag == TP_TAB_STATE_CAMERA || item.tag == TP_TAB_STATE_OPTIONS) {
        
        [tabControl setSelectedItem:prevTabItem];
    } else {
        
        prevTabItem = item;
    }
}

@end

