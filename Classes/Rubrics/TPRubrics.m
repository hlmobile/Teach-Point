//
//  TPRubrics.m
//  teachpoint
//
//  Created by Chris Dunn on 4/6/11.
//  Copyright 2011 Clear Pond Technologies, Inc. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "TPData.h"
#import "TPView.h"
#import "TPStyle.h"
#import "TPModel.h"
#import "TPModelReport.h"
#import "TPRubrics.h"
#import "TPRubricQCellHeading.h"
#import "TPRubricQCellInstructions.h"
#import "TPRubricQCellText.h"
#import "TPRubricQCellRating.h"
#import "TPRubricQCellMultiSelect.h"
#import "TPRubricQCellSignature.h"
#import "TPRubricQCellTimer.h"
#import "TPRubricQCellMultiSelectCumulative.h"
#import "TPRubricQCellDate.h"
#import "TPRubricQCellUnknown.h"
#import "TPGradePO.h"
#import "TPUtil.h"
#import "TPDatabase.h"
#import "TPCompat.h"
#import "TPModelSync.h" //jxi
#import "TPAttachListVC.h" //jxi;
#import "TPAttachListPO.h" //jxi;
#import "TPVideoPreview.h" //jxi;
#import <MediaPlayer/MediaPlayer.h> //jxi;

// --------------------------------------------------------------------------------------
// TPRubricVC - renders form from definition and data
// --------------------------------------------------------------------------------------
@implementation TPRubricVC

//jxi Image and video Preview
@synthesize imagePreviewVC;
@synthesize previewVC;
@synthesize videoPreviewVC; //jxi;
@synthesize videoVC; //jxi;
@synthesize preview_userdataid;
@synthesize questionCells;
@synthesize openTextView;
@synthesize cur_attachlistVC; //jxi;

- (id)initWithView:(TPView *)mainview {

    if (debugRubric) NSLog(@"TPRubricVC initWithView");
    
    self = [super init];
    if (self) {
        
        viewDelegate = mainview;
        
        self.title = @"";
        openTextView = nil;
        
		// predefined cell array
        questionCells = [[NSMutableArray alloc] init];
		
        rightbutton = [[UIBarButtonItem alloc] 
                       initWithTitle:@"Done" 
                       style: UIBarButtonItemStylePlain
                       target: viewDelegate 
                       action: @selector(rubricDoneEditing)];
		self.navigationItem.rightBarButtonItem = rightbutton;
        self.navigationItem.hidesBackButton = YES;
        
        expandController = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"Outline", @"Expand", nil]];
        //expandController = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"Outline", @"Expand", @"Attach", nil]]; //jxi;
        expandController.segmentedControlStyle = UISegmentedControlStyleBar;
        //expandController.frame = CGRectMake(0, 0, 120, 30);
        expandController.frame = CGRectMake(0, 0, 180, 30);
        expandController.selectedSegmentIndex = 1;
        [expandController addTarget:self action:@selector(outlineMode) forControlEvents:UIControlEventValueChanged];
        UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithCustomView:expandController];
        self.navigationItem.leftBarButtonItem = button;
        [button release];
        
        //jxi; Attachment Handling: Create attachmentlist pop-up window
        attachlistPO = [[TPAttachListPO alloc] initWithViewDelegate:viewDelegate];
        attachlistPOC = [[UIPopoverController alloc] initWithContentViewController:attachlistPO];
        [attachlistPOC setPopoverContentSize:CGSizeMake(300, 260)];
        
        // Setup header
        self.navigationItem.prompt = @"";
        headerView = [[TPRubricHeader alloc] initWithView:viewDelegate];
        self.navigationItem.titleView = headerView;
        self.tableView.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];

		// Setup subhheading
        subHeadingView = [[TPRubricQCellSubHeading alloc] initWithView:viewDelegate];
        self.tableView.tableHeaderView.frame = subHeadingView.frame;
        self.tableView.tableHeaderView = subHeadingView;
        /*
        if (![viewDelegate.model isRubricEditable:viewDelegate.model.appstate.rubric_id]) {
            self.tableView.tableHeaderView.frame = CGRectMake(0, 0, TP_QUESTION_CELL_WIDTH, 60);
        } else {
            self.tableView.tableHeaderView.frame = CGRectMake(0, 0, TP_QUESTION_CELL_WIDTH, 180);
        }
		*/
        
        // Set separator color to invisible
		//[self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
        // Set separator style/color to normal (light gray)
        [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
        
		self.tableView.dataSource = self;
        self.tableView.delegate = self;
        
        UIView *view1 = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, TP_QUESTION_CELL_WIDTH, 200)] autorelease];
        self.tableView.tableFooterView = view1;
        self.tableView.tableFooterView.frame = CGRectMake(0, 10, TP_QUESTION_CELL_WIDTH, 200);
        
        //jxi; Add attchlist button
        attachlistButton = [[UIButton alloc] initWithFrame:CGRectMake(TP_QUESTION_CELL_WIDTH_EFFECTIVE - 20, TP_QUESTION_AFTER_QUESTION_MARGIN, 30, 30)];
        attachlistImage = [UIImage imageNamed:@"paperclip.png"];
        [attachlistButton setImage:attachlistImage forState:UIControlStateNormal];
        [attachlistButton addTarget:self action:@selector(onAttachListButton) forControlEvents:UIControlEventTouchUpInside];
        [self.tableView.tableFooterView addSubview:attachlistButton];
        
        //jxi; Add attachment list
        attachListVC = [[TPAttachListVC alloc]initWithViewDelegate:viewDelegate
                                                            parent:self
                                                     containerType:TP_ATTACHLIST_CONTAINER_TYPE_FORM
                                              parentFormUserDataID:viewDelegate.model.appstate.userdata_id parentQuestionID:0];
        attachListVC.view.frame = CGRectMake(10, TP_QUESTION_AFTER_QUESTION_MARGIN, 320, attachListVC.attachListHeight);
        [self.tableView.tableFooterView addSubview:attachListVC.view
         ];
        
        [self updateAttachmentUI];
        
        //jxi; Get the current userdata
        TPUserData* userdata = [viewDelegate.model getCurrentUserData];
        if (userdata.state == TP_USERDATA_NODATA_STATE) {
            //jxi; If the userdata with nodata state, then preparing the spinning...
            formLoadingView = [[UIImageView alloc] init];
            [formLoadingView setFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
            [formLoadingView setAutoresizingMask:(UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth)];
            [formLoadingView setBackgroundColor:[UIColor blackColor]];
            [self.view addSubview:formLoadingView];
            
            formLoadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
            [formLoadingIndicator setFrame:CGRectMake((self.view.bounds.size.width - 44)/2, (self.view.bounds.size.height - 44)/2, 44, 44)];
            [formLoadingIndicator setAutoresizingMask:(UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin)];
            [self.tableView addSubview:formLoadingIndicator];
            [formLoadingIndicator startAnimating];

        }
	}
    return self;
}

- (void)dealloc {
    if (debugRubric) NSLog(@"TPRubricVC dealloc");
	if (questionCells) {
		[questionCells release];
		questionCells = nil;
	}
	[rightbutton release];
    [expandController release];
	[subHeadingView release];
    [headerView release];
    
    //jxi;
    if (formLoadingView) {
        [formLoadingView release];
        formLoadingView = nil;
    }
    
    //jxi;
    if (formLoadingIndicator) {
        [formLoadingIndicator release];
        formLoadingView = nil;
    }
    
    [super dealloc];
}

- (void)loadView {
    if (debugRubric) NSLog(@"TPRubricVC loadView");
    [super loadView];
    self.tableView.allowsSelection = NO;  // Don't allow selection of table cell
}

- (void)viewDidUnload {
    if (debugRubric) NSLog(@"TPRubricVC viewDidUnload");
    [super viewDidUnload];
}

- (void)viewDidAppear:(BOOL)animated {
    if (debugRubric) NSLog(@"TPRubricVC viewDidAppear");
    viewDelegate.model.currentMainViewState = @"rubric";
    //NSLog(@"currentMainViewState = %@", viewDelegate.model.currentMainViewState);
}

- (void)didReceiveMemoryWarning {
    if (debugRubric) NSLog(@"TPRubricVC didReceiveMemoryWarning");
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

// --------------------------------------------------------------------------------------
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration {
    if (debugRotate) NSLog(@"TPRubricVC willRotateToInterfaceOrientation");
}

- (void)viewWillLayoutSubviews {
    if (debugRotate) NSLog(@"TPRubricVC viewWillLayoutSubviews");
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration {
    if (debugRotate) NSLog(@"TPRubricVC willAnimateRotationToInterfaceOrientation");
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    if (debugRotate) NSLog(@"TPRubricVC didRotateFromInterfaceOrientation");
    [self updateCellsUI]; // Resize table cells immediately after rotation (based on current orientation)
    
    [self updateAttachmentUI];
}

// --------------------------------------------------------------------------------------
// jxi;
// --------------------------------------------------------------------------------------
- (void)updateAttachmentUI {
    if (debugRotate) NSLog(@"TPRubricVC updateAttachmentUI");
    
    float aCellWidth = 0.0;
    if ([TPUtil isPortraitOrientation]) {
        aCellWidth = TP_QUESTION_CELL_WIDTH_EFFECTIVE + 65;
    } else {
        aCellWidth = TP_QUESTION_CELL_WIDTH_EFFECTIVE;
    }
    
    [attachlistButton setFrame:CGRectMake(aCellWidth - 20, TP_QUESTION_AFTER_QUESTION_MARGIN, 30, 30)];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    if (debugRotate) NSLog(@"TPRubricVC shouldAutorotateToInterfaceOrientation");
    return YES;
}

// --------------------------------------------------------------------------------------
// UITableViewDataSource methods
// --------------------------------------------------------------------------------------
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

// --------------------------------------------------------------------------------------
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [viewDelegate.model.question_list count];
}

// --------------------------------------------------------------------------------------
- (TPRubricQCell *)customCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (debugRubric) NSLog(@"TPRubricVC customCellForRowAtIndexPath");
    
    TPQuestion *question = [viewDelegate.model.question_list objectAtIndex:indexPath.row];
    NSString *CellIdentifier = [NSString stringWithFormat:@"%@/%d/%@",
                                viewDelegate.model.appstate.userdata_id, question.order, question.title];

    //NSLog(@"---------- %d %d %@", (int)self, question.order, question.title);
    
	TPRubricQCell *cell = nil;
    
    BOOL isLast = NO;
    if (indexPath.row + 1 == [viewDelegate.model.question_list count]) isLast = YES;
    
	if (indexPath.row < [questionCells count]) {
		cell = [questionCells objectAtIndex:indexPath.row];
	}
	
	if (cell == nil) {	
        if (question.subtype != TP_QUESTION_SUBTYPE_NORMAL &&
            question.subtype != TP_QUESTION_SUBTYPE_REFLECTION &&
            question.subtype != TP_QUESTION_SUBTYPE_THIRDPARTY &&
            question.subtype != TP_QUESTION_SUBTYPE_READONLY &&
            question.subtype != TP_QUESTION_SUBTYPE_COMPUTED) {
         
            cell = [[[TPRubricQCellUnknown alloc] initWithView:viewDelegate 
                                                         style:UITableViewCellStyleDefault 
                                               reuseIdentifier:CellIdentifier 
                                                      question:question
                                                        isLast:isLast] autorelease];
            return cell;
        } else {
            switch (question.type) {
                case TP_QUESTION_TYPE_HEADING:
                    cell = [[[TPRubricQCellHeading alloc] initWithView:viewDelegate 
                                                                 style:UITableViewCellStyleDefault 
                                                       reuseIdentifier:CellIdentifier 
                                                              question:question] autorelease];
                    break;
                case TP_QUESTION_TYPE_INSTRUCTIONS:
                    cell = [[[TPRubricQCellInstructions alloc] initWithView:viewDelegate 
                                                                      style:UITableViewCellStyleDefault 
                                                            reuseIdentifier:CellIdentifier 
                                                                   question:question
                                                                     isLast:isLast] autorelease];
                    break;
                case TP_QUESTION_TYPE_TEXT:
                    cell = [[[TPRubricQCellText alloc] initWithView:viewDelegate 
                                                              style:UITableViewCellStyleDefault 
                                                    reuseIdentifier:CellIdentifier
                                                           question:question
                                                             isLast:isLast] autorelease];
                    break;
                case TP_QUESTION_TYPE_RATING:
                    cell = [[[TPRubricQCellRating alloc] initWithView:viewDelegate
                                                                style:UITableViewCellStyleDefault 
                                                      reuseIdentifier:CellIdentifier
                                                             question:question
                                                               isLast:isLast] autorelease];
                    break;
                case TP_QUESTION_TYPE_UNISELECT:
                case TP_QUESTION_TYPE_MULTISELECT:
                    cell = [[[TPRubricQCellMultiSelect alloc] initWithView:viewDelegate 
                                                                     style:UITableViewCellStyleDefault 
                                                           reuseIdentifier:CellIdentifier
                                                                  question:question
                                                                    isLast:isLast] autorelease];
                    break;
                case TP_QUESTION_TYPE_SIGNATURE_RESTRICTED:
                    cell = [[[TPRubricQCellSignature alloc] initWithView:viewDelegate 
                                                                   style:UITableViewCellStyleDefault 
                                                         reuseIdentifier:CellIdentifier
                                                                question:question
                                                                  isLast:isLast] autorelease];
                    break;
                case TP_QUESTION_TYPE_TIMER:
                    cell = [[[TPRubricQCellTimer alloc] initWithView:viewDelegate 
                                                               style:UITableViewCellStyleDefault 
                                                     reuseIdentifier:CellIdentifier
                                                            question:question
                                                              isLast:isLast] autorelease];
                    break;
                case TP_QUESTION_TYPE_MULTISELECT_CUMULATIVE:
                    cell = [[[TPRubricQCellMultiSelectCumulative alloc] initWithView:viewDelegate 
                                                                               style:UITableViewCellStyleDefault 
                                                                     reuseIdentifier:CellIdentifier
                                                                            question:question
                                                                              isLast:isLast] autorelease];
                    break;
                case TP_QUESTION_TYPE_DATE:
                    cell = [[[TPRubricQCellDate alloc] initWithView:viewDelegate 
                                                              style:UITableViewCellStyleDefault 
                                                    reuseIdentifier:CellIdentifier 
                                                           question:question 
                                                             isLast:isLast] autorelease];
                    break;
                case TP_QUESTION_TYPE_TIME:
                    cell = [[[TPRubricQCellTime alloc] initWithView:viewDelegate 
                                                              style:UITableViewCellStyleDefault 
                                                    reuseIdentifier:CellIdentifier 
                                                           question:question 
                                                             isLast:isLast] autorelease];
                    break;
                case TP_QUESTION_TYPE_DATE_TIME:
                    cell = [[[TPRubricQCellDateTime alloc] initWithView:viewDelegate 
                                                                  style:UITableViewCellStyleDefault 
                                                        reuseIdentifier:CellIdentifier 
                                                               question:question 
                                                                 isLast:isLast] autorelease];
                    break;

                default:
                    cell = [[[TPRubricQCellUnknown alloc] initWithView:viewDelegate 
                                                                 style:UITableViewCellStyleDefault 
                                                       reuseIdentifier:CellIdentifier 
                                                              question:question
                                                                isLast:isLast] autorelease];
                    break;
                    
            }
        }
    }
    return cell;
}

