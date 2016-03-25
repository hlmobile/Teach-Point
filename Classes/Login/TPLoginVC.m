#import "TPData.h"
#import "TPModel.h"
#import "TPView.h"
#import "TPLoginVC.h"
#import "TPRoundRect.h"
#import "TPUtil.h"
#import "TPCompat.h"
#import "TPDatabase.h"

#include <CommonCrypto/CommonDigest.h>

//------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------
@implementation TPLoginVC

- (id) initWithView:(TPView *)delegate {
	
	self = [ super init ];
	if (self != nil) {
		        
		viewDelegate = delegate;
		
        UIImage *logoImage = [UIImage imageNamed:@"logo.png"];
        UIImageView *logoView = [[[UIImageView alloc] initWithImage:logoImage] autorelease];
        self.navigationItem.titleView = logoView;
				
		wholeview = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 768, 600)];
		wholeview.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;

		welcome = [[[UITextView alloc] initWithFrame:CGRectMake(34, 50, 700, 60)] autorelease];
		welcome.text = @"Login with your TeachPoint account.";
		welcome.textAlignment = TPTextAlignmentCenter;
		welcome.editable = 0;
		welcome.backgroundColor = [UIColor clearColor];
		welcome.textColor = [UIColor whiteColor];
		welcome.font = [UIFont fontWithName:@"Helvetica" size:26.0];
        [wholeview addSubview:welcome];
		
        roundrect1 = [[[TPRoundRectView alloc] initWithFrame:CGRectMake(234, 120, 300, 220)] autorelease];
		roundrect1.rectColor = [UIColor colorWithWhite:0.1 alpha:0.6];
		roundrect1.strokeColor = [UIColor clearColor];
		roundrect1.cornerRadius = 20.0;
        [wholeview addSubview:roundrect1];

		districtloginlabel = [[[UILabel alloc] initWithFrame:CGRectMake(240, 150, 80, 30)] autorelease];
		districtloginlabel.text = @"District:";
		districtloginlabel.textColor = [UIColor whiteColor];
		districtloginlabel.backgroundColor = [UIColor clearColor];
		districtloginlabel.font = [UIFont fontWithName:@"Helvetica" size:16.0];
		districtloginlabel.textAlignment = TPTextAlignmentRight;
        [wholeview addSubview:districtloginlabel];
		
		districtlogintext = [[[UITextField alloc] initWithFrame:CGRectMake(324, 150, 200, 30)] autorelease];
        if ([viewDelegate.model.appstate.login compare:@"jledemo"] != NSOrderedSame) {
            districtlogintext.text = [NSString stringWithString:viewDelegate.model.appstate.districtlogin];
        }
		districtlogintext.borderStyle = 3;
		districtlogintext.adjustsFontSizeToFitWidth = YES;
		districtlogintext.clearsOnBeginEditing = NO;
		districtlogintext.keyboardType = UIKeyboardTypeEmailAddress;
		districtlogintext.autocapitalizationType = UITextAutocapitalizationTypeNone;
		districtlogintext.autocorrectionType = UITextAutocorrectionTypeNo;
		districtlogintext.delegate = self;
        [wholeview addSubview:districtlogintext];
        
        loginlabel = [[[UILabel alloc] initWithFrame:CGRectMake(240, 190, 80, 30)] autorelease];
		loginlabel.text = @"Login:";
		loginlabel.textColor = [UIColor whiteColor];
		loginlabel.backgroundColor = [UIColor clearColor];
		loginlabel.font = [UIFont fontWithName:@"Helvetica" size:16.0];
		loginlabel.textAlignment = TPTextAlignmentRight;
        [wholeview addSubview:loginlabel];
		
		logintext = [[[UITextField alloc] initWithFrame:CGRectMake(324, 190, 200, 30)] autorelease];
        if ([viewDelegate.model.appstate.login compare:@"jledemo"] != NSOrderedSame) {
            logintext.text = [NSString stringWithString:viewDelegate.model.appstate.login];
        }
		logintext.borderStyle = 3;
		logintext.adjustsFontSizeToFitWidth = YES;
		logintext.clearsOnBeginEditing = NO;
		logintext.keyboardType = UIKeyboardTypeEmailAddress;
		logintext.autocapitalizationType = UITextAutocapitalizationTypeNone;
		logintext.autocorrectionType = UITextAutocorrectionTypeNo;
		logintext.delegate = self;
        [wholeview addSubview:logintext];
		
		passwordlabel = [[[UILabel alloc] initWithFrame:CGRectMake(240, 230, 80, 30)] autorelease];
		passwordlabel.text = @"Password:";
		passwordlabel.textColor = [UIColor whiteColor];
		passwordlabel.backgroundColor = [UIColor clearColor];
		passwordlabel.font = [UIFont fontWithName:@"Helvetica" size:16.0];
		passwordlabel.textAlignment = TPTextAlignmentRight;
        [wholeview addSubview:passwordlabel];
		
		passwordtext = [[[UITextField alloc] initWithFrame:CGRectMake(324, 230, 200, 30)] autorelease];
        if ([viewDelegate.model.appstate.login compare:@"jledemo"] != NSOrderedSame) {
            passwordtext.text = [NSString stringWithString:viewDelegate.model.appstate.password];
        }
		passwordtext.borderStyle = 3;
		passwordtext.adjustsFontSizeToFitWidth = YES;
		passwordtext.clearsOnBeginEditing = NO;
		passwordtext.secureTextEntry = YES;
		passwordtext.delegate = self;
		[wholeview addSubview:passwordtext];
		
		loginbutton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
		loginbutton.frame = CGRectMake(324, 280, 120, 30);
		[loginbutton setTitle:@"Login" forState:UIControlStateNormal];
		[loginbutton addTarget:self action:@selector(login) forControlEvents:UIControlEventTouchUpInside];
        [wholeview addSubview:loginbutton];
        
        roundrect2 = [[[TPRoundRectView alloc] initWithFrame:CGRectMake(234, 370, 300, 160)] autorelease];
		roundrect2.rectColor = [UIColor colorWithWhite:0.1 alpha:0.6];
		roundrect2.strokeColor = [UIColor clearColor];
		roundrect2.cornerRadius = 20.0;
        [wholeview addSubview:roundrect2];

        demologinlabel = [[[UILabel alloc] initWithFrame:CGRectMake(239, 410, 290, 30)] autorelease];
		demologinlabel.text = @"Try the demo account.";
		demologinlabel.textColor = [UIColor whiteColor];
		demologinlabel.backgroundColor = [UIColor clearColor];
		demologinlabel.font = [UIFont fontWithName:@"Helvetica" size:18.0];
		demologinlabel.textAlignment = TPTextAlignmentCenter;
        [wholeview addSubview:demologinlabel];

		demologinbutton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
		demologinbutton.frame = CGRectMake(309, 460, 150, 30);
		[demologinbutton setTitle:@"Demo Login" forState:UIControlStateNormal];
		[demologinbutton addTarget:self action:@selector(demologin) forControlEvents:UIControlEventTouchUpInside];
        [wholeview addSubview:demologinbutton];
	}
	return self;
}

