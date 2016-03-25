//
//  TPRubricQCellInstructions.m
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
#import "TPRubricQCellInstructions.h"
#import "TPUtil.h"
#import "TPCompat.h"
#import "TPAttachListVC.h" //jxi

// --------------------------------------------------------------------------------------
// TPRubricQCellInstructions - return content of table cell for heading question
// --------------------------------------------------------------------------------------
@implementation TPRubricQCellInstructions

// --------------------------------------------------------------------------------------
- (id) initWithView:(TPView *)mainview
              style:(UITableViewCellStyle)style
    reuseIdentifier:(NSString *)reuseIdentifier
           question:(TPQuestion *)somequestion
             isLast:(BOOL)isLast {
    
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self != nil) {
        
        viewDelegate = mainview;
        question = somequestion;
        
		// Set cell properties
		self.accessoryType = UITableViewCellAccessoryNone;
		self.contentView.frame = CGRectMake(0, 0, TP_QUESTION_CELL_WIDTH, 300);
		
        [self.contentView setStyle:[TPStyle styleWithDictionary:question.style]];
        cellHeight = self.frame.size.height + TP_QUESTION_AFTER_QUESTION_MARGIN;
        
		if ([question.title length]) {
			CGSize constSize = CGSizeMake(TP_QUESTION_CELL_WIDTH_EFFECTIVE, 1000);
			CGSize textSize = [question.title sizeWithFont:[UIFont fontWithName:@"Helvetica-Bold" size:22.0]
										 constrainedToSize:constSize
											 lineBreakMode:TPLineBreakByWordWrapping];
			
			
			title = [[UILabel alloc] initWithFrame:CGRectMake(10, TP_QUESTION_BEFORE_QUESTION_MARGIN, TP_QUESTION_CELL_WIDTH_EFFECTIVE, textSize.height)];
			title.text = question.title;
			title.numberOfLines = 0;
			title.lineBreakMode = TPLineBreakByWordWrapping;
			title.backgroundColor = [UIColor clearColor];
			title.font = [UIFont fontWithName:@"Helvetica-Bold" size:22.0];
			title.textAlignment = TPTextAlignmentLeft;
            [title setStyle:[TPStyle styleWithDictionary:question.title_style]];
			[self.contentView addSubview:title];
			cellHeight = title.frame.origin.y + prompt.frame.size.height + TP_QUESTION_AFTER_QUESTION_MARGIN;
		}
		
		CGSize constSize = CGSizeMake(TP_QUESTION_CELL_WIDTH_EFFECTIVE, 1000);
        
        // Create prompt text
		if (question.prompt) {
            CGSize textSize = [question.prompt sizeWithFont:[UIFont fontWithName:@"Helvetica" size:16.0]
                                          constrainedToSize:constSize
                                              lineBreakMode:TPLineBreakByWordWrapping];
            
            prompt = [[UILabel alloc] initWithFrame:CGRectMake(10,
                                                               [question.title length]?(title.frame.origin.y + title.frame.size.height + TP_QUESTION_BEFORE_PROMPT_MARGIN):TP_QUESTION_BEFORE_PROMPT_MARGIN/*12*/,
                                                               TP_QUESTION_CELL_WIDTH_EFFECTIVE,
                                                               textSize.height)];
            prompt.text = question.prompt;
            prompt.numberOfLines = 0;
            prompt.lineBreakMode = TPLineBreakByWordWrapping;
            prompt.font = [UIFont fontWithName:@"Helvetica" size:16.0];
            prompt.userInteractionEnabled = NO;
            prompt.textAlignment = TPTextAlignmentLeft;
            prompt.backgroundColor = [UIColor clearColor];
            [prompt setStyle:[TPStyle styleWithDictionary:question.prompt_style]];
            [self.contentView addSubview:prompt];
            cellHeight = prompt.frame.origin.y + prompt.frame.size.height + 10;
        }
        
        //jxi; Add attchlist button
        attachlistButton = [[UIButton alloc] initWithFrame:CGRectMake(TP_QUESTION_CELL_WIDTH_EFFECTIVE - 20, cellHeight, 30, 30)];
        attachlistImage = [UIImage imageNamed:@"paperclip.png"];
        [attachlistButton setImage:attachlistImage forState:UIControlStateNormal];
        [attachlistButton addTarget:self action:@selector(showAttachListPO) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:attachlistButton];
        
        //jxi; Add attachment list
        attachListVC = [[TPAttachListVC alloc]initWithViewDelegate:viewDelegate
                                                            parent:self
                                                     containerType:TP_ATTACHLIST_CONTAINER_TYPE_QUESTION
                                              parentFormUserDataID:viewDelegate.model.appstate.userdata_id parentQuestionID:question.question_id];
        attachListVC.view.frame = CGRectMake(10, cellHeight, 320, attachListVC.attachListHeight);
        [self.contentView addSubview:attachListVC.view];
        
        [self updateUI];
    }
    return self;
}