// --------------------------------------------------------------------------------------
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (debugRubric) NSLog(@"TPRubricVC cellForRowAtIndexPath");
	UITableViewCell *cell = nil;
	
	if ([viewDelegate.model.question_list count]) {
		TPQuestion *question = [viewDelegate.model.question_list objectAtIndex:indexPath.row];
		NSString *CellIdentifier = [NSString stringWithFormat:@"%@/%d/%@",
									viewDelegate.model.appstate.userdata_id, question.order, question.title];
        
		cell = [tableView dequeueReusableCellWithIdentifier: CellIdentifier];
	}
	
	if (cell == nil) {
		cell = [questionCells objectAtIndex:indexPath.row];
	}
    
    return cell;
}

// ========================== UITableViewDelegate methods ===============================

// --------------------------------------------------------------------------------------
// heightForRowAtIndexPath - return cell height at indexpath.  Generate the cell
// if not yet created.
// --------------------------------------------------------------------------------------
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    //if (debugRubric) NSLog(@"TPRubricVC heightForRowAtIndexPath");
    
	UITableViewCell *cell = nil;
	if (indexPath.row < [questionCells count]) {
		cell = [questionCells objectAtIndex:indexPath.row];
	} else {
		cell = [self customCellForRowAtIndexPath:indexPath];
        if (debugRubric) NSLog(@"TPRubricVC heightForRowAtIndexPath change questionCells");
		[questionCells addObject:cell];
	}
    
    return ((TPRubricQCell *)cell).cellHeight;
}

// --------------------------------------------------------------------------------------
- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (debugRubric) NSLog(@"TPRubricVC didSelectRowAtIndexPath");
    // Do nothing
}

// --------------------------------------------------------------------------------------
// reset - reload form
// --------------------------------------------------------------------------------------
- (void) reset {

    if (debugRubric) NSLog(@"TPRubricVC reset");
    
    //TPUserData *userdata = [viewDelegate.model getUserDataFromListById:viewDelegate.model.appstate.userdata_id];
    TPUserData *userdata = [viewDelegate.model getCurrentUserData];
    
    NSString *prompt = [NSString stringWithFormat:@"%@  (%@)  by: %@", userdata.name,
                        [viewDelegate.model prettyStringFromDate:userdata.created],
                        [viewDelegate.model getUserName:userdata.user_id]];
    self.navigationItem.prompt = prompt;
    [headerView reset];
    [self.tableView reloadData];
}

// --------------------------------------------------------------------------------------
// updateElapsedTime - update elapsed time
// --------------------------------------------------------------------------------------
- (BOOL) updateElapsedTime {
	
    if (debugRubric) NSLog(@"TPRubricVC updateElapsedTime");
	
	TPRubric* rubric = [viewDelegate.model getCurrentRubric];
    TPUserData *userdata = [viewDelegate.model getCurrentUserData];
	
	if (rubric.rec_elapsed &&
        [viewDelegate.model userOwnsUserdata] &&
        subHeadingView.elapsedTime != userdata.elapsed) {
        
		[viewDelegate.model updateUserDataElapsed:subHeadingView.elapsedTime];
	}
	
	return (subHeadingView.elapsedTime != 0);
}

// --------------------------------------------------------------------------------------
// finalizeRubricCells - 
// --------------------------------------------------------------------------------------
- (void) finalizeRubricCells:(BOOL) forceClose {
    
	if (debugRubric) NSLog(@"TPRubric finalizeRubricCells BEGIN");
    
    NSArray *tempCellArray = [NSArray arrayWithArray:questionCells];
    
	for (TPRubricQCell *cell in tempCellArray) {
        
        if (debugRubric) NSLog(@"TPView finalizeRubricCells %@", cell.reuseIdentifier);
        
		if ([cell isKindOfClass:[TPRubricQCellText class]]) {
			[((TPRubricQCellText*)cell) setForceClose:forceClose];
			[((TPRubricQCellText*)cell) dismissKeyboard];
            
		} else if ([cell isKindOfClass:[TPRubricQCellTimer class]]) {
            [((TPRubricQCellTimer*)cell) saveTime];
        }
        
        if ([cell isKindOfClass:[TPRubricQCellAnnotated class]]) {
			[((TPRubricQCellAnnotated*)cell) setAnnotForceClose:forceClose];
			[((TPRubricQCellAnnotated*)cell) dismissAnnotKeyboard];
		}
	}
    if (debugRubric) NSLog(@"TPRubric finalizeRubricCells END");
}

// --------------------------------------------------------------------------------------
// indexPathForQuestion - return indexpath for given question, using cached question cells
// --------------------------------------------------------------------------------------
- (NSIndexPath*) indexPathForQuestion: (TPQuestion*)question {
    if (debugRubric) NSLog(@"TPRubricVC indexPathForQuestion");
	for (TPRubricQCell *cell in questionCells) {
		if (cell.question.question_id == question.question_id) {
			return [self.tableView indexPathForCell:cell];
		}
	}
	return NULL;
}

// --------------------------------------------------------------------------------------
- (void) outlineMode {
    if (debugRubric) NSLog(@"TPRubricVC outlineMode");
    outline = expandController.selectedSegmentIndex;
    
    // cycling cells in this way to avoid 'collection was mutated while being enumerated' exception
    for (int i = 0; i < [questionCells count]; i++) {
        TPRubricQCell* cell = [questionCells objectAtIndex:i];
        [cell setCompressState:(expandController.selectedSegmentIndex != 1) :TRUE];
    }
}

// --------------------------------------------------------------------------------------
// jxi; onAttachListButton - called when the attach button clicked
// --------------------------------------------------------------------------------------
-(void) onAttachListButton {
    if (debugRubric) NSLog(@"TPRubricVC onAttachListButton");
    viewDelegate.cameraButtonClickedState = TP_CAMERA_FROM_RUBRIC;
    self.cur_attachlistVC = attachListVC;
    [self showAttachListPO:attachlistButton parentView:self.tableView.tableFooterView];
}

