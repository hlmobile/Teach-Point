#import <sqlite3.h>

#import "TPData.h"
#import "TPDatabase.h"
#import "TPUtil.h"
#import "TPModel.h"
#import "TPModelSync.h"
#import "TPDatabaseReport.h"

// ---------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------
@implementation TPDatabase (Report)

// ------------------------------------------------------------------------------------
// getNumRubricsRecorded - return number of rubrics recorded given time range and
// target user ID.  Exclude self evaluations.
// ------------------------------------------------------------------------------------
- (int) getNumRubricsRecorded:(int)targetId timeRange:(TPModelTimeRange)timeRange rubricId:(int)rubricId filterUserId:(int)filterUserId {
    
    //NSLog(@"getNumRubricsRecorded %d %d", targetId, timeRange);
    
    int returncode;
	sqlite3_stmt *statement;
    NSString *sql;
    int count = 0;
    
    // Create only own data filter
    NSString *ownDataFilter;
    if (filterUserId > 0) {
        ownDataFilter = [NSString stringWithFormat:@" and userdata.user_id = %d ", filterUserId];
    } else {
        ownDataFilter = @"";
    }
    
    if (targetId > 0) {
        sql = [NSString stringWithFormat:@"select created from userdata where target_id = %d \
               and type = 1 and userdata.user_id != userdata.target_id %@", targetId, ownDataFilter];
    } else {
        sql = [NSString stringWithFormat:@"select created from userdata \
               where type = 1 and userdata.user_id != userdata.target_id %@", ownDataFilter];
    }
    if (debugDatabaseDetail) NSLog(@"%@", sql);
    
  	returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
	if (returncode == SQLITE_OK) {
        while (sqlite3_step(statement) == SQLITE_ROW) {
            char *created_str = (char *)sqlite3_column_text(statement, 0);
            NSDate *created = [self dateFromCharStr:created_str];
            float seconds_to_now = [created timeIntervalSinceNow] * -1.0;
            //NSLog(@"userdata %s %f", created_str, seconds_to_now);
            switch (timeRange) {
                case TIME_RANGE_ALL:
                    count++;
                    break;
                case TIME_RANGE_YEAR:
                    if (seconds_to_now < 31104000) { count++; }
                    break;
                case TIME_RANGE_SEMESTER:
                    if (seconds_to_now < 15552000) { count++; }
                    break;
                case TIME_RANGE_MONTH:
                    if (seconds_to_now < 2592000) { count++; }
                    break;
                case TIME_RANGE_WEEK:
                    if (seconds_to_now < 604800) { count++; }
                    break;
                case TIME_RANGE_DAY:
                    if (seconds_to_now < 86400) { count++; }
                    break;
            }
		}
	} else {
		NSLog(@"ERROR: getNumRubricsRecorded DB failed with code %d", returncode);
	}
	sqlite3_finalize(statement);
    
    return count;
}

