#import <sqlite3.h>
#import <CFNetwork/CFNetwork.h>
#import <CFNetwork/CFHTTPStream.h>
#import "TPData.h"
#import "TPDatabase.h"
#import "TPModel.h"
#import "TPModelSync.h"
#import "TPModelReport.h"
#import "TPView.h"
#import "TPParser.h"
#import "TPSyncManager.h"
#import "TPUtil.h"
#import <CommonCrypto/CommonCryptor.h>

// ---------------------------------------------------------------------------------------
// Strings to match recognized functions in expression syntax
struct expfunctions {
	char* keyword;
	int keysize;
} keyarray[] = { "string", 6, "value", 5, "count", 5, "sum", 3, "avg", 3, "countqat", 8, "countqaf", 8, "date", 4};
int keycount = 8;

// ---------------------------------------------------------------------------------------
@implementation TPModel

@synthesize view;
@synthesize database;
@synthesize syncMgr;
@synthesize logoutAfterSync;
@synthesize needSyncStatus;
@synthesize syncInitiator;
@synthesize sync_complete;
@synthesize previousNeedSyncStatus;
@synthesize needSyncUsers;
@synthesize isApplicationFirstTimeSync;
@synthesize isFirstSyncAfterUpgrade;
@synthesize sync_type;
@synthesize sync_data_id;
@synthesize page_connection;
@synthesize page_results;
@synthesize publicstate;
@synthesize appstate;
@synthesize user_array;
@synthesize info_array;
@synthesize rubric_array;
@synthesize category_array;
@synthesize question_array;
@synthesize rating_array;
@synthesize deleted_rubrics_indexes;
@synthesize deleted_questions_indexes;
@synthesize deleted_ratings_indexes;
@synthesize tmp_user_array;
@synthesize tmp_info_array;
@synthesize tmp_rubric_array;
@synthesize tmp_question_array;
@synthesize tmp_rating_array;
@synthesize tmp_category_array;
@synthesize tmp_userdata_array;
@synthesize tmp_userdata_array_flags;
@synthesize tmp_synced_userids;
@synthesize synced_userdata;
@synthesize user_list;
@synthesize rubric_list;
@synthesize image_list;
@synthesize video_list; //jxi;
@synthesize userdata_list;
@synthesize userdata_current;
@synthesize image_current;
@synthesize video_current; //jxi;
@synthesize question_list;
@synthesize num_schools;
@synthesize school_list;
@synthesize school_list_lengths;
@synthesize num_grades;
@synthesize grade_list;
@synthesize grade_list_lengths;
@synthesize currentMainViewState;
@synthesize remoteImageIDToSync;
@synthesize remoteVideoIDToSync; //jxi;
@synthesize sync_queue;
@synthesize uiSyncLock;

//jxi; advanced syncing for userdata
@synthesize userdata_sync_step;
@synthesize userdata_sync_step_response;
@synthesize userdata_sync_current_target_id;
@synthesize userdata_sync_prev_target_id;

//jxi; on-demand syncing for formdata
@synthesize remoteFormIDToSync;

// ---------------------------------------------------------------------------------------
- (id) init {
	
	if (debugModel) NSLog(@"TPModel init");
	
	self = [ super init ];
	if (self != nil) {
		
        // Initialize app settings values
        NSString *priorVersion = [self updateSettingsValues];
        
		// Seed random number generator
		srandom(time(0));
		
        isLoggedIn = NO;
        
		page_results = [[NSMutableData alloc] initWithLength:0];
		page_connection = nil;
        conn_status = 0;
                
        needSyncUsers = [[NSMutableDictionary alloc] init];
        
        synced_userdata = [[NSMutableArray alloc] init];
        userdata_queue = [[NSMutableArray alloc] init];
        localimages_queue = [[NSMutableArray alloc] init];
        localvideos_queue = [[NSMutableArray alloc] init]; //jxi;
        
        // Init derived arrays
        user_list = [[NSMutableArray alloc] init];
        rubric_list = [[NSMutableArray alloc] init];
        image_list = [[NSMutableArray alloc] init];
        video_list = [[NSMutableArray alloc] init]; //jxi;
        userdata_list = [[NSMutableArray alloc] init];
        userdata_current = nil;
        image_current = nil;
        video_current = nil; //jxi;
        question_list = [[NSMutableArray alloc] init];
        userFormPermission = TP_USER_FORM_PERMISSION_UNKNOWN;
        userHasSignedForm = NO;
        userCanEditCurrentUserdata = NO;
        num_schools = 0;
        school_list = [[NSMutableArray alloc] init];
        school_list_lengths = [[NSMutableArray alloc] init];
        num_grades = 0;
        grade_list = [[NSMutableArray alloc] init];
        grade_list_lengths = [[NSMutableArray alloc] init];
        deleted_rubrics_indexes = [[NSMutableIndexSet alloc] init];
        deleted_questions_indexes = [[NSMutableIndexSet alloc] init];
        deleted_ratings_indexes = [[NSMutableIndexSet alloc] init];
        
        // Temp sync arrays
        tmp_user_array = [[NSMutableArray alloc] init];
        tmp_info_array = [[NSMutableArray alloc] init];
        tmp_rubric_array = [[NSMutableArray alloc] init];
        tmp_question_array = [[NSMutableArray alloc] init];
        tmp_rating_array = [[NSMutableArray alloc] init];
        tmp_category_array = [[NSMutableArray alloc] init];
        tmp_userdata_array = [[NSMutableArray alloc] init];
        
        sync_data_id = nil;
        remoteImageIDToSync = nil;
        remoteVideoIDToSync = nil; //jxi;
        
        // Upgrade model as required
        [self modelUpgrade:priorVersion];
		
        // Try to get state from archived local data
		[self unarchivePublicState];

		// Get no state info (app never run) then init all objects
		if (publicstate == nil) {
			
			if (debugModel) NSLog(@"TPModel no state");
			publicstate = [[TPPublicState alloc] init];
			appstate = [[TPAppState alloc] init];
			user_array = [[NSMutableArray alloc] init];
            info_array = [[NSMutableArray alloc] init];
            rubric_array = [[NSMutableArray alloc] init];
            question_array = [[NSMutableArray alloc] init];
            rating_array = [[NSMutableArray alloc] init];
            category_array = [[NSMutableArray alloc] init];

            self.isApplicationFirstTimeSync = YES;
            
            [TPDatabase destroyDatabase]; // Clean up database file if still around

        // If not currently synced by user (no user data)
		} else if ([publicstate.state isEqualToString:@"install"])  {
				
            if (debugModel) NSLog(@"TPModel install state");
            appstate = [[TPAppState alloc] init];
            user_array = [[NSMutableArray alloc] init];
            info_array = [[NSMutableArray alloc] init];
            rubric_array = [[NSMutableArray alloc] init];
            question_array = [[NSMutableArray alloc] init];
            rating_array = [[NSMutableArray alloc] init];
            category_array = [[NSMutableArray alloc] init];
            self.isApplicationFirstTimeSync = YES;
            
            [TPDatabase destroyDatabase]; // Clean up database file if still around
                
        // If synced by user
        } else {
				
            if (debugModel) NSLog(@"TPModel synced state");
            self.isApplicationFirstTimeSync = NO;
            
            // Recover released arrays (THIS SHOULDN'T BE NECESSARY, BUT IS - sync cancel bug)
            if (appstate == nil) appstate = [[TPAppState alloc] init];
            if (user_array == nil) user_array = [[NSMutableArray alloc] init];
            if (info_array == nil) info_array = [[NSMutableArray alloc] init];
            if (rubric_array == nil) rubric_array = [[NSMutableArray alloc] init];
            if (question_array == nil) question_array = [[NSMutableArray alloc] init];
            if (rating_array == nil) rating_array = [[NSMutableArray alloc] init];
            if (category_array == nil) category_array = [[NSMutableArray alloc] init];
		}
		
		// Set default user preferences
		self.useOwnData = FALSE;
		self.autoScrolling = FALSE;
		self.autoCompression = FALSE;
        self.showStatus = FALSE;
        
        // date formatters
        dateFormatter = [[NSDateFormatter alloc] init];
        NSLocale *usLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
        [dateFormatter setLocale:usLocale];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];

        prettyDateFormatter = [[NSDateFormatter alloc] init];
        [prettyDateFormatter setLocale:usLocale];
        [prettyDateFormatter setDateFormat:@"MMM dd, yyyy"];

        prettyTimeFormatter = [[NSDateFormatter alloc] init];
        [prettyTimeFormatter setLocale:usLocale];
        [prettyTimeFormatter setDateFormat:@"h:mm a"];
        
        dateformatterLock = [[NSLock alloc] init];
        
        [usLocale release];
        
        // sync queue and locks
        sync_queue = [NSOperationQueue new];
        [self.sync_queue setMaxConcurrentOperationCount:1];
        uiSyncLock = [[NSLock alloc] init];
        sync_complete = 1;
        
        //jxi; advanced syncing for userdata
        userdata_sync_step = USERDATA_SYNC_STEP_UNKNOWN;
        userdata_sync_step_response = USERDATA_SYNC_STEP_RESPONSE_UNKNOWN;
	}
		
	return self;
}

// ---------------------------------------------------------------------------------------
- (void)dealloc {
    if (debugView) NSLog(@"TPModel dealloc");
    [publicstate release];
	[appstate release];
	[user_array release];
    [info_array release];
	[rubric_array release];
    [question_array release];
    [rating_array release];
    [category_array release];
    [tmp_user_array release];
    [tmp_info_array release];
	[tmp_rubric_array release];
    [tmp_question_array release];
    [tmp_rating_array release];
    [tmp_category_array release];
    [tmp_userdata_array release];
    [synced_userdata release];
    [user_list release];
	[rubric_list release];
    [image_list release];
    [video_list release]; //jxi;
    [userdata_list release];
    [question_list release];
    [school_list release];
    [school_list_lengths release];
    [grade_list release];
    [grade_list_lengths release];
	[database release];
    [userdata_queue release];
    [localimages_queue release];
    [localvideos_queue release]; //jxi;
    [needSyncUsers release];
    [deleted_rubrics_indexes release];
    [deleted_questions_indexes release];
    [deleted_ratings_indexes release];
    [sync_data_id release];
    [remoteImageIDToSync release];
    [remoteVideoIDToSync release]; //jxi;
    [dateFormatter release];
    [prettyDateFormatter release];
    [prettyTimeFormatter release];
    [dateformatterLock release];
    [sync_queue release];
    [uiSyncLock release];
	[super dealloc];
}

// ---------------------------------------------------------------------------------------
// setNeedSyncStatus - set sync status.  If already syncing don't set status unless forced.
// ---------------------------------------------------------------------------------------
- (void)setNeedSyncStatus:(TPNeedSyncStatus)syncStatus forced:(BOOL)forced {
    if (debugSyncControl) NSLog(@"TPModel setNeedSyncStatus %d %d", syncStatus, forced);
    
    if (forced) {
        needSyncStatus = syncStatus;
        [self.view setSyncStatus];
    } else if ((needSyncStatus != syncStatus) && (needSyncStatus != NEEDSYNC_STATUS_SYNCING)) {
        needSyncStatus = syncStatus;
        [self.view setSyncStatus];
    }
}