// --------------------------------------------------------------------------------------
// jxi; showAttachListPO - show attachment list pop-up window
// --------------------------------------------------------------------------------------
-(void) showAttachListPO:(UIButton *)attach_button parentView:(UIView *)view{
    if (debugRubric) NSLog(@"TPRubricVC showAttachListPO");
    if (!formLoadingIndicator) {
        if ([attachlistPOC isPopoverVisible]) {
            [attachlistPOC dismissPopoverAnimated:YES];
        } else {
            [attachlistPO reset];
            [attachlistPOC presentPopoverFromRect:attach_button.frame
                                       inView:view
                     permittedArrowDirections:UIPopoverArrowDirectionAny
                                     animated:YES];
        }
    } else {
        UIAlertView *waitAlert = [[UIAlertView alloc] initWithTitle:@""
                                                            message:@"Operation can't be performed during form loading" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
        [waitAlert show];
        [waitAlert release];
    }
}

// --------------------------------------------------------------------------------------
// jxi; Called when an attachment item in the attachment pop-up window clicked
// --------------------------------------------------------------------------------------
-(void) onAttachListPOItemClicked:(TPUserData *)userdata {
    
    if (debugRubric) NSLog(@"TPRubricVC onAttachListPOItemClicked");
    
    [attachlistPOC dismissPopoverAnimated:YES];
    
    if (userdata.type == TP_USERDATA_TYPE_IMAGE) {
     
        // Set current preview userdata_id
        self.preview_userdataid = userdata.userdata_id;
        
        // Get image
        TPImage *selectedImage = [viewDelegate.model getImageFromListById:preview_userdataid type:TP_IMAGE_TYPE_FULL];
        
        [viewDelegate.model setUserData:userdata];
        
        // If no image in memory then sync
        if (selectedImage == nil) {
            if ([viewDelegate.model syncIsSupended]) {
                // If syncing is suspended (currently executing another sync) then no action
                return;
            } else {
                // Otherwise sync image
                viewDelegate.model.remoteImageIDToSync = userdata.userdata_id;
                [viewDelegate syncNow:SYNC_TYPE_IMAGEDATA];
            }
        }
        
        // Display image
        [self showImagePreview:preview_userdataid];
        
    } else if (userdata.type == TP_USERDATA_TYPE_VIDEO) {
        // Set current preview userdata_id
        self.preview_userdataid = userdata.userdata_id;
        
        // Get video
        TPVideo *selectedVideo = [viewDelegate.model getVideoFromListById:preview_userdataid];
        
        [viewDelegate.model setUserData:userdata];
        
        // If no video in memory then sync
        if (selectedVideo == nil) {
            if ([viewDelegate.model syncIsSupended]) {
                // If syncing is suspended (currently executing another sync) then no action
                return;
            } else {
                // Otherwise sync image
                viewDelegate.model.remoteVideoIDToSync = userdata.userdata_id;
                [viewDelegate syncNow:SYNC_TYPE_VIDEODATA];
            }
        }
        // Display video
        [self showVideoPreview:preview_userdataid];
    }
}

// --------------------------------------------------------------------------------------
// jxi; showCameraView
// --------------------------------------------------------------------------------------
-(void)showCameraView {
    if (debugRubric) NSLog(@"TPRubricVC showCameraView");
    [attachlistPOC dismissPopoverAnimated:YES];
    [viewDelegate switchView:TP_VIEW_STATE_CAMERA];
}


// --------------------------------------------------------------------------------------
- (void) updateCellsUI {
    
    if (debugRubric) NSLog(@"TPRubricVC updateCellsUI");
    
    for (int i = 0; i < [questionCells count]; i++) {
        TPRubricQCell* cell = [questionCells objectAtIndex:i];
        [cell updateUI]; // Currently does nothing
        [cell updateModifiedCell];
    }
    
    [viewDelegate.rubricVC finalizeRubricCells:FALSE];
}

// --------------------------------------------------------------------------------------
- (BOOL) getOutline {
    if (debugRubric) NSLog(@"TPRubricVC getOutline");
    return (expandController.selectedSegmentIndex != 1);
}

// --------------------------------------------------------------------------------------
// jxi; remove the spining progress window and reset the form
// --------------------------------------------------------------------------------------
- (void) reloadForm {
    if (debugRubric) NSLog(@"TPRubricVC reloadForm");
    
    [self reset];
    
    // form loading indicator
    [formLoadingIndicator stopAnimating];
    [formLoadingIndicator removeFromSuperview];
    [formLoadingIndicator release];
    formLoadingIndicator = nil;
    
    // form loading view
    [formLoadingView removeFromSuperview];
    [formLoadingView release];
    formLoadingView = nil;
}

// --------------------------------------------------------------------------------------
// jxi;
// --------------------------------------------------------------------------------------
- (void) showImagePreview:(NSString *)userdata_id {
    if (debugRubric) NSLog(@"TPRubricVC showImagePreview");
    
    viewDelegate.preview_container_state = TP_PREVIEW_FOR_RUBRICVC; //jxi;
    
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

// --------------------------------------------------------------------------------------
- (void) resetPreview {
    if (debugRubric) NSLog(@"TPRubricVC resetPreview");
    if (self.presentedViewController) {
        TPUserData *userdata = [viewDelegate.model getUserDataFromListById:preview_userdataid];
        TPImage *image = [viewDelegate.model getImageFromListById:userdata.userdata_id type:TP_IMAGE_TYPE_FULL];
        [self.imagePreviewVC reloadImage:image.image name:userdata.name share:userdata.share description:userdata.description];
    }
}

// ============================ TPPreviewDelegate methods ===============================
// --------------------------------------------------------------------------------------
// donePreviewWithDeviceOrientation - call after quiting preview screen using done button
// --------------------------------------------------------------------------------------
- (void) donePreviewWithDeviceOrientation:(UIDeviceOrientation)orientation {
    if (debugRubric) NSLog(@"TPRubricVC donePreviewWithDeviceOrientation");
    self.imagePreviewVC = nil;
    [previewVC release];
    previewVC = nil;
    [self dismissViewControllerAnimated:YES completion:nil];
    //[view_delegate reloadUserdataList];
    [cur_attachlistVC reset];
}

// --------------------------------------------------------------------------------------
// jxi;
// --------------------------------------------------------------------------------------
- (void) savePreviewWithDeviceOrientation:(UIDeviceOrientation)orientation
                                imageName:(NSString *)aName
                                    share:(int)aShare
                              description:(NSString *)aDescription
                                  dismiss:(BOOL)dismiss {
    
    if (debugRubric) NSLog(@"TPRubricVC savePreviewWithDeviceOrientation");
    
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
        
        //[view_delegate reloadUserdataList];
        [viewDelegate.model deriveVideoList]; //jxi;
        [viewDelegate.model deriveImageList]; //jxi
        [viewDelegate.model deriveUserDataList]; //jxi
        
        [viewDelegate.model setNeedSyncStatus:NEEDSYNC_STATUS_NOTSYNCED forced:YES];
        [viewDelegate setSyncStatus];
    }
    
    //[previewAttachList reset]; //jxi
    //[cur_attachlistVC reset]; //jxi
    
    //jxi Get existing userdata of the parent form
    TPUserData *parentFormUserData = [viewDelegate.model getUserDataFromListById:newUserdata.aud_id];
    //jxi restore the current userdata as the parent recorded form's userdata
    [viewDelegate.model setUserData:parentFormUserData];
    
    [newUserdata release];
    
    // Dismiss if requested
    if (dismiss) {
        self.imagePreviewVC = nil;
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

// --------------------------------------------------------------------------------------
// jxi;
// --------------------------------------------------------------------------------------
- (void) trashPreviewWithDeviceOrientation:(UIDeviceOrientation)orientation {
    if (debugRubric) NSLog(@"TPRubricVC trashPreviewWithDeviceOrientation");
    [viewDelegate.model.database deleteUserData:preview_userdataid includingImages:YES];
    [viewDelegate reloadUserdataList];
    self.imagePreviewVC = nil;
    [previewVC release];
    previewVC = nil;
    [self dismissViewControllerAnimated:YES completion:nil];
}

// --------------------------------------------------------------------------------------
// jxi; Video Preview functions
// --------------------------------------------------------------------------------------
- (void)showVideoPreview:(NSString *)userdata_id {
    if (debugRubric) NSLog(@"TPRubricVC showVideoPreview");
    
    viewDelegate.preview_container_state = TP_PREVIEW_FOR_RUBRICVC; //jxi;
    
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
// jxi;
// --------------------------------------------------------------------------------------
- (void) resetVideoPreview {
    if (debugRubric) NSLog(@"TPRubricVC resetVideoPreview");
    if (self.presentedViewController) {
        TPUserData *userdata = [viewDelegate.model getUserDataFromListById:preview_userdataid];
        TPVideo *video = [viewDelegate.model getVideoFromListById:userdata.userdata_id];
        
        NSURL *fileURL = [NSURL fileURLWithPath:video.filename];
        
        [self.videoPreviewVC reloadVideo:fileURL name:userdata.name share:userdata.share description:userdata.description];
    }
}
// ============================= TPVideoPreviewDelegate ======================================

// --------------------------------------------------------------------------------------
- (void)trashVideoPreviewWithDeviceOrientation:(UIDeviceOrientation) orientation {
    
    if (debugRubric) NSLog(@"TPRubricVC trashPreviewWithDeviceOrientation");
    [viewDelegate.model.database deleteUserData:preview_userdataid includingImages:YES];
    [viewDelegate reloadUserdataList];
    self.videoPreviewVC = nil;
    [videoVC release];
    videoVC = nil;
    [self dismissViewControllerAnimated:YES completion:nil];
}

// --------------------------------------------------------------------------------------
- (void)doneVideoPreviewWithDeviceOrientation:(UIDeviceOrientation)orientation {
    
    if (debugRubric) NSLog(@"TPRubricVC donePreviewWithDeviceOrientation");
    self.videoPreviewVC = nil;
    [videoVC release];
    videoVC = nil;
    [self dismissViewControllerAnimated:YES completion:nil];
    [cur_attachlistVC reset];
}

// --------------------------------------------------------------------------------------
- (void)saveVideoPreviewWithDeviceOrientation:(UIDeviceOrientation) orientation
                                    imageName:(NSString *)aName
                                        share:(int)aShare
                                  description:(NSString *)aDescription
                                      dismiss:(BOOL)dismiss {
    
    if (debugRubric) NSLog(@"TPRubricVC saveVideoPreviewWithDeviceOrientation");
    
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
        
        //[viewDelegate reloadUserdataList];
        [viewDelegate.model deriveVideoList];//jxi;
        [viewDelegate.model deriveImageList];//jxi;
        [viewDelegate.model deriveUserDataList]; //jxi;
        
        [viewDelegate.model setNeedSyncStatus:NEEDSYNC_STATUS_NOTSYNCED forced:YES];
        [viewDelegate setSyncStatus];
    }
    
    //[previewAttachList reset]; //jxi
    //[cur_attachlistVC reset]; //jxi
    
    //jxi Get existing userdata of the parent form
    TPUserData *parentFormUserData = [viewDelegate.model getUserDataFromListById:newUserdata.aud_id];
    //jxi restore the current userdata as the parent recorded form's userdata
    [viewDelegate.model setUserData:parentFormUserData];
    
    [newUserdata release];
    
    // Dismiss if requested
    if (dismiss) {
        self.videoPreviewVC = nil;
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    
}

@end

// --------------------------------------------------------------------------------------
// TPRubricHeader - view used as header in rubric table
// --------------------------------------------------------------------------------------
@implementation TPRubricHeader

- (id)initWithView:(TPView *)mainview {
    
    if (debugRubric) NSLog(@"TPRubricHeader initWithView");
    
    self = [super init];
    if (self != nil) {
        
        viewDelegate = mainview;
        
        self.frame = CGRectMake(100, 0, 400, 40);
		
        // Target of evaluation
        target = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 400, 20)];
        target.text = @"";
        target.textColor = [UIColor darkGrayColor];
        target.backgroundColor = [UIColor clearColor];
        target.font = [UIFont fontWithName:@"Helvetica-Bold" size:17.0];
        target.textAlignment = TPTextAlignmentCenter;
        [self addSubview:target];
        
        // School
        school = [[UILabel alloc] initWithFrame:CGRectMake(0, 20, 400, 20)];
        school.text = @"";
        school.textColor = [UIColor darkGrayColor];
        school.backgroundColor = [UIColor clearColor];
        school.font = [UIFont fontWithName:@"Helvetica" size:14.0];
        school.textAlignment = TPTextAlignmentCenter;
        [self addSubview:school];
    }
    return self;
}

- (void) dealloc {
    [target release];
    [school release];
    [super dealloc];
}

// --------------------------------------------------------------------------------------
- (void) reset {
    if (debugRubric) NSLog(@"TPRubricHeader reset");
    // Fill with basic target user info
    TPUser *user = [viewDelegate.model getCurrentTarget];
    target.text = [NSString stringWithFormat:@"%@ %@", user.first_name, user.last_name];
    NSString *gradeString = [user getGradeString];
    school.text = [NSString stringWithFormat:@"%@ - Grade: %@ %@", user.schools, gradeString, user.subjects];
}

@end

// --------------------------------------------------------------------------------------
// TPRubricQCell - base class for table cell used to represent rubric questions
// --------------------------------------------------------------------------------------
@implementation TPRubricQCell

@synthesize cellHeight;
@synthesize question;
@synthesize canEdit;

// --------------------------------------------------------------------------------------
- (id) init {
    if (debugRubric) NSLog(@"TPRubricQCell init");
    self = [super init];
    if (self != nil) {
    }
    return self;
}

// --------------------------------------------------------------------------------------
// getTextColor - return text color based on whether can edit current question.
// --------------------------------------------------------------------------------------
+(UIColor *) getTextColor:(BOOL)canEdit {
    
    // CURENTLY DISABLED - ALL TEXT IS BLACK
    return [UIColor blackColor];
    
    if (canEdit) {
        return [UIColor blackColor];
    } else {
        return [UIColor darkGrayColor];
    }
}

// --------------------------------------------------------------------------------------
// updateModified - update cell and finalize all cells.
// --------------------------------------------------------------------------------------
- (void) updateModified {
    
    if (debugRubric) NSLog(@"TPRubricQCell updateModified %d", (int)self);
        
	[self updateModifiedCell];
	
	[viewDelegate.rubricVC finalizeRubricCells:FALSE];
}

// --------------------------------------------------------------------------------------
// updateModifiedCell - update cell based on type
// --------------------------------------------------------------------------------------
- (void) updateModifiedCell {
    
    if (debugRubric) NSLog(@"TPRubricQCell updateModifiedCell %d", (int)self);
    
	// updating cell height for text questions
	if ([self isKindOfClass:[TPRubricQCellText class]]) {
        
        // WARNING - why don't reload text???
		// do not reload cell if editing was forcefully stopped by pressing Done button
        if (![(TPRubricQCellText*)self forceClose]) {
			[self reloadCellAction];
		}
	}
	
	// updating cell height for rating, multiselect, cumulative multiselect questions
	if ([self isKindOfClass:[TPRubricQCellRating class]] ||
        [self isKindOfClass:[TPRubricQCellMultiSelect class]] ||
        [self isKindOfClass:[TPRubricQCellMultiSelectCumulative class]] ||
        [self isKindOfClass:[TPRubricQCellTimer class]] ||
        [self isKindOfClass:[TPRubricQCellDate class]] ||
        [self isKindOfClass:[TPRubricQCellTime class]] ||
        [self isKindOfClass:[TPRubricQCellDateTime class]]) {
		[self reloadCellAction];
	}
}

// --------------------------------------------------------------------------------------
// reloadCellAction - trick interface to redisplay cell by deleting and add cell back.
// --------------------------------------------------------------------------------------
- (void) reloadCellAction {
    
    if (debugRubric) NSLog(@"TPRubricQCell reloadCellAction %d", (int)self);
    
    TPRubricVC* rubricVC = viewDelegate.rubricVC;
	NSIndexPath *ipath = [rubricVC indexPathForQuestion:self.question];
    TPRubricQCell *deletedCell = [rubricVC.questionCells objectAtIndex:ipath.row];
    [rubricVC.questionCells removeObjectAtIndex:ipath.row];
    [self setFrame:CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, cellHeight)];
    [rubricVC.questionCells insertObject:deletedCell atIndex:ipath.row];
    [rubricVC.tableView reloadData];
}

// --------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------
- (void) scrollToNextAction {
    if (debugRubric) NSLog(@"TPRubricQCell scrollToNextAction");
	[viewDelegate.rubricVC.tableView setContentOffset:CGPointMake(0.0, self.frame.origin.y + self.frame.size.height) animated:TRUE];
}

// --------------------------------------------------------------------------------------
// jxi; showAttachListPO - show attachment list Pop up Window
// --------------------------------------------------------------------------------------
- (void) showAttachListPO {
    if (debugRubric) NSLog(@"TPRubricQCell showAttachListPO");
    
    viewDelegate.cameraButtonClickedState = TP_CAMERA_FROM_QUESTION;
    viewDelegate.rubricVC.cur_attachlistVC = attachListVC;
    [viewDelegate.rubricVC showAttachListPO:attachlistButton parentView:self];
}

// --------------------------------------------------------------------------------------
-(void) setCompressState:(BOOL)compress :(BOOL)outline {
    if (debugRubric) NSLog(@"TPRubricQCell setCompressState - DOES NOTHING");
    // default compression method. override for custom actions for different cell types 
}

// --------------------------------------------------------------------------------------
-(void) updateUI {
    if (debugRubric) NSLog(@"TPRubricQCell updateUI - DOES NOTHING");
    // default cell contents update handling method. override for custom actions for different cell types 
}

// --------------------------------------------------------------------------------------
- (void)reloadCell {
    if (debugRubric) NSLog(@"TPRubricQCell reloadCell");
    NSIndexPath *ipath = [viewDelegate.rubricVC indexPathForQuestion:self.question];
    if (ipath != nil) {
        NSArray *indexPaths = [NSArray arrayWithObject:ipath];
        [viewDelegate.rubricVC.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
        // This must be after reloadRowsAtIndexPaths (contrary to documentation), otherwise cell boundary not correct when keyboard appears
        [viewDelegate.rubricVC.tableView beginUpdates];
        [viewDelegate.rubricVC.tableView endUpdates];
    }
}

@end

// --------------------------------------------------------------------------------------
// TPRubricQCellAnnotated - base class for table cell for rubric question with annotation
// --------------------------------------------------------------------------------------
@implementation TPRubricQCellAnnotated : TPRubricQCell 

@synthesize annotText;
@synthesize annotButton;
@synthesize annotForceClose;
@synthesize annotEditable;

// --------------------------------------------------------------------------------------
- (id) init {
    if (debugRubric) NSLog(@"TPRubricQCellAnnotated init");
    self = [super init];
    if (self != nil) {
        annotForceClose = NO;
        [annotText setAutocorrectionType:UITextAutocorrectionTypeYes];
    }
    return self;
}

// --------------------------------------------------------------------------------------
- (void)toggleAnnotAction:(id)sender {
    if (debugRubric) NSLog(@"TPRubricQCellAnnotated toggleAnnotAction");
    showAnnotation = !showAnnotation;
    [self updateUI];
    [self updateModified];
}

// =============================== UITextViewDelegate ===================================

// --------------------------------------------------------------------------------------
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
	if (debugRubric) NSLog(@"TPRubricQCellAnnotated shouldChangeTextInRange %d", (int)textView);
    return [TPUtil shouldChangeTextInRange:range replacementText:text maxLength:10000];
}

// --------------------------------------------------------------------------------------
- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    
    if (debugRubric) NSLog(@"TPRubricQCellAnnotated textViewShouldBeginEditing %d", (int)textView);
    
    BOOL willEdit = [viewDelegate.model userCanEditQuestion:question];
    
    if (willEdit) {
        annotForceClose = NO;
        annotEditable = YES;
        [self updateUI];
        [self reloadCell];
    }
    
    return willEdit;
}

