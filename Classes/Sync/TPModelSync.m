#import <sqlite3.h>
#import <CFNetwork/CFNetwork.h>
#import <CFNetwork/CFHTTPStream.h>
#import <Foundation/Foundation.h>
#import "TPData.h"
#import "TPDatabase.h"
#import "TPModel.h"
#import "TPUtil.h"
#import "TPCompat.h"
#import "TPView.h"
#import "TPModelSync.h"
#import "TPSyncHandlerOp.h"
#import "TPSyncManager.h"
#import "TPRubricList.h"

#define USERDATA_AMOUNT_TO_BATCH_PROCESS     20

// ---------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------
@implementation TPModel (Sync)

- (void) syncinit {
    if (debugSyncControl) NSLog(@"TPModelSync syncinit");
	sync_type = SYNC_TYPE_UNKNOWN;       // No valid sync
	sync_type_start = SYNC_TYPE_UNKNOWN; // No valid sync
    [sync_data_id release];
	sync_data_id = nil;                  // Initialize flag as no data to sync
    logoutAfterSync = NO;                // Normal (don't logout after sync)
	syncStatusDelegate = nil;			 // Delegate and selector for passing sync status 
	syncStatusSelector = nil;			 // for displaying progress in sync popover
    userdata_unprocessed_count = 0;
    syncInitiator = SYNC_INITIATOR_SYNCMGR;
}

// ---------------------------------------------------------------------------------------
// updateLastSync - effectively restarts syncing (next sync will be after sync interval)
// ---------------------------------------------------------------------------------------
- (void) updateLastSync {
    if (debugSyncControl) NSLog(@"TPModelSync updateLastSync");
    syncInitiator = SYNC_INITIATOR_SYNCMGR;
    if (publicstate.is_demo == 1 || [publicstate.state isEqualToString:@"install"]) return; // Prevent demo or install state from auto syncing
    appstate.last_sync_completed = [NSDate date];
    appstate.last_sync = appstate.last_sync_completed;
    if (debugSyncControl) NSLog(@"TPModelSync updateLastSync %@", [self stringFromDate:appstate.last_sync_completed]);
}

// ---------------------------------------------------------------------------------------
// immediateSync - effectively forces immediate sync
// ---------------------------------------------------------------------------------------
- (void) immediateSync {
    if (debugSyncControl) NSLog(@"TPModelSync immediateSync");
    syncInitiator = SYNC_INITIATOR_USER;
    appstate.last_sync = [NSDate distantPast];
    [syncMgr.timer fire];
}

// ---------------------------------------------------------------------------------------
// Suspends syncing
// ---------------------------------------------------------------------------------------
- (void) suspendSyncing {
    if (debugSyncControl) NSLog(@"TPModelSync suspendSyncing");
    appstate.last_sync = nil;
}

// ---------------------------------------------------------------------------------------
// Restarts syncing
// ---------------------------------------------------------------------------------------
- (void) restartSyncing {
    if (debugSyncControl) NSLog(@"TPModelSync restartSyncing");
    syncInitiator = SYNC_INITIATOR_SYNCMGR;
    if (publicstate.is_demo == 1 || [publicstate.state isEqualToString:@"install"]) return; // Prevent demo or install state from auto syncing
    appstate.last_sync = appstate.last_sync_completed;
}

// ---------------------------------------------------------------------------------------
//
// ---------------------------------------------------------------------------------------
- (BOOL) syncIsSupended {
    if (debugSyncControl) NSLog(@"TPModelSync syncIsSupended");
    return appstate.last_sync == nil;
}

// ---------------------------------------------------------------------------------------
// cancelSync - cancel NSURL connection, thread operations, active sync process
// ---------------------------------------------------------------------------------------
- (void) cancelSync {
    
    if (debugSyncControl) NSLog(@"TPModelSync cancelSync");
    
    // Cancel sync operations and wait for queue to be clear (operations have exited)
    [sync_queue cancelAllOperations];
    // Wait up to 2 seconds for queue to empty
    int wait_iter = 0;
    while ([sync_queue operationCount] > 0 && wait_iter < 15) {
        if (debugSyncControl) NSLog(@"  Waiting for operation queue to empty");
        usleep(100000);
        wait_iter++;
    }
    
    // Release connection
    if (page_connection != nil) {
        [page_connection cancel];
        [page_connection release];
        page_connection = nil;
    }
    
    // Hide network activity indicator
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    // Reset sync status
    if ([publicstate.state isEqualToString:@"install"]) {
        [self setNeedSyncStatus:NEEDSYNC_STATUS_SYNCED forced:YES];
    } else {
        if (sync_complete) {
            if ([self getUnsyncedCount] > 0) {
                [self setNeedSyncStatus:NEEDSYNC_STATUS_NOTSYNCED forced:YES];
            } else {
                [self setNeedSyncStatus:NEEDSYNC_STATUS_SYNCED forced:YES];
            }
        } else {
            [self setNeedSyncStatus:NEEDSYNC_STATUS_NOTSYNCED forced:YES];
        }
    };
    [view clearSyncPopupStatus:YES];
    
    // Clear lock and reset data counter
    userdata_unprocessed_count = 0;
    
    // Enable syncing but after normal wait period
    [self updateLastSync];
}

// ---------------------------------------------------------------------------------------
// getLastSync - return last sync time
// ---------------------------------------------------------------------------------------
- (NSDate *) getLastSync {
    return appstate.last_sync;
}

// ---------------------------------------------------------------------------------------
// getUserDataUnsyncedCount - return count of userdata needing syncing
// ---------------------------------------------------------------------------------------
- (int) getUserDataUnsyncedCount {
    return [database getUserDataUnsyncedCount];
}

// ---------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------
- (void) registerSyncStatusCallback:(id)delegate :(SEL)selector {
    //NSLog(@"registerSyncStatusCallback %d", (int)delegate);
	syncStatusDelegate = delegate;
	syncStatusSelector = selector;
}

- (void) unregisterSyncStatusCallback {
    //NSLog(@"unregisterSyncStatusCallback");
	syncStatusDelegate = NULL;
	syncStatusSelector = NULL;
}

// ---------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------
- (void) updateSyncStatus:(int) status {
	if(syncStatusDelegate && syncStatusSelector) {
		NSMethodSignature* sig = [[syncStatusDelegate class] instanceMethodSignatureForSelector:syncStatusSelector];
		NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:sig];
		[invocation setTarget:syncStatusDelegate];
		[invocation setSelector:syncStatusSelector];
		[invocation setArgument:&status atIndex:2];
		[invocation invoke];
	}
}

// ---------------------------------------------------------------------------------------
// syncEncode - encode XML reserved characters. For use with text between XML tags.
// ---------------------------------------------------------------------------------------
- (NSString *) syncEncode:(NSString *)rawstring {
	NSString *cookedstring = [[[rawstring stringByReplacingOccurrencesOfString:@"<" withString:@"%3c"]
							   stringByReplacingOccurrencesOfString:@">" withString:@"%3e"]
							  stringByReplacingOccurrencesOfString:@"&" withString:@"%26"];
	return cookedstring;
}

// ---------------------------------------------------------------------------------------
// syncDecode - decode XML reserved characters. For use with text between XML tags.
// ---------------------------------------------------------------------------------------
- (NSString *) syncDecode:(NSString *)rawstring {
	NSString *cookedstring = [[[rawstring stringByReplacingOccurrencesOfString:@"%3c" withString:@"<"]
							   stringByReplacingOccurrencesOfString:@"%3e" withString:@">"]
							  stringByReplacingOccurrencesOfString:@"%26" withString:@"&"];
	return cookedstring;
}

// --------------------------------------------------------------------------------------
// postRequestEncode - encode URI reserved characters, and use hex encoding for spaces.
// --------------------------------------------------------------------------------------
- (NSString *) postRequestEncode:(NSString *)input {
    return [[[input stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]
             stringByReplacingOccurrencesOfString:@"+" withString:@"%2B"]
            stringByReplacingOccurrencesOfString:@"&" withString:@"%26"];
}

