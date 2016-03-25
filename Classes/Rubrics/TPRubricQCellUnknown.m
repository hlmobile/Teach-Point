//
//  TPRubricQCellUnknown.m
//  teachpoint
//
//  Created by Chris Dunn on 9/29/12.
//
//

#import <QuartzCore/QuartzCore.h>
#import "TPData.h"
#import "TPView.h"
#import "TPStyle.h"
#import "TPModel.h"
#import "TPRubrics.h"
#import "TPRubricQCellUnknown.h"
#import "TPUtil.h"
#import "TPCompat.h"

// --------------------------------------------------------------------------------------
// TPRubricQCellUnknown - return content of tabele cell for question of unknown type
// --------------------------------------------------------------------------------------
@implementation TPRubricQCellUnknown

- (id)initWithView:(TPView *)mainview
             style:(UITableViewCellStyle)style
   reuseIdentifier:(NSString *)reuseIdentifier
          question:(TPQuestion *)somequestion
            isLast:(BOOL)isLast {
    
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self != nil) {
        
        viewDelegate = mainview;
        question = somequestion;
        
        // Create title
		CGSize constSize = CGSizeMake(TP_QUESTION_CELL_WIDTH_EFFECTIVE, 1000);
		CGSize textSize = [question.title sizeWithFont:[UIFont fontWithName:@"Helvetica-Bold" size:18.0]
									 constrainedToSize:constSize
										 lineBreakMode:TPLineBreakByWordWrapping];
		
		title = [[UILabel alloc] initWithFrame:CGRectMake(10, TP_QUESTION_BEFORE_QUESTION_MARGIN, TP_QUESTION_CELL_WIDTH_EFFECTIVE, textSize.height)];
		title.text = question.title;
		title.numberOfLines = 0;
		title.lineBreakMode = TPLineBreakByWordWrapping;
        title.backgroundColor = [UIColor clearColor];
		title.font = [UIFont fontWithName:@"Helvetica-Bold" size:18.0];
		title.textAlignment = TPTextAlignmentLeft;
        [title setStyle:[TPStyle styleWithDictionary:question.title_style]];
        [self.contentView addSubview:title];
        
        // Create "need update" text
        needUpdateLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, title.frame.origin.y + title.frame.size.height + TP_QUESTION_BEFORE_PROMPT_MARGIN, TP_QUESTION_CELL_WIDTH_EFFECTIVE, 25)];
        needUpdateLabel.font = [UIFont fontWithName:@"Helvetica" size:14];
        needUpdateLabel.textColor = [UIColor redColor];
        needUpdateLabel.backgroundColor = [UIColor clearColor];
        needUpdateLabel.text = @"Question not supported in current version. Please check for updates.";
        [self.contentView addSubview:needUpdateLabel];
        
        cellHeight = needUpdateLabel.frame.origin.y + needUpdateLabel.frame.size.height + TP_QUESTION_AFTER_QUESTION_MARGIN;
        int buttonsBaseY = needUpdateLabel.frame.origin.y + needUpdateLabel.frame.size.height + 10;
        
        // Create "next" button
        if (!isLast) {
            nextButton = [[UIButton alloc] initWithFrame:CGRectMake(TP_QUESTION_CELL_WIDTH_EFFECTIVE - 20, buttonsBaseY + TP_QUESTION_BUTTON_TOP_MARGIN, 30, 30)];
            nextImage = [UIImage imageNamed:@"downarrow_sm_flat.png"];
            [nextButton setImage:nextImage forState:UIControlStateNormal];
            [nextButton addTarget:self action:@selector(scrollToNextAction) forControlEvents:UIControlEventTouchUpInside];
            [self.contentView addSubview:nextButton];
            cellHeight = nextButton.frame.origin.y + nextButton.frame.size.height + TP_QUESTION_AFTER_QUESTION_MARGIN;
        }
    }
    
    [self updateUI];
    
    return self;
}

// --------------------------------------------------------------------------------------
- (void) dealloc {
    [needUpdateLabel release];
    [super dealloc];
}

// --------------------------------------------------------------------------------------
- (void) updateUI {
    if ([TPUtil isPortraitOrientation]) {
        [self recalculateCellGeometryForCellWidth:(TP_QUESTION_CELL_WIDTH_EFFECTIVE + 65)];
    } else {
        [self recalculateCellGeometryForCellWidth:(TP_QUESTION_CELL_WIDTH_EFFECTIVE)];
    }
}

// --------------------------------------------------------------------------------------
- (void) recalculateCellGeometryForCellWidth:(int)aCellWidth {
    // title
    CGSize constSize = CGSizeMake(aCellWidth, 1000);
    CGSize textSize = [question.title sizeWithFont:[UIFont fontWithName:@"Helvetica-Bold" size:18.0]
                                 constrainedToSize:constSize
                                     lineBreakMode:TPLineBreakByWordWrapping];
    [title setFrame:CGRectMake(10, TP_QUESTION_BEFORE_QUESTION_MARGIN, aCellWidth, textSize.height)];
    
    // date text field on the same place
    [needUpdateLabel setFrame:CGRectMake(10, title.frame.origin.y + title.frame.size.height + TP_QUESTION_BEFORE_PROMPT_MARGIN, aCellWidth, 25)];
    // next button
    int buttonsBaseY = needUpdateLabel.frame.origin.y + needUpdateLabel.frame.size.height + 10;
    if (nextButton) {
        [nextButton setFrame:CGRectMake(aCellWidth - 20, buttonsBaseY + TP_QUESTION_BUTTON_TOP_MARGIN, 30, 30)];
        cellHeight = nextButton.frame.origin.y + nextButton.frame.size.height + TP_QUESTION_AFTER_QUESTION_MARGIN;
    } else {
        cellHeight = needUpdateLabel.frame.origin.y + needUpdateLabel.frame.size.height + TP_QUESTION_AFTER_QUESTION_MARGIN;
    }
}

@end
