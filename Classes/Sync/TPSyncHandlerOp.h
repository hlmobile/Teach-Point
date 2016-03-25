//
//  SyncHandlerOp.h
//  teachpoint
//
//  Created by Chris Dunn on 7/24/12.
//  Copyright (c) 2012 Clear Pond Technologies, Inc. All rights reserved.
//

@class TPModel;

@protocol TPSyncHandlerDelegate;

@interface TPSyncHandlerOp : NSOperation <NSXMLParserDelegate> {
    
    TPModel *model;
    id <TPSyncHandlerDelegate> delegate;
}

@property (nonatomic, assign) id <TPSyncHandlerDelegate> delegate;
@property (nonatomic, retain) TPModel *model;

- (id)initWithData:(TPModel *)model delegate:(id <TPSyncHandlerDelegate>)theDelegate;
- (BOOL) parseData:(NSData *)data parseError:(NSError **)err;

@end