// --------------------------------------------------------------------------------------
- (void)textViewDidBeginEditing:(UITextView *)textView {
    if (debugRubric) NSLog(@"TPRubricQCellAnnotated textViewDidBeginEditing %d", (int)textView);
    viewDelegate.rubricVC.openTextView = textView; // Flag open text edit area
}

// --------------------------------------------------------------------------------------
- (BOOL)textViewShouldEndEditing:(UITextView *)textView {
    if (debugRubric) NSLog(@"TPRubricQCellAnnotated textViewShouldEndEditing %d %d", (int)textView, [viewDelegate.model isSetUILock]);
    if ([viewDelegate.model isSetUILock]) return NO;  // If lock set then ignore
	return YES;
}

// --------------------------------------------------------------------------------------
- (void)textViewDidEndEditing:(UITextView *)textView {
    
    if (debugRubric) NSLog(@"TPRubricQCellAnnotated textViewDidEndEditing  %d", (int)textView);
    
    annotEditable = NO;
    [viewDelegate.model updateUserDataText:question text:annotText.text isAnnot:1];
    
    showAnnotation = (!showAnnotation || ([annotText.text length] != 0));
    [self updateUI];
    [self reloadCell];
    
    [self.annotText setContentOffset:CGPointMake(0.0, 0.0) animated:TRUE];
    
	if ([self isKindOfClass:[TPRubricQCell class]] && [viewDelegate.model autoScrolling]) {
		[((TPRubricQCell*)self) scrollToNextAction];
	}
    
    viewDelegate.rubricVC.openTextView = nil; // Flag text editing as finished
}

// --------------------------------------------------------------------------------------
// dismissAnnotKeyboard - dismiss keyboard if this cell is first responder
// --------------------------------------------------------------------------------------
- (void)dismissAnnotKeyboard {
    if (debugRubric) NSLog(@"TPRubricQCellAnnotated dismissAnnotKeyboard");
    if ([annotText isFirstResponder]) {
        if (debugRubric) NSLog(@"TPRubricQCellAnnotated dismissAnnotKeyboard %@", self.reuseIdentifier);
        [annotText resignFirstResponder];
    }
}

@end

// --------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------
@implementation TPRubricQRatingCell

@synthesize selectedRating;

// --------------------------------------------------------------------------------------
- (void)addColumn:(CGFloat)position{
	if (!columns) {
		columns = [[NSMutableArray alloc] init];
	}
    [columns addObject:[NSNumber numberWithFloat:position]];
}

// --------------------------------------------------------------------------------------
- (void)resetColumns {
    if (columns) {
        [columns release];
        columns = 0;
    }
    columns = [[NSMutableArray alloc] init];
}

// --------------------------------------------------------------------------------------
- (void)drawRect:(CGRect)rect {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    // Use the same color and width as the default cell separator for now
    CGContextSetRGBStrokeColor(ctx, 0.67, 0.67, 0.67, 1.0);
    CGContextSetLineWidth(ctx, 1.0f);
	CGContextSetShouldAntialias(ctx, NO);
	
    for (int i = 0; i < [columns count] - 1; i++) {
        CGFloat f = [((NSNumber*) [columns objectAtIndex:i]) floatValue];
        CGContextMoveToPoint(ctx, f, 0);
        CGContextAddLineToPoint(ctx, f, self.frame.size.height);
    }
	
    CGContextStrokePath(ctx);
	
    [super drawRect:rect];
}

// --------------------------------------------------------------------------------------
- (void) touchesBegan: (NSSet *)touches withEvent: (UIEvent *)event {
	UITouch *touch = [touches anyObject];
	CGPoint pos = [touch locationInView: self];
	
	selectedRating = pos.x / self.frame.size.width * [columns count];
	
	[super touchesBegan:touches withEvent:event];
}

// --------------------------------------------------------------------------------------
- (void) dealloc {
	if (columns) {
		[columns release];
		columns = 0;
	}
	[super dealloc];
}


@end

// --------------------------------------------------------------------------------------
// Rubric scale question
// --------------------------------------------------------------------------------------
@implementation TPRubricQRatingTable

@synthesize showAnswers;
@synthesize ratingsCount;

// --------------------------------------------------------------------------------------
- (id) initWithView:(TPView *)mainview question:(TPQuestion *)somequestion frame:(CGRect)targetFrame{
    
    self = [super initWithFrame: targetFrame style:UITableViewStylePlain];
    if (self != nil) {
        
        viewDelegate = mainview;
        question = somequestion;
        
        self.delegate = self;
        self.dataSource = self;
        
        UIView *background = [[UIView alloc] init];
        self.backgroundView = background;
        [background release];
		
		ratingCells = [[NSMutableArray alloc] init];

        // Initialize ratingsCount, headerCellHeight, and contentCellHeight
		[self precalculateCellFrame:targetFrame.size.width];
        
		showAnswers = ![viewDelegate.model autoCompression] || [self shouldDisableCollapsing];
		[self setAnswers:showAnswers];
		
		CGRect customFrame = self.frame;
		customFrame.size.height = headerCellHeight + (showAnswers?contentCellHeight:0);
        
		[self setFrame:customFrame];
	    self.layer.borderWidth = 1;
        self.layer.borderColor = [[UIColor darkGrayColor] CGColor];
		self.separatorColor = [UIColor darkGrayColor];
    }
    return self;
}

// --------------------------------------------------------------------------------------
- (void) dealloc {
    [ratingCells release];
    [super dealloc];
}

// --------------------------------------------------------------------------------------
-(UIColor*) getBackgroundColor:(BOOL)isHeader :(BOOL)isSelected :(int)cellIndex {
	if (isHeader) {
		// header cell
		if (isSelected) {
			//showAnswers = FALSE;
			
			switch (cellIndex) {
				case 4:
				case 3:
					return [UIColor colorWithRed:102/255.0 green:255/255.0 blue:102/255.0 alpha:1];
					break;
				case 2:
					return [UIColor colorWithRed:255/255.0 green:255/255.0 blue:153/255.0 alpha:1];
					break;
				case 1:
					return [UIColor colorWithRed:241/255.0 green:74/255.0 blue:74/255.0 alpha:1];
					break;
				default:
					return [UIColor whiteColor];
					break;
			}
		}
		else {
			return [UIColor whiteColor];
		}
		
	} else {
		// content cell
		if (isSelected) {
			//showAnswers = FALSE;
			return [UIColor colorWithRed:238/255.0 green:238/255.0 blue:238/255.0 alpha:1];
		} else {
			return [UIColor whiteColor];
		}
	}
}

