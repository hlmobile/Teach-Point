//
//  TPInfo.m
//  teachpoint
//
//  Created by Chris Dunn on 4/6/11.
//  Copyright 2011 Clear Pond Technologies, Inc. All rights reserved.
//

#import "TPData.h"
#import "TPView.h"
#import "TPModel.h"
#import "TPInfo.h"
#import "TPUtil.h"

@implementation TPInfoVC

// --------------------------------------------------------------------------------------
- (id)initWithView:(TPView *)mainview {

    self = [super init];
    if (self) {
        
        viewDelegate = mainview;
                        
		rightbutton = [[UIBarButtonItem alloc] 
                       initWithTitle:@"Options" 
                       style: UIBarButtonItemStylePlain
                       target: self 
                       action: @selector(showoptions)];
		//self.navigationItem.rightBarButtonItem = rightbutton; //jxi;
        
        webView = [[UIWebView alloc] init];
        webView.dataDetectorTypes = UIDataDetectorTypeNone;
        [webView loadHTMLString:@"" baseURL:[NSURL URLWithString:@""]];
        webView.scalesPageToFit = YES;
        webView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
        
        // Create view control button (segmented)
        viewControl = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"Forms", @"Info", @"Reports", nil]];
        viewControl.segmentedControlStyle = UISegmentedControlStyleBar;
        viewControl.frame = CGRectMake(10, 10, 280, 30);
        [viewControl addTarget:self action:@selector(switchView) forControlEvents:UIControlEventValueChanged];
        
        //self.navigationItem.titleView = viewControl; //jxi; modified;
        self.navigationItem.prompt = @"";
        self.navigationItem.hidesBackButton = YES;
    }
    return self;
}

// --------------------------------------------------------------------------------------
- (void)dealloc {
    [self release];
    [super dealloc];
}

- (void)loadView {
    [super loadView];
    if ([TPUtil isPortraitOrientation]) {
        webView.frame = CGRectMake(0, 0, 768, 930);
    } else {
        webView.frame = CGRectMake(0, 0, 704, 674);
    }
    [self.view addSubview:webView];
    self.view.backgroundColor = [UIColor grayColor];
}

- (void)viewDidAppear:(BOOL)animated {
    [viewDelegate.model setCurrentMainViewState:@"info"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated {
    [self resetPrompt];
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

// --------------------------------------------------------------------------------------

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration {
    if (debugRotate) NSLog(@"TPInfoVC willRotateToInterfaceOrientation");
}

- (void)viewWillLayoutSubviews {
    if (debugRotate) NSLog(@"TPInfoVC viewWillLayoutSubviews");
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration {
    if (debugRotate) NSLog(@"TPInfoVC willAnimateRotationToInterfaceOrientation");
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    if (debugRotate) NSLog(@"TPInfoVC didRotateFromInterfaceOrientation");
    if ([TPUtil isPortraitOrientation]) {
        webView.frame = CGRectMake(0, 0, 768, 930);
    } else {
        webView.frame = CGRectMake(0, 0, 704, 674);
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    if (debugRotate) NSLog(@"TPInfoVC shouldAutorotateToInterfaceOrientation");
    return YES;
}

// --------------------------------------------------------------------------------------
- (void) reset {
    
    // Reset the user name and district
    [self resetPrompt];
    
    // Load subject general info after wrapping with style info and converting newlines
    [webView loadHTMLString:[self getCurrentTargetInfoPage] baseURL:[NSURL URLWithString:@""]];
}

- (void)resetPrompt {
    self.navigationItem.prompt = [viewDelegate.model getDetailViewPromptString];
}


- (void) clearContent {
    
    // Reset the user name and district
    [self resetPrompt];
    
    // Load subject general info after wrapping with style info and converting newlines
    [webView loadHTMLString:@"" baseURL:[NSURL URLWithString:@""]];
}

- (void) switchView {
	[viewDelegate switchView:viewControl.selectedSegmentIndex];
}

- (void) setSelectedView:(int)index {
    viewControl.selectedSegmentIndex = index;
}

- (void) showoptions {
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

// ---------------------------------------------------------------------------------------
// getCurrentTargetInfoPage - return user info page
// ---------------------------------------------------------------------------------------
- (NSString *) getCurrentTargetInfoPage {
        
    // Get the current target user's info
    TPUserInfo *userinfo = [viewDelegate.model getCurrentTargetInfo];
    
    // If no info record then return warning string
    if (userinfo == nil) {
        NSString *content = [NSString stringWithFormat:@"\
                             <div style=\"font-size:16px;font-family:Helvetica,Arial,sans-serif;color:#000000;text-align:center;\">\
                             <br>\
                             <br>\
                             &nbsp;&nbsp;&nbsp;&nbsp;\
                             <i>- No information for selected user -</i>\
                             </div>"];
        return content;
    }
    
    // If text record then convert spaces and newlines
    if (userinfo.type == 1) {
        NSString *content1 = [userinfo.info stringByReplacingOccurrencesOfString:@"\n" withString:@"<br>"];
        NSString *content2 = [content1 stringByReplacingOccurrencesOfString:@" " withString:@"&nbsp;"];
        NSString *content3 = [NSString stringWithFormat:@"\
                              <div style=\"font-size:16px;font-family:Courier;color:#000000;\">\
                              %@\
                              </div>",
                              content2];
        return content3;
    }
    
    // If html record then prepend with style
    if (userinfo.type == 2) {
        NSString *content = [NSString stringWithFormat:@"\
                             <style type=\"text/css\">\
                             .normal {\
                             font-family: Helvetica,Arial,sans-serif;\
                             font-size: 16px;\
                             }\
                             h1 {\
                             font-family: Helvetica,Arial,sans-serif;\
                             font-size: 22px;\
                             margin: 0px;\
                             padding: 4px 0px 4px 0;\
                             }\
                             h2 {\
                             font-family: Helvetica,Arial,sans-serif;\
                             font-size: 20px;\
                             margin: 0px;\
                             padding: 4px 0px 4px 0;\
                             }\
                             h3 {\
                             font-family: Helvetica,Arial,sans-serif;\
                             font-size: 18px;\
                             margin: 0px;\
                             padding: 4px 0px 4px 0;\
                             }\
                             </style>\
                             <div class=\"normal\">\
                             %@\
                             </div>",
                             userinfo.info];
        return content;
    }
    
    return @"";
}

@end
