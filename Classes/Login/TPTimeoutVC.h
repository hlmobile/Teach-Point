@class TPView;
@class TPRoundRectView;

@interface TPTimeoutVC : UIViewController <UITextFieldDelegate> {
	
	TPView *viewDelegate;
	
    UIView *wholeview;
	UITextView *message;
    TPRoundRectView *roundrect;
    UILabel *districtname;
	UILabel *username;
	UITextField *passwordtext;
    UIButton *loginbutton;
    	
    int strikes;
}

- (id) initWithView:(TPView *)delegate;
- (void) reset;
- (void) zeroStrikes;

@end
