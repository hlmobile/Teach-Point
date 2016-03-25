#import "TPUtil.h"
#import <AVFoundation/AVFoundation.h>
#include <CommonCrypto/CommonDigest.h>

@implementation TPUtil

// --------------------------------------------------------------------------------------
// Generate SHA512 hash with constant salt string
// --------------------------------------------------------------------------------------
+ (NSString *) getPasswordHash:(NSString *)password {
    NSString *saltedpassword = [NSString stringWithFormat:@"%@SALTEDteachpointpasswordstring", password];
    const char *hpasswordptr = [saltedpassword UTF8String];
    unsigned char hashbuffer[CC_SHA512_DIGEST_LENGTH];
    CC_SHA512(hpasswordptr, strlen(hpasswordptr), hashbuffer);
    NSMutableString *hashedpassword = [NSMutableString stringWithCapacity:CC_SHA512_DIGEST_LENGTH*2];
    for(int i=0; i<CC_SHA512_DIGEST_LENGTH; i++) [hashedpassword appendFormat:@"%02x",hashbuffer[i]];
    return hashedpassword;
}

// --------------------------------------------------------------------------------------
// Make a string safe to send in XML
// --------------------------------------------------------------------------------------
+ (NSString *) htmlSafeString:(NSString *)input {
    NSString *output1 = [input stringByReplacingOccurrencesOfString:@"&" withString:@"&amp;"];
    NSString *output2 = [output1 stringByReplacingOccurrencesOfString:@"<" withString:@"&lt;"];
    NSString *output3 = [output2 stringByReplacingOccurrencesOfString:@">" withString:@"&gt;"];
    return output3;
}

// --------------------------------------------------------------------------------------
// Convert a safe XMl string back to original string
// --------------------------------------------------------------------------------------
+ (NSString *) htmlconvertString:(NSString *)input {
    NSString *output1 = [input stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"];
    NSString *output2 = [output1 stringByReplacingOccurrencesOfString:@"&lt;" withString:@"<"];
    NSString *output3 = [output2 stringByReplacingOccurrencesOfString:@"&gt;" withString:@">"];
    return output3;
}

// --------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------
+ (NSString *) formatElapsedTime:(int)elapsedTime {
    return [TPUtil formatElapsedTime:elapsedTime :TRUE];
}

// --------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------
+ (NSString *) formatElapsedTime:(int)elapsedTime :(BOOL)withUnits {
    
    if (withUnits)
    {
        if (elapsedTime < 60) {
            return [NSString stringWithFormat: @"%d:%02d sec", elapsedTime/60, elapsedTime%60];
        } else {
            return [NSString stringWithFormat: @"%d:%02d min", elapsedTime/60, elapsedTime%60];
        }
    }
    else
    {
        return [NSString stringWithFormat: @"%d:%02d", elapsedTime/60, elapsedTime%60];
    }
}

// --------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------
+ (UIImage *)thumbnailFromImage:(UIImage *)image scaledToSize:(CGSize)newSize {
    UIGraphicsBeginImageContext(newSize);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();    
    UIGraphicsEndImageContext();
    return newImage;
}

// --------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------
+ (UIImage *)imageRotatedByDegrees:(UIImage *)image :(CGFloat)degrees :(BOOL)flipped
{   
    // calculate the size of the rotated view's containing box for our drawing space
    UIView *rotatedViewBox = [[UIView alloc] initWithFrame:CGRectMake(0,0,image.size.width, image.size.height)];
    CGAffineTransform t = CGAffineTransformMakeRotation(degrees* M_PI/180);
    rotatedViewBox.transform = t;
    CGSize rotatedSize = rotatedViewBox.frame.size;
    [rotatedViewBox release];
    
    // Create the bitmap context
    UIGraphicsBeginImageContext(rotatedSize);
    CGContextRef bitmap = UIGraphicsGetCurrentContext();
    
    // Move the origin to the middle of the image so we will rotate and scale around the center.
    CGContextTranslateCTM(bitmap, rotatedSize.width/2, rotatedSize.height/2);
    
    // Rotate the image context
    CGContextRotateCTM(bitmap, degrees* M_PI/180);
    
    // Now, draw the rotated/scaled image into the context
    if (flipped)
    {
        CGContextScaleCTM(bitmap, 1.0, 1.0);
    }
    else
    {
        CGContextScaleCTM(bitmap, 1.0, -1.0);
    }
    CGContextDrawImage(bitmap, CGRectMake(-image.size.width / 2, -image.size.height / 2, image.size.width, image.size.height), [image CGImage]);
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
    
}

// --------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------
+ (BOOL)isCameraAvailableOnTheDevice {
    return [UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypeCamera];
}

// =============================== String Methods =======================================

// --------------------------------------------------------------------------------------
// escapeQuote - escapes single quotes in a string to make safe for insertion in database
// and truncates to max length.  Handles truncation case where single quotes add to string
// length--does well except for case of very short maxLen and many quotes.
// --------------------------------------------------------------------------------------
+ (NSString *) escapeQuote:(NSString *)input maxLen:(int)maxLen {
    if (input == nil || input.length == 0) return @"";
    NSString *truncString = [TPUtil stringTruncate:input maxLen:maxLen];
    NSString *finalString;
    int num_quotes = [[truncString componentsSeparatedByString:@"'"] count] - 1;
    if (num_quotes > 0) {
        int newSize = maxLen - num_quotes;
        if (newSize <= 0) return @"";
        finalString = [TPUtil stringTruncate:truncString maxLen:newSize];
    } else {
        return truncString;
    }
    return [finalString stringByReplacingOccurrencesOfString:@"'" withString:@"''"];
}

// --------------------------------------------------------------------------------------
// stringTruncate - truncate a string to a given length
// --------------------------------------------------------------------------------------
+ (NSString *)stringTruncate:(NSString *)input maxLen:(int)maxLen {
    if (input == nil) return @"";
    if ([input length] <= maxLen) return input;
    return [input substringToIndex:maxLen];
}

// --------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------
+ (BOOL)shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)string maxLength:(int)maxLen {
    
	// Check that string length is under max length
    if (range.location >= maxLen) return NO;
	
	// check for valid characters
	NSCharacterSet *cs = [[NSCharacterSet characterSetWithCharactersInString:TPLEGALCHARACTERS] invertedSet];
    NSString *filtered = [[string componentsSeparatedByCharactersInSet:cs] componentsJoinedByString:@""];
    return [string isEqualToString:filtered];
}

// --------------------------------------------------------------------------------------
// isPortraitOrientation - hide implementation in case it changes over time within iOS.
// One must be careful when to call this--do not call prior to the final rotated
// position, such as during willRotateToInterfaceOrientation.
// --------------------------------------------------------------------------------------
+ (BOOL)isPortraitOrientation {
    return UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation]);
}

@end
