//
//  SyncHandlerOp.m
//  teachpoint
//
//  Created by Chris Dunn on 7/24/12.
//  Copyright (c) 2012 Clear Pond Technologies, Inc. All rights reserved.
//

#import "TPSyncHandlerOp.h"
#import "TPSyncHandlerDelegate.h"
#import "TPData.h"
#import "TPModel.h"
#import "TPModelSync.h"
#import "TPParser.h"
#import "TPView.h"

@implementation TPSyncHandlerOp

@synthesize delegate;
@synthesize model;

- (id)initWithData:(TPModel *)theModel delegate:(id <TPSyncHandlerDelegate>)theDelegate {
    self = [super init];
    if (self != nil) {
        self.model = theModel;
        self.delegate = theDelegate;
    }
    return self;
}

// --------------------------------------------------------------------------------------
- (void)dealloc {
    [super dealloc];
}

// --------------------------------------------------------------------------------------
- (void)main {
    
    if (debugSync) NSLog(@"TPSyncHandler main %d", model.sync_type);
    
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
    // Parse data
	BOOL isParseComplete = [self parseData:model.page_results parseError:NULL];
    if (debugSync) NSLog(@"TPSyncHandler parse done");
    
    if ([self isCancelled]) { NSLog(@"Op CANCELLED"); [pool release]; return; } // Exit if cancelled
    
    if (isParseComplete) {
        
        // Handle parsed datax
        switch (model.sync_type) {
                
            case SYNC_TYPE_USER:
                if ([model.appstate.sync_status isEqualToString:@"loginfailed"]) {
                    // If sync failed
                    if (model.appstate.user_id == 0) {
                        //[model.view syncfailed:@"Login Failed" poptostart:1];
                        //[model.view performSelectorOnMainThread:@selector(syncfailed:) withObject:@"Login Failed" waitUntilDone:NO];
                        [model clear];
                    }
                    [model restartSyncing];
                    [self.delegate syncHandlerErrorOccurred:@"bad login credentials"];
                } else {
                    // If sync succeeded
                    [model waitForLock:model.uiSyncLock];
                    
                    [model handleUserSyncData];
                    [model archiveUsers];
                    [model deriveUserList];
                    
                    //[model.view sortUsers];
                    //[model.view updatePromptString];
                    //[model.view showMain];
                    //[model.view registerSyncPopupForSyncStatusCallback];
                    
                    [model.view performSelectorOnMainThread:@selector(sortUsers) withObject:nil waitUntilDone:YES];
                    [model.view performSelectorOnMainThread:@selector(updatePromptString) withObject:nil waitUntilDone:YES];
                    [model.view performSelectorOnMainThread:@selector(showMain) withObject:nil waitUntilDone:YES];
                    [model.view performSelectorOnMainThread:@selector(registerSyncPopupForSyncStatusCallback) withObject:nil waitUntilDone:YES];
                    
                    [model freeLock:model.uiSyncLock];
                    
                    if ([self isCancelled]) { NSLog(@"Op CANCELLED"); [pool release]; return; } // Exit if cancelled
                    [self.delegate didFinishSyncHandler:nil];
                }
                break;
                
            case SYNC_TYPE_INFO:
                if ([model.appstate.sync_status isEqualToString:@"loginfailed"]) {
                    // If sync failed
                    [model restartSyncing];
                    [self.delegate syncHandlerErrorOccurred:@"bad login credentials"];
                } else {
                    // If sync succeeded
                    [model waitForLock:model.uiSyncLock];
                    [model handleUserInfoSyncData];
                    [model archiveInfo];
                    [model freeLock:model.uiSyncLock];
                    if ([self isCancelled]) { NSLog(@"Op CANCELLED"); [pool release]; return; } // Exit if cancelled
                    [self.delegate didFinishSyncHandler:nil];
                }
                break;
                
            case SYNC_TYPE_CATEGORY:
                if ([model.appstate.sync_status isEqualToString:@"loginfailed"]) {
                    // If sync failed
                    [model restartSyncing];
                    [self.delegate syncHandlerErrorOccurred:@"bad login credentials"];
                } else {
                    // If sync succeeded
                    [model waitForLock:model.uiSyncLock];
                    [model handleCategorySyncData];
                    [model archiveCategories];
                    [model.view performSelectorOnMainThread:@selector(reloadReport) withObject:nil waitUntilDone:YES];
                    [model freeLock:model.uiSyncLock];
                    if ([self isCancelled]) { NSLog(@"Op CANCELLED"); [pool release]; return; } // Exit if cancelled
                    [self.delegate didFinishSyncHandler:nil];
                }
                break;
                
            case SYNC_TYPE_RUBRIC:
                if ([model.appstate.sync_status isEqualToString:@"loginfailed"]) {
                    // If sync failed
                    [model restartSyncing];
                    [self.delegate syncHandlerErrorOccurred:@"bad login credentials"];
                } else {
                    // If sync succeeded
                    [model waitForLock:model.uiSyncLock];
                    [model handleRubricSyncData];
                    [model archiveRubrics];
                    [model deriveRubricList];
                    [model.view performSelectorOnMainThread:@selector(reloadUserdataList) withObject:nil waitUntilDone:YES];
                    [model freeLock:model.uiSyncLock];
                    if ([self isCancelled]) { NSLog(@"Op CANCELLED"); [pool release]; return; } // Exit if cancelled
                    [self.delegate didFinishSyncHandler:nil];
                }
                break;
                
            case SYNC_TYPE_CLIENTDATA:
                if ([model.appstate.sync_status isEqualToString:@"loginfailed"]) {
                    // If sync failed
                    [model restartSyncing];
                    [self.delegate syncHandlerErrorOccurred:@"bad login credentials"];
                } else if ([model.appstate.sync_status isEqualToString:@"syncfailed"]) {
                    // If sync failed
                    [model restartSyncing];
                    [self.delegate syncHandlerErrorOccurred:@"general sync failure"];
                } else {
                    if ([model.appstate.sync_status isEqualToString:@"syncerror"]) {
                        // If sync error
                        [model restartSyncing];
                        [self.delegate syncHandlerErrorOccurred:@"sync error"];
                    } else {
                        // Otherwise continue sync process
                        [model updateUserDataStateNoTimestamp:model.sync_data_id state:12]; // Mark data as sent
                        if ([self isCancelled]) { NSLog(@"Op CANCELLED"); [pool release]; return; } // Exit if cancelled
                        [self.delegate didFinishSyncHandler:nil];
                    }
                }
                break;
                
            case SYNC_TYPE_CLIENTIMAGE:
                if ([model.appstate.sync_status isEqualToString:@"loginfailed"]) {
                    // If sync failed
                    [self.delegate syncHandlerErrorOccurred:@"bad login credentials"];
                } else if ([model.appstate.sync_status isEqualToString:@"syncfailed"]) {
                    // If sync failed
                    [self.delegate syncHandlerErrorOccurred:@"general sync failure"];
                } else {
                    // If sync succeeded
                    if ([model.appstate.sync_status isEqualToString:@"syncerror"]) {
                        [model restartSyncing];
                        [self.delegate syncHandlerErrorOccurred:@"sync error"];
                    } else {
                        [model updateUserDataStateNoTimestamp:model.sync_data_id state:12]; // Mark data as sent
                        [model updateImageOrigin:model.sync_data_id type:TP_IMAGE_TYPE_FULL origin:TP_IMAGE_ORIGIN_REMOTE];
                        [model updateImageOrigin:model.sync_data_id type:TP_IMAGE_TYPE_THUMBNAIL origin:TP_IMAGE_ORIGIN_REMOTE];
                        if ([self isCancelled]) { NSLog(@"Op CANCELLED"); [pool release]; return; } // Exit if cancelled
                        [self.delegate didFinishSyncHandler:nil];
                    }
                }
                break;
                
            case SYNC_TYPE_CLIENTVIDEO: //jxi;
                if ([model.appstate.sync_status isEqualToString:@"loginfailed"]) {
                    // If sync failed
                    [self.delegate syncHandlerErrorOccurred:@"bad login credentials"];
                } else if ([model.appstate.sync_status isEqualToString:@"syncfailed"]) {
                    // If sync failed
                    [self.delegate syncHandlerErrorOccurred:@"general sync failure"];
                } else {
                    // If sync succeeded
                    if ([model.appstate.sync_status isEqualToString:@"syncerror"]) {
                        [model restartSyncing];
                        [self.delegate syncHandlerErrorOccurred:@"sync error"];
                    } else {
                        [model updateUserDataStateNoTimestamp:model.sync_data_id state:12]; // Mark data as sent
                        [model updateVideoOrigin:model.sync_data_id type:TP_IMAGE_TYPE_FULL origin:TP_IMAGE_ORIGIN_REMOTE];
                        //[model updateImageOrigin:model.sync_data_id type:TP_IMAGE_TYPE_THUMBNAIL origin:TP_IMAGE_ORIGIN_REMOTE];
                        if ([self isCancelled]) { NSLog(@"Op CANCELLED"); [pool release]; return; } // Exit if cancelled
                        [self.delegate didFinishSyncHandler:nil];
                    }
                }
                break;
                
            case SYNC_TYPE_DATA:
                if ([model.appstate.sync_status isEqualToString:@"loginfailed"]) {
                    // If sync failed
                    [model restartSyncing];
                    [self.delegate syncHandlerErrorOccurred:@"bad login credentials"];
                } else if ([model.appstate.sync_status isEqualToString:@"syncfailed"]) {
                    // If sync failed
                    [model restartSyncing];
                    [self.delegate syncHandlerErrorOccurred:@"general sync failure"];
                } else {
                    // If sync succeeded
                    model.isFirstSyncAfterUpgrade = NO;
                    
                    [model waitForLock:model.uiSyncLock];
                    
                    [model.view disableRubricListInteraction]; // Flags only, no UIKit calls
                    
                    [model handleUserDataSyncData:self];
                    
                    if ([self isCancelled]) { NSLog(@"Op CANCELLED"); [model freeLock:model.uiSyncLock]; [pool release]; return; } // Exit if cancelled
                    
                    [model handleDeletedData];
                    
                    [model.view enableRubricListInteraction]; // Flags only, no UIKit calls
                                        
                    if ([self isCancelled]) { NSLog(@"Op CANCELLED"); [model freeLock:model.uiSyncLock]; [pool release]; return; } // Exit if cancelled
                    
                    [model.view performSelectorOnMainThread:@selector(reloadUserdataList) withObject:nil waitUntilDone:YES];
                    
                    [model archiveState];
                    [model deriveUserDataInfo];
                    
                    [model freeLock:model.uiSyncLock];
                    
                    if ([self isCancelled]) { NSLog(@"Op CANCELLED"); [pool release]; return; } // Exit if cancelled
                    [self.delegate didFinishSyncHandler:nil];
                }
                break;
                
            case SYNC_TYPE_IMAGEDATA:
                if ([model.appstate.sync_status isEqualToString:@"loginfailed"]) {
                    // If sync failed
                    [self.delegate syncHandlerErrorOccurred:@"bad login credentials"];
                } else if ([model.appstate.sync_status isEqualToString:@"syncfailed"]) {
                    // If sync failed
                    [self.delegate syncHandlerErrorOccurred:@"general sync failure"];
                } else {
                    if ([model.appstate.sync_status isEqualToString:@"syncerror"]) {
                        // If sync error
                        [self.delegate syncHandlerErrorOccurred:@"sync error"];
                    } else {
                        // If sync succeeded
                        [model waitForLock:model.uiSyncLock];
                        [model handleImageSyncData];
                        [model.view performSelectorOnMainThread:@selector(reloadUserdataList) withObject:nil waitUntilDone:YES];
                        [model.view performSelectorOnMainThread:@selector(resetPreview) withObject:nil waitUntilDone:YES];
                        [model freeLock:model.uiSyncLock];
                        
                        if ([self isCancelled]) { NSLog(@"Op CANCELLED"); [pool release]; return; } // Exit if cancelled
                        [self.delegate didFinishSyncHandler:nil];
                    }
                }
                break;
                
            //jxi; On-Demand syncing for form data with nodata state
            case SYNC_TYPE_FORMDATA:
                if ([model.appstate.sync_status isEqualToString:@"loginfailed"]) {
                    // If sync failed
                    [self.delegate syncHandlerErrorOccurred:@"bad login credentials"];
                } else if ([model.appstate.sync_status isEqualToString:@"syncfailed"]) {
                    // If sync failed
                    [self.delegate syncHandlerErrorOccurred:@"general sync failure"];
                } else {
                    if ([model.appstate.sync_status isEqualToString:@"syncerror"]) {
                        // If sync error
                        [self.delegate syncHandlerErrorOccurred:@"sync error"];
                    } else {
                        // If sync succeeded
                        if ([model.tmp_userdata_array count] > 0) {
                            // If there is data,
                            [model waitForLock:model.uiSyncLock];
                        
                            [model handleUserDataSyncData:self];
                            [model handleDeletedData];
                            [model.view performSelectorOnMainThread:@selector(reloadUserdataList) withObject:nil waitUntilDone:YES];
                            [model archiveState];
                            [model deriveUserDataInfo];
                            
                            TPUserData* userdata = [model getUserDataFromListById:model.remoteFormIDToSync];
                            [model setUserData:userdata];
                            [model.view performSelectorOnMainThread:@selector(resetRubricVC) withObject:nil waitUntilDone:YES];
                        
                            [model freeLock:model.uiSyncLock];
                        } else {
                            // In the meanwhile, the data requested was deleted on Server, then  go back to RubricListVC
                            [model.view performSelectorOnMainThread:@selector(onNoRubricData) withObject:nil waitUntilDone:YES];
                        }
                        
                        if ([self isCancelled]) { NSLog(@"Op CANCELLED"); [pool release]; return; } // Exit if cancelled
                        [self.delegate didFinishSyncHandler:nil];
                    }
                }
                break;
                
            case SYNC_TYPE_VIDEODATA: //jxi;
                if ([model.appstate.sync_status isEqualToString:@"loginfailed"]) {
                    // If sync failed
                    [self.delegate syncHandlerErrorOccurred:@"bad login credentials"];
                } else if ([model.appstate.sync_status isEqualToString:@"syncfailed"]) {
                    // If sync failed
                    [self.delegate syncHandlerErrorOccurred:@"general sync failure"];
                } else {
                    if ([model.appstate.sync_status isEqualToString:@"syncerror"]) {
                        // If sync error
                        [self.delegate syncHandlerErrorOccurred:@"sync error"];
                    } else {
                        // If sync succeeded
                        [model waitForLock:model.uiSyncLock];
                        [model handleVideoSyncData];
                        [model.view performSelectorOnMainThread:@selector(reloadUserdataList) withObject:nil waitUntilDone:YES];
                        [model.view performSelectorOnMainThread:@selector(resetVideoPreview) withObject:nil waitUntilDone:YES];
                        [model freeLock:model.uiSyncLock];
                        
                        if ([self isCancelled]) { NSLog(@"Op CANCELLED"); [pool release]; return; } // Exit if cancelled
                        [self.delegate didFinishSyncHandler:nil];
                    }
                }
                break;

        } // End switch on sync type
        
    } else {
        // If parse error
        [self.delegate syncHandlerErrorOccurred:@"parse error"];
    }
    
	[pool release];
}


