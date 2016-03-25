//
//  TPRubricQCellHeading.m
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
#import "TPRubricQCellHeading.h"
#import "TPCompat.h"

// --------------------------------------------------------------------------------------
// TPRubricQCellHeading - return content of table cell for heading question
// --------------------------------------------------------------------------------------
@implementation TPRubricQCellHeading

// --------------------------------------------------------------------------------------
- (id) initWithView:(TPView *)mainview
              style:(UITableViewCellStyle)style
    reuseIdentifier:(NSString *)reuseIdentifier
           question:(TPQuestion *)somequestion {
    
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self != nil) {
        
        viewDelegate = mainview;
        question = somequestion;
        
        // Set cell properties
		self.accessoryType = UITableViewCellAccessoryNone;
        self.contentView.frame = CGRectMake(0, 0, TP_QUESTION_CELL_WIDTH, 300);
        
        [self.contentView setStyle:[TPStyle styleWithDictionary:question.style]];
        
		CGSize constSize = CGSizeMake(TP_QUESTION_CELL_WIDTH_EFFECTIVE, 1000);
		CGSize textSize = [question.title sizeWithFont:[UIFont fontWithName:@"Helvetica-Bold" size:26.0]
									 constrainedToSize:constSize
										 lineBreakMode:TPLineBreakByWordWrapping];
		
		
		title = [[UILabel alloc] initWithFrame:CGRectMake(10, TP_QUESTION_BEFORE_QUESTION_MARGIN, TP_QUESTION_CELL_WIDTH_EFFECTIVE, textSize.height)];
		title.text = question.title;
		title.numberOfLines = 0;
		title.lineBreakMode = TPLineBreakByWordWrapping;
        title.backgroundColor = [UIColor clearColor];
		title.font = [UIFont fontWithName:@"Helvetica-Bold" size:26.0];
		title.textAlignment = TPTextAlignmentLeft;
        [title setStyle:[TPStyle styleWithDictionary:question.title_style]];
		[self.contentView addSubview:title];
		cellHeight = title.frame.origin.y + title.frame.size.height + TP_QUESTION_AFTER_QUESTION_MARGIN;
        
		// scroll to top button and image
        /*
         nextButton = [[UIButton alloc] initWithFrame:CGRectMake(TP_QUESTION_CELL_WIDTH_EFFECTIVE - 20, title.frame.origin.y + title.frame.size.height + 10, 30, 30)];
         nextImage = [UIImage imageNamed:@"downarrow_sm_flat.png"];
         [nextButton setImage:nextImage forState:UIControlStateNormal];
         [nextButton addTarget:self action:@selector(scrollToNextAction) forControlEvents:UIControlEventTouchUpInside];
         [self.contentView addSubview:nextButton];
         cellHeight = nextButton.frame.origin.y + nextButton.frame.size.height + 10;
         */
        
    }
    return self;
}

// --------------------------------------------------------------------------------------
- (void) dealloc {
    [title release];
    [super dealloc];
}

@end
