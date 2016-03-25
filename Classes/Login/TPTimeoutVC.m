#import "TPData.h"
#import "TPModel.h"
#import "TPModelSync.h"
#import "TPView.h"
#import "TPTimeoutVC.h"
#import "TPRoundRect.h"
#import "TPUtil.h"
#import "TPCompat.h"

#define MAX_BAD_ACCESS 1000 // Effectively disable auto-wipe since we can't access data if app was killed and restarted

//------------------------------------------------------------------------------------------------
// TPTimeoutVC - is the view presented after the application becomes active and the user is
// already logged in (after awaking from sleep or switching applications).
//------------------------------------------------------------------------------------------------
@implementation TPTimeoutVC

//------------------------------------------------------------------------------------------------
- (id) initWithView:(TPView *)delegate {
	
	self = [ super init ];
	if (self != nil) {
        
		viewDelegate = delegate;
		
        strikes = 0;
        
        UIImage *logoImage = [UIImage imageNamed:@"logo.png"];
        UIImageView *logoView = [[[UIImageView alloc] initWithImage:logoImage] autorelease];
        self.navigationItem.titleView = logoView;
        
        // Origin must be 0,0 for autoresizing to work
        wholeview = [[UIView alloc] initWithFrame:CGRectMake(0,0,768,400)];
		wholeview.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        
		message = [[[UITextView alloc] initWithFrame:CGRectMake(134, 60, 500, 60)] autorelease];
		message.text = @"Please enter your password...";
		message.textAlignment = TPTextAlignmentCenter;
		message.editable = 0;
		message.backgroundColor = [UIColor clearColor];
		message.textColor = [UIColor whiteColor];
		message.font = [UIFont fontWithName:@"Helvetica" size:26.0];
        [wholeview addSubview:message];
		
        roundrect = [[[TPRoundRectView alloc] initWithFrame:CGRectMake(234, 120, 300, 220)] autorelease];
		roundrect.rectColor = [UIColor colorWithWhite:0.1 alpha:0.6];
		roundrect.strokeColor = [UIColor clearColor];
		roundrect.cornerRadius = 20.0;
        [wholeview addSubview:roundrect];
        
		districtname = [[[UILabel alloc] initWithFrame:CGRectMake(239, 150, 290, 30)] autorelease];
		districtname.text = viewDelegate.model.publicstate.district_name;
		districtname.textColor = [UIColor whiteColor];
		districtname.backgroundColor = [UIColor clearColor];
		districtname.font = [UIFont fontWithName:@"Helvetica" size:16.0];
		districtname.textAlignment = TPTextAlignmentCenter;
        [wholeview addSubview:districtname];
		
        username = [[[UILabel alloc] initWithFrame:CGRectMake(239, 180, 290, 30)] autorelease];
		username.text = [NSString stringWithFormat:@"%@ %@", viewDelegate.model.publicstate.first_name, viewDelegate.model.publicstate.last_name];
		username.textColor = [UIColor whiteColor];
		username.backgroundColor = [UIColor clearColor];
		username.font = [UIFont fontWithName:@"Helvetica" size:16.0];
		username.textAlignment = TPTextAlignmentCenter;
        [wholeview addSubview:username];
				
		passwordtext = [[UITextField alloc] initWithFrame:CGRectMake(259, 230, 250, 30)];
        passwordtext.text = @"";
		passwordtext.borderStyle = 3;
		passwordtext.adjustsFontSizeToFitWidth = YES;
		passwordtext.clearsOnBeginEditing = NO;
		passwordtext.secureTextEntry = YES;
		passwordtext.delegate = self;
		[wholeview addSubview:passwordtext];
		
		loginbutton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
		loginbutton.frame = CGRectMake(344, 290, 80, 30);
        loginbutton.titleLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:16.0];
		[loginbutton setTitle:@"OK" forState:UIControlStateNormal];
		[loginbutton addTarget:self action:@selector(access) forControlEvents:UIControlEventTouchUpInside];
        [wholeview addSubview:loginbutton];
    }
	return self;
}

//------------------------------------------------------------------------------------------------
- (void) dealloc {
    if (debugLogin) NSLog(@"TPTimeoutVC dealloc");
    [passwordtext release];
	[wholeview release];
    [super dealloc];
}

//------------------------------------------------------------------------------------------------
- (void) loadView {
    if (debugLogin) NSLog(@"TPTimeoutVC loadView");
	[super loadView];		
	[self.view addSubview:wholeview];
	self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"linen.png"]]; 
}