// ---------------------------------------------------------------------------------------
// parseData - parses sync data, return YES if success, NO otherwise
// ---------------------------------------------------------------------------------------
- (BOOL) parseData:(NSData *)data parseError:(NSError **)err {
	
	NSString *pagestring = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
	NSRange found;
    
    // Dump incoming message
    if (debugSyncDetail) {
        NSLog(@"parse data length %d", [data length]);
        NSLog(@"parse string length %d", [pagestring length]);
        NSLog(@"parse string is:\n%@", pagestring);
    }
    
	found = [pagestring rangeOfString:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>"];
	if (found.location == NSNotFound) return NO;
	found = [pagestring rangeOfString:@"</root>"];
	if (found.location == NSNotFound) return NO;
	    
    NSXMLParser *parser = [[[NSXMLParser alloc] initWithData:data] autorelease];
	TPParser *sync_parser = [[[TPParser alloc] initWithModel:model] autorelease];
    [parser setDelegate:sync_parser];
    [parser setShouldProcessNamespaces:NO];
    [parser setShouldReportNamespacePrefixes:NO];
    [parser setShouldResolveExternalEntities:NO];
    [parser parse];
    	
    if (err && [parser parserError]) {
        NSError *err = [parser parserError];
		NSLog(@"ERROR: parsing error %@", err);
		return NO;
    }
    
	return YES;
}

@end