// ------------------------------------------------------------------------------------
// getAnswerAggregate - return aggregate value of all rubric answers for the given
// a list of question IDs.  Filter data by either target user ID or userdata ID.
// Exclude self-evaluation data. If rubric ID is not 0 then filter by rubric too.
// ------------------------------------------------------------------------------------
- (BOOL) getAnswerAggregateForQuestions:(NSMutableIndexSet *)qids rubricId:(int)rubricId targetId:(int)target_id userDataId:(NSString *)userdata_id aggValue:(float *)aggValue filterUserId:(int)filterUserId {
    
    int returncode;
	sqlite3_stmt *statement;
    NSString *sql;
    float total = 0;
    int count = 0;
        
    // Create rubric filter
    NSString *rubricFilter;
    if (rubricId > 0) {
        rubricFilter = [NSString stringWithFormat:@" and rubricdata.rubric_id = %d ", rubricId];
    } else {
        rubricFilter = @"";
    }
	
	// Create only own data filter
    NSString *ownDataFilter;
    if (filterUserId > 0) {
        ownDataFilter = [NSString stringWithFormat:@" and userdata.user_id = %d ", filterUserId];
    } else {
        ownDataFilter = @"";
    }
    
    // Loop over all user data
    if (userdata_id != nil) {
        sql = [NSString stringWithFormat:@"select question_id, rating_id, value from userdata, rubricdata \
               where userdata.userdata_id = rubricdata.userdata_id and userdata.userdata_id = '%@' \
               and userdata.user_id != userdata.target_id %@%@", userdata_id, rubricFilter, ownDataFilter];
    } else {
        if (target_id > 0) {
            sql = [NSString stringWithFormat:@"select question_id, rating_id, value from userdata, rubricdata \
                   where userdata.userdata_id = rubricdata.userdata_id and userdata.target_id = %d \
                   and userdata.user_id != userdata.target_id %@%@", target_id, rubricFilter, ownDataFilter];
        } else {
            sql = [NSString stringWithFormat:@"select question_id, rating_id, value from userdata, rubricdata \
                   where userdata.userdata_id = rubricdata.userdata_id  \
                   and userdata.user_id != userdata.target_id %@%@", rubricFilter, ownDataFilter];
        }
    }
    if (debugDatabaseDetail) NSLog(@"%@", sql);
	returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
	if (returncode == SQLITE_OK) {
		while (sqlite3_step(statement) == SQLITE_ROW) {
            int question_id = (int)sqlite3_column_int(statement, 0);
            int rating_id = (int)sqlite3_column_int(statement, 1);
            float value = (float)sqlite3_column_double(statement, 2);
            if (rating_id > 0 && [qids containsIndex:question_id]) {
                total += value;
                count++;
            }
		}
	} else {
		NSLog(@"ERROR: getAnswerAggregate DB failed with code %d", returncode);
	}
	sqlite3_finalize(statement);
    
    if (count > 0) {
        *aggValue = total / count;
        return YES;
    } else {
        *aggValue = 0;
        return NO;
    }
}

// ---------------------------------------------------------------------------------------
// getRubricsWithRecordedData - get a list of rubric IDs and titles that have recorded
// form data. Return NULL if no ata was found.
// ---------------------------------------------------------------------------------------
- (void) getRubricsWithRecordedData:(NSMutableArray *)idList names:(NSMutableArray *)nameList filterUserId:(int)filterUserId {
	
    int returncode;
    sqlite3_stmt *statement;
    NSString *sql;
      
	// Create only own data filter
    NSString *ownDataFilter;
    if (filterUserId > 0) {
        ownDataFilter = [NSString stringWithFormat:@" and userdata.user_id = %d ", filterUserId];
    } else {
        ownDataFilter = @"";
    }
    
	// Clear existing lists
    [idList removeAllObjects];
    [nameList removeAllObjects];
	
    sql = [NSString stringWithFormat:@"select distinct rubric_id, name from userdata \
           where type = 1 and target_id = %d and user_id != target_id %@ order by lower(name)",
           model.appstate.target_id, ownDataFilter];
    if (debugDatabaseDetail) NSLog(@"%@", sql);
    returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
    if (returncode == SQLITE_OK) {
    while (sqlite3_step(statement) == SQLITE_ROW) {
        int rubric_id = (int)sqlite3_column_int(statement, 0);
        NSString *rubric_name = [NSString stringWithFormat:@"%s", (char *)sqlite3_column_text(statement, 1)];
        [idList addObject:[NSNumber numberWithInt:rubric_id]];
        [nameList addObject:rubric_name];
    }
    } else {
        NSLog(@"ERROR: dumpDatabase DB prepare 1 failed with code %d", returncode);
    }
    sqlite3_finalize(statement);
}