// --------------------------------------------------------------------------------------
- (void) dealloc {
	if (title) {
		[title release];
		title = NULL;
	}
    if (prompt) {
        [prompt release];
        prompt = NULL;
    }
    [super dealloc];
}

// --------------------------------------------------------------------------------------
- (void) recalculateCellGeometryForCellWidth:(int)aCellWidth {
    // title
    CGSize constSize = CGSizeMake(aCellWidth, 1000);
    if (title) {
        CGSize textSize = [question.title sizeWithFont:[UIFont fontWithName:@"Helvetica-Bold" size:22.0]
                                     constrainedToSize:constSize
                                         lineBreakMode:TPLineBreakByWordWrapping];
        [title setFrame:CGRectMake(10, TP_QUESTION_BEFORE_QUESTION_MARGIN, aCellWidth, textSize.height)];
    }
    // prompt
    if (prompt) {
        CGSize textSize = [question.prompt sizeWithFont:[UIFont fontWithName:@"Helvetica" size:16.0]
                                      constrainedToSize:constSize
                                          lineBreakMode:TPLineBreakByWordWrapping];
        [prompt setFrame:CGRectMake(10,
                                    [question.title length]?(title.frame.origin.y + title.frame.size.height + TP_QUESTION_BEFORE_PROMPT_MARGIN):TP_QUESTION_BEFORE_PROMPT_MARGIN/*12*/,
                                    aCellWidth,
                                    textSize.height)];
    }
    // cell height calculation
    if (prompt) {
        cellHeight = prompt.frame.origin.y + prompt.frame.size.height + TP_QUESTION_AFTER_QUESTION_MARGIN;
    } else if (title) {
        cellHeight = title.frame.origin.y + title.frame.size.height + TP_QUESTION_AFTER_QUESTION_MARGIN;
    } else {
        cellHeight = self.frame.origin.y + self.frame.size.height + TP_QUESTION_AFTER_QUESTION_MARGIN;
    }
    
    // jxi;
    [attachlistButton setFrame:CGRectMake(aCellWidth - 20, cellHeight, 30, 30)];
    attachListVC.view.frame = CGRectMake(10, cellHeight, 320, attachListVC.attachListHeight);
    
    if (attachListVC.attachListHeight > attachlistButton.frame.size.height)
        cellHeight = attachListVC.view.frame.origin.y + attachListVC.attachListHeight + TP_QUESTION_AFTER_QUESTION_MARGIN;
    else
        cellHeight = attachlistButton.frame.origin.y + attachlistButton.frame.size.height + TP_QUESTION_AFTER_QUESTION_MARGIN;
}

// --------------------------------------------------------------------------------------
-(void) updateUI {
    if ([TPUtil isPortraitOrientation]) {
        [self recalculateCellGeometryForCellWidth:(TP_QUESTION_CELL_WIDTH_EFFECTIVE + 65)];
    } else {
        [self recalculateCellGeometryForCellWidth:(TP_QUESTION_CELL_WIDTH_EFFECTIVE)];
    }
}

@end
