@class TPUser;

#import "TPModel.h"

// ---------------------------------------------------------------------------------------
@interface TPModel (Report)

// use own data preferences value. temporary storing it in NSUserDefaults until server-side changes are implemented
@property BOOL useOwnData;
@property BOOL autoCompression;
@property BOOL autoScrolling;
@property BOOL showStatus;

- (int) getNumRubricsRecorded:(int)targetId timeRange:(TPModelTimeRange)timeRange rubricId:(int)rubricId;
- (NSString *) getQuestionTitlebyId:(int) questionId;
- (BOOL) getCategoryAggregate:(int)categoryId rubricId:(int)rubricId targetUserId:(int)targetUserId userdataId:(NSString *)userdataId aggValue:(float *)aggValue;
- (void) getRubricsWithRecordedCategoryData:(NSMutableArray *)idList names:(NSMutableArray *)nameList;

@end

// ---------------------------------------------------------------------------------------