// ---------------------------------------------------------------------------------------
// Called by view (main thread)
// ---------------------------------------------------------------------------------------
- (void) doSync:(int)syncType {
    
    if (debugSync) NSLog(@"TPModelSync doSync %d", syncType);
        
	// Setup https request
	sync_type = syncType;
	sync_type_start = syncType;
    sync_complete = 0;
	
	// updating sync status and prevent sync manager from another sync until done
	[self updateSyncStatus: syncType];
    [self suspendSyncing];

    if (syncType == SYNC_TYPE_USER && self.isApplicationFirstTimeSync) {
        [self markAllUsersAsUnsynced];
        [self.view reloadUserList]; 
    }
    
    // Create URL
	NSString *webserver = [[NSUserDefaults standardUserDefaults] stringForKey:@"webserver"];
    NSString *urlString;
    switch (syncType) {
        case SYNC_TYPE_USER:
            urlString = [NSString stringWithFormat:@"%@ipad/syncusers", webserver];
            sync_data_id = nil;
            break;
        case SYNC_TYPE_INFO:
            urlString = [NSString stringWithFormat:@"%@ipad/syncinfo", webserver];
            sync_data_id = nil;
            break;
        case SYNC_TYPE_CATEGORY:
            urlString = [NSString stringWithFormat:@"%@ipad/synccategories", webserver];
            sync_data_id = nil;
            break;
        case SYNC_TYPE_RUBRIC:
            urlString = [NSString stringWithFormat:@"%@ipad/syncrubrics", webserver];
            sync_data_id = nil;
            break;
        case SYNC_TYPE_CLIENTDATA:
            urlString = [NSString stringWithFormat:@"%@ipad/syncdata", webserver];
            [sync_data_id release];
            sync_data_id = [[NSString alloc] initWithString:[userdata_queue lastObject]];
            if (sync_data_id == nil) { return; }
            [userdata_queue removeLastObject];
            if (debugSync) NSLog(@"SYNC sending user data: %@", sync_data_id);
            break;
        case SYNC_TYPE_CLIENTIMAGE:
            urlString = [NSString stringWithFormat:@"%@ipad/syncdata", webserver];
            [sync_data_id release];
            sync_data_id = [[NSString alloc] initWithString:[localimages_queue lastObject]];
            if (sync_data_id == nil) { return; }
            [localimages_queue removeLastObject];
            if (debugSync) NSLog(@"SYNC sending local image: %@", sync_data_id);
            break;
        case SYNC_TYPE_CLIENTVIDEO: //jxi;
            urlString = [NSString stringWithFormat:@"%@ipad/syncdata", webserver];
            [sync_data_id release];
            sync_data_id = [[NSString alloc] initWithString:[localvideos_queue lastObject]];
            if (sync_data_id == nil) { return; }
            [localvideos_queue removeLastObject];
            if (debugSync) NSLog(@"SYNC sending local video: %@", sync_data_id);
            break;
        case SYNC_TYPE_DATA:
            urlString = [NSString stringWithFormat:@"%@ipad/syncuserdata", webserver];
            sync_data_id = nil;
            break;
        case SYNC_TYPE_IMAGEDATA:
            urlString = [NSString stringWithFormat:@"%@ipad/syncimage", webserver];
            [sync_data_id release];
            sync_data_id = [[NSString alloc] initWithString:remoteImageIDToSync];
            if (sync_data_id == nil) { return; }
            if (debugSync) NSLog(@"SYNC sending remote image: %@", sync_data_id);
            break;
        case SYNC_TYPE_VIDEODATA: //jxi;
            urlString = [NSString stringWithFormat:@"%@ipad/syncvideo", webserver];
            [sync_data_id release];
            sync_data_id = [[NSString alloc] initWithString:remoteVideoIDToSync];
            if (sync_data_id == nil) { return; }
            if (debugSync) NSLog(@"SYNC sending remote video: %@", sync_data_id);
            break;
        //jxi; On-Demand syncing for form with nodata state
        case SYNC_TYPE_FORMDATA:
            urlString = [NSString stringWithFormat:@"%@ipad/syncuserdatarecord", webserver];
            [sync_data_id release];
            sync_data_id = [[NSString alloc] initWithString:remoteFormIDToSync];
            if (sync_data_id == nil) { return; }
            if (debugSync) NSLog(@"SYNC sending remote form: %@", sync_data_id);
            break;
        default:
            return;
    }
	NSURL *url = [NSURL URLWithString:urlString];
    
    // Get device and user info
    NSString *udid = [self postRequestEncode:[TPCompat getUdid]];
    NSString *dversion =[self postRequestEncode:[[UIDevice currentDevice] systemVersion]];
    NSString *dmodel = [self postRequestEncode:[[UIDevice currentDevice] model]];
    NSString *dsysname = [self postRequestEncode:[[UIDevice currentDevice] systemName]];
    NSString *dname = [self postRequestEncode:[[UIDevice currentDevice] name]];
    NSString *districtlogin = [self postRequestEncode:[NSString stringWithString:appstate.districtlogin]];
	NSString *login = [self postRequestEncode:[NSString stringWithString:appstate.login]];
	NSString *password = [NSString stringWithString:publicstate.hashed_password];
	NSString *version = [self postRequestEncode:[[NSUserDefaults standardUserDefaults] stringForKey:@"version"]];
    
    // Create common URI values
    NSString *basicValues = [NSString stringWithFormat:@"udid=%@&dversion=%@&dmodel=%@&dsysname=%@&dname=%@&district=%@&login=%@&password=%@&version=%@",
                                udid, dversion, dmodel, dsysname, dname, districtlogin, login, password, version];
    
    // Create POST request
    NSString *requestStr;
    NSString *upload_xml;
    NSString* upload_xml_for_userlist; //jxi; used in SYNC_TYPE_DATA
    switch (syncType) {
        case SYNC_TYPE_USER:
            if (debugSync) NSLog(@"TPModelSync isFirstSyncAfterUpgrade=%d", (int)isFirstSyncAfterUpgrade);
            if (debugSync) NSLog(@"TPModelSync SYNC_TYPE_USER");
            upload_xml = [self getUserListXMLEncoding]; // Encode list of users
            requestStr = [NSString stringWithFormat:@"%@&firstsyncafterupgrade=%d&userlist=%@",
                          basicValues, isFirstSyncAfterUpgrade, upload_xml];
            break;
        case SYNC_TYPE_INFO:
            if (debugSync) NSLog(@"TPModelSync SYNC_TYPE_INFO");
            upload_xml = [self getInfoListXMLEncoding]; // Encode list of users
            requestStr = [NSString stringWithFormat:@"%@&firstsyncafterupgrade=%d&infolist=%@",
                          basicValues, isFirstSyncAfterUpgrade, upload_xml];
            break;
        case SYNC_TYPE_CATEGORY:
            if (debugSync) NSLog(@"TPModelSync SYNC_TYPE_CATEGORY");
            upload_xml = [self getCategoryListXMLEncoding]; // Encode list of categories
            requestStr = [NSString stringWithFormat:@"%@&firstsyncafterupgrade=%d&categorylist=%@",
                          basicValues, isFirstSyncAfterUpgrade, upload_xml];
            break;
        case SYNC_TYPE_RUBRIC:
            if (debugSync) NSLog(@"TPModelSync SYNC_TYPE_RUBRIC");
            if ([self.view.model.currentMainViewState isEqualToString:@"rubric"]  ) {
                [self.view rubricCaptureCurrentState];
            }
            upload_xml = [self getRubricListXMLEncoding]; // Encode list of rubrics
            requestStr = [NSString stringWithFormat:@"%@&firstsyncafterupgrade=%d&rubriclist=%@",
                          basicValues, isFirstSyncAfterUpgrade, upload_xml];
            break;
        case SYNC_TYPE_CLIENTDATA:
            if (debugSync) NSLog(@"TPModelSync SYNC_TYPE_CLIENTDATA %@", sync_data_id);
            upload_xml = [self postRequestEncode:[database getUserDataXMLEncoding:sync_data_id]]; // Encode a single user data object
            requestStr = [NSString stringWithFormat:@"%@&firstsyncafterupgrade=%d&data=%@",
                          basicValues, isFirstSyncAfterUpgrade, upload_xml];
            if (debugSyncDetail) NSLog(@"TPModelSync CLIENTSYNC upload_xml=%@",upload_xml);
            break;
        case SYNC_TYPE_CLIENTIMAGE:
            if (debugSync) NSLog(@"TPModelSync SYNC_TYPE_CLIENTIMAGE %@", sync_data_id);
            upload_xml = [self postRequestEncode:[database getLocalImageXMLEncoding:sync_data_id]]; // Encode a single image object
            requestStr = [NSString stringWithFormat:@"%@&firstsyncafterupgrade=%d&data=%@",
                          basicValues, isFirstSyncAfterUpgrade, upload_xml];
            if (debugSyncDetail) NSLog(@"TPModelSync CLIENTIMAGESYNC upload_xml=%@",upload_xml);
            break;
        case SYNC_TYPE_CLIENTVIDEO: //jxi;
            if (debugSync) NSLog(@"TPModelSync SYNC_TYPE_CLIENTVIDEO %@", sync_data_id);
            upload_xml = [self postRequestEncode:[database getLocalVideoInfoXMLEncoding:sync_data_id]];
            requestStr = [NSString stringWithFormat:@"%@&firstsyncafterupgrade=%d&data=%@",
                          basicValues, isFirstSyncAfterUpgrade, upload_xml];
            if (debugSyncDetail) NSLog(@"TPModelSync CLIENTVIDEOSYNC upload_xml=%@",upload_xml);
            break;
        case SYNC_TYPE_DATA:
            if (debugSync) NSLog(@"TPModelSync SYNC_TYPE_DATA");
            
            //jxi; Advance syncing for userdata_sync_step
            if (userdata_sync_step == USERDATA_SYNC_STEP_UNKNOWN) {
                // if the sync step is set to unknown, then set it up in the first step of the userdata sync step
                userdata_sync_step = USERDATA_SYNC_STEP_USER_CURRENT;
                userdata_sync_current_target_id = appstate.target_id;
            }
            
            //jxi; Advance syncing for userdata_sync_step
            // Store the userids for the current sync step
            NSMutableString* strUserIdList = [NSMutableString stringWithString:@""]; //"(userid, userid,...)";
            upload_xml_for_userlist = [self getUserListXMLEncodingForUserDataSync:strUserIdList]; // Encode list of users for current userdata_sync_step
            upload_xml = [database getUserDataListXMLEncodingForUserDataSync:strUserIdList]; // Encode list of user data objects for the above users
            requestStr = [NSString stringWithFormat:@"%@&firstsyncafterupgrade=%d&userdatalist=%@&userlist=%@",
                          basicValues, isFirstSyncAfterUpgrade, upload_xml, upload_xml_for_userlist];
            break;
        case SYNC_TYPE_IMAGEDATA:
            if (debugSync) NSLog(@"TPModelSync SYNC_TYPE_IMAGEDATA");
            requestStr = [NSString stringWithFormat:@"%@&userdataid=%@",
                          basicValues, sync_data_id];
            if (debugSyncDetail) NSLog(@"TPModelSync SERVERIMAGESYNC upload_xml=%@", requestStr);
            break;
        case SYNC_TYPE_VIDEODATA: //jxi;
            if (debugSync) NSLog(@"TPModelSync SYNC_TYPE_VIDEODATA");
            requestStr = [NSString stringWithFormat:@"%@&userdataid=%@",
                          basicValues, sync_data_id];
            if (debugSyncDetail) NSLog(@"TPModelSync SERVERVIDEOSYNC upload_xml=%@", requestStr);
            break;
        //jxi; On-Demand syncing for form with nodata state
        case SYNC_TYPE_FORMDATA:
            if (debugSync) NSLog(@"TPModelSync SYNC_TYPE_FORMDATA");
            requestStr = [NSString stringWithFormat:@"%@&userdataid=%@",
                          basicValues, sync_data_id];
            if (debugSyncDetail) NSLog(@"TPModelSync SERVERFORMDATASYNC upload_xml=%@", requestStr);
            break;
        default:
            return;
    }
    //NSLog(@"HTTP request string is %@", requestStr);
    NSData *requestData = [NSData dataWithBytes:[requestStr UTF8String] length:[requestStr length]];
	NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:url];
	[urlRequest setHTTPMethod:@"POST"];
	[urlRequest setHTTPBody:requestData];
	[urlRequest setCachePolicy:NSURLRequestReturnCacheDataElseLoad];
	[urlRequest setTimeoutInterval:30];
    
    // Send POST
	[page_results setLength:0];
    page_connection = [[NSURLConnection alloc]
                       initWithRequest:urlRequest
                       delegate:self];
	[urlRequest release];
    
    // Check conenction
	if (!page_connection) {
        NSLog(@"ERROR: in URL connection setup");
        
    } else {
        // Show network activity indicator
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    }
}

