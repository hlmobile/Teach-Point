@class TPDatabase;
@class TPView;
@class TPDatabase;
@class TPPublicState;
@class TPAppState;
@class TPUser;
@class TPUserInfo;
@class TPCategory;
@class TPRubric;
@class TPQuestion;
@class TPRating;
@class TPUserData;
@class TPSyncManager;
@class TPImage;
@class TPVideo; //jxi;

// ---------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------

typedef enum {
    TIME_RANGE_ALL      = 0,
    TIME_RANGE_YEAR     = 1,
    TIME_RANGE_SEMESTER = 2,
    TIME_RANGE_MONTH    = 3,
    TIME_RANGE_WEEK     = 4,
    TIME_RANGE_DAY      = 5
} TPModelTimeRange;

typedef enum {
    NEEDSYNC_STATUS_SYNCED    = 0,
    NEEDSYNC_STATUS_NOTSYNCED = 1,
    NEEDSYNC_STATUS_SYNCING   = 2
} TPNeedSyncStatus;

typedef enum {
    SYNC_INITIATOR_UNKNOWN = 0,
    SYNC_INITIATOR_USER = 1,
    SYNC_INITIATOR_SYNCMGR = 2
} TPSyncInitiator;

// ---------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------
@interface TPModel : NSObject {

    TPView *view;
    
    // Database
    TPDatabase *database;

    // Logged in state
    BOOL isLoggedIn;
    
    // Synced data
    TPPublicState *publicstate;         // Publicly readable state info
	TPAppState *appstate;               // Private state info
	NSMutableArray *user_array;         // Users that system needs
    NSMutableArray *info_array;         // User info
	NSMutableArray *rubric_array;       // All rubrics required
    NSMutableArray *question_array;     // All questions for rubrics in rubric_array
    NSMutableArray *rating_array;       // All ratings for questions in question_array
    NSMutableArray *category_array;     // Categories
    
    // Temporary container for indexes of rubrics to be deleted
    NSMutableIndexSet *deleted_rubrics_indexes;
    NSMutableIndexSet *deleted_questions_indexes;
    NSMutableIndexSet *deleted_ratings_indexes;
    
    // Temporary arrays for synced data (after parsing but before further processing)
    NSMutableArray *tmp_user_array;
    NSMutableArray *tmp_info_array;
	NSMutableArray *tmp_rubric_array;
    NSMutableArray *tmp_question_array;
    NSMutableArray *tmp_rating_array;
    NSMutableArray *tmp_category_array;
    NSMutableArray *tmp_userdata_array;
    NSMutableArray *tmp_userdata_array_flags;
    NSMutableArray *tmp_synced_userids;
    
    // Temporary list of server-side userdata (recordings)
    NSMutableArray *synced_userdata;
    
    NSString *remoteImageIDToSync;
    NSString *remoteVideoIDToSync; //jxi;
    
    // Derived arrays and variables used to cache frequently used data
    NSMutableArray *user_list;      // Users that current login user has permission to view or record
	NSMutableArray *rubric_list;    // List of published forms
    NSMutableArray *image_list;     // list of images for the current (selected) user
    NSMutableArray *question_list;  // List of questions for current rubric sorted by order field
    NSMutableArray *userdata_list;  // List of recordings for selected subject
    NSMutableArray *video_list;  // List of videos for selected subject //jxi;
    
    TPUserData *userdata_current;   // Current open form being edited
    TPImage *image_current;         // Currently selected image
    TPVideo *video_current;         // Currently selected video //jxi;

    int userFormPermission;         // User permission for currently selected form
    BOOL userHasSignedForm;         // True if user has already signed the current form
    BOOL userCanEditCurrentUserdata; // True if user has permission to edit current userdata;
    
    NSMutableArray *school_list;    // List of schools based on those found in user_array
    NSMutableArray *school_list_lengths;
    int num_schools;
    
    NSMutableArray *grade_list;     // List of grades based on those found in user_array
    NSMutableArray *grade_list_lengths;
    int num_grades;
    
    // Syncing and parsing
    TPSyncManager *syncMgr;
    int sync_type;
	int sync_type_start;
    BOOL logoutAfterSync;
	NSURLConnection *page_connection;
	NSMutableData *page_results;
    int conn_status;
	NSString *sync_data_id;
    NSMutableArray *userdata_queue;
    NSMutableArray *localimages_queue;
    NSMutableArray *localvideos_queue; //jxi;
    int userdata_unprocessed_count;
    
