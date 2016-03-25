#import <QuartzCore/QuartzCore.h>

#import "TPData.h"
#import "TPView.h"
#import "TPModel.h"
#import "TPModelReport.h"
#import "TPDatabase.h"
#import "TPDatabaseReport.h"
#import "TPReportList.h"

// --------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------
@implementation TPReportListVC

- (id)initWithView:(TPView *)mainview {
    
    if (debugReport) NSLog(@"TPReportList initWithView");
    
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self != nil) {
        
        viewDelegate = mainview;
        
        // Initialize report arrays
        reportGroupNames = [[NSMutableArray alloc] init];
        reportRubricIdArrays = [[NSMutableArray alloc] init];
        reportNameArrays = [[NSMutableArray alloc] init];
		
        UITabBarItem *tbaritem = [[UITabBarItem alloc] initWithTitle:@"Reports" image:[UIImage imageNamed:@"folder.png"] tag:0];
        self.tabBarItem = tbaritem;
        [tbaritem release];
        
		rightbutton = [[UIBarButtonItem alloc] 
                       initWithTitle:@"Options" 
                       style: UIBarButtonItemStylePlain
                       target: self 
                       action: @selector(showoptions)];
		//self.navigationItem.rightBarButtonItem = rightbutton; //jxi;
        [rightbutton release];
                
        // Create view control button (segmented)
        viewControl = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"Forms", @"Info", @"Reports", nil]];
        viewControl.segmentedControlStyle = UISegmentedControlStyleBar;
        viewControl.frame = CGRectMake(10, 10, 280, 30);
        [viewControl addTarget:self action:@selector(switchView) forControlEvents:UIControlEventValueChanged];
        
        //self.navigationItem.titleView = viewControl; //jxi; modified
        [self resetPrompt];
        self.navigationItem.hidesBackButton = YES;
    }
    return self;
}

// --------------------------------------------------------------------------------------
- (int)getCellIndexByIndexPath:(NSIndexPath *)indexPath {
	switch ([indexPath section]) {
		case 0:
			return [indexPath row];
			break;
		case 1:
			return [indexPath row] + 2;
		case 2:
			return [indexPath row] + 3;
			break;
		default:
			return 0;
			break;
	}
}

// --------------------------------------------------------------------------------------
- (void)dealloc {
    [reportGroupNames release];
    [reportRubricIdArrays release];
    [reportNameArrays release];
    [self release];
    [super dealloc];
}

// --------------------------------------------------------------------------------------
- (void)loadView {
    [super loadView];
}

// --------------------------------------------------------------------------------------
- (void)viewDidAppear:(BOOL)animated {
    viewDelegate.model.currentMainViewState = @"reportlist";
}

// --------------------------------------------------------------------------------------
- (void)viewDidUnload {
    [super viewDidUnload];
}

// --------------------------------------------------------------------------------------
- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

// --------------------------------------------------------------------------------------
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration {
    if (debugRotate) NSLog(@"TPReportListVC willRotateToInterfaceOrientation");
}

- (void)viewWillLayoutSubviews {
    if (debugRotate) NSLog(@"TPReportListVC viewWillLayoutSubviews");
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration {
    if (debugRotate) NSLog(@"TPReportListVC willAnimateRotationToInterfaceOrientation");
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    if (debugRotate) NSLog(@"TPReportListVC didRotateFromInterfaceOrientation");
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    if (debugRotate) NSLog(@"TPReportListVC shouldAutorotateToInterfaceOrientation");
    return YES;
}

// --------------------------------------------------------------------------------------
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return [reportGroupNames count];
}

// --------------------------------------------------------------------------------------
- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if ([reportGroupNames count] > 0) {
        return [reportGroupNames objectAtIndex:section];
    } else {
        return nil;
    }
}

// --------------------------------------------------------------------------------------
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [[reportNameArrays objectAtIndex:section] count];
}

