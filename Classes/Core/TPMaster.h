@class TPView;

// --------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------
typedef enum {
    TP_USER_SORT_NAME = 0,
    TP_USER_SORT_SCHOOL = 1,
    TP_USER_SORT_GRADE = 2,
} TPUserSort;

//jxi; click-status of tab items
typedef enum {
    TP_TAB_STATE_RUBRICS = TP_VIEW_STATE_RUBRICS,
    TP_TAB_STATE_INFO = TP_VIEW_STATE_INFO,
    TP_TAB_STATE_REPORTS = TP_VIEW_STATE_REPORTS,
    TP_TAB_STATE_CAMERA = TP_VIEW_STATE_CAMERA,
    TP_TAB_STATE_OPTIONS = 4
} TPTabState;

// --------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------
@interface TPMasterVC : UIViewController <UITableViewDelegate, UITableViewDataSource, UIAlertViewDelegate, UITabBarDelegate> {
    
    TPView *viewDelegate;
    
	UITableView *table;
    UIView *headerView;
    UISegmentedControl *sortControl;
    UIImage *padlockImage;
    NSIndexPath *current_cell;
    UITableView *customTable;
    int current_sort;
    
    UIButton *greenSyncButton;
    UIButton *yellowSyncButton;
    UIActivityIndicatorView *syncSpinner;
    
    UITabBar* tabControl; //jxi;
    UITabBarItem* prevTabItem; //jx;
    
}

- (id)initWithView:(TPView *)mainview;
- (void)resetPrompt;
- (void) sortUsersUIEvent;
- (void) sortUsers;
- (void) reloadTableData;
- (void) highlightTargetUser;
- (void) setNeedSyncButtonStateForStatus:(TPNeedSyncStatus)status;

@end

// --------------------------------------------------------------------------------------