	id syncStatusDelegate;
	SEL syncStatusSelector;
    
    // Need sync
    TPNeedSyncStatus needSyncStatus;
    TPSyncInitiator syncInitiator;
    int sync_complete;
    NSMutableDictionary *needSyncUsers; // Key: string from user_id need to be synced,  Value: count of unsynced data
    BOOL isApplicationFirstTimeSync; // nedded to mark all users grey for first time sync
    BOOL isFirstSyncAfterUpgrade;
    
    // current state of the DetailView (can be: rubriclist, rubric, reportlist, report, info)
    NSString *currentMainViewState;
    
    // date formatters
    NSDateFormatter *dateFormatter;
    NSDateFormatter *prettyDateFormatter, *prettyTimeFormatter;
    NSLock *dateformatterLock;
    
    // sync queue
    NSOperationQueue *sync_queue;
    NSLock *uiSyncLock;
    
    //jxi; advanced syncing for userdata
    int userdata_sync_step;
    int userdata_sync_step_response;
    int userdata_sync_current_target_id;
    int userdata_sync_prev_target_id;
    
    //jxi;
    NSString* remoteFormIDToSync; // Store the id of an form type of userdata to be synced
}

@property (nonatomic, retain) TPView *view;
@property (nonatomic, retain) TPDatabase *database;
@property (nonatomic, retain) TPSyncManager *syncMgr;
@property (nonatomic, assign) BOOL logoutAfterSync;
@property (nonatomic, assign) TPNeedSyncStatus needSyncStatus;
@property (nonatomic, assign) TPSyncInitiator syncInitiator;
@property (nonatomic) int sync_complete;
@property (nonatomic, assign) TPNeedSyncStatus previousNeedSyncStatus;
@property (nonatomic, retain) NSMutableDictionary *needSyncUsers;
@property (nonatomic, assign) BOOL isApplicationFirstTimeSync;
@property (nonatomic, assign) BOOL isFirstSyncAfterUpgrade;
@property (nonatomic) int sync_type;
@property (nonatomic, copy) NSString *sync_data_id;
@property (nonatomic, retain) NSURLConnection *page_connection;
@property (nonatomic, retain) NSMutableData *page_results;
@property (nonatomic, retain) TPPublicState *publicstate;
@property (nonatomic, retain) TPAppState *appstate;
@property (nonatomic, retain) NSMutableArray *user_array;
@property (nonatomic, retain) NSMutableArray *info_array;
@property (nonatomic, retain) NSMutableArray *rubric_array;
@property (nonatomic, retain) NSMutableArray *question_array;
@property (nonatomic, retain) NSMutableArray *rating_array;
@property (nonatomic, retain) NSMutableArray *category_array;
@property (nonatomic, retain) NSMutableIndexSet *deleted_rubrics_indexes;
@property (nonatomic, retain) NSMutableIndexSet *deleted_questions_indexes;
@property (nonatomic, retain) NSMutableIndexSet *deleted_ratings_indexes;
@property (nonatomic, retain) NSMutableArray *tmp_user_array;
@property (nonatomic, retain) NSMutableArray *tmp_info_array;
@property (nonatomic, retain) NSMutableArray *tmp_rubric_array;
@property (nonatomic, retain) NSMutableArray *tmp_question_array;
@property (nonatomic, retain) NSMutableArray *tmp_rating_array;
@property (nonatomic, retain) NSMutableArray *tmp_category_array;
@property (nonatomic, retain) NSMutableArray *tmp_userdata_array;
@property (nonatomic, retain) NSMutableArray *tmp_userdata_array_flags;
@property (nonatomic, retain) NSMutableArray *tmp_synced_userids;
@property (nonatomic, retain) NSMutableArray *synced_userdata;
@property (nonatomic, retain) NSMutableArray *user_list;
@property (nonatomic, retain) NSMutableArray *rubric_list;
@property (nonatomic, retain) NSMutableArray *image_list;
@property (nonatomic, retain) NSMutableArray *video_list; //jxi;
@property (nonatomic, retain) NSMutableArray *userdata_list;
@property (nonatomic, retain) TPUserData *userdata_current;
@property (nonatomic, retain) TPImage *image_current;
@property (nonatomic, retain) TPVideo *video_current; //jxi;
@property (nonatomic, retain) NSMutableArray *question_list;
@property (nonatomic) int num_schools;
@property (nonatomic, retain) NSMutableArray *school_list;
@property (nonatomic, retain) NSMutableArray *school_list_lengths;
@property (nonatomic) int num_grades;
@property (nonatomic, retain) NSMutableArray *grade_list;
@property (nonatomic, retain) NSMutableArray *grade_list_lengths;
@property (nonatomic, retain) NSString *currentMainViewState;
@property (nonatomic, copy) NSString *remoteImageIDToSync;
@property (nonatomic, copy) NSString *remoteVideoIDToSync; //jxi;
@property (nonatomic, retain) NSOperationQueue *sync_queue;
@property (nonatomic, retain) NSLock *uiSyncLock;