// --------------------------------------------------------------------------------------
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if ([reportGroupNames count]) {
        
        NSNumber *rubricId = [[reportRubricIdArrays objectAtIndex:[indexPath section]] objectAtIndex:[indexPath row]];
        NSString *reportName = [[reportNameArrays objectAtIndex:[indexPath section]] objectAtIndex:[indexPath row]];
                
        NSString *CellIdentifier = [NSString stringWithFormat:@"%d/%d/%d/%d/%@",
                                    viewDelegate.model.appstate.user_id,
                                    [indexPath section],
                                    [indexPath row],
                                    [rubricId intValue],
                                    reportName];
        
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: CellIdentifier];
        
        if (cell == nil) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
            cell.textLabel.text = reportName;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            UIFont *font = [UIFont fontWithName: @"Helvetica" size: 18.0 ];
            cell.textLabel.font = font;
        }
        return cell;
	} else {
        return nil;
    }
}

// --------------------------------------------------------------------------------------
- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *groupName = [reportGroupNames objectAtIndex:[indexPath section]];
    NSNumber *rubricId = [[reportRubricIdArrays objectAtIndex:[indexPath section]] objectAtIndex:[indexPath row]];
    NSString *reportName = [[reportNameArrays objectAtIndex:[indexPath section]] objectAtIndex:[indexPath row]];
    [viewDelegate setReport:[indexPath section] groupName:groupName reportId:[rubricId intValue] reportName:reportName];
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
    self.navigationItem.prompt = [viewDelegate.model getDetailViewPromptString];
}

// --------------------------------------------------------------------------------------

- (void) showoptions {
    if (debugReport) NSLog(@"TPReportList showoptions");
    [viewDelegate hidenew];
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
- (void) reset {
    
    if (debugReport) NSLog(@"TPReportList reset");
    
    // Empty existing report arrays
    [reportGroupNames removeAllObjects];
    for (NSMutableArray *array in reportRubricIdArrays) [array removeAllObjects];
    [reportRubricIdArrays removeAllObjects];
    for (NSMutableArray *array in reportNameArrays) [array removeAllObjects];
    [reportNameArrays removeAllObjects];
    
    // Create temp arrays and variables
    NSMutableArray *rubricIds = [NSMutableArray arrayWithCapacity:0];
    NSMutableArray *rubricNames = [NSMutableArray arrayWithCapacity:0];
    int groupIndex = 0;
    
    // Add performance comparison reports
    [viewDelegate.model getRubricsWithRecordedCategoryData:rubricIds names:rubricNames];
    if ([rubricIds count] > 0) {
        [reportGroupNames addObject:@"Performance Comparison"];
        [reportRubricIdArrays addObject:[NSMutableArray arrayWithArray:rubricIds]];
        [reportNameArrays addObject:[NSMutableArray arrayWithArray:rubricNames]];
    }
    
    // Add progress monitoring reports
    [reportGroupNames addObject:@"Progress Monitoring"];
    groupIndex = [reportGroupNames count] - 1;
    [reportRubricIdArrays addObject:[NSMutableArray arrayWithCapacity:0]];
    [[reportRubricIdArrays objectAtIndex:groupIndex] addObject:[NSNumber numberWithInt:0]];
    [reportNameArrays addObject:[NSMutableArray arrayWithCapacity:0]];
    [[reportNameArrays objectAtIndex:groupIndex] addObject:@"Recorded Forms Report"];
    
    // Add Detailed reports
    // Get list of recorded rubrics from DB for target user (excluding self evaluations)
    [rubricIds removeAllObjects];
    [rubricNames removeAllObjects];
    [viewDelegate.model.database getRubricsWithRecordedData:rubricIds
                                                      names:rubricNames
                                               filterUserId:([viewDelegate.model useOwnData]?viewDelegate.model.appstate.user_id:0)];
    if ([rubricIds count] > 0) {
        [reportGroupNames addObject:@"Detailed Reports"];
        [reportRubricIdArrays addObject:[NSMutableArray arrayWithArray:rubricIds]];
        [reportNameArrays addObject:[NSMutableArray arrayWithArray:rubricNames]];
    }
    
    // Get current list of recorded rubrics
    [self.tableView reloadData];
    
    // Reset the user name and district
    [self resetPrompt];
    self.navigationItem.hidesBackButton = YES;
}

@end
