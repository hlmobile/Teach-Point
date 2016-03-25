@class TPUser;

#import "TPDatabase.h"
#import "TPModel.h"
#import "TPData.h"

// ---------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------
@interface TPDatabase (Report)

- (int) getNumRubricsRecorded:(int)targetId timeRange:(TPModelTimeRange)timeRange rubricId:(int)rubricId filterUserId:(int)filterUserId;
- (BOOL) getAnswerAggregateForQuestions:(NSMutableIndexSet *)qids rubricId:(int)rubricId targetId:(int)target_id userDataId:(NSString *)userdata_id aggValue:(float *)aggValue filterUserId:(int)filterUserId;
- (void) getRubricsWithRecordedData:(NSMutableArray *)idList names:(NSMutableArray *)nameList filterUserId:(int)filterUserId;
- (void) getRubricsWithRecordedCategoryData:(NSMutableIndexSet *)qids idList:(NSMutableArray *)idList nameList:(NSMutableArray *)nameList filterUserId:(int)filterUserId;
- (void) getQuestionStatsForQuestionId:(int)questionId totalRecorded:(int *)total statList:(NSMutableArray *)statList ratingIdList:(NSMutableArray *)ratingIdList filterUserId:(int)filterUserId;
- (void) getTextResponsesForQuestion:(int)questionId entries:(NSMutableArray *)entries filterUserId:(int)filterUserId;
- (void) getAnnotationsForQuestion:(int)questionId entries:(NSMutableArray *)entries filterUserId:(int)filterUserId;
- (void) getRecordingsForRubricId:(int)rubricId dates:(NSMutableArray *)dates evaluators:(NSMutableArray *)evaluators elapsedTimes:(NSMutableArray *)elapsedTimes filterUserId:(int)filterUserId;

@end

// ---------------------------------------------------------------------------------------