- (void) dealloc {
	[wholeview release];
    [super dealloc];
}

- (void) loadView {
	[super loadView];		
	[self.view addSubview:wholeview];
	self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"linen.png"]]; 
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

//------------------------------------------------------------------------------------------------
- (void) login {
    // Get login info from text fields in view
    viewDelegate.model.appstate.districtlogin = [NSString stringWithString:districtlogintext.text];
    viewDelegate.model.appstate.login = [NSString stringWithString:logintext.text];
    viewDelegate.model.appstate.password = [NSString stringWithString:passwordtext.text];
    viewDelegate.model.publicstate.hashed_password = [TPUtil getPasswordHash:viewDelegate.model.appstate.password];
    viewDelegate.model.publicstate.is_demo = 0;
	[passwordtext resignFirstResponder];
    [viewDelegate.model archiveState];
    viewDelegate.model.logoutAfterSync = NO;
    [viewDelegate.model initDatabase]; // Initialize database now that we have a password
    [viewDelegate doSync];
}

- (void) demologin {
    districtlogintext.text = @"";
    logintext.text = @"";
    passwordtext.text = @"";
    viewDelegate.model.appstate.districtlogin = @"demo";
    viewDelegate.model.appstate.login = @"jledemo";
    viewDelegate.model.appstate.password = @"jledemo4tPpaSS";
    viewDelegate.model.publicstate.hashed_password = [TPUtil getPasswordHash:viewDelegate.model.appstate.password];
    viewDelegate.model.publicstate.is_demo = 1;
    [viewDelegate.model archiveState];
    viewDelegate.model.logoutAfterSync = NO;
    [viewDelegate.model initDatabase]; // Initialize database now that we have a password
    [viewDelegate doSync];
}

- (void) clearLoginFields {
    //districtlogintext.text = @"";
    logintext.text = @"";
    passwordtext.text = @"";
}

// --------------------------------------------------------------------------------------
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration {
    if (debugRotate) NSLog(@"TPLogin willRotateToInterfaceOrientation");
}

- (void)viewWillLayoutSubviews {
    if (debugRotate) NSLog(@"TPLogin viewWillLayoutSubviews");
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration {
    if (debugRotate) NSLog(@"TPLogin willAnimateRotationToInterfaceOrientation");
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    if (debugRotate) NSLog(@"TPLogin didRotateFromInterfaceOrientation");
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    if (debugRotate) NSLog(@"TPLogin shouldAutorotateToInterfaceOrientation");
    return YES;
}

//------------------------------------------------------------------------------------------------
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	    
	if (textField == districtlogintext) {
		viewDelegate.model.appstate.districtlogin = [NSString stringWithString:districtlogintext.text];
		[logintext becomeFirstResponder];
        [viewDelegate.model archiveState];
	}
    
    if (textField == logintext) {
		viewDelegate.model.appstate.login = [NSString stringWithString:logintext.text];
		[passwordtext becomeFirstResponder];
        [viewDelegate.model archiveState];
	}
	
	if (textField == passwordtext) {
        [self login];
	}
	    
	return YES;
}

//------------------------------------------------------------------------------------------------

@end
