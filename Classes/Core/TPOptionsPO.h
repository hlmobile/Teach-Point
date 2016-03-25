@class TPView;

//------------------------------------------------------------------------------------------------
@interface TPOptionsPO : UITableViewController <UITableViewDelegate, UITableViewDataSource> {

	TPView *viewDelegate;
	
    UIBarButtonItem *backButton;
	NSMutableArray *buttonList;
}

- (id) initWithViewDelegate:(TPView *)delegate;
- (void) preferences;
- (void) camera;
- (void) sync;
- (void) logout;
- (void) debug:(UILongPressGestureRecognizer*)sender;

@end

//------------------------------------------------------------------------------------------------
@interface TPSyncPO : UIViewController <UIAlertViewDelegate> {
	
	TPView *viewDelegate;
	
	UILabel *lastSyncLabel, *unsyncedLabel, *syncStatusLabel;
	UIButton *syncButton;
	UIImageView *syncWarningIcon;
    //UIImageView *syncWirelessIcon;
	
	int currentSyncType, currentUnsyncCount, totalUnsyncCount;
	BOOL wasSyncedAfterPODisplayed;
}

- (id) initWithViewDelegate:(TPView *)delegate;
- (void) updateStatusUI;
- (void) clearStatusUI:(BOOL)forced;
- (void) registerForSyncStatusCallback;
- (void) setUnsyncCounts;
- (void) updateSyncStatusCallback:(int) syncType;

- (NSString *) lastSyncString;
- (NSString *) unsyncedString;
- (NSString *) syncStatusString;

@end

//------------------------------------------------------------------------------------------------
@interface TPPreferencesPO : UIViewController {
	
	TPView *viewDelegate;
	
	UILabel *useOwnDataLabel;
	UISwitch *useOwnDataSwitch;
	UILabel *autoScrollingLabel;
	UISwitch *autoScrollingSwitch;
	UILabel *autoCompressionLabel;
	UISwitch *autoCompressionSwitch;
    UILabel *showStatusLabel;
	UISwitch *showStatusSwitch;
}

- (id) initWithViewDelegate:(TPView *)delegate;

@end

//------------------------------------------------------------------------------------------------
@interface TPHelpPO : UIViewController {
	
	TPView *viewDelegate;
	
	UILabel *helpLabel;
}

- (id) initWithViewDelegate:(TPView *)delegate;

@end

//------------------------------------------------------------------------------------------------