// --------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------
- (void) setAnswers:(BOOL)doShow {
    showAnswers = doShow;
    [self reloadData];
    [self setFrame:CGRectMake(self.frame.origin.x, 
                              self.frame.origin.y, 
                              self.frame.size.width, 
                              headerCellHeight + (doShow?contentCellHeight:0))];
    if ([self.superview.superview isKindOfClass:[TPRubricQCellRating class]]) {
        [((TPRubricQCellRating*)self.superview.superview) updateUI];
        [((TPRubricQCellRating*)self.superview.superview) updateModified];
    }
}

// --------------------------------------------------------------------------------------
-(void) precalculateCellFrame:(int)width {
	ratingsCount = 0;
	headerCellHeight = 0;
	contentCellHeight = 0;
	for (TPRating *rating in viewDelegate.model.rating_array) {
		if (rating.question_id == question.question_id) {
			ratingsCount++;
		}
	}
	
	if (ratingsCount == 0) {
		ratingsCount = 1;
	}
	
	int i = 0;
	
	for (TPRating *rating in viewDelegate.model.rating_array) {
		if (rating.question_id == question.question_id && i < ratingsCount) {
			CGSize constSize = CGSizeMake(width / ratingsCount - 3, 1000);
			CGSize contentCellSize = [rating.text sizeWithFont:[UIFont fontWithName:@"Helvetica-Oblique" size:16.0] 
										 constrainedToSize:constSize 
											 lineBreakMode:NSLineBreakByWordWrapping];
		
			NSString *titleText = [rating.title length]?rating.title:[TPRating getDefaultRatingScaleTitle:rating.rorder];
			CGSize headerCellSize = [titleText sizeWithFont:[UIFont fontWithName:@"Helvetica-Bold" size:16.0] 
										  constrainedToSize:constSize 
											  lineBreakMode:NSLineBreakByWordWrapping];
			
			if (headerCellHeight < headerCellSize.height + 10) {
				headerCellHeight = headerCellSize.height + 10;
			}
			
			if (contentCellHeight < contentCellSize.height + 30) {
				contentCellHeight = contentCellSize.height + 30;
			}
			i++;
		}
	}
}

// --------------------------------------------------------------------------------------
- (BOOL) shouldDisableCollapsing {
	for (int i = 0; i < ratingsCount; i++) {
		TPRating *rating = [viewDelegate.model getRatingByQuestionId:question.question_id order:i + 1];
		if ([viewDelegate.model ratingIsSelected:rating question:question]) {
			return FALSE;
		}
	}
	return TRUE;
}

// =============================== UITableViewDataSource ================================

// --------------------------------------------------------------------------------------
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    tableView.backgroundColor = [UIColor whiteColor];
    return 1;
}

// --------------------------------------------------------------------------------------
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // If cell not yet computed then compute and add to array
	if (indexPath.row >= [ratingCells count]) {
		UITableViewCell *cell = [self customCellForRowAtIndexPath:indexPath];
		[ratingCells addObject:cell];
	}

	if (indexPath.row == 0) {
		return headerCellHeight;
	} else {
		return showAnswers?contentCellHeight:0;	
	}	
}

// --------------------------------------------------------------------------------------
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return 2;
}

// --------------------------------------------------------------------------------------
- (TPRubricQRatingCell *)customCellForRowAtIndexPath:(NSIndexPath *)indexPath{
    TPRubricQRatingCell *cell = nil;
        
	if (indexPath.row < [ratingCells count]) {
		cell = [ratingCells objectAtIndex:indexPath.row];
	}
    
	if (cell == nil) {
    NSString *CellIdentifier = [NSString stringWithFormat:@"TPRubricQRatingTableCellId %i", indexPath.row];
		// cell = [[[TPRubricQRatingCell alloc] initWithFrame:CGRectZero reuseIdentifier: CellIdentifier] autorelease]; // Deprecated
        cell = [[[TPRubricQRatingCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
		[cell setSelectionStyle:UITableViewCellSelectionStyleNone];
		
		for (int i = 0; i < ratingsCount; i++) {
			int startPos = (int)((self.frame.size.width - 1)/ ratingsCount * i);
			int endPos = (int)((self.frame.size.width - 1)/ ratingsCount * (i + 1));
			[cell addColumn:endPos];
			
			UILabel *label;
			TPRating *rating = [viewDelegate.model getRatingByQuestionId:question.question_id order:i + 1];
			if (indexPath.row == 0) {
				// table header
				label = [[[UILabel alloc] initWithFrame:CGRectMake(startPos + 2, 2, endPos - startPos - 3, headerCellHeight - 4)] autorelease];
				UIColor *color = [self getBackgroundColor:YES :([viewDelegate.model ratingIsSelected:rating question:question])  :(ratingsCount - i)];
				if (color != [UIColor whiteColor]) {
					label.backgroundColor = color;
				}
				label.tag = TP_QUESTION_TYPE_RATING_CELL_LABEL_TAG + i;
				UIFont *font = [UIFont fontWithName: @"Helvetica-Bold" size: 16.0];
				label.font = font;
                if ([rating.title length] == 0) {
                    label.text = [TPRating getDefaultRatingScaleTitle:rating.rorder];
                } else {
                    label.text = rating.title;
                }
				label.textAlignment = TPTextAlignmentCenter;
				label.numberOfLines = 0;
				label.lineBreakMode = NSLineBreakByWordWrapping;
				
			} else {
				// table content
				label = [[[UILabel alloc] initWithFrame:CGRectMake(startPos + 2, 1, endPos - startPos - 3, contentCellHeight - 3)] autorelease];
				UIColor* color = [self getBackgroundColor:NO :([viewDelegate.model ratingIsSelected:rating question:question])  :(ratingsCount - i)];
				if (color != [UIColor whiteColor])
				{
					label.backgroundColor = color;
				}
				label.tag = TP_QUESTION_TYPE_RATING_CELL_LABEL_TAG + i;
				UIFont *font = [UIFont fontWithName: @"Helvetica-Oblique" size: 16.0];
				label.font = font;
				label.text = rating.text;
				label.numberOfLines = 0;
				label.lineBreakMode = NSLineBreakByWordWrapping;
			}
			
			[cell.contentView addSubview:label];
		}
    }
    return cell;
}

// --------------------------------------------------------------------------------------
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = nil;
	
	NSString *CellIdentifier = [NSString stringWithFormat:@"TPRubricQRatingTableCellId %i", indexPath.row];		
	cell = [tableView dequeueReusableCellWithIdentifier: CellIdentifier];

	if (cell == nil) {
		cell = [ratingCells objectAtIndex:indexPath.row];
	}
	
    return cell;
}

// =============================== UITableViewDelegate ==================================

// --------------------------------------------------------------------------------------
- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

	if ([viewDelegate.model isSetUILock]) return;  // If lock set then ignore input
    
    // Skip if user not allowed to edit
    if (![viewDelegate.model userCanEditQuestion:question]) return;
	
	int selectedRating = [(TPRubricQRatingCell*)[ratingCells objectAtIndex:[indexPath row]] selectedRating];
	
    TPRating *rating = [viewDelegate.model getRatingByQuestionId:question.question_id order:selectedRating + 1];
    BOOL cellIsSelected = NO;
    if ([viewDelegate.model ratingIsSelected:rating question:question]) {
        [viewDelegate.model updateUserDataRating:rating selected:FALSE];
        cellIsSelected = NO;
    } else {
        [viewDelegate.model updateUserDataRating:rating selected:TRUE];
        cellIsSelected = YES;
    }

	for (int rowId=0; rowId < [self numberOfRowsInSection:0]; rowId++) {
		for (int columnId=0; columnId < ratingsCount; columnId++) {
			TPRubricQRatingCell *cell = (TPRubricQRatingCell*)[ratingCells objectAtIndex:rowId];
			UILabel* label = (UILabel*) [cell viewWithTag:TP_QUESTION_TYPE_RATING_CELL_LABEL_TAG + columnId];
			UIColor* colorId = [self getBackgroundColor:(rowId == 0) :(columnId == selectedRating && cellIsSelected)  :(ratingsCount - columnId)];	
			if (colorId != label.backgroundColor) {
				label.backgroundColor = colorId;
			}
		}
	}
	
    //[viewDelegate.model updateUserDataRating:rating selected:TRUE];

    // Determine if rating text should be shown
    if ([viewDelegate.model autoCompression]) {
        [self setAnswers:[self shouldDisableCollapsing]];
    } else {
        // If auto-compress not selected, then keep same compressed/uncompressed state of rating
        if (self.showAnswers) {
            [self setAnswers:TRUE];
        } else {
            [self setAnswers:FALSE];
        }
    }
    
	if ([self.superview.superview isKindOfClass:[TPRubricQCell class]] && cellIsSelected && [viewDelegate.model autoScrolling]) {
		[((TPRubricQCell*)self.superview.superview) scrollToNextAction];
	}
}

@end


// --------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------
@implementation TPRubricQMultiSelectTable

@synthesize showAnswers;

-(float) tableHeight {
	float tempValue = 0;
	for (int i = 0; i < cellHeights.count; i++) {
		if (showAnswers || [self cellIsSelected:i]) {
			tempValue += [[cellHeights objectAtIndex:i] floatValue];
		}
	}
	return tempValue;
}

// --------------------------------------------------------------------------------------
-(BOOL) cellIsSelected:(int) index {
	TPRating *rating = [viewDelegate.model getRatingByQuestionId:question.question_id order:index + 1];
	return [viewDelegate.model ratingIsSelected:rating question:question];
}

// --------------------------------------------------------------------------------------
- (void) setAnswers:(BOOL)doShow {
	if (doShow || ![self shouldDisableCollapsing] || (question.type == TP_QUESTION_TYPE_MULTISELECT) || (question.type == TP_QUESTION_TYPE_UNISELECT)) {
		showAnswers = doShow;

		[self setFrame:CGRectMake(self.frame.origin.x, 
								  self.frame.origin.y, 
								  self.frame.size.width, 
								  self.tableHeight)];
		[self reloadData];

		if ([self.superview.superview isKindOfClass:[TPRubricQCellMultiSelect class]]) {
			[((TPRubricQCellMultiSelect*)self.superview.superview) updateUI];
			[((TPRubricQCellMultiSelect*)self.superview.superview) updateModified];
		}
	}
}

// --------------------------------------------------------------------------------------
- (BOOL) shouldDisableCollapsing {
	for (int i = 0; i < cellHeights.count; i++) {
		TPRating *rating = [viewDelegate.model getRatingByQuestionId:question.question_id order:i + 1];
		if ([viewDelegate.model ratingIsSelected:rating question:question]) {
			return FALSE;
		}
	}
	
	return TRUE;
}

// --------------------------------------------------------------------------------------
-(void) precalculateCellFrame:(int)width {
	ratingsCount = 0;
	cellHeights = [[NSMutableArray alloc] init];
	for (TPRating *rating in viewDelegate.model.rating_array) {
		if (rating.question_id == question.question_id) {
			ratingsCount++;
			
			CGSize constSize = CGSizeMake(width - 70, 1000);
			CGSize textSize = [rating.text sizeWithFont:[UIFont fontWithName:@"Helvetica" size:15.0] 
									  constrainedToSize:constSize 
										  lineBreakMode:NSLineBreakByWordWrapping];
			
			[cellHeights addObject:[NSNumber numberWithFloat:textSize.height + 20]];
		}
	}
}

// --------------------------------------------------------------------------------------
-(void) setCheckboxStateForCell:(UITableViewCell*)cell :(float) cellHeight :(BOOL)isChecked {
	[[cell viewWithTag:TP_QUESTION_TYPE_MULTISELECT_CELL_CHECKBOX_UNSELECTED_TAG] removeFromSuperview];
	[[cell viewWithTag:TP_QUESTION_TYPE_MULTISELECT_CELL_CHECKBOX_SELECTED_TAG] removeFromSuperview];
	
	if (isChecked) {	
		CGRect imageRect = CGRectMake(10.0f, (cellHeight - 30.0f)/2, 30.0f, 30.0f);
		UIImageView *checkbox = [[[UIImageView alloc] initWithFrame:imageRect] autorelease];
        if (question.type == TP_QUESTION_TYPE_UNISELECT) {
            [checkbox setImage:[UIImage imageNamed:@"radio_selected.png"]];
        } else {
            [checkbox setImage:[UIImage imageNamed:@"checkbox_checked.png"]];
        }
		checkbox.opaque = YES;
		checkbox.tag = TP_QUESTION_TYPE_MULTISELECT_CELL_CHECKBOX_SELECTED_TAG;
		[cell.contentView addSubview:checkbox];
	} else {	
		CGRect imageRect = CGRectMake(10.0f, (cellHeight - 30.0f)/2, 30.0f, 30.0f);
		UIImageView *checkbox = [[[UIImageView alloc] initWithFrame:imageRect] autorelease];
        if (question.type == TP_QUESTION_TYPE_UNISELECT) {
            [checkbox setImage:[UIImage imageNamed:@"radio_empty.png"]];
        } else {
            [checkbox setImage:[UIImage imageNamed:@"checkbox_empty.png"]];
        }
		checkbox.opaque = YES;
		checkbox.tag = TP_QUESTION_TYPE_MULTISELECT_CELL_CHECKBOX_UNSELECTED_TAG;
		[cell.contentView addSubview:checkbox];
	}
}

// --------------------------------------------------------------------------------------
- (id) initWithView:(TPView *)mainview question:(TPQuestion *)somequestion frame:(CGRect)targetFrame {
    
    self = [super initWithFrame: targetFrame style:UITableViewStylePlain];
    if (self != nil) {
        viewDelegate = mainview;
        question = somequestion;
        
        self.delegate = self;
        self.dataSource = self;
        
        UIView *background = [[UIView alloc] init];
        self.backgroundView = background;
        [background release];
		
		multiSelectTableCells = [[NSMutableArray alloc] init];

		[self precalculateCellFrame:targetFrame.size.width];
		
		showAnswers = ![viewDelegate.model autoCompression] || [self shouldDisableCollapsing];

		[self setAnswers:showAnswers];
		
		CGRect customFrame = self.frame;
		customFrame.size.height = self.tableHeight;
		[self setFrame:customFrame];
		self.layer.borderWidth = 1;
        self.layer.borderColor = [[UIColor darkGrayColor] CGColor];
		self.separatorColor = [UIColor darkGrayColor];
    }
    return self;
}

// --------------------------------------------------------------------------------------
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    tableView.backgroundColor = [UIColor whiteColor];
	return 1;
}

