//
//  TPRubricQCellTimer.h
//  teachpoint
//
//  Created by Chris Dunn on 9/29/12.
//
//

@class TPRubricQCellAnnotated;

// --------------------------------------------------------------------------------------
// TPRubricQCellTimer - return content of table cell for timer question
// --------------------------------------------------------------------------------------
@interface TPRubricQCellTimer : TPRubricQCellAnnotated {
	UILabel *timeLabel;
	UIButton *startStopButton;
	int elapsedTime;
	NSTimer *secondTimer;
    UIView *containerView;
}

- (id)initWithView:(TPView *)mainview style:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier question:(TPQuestion *)somequestion isLast:(BOOL)isLast;
- (void) startStopTime;
- (void) saveTime;

@end
