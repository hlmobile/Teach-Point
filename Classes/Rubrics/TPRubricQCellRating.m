//
//  TPRubricQCellRating.m
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
#import "TPRubricQCellRating.h"
#import "TPUtil.h"
#import "TPCompat.h"
#import "TPAttachListVC.h" //jxi

// --------------------------------------------------------------------------------------
// TPRubricQCellRating - return content of table cell for rubric question
// --------------------------------------------------------------------------------------
@implementation TPRubricQCellRating

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
        
		// Create title
		CGSize constSize = CGSizeMake(TP_QUESTION_CELL_WIDTH_EFFECTIVE, 1000);
		CGSize textSize = [question.title sizeWithFont:[UIFont fontWithName:@"Helvetica-Bold" size:18.0]
									 constrainedToSize:constSize
										 lineBreakMode:TPLineBreakByWordWrapping];
		
		
        title = [[UILabel alloc] initWithFrame:CGRectMake(10, TP_QUESTION_BEFORE_QUESTION_MARGIN, TP_QUESTION_CELL_WIDTH_EFFECTIVE, textSize.height)];
		title.text = question.title;
        title.textColor = [TPRubricQCell getTextColor:canEdit];
		title.numberOfLines = 0;
		title.lineBreakMode = TPLineBreakByWordWrapping;
        title.backgroundColor = [UIColor clearColor];
		title.font = [UIFont fontWithName:@"Helvetica-Bold" size:18.0];
		title.textAlignment = TPTextAlignmentLeft;
        [title setStyle:[TPStyle styleWithDictionary:question.title_style]];
        [self.contentView addSubview:title];
		
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
        
        // rating table
        if (prompt) {
            rating = [[TPRubricQRatingTable alloc] initWithView:viewDelegate question:question frame:CGRectMake(10, prompt.frame.origin.y + prompt.frame.size.height + TP_QUESTION_AFTER_PROMPT_MARGIN, TP_QUESTION_CELL_WIDTH_EFFECTIVE, 200)];
        } else {
            rating = [[TPRubricQRatingTable alloc] initWithView:viewDelegate question:question frame:CGRectMake(10, title.frame.origin.y + title.frame.size.height + TP_QUESTION_AFTER_PROMPT_MARGIN, TP_QUESTION_CELL_WIDTH_EFFECTIVE, 200)];
        }
        if (!isCellEditable) [rating setUserInteractionEnabled:NO];
        [self.contentView addSubview:rating];
        
        // Create category
		category = [[UILabel alloc] initWithFrame:CGRectMake(10,
                                                             rating.frame.origin.y + rating.frame.size.height + TP_QUESTION_CATEGORY_TOP_MARGIN,
                                                             TP_QUESTION_CELL_WIDTH_EFFECTIVE * 0.75,
                                                             20)];
		category.text = [viewDelegate.model getCategoryById:question.category].name;
        category.backgroundColor = [UIColor clearColor];
		category.font = [UIFont fontWithName:@"Helvetica-Oblique" size:14.0];
		category.textAlignment = TPTextAlignmentLeft;
        [self.contentView addSubview:category];
        
        int buttonsBaseY = rating.frame.origin.y + rating.frame.size.height;
        
        // annotation
        CGSize newTextSize = [[viewDelegate.model questionAnnot:question] sizeWithFont:[UIFont fontWithName:@"Helvetica"
                                                                                                       size:15.0]
                                                                     constrainedToSize:constSize
                                                                         lineBreakMode:TPLineBreakByWordWrapping];
        annotText = [[UITextView alloc] initWithFrame:CGRectMake(10, buttonsBaseY + TP_QUESTION_BUTTON_TOP_MARGIN, TP_QUESTION_CELL_WIDTH_EFFECTIVE, (newTextSize.height + 20) > TP_QUESTION_TYPE_TEXT_TEXTVIEW_HEIGHT ? (newTextSize.height + 20) : TP_QUESTION_TYPE_TEXT_TEXTVIEW_HEIGHT)];
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
            [annotButton setFrame:CGRectMake(TP_QUESTION_CELL_WIDTH_EFFECTIVE - 205, buttonsBaseY + TP_QUESTION_BUTTON_TOP_MARGIN, 80, 30)]; //jxi; origina x: 160;
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
        //cellHeight = compressButton.frame.origin.y + compressButton.frame.size.height + TP_QUESTION_AFTER_QUESTION_MARGIN;
        
        //jxi; Add attchlist button
        attachlistButton = [[UIButton alloc] initWithFrame:CGRectMake(TP_QUESTION_CELL_WIDTH_EFFECTIVE - 110, buttonsBaseY + TP_QUESTION_BUTTON_TOP_MARGIN, 30, 30)];
        attachlistImage = [UIImage imageNamed:@"paperclip.png"];
        [attachlistButton setImage:attachlistImage forState:UIControlStateNormal];
        [attachlistButton addTarget:self action:@selector(showAttachListPO) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:attachlistButton];
        
        //jxi; Add attachment list
        attachListVC = [[TPAttachListVC alloc]initWithViewDelegate:viewDelegate
                                                            parent:self
                                                     containerType:TP_ATTACHLIST_CONTAINER_TYPE_QUESTION
                                              parentFormUserDataID:viewDelegate.model.appstate.userdata_id parentQuestionID:question.question_id];
        attachListVC.view.frame = CGRectMake(10, category.frame.origin.y + category.frame.size.height + TP_QUESTION_BUTTON_TOP_MARGIN, 320, attachListVC.attachListHeight);
        [self.contentView addSubview:attachListVC.view];
        
        [self updateUI];
	}
    return self;
}

