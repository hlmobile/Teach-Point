#import <sqlite3.h>

#import <CFNetwork/CFNetwork.h>
#import <CFNetwork/CFHTTPStream.h>
#import "TPData.h"
#import "TPDatabase.h"
#import "TPDatabaseReport.h"
#import "TPModel.h"
#import "TPModelSync.h"
#import "TPModelReport.h"
#import "TPView.h"
#import "TPParser.h"
#import "TPSyncManager.h"

// ---------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------
@implementation TPModel (Report)

- (void) setUseOwnData:(BOOL)useOwnData {
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	NSData* myEncodedObject = [NSKeyedArchiver archivedDataWithRootObject:[NSNumber numberWithBool:useOwnData]];
    [defaults setObject:myEncodedObject forKey:@"UseOwnData"];	
}

// ---------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------
- (BOOL) useOwnData {
	// defaults to FALSE if no value is present in storage
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSData *myEncodedObject = [defaults objectForKey: @"UseOwnData"];
	return [(NSNumber *)[NSKeyedUnarchiver unarchiveObjectWithData: myEncodedObject] boolValue];
}

// ---------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------

- (void) setAutoCompression:(BOOL)autoCompression {
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	NSData* myEncodedObject = [NSKeyedArchiver archivedDataWithRootObject:[NSNumber numberWithBool:autoCompression]];
    [defaults setObject:myEncodedObject forKey:@"AutoCompression"];	
}

// ---------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------
- (BOOL) autoCompression {
	// defaults to FALSE if no value is present in storage
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSData *myEncodedObject = [defaults objectForKey: @"AutoCompression"];
	return [(NSNumber *)[NSKeyedUnarchiver unarchiveObjectWithData: myEncodedObject] boolValue];
}

// ---------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------
- (void) setAutoScrolling:(BOOL)autoScrolling {
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	NSData* myEncodedObject = [NSKeyedArchiver archivedDataWithRootObject:[NSNumber numberWithBool:autoScrolling]];
    [defaults setObject:myEncodedObject forKey:@"AutoScrolling"];	
}

// ---------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------
- (BOOL) autoScrolling {
	// defaults to FALSE if no value is present in storage
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSData *myEncodedObject = [defaults objectForKey: @"AutoScrolling"];
	return [(NSNumber *)[NSKeyedUnarchiver unarchiveObjectWithData: myEncodedObject] boolValue];
}

// ---------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------
- (void) setShowStatus:(BOOL)showStatus {
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	NSData* myEncodedObject = [NSKeyedArchiver archivedDataWithRootObject:[NSNumber numberWithBool:showStatus]];
    [defaults setObject:myEncodedObject forKey:@"ShowStatus"];	
}

// ---------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------
- (BOOL) showStatus {
	// defaults to FALSE if no value is present in storage
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSData *myEncodedObject = [defaults objectForKey: @"ShowStatus"];
	return [(NSNumber *)[NSKeyedUnarchiver unarchiveObjectWithData: myEncodedObject] boolValue];
}

// ---------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------
- (int) getNumRubricsRecorded:(int)targetId timeRange:(TPModelTimeRange)timeRange rubricId:(int)rubricId {
    //NSLog(@"FILTER user ID %d", appstate.user_id);
    return [database getNumRubricsRecorded:targetId timeRange:timeRange rubricId:rubricId filterUserId:(self.useOwnData?appstate.user_id:0)];
}

// ---------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------
- (NSString *) getQuestionTitlebyId:(int) questionId {
	for (TPQuestion *question in question_array) {
		if ( questionId == question.question_id ) return question.title;
    }
    
    return NULL;
}

// ---------------------------------------------------------------------------------------
// getCategoryAggregate - returns average value of all recorded rating scale answers
// for the the given category and the target user.  Do not include self-evaluation or
// reflection data.  Alternatively, if the userdata ID is specified, then limit average
// to responses for that rubric recording (targetUserId is not required in this case and
// may be set to 0). If rubricId is specified then only return data for that rurbic
// (set to 0 if not used).
// ---------------------------------------------------------------------------------------
- (BOOL) getCategoryAggregate:(int)categoryId rubricId:(int)rubricId targetUserId:(int)targetUserId userdataId:(NSString *)userdataId aggValue:(float *)aggValue {
        
    //NSLog(@" getCategoryAggregate %d %d %d %@", categoryId, rubricId, targetUserId, userdataId);
    
    // Create array of question IDs for questions in the given category, that are rating scale, and not reflections
    NSMutableIndexSet *qids = [[[NSMutableIndexSet alloc] init] autorelease];
    for (TPQuestion *question in question_array) {
        if (question.type == TP_QUESTION_TYPE_RATING &&
            question.category == categoryId &&
            ![question isQuestionReflection]) {
            [qids addIndex:question.question_id];
        }
    }
    
    return [database getAnswerAggregateForQuestions:qids rubricId:rubricId targetId:targetUserId userDataId:userdataId aggValue:aggValue filterUserId:(self.useOwnData?appstate.user_id:0)];
}

// ---------------------------------------------------------------------------------------
// getRubricsWithRecordedCategoryData - Gets a list of rubric ids and titles that have
// recorded cetegory (rating scale) data, for all target users.
// ---------------------------------------------------------------------------------------
- (void) getRubricsWithRecordedCategoryData:(NSMutableArray *)idList names:(NSMutableArray *)nameList {
    
    //NSLog(@" getRubricsWithRecordedCategoryData");
    
    // Create array of question IDs for questions that are rating scale, and not reflections
    NSMutableIndexSet *qids = [[[NSMutableIndexSet alloc] init] autorelease];
    for (TPQuestion *question in question_array) {
        if (question.type == TP_QUESTION_TYPE_RATING &&
            ![question isQuestionReflection]) {
            [qids addIndex:question.question_id];
        }
    }

    [database getRubricsWithRecordedCategoryData:qids idList:idList nameList:nameList filterUserId:(self.useOwnData?appstate.user_id:0)];
}

@end

// ---------------------------------------------------------------------------------------
