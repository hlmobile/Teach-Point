//
//  TPStyle.m
//  teachpoint
//
//  Created by Dmitriy Doroshenko on 30/11/2011.
//  Copyright (c) 2011 QArea. All rights reserved.
//

#import "TPStyle.h"
#import "TPCompat.h"

@implementation TPStyle

@synthesize styleFlags;
@synthesize fontSize;
@synthesize backgroundColor;
@synthesize textAlignment;

// --------------------------------------------------------------------------------------
- (id)initWithDictionary:(NSDictionary *) dict {
    
    self = [super init];
	if (self != nil) {
        styleFlags.fontSize = FALSE;
        styleFlags.backgroundColor = FALSE;
        styleFlags.textAlignment = FALSE;
        
        fontSize = 0.0f;
        backgroundColor = nil;
        textAlignment = TPTextAlignmentLeft;
        
        for (NSString *key in dict) 
        {
            NSString *value = (NSString *)[dict objectForKey:key];

            if ([key isEqualToString:@"font-size"]) {
                fontSize = [(NSNumber *)value floatValue];
                styleFlags.fontSize = TRUE;
            }
                        
            else if ([key isEqualToString:@"background-color"]) {
                backgroundColor = [self colorWithHexString:(NSString*)value];
                styleFlags.backgroundColor = TRUE;
            }
                        
            else if ([key isEqualToString:@"text-align"]) {
                if ([value isEqualToString:@"center"]) {
                    textAlignment = TPTextAlignmentCenter;
                }
                else if ([value isEqualToString:@"right"]) {
                    textAlignment = TPTextAlignmentRight;
                }
                else {
                    textAlignment = TPTextAlignmentLeft;
                }
                styleFlags.textAlignment = TRUE;
            }
        }
    }
    return self;
}

// --------------------------------------------------------------------------------------
- (UIColor *) colorWithHexString: (NSString *) hex {
    
    NSString *cString = [[hex stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];  
    
    if ([cString length] < 6) return [UIColor grayColor];  
    
    // strip 0X if it appears  
    if ([cString hasPrefix:@"0X"]) cString = [cString substringFromIndex:2];  
    
    if ([cString hasPrefix:@"#"]) cString = [cString substringFromIndex:1]; 
    
    if ([cString length] != 6) return  [UIColor grayColor];  
    
    // Separate into r, g, b substrings  
    NSRange range;  
    range.location = 0;  
    range.length = 2;  
    NSString *rString = [cString substringWithRange:range];  
    
    range.location = 2;  
    NSString *gString = [cString substringWithRange:range];  
    
    range.location = 4;  
    NSString *bString = [cString substringWithRange:range];  
    
    // Scan values  
    unsigned int r, g, b;  
    [[NSScanner scannerWithString:rString] scanHexInt:&r];  
    [[NSScanner scannerWithString:gString] scanHexInt:&g];  
    [[NSScanner scannerWithString:bString] scanHexInt:&b];  
    
    return [UIColor colorWithRed:((float) r / 255.0f)  
                           green:((float) g / 255.0f)  
                            blue:((float) b / 255.0f)  
                           alpha:1.0f];  
} 

// --------------------------------------------------------------------------------------
- (void)dealloc {
    [super dealloc];
}

// --------------------------------------------------------------------------------------
+ (id)styleWithDictionary:(NSDictionary *) dict {
    return [[[TPStyle alloc] initWithDictionary:dict] autorelease];
}

@end


// --------------------------------------------------------------------------------------
// extension to UILabel with support of CSS styling
// --------------------------------------------------------------------------------------
@implementation UILabel (TPStyle)

// --------------------------------------------------------------------------------------
- (void)setStyle:(TPStyle *)style {
    
    if (style.styleFlags.fontSize) {
        
        UIFont *font = [[self font] fontWithSize:style.fontSize];
        [self setFont:font];
        
        CGRect currentFrame = self.frame;        
        CGSize constSize = CGSizeMake(currentFrame.size.width, 1000);
        CGSize customLabelSize = [self.text sizeWithFont:font
                                       constrainedToSize:constSize 
                                           lineBreakMode:TPLineBreakByWordWrapping];

        currentFrame.size.height = customLabelSize.height;
        [self setFrame:currentFrame];
    }
       
    if (style.styleFlags.textAlignment) {
        [self setTextAlignment:style.textAlignment];
    }
}

@end

// --------------------------------------------------------------------------------------
// extension to UIView with support of CSS styling
// --------------------------------------------------------------------------------------
@implementation UIView (TPStyle)

// --------------------------------------------------------------------------------------
- (void)setStyle:(TPStyle *)style {
    
    if (style.styleFlags.backgroundColor) {
        [self setBackgroundColor:style.backgroundColor];
    }
}

@end
