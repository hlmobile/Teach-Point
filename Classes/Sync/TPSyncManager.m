#import "TPData.h"
#import "TPView.h"
#import "TPModel.h"
#import "TPModelSync.h"
#import "TPSyncManager.h"

#define SYNC_INTERVAL 600          // Sync interval in seconds after successful sync
#define SYNC_CHECK_INTERVAL 10.0   // Interval in seconds to check if need to sync (keeps checking at this interval until successful sync)

// ---------------------------------------------------------------------------------------
// TPSyncManager - The sync manager runs continually at a fixed interval (SYNC_CHECK_INTERVAL)
// and checks to see if the appplication should be synced.  If the last sync time, given
// by the TPModel method getLastSync, is nil, then no sync is done.  In this case the sync manager
// is running but "idling".  If last sync is not nil and time since the last sync is
// greater than SYNC_INTERVAL, then a sync is done.  The type of sync is controlled by
// variable(s) set in the TPView class.
// ---------------------------------------------------------------------------------------
@implementation TPSyncManager

@synthesize timer;

- (id)initWithView:(TPView *)mainview {
    self = [super init];
    if (self) {
        viewDelegate = mainview;
        lastSuccess = 1;
    }
    return self;
}

// ---------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------
- (void) start {
    if (debugSyncMgr) NSLog(@"TPSyncManager start");
    timer = [NSTimer scheduledTimerWithTimeInterval:SYNC_CHECK_INTERVAL target:self selector:@selector(runSyncManager:) userInfo:nil repeats:YES];
}

// ---------------------------------------------------------------------------------------
// runSyncManager - Wake and check sync status, possibly begin a sync process,
// alert user as required
// ---------------------------------------------------------------------------------------
- (void) runSyncManager:(NSTimer *)theTimer {
    
    if (debugSyncMgr) NSLog(@"runSyncManager");
    
    NSDate *last_sync = [[viewDelegate.model getLastSync] retain];
    if (last_sync != nil) {
        if (debugSyncMgr) NSLog(@"TPSyncManager checking sync interval - last %@", [viewDelegate.model stringFromDate:last_sync]);
        // If need sync then try to sync
        NSTimeInterval interval = [last_sync timeIntervalSinceNow] * -1;
        if (interval > SYNC_INTERVAL) {
            if (debugSyncMgr) NSLog(@"runSyncManager SYNCING user");
            [viewDelegate doSync];
        }
    }
    [last_sync release];
}

- (void) runSyncManager {
    [self runSyncManager:nil];
}

@end

// ---------------------------------------------------------------------------------------