//jxi; advanced syncing for userdata
@property (nonatomic) int userdata_sync_step;
@property (nonatomic) int userdata_sync_step_response;
@property (nonatomic) int userdata_sync_current_target_id;
@property (nonatomic) int userdata_sync_prev_target_id;

//jxi; on-demand syncing for form data
@property (nonatomic, copy) NSString *remoteFormIDToSync;

- (void) initDatabase;
- (void) closeDatabase;
+ (void) destroyDatabase;

- (NSString *) updateSettingsValues ;
- (void) modelUpgrade:(NSString *)priorVersion;

- (void) clear;
- (void) clearData;
- (void) clearUser;
- (void) clearDatabase;

// ---------------- Archive/unarchive data ------------------
- (BOOL) archiveState;
- (BOOL) archiveData;
- (BOOL) archiveUsers;
- (BOOL) archiveInfo;
- (BOOL) archiveCategories;
- (BOOL) archiveRubrics;

- (void) unarchiveState_v1d4;
- (void) unarchiveData_v1d4;

- (void) unarchivePublicState;
- (void) unarchiveState:(NSString *)password;
- (void) unarchiveData;
- (void) unarchiveRubrics;

- (NSString *) getEncryptionKey;
- (NSString *) getEncryptionKeyFromPassword:(NSString *)password;
- (NSData *) encryptData:(NSData *)data key:(NSString *)key;
- (NSData *) decryptData:(NSData *)data key:(NSString *)key;

// ------------------ Derive data ---------------------------
- (void) deriveData;
- (void) deriveUserList;
- (void) deriveUserDataList;
- (void) deriveRubricList;
- (void) deriveUserDataInfo;
- (void) deriveImageList;
- (void) deriveVideoList; //jxi;

- (void) dump;
- (void) dumpstate;
- (void) dumpDatabase;

- (NSString *) getState;
- (void) setState:(NSString *)state;

- (NSString *) getLoginUserName;
- (NSString *) getTargetUserName;
- (void) setSubjectByIndex:(NSInteger)index;
- (NSString *) getUserName:(int)user_id;
- (NSInteger) getSubjectIndex;
- (NSString *) getDetailViewPromptString;

- (TPUser *) getCurrentUser;
- (TPUser *) getCurrentTarget;
- (TPUserInfo *) getCurrentTargetInfo;

- (TPVideo *) getVideoFromListById:(NSString *)userdata_id; //jxi;

- (TPUserData *) getUserDataFromListById:(NSString *)userdata_id;
- (TPImage *) getImageFromListById:(NSString *)userdata_id type:(int)type;
- (void) setCurrentRubricById:(int)rubric_id;
- (void) userHasSignedQuestion:(TPQuestion *)question;
- (void) getQuestionListByRubricId:(NSMutableArray *)questionList rubricId:(int)rubricId;
- (void) clearCurrentRubric;
- (TPRubric *) getCurrentRubric;
- (TPRubric *) getRubricById:(int)rubricId;
- (TPUserData *) getCurrentUserData;
- (void) deleteUserData:(NSString *)userdata_id includingImages:(BOOL)includingImages;
- (void) purgeUserRecordedDemoData;

