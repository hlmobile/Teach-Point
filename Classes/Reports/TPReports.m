//
//  TPReports.m
//  teachpoint
//
//  Created by Chris Dunn on 4/6/11.
//  Copyright 2011 Clear Pond Technologies, Inc. All rights reserved.
//

#import "TPData.h"
#import "TPView.h"
#import "TPModel.h"
#import "TPReports.h"
#import "TPUtil.h"
#import "TPDatabaseReport.h"
#import "TPModelReport.h"

@implementation TPReportVC

// --------------------------------------------------------------------------------------
- (id)initWithView:(TPView *)mainview {

    self = [super init];
    if (self != nil) {
        
        viewDelegate = mainview;
        
        UITabBarItem *tbar = [[UITabBarItem alloc] initWithTitle:@"Reports" image:[UIImage imageNamed:@"graph.png"] tag:2];
        self.tabBarItem = tbar;
        [tbar release];
        
        rightbutton = [[UIBarButtonItem alloc] 
                       initWithTitle:@"Done" 
                       style: UIBarButtonItemStylePlain
                       target: viewDelegate 
                       action: @selector(reportDoneViewing)];
		self.navigationItem.rightBarButtonItem = rightbutton;
        [rightbutton release];
        
        self.navigationItem.hidesBackButton = YES;
              
        scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, 768, 1000)];
        scrollView.contentSize = CGSizeMake(768, 1000);
        scrollView.scrollEnabled = YES;
        scrollView.clipsToBounds = YES;
        scrollView.delegate = self;
        
        webView = [[UIWebView alloc] init];
        webView.dataDetectorTypes = UIDataDetectorTypeNone;
        webView.delegate = self;
        [webView loadHTMLString:@"" baseURL:[NSURL URLWithString:@""]];
        [scrollView addSubview:webView];
        
        self.navigationItem.title = @"Report";
        self.navigationItem.prompt = [NSString stringWithFormat:@"%@ %@  -  %@",
                                      viewDelegate.model.appstate.first_name,
                                      viewDelegate.model.appstate.last_name,
                                      viewDelegate.model.appstate.district_name];
    }
    return self;
}

// --------------------------------------------------------------------------------------
- (void)dealloc {
    [rightbutton release];
    [webView release];
    [scrollView release];
    [super dealloc];
}

- (void)loadView {
    [super loadView];
    if ([UIDevice currentDevice].orientation <= UIInterfaceOrientationPortrait) {
        webView.frame = CGRectMake(0, 0, 768, 1000);
    } else {
        webView.frame = CGRectMake(0, 0, 768, 1000);
    }
    [self.view addSubview:scrollView];
    //[self.view addSubview:webView];
    self.view.backgroundColor = [UIColor grayColor];
}

