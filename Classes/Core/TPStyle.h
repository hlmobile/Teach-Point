//
//  TPStyle.h
//  teachpoint
//
//  Created by Dmitriy Doroshenko on 30/11/2011.
//  Copyright (c) 2011 QArea. All rights reserved.
//

typedef struct {
    BOOL fontSize:TRUE;
    BOOL backgroundColor:TRUE;
    BOOL textAlignment:TRUE;
} TPStyleFlags;

@interface TPStyle: NSObject {
}

@property (readonly, nonatomic) TPStyleFlags styleFlags;
@property (readonly, nonatomic) float fontSize;
@property (readonly, nonatomic) UIColor *backgroundColor;
@property (readonly, nonatomic) UITextAlignment textAlignment;

- (id)initWithDictionary:(NSDictionary *) dict;
+ (id)styleWithDictionary:(NSDictionary *) dict;

- (UIColor *) colorWithHexString: (NSString *) hex;

@end

@interface UIView (TPStyle)
- (void)setStyle:(TPStyle *)style;
@end

@interface UILabel (TPStyle)
- (void)setStyle:(TPStyle *)style;
@end