- (BOOL) ratingIsSelected:(TPRating *)rating question:(TPQuestion *)question;
- (float) ratingValue:(TPRating *)rating question:(TPQuestion *)question;
- (NSString *) questionText:(TPQuestion *)question userdata_id:(NSString *)userdata_id;
- (NSString *) questionText:(TPQuestion *)question;
- (NSString *) questionAnnot:(TPQuestion *)question userdata_id:(NSString *)userdata_id;
- (NSString *) questionAnnot:(TPQuestion *)question;
- (NSDate *) questionDatevalue:(TPQuestion *)question;

- (void) newUserData:(TPRubric *)rubric;
- (void) setUserData:(TPUserData *)userdata;

- (void) updateUserData:(TPUserData *)userdata setModified:(BOOL)setModified;
- (void) updateImage:(TPImage *)image;
- (void) updateImageOrigin:(NSString *)userdata_id type:(int)image_type origin:(int)neworigin;
- (void) updateVideoOrigin:(NSString *)userdata_id type:(int)image_type origin:(int)neworigin; //jxi;
- (int) getUserDataState:(NSString *)userdata_id;
- (void) updateUserDataState:(NSString *)userdata_id state:(int)newstate;
- (void) updateUserDataStateNoTimestamp:(NSString *)userdata_id state:(int)newstate;
- (void) updateUserDataRating:(TPRating *)rating selected:(BOOL)selected;
- (void) updateUserDataRatingCumulative:(TPRating *)rating cumulativeValue:(float)value;
- (void) updateUserDataText:(TPQuestion *)question text:(NSString *)sometext isAnnot:(int)isAnnot;
- (void) updateUserDataDatevalue:(TPQuestion *)question dateValue:(NSDate *)datevalue;
- (void) purgeUserDataIfEmpty:(NSString *)userdata_id;
- (void) setStateToSync:(TPUserData *)userdata;
- (void) updateUserDataShare:(int)newshare;
- (void) updateUserDataElapsed:(int)newelapsed;
- (void) updateUserDataGrade:(int)newgrade;

- (TPRating *) getRatingByQuestionId:(int)question_id order:(int)order;

- (void) getRecRubricList:(NSMutableArray *)userDataIdArray;

- (BOOL) userOwnsUserdata;
- (BOOL) userCanEditUserdata;
- (BOOL) userCanEditFormHeading;
- (BOOL) userCanEditQuestion:(TPQuestion *)question;
- (BOOL) userCanEditQuestion:(BOOL)isReflection :(BOOL)isThirdParty;
- (BOOL) isRubricEditable:(int)rubric_id;
- (BOOL) isQuestionEditable:(int)question_id;
- (BOOL) isThirdPartyUser;
- (void) setNeedSyncStatus:(TPNeedSyncStatus)syncStatus forced:(BOOL)forced;
- (void) setNeedSyncStatusFromUnsyncedCount:(BOOL)forced;

// --------------- Date manipulation -------------------
- (NSDate *) dateFromCharStr:(char *)date_charstr;
- (NSDate *) dateFromStr:(NSString *)date_str;
- (NSString *) stringFromDate:(NSDate *)date;
- (NSString *) prettyStringFromDate:(NSDate *)date;
- (NSString *) prettyStringFromDate:(NSDate *)date newline:(BOOL)newLine;

- (int) getUserArrayIndex:(TPUser *)target;
- (int) getInfoArrayIndex:(TPUserInfo *)target;
- (void) deleteInfoForUserId:(int) user_id;
- (int) getCategoryArrayIndex:(TPCategory *)target;
- (TPCategory *) getCategoryById:(int)category_id;
- (int) getRubricArrayIndex:(TPRubric *)target;
- (int) getQuestionArrayIndex:(TPQuestion *)target;
- (TPQuestion *) getQuestionById:(int)question_id;
- (int) getRatingArrayIndex:(TPRating *)target;

// --------------- Utility methods --------------------
- (int) getSyncType;

- (void) setUILock;
- (void) clearUILock;
- (BOOL) isSetUILock;
- (void) waitForUILock;

- (void) waitForLock:(NSLock *)someLock;
- (BOOL) tryLock:(NSLock *)someLock;
- (void) freeLock:(NSLock *)someLock;

- (void) resetAllLocks;

//jxi; ------------- UserData Advanced Sync Methods -------
- (TPUser *) getUserByUserId:(int) user_id;

@end

// ---------------------------------------------------------------------------------------