// ---------------------------------------------------------------------------------------
// clientDataSyncPrep - Create array of userdata IDs to use with data sync. Call this once
// before syncing the unsynced user data.
// ---------------------------------------------------------------------------------------
- (void) clientDataSyncPrep {
    if (debugSync) NSLog(@"TPModelSync clientDataSyncPrep");
    // IMPORTANT - must send open form - if new and not sent then it would be deleted from incoming userdata sync flag
    //[database getUserDataUnsyncedDataList:userdata_queue localImagesList:localimages_queue includeCurrentUserdata:YES];
    [database getUserDataUnsyncedDataList:userdata_queue localImagesList:localimages_queue localVideosList:localvideos_queue includeCurrentUserdata:YES]; //jxi;

    if (debugSync) NSLog(@"TPModelSync clientDataSyncPrep found %d userdata", [userdata_queue count]);
}

// ---------------------------------------------------------------------------------------
// getUnsyncedCount - returns the number of unsynced userdata items.
// ---------------------------------------------------------------------------------------
- (int) getUnsyncedCount {
    if (debugSync) NSLog(@"TPModelSync getUnsyncedCount");
    int count = [database getUserDataUnsyncedCount];
    if (count != 0 && [self needSyncStatus] != NEEDSYNC_STATUS_SYNCING) {
        [self setNeedSyncStatus:NEEDSYNC_STATUS_NOTSYNCED forced:NO];
    }
	return count;
}

// ---------------------------------------------------------------------------------------
// getUnprocessedCount - returns the number of items not added to database.
// ---------------------------------------------------------------------------------------
- (int) getUnprocessedCount {
    if (debugSync) NSLog(@"TPModelSync getUnprocessedCount");
	//return [database getUserDataUnsyncedCount];
    return userdata_unprocessed_count;
}

// ---------------------------------------------------------------------------------------
// syncDataIsComplete - checks that returned sync data is complete.  If bad web server
// this will catch bad page data being returned.
// ---------------------------------------------------------------------------------------
- (BOOL) syncDataIsComplete:(NSMutableData *)data {
    if (debugSync) NSLog(@"TPModelSync syncDataIsComplete");
    NSString *pagestring = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
    if (((NSRange)[pagestring rangeOfString:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>"]).location != NSNotFound &&
        ((NSRange)[pagestring rangeOfString:@"<root>"]).location != NSNotFound &&
        ((NSRange)[pagestring rangeOfString:@"</root>"]).location != NSNotFound) {
        return YES;
    } else {
        return NO;
    }
}

// ---------------------------------------------------------------------------------------
// Database's savepoints operations
// ---------------------------------------------------------------------------------------
- (void) setDatabaseSavepointWithName:(NSString*) savepointName {
    [self.database setSavepointWithName:savepointName];
}

// --------------------------------------------------------------------------------------
- (void) releaseDatabaseSavepointWithName:(NSString*) savepointName {
    [self.database releaseSavepointWithName:savepointName];
}

// --------------------------------------------------------------------------------------
- (void) rollbackToDatabaseSavepointWithName:(NSString*) savepointName {
    [self.database rollbackToSavepointWithName:savepointName];
    [self.database releaseSavepointWithName:savepointName];
}

// ============================= Connection Handling =====================================

// ---------------------------------------------------------------------------------------
- (BOOL)connectionShouldUseCredentialStorage:(NSURLConnection *)connection {
    if (debugSyncConn) NSLog(@"TPModelSync connectionShouldUseCredentialStorage");
    return YES;
}

// --------------------------------------------------------------------------------------
- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    if (debugSyncConn) NSLog(@"TPModelSync didReceiveAuthenticationChallenge");
}

// --------------------------------------------------------------------------------------
- (void)connection:(NSURLConnection *)connection didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    if (debugSyncConn) NSLog(@"TPModelSync didCancelAuthenticationChallenge");
}

