@class TPUser;
@class TPSyncHandlerOp;

#import "TPModel.h"
#import "TPSyncHandlerDelegate.h"

// ---------------------------------------------------------------------------------------
typedef enum {
    SYNC_TYPE_UNKNOWN = 0,
    SYNC_TYPE_USER = 1,
    SYNC_TYPE_INFO = 2,
    SYNC_TYPE_CATEGORY = 3,
    SYNC_TYPE_RUBRIC = 4,
    SYNC_TYPE_CLIENTDATA = 5,
    SYNC_TYPE_CLIENTIMAGE = 6,
    SYNC_TYPE_DATA = 7,
    SYNC_TYPE_IMAGEDATA = 8,
    SYNC_TYPE_VIDEODATA = 9, //jxi;
    SYNC_TYPE_CLIENTVIDEO = 10, //jxi;
    SYNC_TYPE_FORMDATA=11, //jxi;
} TPModelSyncType;

typedef enum {
	SYNC_ERROR_OK = 0,
	SYNC_ERROR_GENERAL = -1,
	SYNC_ERROR_WIFI = -2,
	SYNC_ERROR_TIMEOUT = -3,
	SYNC_ERROR_LOGIN = -4
} TPModelSyncError;

//jxi; advanced syncing for userdata
typedef enum {
	USERDATA_SYNC_STEP_UNKNOWN = 0,
    USERDATA_SYNC_STEP_USER_CURRENT = 1,
	USERDATA_SYNC_STEP_USERS_IN_SAME_SCHOOL  = 2,
	USERDATA_SYNC_STEP_USERS_ALL  = 3,
} TPModelUserDataSyncStep;

typedef enum {
    USERDATA_SYNC_STEP_RESPONSE_UNKNOWN = 0,
    USERDATA_SYNC_STEP_RESPONSE_PARTIAL = 1,
    USERDATA_SYNC_STEP_RESPONSE_COMPLETE = 2,
} TPModelUserDataSyncStepResponse;

// ---------------------------------------------------------------------------------------
@interface TPModel (Sync) <TPSyncHandlerDelegate>

- (void) syncinit;
- (void) updateLastSync;
- (void) immediateSync;
- (void) suspendSyncing;
- (void) restartSyncing;
- (BOOL) syncIsSupended;
- (NSDate *) getLastSync;
- (int) getUserDataUnsyncedCount;

- (void) registerSyncStatusCallback:(id) delegate :(SEL)selector;
- (void) unregisterSyncStatusCallback;
- (void) updateSyncStatus:(int) status;

- (NSString *) syncEncode:(NSString *)rawstring;
- (NSString *) syncDecode:(NSString *)rawstring;
- (NSString *) postRequestEncode:(NSString *)input;

- (void) doSync:(int)syncType;
- (void) cancelSync;
- (void) clientDataSyncPrep;
- (int) getUnsyncedCount;
- (int) getUnprocessedCount;

- (void) setDatabaseSavepointWithName:(NSString*) savepointName;
- (void) releaseDatabaseSavepointWithName:(NSString*) savepointName;
- (void) rollbackToDatabaseSavepointWithName:(NSString*) savepointName;

- (NSString *) getUserListXMLEncoding;
- (NSString *) getInfoListXMLEncoding;
- (NSString *) getCategoryListXMLEncoding;
- (NSString *) getRubricListXMLEncoding;

- (void) handleUserSyncData;
- (void) handleUserInfoSyncData;
- (void) handleCategorySyncData;
- (void) handleRubricSyncData;
- (void) handleImageSyncData;
- (void) handleVideoSyncData; //jxi;
- (void) handleUserDataSyncData:(TPSyncHandlerOp *)callingOperation;
- (BOOL) handleUserDataSyncDataSubset:(TPSyncHandlerOp *)callingOperation target_id:(int)target_id;
- (void) handleDeletedData;

- (void) markAllUsersAsUnsynced;

@end

// ---------------------------------------------------------------------------------------
