//
//  TPRubricQCellMultiSelectCumulative.m
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
#import "TPRubricQCellMultiSelectCumulative.h"
#import "TPUtil.h"
#import "TPCompat.h"

// --------------------------------------------------------------------------------------
// TPRubricQCellMultiSelectCumulative - return content of table cell for uni-/multiselect question
// --------------------------------------------------------------------------------------
@implementation TPRubricQCellMultiSelectCumulative

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
        canEdit = [viewDelegate.model userCanEditQuestion:question];
        showAnnotation = FALSE;
        annotEditable = NO;
        
        // configuration of cell
        BOOL isCellEditable = YES;
        BOOL isRubricEditable = [viewDelegate.model isRubricEditable:question.rubric_id];
        BOOL isQuestionEditable = [question isQuestionEditable];
        if ( !isQuestionEditable || !isRubricEditable) {
            isCellEditable = NO;
        }
        
        // Set cell properties
		self.accessoryType = UITableViewCellAccessoryNone;
        self.contentView.frame = CGRectMake(0, 0, TP_QUESTION_CELL_WIDTH, 300);
        
        [self.contentView setStyle:[TPStyle styleWithDictionary:question.style]];
		
		// Create category
        /*
		 category = [[UILabel alloc] initWithFrame:CGRectMake(TP_QUESTION_CELL_WIDTH_EFFECTIVE - 490, 10, 500, 20)];
		 //category.text = ((TPCategory*)[viewDelegate.model.category_array objectAtIndex:question.category]).name;
		 category.text = [viewDelegate.model getCategoryById:question.category].name;
		 category.backgroundColor = self.contentView.backgroundColor?self.contentView.backgroundColor:[UIColor whiteColor];
		 category.font = [UIFont fontWithName:@"Helvetica-Oblique" size:14.0];
		 category.textAlignment = UITextAlignmentRight;
         */
        
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
		
		constSize = CGSizeMake(TP_QUESTION_CELL_WIDTH_EFFECTIVE, 300);
		
        // Create prompt text
        if (![question.prompt isEqualToString:@""]) {
            textSize = [question.prompt sizeWithFont:[UIFont fontWithName:@"Helvetica" size:16.0]
                                   constrainedToSize:constSize
                                       lineBreakMode:TPLineBreakByWordWrapping];
            prompt = [[UILabel alloc] initWithFrame:CGRectMake(10,
                                                               title.frame.origin.y + title.frame.size.height + TP_QUESTION_BEFORE_PROMPT_MARGIN,
                                                               TP_QUESTION_CELL_WIDTH_EFFECTIVE,
                                                               textSize.height)];
            prompt.text = question.prompt;
            prompt.font = [UIFont fontWithName:@"Helvetica" size:16.0];
            prompt.numberOfLines = 0;
            prompt.lineBreakMode = TPLineBreakByWordWrapping;
            prompt.userInteractionEnabled = NO;
            prompt.backgroundColor = [UIColor clearColor];
            [prompt setStyle:[TPStyle styleWithDictionary:question.prompt_style]];
            [self.contentView addSubview:prompt];
        }
        
		// Create no answers text
		noAnswers = [[UILabel alloc] initWithFrame:CGRectMake(10, title.frame.origin.y + title.frame.size.height + 5, TP_QUESTION_CELL_WIDTH_EFFECTIVE, 20)];
		noAnswers.text = @"No data has been recorded";
        noAnswers.backgroundColor = [UIColor clearColor];
		noAnswers.font = [UIFont fontWithName:@"Helvetica-Oblique" size:15.0];
		noAnswers.textAlignment = TPTextAlignmentLeft;
        [self.contentView addSubview:noAnswers];
		
		if (prompt) {
            multiSelect = [[TPRubricQMultiSelectCumulativeTable alloc] initWithView:mainview
                                                                           question:somequestion
                                                                              frame:CGRectMake(10,
                                                                                               prompt.frame.origin.y + prompt.frame.size.height + TP_QUESTION_AFTER_PROMPT_MARGIN,
                                                                                               TP_QUESTION_CELL_WIDTH_EFFECTIVE,
                                                                                               500)];
        } else {
            multiSelect = [[TPRubricQMultiSelectCumulativeTable alloc] initWithView:mainview
                                                                           question:somequestion
                                                                              frame:CGRectMake(10,
                                                                                               title.frame.origin.y + title.frame.size.height + TP_QUESTION_AFTER_PROMPT_MARGIN,
                                                                                               TP_QUESTION_CELL_WIDTH_EFFECTIVE,
                                                                                               500)];
        }
        if (!isCellEditable) [multiSelect setUserInteractionEnabled:NO];
        [self.contentView addSubview:multiSelect];
		
        int buttonsBaseY = multiSelect.frame.origin.y + multiSelect.frame.size.height;
        
        CGSize newTextSize = [[viewDelegate.model questionAnnot:question] sizeWithFont:[UIFont fontWithName:@"Helvetica" size:15.0]
                                                                     constrainedToSize:constSize
                                                                         lineBreakMode:TPLineBreakByWordWrapping];
        annotText = [[UITextView alloc] initWithFrame:CGRectMake(10, buttonsBaseY + TP_QUESTION_BUTTON_TOP_MARGIN, TP_QUESTION_CELL_WIDTH_EFFECTIVE, (newTextSize.height + 20)>TP_QUESTION_TYPE_TEXT_TEXTVIEW_HEIGHT?(newTextSize.height + 20):TP_QUESTION_TYPE_TEXT_TEXTVIEW_HEIGHT)];
        annotText.text = [viewDelegate.model questionAnnot:question];
        annotText.editable = [viewDelegate.model userCanEditQuestion:question];
        annotText.layer.borderWidth = 1;
        annotText.layer.borderColor = [[UIColor lightGrayColor] CGColor];
        annotText.font = [UIFont fontWithName:@"Helvetica" size:15.0];
        annotText.userInteractionEnabled = YES;
        annotText.delegate = self;
        showAnnotation = (question.annotation && ([annotText.text length] != 0));
        [annotText setHidden:!showAnnotation];
        if (!isCellEditable) [annotText setUserInteractionEnabled:NO];
        [self.contentView addSubview:annotText];
        
        if (question.annotation) {
            annotButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
            [annotButton setFrame:CGRectMake(TP_QUESTION_CELL_WIDTH_EFFECTIVE - 160, buttonsBaseY + TP_QUESTION_BUTTON_TOP_MARGIN, 80, 30)];
            [annotButton addTarget:self action:@selector(toggleAnnotAction:) forControlEvents:UIControlEventTouchUpInside];
            [annotButton setTitle:@"Annotate" forState:UIControlStateNormal];
            [self.contentView addSubview:annotButton];
        }
        compressor = [[UIImageView alloc] initWithFrame:CGRectMake(TP_QUESTION_CELL_WIDTH_EFFECTIVE - 65, buttonsBaseY + TP_QUESTION_BUTTON_TOP_MARGIN, 30, 30)];
		compressor.image = [UIImage imageNamed:@"compress_sm_flat.png"];
		[self.contentView addSubview:compressor];
		
		compressButton = [[UIButton alloc] initWithFrame:CGRectMake(TP_QUESTION_CELL_WIDTH_EFFECTIVE - 65, buttonsBaseY + TP_QUESTION_BUTTON_TOP_MARGIN, 30, 30)];
		[compressButton addTarget:self action:@selector(buttonPressedAction:) forControlEvents:UIControlEventTouchUpInside];
		[self.contentView addSubview:compressButton];
		
		// scroll to top button and image
        if (!isLast) {
            nextButton = [[UIButton alloc] initWithFrame:CGRectMake(TP_QUESTION_CELL_WIDTH_EFFECTIVE - 20, buttonsBaseY + TP_QUESTION_BUTTON_TOP_MARGIN, 30, 30)];
            nextImage = [UIImage imageNamed:@"downarrow_sm_flat.png"];
            [nextButton setImage:nextImage forState:UIControlStateNormal];
            [nextButton addTarget:self action:@selector(scrollToNextAction) forControlEvents:UIControlEventTouchUpInside];
            [self.contentView addSubview:nextButton];
        }
        
        [self updateUI];
    }
    return self;
}