// --------------------------------------------------------------------------------------
- (NSCachedURLResponse *) connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse {
	if (debugSyncConn) NSLog(@"TPModelSync willCacheResponse");
	return nil;
}

// --------------------------------------------------------------------------------------
- (void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	if (debugSyncConn) NSLog(@"TPModelSync didReceiveResponse");
    if ([response respondsToSelector:@selector(statusCode)]) {
        conn_status = [(NSHTTPURLResponse *)response statusCode];
    } else {
        conn_status = 0;
    }
}

// --------------------------------------------------------------------------------------
- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	if (debugSyncConn) NSLog(@"TPModelSync didReceiveData");
	[page_results appendData:data];
}

// --------------------------------------------------------------------------------------
- (void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	
	if (debugSyncConn) NSLog(@"TPModelSync didFailWithError %d %d %d", [error code], self.appstate.user_id, self.syncInitiator);
	
    // Hide network activity indicator
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    // Handle error by issuing messages
    switch ([error code]) {
        case NSURLErrorCannotConnectToHost:
        case NSURLErrorNotConnectedToInternet:
        case NSURLErrorNetworkConnectionLost:
            if (self.appstate.user_id != 0) [self updateSyncStatus:SYNC_ERROR_WIFI];
            if (self.appstate.user_id == 0 || self.syncInitiator == SYNC_INITIATOR_USER) {
                [view generalAlert:@"Network Error" message:@"\nPlease check your WiFi connection.\n\n" poptostart:0];
            }
            break;
        case NSURLErrorTimedOut:
            if (self.appstate.user_id != 0) [self updateSyncStatus:SYNC_ERROR_TIMEOUT];
            if (self.appstate.user_id == 0 || self.syncInitiator == SYNC_INITIATOR_USER) {
                [view generalAlert:@"Sync Timeout" message:@"\nNo response from server. Please check your settings.\n\n" poptostart:0];
            }
            break;
        default:
            if (self.appstate.user_id != 0) [self updateSyncStatus:SYNC_ERROR_GENERAL];
            if (self.appstate.user_id == 0 || self.syncInitiator == SYNC_INITIATOR_USER) {
                [view generalAlert:@"Sync Error" message:@"\nUnknown error while contacting server.\n\n" poptostart:0];
            }
            break;
    }
    
    // Clean up
    if (self.appstate.user_id == 0) {
        [view returnToLoginScreen];
    } else {
        [self cancelSync];
    }
        
	// Release connection
	if (page_connection != nil) [page_connection release];
    page_connection = nil;
}

// --------------------------------------------------------------------------------------
// connectionDidFinishLoading - if HTTP succeeds then handle data returned (main thread)
// --------------------------------------------------------------------------------------
- (void) connectionDidFinishLoading:(NSURLConnection *)connection {
	
	if (debugSyncConn) NSLog(@"TPModelSync connectionDidFinishLoading %d", conn_status);
			
    // Hide network activity indicator
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    // Check is sync data is complete
    BOOL isSyncComplete = [self syncDataIsComplete:page_results];
    if (isSyncComplete) {
        // If sync data complete then handle via operation on separate thread
        TPSyncHandlerOp *synchandler = [[TPSyncHandlerOp alloc] initWithData:self delegate:self];
        [sync_queue addOperation:synchandler];
        [synchandler release];
    } else {
        if (debugSyncDetail) {
            NSString *pagestring = [[[NSString alloc] initWithData:page_results encoding:NSUTF8StringEncoding] autorelease]; 
            NSLog(@"parse data length %d", [page_results length]);
            NSLog(@"parse string length %d", [pagestring length]);
            NSLog(@"parse string is:\n%@", pagestring);
        }
        // If sync data not complete then show error alert
        if (conn_status == 0) {
          [self handleSyncError:@"Sync has incomplete data"];
        } else {
            [self handleSyncError:[NSString stringWithFormat:@"HTTP response (%d)", conn_status]];
        }
    }
	
    // Release connection
	if (page_connection != nil) [page_connection release];
    page_connection = nil;
}

