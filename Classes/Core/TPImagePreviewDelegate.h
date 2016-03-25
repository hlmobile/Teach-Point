//
//  TPImagePreviewDelegate.h
//  teachpoint
//
//  Created by admin on 7/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol TPImagePreviewDelegate <NSObject>

- (void) reloadImage:(UIImage *)someimage name:(NSString *)name share:(BOOL)share description:(NSString *)description;

@end

@protocol TPVPreviewDelegate <NSObject>

- (void) reloadVideo:(NSURL *)videoURL name:(NSString *)name share:(BOOL)share description:(NSString *)description;

@end