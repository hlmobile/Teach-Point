@class TPView;

// ---------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------
@interface TPSyncManager : NSObject {
    TPView *viewDelegate;
    NSTimer *timer;
    int lastSuccess;
}

@property (nonatomic, retain) NSTimer * timer; 

- (id)initWithView:(TPView *)mainview;
- (void) start;
- (void) runSyncManager;

@end

// ---------------------------------------------------------------------------------------