//------------------------------------------------------------------------------------------------
- (void)didReceiveMemoryWarning {
    if (debugLogin) NSLog(@"TPTimeout didReceiveMemoryWarning");
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

//------------------------------------------------------------------------------------------------
// access - try to access main screen from timeout after user selects OK button
//------------------------------------------------------------------------------------------------
- (void) access {
    
    if (debugLogin) NSLog(@"TPTimeoutVC access");
    
    // Get hash password entered by user
    NSString *hashedpassword = [TPUtil getPasswordHash:passwordtext.text];
        
    // If password matches then exit timeout screen (go back to main screen)
    if ([hashedpassword isEqualToString:viewDelegate.model.publicstate.hashed_password] || viewDelegate.model.publicstate.is_demo == 1) {
        
        [viewDelegate.model initDatabase]; // Initialize database now that we have a password (in case closed)
        
        if (debugLogin) NSLog(@"TPTimeoutVC password OK");
        strikes = 0;
        viewDelegate.model.logoutAfterSync = NO;
        
        // Unarchive private state and data
        if (viewDelegate.model.publicstate.is_demo == 0) {
          [viewDelegate.model unarchiveState:passwordtext.text];
        } else {
            [viewDelegate.model unarchiveState:@"jledemo4tPpaSS"];
        }
        [viewDelegate.model unarchiveData];
        // Compute derived rubric list
        [viewDelegate.model deriveData];
        
        // Exit timeout screen
        [viewDelegate exittimeoutscreen];
        // Reset sync button
        //[viewDelegate.model setNeedSyncStatusFromUnsyncedCount:YES];
        //[viewDelegate setSyncStatus];
        
    // Otherwise handle bad password
    } else {
        strikes++;
        passwordtext.text = @"";
        if (debugLogin) NSLog(@"TPTimeoutVC password bad %d strikes", strikes);
        // If three strikes then try to logout
        if (strikes >= MAX_BAD_ACCESS) {
            // If no data to sync then logout immediately
            if ([viewDelegate.model getUserDataUnsyncedCount] == 0) {
                if (debugLogin) NSLog(@"TPTimeoutVC no data to sync - logging out");
                strikes = 0;
				[viewDelegate returnFromOpenedView];
                [viewDelegate logout];
                [viewDelegate exittimeoutscreen];
            // Otherwise sync first but set logout flag to logout if sync successful
            } else {
                if (debugLogin) NSLog(@"TPTimeoutVC data to sync - syncing with logout");
                viewDelegate.model.logoutAfterSync = YES;
                [viewDelegate syncNow:SYNC_TYPE_CLIENTDATA];
            }
        } else {
            UIAlertView *alert = [[UIAlertView alloc]
                                  initWithTitle:@""
                                  message:@"\nIncorrect password\n\n"
                                  delegate:self
                                  cancelButtonTitle: nil
                                  otherButtonTitles: @"OK", nil];
            [alert show];
            [alert release];
        }
    }
}

//------------------------------------------------------------------------------------------------
- (void) reset {
    
    if (debugLogin) NSLog(@"TPTimeoutVC reset");
    
    // Remove optional elements
    [passwordtext removeFromSuperview];
    
    // If demo account
    if (viewDelegate.model.publicstate.is_demo == 1) {
        message.text = @"Select OK to resume the demo.";
        districtname.text = viewDelegate.model.publicstate.district_name;
        username.text = [NSString stringWithFormat:@"%@ %@", viewDelegate.model.publicstate.first_name, viewDelegate.model.publicstate.last_name];
        passwordtext.text = @"";
        
    // Otherwise regular account
    } else {
        message.text = @"Please enter your password.";
        districtname.text = viewDelegate.model.publicstate.district_name;
        username.text = [NSString stringWithFormat:@"%@ %@", viewDelegate.model.publicstate.first_name, viewDelegate.model.publicstate.last_name];
        passwordtext.text = @"";
        [wholeview addSubview:passwordtext];
    }
}

//------------------------------------------------------------------------------------------------
- (void) zeroStrikes {
    strikes = 0;
}

// --------------------------------------------------------------------------------------
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration {
    if (debugRotate) NSLog(@"TPTimeoutVC willRotateToInterfaceOrientation");
}

- (void)viewWillLayoutSubviews {
    if (debugRotate) NSLog(@"TPTimeoutVC viewWillLayoutSubviews");
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration {
    if (debugRotate) NSLog(@"TPTimeoutVC willAnimateRotationToInterfaceOrientation");
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    if (debugRotate) NSLog(@"TPTimeoutVC didRotateFromInterfaceOrientation");
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    if (debugRotate) NSLog(@"TPTimeoutVC shouldAutorotateToInterfaceOrientation");
    return YES;
}

//------------------------------------------------------------------------------------------------
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (debugLogin) NSLog(@"TPTimeoutVC textFieldShouldReturn");
    [self access];
	return YES;
}

@end