// ---------------------------------------------------------------------------------------
// getRubricsWithRecordedCategoryData - Gets a list of rubric ids and titles that data
// recorded for specified questions, and that isn't self-evaluation data, for all
// target users.
// ---------------------------------------------------------------------------------------
- (void) getRubricsWithRecordedCategoryData:(NSMutableIndexSet *)qids idList:(NSMutableArray *)idList nameList:(NSMutableArray *)nameList filterUserId:(int)filterUserId {
	
    int returncode;
    sqlite3_stmt *statement;
    NSString *sql;
    NSMutableIndexSet *idSet = [[[NSMutableIndexSet alloc] init] autorelease];
    
	// Create only own data filter
    NSString *ownDataFilter;
    if (filterUserId > 0) {
        ownDataFilter = [NSString stringWithFormat:@" and userdata.user_id = %d ", filterUserId];
    } else {
        ownDataFilter = @"";
    }
	
    // Clear existing lists
    [idList removeAllObjects];
    [nameList removeAllObjects];
    
    // Skip if question list is empty
    if ([qids count] == 0) return;
        
    sql = [NSString stringWithFormat:@"select distinct userdata.rubric_id, userdata.name, rubricdata.question_id from userdata, rubricdata \
           where userdata.userdata_id = rubricdata.userdata_id and userdata.user_id != userdata.target_id %@ order by lower(userdata.name)",
		   ownDataFilter];
    if (debugDatabaseDetail) NSLog(@"%@", sql);
    returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
    if (returncode == SQLITE_OK) {
        while (sqlite3_step(statement) == SQLITE_ROW) {
            int rubric_id = (int)sqlite3_column_int(statement, 0);
            NSString *rubric_name = [NSString stringWithFormat:@"%s", (char *)sqlite3_column_text(statement, 1)];
            int question_id = (int)sqlite3_column_int(statement, 2);
            if ([qids containsIndex:question_id] && ![idSet containsIndex:rubric_id]) {
                [idSet addIndex:rubric_id];
                [idList addObject:[NSNumber numberWithInt:rubric_id]];
                [nameList addObject:rubric_name];
            }
        }
    } else {
        NSLog(@"ERROR: dumpDatabase DB prepare 1 failed with code %d", returncode);
    }
    sqlite3_finalize(statement);
}

// ---------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------
- (void) getQuestionStatsForQuestionId:(int)questionId totalRecorded:(int *)total statList:(NSMutableArray *)statList ratingIdList:(NSMutableArray *)ratingIdList filterUserId:(int)filterUserId {
    
    int returncode;
    sqlite3_stmt *statement;
    NSString *sql;

	// Create only own data filter
    NSString *ownDataFilter;
    if (filterUserId > 0) {
        ownDataFilter = [NSString stringWithFormat:@" and userdata.user_id = %d ", filterUserId];
    } else {
        ownDataFilter = @"";
    }
	
    // Clear existing lists
    [statList removeAllObjects];
    [ratingIdList removeAllObjects];
    int sum = 0;
    
    sql = [NSString stringWithFormat:@"select rating_id, count(*) from rubricdata, userdata where rubricdata.userdata_id = userdata.userdata_id \
           and target_id = %d and userdata.user_id != target_id and question_id = %d %@ group by rating_id order by rating_id",
           model.appstate.target_id, questionId, ownDataFilter];
    if (debugDatabaseDetail) NSLog(@"%@", sql);
    returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
    if (returncode == SQLITE_OK) {
        while (sqlite3_step(statement) == SQLITE_ROW) {
            int rating_id = (int)sqlite3_column_int(statement, 0);
            int rating_count = (int)sqlite3_column_int(statement, 1);
            [statList addObject:[NSNumber numberWithInt:rating_count]];
            [ratingIdList addObject:[NSNumber numberWithInt:rating_id]];
        }
    } else {
        NSLog(@"ERROR: getQuestionStatsForQuestionId DB prepare 1 failed with code %d", returncode);
    }
    sqlite3_finalize(statement);

    sql = [NSString stringWithFormat:@"select count(*) from rubricdata, userdata where rubricdata.userdata_id = userdata.userdata_id \
           and target_id = %d and userdata.user_id != target_id and question_id = %d %@ group by question_id, rubricdata.userdata_id",
           model.appstate.target_id, questionId, ownDataFilter];
    //NSLog(@"getRubricsWithRecordedData %@", sql);
    returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
    if (returncode == SQLITE_OK) {
        while (sqlite3_step(statement) == SQLITE_ROW) {
            sum++;
        }
    } else {
        NSLog(@"ERROR: getQuestionStatsForQuestionId DB prepare 2 failed with code %d", returncode);
    }
    sqlite3_finalize(statement);
    *total = sum;
}

