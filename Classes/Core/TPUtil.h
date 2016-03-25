//
//  TPUtil.h
//  teachpoint
//
//  Created by Chris Dunn on 4/8/11.
//  Copyright 2011 Clear Pond Technologies, Inc. All rights reserved.
//

// --------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------
#define TPLEGALCHARACTERS @" ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890~`!@#$%^&*()_-+={[}]|\\:;\"'<,>.?/\n"

// --------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------
@interface TPUtil : NSObject {
}

+ (NSString *) getPasswordHash:(NSString *)password;
+ (NSString *) htmlSafeString:(NSString *)input;
+ (NSString *) htmlconvertString:(NSString *)input;
+ (NSString *) formatElapsedTime:(int)elapsedTime;
+ (NSString *) formatElapsedTime:(int)elapsedTime :(BOOL)withUnits;

// image manipulation helpers
+ (UIImage *)thumbnailFromImage:(UIImage *)image scaledToSize:(CGSize)newSize;
+ (UIImage *)imageRotatedByDegrees:(UIImage *)image :(CGFloat)degrees :(BOOL)flipped; 
+ (BOOL)isCameraAvailableOnTheDevice;

// String manipulation methods
+ (NSString *) escapeQuote:(NSString *)input maxLen:(int)maxLen;
+ (NSString *)stringTruncate:(NSString *)input maxLen:(int)maxLen;
+ (BOOL)shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)string maxLength:(int)maxLen;

// Interface orientation
+ (BOOL)isPortraitOrientation;

@end
