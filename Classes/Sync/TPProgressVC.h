//
//  TPProgressVC.h
//  teachpoint
//
//  Created by Dmitriy Doroshenko on 17.11.11.
//  Copyright (c) 2011 QArea. All rights reserved.
//

@class TPView;
@class TPRoundRectView;

@interface TPProgressVC : UIViewController {

    TPView *viewDelegate;

    UIView *wholeview;
    TPRoundRectView *roundrect;
    
    UILabel *userLabel;
    UILabel *statusLabel;
    UIButton *cancelButton;
    
    int currentSyncType, currentUnprocessedCount, totalUnprocessedCount;
    BOOL cleanState;
}

- (id) initWithView:(TPView *)delegate;

// sync-related functions
- (void) updateSyncStatusCallback:(int) syncType;
- (void) updateStatusUI;
- (void) setUnprocessedCounts;
- (NSString *) syncStatusString;

@end