// ---------------------------------------------------------------------------------------
- (void) setNeedSyncStatusFromUnsyncedCount:(BOOL)forced {
    if ([self getUnsyncedCount] > 0) {
        [self setNeedSyncStatus:NEEDSYNC_STATUS_NOTSYNCED forced:forced];
    } else {
        [self setNeedSyncStatus:NEEDSYNC_STATUS_SYNCED forced:forced];
    }
}

// ---------------------------------------------------------------------------------------
// initDatabase - init database, call after login since needs encryption
// ---------------------------------------------------------------------------------------
- (void) initDatabase {
    if (debugModel) NSLog(@"initDatabase");
    database = [[TPDatabase alloc] initWithModel:self];
}

// ------------------------------------------------------------------------------------
- (void) closeDatabase {
    if (debugModel) NSLog(@"closeDatabase %d", (int)database);
    [database closeDatabase];
}

// ------------------------------------------------------------------------------------
+ (void) destroyDatabase {
    [TPDatabase destroyDatabase];
}

// ---------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------
- (NSString *) updateSettingsValues {
    
    // Initialize settings value - code dependent on order of values in Root.plist file (0-version, 1-webserver)
    // Get Root.plist default values
    NSString *settingsPath = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"Settings.bundle"];
    NSString *plistPath = [settingsPath stringByAppendingPathComponent:@"Root.plist"];
    NSDictionary *settingsDictionary = [NSDictionary dictionaryWithContentsOfFile:plistPath];
    NSArray *preferencesArray = [settingsDictionary objectForKey:@"PreferenceSpecifiers"];
    NSString *versionDefault = [[preferencesArray objectAtIndex:0] objectForKey:@"DefaultValue"];
    NSString *webserverDefault = [[preferencesArray objectAtIndex:1] objectForKey:@"DefaultValue"];
    
    // Always override existing version number
    NSString *priorVersion = [[NSUserDefaults standardUserDefaults] stringForKey:@"version"];
    [[NSUserDefaults standardUserDefaults] setObject:versionDefault forKey:@"version"];
    [[NSUserDefaults standardUserDefaults] synchronize];
        
    // Set the webserver if not already set (keep any existing value)
    NSString *webserver = [[NSUserDefaults standardUserDefaults] stringForKey:@"webserver"];
    if (webserver == nil) {
        [[NSUserDefaults standardUserDefaults] setObject:webserverDefault forKey:@"webserver"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    return priorVersion;
}

// ---------------------------------------------------------------------------------------
// Make any required model upgrades if app has been upgraded
// ---------------------------------------------------------------------------------------
- (void) modelUpgrade:(NSString *)priorVersion {
        
    // Get current version (settings must already be updated)
    NSString *currentVersion = [[NSUserDefaults standardUserDefaults] stringForKey:@"version"];
    if (debugModel) NSLog(@"TPModel upgrading version %@ to %@", priorVersion, currentVersion);
    
    // Updates required for compatibility with older versions
    isFirstSyncAfterUpgrade = NO;
    if (![currentVersion isEqualToString:priorVersion]) isFirstSyncAfterUpgrade = YES;
    if (debugModel) NSLog(@"TPModel isFirstSyncAfterUpgrade=%d", (int)isFirstSyncAfterUpgrade);
        
    // Upgrade version 1.4 to 1.5 (hash the password)
    if ([[priorVersion substringToIndex:3] isEqualToString:@"1.4"] && [[currentVersion substringToIndex:3] isEqualToString:@"1.5"]) {
                
        // Try to unarchive old state
        if (debugModel) NSLog(@"TPModel upgrade v1.4 to v1.5");
        [self unarchiveState_v1d4];
        
        // Skip migration if no user state or no user data
        if (appstate == nil || [appstate.state isEqualToString:@"install"]) {
            [self clear];
            return;
        }
        
        // Create public state then archive public and private state
        publicstate = [[TPPublicState alloc] init];
        publicstate.state = appstate.state;
        publicstate.district_name = appstate.district_name;
        publicstate.first_name = appstate.first_name;
        publicstate.last_name = appstate.last_name;
        publicstate.hashed_password = [TPUtil getPasswordHash:appstate.password];
        publicstate.is_demo = [appstate.districtlogin isEqualToString:@"demo"] && [appstate.login isEqualToString:@"jledemo"];
        [self archiveState];
        
        // Unarchive and rearchive data
        [self unarchiveData_v1d4];
        [self archiveData];
        
        // Set version tag
        priorVersion = @"1.5";
    }
    
    if ([[priorVersion substringToIndex:3] isEqualToString:@"1.5"] && [[currentVersion substringToIndex:3] isEqualToString:@"1.6"]) {
        if (debugModel) NSLog(@"model upgrade from 1.5 to 1.6");
        [self unarchiveRubrics];
        [self archiveRubrics];
        priorVersion = @"1.6";
    }
    
    // Maybe not necessary
    if ([[priorVersion substringToIndex:3] isEqualToString:@"1.6"] && [[currentVersion substringToIndex:3] isEqualToString:@"1.7"]) {
        if (debugModel) NSLog(@"model upgrade from 1.6 to 1.7");
        [self unarchiveRubrics];
        [self archiveRubrics];
        //priorVersion = @"1.7";
    }
}

// ---------------------------------------------------------------------------------------
- (void) clear {
	
	if (debugModel) NSLog(@"TPModel clear");
	
	// Clear application state
    [publicstate release];
    publicstate = [[TPPublicState alloc] init];
	[appstate release];
	appstate = [[TPAppState alloc] init];
	
	// Delete application state archive files
	NSFileManager *filemanager = [NSFileManager defaultManager];
	NSString *state_path = [NSString stringWithFormat:@"%@/Documents/state.xml", NSHomeDirectory()];
	[filemanager removeItemAtPath:state_path error:NULL];
	
    // Clear data and save state to archive file
	[self clearData];
	[self archiveState];
}

// ---------------------------------------------------------------------------------------
- (void) clearData {
	
	if (debugModel) NSLog(@"TPModel clearData");
	
	// Clear data arrays
	[user_array release];
    [info_array release];
    [rubric_array release];
    [question_array release];
    [rating_array release];
    [category_array release];
    	
	// Re-init data arrays
	user_array = [[NSMutableArray alloc] init];
    info_array = [[NSMutableArray alloc] init];
	rubric_array = [[NSMutableArray alloc] init];
    question_array = [[NSMutableArray alloc] init];
    rating_array = [[NSMutableArray alloc] init];
    category_array = [[NSMutableArray alloc] init];
    	
	// Delete archive files
	NSFileManager *filemanager = [NSFileManager defaultManager];
	NSString *userspath = [NSString stringWithFormat:@"%@/Documents/users.xml", NSHomeDirectory()];
	[filemanager removeItemAtPath:userspath error:NULL];
     NSString *infopath = [NSString stringWithFormat:@"%@/Documents/info.xml", NSHomeDirectory()];
    [filemanager removeItemAtPath:infopath error:NULL];
	NSString *rubricspath = [NSString stringWithFormat:@"%@/Documents/rubrics.xml", NSHomeDirectory()];
	[filemanager removeItemAtPath:rubricspath error:NULL];
    NSString *questionspath = [NSString stringWithFormat:@"%@/Documents/questions.xml", NSHomeDirectory()];
    [filemanager removeItemAtPath:questionspath error:NULL];
    NSString *ratingspath = [NSString stringWithFormat:@"%@/Documents/ratings.xml", NSHomeDirectory()];
    [filemanager removeItemAtPath:ratingspath error:NULL];
    NSString *catpath = [NSString stringWithFormat:@"%@/Documents/categories.xml", NSHomeDirectory()];
    [filemanager removeItemAtPath:catpath error:NULL];
		
	// Clear derived rubric list
    [user_list removeAllObjects];
	[rubric_list removeAllObjects];
    [userdata_list removeAllObjects];
    if (userdata_current != nil) {
        [userdata_current release];
        userdata_current = nil;
    }
    if (image_current != nil) {
        [image_current release];
        image_current = nil;
    }
    //jxi;
    if (video_current != nil) {
        [video_current release];
        video_current = nil;
    }
    [question_list removeAllObjects];
    userFormPermission = TP_USER_FORM_PERMISSION_UNKNOWN;
    userHasSignedForm = NO;
    num_schools = 0;
    [school_list removeAllObjects];
    [school_list_lengths removeAllObjects];
    num_grades = 0;
    [grade_list removeAllObjects];
    [grade_list_lengths removeAllObjects];
}

// ---------------------------------------------------------------------------------------
- (void) clearUser {
    if (debugModel) NSLog(@"TPModel clearUser");
    [self clear];
    [view returnToLoginScreen];
}

// ---------------------------------------------------------------------------------------
- (void) clearDatabase {
    if (debugModel) NSLog(@"TPModel clearDatabase %d", (int)database);
    [database clear];
}

// ---------------------------------------------------------------------------------------
- (BOOL) archiveState {
    if (debugArchive) NSLog(@"TPModel archiveState");
    
    // Archive public state (plain text)
    NSString *filepath = [NSString stringWithFormat:@"%@/Documents/publicstate.xml", NSHomeDirectory()];
	BOOL result = [NSKeyedArchiver archiveRootObject:publicstate toFile:filepath];
    if (!result) { return result; }
    
    // Archive private state (encrypted)
	filepath = [NSString stringWithFormat:@"%@/Documents/state.xml", NSHomeDirectory()];    
    NSData *plainData = [NSKeyedArchiver archivedDataWithRootObject:appstate]; // Create archive of object
    NSData *encryptedData = [self encryptData:plainData key:[self getEncryptionKey]]; // Encrypt archive
    result = [encryptedData writeToFile:filepath atomically:YES]; // Write encrypted data to file
    if (!result) { return result; }
    if (debugArchive) NSLog(@"TPModel archiveState DONE");
	return result;
}

- (BOOL) archiveUsers {
    if (debugArchive) NSLog(@"TPModel archiveUsers");
    // Archive users (encrypted)
	NSString *userspath = [NSString stringWithFormat:@"%@/Documents/users.xml", NSHomeDirectory()];
    NSData *plainData = [NSKeyedArchiver archivedDataWithRootObject:user_array]; // Create archive of object
    NSData *encryptedData = [self encryptData:plainData key:[self getEncryptionKey]]; // Encrypt archive
    BOOL result = [encryptedData writeToFile:userspath atomically:YES]; // Write encrypted data to file
	if (!result) { return result; }
    if (debugArchive) NSLog(@"TPModel archiveUsers DONE");
	return result;
}

- (BOOL) archiveInfo {
    if (debugArchive) NSLog(@"TPModel archiveInfo");
    // Archive info (encrypted)
    NSString *infopath = [NSString stringWithFormat:@"%@/Documents/info.xml", NSHomeDirectory()];
    NSData *plainData = [NSKeyedArchiver archivedDataWithRootObject:info_array]; // Create archive of object
    NSData *encryptedData = [self encryptData:plainData key:[self getEncryptionKey]]; // Encrypt archive
    BOOL result = [encryptedData writeToFile:infopath atomically:YES]; // Write encrypted data to file
	if (!result) { return result; }
    if (debugArchive) NSLog(@"TPModel archiveInfo DONE");
	return result;
}

- (BOOL) archiveCategories {	
	if (debugArchive) NSLog(@"TPModel archiveCategories");
    NSString *catpath = [NSString stringWithFormat:@"%@/Documents/categories.xml", NSHomeDirectory()];
    BOOL result = [NSKeyedArchiver archiveRootObject:category_array toFile:catpath];
	if (!result) { return result; }
    if (debugArchive) NSLog(@"TPModel archiveCategories DONE");
	return result;
}

- (BOOL) archiveRubrics {	
    if (debugArchive) NSLog(@"TPModel archiveRubrics");
	NSString *rubricspath = [NSString stringWithFormat:@"%@/Documents/rubrics.xml", NSHomeDirectory()];
	BOOL result = [NSKeyedArchiver archiveRootObject:rubric_array toFile:rubricspath];
	if (!result) { return result; }
    NSString *questionspath = [NSString stringWithFormat:@"%@/Documents/questions.xml", NSHomeDirectory()];
    result = [NSKeyedArchiver archiveRootObject:question_array toFile:questionspath];
	if (!result) { return result; }
    NSString *ratingspath = [NSString stringWithFormat:@"%@/Documents/ratings.xml", NSHomeDirectory()];
	result = [NSKeyedArchiver archiveRootObject:rating_array toFile:ratingspath];
	if (!result) { return result; }
    if (debugArchive) NSLog(@"TPModel archiveRubrics DONE");
	return result;
}

- (BOOL) archiveData {	
    if (debugArchive) NSLog(@"TPModel archiveData");
	BOOL result = [self archiveUsers];
	if (!result) { return result; }
    result = [self archiveInfo];
	if (!result) { return result; }
    result = [self archiveCategories];
	if (!result) { return result; }
    result = [self archiveRubrics];
	if (!result) { return result; }
    if (debugArchive) NSLog(@"TPModel archiveData DONE");
    return result;
}


// ---------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------
- (NSString *) getEncryptionKey {
    if (debugCrypt) NSLog(@"TPModel getEncryptionKey with password %@", appstate.password);
    return [NSString stringWithFormat:@"%@SALTEDteachpointpasswordstring", appstate.password];
}

// ---------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------
- (NSString *) getEncryptionKeyFromPassword:(NSString *)password {
    if (debugCrypt) NSLog(@"TPModel getEncryptionKey with password %@", password);
    return [NSString stringWithFormat:@"%@SALTEDteachpointpasswordstring", password];
}

// ---------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------
- (NSData *) encryptData:(NSData *)data key:(NSString *)key {
    
    if (debugCrypt) NSLog(@"TPModel encryptData with key %@", key);
    
    // Create structure for key
    char keyPtr[kCCKeySizeAES256+1];
    bzero(keyPtr, sizeof(keyPtr));
    [key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF16StringEncoding];
    
    // Create a buffer for encryption
    size_t size = [data length] + kCCBlockSizeAES128;
	void *buf = malloc(size);
    size_t outputLength = 0;
    
    // Encrypt the data
    CCCryptorStatus result = CCCrypt(kCCEncrypt,
                                     kCCAlgorithmAES128,
                                     kCCOptionPKCS7Padding,
                                     keyPtr,
                                     kCCKeySizeAES256,
                                     NULL,
                                     [data bytes],
                                     [data length],
                                     buf,
                                     size,
                                     &outputLength);
        
    
    if(result == kCCSuccess) {
        // If success put encrypted buffer into NData object
        // This method takes over buf memory (so don't free buf manually)
        NSMutableData *encryptedOutput = [NSMutableData dataWithBytesNoCopy:buf length:outputLength]; 
        // Return the data
        if (debugModel) NSLog(@"TPModel encrypt success");
        return encryptedOutput;
    }
    
    // If unsuccessful return null
    NSLog(@"TPModel encrypt FAILURE!");
    free(buf);
    return NULL;
}

// ---------------------------------------------------------------------------------------
- (NSData *) decryptData:(NSData *)data key:(NSString *)key {
    
    if (debugCrypt) NSLog(@"TPModel decryptData with key %@", key);
    
    // Create structure for key
    char keyPtr[kCCKeySizeAES256+1];
    bzero(keyPtr, sizeof(keyPtr));
    [key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF16StringEncoding];
    
    // Create a buffer for decryption
	size_t size = [data length] + kCCBlockSizeAES128;
	void *buf = malloc(size);
    size_t outputLength = 0;
    
    
    
    CCCryptorStatus result = CCCrypt(kCCDecrypt,
                                     kCCAlgorithmAES128,
                                     kCCOptionPKCS7Padding,
                                     keyPtr,
                                     kCCKeySizeAES256,
                                     NULL,
                                     [data bytes],
                                     [data length],
                                     buf,
                                     size,
                                     &outputLength);
    
    if(result == kCCSuccess) {
        // If success put output into NData object and free the buffer
        // This method takes over buf memory (so don't free buf)
        NSMutableData *decryptedOutput = [NSMutableData dataWithBytesNoCopy:buf length:outputLength]; 
        // Return the data
        if (debugModel) NSLog(@"TPModel decrypt success");
        return decryptedOutput;
    }
    
    // If unsuccessful free buffer and return null
    NSLog(@"TPModel decrypt FAILURE!");
    free(buf);
    return NULL;
}

// ---------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------
- (void) unarchiveState_v1d4 {
    if (debugModel) NSLog(@"TPModel unarchiveState_v1d4");
    if (appstate != nil) [appstate release];
	NSString *filepath = [NSString stringWithFormat:@"%@/Documents/state.xml", NSHomeDirectory()];
	appstate = [NSKeyedUnarchiver unarchiveObjectWithFile:filepath];
	if (appstate != nil) {
        [appstate retain];
    } else {
         NSLog(@"TPModel unarchiveState_v1d4 FAILED");
        appstate = [[TPAppState alloc] init];
    }
}

- (void) unarchiveData_v1d4 {
    if (debugModel) NSLog(@"TPModel unarchiveData_v1d4");
    if (user_array != nil) [user_array release];
	NSString *userspath = [NSString stringWithFormat:@"%@/Documents/users.xml", NSHomeDirectory()];
	user_array = [NSKeyedUnarchiver unarchiveObjectWithFile:userspath];
	if (user_array != nil) {
		[user_array sortUsingSelector:@selector(compareName:)];
		[user_array retain];
	} else {
        NSLog(@"TPModel unarchiveData_v1d4 user_array FAILED");
        user_array = [[NSMutableArray alloc] init];
    }
    if (info_array != nil) [info_array release];
    NSString *infopath = [NSString stringWithFormat:@"%@/Documents/info.xml", NSHomeDirectory()];
	info_array = [NSKeyedUnarchiver unarchiveObjectWithFile:infopath];
	if (info_array != nil) {
		[info_array sortUsingSelector:@selector(compare:)];
		[info_array retain];
	} else {
        NSLog(@"TPModel unarchiveData_v1d4 info_array FAILED");
        info_array = [[NSMutableArray alloc] init];
    }
    if (rubric_array != nil) [rubric_array release];
    NSString *rubricspath = [NSString stringWithFormat:@"%@/Documents/rubrics.xml", NSHomeDirectory()];
	rubric_array = [NSKeyedUnarchiver unarchiveObjectWithFile:rubricspath];
	if (rubric_array != nil) {
		[rubric_array sortUsingSelector:@selector(compare:)];
		[rubric_array retain];
	} else {
        NSLog(@"TPModel unarchiveData_v1d4 rubric_array FAILED");
        rubric_array = [[NSMutableArray alloc] init];
    }
    if (question_array != nil) [question_array release];
    NSString *questionspath = [NSString stringWithFormat:@"%@/Documents/questions.xml", NSHomeDirectory()];
	question_array = [NSKeyedUnarchiver unarchiveObjectWithFile:questionspath];
	if (question_array != nil) {
		[question_array sortUsingSelector:@selector(compare:)];
		[question_array retain];
	} else {
        NSLog(@"TPModel unarchiveData_v1d4 question_array FAILED");
        question_array = [[NSMutableArray alloc] init];
    }
    if (rating_array != nil) [rating_array release];
    NSString *ratingspath = [NSString stringWithFormat:@"%@/Documents/ratings.xml", NSHomeDirectory()];
	rating_array = [NSKeyedUnarchiver unarchiveObjectWithFile:ratingspath];
	if (rating_array != nil) {
		[rating_array sortUsingSelector:@selector(compare:)];
		[rating_array retain];
	} else {
        NSLog(@"TPModel unarchiveData_v1d4 rating_array FAILED");
        rating_array = [[NSMutableArray alloc] init];
    }
    if (category_array != nil) [category_array release];
    NSString *catpath = [NSString stringWithFormat:@"%@/Documents/categories.xml", NSHomeDirectory()];
	category_array = [NSKeyedUnarchiver unarchiveObjectWithFile:catpath];
	if (category_array != nil) {
		[category_array sortUsingSelector:@selector(compare:)];
		[category_array retain];
	} else {
        NSLog(@"TPModel unarchiveData_v1d4 category_array FAILED");
        category_array = [[NSMutableArray alloc] init];
    }
}

// ---------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------
// Unarchive public state (plain text)
- (void) unarchivePublicState {
    if (debugArchive) NSLog(@"TPModel unarchivePublicState");
    if (publicstate != nil) [publicstate release];
    NSString *filepath = [NSString stringWithFormat:@"%@/Documents/publicstate.xml", NSHomeDirectory()];
	publicstate = [NSKeyedUnarchiver unarchiveObjectWithFile:filepath];
	if (publicstate != nil) {
        [publicstate retain];
    } else {
        NSLog(@"TPModel unarchivePublicState FAILED");
        publicstate = [[TPPublicState alloc] init];
    }
    if (debugArchive) NSLog(@"TPModel unarchivePublicState DONE");
}

// Unarchive private state (encrypted)
- (void) unarchiveState:(NSString *)password {
    if (debugArchive) NSLog(@"TPModel unarchiveState");
    if (appstate != nil) [appstate release];
	NSString *filepath = [NSString stringWithFormat:@"%@/Documents/state.xml", NSHomeDirectory()];
    NSData *encryptedData = [NSData dataWithContentsOfFile:filepath]; // Get encrypted object from file
    NSData *plainData = [self decryptData:encryptedData key:[self getEncryptionKeyFromPassword:password]];  // Decrypt object
	appstate = [NSKeyedUnarchiver unarchiveObjectWithData:plainData]; // Unarchive object
	if (appstate != nil) {
        [appstate retain];
    } else {
        NSLog(@"TPModel unarchiveState FAILED");
        appstate = [[TPAppState alloc] init];
    }
    if (debugArchive) NSLog(@"TPModel unarchiveState DONE");
}

- (void) unarchiveData {
    if (debugArchive) NSLog(@"TPModel unarchiveData users");
    if (user_array != nil) [user_array release];
	NSString *userspath = [NSString stringWithFormat:@"%@/Documents/users.xml", NSHomeDirectory()];
    NSData *encryptedData = [NSData dataWithContentsOfFile:userspath]; // Get encrypted object from file
    NSData *plainData = [self decryptData:encryptedData key:[self getEncryptionKey]];  // Decrypt object
	user_array = [NSKeyedUnarchiver unarchiveObjectWithData:plainData]; // Unarchive object
	if (user_array != nil) {
		[user_array sortUsingSelector:@selector(compareName:)];
		[user_array retain];
	} else {
        NSLog(@"TPModel unarchiveData user_array FAILED");
        user_array = [[NSMutableArray alloc] init];
    }
    if (debugArchive) NSLog(@"TPModel unarchiveData info");
    if (info_array != nil) [info_array release];
    NSString *infopath = [NSString stringWithFormat:@"%@/Documents/info.xml", NSHomeDirectory()];
    encryptedData = [NSData dataWithContentsOfFile:infopath]; // Get encrypted object from file
    plainData = [self decryptData:encryptedData key:[self getEncryptionKey]];  // Decrypt object
	info_array = [NSKeyedUnarchiver unarchiveObjectWithData:plainData]; // Unarchive object
	if (info_array != nil) {
		[info_array sortUsingSelector:@selector(compare:)];
		[info_array retain];
	} else {
        NSLog(@"TPModel unarchiveData info_array FAILED");
        info_array = [[NSMutableArray alloc] init];
    }
    if (debugArchive) NSLog(@"TPModel unarchiveData rubrics");
    if (rubric_array != nil) [rubric_array release];
	NSString *rubricspath = [NSString stringWithFormat:@"%@/Documents/rubrics.xml", NSHomeDirectory()];
	rubric_array = [NSKeyedUnarchiver unarchiveObjectWithFile:rubricspath];
	if (rubric_array != nil) {
		[rubric_array sortUsingSelector:@selector(compare:)];
		[rubric_array retain];
	} else {
        NSLog(@"TPModel unarchiveData rubric_array FAILED");
        rubric_array = [[NSMutableArray alloc] init];
    }
    if (debugArchive) NSLog(@"TPModel unarchiveData questions");
    if (question_array != nil) [question_array release];
    NSString *questionspath = [NSString stringWithFormat:@"%@/Documents/questions.xml", NSHomeDirectory()];
	question_array = [NSKeyedUnarchiver unarchiveObjectWithFile:questionspath];
	if (question_array != nil) {
		[question_array sortUsingSelector:@selector(compare:)];
		[question_array retain];
	} else {
        NSLog(@"TPModel unarchiveData question_array FAILED");
        question_array = [[NSMutableArray alloc] init];
    }
    if (debugArchive) NSLog(@"TPModel unarchiveData ratings");
    if (rating_array != nil) [rating_array release];
    NSString *ratingspath = [NSString stringWithFormat:@"%@/Documents/ratings.xml", NSHomeDirectory()];
	rating_array = [NSKeyedUnarchiver unarchiveObjectWithFile:ratingspath];
	if (rating_array != nil) {
		[rating_array sortUsingSelector:@selector(compare:)];
		[rating_array retain];
	} else {
        NSLog(@"TPModel unarchiveData rating_array FAILED");
        rating_array = [[NSMutableArray alloc] init];
    }
    if (debugArchive) NSLog(@"TPModel unarchiveData categories");
    if (category_array != nil) [category_array release];
    NSString *catpath = [NSString stringWithFormat:@"%@/Documents/categories.xml", NSHomeDirectory()];
	category_array = [NSKeyedUnarchiver unarchiveObjectWithFile:catpath];
	if (category_array != nil) {
		[category_array sortUsingSelector:@selector(compare:)];
		[category_array retain];
	} else {
        NSLog(@"TPModel unarchiveData category_array FAILED");
        category_array = [[NSMutableArray alloc] init];
    }
    if (debugArchive) NSLog(@"TPModel unarchiveData DONE");
}

- (void)unarchiveRubrics {
    if (debugArchive) NSLog(@"TPModel unarchiveRubrics");
     if (rubric_array != nil) [rubric_array release];
	NSString *rubricspath = [NSString stringWithFormat:@"%@/Documents/rubrics.xml", NSHomeDirectory()];
	rubric_array = [NSKeyedUnarchiver unarchiveObjectWithFile:rubricspath];
	if (rubric_array != nil) {
		[rubric_array sortUsingSelector:@selector(compare:)];
		[rubric_array retain];
	} else {
         NSLog(@"TPModel unarchiveData rubric_array FAILED");
        rubric_array = [[NSMutableArray alloc] init];
    }
    if (debugArchive) NSLog(@"TPModel unarchiveData questions");
    if (question_array != nil) [question_array release];
    NSString *questionspath = [NSString stringWithFormat:@"%@/Documents/questions.xml", NSHomeDirectory()];
	question_array = [NSKeyedUnarchiver unarchiveObjectWithFile:questionspath];
	if (question_array != nil) {
		[question_array sortUsingSelector:@selector(compare:)];
		[question_array retain];
	} else {
        NSLog(@"TPModel unarchiveData question_array FAILED");
        question_array = [[NSMutableArray alloc] init];
    }
    if (debugArchive) NSLog(@"TPModel unarchiveData ratings");
    if (rating_array != nil) [rating_array release];
    NSString *ratingspath = [NSString stringWithFormat:@"%@/Documents/ratings.xml", NSHomeDirectory()];
	rating_array = [NSKeyedUnarchiver unarchiveObjectWithFile:ratingspath];
	if (rating_array != nil) {
		[rating_array sortUsingSelector:@selector(compare:)];
		[rating_array retain];
	} else {
        NSLog(@"TPModel unarchiveData rating_array FAILED");
        rating_array = [[NSMutableArray alloc] init];
    }
    if (debugArchive) NSLog(@"TPModel unarchiveRubrics DONE");
}

// ---------------------------------------------------------------------------------------
// deriveData - derive useful data arrays and metrics from synced data
// ---------------------------------------------------------------------------------------
- (void) deriveData {
    	
    if (debugModel) NSLog(@"deriveData");
    
    // Derive list of permitted users
    [self deriveUserList];
    
	// Get sorted list of all published rubrics
    [self deriveRubricList];
    
    // Get list of userdata for selected target user
    [self deriveUserDataList];
    
    // Get userdata info for users
    [self deriveUserDataInfo];
    
    // Get list of images for selected target user
    [self deriveImageList];
    
    // Get list of videos for selected target user //jxi;
    [self deriveVideoList];
    
    // Get 
    // Compute school list
    num_schools = 0;
    [school_list removeAllObjects];
    [school_list_lengths removeAllObjects];
    [user_list sortUsingSelector:@selector(compareSchool:)];
    NSString *schools = @"";
    for (TPUser *user in user_list) {
        NSString *schooltarget = [NSString stringWithFormat:@"<BEG>%@<END>", user.schools];
        if ([schools rangeOfString:schooltarget].location == NSNotFound) {
            schools = [schools stringByAppendingString:schooltarget];
            [school_list addObject:user.schools];
            [school_list_lengths addObject:[NSNumber numberWithInt:1]];
            //NSLog(@"school length count %d", [school_list_lengths count]);
            num_schools++;
        } else {
            int index = 0;
            for (NSString *school_str in school_list) {
                if ([school_str compare:user.schools] == NSOrderedSame) {
                    break;
                } else {
                    index++;
                }
            }
            [school_list_lengths
             replaceObjectAtIndex:index
             withObject:[NSNumber numberWithInt:[[school_list_lengths objectAtIndex:index] intValue] + 1]];
        }
    }
    
    // Compute grade list
    num_grades = 0;
    [grade_list removeAllObjects];
    [grade_list_lengths removeAllObjects];
    [user_list sortUsingSelector:@selector(compareGrade:)];
    NSString *grades = @"";
    for (TPUser *user in user_list) {
        NSString *gradetarget;
        NSString *gradestring;
        gradetarget = [NSString stringWithFormat:@"<BEG>%@<END>", [user getGradeString]];
        gradestring = [NSString stringWithFormat:@"%@", [user getGradeString]];
        if ([grades rangeOfString:gradetarget].location == NSNotFound) {
            grades = [grades stringByAppendingString:gradetarget];
            [grade_list addObject:gradestring];
            [grade_list_lengths addObject:[NSNumber numberWithInt:1]];
            num_grades++;
        } else {
            int index = 0;
            for (NSString *grade_str in grade_list) {
                if ([grade_str compare:gradestring] == NSOrderedSame) {
                    break;
                } else {
                    index++;
                }
            }
            [grade_list_lengths
             replaceObjectAtIndex:index
             withObject:[NSNumber numberWithInt:[[grade_list_lengths objectAtIndex:index] intValue] + 1]];
        }
    }
    
    // Sort and reload user list
    [view sortUsers];
}

// ---------------------------------------------------------------------------------------
- (void) deriveUserList {
    
    [user_list removeAllObjects];
    for (TPUser *user in user_array) {
        if (user.permission > TP_PERMISSION_UNKNOWN) {
            [user_list addObject:user];
        }
	}
}

// ---------------------------------------------------------------------------------------
- (void) deriveUserDataList {
    
    // Get all userdata for target user
    [database getUserDataList:userdata_list target:(int)appstate.target_id filterUserId:(self.useOwnData?appstate.user_id:0)];
    
    // Substitute rubric name for recorded name if userdata is a form
    NSDictionary *formNameByFormId = [self getFormNameByFormId];
    for (TPUserData *userdata in userdata_list) {
        if (userdata.type == TP_USERDATA_TYPE_FORM) {
            NSString *title = [formNameByFormId objectForKey:[NSNumber numberWithInt:userdata.rubric_id]];
            if (title != nil) {
                userdata.name = title;
            }
        }
    }
}

// ---------------------------------------------------------------------------------------
// getFormNameByFormId - return an NSDictionary of form titles by rubric_id
// ---------------------------------------------------------------------------------------
- (NSDictionary *)getFormNameByFormId {
    NSMutableDictionary *formNameByFormId = [[[NSMutableDictionary alloc] initWithCapacity:100] autorelease];
    for (TPRubric *rubric in rubric_array) {
        [formNameByFormId setObject:rubric.title forKey:[NSNumber numberWithInt:rubric.rubric_id]];
    }
    return formNameByFormId;
}

// ---------------------------------------------------------------------------------------
- (void) deriveRubricList {
    // Get list of all published rubrics
    [rubric_list removeAllObjects];
	for (TPRubric *rubric in rubric_array) {
        if (rubric.state == TP_RUBRIC_PUBLISHED_STATE) [rubric_list addObject:rubric];
	}
}

// ---------------------------------------------------------------------------------------
- (void) deriveImageList {
    // Get all images for target user
    [database getImageList:image_list target:(int)appstate.target_id filterUserId:(self.useOwnData?appstate.user_id:0)];
    //[image_list sortUsingSelector:@selector(compareModifiedDate:)];
}

//jxi;
// ---------------------------------------------------------------------------------------
- (void) deriveVideoList {
    // Get all images for target user
    [database getVideoList:video_list target:(int)appstate.target_id filterUserId:(self.useOwnData?appstate.user_id:0)];
    //[image_list sortUsingSelector:@selector(compareModifiedDate:)];
}

// ---------------------------------------------------------------------------------------
// deriveUserDataInfo - generate user form info to annotate user list shown in UI
// ---------------------------------------------------------------------------------------
- (void) deriveUserDataInfo {
    
    // Get elapsed times and number of recorded forms by user_id
    NSDictionary *totalElapsedByUserId = [database getTotalElapsedByUserId:(self.useOwnData?appstate.user_id:0)];
    NSDictionary *totalFormsByUserId = [database getTotalFormsByUserId:(self.useOwnData?appstate.user_id:0)];
    
    // If form data has been recorded
    if ([totalFormsByUserId count] > 0) {
        
        // Loop over all users and compute stats
        for (TPUser *user in user_list) {
            
            NSNumber *total_elapsed = [totalElapsedByUserId objectForKey:[NSNumber numberWithInt:user.user_id]];
            if (total_elapsed == nil) {
                user.total_elapsed = 0;
            } else {
                user.total_elapsed = [total_elapsed intValue];
            }
            
            NSNumber *total_forms = [totalFormsByUserId objectForKey:[NSNumber numberWithInt:user.user_id]];
            if (total_forms == nil) {
                user.total_forms = 0;
            } else {
                user.total_forms = [total_forms intValue];
            }
            
        } // End loop over user list
    } // End condition on recorded forms
}

// ---------------------------------------------------------------------------------------
- (void) dump {
	
	NSLog(@"DUMP Data:");
	
	NSLog(@" public: state=%@ district=%@ user=%@ %@ hash=%@",
		  publicstate.state, publicstate.district_name, publicstate.first_name, publicstate.last_name, publicstate.hashed_password);
    
    NSLog(@" state: state=%@ district=%@ user=%@ %@ user=%d target=%d district=%d rubric=%d userdata=%@",
		  appstate.state, publicstate.district_name, publicstate.first_name, publicstate.last_name,
          appstate.user_id, appstate.target_id, appstate.district_id,
          appstate.rubric_id, appstate.userdata_id);
    
	NSLog(@" Users");
	for (TPUser *user in user_array) {
		NSLog(@"  user: ID=%d perm=%d first_name=%@ last_name=%@ school=%@ subject=%@ modified=%@",
			  user.user_id, user.permission, user.first_name, user.last_name, user.schools, user.subjects, [self stringFromDate:user.modified]);
	}
	
    NSLog(@" Info");
	for (TPUserInfo *info in info_array) {
		NSLog(@"  info: ID=%d info=%@ modified=%@",
			  info.user_id, info.info, [self stringFromDate:info.modified]);
	}
    
    NSLog(@" Rubrics");
	for (TPRubric *rubric in rubric_array) {
		NSLog(@"  rubric: ID=%d title=%@ version=%d state=%d",
			  rubric.rubric_id, rubric.title, rubric.version, rubric.state);
	}
    
    NSLog(@" Questions");
	for (TPQuestion *question in question_array) {
		NSLog(@"  question: ID=%d rubric=%d order=%d type=%d category=%d title=%@ optional=%d",
			  question.question_id, question.rubric_id, question.order, question.type,
              question.category, question.title, question.optional);
        NSLog(@"            prompt=%@", question.prompt);
	}
    
    NSLog(@" Ratings");
	for (TPRating *rating in rating_array) {
		NSLog(@"  rating: ID=%d question=%d rubric=%d order=%d value=%f",
			  rating.rating_id, rating.question_id, rating.rubric_id, rating.rorder, rating.value);
        NSLog(@"          title=%@ text=%@", rating.title, rating.text);
	}
    
    NSLog(@" Categories");
	for (TPCategory *category in category_array) {
		NSLog(@"  category: ID=%d order=%d state=%d, name=%@",
			  category.category_id, category.corder, category.state, category.name);
	}

    NSLog(@" Derived user list size=%d", [user_list count]);
    
	NSLog(@" Derived rubric list size=%d", [rubric_list count]);
    
    NSLog(@" Derived userdata list size=%d", [userdata_list count]);
    
	NSLog(@"DUMP Data - COMPLETE");
}

- (void) dumpstate {
	
	NSLog(@"DUMP State:");
	
    NSLog(@" public: state=%@ district=%@ user=%@ %@ hash=%@ demo=%d",
		  publicstate.state, publicstate.district_name, publicstate.first_name, publicstate.last_name, publicstate.hashed_password, publicstate.is_demo);
    
	NSLog(@" state: state=%@ district=%@ user=%@ %@ userID=%d login=%@ pw=%@ target=%d district=%d rubric=%d userdata=%@",
		  appstate.state, publicstate.district_name, publicstate.first_name, publicstate.last_name,
          appstate.user_id, appstate.login, appstate.password,
          appstate.target_id, appstate.district_id,
          appstate.rubric_id, appstate.userdata_id);

    NSLog(@" Derived user array size=%d", [user_array count]);
    NSLog(@" Derived user list size=%d", [user_list count]);
	NSLog(@" Derived rubric list size=%d", [rubric_list count]);
    NSLog(@" Derived userdata list size=%d", [userdata_list count]);
	
	NSLog(@"DUMP State - COMPLETE");
}

// ---------------------------------------------------------------------------------------
- (void) dumpDatabase {
    NSLog(@"TPModel dumpDatabase %d", (int)database);
    [database dumpDatabase];
}

// ---------------------------------------------------------------------------------------
- (NSString *)getState {
    return publicstate.state;
}

- (void) setState:(NSString *)state {
    publicstate.state = state;
	appstate.state = state;
    // Archive state if not install or timeout state (no password otherwise)
    if (![publicstate.state isEqualToString:@"install"] && ![publicstate.state isEqualToString:@"timeout"]) {
        [self archiveState];
    }
}

// ---------------------------------------------------------------------------------------
- (NSString *) getLoginUserName {
    for (TPUser *user in user_array) {
        if (user.user_id == appstate.user_id) {
            return [user getDisplayName];
        }
    }
    return @"";
}

- (NSString *) getTargetUserName {
    for (TPUser *user in user_array) {
        if (user.user_id == appstate.target_id) {
            return [user getDisplayName];
        }
    }
    return @"";
}

- (void) setSubjectByIndex:(NSInteger)index {
	appstate.target_id = [(TPUser *)[user_list objectAtIndex:index] user_id];
}

- (NSString *) getUserName:(int)user_id {
	if (user_id > 0) {
		for (TPUser *user in user_array) {
			if (user.user_id == user_id) { return [user getDisplayName]; }
		}
	}
	return @"";
}

- (NSInteger) getSubjectIndex {
	if (appstate.target_id) {
		int index = 0;
		for (TPUser *user in user_list) {
			if (user.user_id == appstate.target_id) { return index; }
			index++;
		}
	}
	return -1;
}

- (NSString *) getDetailViewPromptString {
    TPUser *subject = [self getCurrentTarget];
    if (subject) {
        return [NSString stringWithFormat:@"%@ %@  -  %@", subject.first_name, subject.last_name, subject.schools];
    } else {
        return @"";
    }
}

// ---------------------------------------------------------------------------------------
- (TPUser *) getCurrentUser {
    for (TPUser *user in user_array) {
        if (user.user_id == appstate.user_id) return user;
    }
    return nil;
}

- (TPUser *) getCurrentTarget {
    for (TPUser *user in user_array) {
        if (user.user_id == appstate.target_id) return user;
    }
    return nil;
}

- (TPUserInfo *) getCurrentTargetInfo {
    for (TPUserInfo *userinfo in info_array) {
        if (userinfo.user_id == appstate.target_id) return userinfo;
    }
    return nil;
}

// ---------------------------------------------------------------------------------------
- (TPUserData *) getUserDataFromListById:(NSString *)userdata_id {
    
    for (TPUserData *userdata in userdata_list) {
        if ([userdata.userdata_id isEqualToString:userdata_id]) {
            return userdata;
        }
    }
    return nil;
}

//jxi;
// ---------------------------------------------------------------------------------------
- (TPVideo *) getVideoFromListById:(NSString *)userdata_id
{
    for (TPVideo *userdata in video_list) {
        if ([userdata.userdata_id isEqualToString:userdata_id]) {
            return userdata;
        }
    }
    return nil;
}

// ---------------------------------------------------------------------------------------
- (TPImage *) getImageFromListById:(NSString *)userdata_id type:(int)type {
    
    for (TPImage *image in image_list) {
        if ([image.userdata_id isEqualToString:userdata_id] && image.type == type) {
            return image;
        }
    }
    return nil;
}

// ---------------------------------------------------------------------------------------
- (void) setCurrentRubricById:(int)rubric_id {
    
    // Set current rubric ID
    appstate.rubric_id = rubric_id;
    
    // Derive sorted question list (assumes questions are pre-sorted in question_array)
    if (rubric_id > 0) [self getQuestionListByRubricId:question_list rubricId:rubric_id];
    
    // If new form set permission and signed state
    if ([appstate.userdata_id length] == 0) {
        userFormPermission = TP_USER_FORM_PERMISSION_OWNER;
        userHasSignedForm = NO;
        
    // Otherwise editing existing form
    } else {
        
        TPUserData *userdata = [self getCurrentUserData];
        
        // Compute user permission for current form
        if (appstate.user_id  == userdata.user_id) {
            userFormPermission = TP_USER_FORM_PERMISSION_OWNER;
        } else if (appstate.user_id  == userdata.target_id) {
            userFormPermission = TP_USER_FORM_PERMISSION_SUBJECT;
        } else {
            userFormPermission = TP_USER_FORM_PERMISSION_THIRDPARTY;
        }
            
        // Compute if user has signed form (must be refreshed if new signature added while editing)
        userHasSignedForm = NO;
        for (TPQuestion *question in question_list) {
            
            // If signature defined then check if user has signed form
            if (question.type == TP_QUESTION_TYPE_SIGNATURE_RESTRICTED) {
                
                // Find recorded signature
                TPRubricData *signature = nil;
                for (TPRubricData *rubricdata in userdata.rubricdata) {
                    if (rubricdata.question_id == question.question_id) {
                        signature = rubricdata;
                        break;
                    }
                }
                if (signature == nil) continue; // If no signature then skip this question
            
                // Check if user has signed
                if (question.subtype == TP_QUESTION_SUBTYPE_NORMAL &&
                    userFormPermission == TP_USER_FORM_PERMISSION_OWNER &&
                    [signature.text length] > 0) {
                    userHasSignedForm = YES;
                    return;
                } else if (question.subtype == TP_QUESTION_SUBTYPE_REFLECTION &&
                           userFormPermission == TP_USER_FORM_PERMISSION_SUBJECT &&
                           [signature.text length] > 0) {
                    userHasSignedForm = YES;
                    return;
                } else if (question.subtype == TP_QUESTION_SUBTYPE_THIRDPARTY &&
                           userFormPermission == TP_USER_FORM_PERMISSION_THIRDPARTY &&
                           [signature.text length] > 0) {
                    userHasSignedForm = YES;
                    return;
                }
            } // End condition on question type
            
        } // End loop over defined questions
        
    } // End condition on new or existing form
}

// ---------------------------------------------------------------------------------------
- (void) userHasSignedQuestion:(TPQuestion *)question {
    userHasSignedForm = YES;
}

// ---------------------------------------------------------------------------------------
- (void) getQuestionListByRubricId:(NSMutableArray *)questionList rubricId:(int)rubricId {
    
    // Get sorted question list (assumes questions are pre-sorted in question_array)
    [questionList removeAllObjects];
    for (TPQuestion *question in question_array) {
        if (question.rubric_id == rubricId) {
            [questionList addObject:question];
        }
    }
    [question_list sortUsingSelector:@selector(compare:)];
}

// ---------------------------------------------------------------------------------------
- (void) clearCurrentRubric {
    
    if (debugModel) NSLog(@"TPModel clearCurrentRubric");
    
    appstate.rubric_id = 0;
    appstate.userdata_id = @"";
    appstate.can_edit = 0;
    userCanEditCurrentUserdata = NO;
    [question_list removeAllObjects];
    userFormPermission = TP_USER_FORM_PERMISSION_UNKNOWN;
    userHasSignedForm = NO;
}

// ---------------------------------------------------------------------------------------
- (TPRubric *) getCurrentRubric {
    for (TPRubric *rubric in rubric_array) {
        if  (rubric.rubric_id == appstate.rubric_id) {
            return rubric;
        }
    }
    return nil;
}

// ---------------------------------------------------------------------------------------
- (TPRubric *) getRubricById:(int)rubricId {
    for (TPRubric *rubric in rubric_array) {
        if  (rubric.rubric_id == rubricId) {
            return rubric;
        }
    }
    return nil;
}

// ---------------------------------------------------------------------------------------
- (TPUserData *) getCurrentUserData {
    return userdata_current;
}

// ---------------------------------------------------------------------------------------
- (void) deleteUserData:(NSString *)userdata_id includingImages:(BOOL)includingImages {
    [database deleteUserData:userdata_id includingImages:includingImages];
    [self deriveImageList];
    [self deriveVideoList]; //jxi;
}

// ---------------------------------------------------------------------------------------
- (void) purgeUserRecordedDemoData {
    
    // Skip if not demo user
    if (publicstate.is_demo == 0) return;
    
    // Get list of all userdata needing to be synced
    NSMutableArray *userdataPurgeList = [NSMutableArray arrayWithCapacity:0];
    NSMutableArray *imagedataPurgeList = [NSMutableArray arrayWithCapacity:0];
    NSMutableArray *videoPurgeList = [NSMutableArray arrayWithCapacity:0]; //jxi;

    //[database getUserDataUnsyncedDataList:userdataPurgeList localImagesList:imagedataPurgeList includeCurrentUserdata:YES];
    [database getUserDataUnsyncedDataList:userdataPurgeList localImagesList:imagedataPurgeList localVideosList:videoPurgeList includeCurrentUserdata:YES]; //jxi;
    
    // Loop over all and delete
    for (NSString *userdata_id in userdataPurgeList) {
        [self deleteUserData:userdata_id includingImages:YES];
    }
    for (NSString *userdata_id in imagedataPurgeList) {
        [self deleteUserData:userdata_id includingImages:YES];
    }
    for (NSString *userdata_id in videoPurgeList) { //jxi;
        [self deleteUserData:userdata_id includingImages:YES];
    }
}

// ---------------------------------------------------------------------------------------
- (BOOL) ratingIsSelected:(TPRating *)rating question:(TPQuestion *)question {
    return [database ratingIsSelected:rating question:question userdata_id:appstate.userdata_id];
}

- (float) ratingValue:(TPRating *)rating question:(TPQuestion *)question {
    return [database ratingValue:rating question:question userdata_id:appstate.userdata_id];
}

- (NSString *) questionText:(TPQuestion *)question {
    return [database questionText:question userdata_id:appstate.userdata_id];
}

- (NSString *) questionText:(TPQuestion *)question userdata_id:(NSString *)userdata_id 
{
    return [database questionText:question userdata_id:userdata_id];
}

- (NSString *) questionAnnot:(TPQuestion *)question {
    return [database questionAnnot:question userdata_id:appstate.userdata_id];
}

- (NSString *) questionAnnot:(TPQuestion *)question userdata_id:(NSString *)userdata_id 
{
    return [database questionAnnot:question userdata_id:userdata_id];
}

- (NSDate *) questionDatevalue:(TPQuestion *)question {
    return [database questionDatevalue:question userdata_id:appstate.userdata_id];
}

// ---------------------------------------------------------------------------------------
// newUserData - call when creating new form to edit
// ---------------------------------------------------------------------------------------
- (void) newUserData:(TPRubric *)rubric {
    
    if (debugModel) NSLog(@"TPModel newUserData");
    
    // Set the current rubric
    appstate.userdata_id = @""; // Make sure userdata indicates new form (needed for deriving data in setCurrentRubricById)
    [self setCurrentRubricById:rubric.rubric_id];
    
    // Create user data instance, add to list, and update database
    TPUserData *userdata = [[TPUserData alloc] initWithModel:self name:rubric.title rubricId:rubric.rubric_id type:1];
    appstate.userdata_id = userdata.userdata_id;
    appstate.can_edit = 1;
    [userdata_list addObject:userdata];
    userdata_current = userdata;
    userCanEditCurrentUserdata = [self userCanEditUserdata];
    if (userCanEditCurrentUserdata) {
        appstate.can_edit = 1;
    } else {
        appstate.can_edit = 0;
    }
    [database updateUserData:userdata setModified:YES];
    //[userdata release];
    
    [self deriveUserDataInfo];
    [view reloadUserList];
    [self setNeedSyncStatus:NEEDSYNC_STATUS_NOTSYNCED forced:NO];
}

// ---------------------------------------------------------------------------------------
// setUserData - call when selecting existing form to edit
// ---------------------------------------------------------------------------------------
- (void) setUserData:(TPUserData *)userdata {
    
    if (debugModel) NSLog(@"TPModel setUserData");
    
    // Set current userdata
    appstate.userdata_id = userdata.userdata_id;
    userdata_current = [[TPUserData alloc] initWithUserData:userdata];
    userCanEditCurrentUserdata = [self userCanEditUserdata];
    if (userCanEditCurrentUserdata) {
        appstate.can_edit = 1;
    } else {
        appstate.can_edit = 0;
    }
    
    // Set the current rubric
    int rubric_id = [database getRubricIdFromUserdataID:userdata.userdata_id];
    [self setCurrentRubricById:rubric_id];
}

// ---------------------------------------------------------------------------------------
- (void) updateUserData:(TPUserData *)userdata setModified:(BOOL)setModified {
    [database updateUserData:userdata setModified:setModified];
}

// ---------------------------------------------------------------------------------------
- (void) updateImage:(TPImage *)image {
    [database updateImage:image];
}

// ---------------------------------------------------------------------------------------
- (void) updateImageOrigin:(NSString *)userdata_id type:(int)image_type origin:(int)neworigin {
    [database updateImageOrigin:userdata_id type:image_type origin:neworigin];
}

// ---------------------------------------------------------------------------------------
// jxi;
// ---------------------------------------------------------------------------------------
- (void) updateVideoOrigin:(NSString *)userdata_id type:(int)image_type origin:(int)neworigin {
    [database updateVideoOrigin:userdata_id type:image_type origin:neworigin];
}

// ---------------------------------------------------------------------------------------
- (int) getUserDataState:(NSString *)userdata_id {
    return [database getUserDataState:userdata_id];
}

// ---------------------------------------------------------------------------------------
- (void) updateUserDataState:(NSString *)userdata_id state:(int)newstate {
    [database updateUserDataState:userdata_id state:newstate];
}

// ---------------------------------------------------------------------------------------
- (void) updateUserDataStateNoTimestamp:(NSString *)userdata_id state:(int)newstate {
    [database updateUserDataStateNoTimestamp:userdata_id state:newstate];
}


// ---------------------------------------------------------------------------------------
// updateUserDataRatingCumulative - updates rating value in temporary userdata instance and in
// database.  Sets current value for cumulative multiselect questions.
// ---------------------------------------------------------------------------------------
- (void) updateUserDataRatingCumulative:(TPRating *)rating cumulativeValue:(float)value {
        
    int edit_made = 0;
    TPRubricData *rubricdata = nil;
    int ratingIndex = 0;
    
    // Get userdata
    TPUserData *userdata = [self getCurrentUserData];
    
    // Get related question
    TPQuestion *question = [self getQuestionById:rating.question_id];
            
    // Only for cumulative multiselect questions
    switch (question.type) {
            
        case TP_QUESTION_TYPE_MULTISELECT_CUMULATIVE:
            
            // Find existing rubricdata 
            for (TPRubricData *item in userdata.rubricdata) {
                if (item.rating_id == rating.rating_id && item.annotation == 0) {
                    rubricdata = item;
                    break;
                }
                ratingIndex++;
            }

            // If matching rating exists but value is not greater than 0, then remove
            if (rubricdata != nil && value <= 0.0) {
                    rubricdata.user = appstate.user_id;
                    rubricdata.modified = [NSDate date];
                    edit_made = 1;
                    [userdata.rubricdata removeObjectAtIndex:ratingIndex];
            }
			// If matching rating exists and rubricdata value is different from current, then update value
            if (rubricdata != nil && rubricdata.value != value) {
                rubricdata.user = appstate.user_id;
                rubricdata.modified = [NSDate date];
				edit_made = 1;
				((TPRubricData *)[userdata.rubricdata objectAtIndex:ratingIndex]).value = value;
            }
            // If no rating exists and rating has value greater than 0, then add new rating
            if (rubricdata == nil && value > 0.0) {
                    edit_made = 1;
                    rubricdata = [[[TPRubricData alloc] initWithModel:self rating:rating] autorelease];
                    rubricdata.user = appstate.user_id;
                    rubricdata.modified = [NSDate date];
					rubricdata.value = value;
                    [userdata.rubricdata addObject:rubricdata];
            }
            break;
            
    } // End switch
    
    // Update if edits made then update database
    if (edit_made == 1) {
        
        // Update sync flag
        [self setStateToSync:userdata];
        
        // Update database copy
        [database updateUserData:userdata setModified:YES];
        [self setNeedSyncStatus:NEEDSYNC_STATUS_NOTSYNCED forced:NO];
    }
}

// ---------------------------------------------------------------------------------------
// updateUserDataRating - updates rating value in temporary userdata instance and in
// database.  Uses question type to unselect prior ratings if required (rating scale
// and uniselect questions).
// ---------------------------------------------------------------------------------------
- (void) updateUserDataRating:(TPRating *)rating selected:(BOOL)selected {
	
    int edit_made = 0;
    TPRubricData *rubricdata = nil;
    int ratingIndex = 0;
    
    // Get userdata
    TPUserData *userdata = [self getCurrentUserData];
    
    // Get related question
    TPQuestion *question = [self getQuestionById:rating.question_id];
	
    // Handle single and multi selections differently
    switch (question.type) {
            
        case TP_QUESTION_TYPE_RATING:
        case TP_QUESTION_TYPE_UNISELECT:
            
            // Find existing rubricdata 
            for (TPRubricData *item in userdata.rubricdata) {
                if (item.question_id == rating.question_id && item.annotation == 0) {
                    rubricdata = item;
                    break;
                }
                ratingIndex++;
            }
			
            // If matching rating exists
            if (rubricdata != nil) {
                
                // If rating is selected and different than existing value, then change to given rating
                if (selected) {
                    if (rubricdata.rating_id != rating.rating_id) {
                        edit_made = 1;
                        rubricdata.rating_id = rating.rating_id;
                        rubricdata.value = rating.value;
                        rubricdata.text = rating.text;
                        rubricdata.user = appstate.user_id;
                        rubricdata.modified = [NSDate date];
                    }
                    
					// If rating is not selected and same as existing value, then remove rating 
                } else {
                    if (rubricdata.rating_id == rating.rating_id) {
                        rubricdata.user = appstate.user_id;
                        rubricdata.modified = [NSDate date];
                        edit_made = 1;
                        [userdata.rubricdata removeObjectAtIndex:ratingIndex];
                    }
                }
                
				// If no existing data but rating is selected, then add new rating
            } else if (selected) {
                edit_made = 1;
                rubricdata = [[[TPRubricData alloc] initWithModel:self rating:rating] autorelease];
                rubricdata.user = appstate.user_id;
                rubricdata.modified = [NSDate date];
                [userdata.rubricdata addObject:rubricdata];
            }
            break;
            
        case TP_QUESTION_TYPE_MULTISELECT:
            
            // Find existing rubricdata 
            for (TPRubricData *item in userdata.rubricdata) {
                if (item.rating_id == rating.rating_id && item.annotation == 0) {
                    rubricdata = item;
                    break;
                }
                ratingIndex++;
            }
			
            // If matching rating exists but rating is not selected, then remove
            if (rubricdata != nil && !selected) {
                rubricdata.user = appstate.user_id;
                rubricdata.modified = [NSDate date];
				edit_made = 1;
				[userdata.rubricdata removeObjectAtIndex:ratingIndex];
            }
            // If no rating exists and rating is selected, then add new rating
            if (rubricdata == nil && selected) {
				edit_made = 1;
				rubricdata = [[[TPRubricData alloc] initWithModel:self rating:rating] autorelease];
                rubricdata.user = appstate.user_id;
                rubricdata.modified = [NSDate date];
				[userdata.rubricdata addObject:rubricdata];
            }
            break;
            
    } // End switch
    
    // Update if edits made then update database
    if (edit_made == 1) {
        
        // Update sync flag
        [self setStateToSync:userdata];
        
        // Update database copy
        [database updateUserData:userdata setModified:YES];
        [self setNeedSyncStatus:NEEDSYNC_STATUS_NOTSYNCED forced:NO];
    }
}

// ---------------------------------------------------------------------------------------
// updateUserDataText - update text or annotation fields.  Delete existing entry if empty
// text.
// ---------------------------------------------------------------------------------------
- (void) updateUserDataText:(TPQuestion *)question text:(NSString *)sometext isAnnot:(int)isAnnot {
    
    if (debugModel)  NSLog(@"TPModel updateUserDataText userdataId %@ text %@", self.appstate.userdata_id, sometext);
    
    // Get userdata
    TPUserData *userdata = [self getCurrentUserData];
    BOOL needDatabaseUpdate = NO;
    
    if (debugModel) NSLog(@"TPModel updateUserDataText userdata ID %@", userdata.userdata_id);
    
    // Find existing rubricdata 
    TPRubricData *rubricdata = nil;
    for (TPRubricData *item in userdata.rubricdata) {
        if (item.question_id == question.question_id && item.annotation == isAnnot) {
            rubricdata = item;
            break;
        }
    }
    
    // If existing data then update
    if (rubricdata != nil) {
        
        // If text is non empty change current
        if ([sometext length] > 0) {
            rubricdata.text = sometext;
            rubricdata.user = appstate.user_id;
            rubricdata.modified = [NSDate date];
            needDatabaseUpdate = YES;
        // Otherwise delete current
        } else {
            [userdata.rubricdata removeObject:rubricdata];
            needDatabaseUpdate = YES;
        }
        
    // Otherwise no existing data
    } else {
        // Check that text is non empty
        if ([sometext length] > 0) {
            rubricdata = [[[TPRubricData alloc] initWithModel:self question:question text:sometext annotation:isAnnot] autorelease];
            rubricdata.user = appstate.user_id;
            rubricdata.modified = [NSDate date];
            [userdata.rubricdata addObject:rubricdata];
            needDatabaseUpdate = YES;
        }
    }
    
        
    // If needs update then do it
    if (needDatabaseUpdate) {
        [self setStateToSync:userdata]; // Update sync flag
        [database updateUserData:userdata setModified:YES];
        [self setNeedSyncStatus:NEEDSYNC_STATUS_NOTSYNCED forced:NO];
    }
}

// ---------------------------------------------------------------------------------------
- (void) updateUserDataDatevalue:(TPQuestion *)question dateValue:(NSDate *)datevalue {
    
    if (debugModel) NSLog(@"updateUserDataDatevalue appstate userdata ID %@", self.appstate.userdata_id);
    
    // Get userdata
    TPUserData *userdata = [self getCurrentUserData];
    BOOL needDatabaseUpdate = NO;
        
    // Find existing rubricdata 
    TPRubricData *rubricdata = nil;
    for (TPRubricData *item in userdata.rubricdata) {
        if (item.question_id == question.question_id) {
            rubricdata = item;
            break;
        }
    }
    
    // If existing data then update
    if (rubricdata != nil) {
        
        // If date is non empty change current
        if (datevalue != nil) {
            rubricdata.user = appstate.user_id;
            rubricdata.modified = [NSDate date];
            rubricdata.datevalue = datevalue;
            needDatabaseUpdate = YES;
        // Otherwise delete current
        } else {
            [userdata.rubricdata removeObject:rubricdata];
            needDatabaseUpdate = YES;
        }
        
    // Otherwise no existing data
    } else {
        // Check that date is non empty
        if (datevalue != nil) {
            rubricdata = [[[TPRubricData alloc] initWithModel:self question:question text:@"" annotation:0] autorelease];
            rubricdata.user = appstate.user_id;
            rubricdata.modified = [NSDate date];
            rubricdata.datevalue = datevalue;
            [userdata.rubricdata addObject:rubricdata];
            needDatabaseUpdate = YES;
        }
    }
    
    // If needs update then do it
    if (needDatabaseUpdate) {
        [self setStateToSync:userdata]; // Update sync flag
        [database updateUserData:userdata setModified:YES];
        [self setNeedSyncStatus:NEEDSYNC_STATUS_NOTSYNCED forced:NO];
    }
}

// ---------------------------------------------------------------------------------------
- (void) purgeUserDataIfEmpty:(NSString *)userdata_id {
    
    if (debugModel) NSLog(@"TPModel purgeUserDataIfEmpty userdata_id %@", userdata_id);
    
    BOOL didPurgeData = [database purgeUserDataIfEmpty:userdata_id];
    if (didPurgeData) {
      // Reset derived data
      [self deriveUserDataInfo];
      [view reloadUserList];
    }
}

// ---------------------------------------------------------------------------------------
// Update state to sync if previously empty or previously empty.
// ---------------------------------------------------------------------------------------
- (void) setStateToSync:(TPUserData *)userdata {
    if (userdata.state == TP_USERDATA_DELETED_STATE ||
        userdata.state == TP_USERDATA_EMPTY_STATE) {
        
        userdata.state = TP_USERDATA_PARTIAL_STATE;
    } else if (userdata.state == TP_USERDATA_SYNCED_PARTIAL_STATE ||
               userdata.state == TP_USERDATA_SYNCED_COMPLETE_STATE) {
        
        userdata.state = TP_USERDATA_PARTIAL_STATE;
    }
}
// ---------------------------------------------------------------------------------------
- (void) updateUserDataShare:(int)newshare {
    
    // Get userdata
    TPUserData *userdata = [self getCurrentUserData];
    
    // Update the share flag
    userdata.share = newshare;
    
    // Update sync flag
    [self setStateToSync:userdata];
    
    [database updateUserDataShare:userdata.userdata_id share:newshare];
    [database updateUserDataState:userdata.userdata_id state:userdata.state];
    
    [self setNeedSyncStatus:NEEDSYNC_STATUS_NOTSYNCED forced:NO];
}

// ---------------------------------------------------------------------------------------
- (void) updateUserDataElapsed:(int)newelapsed {
    
    // Get userdata
    TPUserData *userdata = [self getCurrentUserData];
    
    // Update the elapsed value
    userdata.elapsed += newelapsed;
    
    // Update sync flag
    [self setStateToSync:userdata];
    
    [database updateUserDataElapsed:userdata.userdata_id elapsed:newelapsed];
    [database updateUserDataState:userdata.userdata_id state:userdata.state];
    
    [self deriveUserDataInfo];
    [view reloadUserList];
    
    [self setNeedSyncStatus:NEEDSYNC_STATUS_NOTSYNCED forced:NO];
}

// ---------------------------------------------------------------------------------------
- (void) updateUserDataGrade:(int)newgrade {
    
    // Get userdata
    TPUserData *userdata = [self getCurrentUserData];
    
    // Update the elapsed value
    userdata.grade = newgrade;
    
    // Update sync flag
    [self setStateToSync:userdata];
    
    [database updateUserDataGrade:userdata.userdata_id grade:newgrade];
    [database updateUserDataState:userdata.userdata_id state:userdata.state];
    
    [self setNeedSyncStatus:NEEDSYNC_STATUS_NOTSYNCED forced:NO];
}

// ---------------------------------------------------------------------------------------
- (TPRating *) getRatingByQuestionId:(int)question_id order:(int)order {
    
    for (TPRating *rating in view.model.rating_array) {
        if (rating.question_id == question_id &&
            rating.rorder == order) {
            return rating;
        }
    }
    return nil;
}

// ---------------------------------------------------------------------------------------
- (void) getRecRubricList:(NSMutableArray *)userDataIdArray {
    [database getRecRubricList:userDataIdArray targetId:appstate.target_id];
}

// ---------------------------------------------------------------------------------------
// userOwnsUserdata - return true if user is owner of userdata.
// ---------------------------------------------------------------------------------------
- (BOOL) userOwnsUserdata {
    TPUserData *userdata = [self getCurrentUserData];    
    if (userdata.user_id == appstate.user_id) {
        return YES;
    } else {
        return NO;
    }
}

// ---------------------------------------------------------------------------------------
// userCanEditUserdata - return true if user is owner, subject, or has record permission
// for subject.
// ---------------------------------------------------------------------------------------
- (BOOL) userCanEditUserdata {
    TPUserData *userdata = [self getCurrentUserData];
    TPUser *target = [self getCurrentTarget];
    if (appstate.user_id == userdata.user_id ||
        appstate.user_id == userdata.target_id ||
        (target.permission == TP_PERMISSION_VIEW_AND_RECORD || target.permission == TP_PERMISSION_RECORD)) {
        return YES;
    } else {
        return NO;
    }
}

// ---------------------------------------------------------------------------------------
// userCanEditFormHeading - return true if user is owner of userdata and has not signed.
// ---------------------------------------------------------------------------------------
- (BOOL) userCanEditFormHeading {
    TPUserData *userdata = [self getCurrentUserData];
    return userdata.user_id == appstate.user_id && !userHasSignedForm;
}

// ---------------------------------------------------------------------------------------
// userCanEditQuestion - return true if user has permission to edit question.
// ---------------------------------------------------------------------------------------
- (BOOL) userCanEditQuestion:(TPQuestion *)question {
        
    // Check that user can edit fuserdata
    if (!userCanEditCurrentUserdata) return NO;
    
    // Check for signature
    if (userHasSignedForm) return NO;
    
    // Check for uneditable question subtypes
    if (question.subtype == TP_QUESTION_SUBTYPE_READONLY ||
        question.subtype == TP_QUESTION_SUBTYPE_COMPUTED) return NO;
    
    // Otherwise check user type against question subtype
    if (question.subtype == TP_QUESTION_SUBTYPE_NORMAL && userFormPermission == TP_USER_FORM_PERMISSION_OWNER) return YES;
    if (question.subtype == TP_QUESTION_SUBTYPE_REFLECTION && userFormPermission == TP_USER_FORM_PERMISSION_SUBJECT) return YES;
    if (question.subtype == TP_QUESTION_SUBTYPE_THIRDPARTY && userFormPermission == TP_USER_FORM_PERMISSION_THIRDPARTY) return YES;
    
    return NO;
}

// ---------------------------------------------------------------------------------------
// DEPRICATED
// userCanEditQuestion - return true if user has permission to edit question.
// ---------------------------------------------------------------------------------------
- (BOOL) userCanEditQuestion:(BOOL)isReflection :(BOOL)isThirdParty {
    
    if (debugModel) NSLog(@"TPModel userCanEditQuestion");
    
	BOOL canEditReflections = FALSE, canEditNonReflections = FALSE, canEditThirdParty = FALSE;
    
	//TPUserData *userdata = [self getUserDataFromListById:appstate.userdata_id];
    TPUserData *userdata = [self getCurrentUserData];
	
	// Determine which type of questions user can edit (only one should be YES)
	canEditNonReflections = (appstate.user_id  == userdata.user_id);
	canEditReflections = (appstate.user_id  == userdata.target_id);
	canEditThirdParty = [self isThirdPartyUser];

	// Determine if user has already signed the form // WARNING - more efficient if this was cached when form chosen
	BOOL isSignedForCurrentReflectionState = FALSE;
	for (TPQuestion *question in question_list) {
		if (isThirdParty) {
            if ((TP_QUESTION_TYPE_SIGNATURE_RESTRICTED == question.type) && (TP_QUESTION_SUBTYPE_THIRDPARTY == question.subtype)) {
				isSignedForCurrentReflectionState = [[self questionText:question] length] && ![[self questionText:question] isEqualToString:@"(null)"];
			}
		} else {
            if (([question isQuestionReflection] == isReflection) && (question.type == TP_QUESTION_TYPE_SIGNATURE_RESTRICTED)) {
                isSignedForCurrentReflectionState = [[self questionText:question] length] && ![[self questionText:question] isEqualToString:@"(null)"];
            }
        }
	}
		
	// User cannot edit question if he already signed it
	if (isThirdParty) return (canEditThirdParty && !isSignedForCurrentReflectionState);
    if (isReflection) return (canEditReflections && !isSignedForCurrentReflectionState);
    return (canEditNonReflections &&!isSignedForCurrentReflectionState);
}

// ---------------------------------------------------------------------------------------
- (BOOL) isThirdPartyUser {
    
	TPUserData *userdata = [self getUserDataFromListById:appstate.userdata_id];
	return (appstate.user_id  != userdata.user_id) && (appstate.user_id  != userdata.target_id);		
	
}

- (BOOL) isRubricEditable:(int)rubric_id {
    return [[self getRubricById:rubric_id] isRubricEditable]; 
}

- (BOOL) isQuestionEditable:(int)question_id {
    return [[self getQuestionById:question_id] isQuestionEditable];
}

// ---------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------
- (NSDate *) dateFromCharStr:(char *)date_charstr {
    [self waitForLock:dateformatterLock]; // Use lock since NSDateFormatter is not thread safe
    NSDate *date = [dateFormatter dateFromString:[NSString stringWithFormat:@"%s", date_charstr]];
    [self freeLock:dateformatterLock];
    return date;
}

- (NSDate *) dateFromStr:(NSString *)date_str {
    [self waitForLock:dateformatterLock]; // Use lock since NSDateFormatter is not thread safe
    NSDate *date = [dateFormatter dateFromString:date_str];
    [self freeLock:dateformatterLock];
    return date;
}

- (NSString *) stringFromDate:(NSDate *)date {
    if (date == nil) return @"";
    [self waitForLock:dateformatterLock]; // Use lock since NSDateFormatter is not thread safe
	NSString *date_str = [NSString stringWithFormat:@"%s", [[dateFormatter stringFromDate:date] UTF8String]];
	[self freeLock:dateformatterLock];
	return date_str;
}

- (NSString *) prettyStringFromDate:(NSDate *)date {
    return [self prettyStringFromDate:date newline:FALSE];
}

- (NSString *) prettyStringFromDate:(NSDate *)date newline:(BOOL)newLine{
    
    NSString *separator;
    if (newLine) {
        separator = @"\n";
    } else {
        separator = @"  ";
    }
    [self waitForLock:dateformatterLock]; // Use lock since NSDateFormatter is not thread safe
	NSString *date_str = [NSString stringWithFormat:@"%s%@%s", [[prettyDateFormatter stringFromDate:date] UTF8String], separator, [[prettyTimeFormatter stringFromDate:date] UTF8String]];
	[self freeLock:dateformatterLock];
	return date_str;
}

// ---------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------
- (int) getUserArrayIndex:(TPUser *)target {
    int index = 0;
    for (TPUser *user in user_array) {
        if (user.user_id == target.user_id) return index;
        index++;
    }
    return -1;
}

- (int) getInfoArrayIndex:(TPUserInfo *)target {
    int index = 0;
    for (TPUserInfo *userinfo in info_array) {
        if (userinfo.user_id == target.user_id) return index;
        index++;
    }
    return -1;
}

- (void) deleteInfoForUserId:(int)user_id {
    int index = 0;
    int found = -1;
    for (TPUserInfo *userinfo in info_array) {
        if (userinfo.user_id == user_id) {
            found = index;
            break;
        }
        index++;
    }
    if (found >= 0) {
        [info_array removeObjectAtIndex:index];
    }
}

- (int) getCategoryArrayIndex:(TPCategory *)target {
    int index = 0;
    for (TPCategory *category in category_array) {
        if (category.category_id == target.category_id) return index;
        index++;
    }
    return -1;
}

- (TPCategory *) getCategoryById:(int)category_id {
    for (TPCategory *category in category_array) {
        if (category.category_id == category_id) return category;
    }
    return nil;
}

- (int) getRubricArrayIndex:(TPRubric *)target {
    int index = 0;
    for (TPRubric *rubric in rubric_array) {
        if (rubric.rubric_id == target.rubric_id) return index;
        index++;
    }
    return -1;
}

- (int) getQuestionArrayIndex:(TPQuestion *)target {
    int index = 0;
    for (TPQuestion *question in question_array) {
        if (question.question_id == target.question_id) return index;
        index++;
    }
    return -1;
}
  
- (TPQuestion *) getQuestionById:(int)question_id {
    for (TPQuestion *question in question_array) {
        if (question.question_id == question_id) return question;
    }
    return nil;
}

- (int) getRatingArrayIndex:(TPRating *)target {
    int index = 0;
    for (TPRating *rating in rating_array) {
        if (rating.rating_id == target.rating_id) return index;
        index++;
    }
    return -1;
}

// ---------------------------------------------------------------------------------------
- (int) getSyncType {
    return sync_type;
}

// ---------------------------------------------------------------------------------------
- (void) setUILock {
    if (debugLock) NSLog(@"**** setUILock");
    appstate.lock = 1;
}

// ---------------------------------------------------------------------------------------
- (void) clearUILock {
    if (debugLock) NSLog(@"**** clearUILock");
    appstate.lock = 0;
}

// ---------------------------------------------------------------------------------------
- (BOOL) isSetUILock {
    if (debugLock) NSLog(@"**** isSetUILock %d", appstate.lock);
    return appstate.lock == 1;
}

// ---------------------------------------------------------------------------------------
- (void) waitForUILock {
    if (debugLock) NSLog(@"**** waitForUILock WAIT");
    while (appstate.lock == 1) {
        usleep(1000);
    }
    if (debugLock) NSLog(@"**** waitForUILock GO");
}


// ---------------------------------------------------------------------------------------
- (void) waitForLock:(NSLock *)someLock {
    if (debugLock) NSLog(@"**** waitForLock WAIT");
    while ([someLock tryLock] == NO) {
        usleep(1000);
    }
    if (debugLock) NSLog(@"**** waitForLock GO");
}

// ---------------------------------------------------------------------------------------
- (BOOL) tryLock:(NSLock *)someLock {
    BOOL result = [someLock tryLock];
    if (debugLock) NSLog(@"**** tryLock %d", result);
    return result;
}

// ---------------------------------------------------------------------------------------
- (void) freeLock:(NSLock *)someLock {
    if (debugLock) NSLog(@"**** freeLock");
    [someLock unlock];
}


// ---------------------------------------------------------------------------------------
- (void) resetAllLocks {
    
    if (debugLock) NSLog(@"**** resetAllLocks");
    
    appstate.lock = 0;
    
    if (uiSyncLock != nil) [uiSyncLock release];
    uiSyncLock = [[NSLock alloc] init];
}

//jxi; -------------------------- Methods for UserData Advanced Sync ---------------------
//jxi; get User by UserId
- (TPUser *) getUserByUserId:(int) user_id {
    
    for (TPUser *user in user_array) {
        
        if (user.user_id == user_id)
            return user;
        
    }
    return nil;
}


@end
