@class TPView;
@class TPRubricQRatingTable;
@class TPNewPO;
@class TPUserData;

// --------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------
@interface TPReportListVC : UITableViewController <UITableViewDelegate, UITableViewDataSource> {
    
    TPView *viewDelegate;
    
    NSMutableArray *reportList;
	NSMutableArray *sectionList;
    
    NSMutableArray *reportGroupNames;
    NSMutableArray *reportRubricIdArrays;
	NSMutableArray *reportNameArrays;
    
    UISegmentedControl *viewControl;
    UIBarButtonItem *leftbutton;
    UIBarButtonItem *rightbutton;
	UIPopoverController *newPOC;
}

- (id) initWithView:(TPView *)mainview;
//- (void) initDynamicReports;
- (void) reset;
- (void) resetPrompt;
- (void) switchView;
- (void) setSelectedView:(int)index;

@end

// --------------------------------------------------------------------------------------