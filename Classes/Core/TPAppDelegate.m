#import "TPAppDelegate.h"
#import "TPData.h"
#import "TPDatabase.h"
#import "TPModel.h"
#import "TPModelSync.h"
#import "TPView.h"
#import "TPSyncManager.h"

@implementation TPAppDelegate

// ----------------------------------------------------------------------------------------------
// didFinishLaunchingWithOptions - called when first installed or restarting after killed
// ----------------------------------------------------------------------------------------------
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    if (debugAppStart) {
        NSLog(@"**********TPAppDelegate didFinishLaunchingWithOptions");
        for(id key in launchOptions) {
            if (debugAppStart) NSLog(@"**********TPAppDelegate launch option %@", (NSString *)key);
        }
    }
    
    // Create the model
	model = [[TPModel alloc] init];
    
    // Create the view and connect to model
	viewDelegate = [[TPView alloc] initWithModel:model];
	model.view = viewDelegate;
    
    // Create the sync manager and run sync timer
    [model resetAllLocks]; // Reset all locks - shouldn't be require but do here in case locked
    
    TPSyncManager *syncmanager = [[TPSyncManager alloc] initWithView:viewDelegate];
    model.syncMgr = syncmanager;
    [syncmanager release];
    
    [model.syncMgr start];
    
    if (debugAppStart) [model dumpstate];
    
    return YES;
}

// ----------------------------------------------------------------------------------------------
//applicationWillEnterForeground - called first when returning from background
// ----------------------------------------------------------------------------------------------
- (void)applicationWillEnterForeground:(UIApplication *)application {
    if (debugAppStart) NSLog(@"**********TPAppDelegate applicationWillEnterForeground");
    if (debugAppStart) [model dumpstate];
    [model resetAllLocks]; // Reset all locks - shouldn't be require but do here in case locked
    [model.syncMgr runSyncManager];
    [model.syncMgr start];
}

// ----------------------------------------------------------------------------------------------
// applicationDidBecomeActive - called second after starting or entering foreground
// ----------------------------------------------------------------------------------------------
- (void)applicationDidBecomeActive:(UIApplication *)application {
    
	if (debugAppStart) NSLog(@"**********TPAppDelegate applicationDidBecomeActive");
    // Update orientation value
    // If regular (non-demo) user is logged in go to timeout screen
    if (![[model getState] isEqualToString:@"install"])  {
        [viewDelegate timeoutscreen];
    }
}

// ----------------------------------------------------------------------------------------------
// applicationWillResignActive - called first before entering background
// ----------------------------------------------------------------------------------------------
- (void)applicationWillResignActive:(UIApplication *)application {
    
	if (debugAppStart) NSLog(@"**********TPAppDelegate applicationWillResignActive");
    
    // Cancel sync and close database
    [model cancelSync];
    
    // Return from open form or report
    [viewDelegate returnFromOpenedView];
    
    // Make sure popups and alerts are closed
    [viewDelegate closeAllPopupsAndAlerts];
    
    // If logged in then archive state
    NSString *currentState = [model getState];
    if (currentState != nil &&
        ![currentState isEqualToString:@"install"] &&
        ![currentState isEqualToString:@"timeout"]) {
        [model setState:@"timeout"];
        [model archiveState];
    }
    
    // If not install state the go to timeout screen
    if (![[model getState] isEqualToString:@"install"])  {
        [viewDelegate timeoutscreen];
    }
}

// ----------------------------------------------------------------------------------------------
// applicationDidEnterBackground - called second entering background and MULTI-TASKING is on
// ----------------------------------------------------------------------------------------------
- (void)applicationDidEnterBackground:(UIApplication *)application {
    if (debugAppStart) NSLog(@"**********TPAppDelegate applicationDidEnterBackground");
    [model.syncMgr.timer invalidate];
    [model suspendSyncing];
}

// ----------------------------------------------------------------------------------------------
// applicationWillTerminate - called second when MULTI-TASKING is NOT on
// ----------------------------------------------------------------------------------------------
- (void)applicationWillTerminate:(UIApplication *)application {
	if (debugAppStart) NSLog(@"**********TPAppDelegate applicationWillTerminate");
    
    // Make sure popups and alerts are closed
    [viewDelegate closeAllPopupsAndAlerts];
    
    // Stop sync timer
    [model.syncMgr.timer invalidate];
    [model suspendSyncing];
}

// ----------------------------------------------------------------------------------------------
- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    if (debugAppStart) NSLog(@"**********TPAppDelegate applicationDidReceiveMemoryWarning");
}

// ----------------------------------------------------------------------------------------------
- (void)applicationProtectedDataWillBecomeUnavailable:(UIApplication *)application {
    if (debugAppStart) NSLog(@"**********TPAppDelegate applicationProtectedDataWillBecomeUnavailable");
}

// ----------------------------------------------------------------------------------------------
- (void)dealloc {
	if (debugAppStart) NSLog(@"**********TPAppDelegate dealloc");
	[viewDelegate release];
	[model release];
	[super dealloc];
}

// ----------------------------------------------------------------------------------------------
- (NSUInteger)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window {
    if (debugAppStart) NSLog(@"**********TPAppDelegate supportedInterfaceOrientationsForWindow");
    return UIInterfaceOrientationMaskAll;
}

@end