// --------------------------------------------------------------------------------------
- (void) dealloc {
    [title release];
    if (prompt) {
        [prompt release];
        prompt = NULL;
    }
	[multiSelect release];
	if (nextButton) {
		[nextButton release];
		nextButton = 0;
	}
    [super dealloc];
}

// --------------------------------------------------------------------------------------
- (void) buttonPressedAction:(id)sender {
	[self setCompressState:multiSelect.showAnswers :FALSE];
}

// --------------------------------------------------------------------------------------
- (void) setCompressState:(BOOL)compress :(BOOL)outline {
    [multiSelect setAnswers:!compress];
}

// --------------------------------------------------------------------------------------
- (void) recalculateCellGeometryForCellWidth:(int)aCellWidth {
    // title
    CGSize constSize = CGSizeMake(aCellWidth, 1000);
    CGSize textSize = [question.title sizeWithFont:[UIFont fontWithName:@"Helvetica-Bold" size:18.0]
                                 constrainedToSize:constSize
                                     lineBreakMode:TPLineBreakByWordWrapping];
    [title setFrame:CGRectMake(10, TP_QUESTION_BEFORE_QUESTION_MARGIN, aCellWidth, textSize.height)];
    
    // prompt
    if (prompt) {
        constSize = CGSizeMake(aCellWidth, 300);
        textSize = [question.prompt sizeWithFont:[UIFont fontWithName:@"Helvetica" size:16.0]
                               constrainedToSize:constSize
                                   lineBreakMode:TPLineBreakByWordWrapping];
        [prompt setFrame:CGRectMake(10,
                                    title.frame.origin.y + title.frame.size.height + TP_QUESTION_BEFORE_PROMPT_MARGIN,
                                    aCellWidth,
                                    textSize.height)];
    }
    
    // multiSelect
    CGRect tableFrame = [multiSelect frame];
    tableFrame.size.width = aCellWidth;
    [multiSelect setFrame:tableFrame];
    
    if (multiSelect.showAnswers) {
		compressor.image = [UIImage imageNamed:@"compress_sm_flat.png"];
        if (prompt) {
            [prompt setHidden:FALSE];
            tableFrame.origin.y = prompt.frame.origin.y + prompt.frame.size.height + TP_QUESTION_AFTER_PROMPT_MARGIN;
        } else {
            tableFrame.origin.y = title.frame.origin.y + title.frame.size.height + TP_QUESTION_AFTER_PROMPT_MARGIN;
        }
	} else {
		compressor.image = [UIImage imageNamed:@"uncompress_sm_flat.png"];
        if (prompt) {
            [prompt setHidden:TRUE];
        }
        tableFrame.origin.y = title.frame.origin.y + title.frame.size.height + TP_QUESTION_AFTER_PROMPT_MARGIN;
	}
    [multiSelect setFrame:tableFrame];
	
	int buttonsBaseY;
	if (multiSelect.showAnswers || ![multiSelect shouldDisableCollapsing]) {
        [noAnswers setHidden:TRUE];
		buttonsBaseY = multiSelect.frame.origin.y + multiSelect.tableHeight;
	} else {
        [noAnswers setHidden:FALSE];
		buttonsBaseY = noAnswers.frame.origin.y + noAnswers.frame.size.height;
	}
    // annotation text
    if (question.annotation) {
        if (showAnnotation) {
            CGSize constSize = CGSizeMake(aCellWidth, 1000);
            CGSize newTextSize = [[viewDelegate.model questionAnnot:question] sizeWithFont:[UIFont fontWithName:@"Helvetica" size:15.0] constrainedToSize:constSize lineBreakMode:TPLineBreakByWordWrapping];
            if (annotEditable) {
                [annotText setFrame:CGRectMake(10,
                                               buttonsBaseY + TP_QUESTION_BUTTON_TOP_MARGIN,
                                               aCellWidth,
                                               (newTextSize.height + 20)>TP_QUESTION_TYPE_TEXT_TEXTVIEW_HEIGHT_EDITED?(newTextSize.height + 20):TP_QUESTION_TYPE_TEXT_TEXTVIEW_HEIGHT_EDITED)];
            } else {
                [annotText setFrame:CGRectMake(10,
                                               buttonsBaseY + TP_QUESTION_BUTTON_TOP_MARGIN,
                                               aCellWidth,
                                               (newTextSize.height + 20)>TP_QUESTION_TYPE_TEXT_TEXTVIEW_HEIGHT?(newTextSize.height + 20):TP_QUESTION_TYPE_TEXT_TEXTVIEW_HEIGHT)];
            }
        }
        [annotText setHidden:!showAnnotation];
        buttonsBaseY = ([annotText isHidden] ? (buttonsBaseY) : (annotText.frame.origin.y + annotText.frame.size.height));
    }
    // annotation button
    if (annotButton) {
        [annotButton setFrame:CGRectMake(aCellWidth - 160, buttonsBaseY + TP_QUESTION_BUTTON_TOP_MARGIN, 80, 30)];
        [annotButton setHidden:showAnnotation];
    }
    // compressor button
    [compressor setFrame:CGRectMake(aCellWidth - 65, buttonsBaseY + TP_QUESTION_BUTTON_TOP_MARGIN, 30, 30)];
    [compressButton setFrame:CGRectMake(aCellWidth - 65, buttonsBaseY + TP_QUESTION_BUTTON_TOP_MARGIN, 30, 30)];
	// next question button
	if (nextButton) {
        [nextButton setFrame:CGRectMake(aCellWidth - 20, buttonsBaseY + TP_QUESTION_BUTTON_TOP_MARGIN, 30, 30)];
	}
	cellHeight = compressButton.frame.origin.y + compressButton.frame.size.height + TP_QUESTION_AFTER_QUESTION_MARGIN;
}

// --------------------------------------------------------------------------------------
- (void) updateUI {
    if ([TPUtil isPortraitOrientation]) {
        [self recalculateCellGeometryForCellWidth:(TP_QUESTION_CELL_WIDTH_EFFECTIVE + 65)];
    } else {
        [self recalculateCellGeometryForCellWidth:(TP_QUESTION_CELL_WIDTH_EFFECTIVE)];
    }
}

@end