// ---------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------
- (void) getTextResponsesForQuestion:(int)questionId entries:(NSMutableArray *)entries filterUserId:(int)filterUserId {
	
    int returncode;
    sqlite3_stmt *statement;
    NSString *sql;
    
	// Create only own data filter
    NSString *ownDataFilter;
    if (filterUserId > 0) {
        ownDataFilter = [NSString stringWithFormat:@" and userdata.user_id = %d ", filterUserId];
    } else {
        ownDataFilter = @"";
    }
	
    // Clear list
    [entries removeAllObjects];
    
    sql = [NSString stringWithFormat:@"select rubricdata.text from rubricdata, userdata where rubricdata.userdata_id = userdata.userdata_id \
           and target_id = %d and userdata.user_id != target_id and rubricdata.question_id = %d %@",
           model.appstate.target_id, questionId, ownDataFilter];
    if (debugDatabaseDetail) NSLog(@"%@", sql);
    returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
    if (returncode == SQLITE_OK) {
        while (sqlite3_step(statement) == SQLITE_ROW) {
            NSString *question_text = [NSString stringWithFormat:@"%s", (char *)sqlite3_column_text(statement, 0)];
            [entries addObject:question_text];
        }
    } else {
        NSLog(@"ERROR: getTextResponsesForQuestion DB prepare 1 failed with code %d", returncode);
    }
    sqlite3_finalize(statement);
}

// ---------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------
- (void) getAnnotationsForQuestion:(int)questionId entries:(NSMutableArray *)entries filterUserId:(int)filterUserId {
	
    int returncode;
    sqlite3_stmt *statement;
    NSString *sql;
    
	// Create only own data filter
    NSString *ownDataFilter;
    if (filterUserId > 0) {
        ownDataFilter = [NSString stringWithFormat:@" and userdata.user_id = %d ", filterUserId];
    } else {
        ownDataFilter = @"";
    }
	
    // Clear list
    [entries removeAllObjects];
    
    sql = [NSString stringWithFormat:@"select rubricdata.text from rubricdata, userdata where rubricdata.userdata_id = userdata.userdata_id \
           and target_id = %d and userdata.user_id != target_id and rubricdata.question_id = %d and rubricdata.annot = 1 %@",
           model.appstate.target_id, questionId, ownDataFilter];
    if (debugDatabaseDetail) NSLog(@"%@", sql);
    returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
    if (returncode == SQLITE_OK) {
        while (sqlite3_step(statement) == SQLITE_ROW) {
            NSString *question_annotation = [NSString stringWithFormat:@"%s", (char *)sqlite3_column_text(statement, 0)];
            [entries addObject:question_annotation];
        }
    } else {
        NSLog(@"ERROR: getAnnotationsForQuestion DB prepare 1 failed with code %d", returncode);
    }
    sqlite3_finalize(statement);
}

// ---------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------
- (void) getRecordingsForRubricId:(int)rubricId
                            dates:(NSMutableArray *)dates
                       evaluators:(NSMutableArray *)evaluators
                     elapsedTimes:(NSMutableArray *)elapsedTimes
                     filterUserId:(int)filterUserId {
    
    int returncode;
    sqlite3_stmt *statement;
    NSString *sql;
    
	// Create only own data filter
    NSString *ownDataFilter;
    if (filterUserId > 0) {
        ownDataFilter = [NSString stringWithFormat:@" and userdata.user_id = %d ", filterUserId];
    } else {
        ownDataFilter = @"";
    }
	
    // Clear list
    [dates removeAllObjects];
    [evaluators removeAllObjects];
    [elapsedTimes removeAllObjects];
    
    sql = [NSString stringWithFormat:@"select created, user_id, elapsed from userdata where rubric_id = %d and target_id = %d \
           and user_id != target_id %@ order by created desc",
           rubricId, model.appstate.target_id, ownDataFilter];
    if (debugDatabaseDetail) NSLog(@"%@", sql);
    returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
    if (returncode == SQLITE_OK) {
        while (sqlite3_step(statement) == SQLITE_ROW) {
            char *created = (char *)sqlite3_column_text(statement, 0);
            int user_id = (int)sqlite3_column_int(statement, 1);
            int elapsed = (int)sqlite3_column_int(statement, 2);
            
            [dates addObject:[self dateFromCharStr:created]];
            [evaluators addObject:[model getUserName:user_id]];
            [elapsedTimes addObject:[NSNumber numberWithInt:elapsed]];
        }
    } else {
        NSLog(@"ERROR: getQuestionStatsForQuestionId DB prepare 1 failed with code %d", returncode);
    }
    sqlite3_finalize(statement);
}

@end

// ---------------------------------------------------------------------------------------