// --------------------------------------------------------------------------------------
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = nil;
	if (indexPath.row < [multiSelectTableCells count]) {
		cell = [multiSelectTableCells objectAtIndex:indexPath.row];
	} else {
		cell = [self customCellForRowAtIndexPath:indexPath];
		[multiSelectTableCells addObject:cell];
	}
	
	if ([self cellIsSelected:indexPath.row]) {
		[self cellContentHider:cell :FALSE];
		return [[cellHeights objectAtIndex:indexPath.row] floatValue];
	} else {
		[self cellContentHider:cell :!showAnswers];
		return showAnswers?[[cellHeights objectAtIndex:indexPath.row] floatValue]:0;
	}
}

// --------------------------------------------------------------------------------------
- (void) cellContentHider:(UITableViewCell*)cell :(BOOL)doHide {
	[[cell.contentView viewWithTag:TP_QUESTION_TYPE_MULTISELECT_CELL_LABEL] setHidden:doHide];
	[[cell.contentView viewWithTag:TP_QUESTION_TYPE_MULTISELECT_CELL_CHECKBOX_SELECTED_TAG] setHidden:doHide];
	[[cell.contentView viewWithTag:TP_QUESTION_TYPE_MULTISELECT_CELL_CHECKBOX_UNSELECTED_TAG] setHidden:doHide];
}

// --------------------------------------------------------------------------------------
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return ratingsCount;
}

// --------------------------------------------------------------------------------------
- (TPRubricQRatingCell *)customCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TPRubricQRatingCell *cell = nil;
	
	TPRating *rating = [viewDelegate.model getRatingByQuestionId:question.question_id order:indexPath.row + 1];
	
	if (indexPath.row < [multiSelectTableCells count]) {
		cell = [multiSelectTableCells objectAtIndex:indexPath.row];
	}
    
	if (cell == nil) {
        NSString *CellIdentifier = [NSString stringWithFormat:@"TPRubricQMultiSelectTableCellId %i", indexPath.row];
		// cell = [[[TPRubricQRatingCell alloc] initWithFrame:CGRectZero reuseIdentifier: CellIdentifier] autorelease]; // Deprecated
        cell = [[[TPRubricQRatingCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
		[cell setSelectionStyle:UITableViewCellSelectionStyleNone];
		[cell addColumn:self.frame.size.width - 1];
		
		UILabel *label;
		// table content
		label = [[[UILabel alloc] initWithFrame:CGRectMake(50, 1, self.frame.size.width  - 70, [[cellHeights objectAtIndex:indexPath.row] floatValue]-1)] autorelease];
		label.font = [UIFont fontWithName: @"Helvetica" size: 15.0];
		label.text = rating.text;
		label.numberOfLines = 0;
		label.lineBreakMode = NSLineBreakByWordWrapping;
		label.tag = TP_QUESTION_TYPE_MULTISELECT_CELL_LABEL;
		
		[cell.contentView addSubview:label];
    }
	
	[self setCheckboxStateForCell:cell :[[cellHeights objectAtIndex:indexPath.row] floatValue] :[viewDelegate.model ratingIsSelected:rating question:question]];
	
    return cell;
}

// --------------------------------------------------------------------------------------
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
	UITableViewCell *cell = nil;
	
	NSString *CellIdentifier = [NSString stringWithFormat:@"TPRubricQMultiSelectTableCellId %i", indexPath.row];		
	cell = [tableView dequeueReusableCellWithIdentifier: CellIdentifier];
	
	if (cell == nil) {
		cell = [multiSelectTableCells objectAtIndex:indexPath.row];
	}
   	
    return cell;
}


// --------------------------------------------------------------------------------------
- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
	UITableViewCell *cell;
	BOOL isSelected = FALSE;
    
	if ([viewDelegate.model isSetUILock]) return;  // If lock set then ignore input
	
	// Skip if user not allowed to edit
    if (![viewDelegate.model userCanEditQuestion:question]) {
		[tableView deselectRowAtIndexPath:[tableView indexPathForSelectedRow] animated:NO];
		return;
	}
	
	// WARNING - change to get rating, not by index!
	TPRating *rating = [viewDelegate.model getRatingByQuestionId:question.question_id order:[indexPath row] + 1];
	
	// Remove any prior checkmarks, set checkmark and deselect cell
	if (question.type == TP_QUESTION_TYPE_MULTISELECT) {
		cell = [tableView cellForRowAtIndexPath:indexPath];
		if ([cell viewWithTag:TP_QUESTION_TYPE_MULTISELECT_CELL_CHECKBOX_UNSELECTED_TAG]) {
			[self setCheckboxStateForCell:cell :[tableView rectForRowAtIndexPath:indexPath].size.height :TRUE];
			[viewDelegate.model updateUserDataRating:rating selected:TRUE];
		} else {
			[self setCheckboxStateForCell:cell :[tableView rectForRowAtIndexPath:indexPath].size.height :FALSE];
			[viewDelegate.model updateUserDataRating:rating selected:FALSE];
		}
	} else {
        int found_selection = 0;
        int selection_index = 0;
		for (int i=0; i < [tableView numberOfRowsInSection:0]; i++) {
			cell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
			if ([cell viewWithTag:TP_QUESTION_TYPE_MULTISELECT_CELL_CHECKBOX_SELECTED_TAG]) {
				[self setCheckboxStateForCell:cell :[tableView rectForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]].size.height :FALSE];
                found_selection = 1;
                selection_index = i;
			}
		}
        // If first selection or selecting different item
        isSelected = (found_selection == 0 || selection_index != [indexPath row]);
		if (isSelected) {
            cell = [tableView cellForRowAtIndexPath:indexPath];
            [self setCheckboxStateForCell:cell :[tableView rectForRowAtIndexPath:indexPath].size.height :TRUE];
            [viewDelegate.model updateUserDataRating:rating selected:TRUE];
        } else {
            // If reselecting prior selection then remove
            [viewDelegate.model updateUserDataRating:rating selected:FALSE];
        }
	}
	
	BOOL doShowAnswers = FALSE;
	
	if ([viewDelegate.model autoCompression] && (question.type == TP_QUESTION_TYPE_UNISELECT)) {
		doShowAnswers = [self shouldDisableCollapsing];
	} else {
		doShowAnswers = TRUE;
	}
	
	[self setAnswers:doShowAnswers];
	
	if ([self.superview.superview isKindOfClass:[TPRubricQCell class]] && question.type == TP_QUESTION_TYPE_UNISELECT && isSelected && [viewDelegate.model autoScrolling]) {
		[((TPRubricQCell*)self.superview.superview) scrollToNextAction];
	}
}

// --------------------------------------------------------------------------------------
- (void)dealloc {
	if (multiSelectTableCells) {
		[multiSelectTableCells release];
		multiSelectTableCells = nil;
	}
	[cellHeights release];
    [super dealloc];
}

@end

// --------------------------------------------------------------------------------------


// --------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------
@implementation TPRubricQMultiSelectCumulativeTable

@synthesize showAnswers;

// --------------------------------------------------------------------------------------
-(float) tableHeight {
	float tempValue = 0;
	for (int i = 0; i < cellHeights.count; i++) {
		if (showAnswers || [self cellIsSelected:i]) {
			tempValue += [[cellHeights objectAtIndex:i] floatValue];
		}
	}
	return tempValue;
}

// --------------------------------------------------------------------------------------
-(BOOL) cellIsSelected:(int) index {
	return ([[cellValues objectAtIndex:index] floatValue] > 0);
}

// --------------------------------------------------------------------------------------
- (void) setAnswers:(BOOL)doShow {
	//if (doShow || ![self shouldDisableCollapsing])
	//{
		showAnswers = doShow;
		
		[self setFrame:CGRectMake(self.frame.origin.x, 
								  self.frame.origin.y, 
								  self.frame.size.width, 
								  self.tableHeight)];
		[self reloadData];

		if ([self.superview.superview isKindOfClass:[TPRubricQCellMultiSelectCumulative class]]) {
			[((TPRubricQCellMultiSelect*)self.superview.superview) updateUI];
			[((TPRubricQCellMultiSelect*)self.superview.superview) updateModified];
		}
	//}
}

// --------------------------------------------------------------------------------------
- (BOOL) shouldDisableCollapsing {
	for (int i = 0; i < cellValues.count; i++) {
		if ([[cellValues objectAtIndex:i] floatValue] > 0) {
			return FALSE;
		}
	}
	return TRUE;
}

// --------------------------------------------------------------------------------------
-(void) precalculateCellFrame:(int)width {
	ratingsCount = 0;
	cellHeights = [[NSMutableArray alloc] init];
	cellValues = [[NSMutableArray alloc] init];
	for (TPRating *rating in viewDelegate.model.rating_array) {
		if (rating.question_id == question.question_id) {
			ratingsCount++;
			
			CGSize constSize = CGSizeMake(width - 70, 1000);
			CGSize textSize = [rating.text sizeWithFont:[UIFont fontWithName:@"Helvetica" size:15.0] 
									  constrainedToSize:constSize 
										  lineBreakMode:NSLineBreakByWordWrapping];
			
			[cellHeights addObject:[NSNumber numberWithFloat:textSize.height + 20]];
			[cellValues addObject:[NSNumber numberWithFloat:[viewDelegate.model ratingValue:rating question:question]]];
		}
	}
}