// ------------------------------------------------------------------------------------
// getUserListXMLEncoding - return XML encoding of known users
// ------------------------------------------------------------------------------------
- (NSString *) getUserListXMLEncoding {
        
	NSMutableString *content = [NSMutableString stringWithString:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>"];
    
	// Encode users
    [content appendFormat:@"\n<objectlist>"];
    for (TPUser *user in user_array) {
        [content appendFormat:@"\n<object id=\"%d\" flag=\"%d\" idstr=\"0\">%@</object>", user.user_id, user.permission, [self stringFromDate:user.modified]];
    }
    [content appendFormat:@"\n</objectlist>"];
    
	return content;
}

// ------------------------------------------------------------------------------------
// jxi; getUserListXMLEncoding for SYNC_TYPE_DATA - return XML encoding of user or
// users for current userdata_sync_step
// ------------------------------------------------------------------------------------
- (NSString *) getUserListXMLEncodingForUserDataSync:(NSMutableString*)strUserIdList {
    
    if (debugSyncConn) NSLog(@"TPModelSync getUserListXMLEncodingForUserDataSync");
    
	NSMutableString *content = [NSMutableString stringWithString:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>"];
    
    [strUserIdList appendString:@"("];
    int i = 0;
    
    TPUser* targetUser = [self getUserByUserId:userdata_sync_current_target_id];
    
    // Encode users
    [content appendFormat:@"\n<objectlist>"];
    for (TPUser *user in user_array) {
        
        if (userdata_sync_step == USERDATA_SYNC_STEP_USER_CURRENT &&
            user.user_id == userdata_sync_current_target_id) {
            // add the current user info into the xml
            [content appendFormat:@"\n<object id=\"%d\" flag=\"%d\" idstr=\"0\">%@</object>", user.user_id, user.permission, [self stringFromDate:user.modified]];
            [strUserIdList appendFormat:@"%d", user.user_id];
            break;
            
        } else if (userdata_sync_step == USERDATA_SYNC_STEP_USERS_IN_SAME_SCHOOL &&
            user.school_id == targetUser.school_id && user.user_id != targetUser.user_id) {
            // add the users info in the same school as current user
            [content appendFormat:@"\n<object id=\"%d\" flag=\"%d\" idstr=\"0\">%@</object>", user.user_id, user.permission, [self stringFromDate:user.modified]];
            
            if (i == 0)
                [strUserIdList appendFormat:@"%d", user.user_id];
            else
                [strUserIdList appendFormat:@",%d", user.user_id];
            
            i++;
            
        } else if (userdata_sync_step == USERDATA_SYNC_STEP_USERS_ALL &&
            user.school_id != targetUser.school_id) {
            // add the all the remaining users info
            [content appendFormat:@"\n<object id=\"%d\" flag=\"%d\" idstr=\"0\">%@</object>", user.user_id, user.permission, [self stringFromDate:user.modified]];
            
            if (i == 0)
                [strUserIdList appendFormat:@"%d", user.user_id];
            else
                [strUserIdList appendFormat:@",%d", user.user_id];
            
            i++;
            
        }
    
    }
    [content appendFormat:@"\n</objectlist>"];
    [strUserIdList appendString:@")"];
    
	return content;
}

// ------------------------------------------------------------------------------------
// getInfoListXMLEncoding - return XML encoding of known user info
// ------------------------------------------------------------------------------------
- (NSString *) getInfoListXMLEncoding {
    
	NSMutableString *content = [NSMutableString stringWithString:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>"];
    
	// Encode users
    [content appendFormat:@"\n<objectlist>"];
    for (TPUserInfo *userinfo in info_array) {
        [content appendFormat:@"\n<object id=\"%d\" flag=\"0\" idstr=\"0\">%@</object>", userinfo.user_id, [self stringFromDate:userinfo.modified]];
    }
    [content appendFormat:@"\n</objectlist>"];
    
	return content;
}

// ------------------------------------------------------------------------------------
// getCategoryListXMLEncoding - return XML encoding of known categories
// ------------------------------------------------------------------------------------
- (NSString *) getCategoryListXMLEncoding {
    
	NSMutableString *content = [NSMutableString stringWithString:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>"];
    
	// Encode users
    [content appendFormat:@"\n<objectlist>"];
    for (TPCategory *category in category_array) {
        [content appendFormat:@"\n<object id=\"%d\" flag=\"0\" idstr=\"0\">%@</object>", category.category_id, [self stringFromDate:category.modified]];
    }
    [content appendFormat:@"\n</objectlist>"];
    
	return content;
}

// ------------------------------------------------------------------------------------
// getRubricListXMLEncoding - return XML encoding of known rubrics
// ------------------------------------------------------------------------------------
- (NSString *) getRubricListXMLEncoding {
    
	NSMutableString *content = [NSMutableString stringWithString:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>"];
    
	// Encode rubrics
    [content appendFormat:@"\n<objectlist>"];
    for (TPRubric *rubric in rubric_array) {
        [content appendFormat:@"\n<object id=\"%d\" flag=\"%d\" idstr=\"0\">%@</object>", rubric.rubric_id, rubric.state, [self stringFromDate:rubric.modified]];
    }
    [content appendFormat:@"\n</objectlist>"];
    
	return content;
}

// ------------------------------------------------------------------------------------
// handleUserSyncData - handle user sync data. Add new user objects and delete users
// flagged for deletion (sync thread)
// ------------------------------------------------------------------------------------
- (void) handleUserSyncData {
    
    int index;
    
    // Loop over sync data
    for (TPUser *newuser in tmp_user_array) {
        
        // If user has delete flag then delete
        if (newuser.state == 0) {
            index = [self getUserArrayIndex:newuser];
            [user_array removeObjectAtIndex:index];
            [self deleteInfoForUserId:newuser.user_id];
            
        } else {
            // Check is object is found and update or insert
            index = [self getUserArrayIndex:newuser];
            if (index == -1) {
                [user_array addObject:newuser];
            } else {
                [user_array replaceObjectAtIndex:index withObject:newuser];
            }
        }
    }
    
    // Clear data in temp array
    [tmp_user_array removeAllObjects];
}

// ------------------------------------------------------------------------------------
// Handle user info sync data, add new user info
// ------------------------------------------------------------------------------------
- (void) handleUserInfoSyncData {
    
    int index;
    
    // Loop over sync data
    for (TPUserInfo *newuserinfo in tmp_info_array) {
        //NSLog(@"found user info %d %@", newuserinfo.user_id, newuserinfo.info);
        // Check is object is found and update or insert
        index = [self getInfoArrayIndex:newuserinfo];
        if (index == -1) {
            [info_array addObject:newuserinfo];
        } else {
            [info_array replaceObjectAtIndex:index withObject:newuserinfo];
        }
    }

    // Clear data in temp array
    [tmp_info_array removeAllObjects];
}

// ------------------------------------------------------------------------------------
// Handle category sync data, add new user info
// ------------------------------------------------------------------------------------
- (void) handleCategorySyncData {
    
    int index;
    
    // Loop over sync data
    for (TPCategory *newcategory in tmp_category_array) {
        
        // If user has delete flag then delete
        if (newcategory.state == 0) {
            index = [self getCategoryArrayIndex:newcategory];
            [user_array removeObjectAtIndex:index];
            
        } else {
            // Check is object is found and update or insert
            index = [self getCategoryArrayIndex:newcategory];
            if (index == -1) {
                [category_array addObject:newcategory];
            } else {
                [category_array replaceObjectAtIndex:index withObject:newcategory];
            }
        }
    }
        
    // Clear data in temp array
    [tmp_category_array removeAllObjects];
}

// ------------------------------------------------------------------------------------
// Handle rubric sync data. Add new rubric objects and delete rubric flagged for deletion.
// ------------------------------------------------------------------------------------
- (void) handleRubricSyncData {
    
    int index;
    [deleted_rubrics_indexes removeAllIndexes];
    
    // Loop over sync'd data
    for (TPRubric *newrubric in tmp_rubric_array) {
        
        // If user has delete flag then delete
        if (newrubric.state == TP_RUBRIC_DELETED_STATE) {
            
            // If rubric marked for deletion and is opened for editing then close
            if (([self.currentMainViewState isEqualToString:@"rubric"]) &&
                (self.appstate.rubric_id == newrubric.rubric_id)) {
                [self.view rubricDoneEditing];
            }
            // Add to list of deleted rubrics
            [self.deleted_rubrics_indexes addIndex:newrubric.rubric_id];
            // Remove from rubric array
            index = [self getRubricArrayIndex:newrubric];
            [rubric_array removeObjectAtIndex:index];
            
        // Otherwise replace or insert
        } else {
            index = [self getRubricArrayIndex:newrubric];
            if (index == -1) {
                [rubric_array addObject:newrubric];
            } else {
                [rubric_array replaceObjectAtIndex:index withObject:newrubric];
            }
        }
    }
    
    [self.deleted_questions_indexes removeAllIndexes];
    for (TPQuestion *newquestion in tmp_question_array) {
        // If question associated with deleted rubric then delete
        if ([deleted_rubrics_indexes containsIndex:newquestion.rubric_id]) { 
            index = [self getQuestionArrayIndex:newquestion];
            [self.deleted_questions_indexes addIndex:index];
        // Otherwise object found so update or insert
        } else { 
            index = [self getQuestionArrayIndex:newquestion];
            if (index == -1) {
                [question_array addObject:newquestion];
            } else {
                [question_array replaceObjectAtIndex:index withObject:newquestion];
            }
        }
    }
    
    [self.deleted_ratings_indexes removeAllIndexes];
    for (TPRating *newrating in tmp_rating_array) {
        // If rating associated with deleted rubric
        if ([deleted_rubrics_indexes containsIndex:newrating.rubric_id]) { 
            index = [self getRatingArrayIndex:newrating];
            [self.deleted_ratings_indexes addIndex:index];
        // Otherwise object found so update or insert
        } else { 
            index = [self getRatingArrayIndex:newrating];
            if (index == -1) {
                [rating_array addObject:newrating];
            } else {
                [rating_array replaceObjectAtIndex:index withObject:newrating];
            }
        }
    }
    
    // Clear data in temp arrays
    [tmp_rubric_array removeAllObjects];
    [tmp_question_array removeAllObjects];
    [tmp_rating_array removeAllObjects];
}

// ------------------------------------------------------------------------------------
// Handle image sync data. Replace thumbnail with full image
// ------------------------------------------------------------------------------------
- (void) handleImageSyncData {

    // Update database and related file
    [self.database updateImage:image_current];
    
    // Create thumbnail and update database and related file
    NSString *thumbnail_filename = [TPDatabase imagePathWithUserdataID:image_current.userdata_id
                                                                suffix:@"jpg"
                                                             imageType:TP_IMAGE_TYPE_THUMBNAIL];
    
    UIImage *thumbnail_image = [image_current createThumbnailImage];
    
    TPImage *thumbnail = [[TPImage alloc] initWithImage:thumbnail_image
                                             districtId:image_current.district_id
                                             userdataID:image_current.userdata_id
                                                   type:TP_IMAGE_TYPE_THUMBNAIL
                                                  width:thumbnail_image.size.width
                                                 height:thumbnail_image.size.height
                                                 format:@"jpg"
                                               encoding:@"binary"
                                                 userId:image_current.user_id
                                               modified:[NSDate date] 
                                               filename:thumbnail_filename 
                                                 origin:TP_IMAGE_ORIGIN_REMOTE];
    [self.database updateImage:thumbnail];
    [thumbnail release];
    
}

// ------------------------------------------------------------------------------------
// Handle video sync data. Replace thumbnail with full image //jxi;
// ------------------------------------------------------------------------------------
- (void) handleVideoSyncData {
    
    // Update database and related file
    [self.database updateVideo:video_current];
}

// ------------------------------------------------------------------------------------
// Handle userdata sync data. Add new userdata objects and delete userdata objects
// flagged for deletion.
// ------------------------------------------------------------------------------------
- (void) markAllUsersAsUnsynced {
    
    //NSMutableDictionary *unsyncedUsers = [NSMutableDictionary dictionary];
    [needSyncUsers removeAllObjects];
    for (TPUser *userItem in user_list) {
        NSString *keyFromUserID = [NSString stringWithFormat:@"%d", userItem.user_id];
        NSNumber *initialEditNumber = [NSNumber numberWithInt:1];
        //[unsyncedUsers setObject:initialEditNumber forKey:keyFromUserID];
        [needSyncUsers setObject:initialEditNumber forKey:keyFromUserID];
    }
    //[self setNeedSyncUsers:unsyncedUsers];
}

// ------------------------------------------------------------------------------------
// selectUnsyncedUsers - compute how many userdata objects to process for each user
// ------------------------------------------------------------------------------------
- (NSMutableDictionary*) selectUnsyncedUsers {
    
    //NSMutableDictionary *unsyncedUsers = [NSMutableDictionary dictionary];
    [needSyncUsers removeAllObjects];
    for (TPUserData *dataItem in tmp_userdata_array) {
        NSString *keyFromTargetID = [NSString stringWithFormat:@"%d", [dataItem target_id]];
        if ([needSyncUsers objectForKey:keyFromTargetID] == nil) {
            NSNumber *initialEditNumber = [NSNumber numberWithInt:1];
            //[unsyncedUsers setObject:initialEditNumber forKey:keyFromTargetID];
            [needSyncUsers setObject:initialEditNumber forKey:keyFromTargetID];
        } else {
            NSNumber *current_editNumber = [needSyncUsers objectForKey:keyFromTargetID];
            NSNumber *new_editNumber = [NSNumber numberWithInt:([current_editNumber intValue]+1)];
            //[unsyncedUsers setValue:new_editNumber forKey:keyFromTargetID];
            [needSyncUsers setValue:new_editNumber forKey:keyFromTargetID];
        }
    }
    return needSyncUsers;
}


// ------------------------------------------------------------------------------------
// handleUserDataSyncData - handle all synced userdata from server.  Called by
// TPSyncHandlerOp (sync thread)
// ------------------------------------------------------------------------------------
- (void) handleUserDataSyncData:(TPSyncHandlerOp *)callingOperation {

    if (debugSyncUDHandle) NSLog(@"TPModelSync handleUserDataSyncData");
    
    //[self setNeedSyncUsers:[self selectUnsyncedUsers]]; // Compute amount of userdata objects for each user
    [self selectUnsyncedUsers];
    
    userdata_unprocessed_count = [tmp_userdata_array count];
    tmp_userdata_array_flags = [[[NSMutableArray alloc] initWithCapacity:userdata_unprocessed_count] autorelease];
    tmp_synced_userids = [[[NSMutableArray alloc] init] autorelease];
    
    // Initialize flag array with FALSE values (not yet processed)
    for (int i = 0; i < userdata_unprocessed_count; i++) {
        [tmp_userdata_array_flags addObject:[NSNumber numberWithBool:FALSE]];
    }    
    
    if ([callingOperation isCancelled]) { NSLog(@"handleUserDataSyncData CANCELLED"); return; } // Exit if cancelled
    
    // Process synced userdata beginning with current target user
    int target_user_id = appstate.target_id;
    
    BOOL returnResult = [self handleUserDataSyncDataSubset:callingOperation target_id:target_user_id];
    if ([callingOperation isCancelled]) { NSLog(@"handleUserDataSyncData CANCELLED"); return; } // Exit if cancelled
    
    if (returnResult) {
        if (debugSyncUDHandle) NSLog(@"TPModelSync handleUserDataSyncData finished with target %d", target_user_id);
        [self handleUserDataSyncDataSubset:callingOperation target_id:-1];
        if ([callingOperation isCancelled]) { NSLog(@"handleUserDataSyncData CANCELLED"); return; } // Exit if cancelled
    }
    
    // Clear data in temp arrays
    [tmp_userdata_array removeAllObjects];
}

// ------------------------------------------------------------------------------------
// makeDatabaseRequestForHandlingUserData - update database for specified userdata.
// Called by handleUserDataSyncDataSubset (sync thread)
// ------------------------------------------------------------------------------------
- (void)makeDatabaseRequestForHandlingUserData:(TPUserData*)userdata {
    
    if (debugSyncUDHandle) NSLog(@"TPModelSync makeDatabaseRequestForHandlingUserData for target %d", userdata.target_id);
        
    // If form currently being viewed/edited then close form
    //if ([userdata.userdata_id isEqualToString:appstate.userdata_id]) {
    //    if (debugSyncUDHandle) NSLog(@"TPModelSync makeDatabaseRequestForHandlingUserData closing open form");
    //    [self.view performSelectorOnMainThread:@selector(rubricDoneEditing) withObject:nil waitUntilDone:YES]; // Close open form
    //}
    
    // If user has delete flag then delete, otherwise insert/update
    if (userdata.state == TP_USERDATA_DELETED_STATE) {
        // Delete userdata flagged to be deleted
        [self deleteUserData:userdata.userdata_id includingImages:YES];
        
    } else if (userdata.state == TP_USERDATA_RESEND_REQUEST) {
        // Resend userdata flagged to resend (by setting state to unsynced)
        TPUserData *udtemp = [database getUserData:userdata.userdata_id];
        
        if (udtemp.type == TP_USERDATA_TYPE_IMAGE) {
            BOOL imageExists = [database imageDataDoesExist:userdata.userdata_id imageType:TP_IMAGE_TYPE_FULL];
            if (!imageExists) {
                BOOL imageFileExists = [database imageFileDoesExist:userdata.userdata_id imageType:TP_IMAGE_TYPE_FULL];
                if (imageFileExists) {
                    imageExists = [database tryRestoreImageData:userdata.userdata_id];
                }
            }
            if (imageExists) {
                if (udtemp.state == TP_USERDATA_SYNCED_PARTIAL_STATE) {
                    [self updateUserDataState:userdata.userdata_id state:TP_USERDATA_PARTIAL_STATE];
                }
                if (udtemp.state == TP_USERDATA_SYNCED_COMPLETE_STATE) {
                    [self updateUserDataState:userdata.userdata_id state:TP_USERDATA_COMPLETE];
                }
                [self updateImageOrigin:userdata.userdata_id type:TP_IMAGE_TYPE_FULL origin:TP_IMAGE_ORIGIN_LOCAL];
            }
        } else if (udtemp.type ==  TP_USERDATA_TYPE_VIDEO) {
            BOOL videoExists = [database videoDataDoesExist:userdata.userdata_id];
            if (!videoExists) {
                BOOL videoFileExists = [database videoFileDoesExist:userdata.userdata_id];
                if (videoFileExists) {
                    videoExists = [database tryRestoreVideoData:userdata.userdata_id];
                }
            }
            if (videoExists) {
                if (udtemp.state == TP_USERDATA_SYNCED_PARTIAL_STATE) {
                    [self updateUserDataState:userdata.userdata_id state:TP_USERDATA_PARTIAL_STATE];
                }
                if (udtemp.state == TP_USERDATA_SYNCED_COMPLETE_STATE) {
                    [self updateUserDataState:userdata.userdata_id state:TP_USERDATA_COMPLETE];
                }
                //[self updateImageOrigin:userdata.userdata_id type:TP_IMAGE_TYPE_FULL origin:TP_IMAGE_ORIGIN_LOCAL];
            }
        } else {
            if (udtemp.state == TP_USERDATA_SYNCED_PARTIAL_STATE) {
                [self updateUserDataState:userdata.userdata_id state:TP_USERDATA_PARTIAL_STATE];
            }
            if (udtemp.state == TP_USERDATA_SYNCED_COMPLETE_STATE) {
                [self updateUserDataState:userdata.userdata_id state:TP_USERDATA_COMPLETE];
            }
        }
        
        
    } else {
        // Otherwise save userdata
        [self updateUserData:userdata setModified:NO];
    }
    
    // Decrease the changes count for the target user of the processed userdata
    NSString *key = [NSString stringWithFormat:@"%d", [userdata target_id]];
    NSNumber *current_changes_count = [needSyncUsers objectForKey:key];
    NSNumber *new_changes_count = [NSNumber numberWithInt:([current_changes_count intValue]-1)];
    if ([new_changes_count isEqualToNumber:[NSNumber numberWithInt:0]]) {
        [needSyncUsers removeObjectForKey:key];
        if (debugSyncUDHandle) NSLog(@"TPModelSync makeDatabaseRequestForHandlingUserData updating user list after processing all userdata");
        [self.view performSelectorOnMainThread:@selector(reloadUserList) withObject:nil waitUntilDone:NO];
    } else {
        [needSyncUsers setValue:new_changes_count forKey:key];
    }
}

// ------------------------------------------------------------------------------------
// handleUserDataSyncDataSubset - handle synced userdata for target user (-1 for all
// users, 0 for deleted userdata).  Called by handleUserDataSyncData (sync thread)
// ------------------------------------------------------------------------------------
- (BOOL) handleUserDataSyncDataSubset:(TPSyncHandlerOp *)callingOperation target_id:(int)target_id {
    
    if (debugSyncUDHandle) NSLog(@"TPModelSync handleUserDataSyncDataSubset for target %d", target_id);
                         
    int target_id_initial = appstate.target_id;
    
    // Loop over all synced data
    for (int i = 0; i < [tmp_userdata_array count]; i++) {
        
        if ([callingOperation isCancelled]) { NSLog(@"handleUserDataSyncDataSubset CANCELLED"); return FALSE; } // Exit if cancelled
        
        TPUserData *newuserdata = [tmp_userdata_array objectAtIndex:i];  
        
        // Process userdata if not yet processed, and target is specified target user or delete flagged
        if (![[tmp_userdata_array_flags objectAtIndex:i] boolValue] &&
            (newuserdata.target_id == target_id || target_id == -1 || newuserdata.target_id == 0)) {
            
            // Process userdata
            [self makeDatabaseRequestForHandlingUserData:newuserdata];
            
            // Update flag array
            [tmp_userdata_array_flags replaceObjectAtIndex:i withObject:[NSNumber numberWithBool:TRUE]];
            
            // Update count of unprocessed userdata
            userdata_unprocessed_count--;
            
            // For every batch of userdata processed do something
            if (userdata_unprocessed_count%USERDATA_AMOUNT_TO_BATCH_PROCESS == 0) {
                
                // If target has changed and new target not processed
                if (target_id_initial != appstate.target_id && 
                    ![tmp_synced_userids containsObject:[NSNumber numberWithInt:appstate.target_id]]) {
                    
                    // Process new target user
                    BOOL returnResult = [self handleUserDataSyncDataSubset:callingOperation target_id:appstate.target_id];
                    if ([callingOperation isCancelled]) { NSLog(@"handleUserDataSyncDataSubset CANCELLED"); return FALSE; } // Exit if cancelled
                    
                    if (!returnResult) {
                        return FALSE;
                    } else {
                        if (debugSyncUDHandle) NSLog(@"TPModelSync handleUserDataSyncDataSubset reloadUserdataList");
                        [self.view performSelectorOnMainThread:@selector(reloadUserdataList) withObject:nil waitUntilDone:NO];
                        
                    }
                }
                
                //[self updateSyncStatus:SYNC_TYPE_DATA];
                
                // WARNING - need to allow thread to give up lock and sleep to allow UI to proess events.
                //[NSThread sleepForTimeInterval:.2]; // This won't work until the lock is released too.
                
            } // End processing a batch of data
        }
    }
    // Store completed target users
    [tmp_synced_userids addObject:[NSNumber numberWithInt:target_id_initial]];

    return TRUE;
}

// --------------------------------------------------------------------------------------
// handleDeletedData - remove rubrics (previously marked for deletion) with according
// questions and ratings from the database and remove data for these rubrics from model
// arrays (question_array, rating_array)
// --------------------------------------------------------------------------------------
- (void)handleDeletedData {
    
    if (self.deleted_rubrics_indexes != nil) {
        NSUInteger index=[self.deleted_rubrics_indexes firstIndex];
        while(index != NSNotFound) {
            [self.database deleteRubricData:index];
            index=[self.deleted_rubrics_indexes indexGreaterThanIndex: index];
        }
        [self.deleted_rubrics_indexes removeAllIndexes];
    }
    
    if (self.deleted_questions_indexes != nil) {
        NSUInteger index = [self.deleted_questions_indexes firstIndex];
        while (index != NSNotFound) {
            [question_array removeObjectAtIndex:index];
            index = [self.deleted_questions_indexes indexGreaterThanIndex:index];
        }
        [self.deleted_questions_indexes removeAllIndexes];
    }
    
    if (self.deleted_ratings_indexes != 0) {
        NSUInteger index = [self.deleted_ratings_indexes firstIndex];
        while (index != NSNotFound) {
            [question_array removeObjectAtIndex:index];
            index = [self.deleted_ratings_indexes indexGreaterThanIndex:index];
        }
        [self.deleted_ratings_indexes removeAllIndexes];
    }
}

// --------------------------------------------------------------------------------------
// syncHandlerErrorOccurred - error callback from sync handler which calls main thread
// error handler (operation thread)
// --------------------------------------------------------------------------------------
- (void)syncHandlerErrorOccurred:(NSString *)errorMessage {
    [self performSelectorOnMainThread:@selector(handleSyncError:) withObject:errorMessage waitUntilDone:NO];
}

// --------------------------------------------------------------------------------------
// handleSyncError - handles sync error (main thread)
// --------------------------------------------------------------------------------------
- (void)handleSyncError:(NSString *)errorMessage {
    
    if (debugSync) NSLog(@"TPModelSync handleSyncError %d", sync_type);
    
    // If logged out then alert user of sync error
    if (appstate.user_id == 0) {
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"Failure"
                              message:@"A problem occurred while contacting the TeachPoint server.  Please try again."
                              delegate:self
                              cancelButtonTitle: nil
                              otherButtonTitles: @"OK", nil];
        [alert show];
        [alert release];
    } else {
        UIAlertView *alert = [[UIAlertView alloc]
                                  initWithTitle:@"Sync Error"
                                  message:errorMessage
                                  delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alert show];
        [alert release];
    }
    
    // Update sync status message
    [self updateSyncStatus: SYNC_ERROR_GENERAL];
    [self setNeedSyncStatus:NEEDSYNC_STATUS_NOTSYNCED forced:YES];
        
    // Cancel sync process
    [self cancelSync];
    
    // If not logged in then return to login screen
    if (appstate.user_id == 0) {
      [view returnToLoginScreen];
    }

}

// --------------------------------------------------------------------------------------
// didFinishSyncHandler - callback from sync handler which calls main thread to continue
// sync process (operation thread)
// --------------------------------------------------------------------------------------
- (void)didFinishSyncHandler:(NSArray *)appList {
    [self performSelectorOnMainThread:@selector(handleSyncSuccess:) withObject:appList waitUntilDone:NO];
}

// --------------------------------------------------------------------------------------
// handleSyncSuccess - go to next step in sync process (main thread)
// --------------------------------------------------------------------------------------
- (void)handleSyncSuccess:(int)syncTypeCompleted {
        
    if (debugSync) NSLog(@"TPModelSync handleSyncSuccess %d", sync_type);
    
    // Go to next sync step
    sync_complete = 1;
    switch (sync_type) {
            
		case SYNC_TYPE_USER:
            [view sortUsers];
            [view updatePromptString];
            [view showMain];
            [view registerSyncPopupForSyncStatusCallback];
            [self doSync:SYNC_TYPE_INFO];
			break;
            
        case SYNC_TYPE_INFO:
            [view reloadInfo];
            [self doSync:SYNC_TYPE_CATEGORY];
			break;
            
        case SYNC_TYPE_CATEGORY:
            [self doSync:SYNC_TYPE_RUBRIC];
			break;
            
        case SYNC_TYPE_RUBRIC:
            // If demo then skip data upload
            if (publicstate.is_demo == 1) {
                [self purgeUserRecordedDemoData]; // Purge data altered by demo user
                [self doSync:SYNC_TYPE_DATA];
                break;
            }
            [self clientDataSyncPrep]; // Create data queues for sending unsynced data
            if ([userdata_queue count] > 0) {
                [self doSync:SYNC_TYPE_CLIENTDATA]; // Sync client data if needed
            } else if ([localimages_queue count] > 0) { 
                [self doSync:SYNC_TYPE_CLIENTIMAGE]; // Sync client image if needed
            } else if ([localvideos_queue count] > 0) { //jxi;
                [self doSync:SYNC_TYPE_CLIENTVIDEO]; // Sync client image if needed
            }else {
                if (logoutAfterSync) {
                    // If flag set to logout then logout
                    [view returnFromOpenedView];
                    [view logout];
                    [view exittimeoutscreen];
                } else {
                    // Otherwise continue sync process
                    [self doSync:SYNC_TYPE_DATA];
                }
            }
			break;
            
        case SYNC_TYPE_CLIENTDATA:
            if ([userdata_queue count] > 0) {
                [self doSync:SYNC_TYPE_CLIENTDATA]; // Sync client data if needed
            } else  if ([localimages_queue count] > 0) {
                [self doSync:SYNC_TYPE_CLIENTIMAGE]; // Sync client image if needed
            } else  if ([localvideos_queue count] > 0) { //jxi;
                [self doSync:SYNC_TYPE_CLIENTVIDEO]; // Sync client video if needed
            } else {
                if (logoutAfterSync) {
                    // If flag set to logout then logout
                    [view returnFromOpenedView];
                    [view logout];
                    [view exittimeoutscreen];
                } else {
                    // Otherwise continue sync process
                    [self doSync:SYNC_TYPE_DATA];
                }
            }
			break;
            
        case SYNC_TYPE_CLIENTIMAGE:
            if ([localimages_queue count] > 0) {
                [self doSync:SYNC_TYPE_CLIENTIMAGE]; // Sync client image if needed
            } else  if ([localvideos_queue count] > 0) { //jxi;
                [self doSync:SYNC_TYPE_CLIENTVIDEO]; // Sync client video if needed
            }else {
                if (logoutAfterSync) {
                    // If flag set to logout then logout
                    [view returnFromOpenedView];
                    [view logout];
                    [view exittimeoutscreen];
                } else {
                    // Otherwise continue sync process
                    [self doSync:SYNC_TYPE_DATA];
                }
            }
			break;
        case SYNC_TYPE_CLIENTVIDEO: //jxi;
            if ([localvideos_queue count] > 0) {
                [self doSync:SYNC_TYPE_CLIENTVIDEO]; // Sync client video if needed
            }else if ([localimages_queue count] > 0) {
                [self doSync:SYNC_TYPE_CLIENTIMAGE]; // Sync client image if needed
            } else {
                if (logoutAfterSync) {
                    // If flag set to logout then logout
                    [view returnFromOpenedView];
                    [view logout];
                    [view exittimeoutscreen];
                } else {
                    // Otherwise continue sync process
                    [self doSync:SYNC_TYPE_DATA];
                }      
            }
            break;
        case SYNC_TYPE_DATA:
            
            //jxi; advance syncing
            if (userdata_sync_step_response == USERDATA_SYNC_STEP_RESPONSE_PARTIAL) {
                // if response type is partial, then send the same request again with the current step
                [self doSync:SYNC_TYPE_DATA];
            
            } else if (userdata_sync_current_target_id != appstate.target_id) {
                // if the selected user changes, go back to requesting data for that changed user
                userdata_sync_step = USERDATA_SYNC_STEP_UNKNOWN;
                [self doSync:SYNC_TYPE_DATA];
            }
            else if (userdata_sync_step_response == USERDATA_SYNC_STEP_RESPONSE_COMPLETE ||
                       userdata_sync_step_response == USERDATA_SYNC_STEP_RESPONSE_UNKNOWN) {
                // if response type is complete, then determine which state to go to
                if (userdata_sync_step == USERDATA_SYNC_STEP_USER_CURRENT ||
                    userdata_sync_step == USERDATA_SYNC_STEP_USERS_IN_SAME_SCHOOL) {
                    
                    if (userdata_sync_step == USERDATA_SYNC_STEP_USER_CURRENT) {
                        // if it was in the 1st step, then go back to next step;
                        // requesting for userdata of the users in the same school as current target
                        userdata_sync_step = USERDATA_SYNC_STEP_USERS_IN_SAME_SCHOOL;
                        
                    } else if (userdata_sync_step == USERDATA_SYNC_STEP_USERS_IN_SAME_SCHOOL) {
                        // if it was in the 2nd step, then go back to last step;
                        // requesting for userdata of all the remaining users
                        userdata_sync_step = USERDATA_SYNC_STEP_USERS_ALL;
                        
                    }
                    
                    [self doSync:SYNC_TYPE_DATA];
                    
                } else if (userdata_sync_step == USERDATA_SYNC_STEP_USERS_ALL) {
                    // if all the 3 steps finished, then reset the sync status value
                    userdata_sync_step = USERDATA_SYNC_STEP_UNKNOWN;
                    
                    if ([self getUnsyncedCount] > 0) {
                        
                        [self setNeedSyncStatus:NEEDSYNC_STATUS_NOTSYNCED forced:YES];
                    } else {
                        
                        [self setNeedSyncStatus:NEEDSYNC_STATUS_SYNCED forced:YES];
                    }
                    [self setIsApplicationFirstTimeSync:NO];
                    [self updateLastSync];
                    [self updateSyncStatus: 0];

                }
            }
			break;
            
        case SYNC_TYPE_IMAGEDATA:
            if ([self getUnsyncedCount] > 0) {
                [self setNeedSyncStatus:NEEDSYNC_STATUS_NOTSYNCED forced:YES];
            } else {
                [self setNeedSyncStatus:NEEDSYNC_STATUS_SYNCED forced:YES];
            }
            [self restartSyncing];
            break;
            
        case SYNC_TYPE_VIDEODATA: //jxi;
            if ([self getUnsyncedCount] > 0) {
                [self setNeedSyncStatus:NEEDSYNC_STATUS_NOTSYNCED forced:YES];
            } else {
                [self setNeedSyncStatus:NEEDSYNC_STATUS_SYNCED forced:YES];
            }
            
            
            [self restartSyncing];
            break;
        //jxi; For on-demand syncing for formdata with nodata state
        case SYNC_TYPE_FORMDATA:
            if ([self getUnsyncedCount] > 0) {
                [self setNeedSyncStatus:NEEDSYNC_STATUS_NOTSYNCED forced:YES];
            } else {
                [self setNeedSyncStatus:NEEDSYNC_STATUS_SYNCED forced:YES];
            }
            [self updateLastSync];
            [self updateSyncStatus: 0];
            [self restartSyncing];
            break;
            
	} // End switch on sync type
}

@end
