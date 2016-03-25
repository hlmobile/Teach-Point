@class TPModel;
@class TPView;
@class TPLoginVC;
@class TPTimeoutVC;
@class TPMasterVC;
@class TPRubricListVC;
@class TPRubricVC;
@class TPInfoVC;
@class TPReportListVC;
@class TPReportVC;
@class TPPickerVC;
@class TPCameraVC;
@class TPRubric;
@class TPUserData;
@class MTStatusBarOverlay;
@class TPOptionsPO;
@class TPSyncPO;
@class TPPreferencesPO;
@class TPHelpPO;
@class TPProgressVC;
@class TPVideoVC; //jxi;

// --------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------
typedef enum {
    TP_VIEW_STATE_RUBRICS = 0,
    TP_VIEW_STATE_INFO = 1,
    TP_VIEW_STATE_REPORTS = 2,
    TP_VIEW_STATE_CAMERA = 3 //jxi;
} TPViewState;


typedef enum {
	TP_CAMERA_FROM_TAB = 0,
	TP_CAMERA_FROM_RUBRIC = 1,
	TP_CAMERA_FROM_QUESTION = 2
} TPCameraButtonClickedState; //jxi;

typedef enum {
	TP_PREVIEW_FOR_RUBRICLIST = 0,
	TP_PREVIEW_FOR_RUBRICVC = 1,
} TPPreviewVCContainerState; //jxi;
// --------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------
@interface TPView : NSObject <UISplitViewControllerDelegate> {

	TPModel *model;
		
	UIWindow *window;
    
    MTStatusBarOverlay *statusBarOverlay;
    TPOptionsPO *optionsPO;
	TPSyncPO *syncPO;
	TPPreferencesPO *preferencesPO;
    TPHelpPO *helpPO;
	UINavigationController *optionsNC;
	UIPopoverController *optionsPOC;
	int optionsPOViewHeight, optionsPOViewWidth, optionsPOViewWidthExpanded;
    
    // Login screen
    UINavigationController *loginNC;
	TPLoginVC *loginVC;
    
    // Timeout screen
    TPTimeoutVC *timeoutVC;
    UINavigationController *timeoutNC;
    
    // Progress screen
    TPProgressVC *progressVC;
    UINavigationController *progressNC;
    
    // Sync type (local to view class)
    int sync_type;
    
    // Main screen
    UISplitViewController *splitVC;
    
    UINavigationController *masterNC;
    UINavigationController *detailNC;
    
    TPMasterVC *teacherlistVC;
    
    TPRubricListVC *rubriclistVC;
    TPRubricVC *rubricVC;
    TPInfoVC *infoVC;
    TPReportListVC *reportlistVC;
    TPReportVC *reportVC;
    
    TPCameraVC *cameraVC;
    UINavigationController *cameraNC;
    
    UIAlertView *confirmalert;
    UIAlertView *generalalert;
    
    UISegmentedControl *viewControl;
    int currentViewState;
    
    //jxi; Video Capture
    TPVideoVC *videoVC;
    UINavigationController *videoNC;
    
    int cameraButtonClickedState; //jxi;
    
    //jxi; state where the synced image or video to be previewd; i.e; to rubriclist or rubricVC
    int preview_container_state;
}

@property (nonatomic, retain) TPModel *model;
@property (nonatomic, retain) TPRubricVC *rubricVC;
@property (nonatomic, retain) TPRubricListVC *rubriclistVC;
@property (nonatomic, retain) TPCameraVC *cameraVC;
@property (nonatomic, retain) TPVideoVC *videoVC; //jxi;
@property (nonatomic) int preview_container_state; //jxi;
@property (nonatomic, retain) UISegmentedControl *viewControl;
@property (nonatomic, retain) UIPopoverController *optionsPOC;
@property (nonatomic, retain) UIPopoverController *gradePOC;
@property (nonatomic) int optionsPOViewHeight;
@property (nonatomic) int optionsPOViewWidth;
@property (nonatomic) int optionsPOViewWidthExpanded;
@property (nonatomic) int cameraButtonClickedState; //jxi;
@property (nonatomic) int currentViewState; //jxi;

- (id) initWithModel:(TPModel *)some_model;

- (void) syncfailed:(NSString *)title poptostart:(NSInteger)poptostart;
- (void) syncwarning:(NSString *)title;
- (void) setSyncStatus;
- (void) urlfailed:(NSError *)error;
- (void) badnumeric;
- (void) syncwarning;
- (void) generalAlert:(NSString *)title message:(NSString *)message poptostart:(NSInteger)poptostart;
- (void) confirm_abortlog;
- (void) confirmAlert:(NSString *)title message:(NSString *)message;

- (void) updatePromptString;
- (void) showMain;
- (void) sortUsers;
- (void) pushProgress;
- (void) popProgress;

- (void) pushSync;
- (void) registerSyncPopupForSyncStatusCallback;
- (void) clearSyncPopupStatus:(BOOL)forced;
- (void) pushPreferences;
- (void) popOptionsPO;
- (void) doSync;
- (void) finishSuspendedSync;
- (void) syncNow:(int)syncType;

- (void) returnToLoginScreen;
- (void) debug;

- (void) selectTargetAtIndex:(int)index;

- (void) rubricBeginEditing;
- (void) rubricDoneEditing;
- (void) rubricCaptureCurrentState;
- (void) reloadUserdataList;
- (void) reloadUserList;
- (void) reloadReportList;
- (void) reloadRubric;
- (void) reloadInfo;
- (void) reloadReport;

- (void) newUserData:(TPRubric *)rubric;
- (void) setUserData:(TPUserData *)userdata;

- (void) setReport:(int)reportgroup groupName:(NSString *)groupName reportId:(int)reportId reportName:(NSString *)reportName;
- (void) reportBeginViewing;
- (void) reportDoneViewing;

- (void) cameraBeginCapture;
- (void) cameraDoneCapture;

- (void) returnFromOpenedView;

- (void) pushCamera;
- (void) resetPreview;

- (void) switchView:(int)index;
- (void) logout: (BOOL)confirmRequired;
- (void) logout;
- (void) doLogout;
- (void) timeoutscreen;
- (void) gotologinscreen;
- (void) exittimeoutscreen;

- (void) hidenew;
- (void) hideoptions;
- (void) closeAllPopupsAndAlerts;

- (void) highlightTargetUser;

- (void) disableRubricListInteraction;
- (void) enableRubricListInteraction;

- (void) resetRubricVC; //jxi;
- (void) onNoRubricData; //jxi;


- (void) videoBeginCapture; //jxi;
- (void) videoDoneCapture; //jxi;

- (void) pushVideo; //jxi;
- (void) resetVideoPreview; //jxi;
@end

// --------------------------------------------------------------------------------------
