@class TPView;

// --------------------------------------------------------------------------------------
@interface TPInfoVC : UIViewController {
    
    TPView *viewDelegate;
    UISegmentedControl *viewControl;
    UIBarButtonItem *rightbutton;
    UIWebView *webView;
}

- (id)initWithView:(TPView *)mainview;
- (void) reset;
- (void) resetPrompt;
- (void) clearContent;
- (void) switchView;
- (void) setSelectedView:(int)index;
- (void) showoptions;
- (NSString *) getCurrentTargetInfoPage;

@end

// --------------------------------------------------------------------------------------