// --------------------------------------------------------------------------------------
- (void) dealloc {
    [title release];
	[category release];
    if (prompt) {
        [prompt release];
        prompt = NULL;
    }
	[rating release];
	if (nextButton) {
		[nextButton release];
		nextButton = 0;
	}
    [super dealloc];
}

// --------------------------------------------------------------------------------------
- (void)buttonPressedAction:(id)sender {
	[self setCompressState:rating.showAnswers :FALSE];
}

// --------------------------------------------------------------------------------------
- (void) setCompressState:(BOOL)compress :(BOOL)outline {
    [rating setAnswers:!compress];
}

// --------------------------------------------------------------------------------------
- (void) recalculateCellGeometryForCellWidth:(int)aCellWidth {
    
    // title
    CGSize constSize = CGSizeMake(aCellWidth, 1000);
    CGSize textSize = [question.title sizeWithFont:title.font
                                 constrainedToSize:constSize
                                     lineBreakMode:TPLineBreakByWordWrapping];
    [title setFrame:CGRectMake(10, TP_QUESTION_BEFORE_QUESTION_MARGIN, aCellWidth, textSize.height)];
    
    // prompt
    if (prompt) {
        textSize = [question.prompt sizeWithFont:prompt.font
                               constrainedToSize:constSize
                                   lineBreakMode:TPLineBreakByWordWrapping];
        [prompt setFrame:CGRectMake(10,
                                    title.frame.origin.y + title.frame.size.height + TP_QUESTION_BEFORE_PROMPT_MARGIN,
                                    aCellWidth,
                                    textSize.height)];
    }
    
    // rating
    CGRect ratingFrame = [rating frame];
    ratingFrame.size.width = aCellWidth;
    [rating setFrame:ratingFrame];
    
    if (rating.showAnswers) {
        compressor.image = [UIImage imageNamed:@"compress_sm_flat.png"];
        if (prompt)
        {
            [prompt setHidden:FALSE];
            ratingFrame.origin.y = prompt.frame.origin.y + prompt.frame.size.height + TP_QUESTION_AFTER_PROMPT_MARGIN;
        }
        else
        {
            ratingFrame.origin.y = title.frame.origin.y + title.frame.size.height + TP_QUESTION_AFTER_PROMPT_MARGIN;
        }
    } else {
        compressor.image = [UIImage imageNamed:@"uncompress_sm_flat.png"];
        if (prompt)
        {
            [prompt setHidden:TRUE];
        }
        ratingFrame.origin.y = title.frame.origin.y + title.frame.size.height + 10;
    }
    [rating setFrame:ratingFrame];
    
    // rating cells
    TPRubricQRatingCell* header_cell  = (TPRubricQRatingCell*)[rating cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    TPRubricQRatingCell* content_cell = (TPRubricQRatingCell*)[rating cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    
    [header_cell  resetColumns];
    [content_cell resetColumns];
    for ( int i = 0; i < rating.ratingsCount; i++) {
        int startPos = (int)((ratingFrame.size.width - 1)/ rating.ratingsCount * i);
        int endPos   = (int)((ratingFrame.size.width - 1)/ rating.ratingsCount * (i + 1));
        [header_cell  addColumn:endPos];
        [content_cell addColumn:endPos];
        //
        UILabel* header_label  = (UILabel*)[header_cell  viewWithTag:TP_QUESTION_TYPE_RATING_CELL_LABEL_TAG + i];
        UILabel* content_label = (UILabel*)[content_cell viewWithTag:TP_QUESTION_TYPE_RATING_CELL_LABEL_TAG + i];
        
        CGRect header_frame = [header_label frame];
        header_frame.origin.x = startPos + 2;
        header_frame.origin.y = 2;
        header_frame.size.width = endPos - startPos - 3;
        [header_label  setFrame:header_frame];
        
        CGRect content_frame = [content_label frame];
        content_frame.origin.x = startPos + 2;
        content_frame.origin.y = 1;
        content_frame.size.width = endPos - startPos - 3;
        [content_label setFrame:content_frame];
    }
    
    // category
    [category setFrame:CGRectMake(10,
                                  rating.frame.origin.y + rating.frame.size.height + TP_QUESTION_CATEGORY_TOP_MARGIN,
                                  aCellWidth * 0.75,
                                  20)];
    
    // annotation text
    int buttonsBaseY = rating.frame.origin.y + rating.frame.size.height;
    
    if (question.annotation) {
        if (showAnnotation) {
            CGSize constSize = CGSizeMake(aCellWidth, 1000);
            CGSize newTextSize = [[viewDelegate.model questionAnnot:question] sizeWithFont:[UIFont fontWithName:@"Helvetica" size:15.0]
                                                                         constrainedToSize:constSize
                                                                             lineBreakMode:TPLineBreakByWordWrapping];
            if (annotEditable) {
                [annotText setFrame:CGRectMake(10,
                                               category.frame.origin.y + category.frame.size.height + TP_QUESTION_BUTTON_TOP_MARGIN,
                                               aCellWidth,
                                               (newTextSize.height + 20) > TP_QUESTION_TYPE_TEXT_TEXTVIEW_HEIGHT_EDITED ? (newTextSize.height + 20) : TP_QUESTION_TYPE_TEXT_TEXTVIEW_HEIGHT_EDITED)];
            }
            else {
                [annotText setFrame:CGRectMake(10,
                                               category.frame.origin.y + category.frame.size.height + TP_QUESTION_BUTTON_TOP_MARGIN,
                                               aCellWidth,
                                               (newTextSize.height + 20) > TP_QUESTION_TYPE_TEXT_TEXTVIEW_HEIGHT ? (newTextSize.height + 20) : TP_QUESTION_TYPE_TEXT_TEXTVIEW_HEIGHT)];
            }
            buttonsBaseY = annotText.frame.origin.y + annotText.frame.size.height;
        }
        [annotText setHidden:!showAnnotation];
    }
    
    // annotation button
    if (annotButton) {
        [annotButton setFrame:CGRectMake(aCellWidth - 205, buttonsBaseY + TP_QUESTION_BUTTON_TOP_MARGIN, 80, 30)]; //jxi; origina x: 160;
        [annotButton setHidden:showAnnotation];
	}
    
    // compress button
    [compressor setFrame:CGRectMake(aCellWidth - 65, buttonsBaseY + TP_QUESTION_BUTTON_TOP_MARGIN, 30, 30)];
    [compressButton setFrame:CGRectMake(aCellWidth - 65, buttonsBaseY + TP_QUESTION_BUTTON_TOP_MARGIN, 30, 30)];
	
    // nextButton button
	if (nextButton) {
        [nextButton setFrame:CGRectMake(aCellWidth - 20, buttonsBaseY + TP_QUESTION_BUTTON_TOP_MARGIN, 30, 30)];
	}
    
	//cellHeight = compressButton.frame.origin.y + compressButton.frame.size.height + TP_QUESTION_AFTER_QUESTION_MARGIN;
    
    // jxi;
    attachlistButton.frame = CGRectMake(aCellWidth - 110, buttonsBaseY + TP_QUESTION_BUTTON_TOP_MARGIN, 30, 30);
    attachListVC.view.frame = CGRectMake(10, category.frame.origin.y + category.frame.size.height + TP_QUESTION_BUTTON_TOP_MARGIN, 320, attachListVC.attachListHeight);
    
    if (attachListVC.attachListHeight > attachlistButton.frame.size.height)
        cellHeight = attachListVC.view.frame.origin.y + attachListVC.attachListHeight + TP_QUESTION_AFTER_QUESTION_MARGIN;
    else
        cellHeight = attachlistButton.frame.origin.y + attachlistButton.frame.size.height + TP_QUESTION_AFTER_QUESTION_MARGIN;
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
