@class TPView;

@class TPRoundRectView;

@interface TPLoginVC : UIViewController <UITextFieldDelegate> {
	
	TPView *viewDelegate;
	
    UIView *wholeview;
	UITextView *welcome;
    TPRoundRectView *roundrect1;
    TPRoundRectView *roundrect2;
    UILabel *districtloginlabel;
	UITextField *districtlogintext;
	UILabel *loginlabel;
	UITextField *logintext;	
	UILabel *passwordlabel;
	UITextField *passwordtext;
    UIButton *loginbutton;
    UILabel *demologinlabel;
    UIButton *demologinbutton;
	
}

- (id) initWithView:(TPView *)delegate;
- (void) clearLoginFields;

@end