// --------------------------------------------------------------------------------------
- (id) initWithView:(TPView *)mainview question:(TPQuestion *)somequestion frame:(CGRect)targetFrame{
    self = [super initWithFrame: targetFrame style:UITableViewStylePlain];
    if (self != nil) {
        viewDelegate = mainview;
        question = somequestion;
        
        self.delegate = self;
        self.dataSource = self;
        
        UIView *background = [[UIView alloc] init];
        self.backgroundView = background;
        [background release];
		
		multiSelectTableCells = [[NSMutableArray alloc] init];
		
		[self precalculateCellFrame:targetFrame.size.width];
		
		showAnswers = ![viewDelegate.model autoCompression] || [self shouldDisableCollapsing];
		[self setAnswers:showAnswers];
		
		CGRect customFrame = self.frame;
		customFrame.size.height = self.tableHeight;
		[self setFrame:customFrame];
		self.layer.borderWidth = 1;
        self.layer.borderColor = [[UIColor darkGrayColor] CGColor];
		self.separatorColor = [UIColor darkGrayColor];
    }
    return self;
}

// --------------------------------------------------------------------------------------
- (void) cellContentHider:(UITableViewCell*)cell :(NSIndexPath*)indexPath :(BOOL)doHide {
	[[cell.contentView viewWithTag:TP_QUESTION_TYPE_MULTISELECT_CELL_LABEL] setHidden:doHide];
	[[cell.contentView viewWithTag:TP_QUESTION_TYPE_MULTISELECT_CUMULATIVE_CELL_BUTTON + indexPath.row] setHidden:doHide];
}

// --------------------------------------------------------------------------------------
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    tableView.backgroundColor = [UIColor whiteColor];
	return 1;
}

// --------------------------------------------------------------------------------------
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = nil;
	if (indexPath.row < [multiSelectTableCells count]) {
		cell = [multiSelectTableCells objectAtIndex:indexPath.row];
	} else {
		cell = [self customCellForRowAtIndexPath:indexPath];
		[multiSelectTableCells addObject:cell];
	}
	
	if ([self cellIsSelected:indexPath.row]) {
		[self cellContentHider:cell :indexPath :FALSE];
		return [[cellHeights objectAtIndex:indexPath.row] floatValue];
	} else {
		[self cellContentHider:cell :indexPath :!showAnswers];
		return showAnswers?[[cellHeights objectAtIndex:indexPath.row] floatValue]:0;
	}
}

// --------------------------------------------------------------------------------------
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return ratingsCount;
}

// --------------------------------------------------------------------------------------
- (TPRubricQRatingCell *)customCellForRowAtIndexPath:(NSIndexPath *)indexPath{
    TPRubricQRatingCell *cell = nil;

	TPRating *rating = [viewDelegate.model getRatingByQuestionId:question.question_id order:indexPath.row + 1];
	
	if (indexPath.row < [multiSelectTableCells count]) {
		cell = [multiSelectTableCells objectAtIndex:indexPath.row];
	}
	
	if (cell == nil) {
		NSString *CellIdentifier = [NSString stringWithFormat:@"TPRubricQMultiSelectCumulativeTableCellId %i", indexPath.row];
		// cell = [[[TPRubricQRatingCell alloc] initWithFrame:CGRectZero reuseIdentifier:CellIdentifier] autorelease]; // Deprecated
        cell = [[[TPRubricQRatingCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
		[cell setSelectionStyle:UITableViewCellSelectionStyleNone];
		[cell addColumn:self.frame.size.width - 1];
				
		// table content
		UIButton *valueButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
		[valueButton setFrame:CGRectMake(10.0f, ([[cellHeights objectAtIndex:indexPath.row] floatValue] - 30.0f)/2, 30.0f, 30.0f)];
		[valueButton addTarget:self action:@selector(addValueAction:) forControlEvents:UIControlEventTouchUpInside];
		[valueButton setTitle:[NSString stringWithFormat:@"%d", (int)[[cellValues objectAtIndex:indexPath.row] floatValue]] forState:UIControlStateNormal];
		[valueButton setTag: TP_QUESTION_TYPE_MULTISELECT_CUMULATIVE_CELL_BUTTON + indexPath.row];
        [valueButton setEnabled:[viewDelegate.model userCanEditQuestion:question]];
		[cell.contentView addSubview:valueButton];
		
		UILabel *label = [[[UILabel alloc] initWithFrame:CGRectMake(50, 1, self.frame.size.width  - 70, [[cellHeights objectAtIndex:indexPath.row] floatValue]-1)] autorelease];
		label.font = [UIFont fontWithName: @"Helvetica" size: 15.0];
		label.text = rating.text;
		label.numberOfLines = 0;
		label.lineBreakMode = NSLineBreakByWordWrapping;
		label.tag = TP_QUESTION_TYPE_MULTISELECT_CELL_LABEL;		
		[cell.contentView addSubview:label];
    }

    return cell;
}

// --------------------------------------------------------------------------------------
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

	UITableViewCell *cell = nil;
	
	NSString *CellIdentifier = [NSString stringWithFormat:@"TPRubricQMultiSelectCumulativeTableCellId %i", indexPath.row];		
	cell = [tableView dequeueReusableCellWithIdentifier: CellIdentifier];
	
	if (cell == nil) {
		cell = [multiSelectTableCells objectAtIndex:indexPath.row];
	}

    return cell;
}

// --------------------------------------------------------------------------------------
- (void)addValueAction:(id)sender {

	if ([viewDelegate.model isSetUILock]) return;  // If lock set then ignore input
    
    // Skip if user not allowed to edit
    if (![viewDelegate.model userCanEditQuestion:question]) {
		[sender setEnabled:FALSE];
        return;
    }
	
	int index = [(UIButton*)sender tag] - TP_QUESTION_TYPE_MULTISELECT_CUMULATIVE_CELL_BUTTON;
	float currentValue = [[cellValues objectAtIndex:index] floatValue];
	TPRating *rating = [viewDelegate.model getRatingByQuestionId:question.question_id order:index + 1];
	[cellValues replaceObjectAtIndex:index withObject:[NSNumber numberWithFloat:currentValue + rating.value]];
	
	[viewDelegate.model updateUserDataRatingCumulative:rating cumulativeValue:[[cellValues objectAtIndex:index] floatValue]];	
	[(UIButton*)sender setTitle:[NSString stringWithFormat:@"%d", (int)[[cellValues objectAtIndex:index] floatValue]] forState:UIControlStateNormal];
	[self setAnswers:TRUE];
}

// --------------------------------------------------------------------------------------
- (void)dealloc {
	if (multiSelectTableCells) {
		[multiSelectTableCells release];
		multiSelectTableCells = nil;
	}
	[cellHeights release];
	[cellValues release];
    [super dealloc];
}

@end


// --------------------------------------------------------------------------------------
// TPRubricQCellSubHeading - return content of table cell for heading data
// --------------------------------------------------------------------------------------
@implementation TPRubricQCellSubHeading

@synthesize elapsedTime;

// --------------------------------------------------------------------------------------
- (id) initWithView:(TPView *)mainview {
    
    if (![mainview.model isRubricEditable:mainview.model.appstate.rubric_id]) {
        self = [super initWithFrame:CGRectMake(0, 0, TP_QUESTION_CELL_WIDTH, 70)];
    } else {
        self = [super initWithFrame:CGRectMake(0, 0, TP_QUESTION_CELL_WIDTH, 180)];
    }
    
    if (self != nil) {
        
        viewDelegate = mainview;
        
        // Set view properties
		self.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
		
		//TPUserData *userdata = [viewDelegate.model getUserDataFromListById:viewDelegate.model.appstate.userdata_id];
        TPUserData *userdata = [viewDelegate.model getCurrentUserData];
        
        // If read-only form then just display title
        if (![viewDelegate.model isRubricEditable:viewDelegate.model.appstate.rubric_id]) {
            
            // Title of form
            title = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, TP_QUESTION_CELL_WIDTH_EFFECTIVE, 34)];
            title.text = userdata.name;
            title.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
            title.font = [UIFont fontWithName:@"Helvetica-Bold" size:24.0];
            title.textAlignment = TPTextAlignmentCenter;
            [self addSubview:title];
            
            // Read-only message
            readonlymsg = [[UILabel alloc] initWithFrame:CGRectMake(10, 50, TP_QUESTION_CELL_WIDTH_EFFECTIVE, 15)];
            readonlymsg.text = @"This form can only be read and not recorded";
            readonlymsg.textColor = [UIColor blueColor];
            readonlymsg.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
            readonlymsg.font = [UIFont fontWithName:@"Helvetica-Oblique" size:13.0];
            readonlymsg.textAlignment = TPTextAlignmentCenter;
            [self addSubview:readonlymsg];
            
        // Otherwise display all items
        } else {
            
		TPUser *user = [viewDelegate.model getCurrentTarget];
		TPRubric *rubric = [viewDelegate.model getCurrentRubric];
		
		// Captions	
		nameCaption = [[UILabel alloc] initWithFrame:CGRectMake(5, 45, 80, 30)];
		nameCaption.text = @"Name:";
		nameCaption.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
		nameCaption.font = [UIFont fontWithName:@"Helvetica" size:16.0];
        nameCaption.textColor = [UIColor darkGrayColor];
		nameCaption.textAlignment = TPTextAlignmentRight;
		[self addSubview:nameCaption];
		
		if ([user.schools length]) {
			schoolCaption = [[UILabel alloc] initWithFrame:CGRectMake(5, 75, 80, 30)];
			schoolCaption.text = @"School:";
			schoolCaption.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
			schoolCaption.font = [UIFont fontWithName:@"Helvetica" size:16.0];
            schoolCaption.textColor = [UIColor darkGrayColor];
			schoolCaption.textAlignment = TPTextAlignmentRight;
			[self addSubview:schoolCaption];
		}
		
		if ([user.subjects length]) {
			subjectCaption = [[UILabel alloc] initWithFrame:CGRectMake(5, 105, 80, 30)];
			subjectCaption.text = @"Subject:";
			subjectCaption.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
			subjectCaption.font = [UIFont fontWithName:@"Helvetica" size:16.0];
            subjectCaption.textColor = [UIColor darkGrayColor];
			subjectCaption.textAlignment = TPTextAlignmentRight;
			[self addSubview:subjectCaption];
		}
		
		if ([[user getGradeString] length]) {
			gradeCaption = [[UILabel alloc] initWithFrame:CGRectMake(5, 135, 80, 30)];
			gradeCaption.text = @"Grade:";
			gradeCaption.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
			gradeCaption.font = [UIFont fontWithName:@"Helvetica" size:16.0];
            gradeCaption.textColor = [UIColor darkGrayColor];
			gradeCaption.textAlignment = TPTextAlignmentRight;
			[self addSubview:gradeCaption];
		}
		
		evaluatorCaption = [[UILabel alloc] initWithFrame:CGRectMake(370, 45, 100, 30)];
		evaluatorCaption.text = @"Evaluator:";
		evaluatorCaption.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
		evaluatorCaption.font = [UIFont fontWithName:@"Helvetica" size:16.0];
        evaluatorCaption.textColor = [UIColor darkGrayColor];
		evaluatorCaption.textAlignment = TPTextAlignmentRight;
		[self addSubview:evaluatorCaption];
		
		dateCaption = [[UILabel alloc] initWithFrame:CGRectMake(370, 75, 100, 30)];
		dateCaption.text = @"Date:";
		dateCaption.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
		dateCaption.font = [UIFont fontWithName:@"Helvetica" size:16.0];
        dateCaption.textColor = [UIColor darkGrayColor];
		dateCaption.textAlignment = TPTextAlignmentRight;
		[self addSubview:dateCaption];
		
		if (rubric.rec_elapsed) {
			elapsedCaption = [[UILabel alloc] initWithFrame:CGRectMake(370, 105, 100, 30)];
			elapsedCaption.text = @"Elapsed:";
			elapsedCaption.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
			elapsedCaption.font = [UIFont fontWithName:@"Helvetica" size:16.0];
            elapsedCaption.textColor = [UIColor darkGrayColor];
			elapsedCaption.textAlignment = TPTextAlignmentRight;
			[self addSubview:elapsedCaption];
		}
		
		shareCaption = [[UILabel alloc] initWithFrame:CGRectMake(370, 135, 100, 30)];
		shareCaption.text = @"Share:";
		shareCaption.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
		shareCaption.font = [UIFont fontWithName:@"Helvetica" size:16.0];
        shareCaption.textColor = [UIColor darkGrayColor];
		shareCaption.textAlignment = TPTextAlignmentRight;
		[self addSubview:shareCaption];

		
		// Values
		title = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, TP_QUESTION_CELL_WIDTH_EFFECTIVE, 34)];
		title.text = userdata.name;
		title.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
		title.font = [UIFont fontWithName:@"Helvetica-Bold" size:24.0];
		title.textAlignment = TPTextAlignmentCenter;
		[self addSubview:title];
		
		name = [[UILabel alloc] initWithFrame:CGRectMake(90, 45, 250, 30)];
		name.text = [viewDelegate.model getUserName:userdata.target_id];
		name.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
		name.font = [UIFont fontWithName:@"Helvetica" size:16.0];
		name.textAlignment = TPTextAlignmentLeft;
		[self addSubview:name];
		
		if ([user.schools length]) {
			school = [[UILabel alloc] initWithFrame:CGRectMake(90, 75, 250, 30)];
			school.text = user.schools;
			school.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
			school.font = [UIFont fontWithName:@"Helvetica" size:16.0];
			school.textAlignment = TPTextAlignmentLeft;
			[self addSubview:school];
		}
		
		if ([user.subjects length]) {
			subject = [[UILabel alloc] initWithFrame:CGRectMake(90, 105, 250, 30)];
			subject.text = user.subjects;
			subject.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
			subject.font = [UIFont fontWithName:@"Helvetica" size:16.0];
			subject.textAlignment = TPTextAlignmentLeft;
			[self addSubview:subject];
		}
		
        // If user has grade specification then display
		if ([[user getGradeString] length]) {
            
			CGSize constSize = CGSizeMake(TP_QUESTION_CELL_WIDTH_EFFECTIVE, 400);
			CGSize textSize = [[user getGradeString] sizeWithFont:[UIFont fontWithName:@"Helvetica" size:16.0] 
										  constrainedToSize:constSize 
											  lineBreakMode:NSLineBreakByWordWrapping];
			
            // If user is owner then show grade change button
            if (userdata.user_id == viewDelegate.model.appstate.user_id) {
                
				//Create popovers and controllers
				gradePO = [[TPGradePO alloc] initWithViewDelegate:viewDelegate parent:self minGrade:user.grade_min maxGrade:user.grade_max];
				gradePOC = [[UIPopoverController alloc] initWithContentViewController:gradePO];
				[gradePOC setPopoverContentSize:CGSizeMake(180, 400)];
				
				changeGrade = [UIButton buttonWithType:UIButtonTypeRoundedRect];
				[changeGrade setFrame:CGRectMake(90, 136, 50, 26)];
				[changeGrade addTarget:self action:@selector(changeGradeAction) forControlEvents:UIControlEventTouchUpInside];
				//[changeGrade setTitle:@"Change grade" forState:UIControlStateNormal];
                
                if (userdata.grade) {
                    [changeGrade setTitle:[TPUser getGradeStringById:userdata.grade] forState:UIControlStateNormal];
                } else {
                    [changeGrade setTitle:[user getGradeString] forState:UIControlStateNormal];
                }
                
				//[changeGrade setHidden:![viewDelegate.model userCanEditFormHeading]];
                if ([viewDelegate.model userCanEditFormHeading]) {
                    changeGrade.enabled = YES;
                } else {
                    changeGrade.enabled = NO;
                }
                
				[self addSubview:changeGrade];
                
            // Otherwise show static string
			} else {
                grade = [[UILabel alloc] initWithFrame:CGRectMake(90, 135, textSize.width, 30)];
                if (userdata.grade) {
                    grade.text = [TPUser getGradeStringById:userdata.grade];
                } else {
                    grade.text = [user getGradeString];
                }
                
                grade.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
                grade.font = [UIFont fontWithName:@"Helvetica" size:16.0];
                grade.textAlignment = TPTextAlignmentLeft;
                [self addSubview:grade];
            }
		}
		
		evaluator = [[UILabel alloc] initWithFrame:CGRectMake(475, 45, 200, 30)];
        evaluator.text = [viewDelegate.model getUserName:userdata.user_id];
		evaluator.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
		evaluator.font = [UIFont fontWithName:@"Helvetica" size:16.0];
		evaluator.textAlignment = TPTextAlignmentLeft;
		[self addSubview:evaluator];
		
		date = [[UILabel alloc] initWithFrame:CGRectMake(475, 75, 200, 30)];
		date.text = [viewDelegate.model prettyStringFromDate:userdata.created];
		date.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
		date.font = [UIFont fontWithName:@"Helvetica" size:16.0];
		date.textAlignment = TPTextAlignmentLeft;
		[self addSubview:date];
		
		if (rubric.rec_elapsed) {
			elapsedTime = userdata.elapsed;
			elapsed = [[UILabel alloc] initWithFrame:CGRectMake(475, 105, 200, 30)];
			elapsed.text = [TPUtil formatElapsedTime:elapsedTime];
			elapsed.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
			elapsed.font = [UIFont fontWithName:@"Helvetica" size:16.0];
			elapsed.textAlignment = TPTextAlignmentLeft;
			[self addSubview:elapsed];
			
			if (userdata.user_id == viewDelegate.model.appstate.user_id) {
				// Elapsed button
				elapsedButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
				[elapsedButton setFrame:CGRectMake(590, 108, 60, 26)];
				[elapsedButton addTarget:self action:@selector(startStopElapsedAction) forControlEvents:UIControlEventTouchUpInside];
				[elapsedButton setTitle:@"Start" forState:UIControlStateNormal];
				[elapsedButton setHidden:![viewDelegate.model userCanEditFormHeading]];
				[self addSubview:elapsedButton];
			}
		}
		
		shareSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(475, 137, 100, 30)];
		shareSwitch.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
		[shareSwitch addTarget:self action:@selector(sharechange) forControlEvents:UIControlEventValueChanged];
        [self shareReset];
		[self addSubview:shareSwitch];
            
        } // End heading for normal (non-read only) forms
    }
    return self;
}