- (void) viewDidAppear:(BOOL)animated {
    viewDelegate.model.currentMainViewState = @"report";
    //NSLog(@"currentMainViewState = %@", viewDelegate.model.currentMainViewState);
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

// --------------------------------------------------------------------------------------
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration {
    if (debugRotate) NSLog(@"TPReportVC willRotateToInterfaceOrientation");
}

- (void)viewWillLayoutSubviews {
    if (debugRotate) NSLog(@"TPReportVC viewWillLayoutSubviews");
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration {
    if (debugRotate) NSLog(@"TPReportVC willAnimateRotationToInterfaceOrientation");
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    if (debugRotate) NSLog(@"TPReportVC didRotateFromInterfaceOrientation");
    // Adjust scrollview to overall view size
    scrollView.frame = self.view.frame;
    //webView.frame = CGRectMake(0, 0, 768, 1000);
    [self webViewDidFinishLoad:webView];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    if (debugRotate) NSLog(@"TPReportVC shouldAutorotateToInterfaceOrientation");
	return YES;
}

// --------------------------------------------------------------------------------------
// webViewDidFinishLoad - resize to fit content after report is loaded
// --------------------------------------------------------------------------------------
- (void)webViewDidFinishLoad:(UIWebView *)thisWebView {
    
    //NSLog(@"webViewDidFinishLoad");
        
    // Adjust scrollview to overall view size
    scrollView.frame = self.view.frame;
    
    // Find size that fits content
    thisWebView.frame = CGRectMake(0, 0, 10, 10);
    CGSize fitsize = [thisWebView sizeThatFits:CGSizeZero];
    
    // Limit maximum in case content is huge
    if (fitsize.width > 2048) fitsize.width = 2048;
    if (fitsize.height > 10240) fitsize.height = 10240;
    
    // Limit minimum size to parent view size
    if (fitsize.width < self.view.frame.size.width) fitsize.width = self.view.frame.size.width;
    if (fitsize.height < self.view.frame.size.height) fitsize.height = self.view.frame.size.height;
    
    // Adjust web view and scroll view content size
    webView.frame = CGRectMake(0, 0, fitsize.width, fitsize.height);
    scrollView.contentSize = fitsize;
    [scrollView setContentOffset:CGPointMake(0, 0) animated:YES];
}

// --------------------------------------------------------------------------------------
- (void) reset:(int)reportgroup groupName:(NSString *)groupName reportId:(int)reportId reportName:(NSString *)reportName {
        
    if (debugReport) NSLog(@"TPReportVC reset %d %d %@", reportgroup, reportId, reportName);
    
    // Reset prompt
    [self resetPrompt];
    
    // Get the selected report
    NSString *report = @"";
    if ([groupName isEqualToString:@"Performance Comparison"]) {
        report = [self performanceComparisonReportByRubric:reportId rubricName:reportName];
    } else if ([groupName isEqualToString:@"Progress Monitoring"]) {
        report = [self rubricCompletedReport];
    } else if ([groupName isEqualToString:@"Detailed Reports"]) {
        report = [self advancedRubricReport:reportId rubricName:reportName];
    }
    
    // Reset the size to extra small so size calculation in webViewDidFinishLoad will work properly
    webView.frame = CGRectMake(0, 0, 10, 10);
    
    // Load the report content
    [webView loadHTMLString:report baseURL:[NSURL URLWithString:@""]];
}

// --------------------------------------------------------------------------------------
- (void)resetPrompt {
    self.navigationItem.prompt = [viewDelegate.model getDetailViewPromptString];
}

// --------------------------------------------------------------------------------------
// individualPerformanceReportByRubric - generate a report for the current target user, with
// all available recorded data (except self-evaluation data).  Split report into separate
// tables per recorded rubric.
// --------------------------------------------------------------------------------------
- (NSString *) individualPerformanceReportByRubric {
    
    float aggValue;
    BOOL foundData;
    int numCategories;
    int rubricId;
    
    // Get the target user
    TPUser *targetUser = [viewDelegate.model getCurrentTarget];
    
    // Create temporary arrays to hold categories to report
    NSMutableArray *categoryIdList = [[[NSMutableArray alloc] init] autorelease];
    NSMutableArray *categoryNameList = [[[NSMutableArray alloc] init] autorelease];
    NSMutableArray *categoryAggregateValueList = [[[NSMutableArray alloc] init] autorelease];
    numCategories = 0;
    for (TPCategory *category in viewDelegate.model.category_array) {
        if (category.state != 1) continue;
        foundData = [viewDelegate.model getCategoryAggregate:category.category_id
													rubricId:0
                                                targetUserId:viewDelegate.model.appstate.target_id
                                                  userdataId:nil
                                                    aggValue:&aggValue];
        if (foundData) {
            [categoryIdList addObject:[NSNumber numberWithInt:category.category_id]];
            [categoryNameList addObject:category.name];
            [categoryAggregateValueList addObject:[NSNumber numberWithFloat:aggValue]];
            numCategories++;
        }
    }
    
    // Get list of rubrics with category data for all target users
    NSMutableArray *rubricsIdList = [[[NSMutableArray alloc] init] autorelease];
	NSMutableArray *rubricsNameList = [[[NSMutableArray alloc] init] autorelease];
	[viewDelegate.model getRubricsWithRecordedCategoryData:rubricsIdList names:rubricsNameList];
    
    // Begin report with styles
    NSMutableString *report = [NSMutableString stringWithFormat:@"\
                               <style type=\"text/css\">\
                               h2 {\
                               font-family:  Helvetica,Arial,sans-serif;\
                               font-size: 22px;\
                               }\
                               h3 {\
                               font-family:  Helvetica,Arial,sans-serif;\
                               font-size: 20px;\
                               }\
                               h4 {\
                               font-family:  Helvetica,Arial,sans-serif;\
                               font-size: 16px;\
                               font-weight: normal;\
                               margin: 0px;\
                               }\
                               .report {\
                               display: block;\
                               margin: 5px;\
                               }\
                               table th {\
                               min-width: 95px;\
                               font-family:  Helvetica,Arial,sans-serif;\
                               font-size: 12px;\
                               }\
                               table td {\
                               text-align: center;\
                               font-family:  Helvetica,Arial,sans-serif;\
                               font-size: 14px;\
                               }\
                               .green {\
                               background-color: #66FF33;\
                               }\
                               .yellow {\
                               background-color: #ffff66;\
                               }\
                               .red {\
                               background-color: #ff6666;\
                               }\
                               .gray {\
                               background-color: #666666;\
                               }\
                               </style>"];
    
    // Begin report
    [report appendFormat:@"<div>"];
    [report appendString:[self getReportHeader:@"Individual Performance"]];
    
    // Skip if no data
    if (numCategories == 0 ||
        [rubricsIdList count] == 0) {
        [report appendFormat:@"<br/><br/><div style=\"text-align:center;font-size:18px;font-style:italic;font-weight:bold;\">No rating scale data is available.</div>"];
        [report appendString:@"<br/><br/><i>Note: Self-evaluation and reflective data is not included in this report.</i>"];
        return report;
    }
    
    // Add target user info
	[report appendFormat:@"<h4>Name: %@</h4>", [TPUtil htmlSafeString:[targetUser getDisplayName]]];
	if ([targetUser.schools length]) [report appendFormat:@"<h4>School: %@</h4>", [TPUtil htmlSafeString:targetUser.schools]];
	if ([targetUser.subjects length]) [report appendFormat:@"<h4>Subject: %@</h4>", [TPUtil htmlSafeString:targetUser.subjects]];
	if ([[targetUser getGradeString] length]) [report appendFormat:@"<h4>Grade: %@</h4>", [TPUtil htmlSafeString:[targetUser getGradeString]]];
    
    // Loop over all recorded rubrics
    for (int i = 0; i < [rubricsIdList count]; i++) {
        
        rubricId = [[rubricsIdList objectAtIndex:i] intValue];
                    
        // Loop over all categories for current rubric and find those with data
		numCategories = 0;
        [categoryIdList removeAllObjects];
        [categoryNameList removeAllObjects];
        [categoryAggregateValueList removeAllObjects];
		for (TPCategory *category in viewDelegate.model.category_array) {
			if (category.state != 1) continue;
			foundData = [viewDelegate.model getCategoryAggregate:category.category_id
														rubricId:rubricId
													targetUserId:targetUser.user_id
													  userdataId:nil
														aggValue:&aggValue];
			if (foundData) {
				[categoryIdList addObject:[NSNumber numberWithInt:category.category_id]];
				[categoryNameList addObject:category.name];
				[categoryAggregateValueList addObject:[NSNumber numberWithFloat:aggValue]];
				numCategories++;
			}
		}
        
        // Skip if no category data
        if (numCategories == 0) continue;
        
        // Current rubric name
        int tableWidth = 95 * (numCategories + 1);
        
		[report appendFormat:@"<h3>%@</h3>", [TPUtil htmlSafeString:[rubricsNameList objectAtIndex:i]]];
		[report appendFormat:@"<table class=\"report\" style=\"width:%d;\" border=1 cellpadding=5 cellspacing=0>", tableWidth];
        
        // Header row of categories
		[report appendFormat:@"<tr><th>&nbsp;</th>"];
		for (int i = 0; i < [categoryIdList count]; i++) {
			NSString *category_name = [categoryNameList objectAtIndex:i];
			[report appendFormat:@"<th>%@</th>", [TPUtil htmlSafeString:category_name]];
		}
		[report appendFormat:@"</tr>"];
        
        // Initialize row
        int has_data = 0;
        NSMutableString *reportrow = [NSMutableString stringWithFormat:@""];
        
        // Add row for all recorded instances of this rubric
        [reportrow appendString:@"<tr><td><br/>All&nbsp;Rubrics<br/><br/></td>"];
        
        // Loop over all categories
        for (int j = 0; j < [categoryIdList count]; j++) {
            
            int category_id = [[categoryIdList objectAtIndex:j] intValue];
            
            foundData = [viewDelegate.model getCategoryAggregate:category_id
                                                        rubricId:rubricId
                                                    targetUserId:targetUser.user_id
                                                      userdataId:nil
                                                        aggValue:&aggValue];
        
            if (!foundData) {
                [reportrow appendFormat:@"<td>&nbsp;</td>"];
            } else if (aggValue < 1.5) {
                has_data = 1;
                [reportrow appendFormat:@"<td class=\"red\">%2.1f</td>", aggValue];
            } else if (aggValue < 2.5) {
                has_data = 1;
                [reportrow appendFormat:@"<td class=\"yellow\">%2.1f</td>", aggValue];
            } else {
                has_data = 1;
                [reportrow appendFormat:@"<td class=\"green\">%2.1f</td>", aggValue];
            }
        }
        [reportrow appendString:@"</tr>"];
        
        // Add row if data is available
        if (has_data == 1) {
            [report appendString:reportrow];
        }
        [self addDetailRubric:report targetUser:targetUser categoryIdList:categoryIdList rubricId:rubricId];
        
        [report appendString:@"</table><br/>"];
    } // End Loop over rubrics
    
        
    // Close out the report
    [report appendString:@"<br/><br/><i>Note: Self-evaluation and reflective data is not included in this report.</i>\
     </div>"];
    
    return report;
}

// --------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------
- (void) addDetailRubric:(NSMutableString *)report targetUser:(TPUser *)targetUser categoryIdList:(NSMutableArray *)categoryIdList rubricId:(int)rubricId {
    
    float aggValue;
    BOOL foundData;
    
    // List a report for each recorded rubric with a rating scale
    for (TPUserData *userdata in viewDelegate.model.userdata_list) {
        
        // Skip if not recording for specified rubric
        if (userdata.rubric_id != rubricId) continue;
        
        // Skip self-evaluations
        if (userdata.user_id == userdata.target_id) continue;
        
        // Skip if own-data filter set and not owned by user
        if (viewDelegate.model.useOwnData && userdata.user_id != viewDelegate.model.appstate.user_id) continue;
                
        // Initialize row
        int has_data = 0;
        NSMutableString *reportrow = [NSMutableString stringWithFormat:@""];        
        
            
        // Report aggregate values for this recorded rubric
        [reportrow appendFormat:@"<tr><td>%@ %@</td>", [TPUtil htmlSafeString:userdata.name], [viewDelegate.model prettyStringFromDate:userdata.created]];
                
        for (int j = 0; j < [categoryIdList count]; j++) {
            
            int category_id = [[categoryIdList objectAtIndex:j] intValue];
                                                            
            foundData = [viewDelegate.model getCategoryAggregate:category_id
                                                        rubricId:0
                                                    targetUserId:targetUser.user_id
                                                      userdataId:userdata.userdata_id
                                                        aggValue:&aggValue];
            if (!foundData) {
                [reportrow appendFormat:@"<td>&nbsp;</td>"];
            } else if (aggValue < 1.5) {
                has_data = 1;
                [reportrow appendFormat:@"<td class=\"red\">%2.1f</td>", aggValue];
            } else if (aggValue < 2.5) {
                has_data = 1;
                [reportrow appendFormat:@"<td class=\"yellow\">%2.1f</td>", aggValue];
            } else {
                has_data = 1;
                [reportrow appendFormat:@"<td class=\"green\">%2.1f</td>", aggValue];
            }
        }
        [reportrow appendString:@"</tr>"];
        
        // Add row if data is available
        if (has_data == 1) {
            [report appendString:reportrow];
        }

    } // End loop over userdata
}

// --------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------
- (NSString *) performanceComparisonReportByRubric:(int)rubricId rubricName:(NSString *)rubricName {
    
    BOOL foundData;
    float aggValue;
    int numCategories;
    int tableWidth;
        
    // Create temporary array to hold rubrics and categories to report
    NSMutableArray *categoryIdList = [[[NSMutableArray alloc] init] autorelease];
    NSMutableArray *categoryNameList = [[[NSMutableArray alloc] init] autorelease];
    NSMutableArray *categoryAggregateValueList = [[[NSMutableArray alloc] init] autorelease];
    	
    // Begin report
    NSMutableString *report = [NSMutableString stringWithFormat:@"\
                               <style type=\"text/css\">\
                               h2 {\
                               font-family:  Helvetica,Arial,sans-serif;\
                               font-size: 22px;\
                               }\
                               h3 {\
                               font-family:  Helvetica,Arial,sans-serif;\
                               font-size: 20px;\
                               }\
                               h4 {\
                               font-family:  Helvetica,Arial,sans-serif;\
                               font-size: 16px;\
                               font-weight: normal;\
                               margin: 0px;\
                               }\
                               .report {\
                               display: block;\
                               margin: 5px;\
                               }\
                               table th {\
                               min-width: 95px;\
                               font-family:  Helvetica,Arial,sans-serif;\
                               font-size: 12px;\
                               }\
                               table td {\
                               text-align: center;\
                               font-family:  Helvetica,Arial,sans-serif;\
                               font-size: 14px;\
                               }\
                               .green {\
                               background-color: #66FF33;\
                               }\
                               .yellow {\
                               background-color: #ffff66;\
                               }\
                               .red {\
                               background-color: #ff6666;\
                               }\
                               .gray {\
                               background-color: #666666;\
                               }\
                               </style>"];
    
    // Begin report
    [report appendFormat:@"<div>"];
    [report appendString:[self getReportHeader:@"Performance Comparison"]];
    
		// Current rubric name
		[report appendFormat:@"<h3>%@</h3>", [TPUtil htmlSafeString:rubricName]];
	
		// Loop over all categories for current rubric and find those with data
		numCategories = 0;
        [categoryIdList removeAllObjects];
        [categoryNameList removeAllObjects];
        [categoryAggregateValueList removeAllObjects];
		for (TPCategory *category in viewDelegate.model.category_array) {
			if (category.state != 1) continue;
			foundData = [viewDelegate.model getCategoryAggregate:category.category_id
														rubricId:rubricId
													targetUserId:0
													  userdataId:nil
														aggValue:&aggValue];
			if (foundData) {
				[categoryIdList addObject:[NSNumber numberWithInt:category.category_id]];
				[categoryNameList addObject:category.name];
				[categoryAggregateValueList addObject:[NSNumber numberWithFloat:aggValue]];
				numCategories++;
			}
		}
        
        // Current rubric name
        tableWidth = 95 * (numCategories + 1);
		[report appendFormat:@"<table class=\"report\" style=\"width:%d;\" border=1 cellpadding=5 cellspacing=0>", tableWidth];

		// Header row of categories
		[report appendFormat:@"<tr><th>&nbsp;</th>"];
		for (int i = 0; i < [categoryIdList count]; i++) {
			NSString *category_name = [categoryNameList objectAtIndex:i];
			[report appendFormat:@"<th>%@</th>", [TPUtil htmlSafeString:category_name]];
		}
		[report appendFormat:@"</tr>"];
    
		// Loop over all teacher
		NSMutableString *reportrow = [NSMutableString stringWithFormat:@""];
		int has_data;
		for (TPUser *user in viewDelegate.model.user_array) {
        
			// Add if have permission to view user
			if (user.permission > TP_PERMISSION_UNKNOWN) {
                            
				// Initialize the row
				has_data = 0;
				[reportrow setString:@""];
			
				// Add user name to row
				[reportrow appendFormat:@"<tr><td><br/>%@ %@<br/><br/></td>", [TPUtil htmlSafeString:user.first_name], [TPUtil htmlSafeString:user.last_name]];
            
				// Loop over all categories
				for (int i = 0; i < [categoryIdList count]; i++) {
                    
					int category_id = [[categoryIdList objectAtIndex:i] intValue];
                
					foundData = [viewDelegate.model getCategoryAggregate:category_id
																rubricId:rubricId
															targetUserId:user.user_id
															  userdataId:nil
																aggValue:&aggValue];
					if (!foundData) {
						[reportrow appendFormat:@"<td>&nbsp;</td>"];
					} else if (aggValue < 1.5) {
						has_data = 1;
						[reportrow appendFormat:@"<td class=\"red\">%2.1f</td>", aggValue];
					} else if (aggValue < 2.5) {
						has_data = 1;
						[reportrow appendFormat:@"<td class=\"yellow\">%2.1f</td>", aggValue];
					} else {
						has_data = 1;
							[reportrow appendFormat:@"<td class=\"green\">%2.1f</td>", aggValue];
						}
					}
					[reportrow appendString:@"</tr>"];
            
					// Add row if data is available
					if (has_data == 1) [report appendString:reportrow];
                
				} // End loop over categories
			} // End loop over teachers
		[report appendString:@"</table><br/>"];
                               
    // Close out the report
    [report appendString:@"<br/><br/><i>Note: Self-evaluation and reflective data is not included in this report.</i></div>"];
    
    return report;
}

// --------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------
- (NSString *) rubricCompletedReport {
    
    NSMutableString *report = [NSMutableString stringWithFormat:@"\
                               <style type=\"text/css\">\
                               h2 {\
                               font-family:  Helvetica,Arial,sans-serif;\
                               font-size: 22px;\
                               }\
                               h3 {\
                               font-family:  Helvetica,Arial,sans-serif;\
                               font-size: 20px;\
                               }\
                               h4 {\
                               font-family:  Helvetica,Arial,sans-serif;\
                               font-size: 16px;\
                               margin: 0px;\
                               font-weight: normal;\
                               }\
                               .report {\
                               width: 690px;\
                               }\
                               table th {\
                               min-width: 100px;\
                               font-family:  Helvetica,Arial,sans-serif;\
                               font-size: 14px;\
                               }\
                               table td {\
                               text-align: center;\
                               font-family:  Helvetica,Arial,sans-serif;\
                               font-size: 14px;\
                               }\
                               .green {\
                               background-color: #66FF33;\
                               }\
                               .yellow {\
                               background-color: #ffff66;\
                               }\
                               .red {\
                               background-color: #ff6666;\
                               }\
                               .gray {\
                               background-color: #666666;\
                               }\
                               .paleblue {\
                               background-color: #bdeaff;\
                               }\
                               .lightgray {\
                               background-color: #eeeeee;\
                               }\
                               </style>"];
                               
    // Begin report
    [report appendFormat:@"<div class=\"report\""];
    [report appendString:[self getReportHeader:@"Forms completed"]];
    
    [report appendFormat:@"<br/><br/>\
     <table border=1 cellpadding=5 cellspacing=0>\
     <tr>\
     <th>&nbsp;</th>\
     <th>This Year</th>\
     <th>This Semester</th>\
     <th>30 Days</th>\
     <th>Week</th>\
     <th>Today</th>\
     </tr>"];
    
    // [database getNumRubricsRecorded:targetId timeRange:timeRange rubricId:rubricId]
    
    // Report number rubrics recorded for all users
    [report appendFormat:@"<tr><td class=\"lightgray\"><br/>All&nbsp;Users<br/><br/></td>"];
    [report appendFormat:@"<td class=\"lightgray\">%d</td>", [viewDelegate.model getNumRubricsRecorded:0 timeRange:TIME_RANGE_YEAR rubricId:0]];
    [report appendFormat:@"<td class=\"lightgray\">%d</td>", [viewDelegate.model getNumRubricsRecorded:0 timeRange:TIME_RANGE_SEMESTER rubricId:0]];
    [report appendFormat:@"<td class=\"lightgray\">%d</td>", [viewDelegate.model getNumRubricsRecorded:0 timeRange:TIME_RANGE_MONTH rubricId:0]];
    [report appendFormat:@"<td class=\"lightgray\">%d</td>", [viewDelegate.model getNumRubricsRecorded:0 timeRange:TIME_RANGE_WEEK rubricId:0]];
    [report appendFormat:@"<td class=\"lightgray\">%d</td>", [viewDelegate.model getNumRubricsRecorded:0 timeRange:TIME_RANGE_DAY rubricId:0]];
    [report appendString:@"</tr>"];
    
    // List a report for each recorded rubric with a rating scale
    NSString *style;
    NSMutableString *reportrow = [NSMutableString stringWithFormat:@""];
    int has_data;
    int count;
    int countRows = 0;
    for (TPUser *user in viewDelegate.model.user_array) {
        
        if (user.permission > TP_PERMISSION_UNKNOWN) {
            
            // Initialize the row
            has_data = 0;
            [reportrow setString:@""];
            
            if (user.user_id == viewDelegate.model.appstate.target_id) {
                style = @" class=\"paleblue\"";
            } else {
                style = @"";
            }
            [reportrow appendFormat:@"<tr><td %@>%@ %@</td>", style,
             [TPUtil htmlSafeString:user.first_name], [TPUtil htmlSafeString:user.last_name]];
            count = [viewDelegate.model getNumRubricsRecorded:user.user_id timeRange:TIME_RANGE_YEAR rubricId:0];
            if (count > 0) has_data = 1;
            [reportrow appendFormat:@"<td %@>%d</td>", style, count];
            count = [viewDelegate.model getNumRubricsRecorded:user.user_id timeRange:TIME_RANGE_SEMESTER rubricId:0];
            if (count > 0) has_data = 1;
            [reportrow appendFormat:@"<td %@>%d</td>", style, count];
            count = [viewDelegate.model getNumRubricsRecorded:user.user_id timeRange:TIME_RANGE_MONTH rubricId:0];
            if (count > 0) has_data = 1;
            [reportrow appendFormat:@"<td %@>%d</td>", style, count];
            count = [viewDelegate.model getNumRubricsRecorded:user.user_id timeRange:TIME_RANGE_WEEK rubricId:0];
            if (count > 0) has_data = 1;
            [reportrow appendFormat:@"<td %@>%d</td>", style, count];
            count = [viewDelegate.model getNumRubricsRecorded:user.user_id timeRange:TIME_RANGE_DAY rubricId:0];
            if (count > 0) has_data = 1;
            [reportrow appendFormat:@"<td %@>%d</td>", style, count];
            [reportrow appendString:@"</tr>"];
            
            // Add row if data is available
            if (has_data == 1) {
                [report appendString:reportrow];
                countRows++;
            }
        }
    }
    
    // If no users with recorded forms then add top row
    if (countRows == 0) {
    }
    
    // Close out the report
    [report appendString:@"\
     </table>\
     <i>Note: Self-evaluation and reflective data is not included in this report.</i>\
     </div>"];
    
    return report;
}

// --------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------
- (NSString *) advancedRubricReport:(int)rubricId rubricName:(NSString *)rubricName {
    
    //NSLog(@"advancedRubricReport with rubric ID %d", rubricId);
    
    // Add report style
    NSMutableString *html = [NSMutableString stringWithString:@"\
							 <style type=\"text/css\">\
                             h2 {\
                             font-family:  Helvetica,Arial,sans-serif;\
                             font-size: 22px;\
                             }\
                             h3 {\
                             font-family:  Helvetica,Arial,sans-serif;\
                             font-size: 20px;\
                             margin-bottom:5px;\
                             }\
                             h4 {\
                             font-family:  Helvetica,Arial,sans-serif;\
                             font-size: 16px;\
                             margin: 0px;\
                             font-weight: normal;\
                             }\
							 body {\
                             background-color: white;\
                             }\
                             </style>"];
	
	// target user and userdata
	TPUser *user = [viewDelegate.model getCurrentTarget];

    // Add bar chart style
    [html appendString:[self getReportBarChartStyle]];
    
    // Begin report
    [html appendString:[self getReportHeader:[NSString stringWithFormat:@"%@ (Detailed Report)", [TPUtil htmlSafeString:rubricName]]]];
	
	// Add target user info
	[html appendFormat:@"<h4>Name: %@</h4>", [TPUtil htmlSafeString:[user getDisplayName]]];
	if ([user.schools length]) [html appendFormat:@"<h4>School: %@</h4>", [TPUtil htmlSafeString:user.schools]];
	if ([user.subjects length]) [html appendFormat:@"<h4>Subject: %@</h4>", [TPUtil htmlSafeString:user.subjects]];
	if ([[user getGradeString] length]) [html appendFormat:@"<h4>Grade: %@</h4>", [TPUtil htmlSafeString:[user getGradeString]]];
    
	// Add recording and elapsed times
	NSMutableArray *datesList = [[[NSMutableArray alloc] init] autorelease];
    NSMutableArray *evaluatorList = [[[NSMutableArray alloc] init] autorelease];
	NSMutableArray *elapsedList = [[[NSMutableArray alloc] init] autorelease];
	[viewDelegate.model.database getRecordingsForRubricId:rubricId
                                                    dates:datesList
                                               evaluators:evaluatorList
                                             elapsedTimes:elapsedList
                                             filterUserId:(viewDelegate.model.useOwnData?viewDelegate.model.appstate.user_id:0)];
	[html appendString:[self getElapsedTable:rubricId datesList:datesList evaluatorList:evaluatorList elapsedList:elapsedList]];
	
    // Get the question list for this rubric
    NSMutableArray *questionList = [[[NSMutableArray alloc] init] autorelease];
    [viewDelegate.model getQuestionListByRubricId:questionList rubricId:rubricId];
    
    // Initialize some temporary arrays
    NSMutableArray *statList = [[[NSMutableArray alloc] init] autorelease];
    NSMutableArray *ratingIdList = [[[NSMutableArray alloc] init] autorelease];
    NSMutableArray *ratingList = [[[NSMutableArray alloc] init] autorelease];
	NSMutableArray *textResponcesList = [[[NSMutableArray alloc] init] autorelease];
    NSMutableArray *annotationsList = [[[NSMutableArray alloc] init] autorelease];
    NSMutableArray *tableEntries = [[[NSMutableArray alloc] initWithCapacity:40] autorelease];
    
    // Loop over all question in the rubric
    for (TPQuestion *question in questionList) {
        
        // Skip reflection questions
        if ([question isQuestionReflection]) continue;
        
        switch (question.type) {
                
            case TP_QUESTION_TYPE_RATING:
            case TP_QUESTION_TYPE_UNISELECT:
            case TP_QUESTION_TYPE_MULTISELECT:
                
                // Get the list of all possible answers for this question
                //NSLog(@"Question: %@", question.title);
                [ratingList removeAllObjects];
                for (TPRating *rating in viewDelegate.model.rating_array) {
                    if (rating.question_id == question.question_id) {
                        [ratingList addObject:rating];
                        //NSLog(@"  Answer: %d %d %f %@", rating.rating_id, rating.rorder, rating.value, rating.text);
                    }
                }
                
                // Find recorded data for this question
                int total = 0;
                [viewDelegate.model.database getQuestionStatsForQuestionId:question.question_id
                                                             totalRecorded:&total
                                                                  statList:statList
                                                              ratingIdList:ratingIdList
															  filterUserId:(viewDelegate.model.useOwnData?viewDelegate.model.appstate.user_id:0)];
                
				// If data was found create bar chart and table                
                if (total > 0) {
					
                    
					// Loop over all answers defined for this question and build table of data
                    [tableEntries removeAllObjects];
                    for (int i = 0; i < [ratingList count]; i++) {
                        
                        // Init report table
                        TPReportTableEntry *entry = [[TPReportTableEntry alloc] init];
                        
                        // Get this rating
                        TPRating *thisRating = [ratingList objectAtIndex:i];
                        
                        // Find stat for this rating
                        int statIndex = -1;
                        int rating_id;
                        for (int j = 0; j < [ratingIdList count]; j++) {
                            rating_id = [[ratingIdList objectAtIndex:j] intValue];
                            if (rating_id == thisRating.rating_id) {
                                statIndex = j;
                                break;
                            }
                        }
                                                
                        // Get the stats for this answer
						if (statIndex > -1) {
							entry.count = [[statList objectAtIndex:statIndex] intValue];
						} else {
							entry.count = 0;
						}
			
                        // Create a row label to use for chart
                        if (question.type == TP_QUESTION_TYPE_RATING) {
                            if ([thisRating.title length] == 0) {
                                entry.text = [TPRating getDefaultRatingScaleTitle:thisRating.rorder];
                            } else {
                                entry.text = thisRating.title;
                            }
                        } else {
                            entry.text = thisRating.text;
                        }
                        
                        // Add entry to table
                        [tableEntries addObject:entry];
                        [entry release];
                    }
                    
                    // Add the bar chart and table data
                    if (question.type == TP_QUESTION_TYPE_RATING)
                    {
                        [html appendString:[self getRatingsReportBarChart:question.title totalRecorded:total entries:tableEntries]];
                    }
                    else
                    {
                        [html appendString:[self getReportBarChart:question.title totalRecorded:total entries:tableEntries]];
                    }
                    
                    // Find recorded annotations for this quesiton
                    [viewDelegate.model.database getAnnotationsForQuestion:question.question_id 
                                                                   entries:annotationsList 
                                                              filterUserId:(viewDelegate.model.useOwnData?viewDelegate.model.appstate.user_id:0)];
                    // add annotations summary
                    if ([annotationsList count])
                    {
                        [html appendString:[self getTextListing:@""/*question.title*/ entries:annotationsList]];
                    }
                    //else
                    //{
                    //    [html appendFormat: @"<h3>%@</h3>", [TPUtil htmlSafeString:@"Annotations"/*question.title*/]];
                    //    [html appendFormat: @"&nbsp;&nbsp;&nbsp;&nbsp;<i>No annotations recorded for this question</i>"];
                    //}
                
                // Otherwise indicate no data was found for this question
                } else {
                    [html appendFormat: @"<h3>%@</h3>", [TPUtil htmlSafeString:question.title]];
                    [html appendFormat: @"&nbsp;&nbsp;&nbsp;&nbsp;<i>No data recorded for this question</i>"];
                }
                
				break;
            case TP_QUESTION_TYPE_TEXT:
				
				[viewDelegate.model.database getTextResponsesForQuestion:question.question_id entries:textResponcesList  filterUserId:(viewDelegate.model.useOwnData?viewDelegate.model.appstate.user_id:0)];
				if ([textResponcesList count])
				{
					[html appendString:[self getTextListing:question.title entries:textResponcesList]];
				}
				else
				{
					[html appendFormat: @"<h3>%@</h3>", [TPUtil htmlSafeString:question.title]];
                    [html appendFormat: @"&nbsp;&nbsp;&nbsp;&nbsp;<i>No data recorded for this question</i>"];
				}
					
				break;
        } // End switch on question types
        
    } // End loop over questions in rubric
    
	[html appendString:@"</tbody></table>"];
	[html appendString:@"<br/><br/><i>Note: Self-evaluation and reflective data is not included in this report.</i>"];
    
    //NSLog(@"%@", html);
    
    return html;
}

// --------------------------------------------------------------------------------------
- (NSString *) getElapsedTable:(int)rubricId datesList:(NSMutableArray *)datesList evaluatorList:(NSMutableArray *)evaluatorList elapsedList:(NSMutableArray *)elapsedList {
	
    int tableWidth = 680;
    int totalTime = 0;
        
    TPRubric *rubric = [viewDelegate.model getRubricById:rubricId];
    
    NSMutableString* html = [[[NSMutableString alloc] initWithString:@""] autorelease];
    
    // Begin table
    [html appendFormat: @"<h3>Recording and elapsed times</h3>"];
    [html appendFormat: @"<table width=\"%d\" class=\"graph\" cellspacing=\"6\" cellpadding=\"0\">", tableWidth];
    [html appendString:@"<tr>"];
	[html appendString:@"<th align=center width=\"220\">Date</th>"];
    [html appendString:@"<th align=center width=\"220\">Evaluator</th>"];
    if (rubric.rec_elapsed == 1) {
        [html appendString:@"<th align=center width=\"220\">Elapsed Time</th>"];
    } else {
        [html appendString:@"<th align=center width=\"220\">&nbsp;</th>"];
    }
    [html appendString:@"</tr>"];
	
    // Loop over all recordings and add row for each
	for (int i = 0; i < [datesList count]; i++) {
        [html appendString:@"<tr>"];
		[html appendFormat:@"<td align=center width=\"220\">%@</td>", [viewDelegate.model prettyStringFromDate:[datesList objectAtIndex:i]]];
        [html appendFormat:@"<td align=center width=\"220\">%@</td>", [evaluatorList objectAtIndex:i]];
		if (rubric.rec_elapsed == 1) {
			[html appendFormat:@"<td align=center width=\"220\">%@</td>", [TPUtil formatElapsedTime:[[elapsedList objectAtIndex:i] intValue]]];
            totalTime += [[elapsedList objectAtIndex:i] intValue];
		} else {
			[html appendFormat:@"<td align=center width=\"220\">&nbsp;</td>"];
		}
        [html appendString:@"</tr>"];
	}
    
    [html appendString:@"</table>"];
    
    // Total time
    if (rubric.rec_elapsed == 1) {
        [html appendFormat:@"<div style=\"width:680px;text-align:right\">Total elapsed time is %@</div>", [TPUtil formatElapsedTime:totalTime]];
    }
    
    return html;
}

// --------------------------------------------------------------------------------------
- (NSString *) getReportBarChartStyle {
    NSString *html = @"\
                      <style type=\"text/css\">\
                      .graph {\
                      background-color: white;\
                      }\
                      table.graph {\
                      border: solid 1px #aaaaaa;\
                      }\
                      .graph td {\
                      font-family: verdana, arial, sans serif;\
                      font-size: 14px;\
                      }\
                      .graph thead th {\
                      border-bottom: double 3px black;\
                      font-family: verdana, arial, sans serif;\
                      padding: 1em;\
                      }\
                      .graph tfoot td {\
                      border-top: solid 1px #999999;\
                      font-size: x-small;\
                      text-align: center;\
                      padding: 0;\
                      color: #666666;\
                      }\
                      .bar {\
                      background-color: white;\
                      text-align: right;\
                      border: solid 1px black;\
                      padding-right: 0;\
                      width: 400px;\
                      }\
                      td.bar {\
                      border: solid 1px #999999;\
                      }\
                      .bar div {\
                      background-color: #7f80ff;\
                      text-align: right;\
                      color: white;\
                      float: left;\
                      padding-top: 0;\
                      height: 1.2em;\
                      }\
                      td.barred {\
                      border: solid 1px #999999;\
                      }\
                      .barred div {\
                      background-color: #f14a4a;\
                      text-align: right;\
                      color: white;\
                      float: left;\
                      padding-top: 0;\
                      height: 1.2em;\
                      }\
                      td.baryellow {\
                      border: solid 1px #999999;\
                      }\
                      .baryellow div {\
                      background-color: #ffff99;\
                      text-align: right;\
                      color: white;\
                      float: left;\
                      padding-top: 0;\
                      height: 1.2em;\
                      }\
                      td.bargreen {\
                      border: solid 1px #999999;\
                      }\
                      .bargreen div {\
                      background-color: #66ff66;\
                      text-align: right;\
                      color: white;\
                      float: left;\
                      padding-top: 0;\
                      height: 1.2em;\
                      }\
                      </style>";
    return html;
}

// --------------------------------------------------------------------------------------
- (NSString *) getReportBarChart:(NSString *)questionTitle totalRecorded:(int)totalRecorded entries:(NSArray *)entries {

    int tableWidth = 680;
    int maxTextLength = 30;
    
    NSMutableString* html = [[[NSMutableString alloc] initWithString:@""] autorelease];
    
    [html appendFormat: @"<h3>%@</h3>", [TPUtil htmlSafeString:questionTitle]];
    
    [html appendFormat: @"<table width=\"%d\" class=\"graph\" cellspacing=\"6\" cellpadding=\"0\">", tableWidth];
    
    for (TPReportTableEntry *entry in entries) {
        NSString *percentage = [NSString stringWithFormat:@"%d%%", (int)((float)entry.count/totalRecorded*100.0)];
        if ([entry.text length] > maxTextLength) {
            [html appendFormat:@"<tr><td align=right width=\"270\">%@...</td>", [TPUtil htmlSafeString:[entry.text substringToIndex:(maxTextLength-1)]]];
        } else {
            [html appendFormat:@"<tr><td align=right width=\"270\">%@</td>", [TPUtil htmlSafeString:entry.text]];
        }
        [html appendFormat:@"<td width=\"400\" class=\"bar\"><div style=\"width: %@\"></div></td><td>%d&nbsp;%@</td></tr>",
         percentage,
         entry.count, 
         [TPUtil htmlSafeString:percentage]];
    }
    [html appendString: @"</tbody></table>"];
    
    return html;
}

// --------------------------------------------------------------------------------------
- (NSString *) getRatingsReportBarChart:(NSString *)questionTitle totalRecorded:(int)totalRecorded entries:(NSArray *)entries {
    
    int tableWidth = 680;
    int maxTextLength = 30;
    NSArray *chartColors = [NSArray arrayWithObjects:@"bargreen", @"bargreen", @"baryellow", @"barred", nil];
    
    NSMutableString* html = [[[NSMutableString alloc] initWithString:@""] autorelease];
    
    [html appendFormat: @"<h3>%@</h3>", [TPUtil htmlSafeString:questionTitle]];
    
    [html appendFormat: @"<table width=\"%d\" class=\"graph\" cellspacing=\"6\" cellpadding=\"0\">", tableWidth];
    
    for (int i=0; i<4; i++) {
        TPReportTableEntry *entry = [entries objectAtIndex:i];
        NSString *percentage = [NSString stringWithFormat:@"%d%%", (int)((float)entry.count/totalRecorded*100.0)];
        if ([entry.text length] > maxTextLength) {
            [html appendFormat:@"<tr><td align=right width=\"270\">%@...</td>", [TPUtil htmlSafeString:[entry.text substringToIndex:(maxTextLength-1)]]];
        } else {
            [html appendFormat:@"<tr><td align=right width=\"270\">%@</td>", [TPUtil htmlSafeString:entry.text]];
        }
        [html appendFormat:@"<td width=\"400\" class=\"%@\"><div style=\"width: %@\"></div></td><td>%d&nbsp;%@</td></tr>",
         [chartColors objectAtIndex:i],
         percentage,
         entry.count, 
         [TPUtil htmlSafeString:percentage]];
    }
    [html appendString: @"</tbody></table>"];
    
    return html;
}

// --------------------------------------------------------------------------------------
- (NSString *) getTextListing:(NSString *)questionTitle entries:(NSArray *)entries {
	
    int maxTextLength = 10000;
	BOOL isFirst = TRUE;
    
    NSMutableString* html = [[[NSMutableString alloc] initWithString:@""] autorelease];
    
    if ([questionTitle length] > 0) {
      [html appendFormat: @"<h3>%@</h3>", [TPUtil htmlSafeString:questionTitle]];
    }

    [html appendString:@"<div style=\"width:680px;text-align:right\">"];
    for (NSString *entry in entries) {
		if (!isFirst) {
			[html appendString:@" | "];
		}
		if ([entry length] > maxTextLength) {
            [html appendFormat:@"%@...", [TPUtil htmlSafeString:[entry substringToIndex:(maxTextLength-1)]]];
        } else {
            [html appendFormat:@"%@", [TPUtil htmlSafeString:entry]];
        }
		isFirst = FALSE;
    }
    [html appendString:@"</div>"];
    
    [html appendString: @"<br />"];
    
    return html;
}

// --------------------------------------------------------------------------------------
- (NSString *) getReportHeader:(NSString *)reportTitle {
	    
    NSMutableString* html = [[[NSMutableString alloc] initWithString:@""] autorelease];
    
    [html appendFormat:@"<div style=\"text-align:center;font-family:Helvetica,Arial,sans-serif;\">"];
    [html appendFormat:@"<span style=\"font-size:20px;font-weight:bold;\">%@</span><br/>", viewDelegate.model.appstate.district_name];
    [html appendFormat:@"<span style=\"font-size:18px;\">%@</span><br/>", reportTitle];
    [html appendFormat:@"<span style=\"font-size:16px;\">%@</span><br/>", [viewDelegate.model prettyStringFromDate:[NSDate date] newline:FALSE]];
    [html appendFormat:@"</div>"];
    
    return html;
}

@end

// --------------------------------------------------------------------------------------
@implementation TPReportTableEntry

@synthesize text;
@synthesize count;

@end

// --------------------------------------------------------------------------------------