// --------------------------------------------------------------------------------------
- (void) dealloc {
	
	if (nameCaption) {
		[nameCaption release];
		nameCaption = NULL;
	}
	if (schoolCaption) {
		[schoolCaption release];
		schoolCaption = NULL;
	}
	if (subjectCaption) {
		[subjectCaption release];
		subjectCaption = NULL;
	}
	if (gradeCaption) {
		[gradeCaption release];
		gradeCaption = NULL;
	}
	if (evaluatorCaption) {
		[evaluatorCaption release];
		evaluatorCaption = NULL;
	}
	if (dateCaption) {
		[dateCaption release];
		dateCaption = NULL;
	}
	if (elapsedCaption) {
		[elapsedCaption release];
		elapsedCaption = NULL;
	}
	if (shareCaption) {
		[shareCaption release];
		shareCaption = NULL;
	}
	if (name) {
		[name release];
		name = NULL;
	}
	if (school) {
		[school release];
		school = NULL;
	}
	if (subject) {
		[subject release];
		subject = NULL;
	}
	if (grade) {
		[grade release];
		grade = NULL;
	}
	if (evaluator) {
		[evaluator release];
		evaluator = NULL;
	}
	if (date) {
		[date release];
		date = NULL;
	}
	if (elapsed) {
		[elapsed release];
		elapsed = NULL;
	}
	if (title) {
		[title release];
		title = NULL;
	}
    if (readonlymsg) {
        [readonlymsg release];
        readonlymsg = nil;
    }
	if (shareSwitch) {
        [shareSwitch release];
        shareSwitch = nil;
    }
	if (secondTimer) {
		[secondTimer invalidate];
		secondTimer = nil;
	}
	[super dealloc];
}

// --------------------------------------------------------------------------------------
- (void)drawRect:(CGRect)rect {
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	CGContextSetRGBStrokeColor(ctx, 0, 0, 0, 1.0);
	CGContextSetLineWidth(ctx, 0.25);
		
	CGContextMoveToPoint(ctx, 1, 1);
	CGContextAddLineToPoint(ctx, self.bounds.size.width - 1, 1);
	CGContextAddLineToPoint(ctx, self.bounds.size.width - 1, self.bounds.size.height - 2);
	CGContextAddLineToPoint(ctx, 1, self.bounds.size.height - 2);
	CGContextAddLineToPoint(ctx, 1, 1);
		
	CGContextStrokePath(ctx);
		
	[super drawRect:rect];
}

// --------------------------------------------------------------------------------------
- (void)startStopElapsedAction {
	// updating elapsed time for rubrics owner
	if (!secondTimer) {
		secondTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(everySecond) userInfo:nil repeats:YES];
		[elapsedButton setTitle:@"Stop" forState:UIControlStateNormal];
	} else {
		[secondTimer invalidate];
		secondTimer = nil;
		[elapsedButton setTitle:@"Start" forState:UIControlStateNormal];
	}

}

// --------------------------------------------------------------------------------------
- (void)stopElapsedTime {
	if (secondTimer) {
		[secondTimer invalidate];
		secondTimer = nil;
		[elapsedButton setTitle:@"Start" forState:UIControlStateNormal];
	}
}

// --------------------------------------------------------------------------------------
- (void)everySecond {
	elapsedTime++;
	elapsed.text = [TPUtil formatElapsedTime:elapsedTime];	
}

// --------------------------------------------------------------------------------------
- (void)changeGradeAction {
	if ([gradePOC isPopoverVisible]) {
		[gradePOC  dismissPopoverAnimated:YES];
	} else {
		[gradePO reset];
		[gradePOC presentPopoverFromRect:changeGrade.frame
								  inView:self 
				permittedArrowDirections:UIPopoverArrowDirectionUp
								animated:YES];
	}
}

// --------------------------------------------------------------------------------------
- (void)changeGradeActionCallback:(NSNumber*)selected {
	[gradePOC dismissPopoverAnimated:YES]; // Dismiss popup grade picker
	[viewDelegate.model updateUserDataGrade:[selected intValue]]; // Update grade in userdata
    //grade.text = [TPUser getGradeStringById:[selected intValue]]; // Update grade in form header
    [changeGrade setTitle:[TPUser getGradeStringById:[selected intValue]] forState:UIControlStateNormal]; // Change button text
}

// --------------------------------------------------------------------------------------
- (void) shareReset {
    
    TPUserData *userdata = [viewDelegate.model getCurrentUserData];
    if (userdata.share == 1) {
        [shareSwitch setOn:YES animated:NO];
    } else {
        [shareSwitch setOn:NO animated:NO];
    }
    
	if ([viewDelegate.model userOwnsUserdata]) {
        shareSwitch.enabled = YES;
    } else {
        shareSwitch.enabled = NO;
    }
}

// --------------------------------------------------------------------------------------
- (void) sharechange {
        
    if ([viewDelegate.model isSetUILock]) return;  // If lock set then ignore input
    
    TPUserData *userdata = [viewDelegate.model getCurrentUserData];
    userdata.share = shareSwitch.on;
    
    // Update in database
    [viewDelegate.model updateUserDataShare:userdata.share];
}
@end
