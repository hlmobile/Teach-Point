#import <sqlite3.h>
#import "TPData.h"
#import "TPDatabase.h"
#import "TPUtil.h"
#import "TPModel.h"
#import "TPModelSync.h"
#import "string.h"
#import <MediaPlayer/MediaPlayer.h>

#define SQLCIPHER_ENCRYPTION_KEY_LENGTH  64

// ------------------------------------------------------------------------------------
@implementation TPDatabase

@synthesize imagesPath;
@synthesize videosPath;

static sqlite3_stmt *insert_statement = nil;
static sqlite3_stmt *delete_statement = nil;

// ------------------------------------------------------------------------------------
- (id)initWithModel:(TPModel *)some_model {
    if (debugDatabaseControl) NSLog(@"TPDatabase initWithModel");
	self = [ super init ];
	if (self != nil) {
		model = some_model;
        
        dateformatter = [[NSDateFormatter alloc] init];
        dateLocal = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
        [dateformatter setLocale:dateLocal];
        [dateformatter setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
        dateformatterLock = [[NSLock alloc] init];
        
        imagesPath = [NSString stringWithFormat:@"%@/Documents/Images", NSHomeDirectory()];
        videosPath = [NSString stringWithFormat:@"%@/Documents/Videos", NSHomeDirectory()]; //jxi;
        
		[self initDatabase];
	}
	return self;
}

// ------------------------------------------------------------------------------------
- (void)dealloc {
    if (debugDatabaseControl) NSLog(@"TPDatabase dealloc");
	sqlite3_finalize(insert_statement);
	sqlite3_finalize(delete_statement);
	if (sqlite3_close(database) != SQLITE_OK) {
        NSAssert1(0, @"Error: closing database with message '%s'.", sqlite3_errmsg(database));
    }
    [imagesPath release];
    [videosPath release]; //jxi;
	[dateformatter release];
    [dateLocal release];
    [dateformatterLock release];
	[super dealloc];
}

// ------------------------------------------------------------------------------------

- (NSString *)getDatabaseEncryptionKey {   
	NSMutableString *databaseEncryptionKey = [NSMutableString stringWithString:model.publicstate.hashed_password];
    int len = [databaseEncryptionKey length];
    [databaseEncryptionKey deleteCharactersInRange:NSMakeRange(SQLCIPHER_ENCRYPTION_KEY_LENGTH, len - SQLCIPHER_ENCRYPTION_KEY_LENGTH)];
    return databaseEncryptionKey;
}

- (BOOL) isDatabaseEncrypted {
    /* Test of the opened database. This method have to be used only AFTER sqlite3_key() function! */
    int returncode;
    returncode = sqlite3_exec(database, [@"SELECT * FROM SQLITE_MASTER" UTF8String], NULL, NULL, NULL);
    if (returncode == SQLITE_OK) {
        return YES;
    } else {
        return NO;
    }
}

- (void) encryptDatabaseWithKey:(NSString *) aKey {
    if (debugDatabase) NSLog(@"TPDatabase encryptDatabaseWithKey %@", aKey);
    // open old plaintext database
    int returncode;
    NSFileManager *filemanager = [NSFileManager defaultManager];
    NSString *oldDBPath = [NSString stringWithFormat:@"%@/Documents/rubricdb.sql", NSHomeDirectory()];
    NSString *newDBPath = [NSString stringWithFormat:@"%@/Documents/rubricdb_new.sql", NSHomeDirectory()];
    
    sqlite3 *oldDB;
    if (sqlite3_open([oldDBPath UTF8String], &oldDB) == SQLITE_OK) {
        // Attach empty encrypted database to unencrypted database
        
        returncode = sqlite3_exec(oldDB, [[NSString stringWithFormat:@"ATTACH DATABASE '%@' AS encrypted KEY '%@';", newDBPath, aKey] UTF8String], NULL, NULL, NULL);
        if (returncode != SQLITE_OK)
            NSLog(@"ERROR: database encryption at step 1 with code: %i (%s)", returncode, sqlite3_errmsg(database));
        // export data from old (plaintext) to new (encrypted) database
        returncode = sqlite3_exec(oldDB, [@"SELECT sqlcipher_export('encrypted');" UTF8String], NULL, NULL, NULL);
        if (returncode != SQLITE_OK)
            NSLog(@"ERROR: database encryption at step 2 with code: %i (%s)", returncode, sqlite3_errmsg(database));
        // detach new (encrypted) database
        returncode = sqlite3_exec(oldDB, [@"DETACH DATABASE encrypted;" UTF8String], NULL, NULL, NULL);
        if (returncode != SQLITE_OK)
            NSLog(@"ERROR: database encryption at step 3 with code: %i (%s)", returncode, sqlite3_errmsg(database));
        // close (old) plaintext database
        returncode = sqlite3_close(oldDB);
        if (returncode != SQLITE_OK)
            NSLog(@"ERROR: database encryption at step 4 with code: %i (%s)", returncode, sqlite3_errmsg(database));
    }
    sqlite3_close(oldDB);
    // remove old (plaintext) database 
    [filemanager removeItemAtPath:oldDBPath error:NULL];
    // rename new (encrypted) database
    [filemanager moveItemAtPath:newDBPath toPath:oldDBPath error:NULL];
}

// ------------------------------------------------------------------------------------
- (void)initDatabase {    

    if (debugDatabaseControl) NSLog(@"TPDatabase initDatabase version %s thread safety %d", sqlite3_version, sqlite3_threadsafe());
        
	int returncode;
	sqlite3_stmt *statement;
	
	NSFileManager *filemanager = [NSFileManager defaultManager];
	NSString *dbpath = [NSString stringWithFormat:@"%@/Documents/rubricdb.sql", NSHomeDirectory()];
	BOOL dbexists = [filemanager fileExistsAtPath:dbpath];
	
	if (sqlite3_open_v2([dbpath UTF8String], &database, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX, 0) == SQLITE_OK) {

        // database encryption
        NSString *key = [NSString stringWithString:[self getDatabaseEncryptionKey]];
        const char *ckey = [key UTF8String];
        sqlite3_key(database, ckey, strlen(ckey));
        if (![self isDatabaseEncrypted]) {
            sqlite3_close(database);
            [self encryptDatabaseWithKey:key];
            sqlite3_open([dbpath UTF8String], &database);
            sqlite3_key(database, ckey, strlen(ckey));
        }        

		// If DB empty then create tables
		if (!dbexists) {
						
            if (debugDatabase) NSLog(@"TPDatabase init database");
            
            // Set auto vacuum mode
			const char *setautovacuum = "PRAGMA auto_vacuum = 1;";
			returncode = sqlite3_prepare_v2(database, setautovacuum, -1, &statement, NULL);
			if (returncode == SQLITE_OK) {
				returncode = sqlite3_step(statement);
                if (returncode != SQLITE_DONE) NSLog(@"ERROR: failed to set auto vacuum mode with code %d", returncode);
			} else {
				NSLog(@"ERROR: failed to prepare auto vacuum mode with code %d", returncode);
			}
			sqlite3_finalize(statement);

			// Create table of user recorded data (rubrics, notes, etc.)
			const char *createuserdata = "\
			create table userdata (\
			  district_id     integer,\
              user_id         integer,\
			  target_id       integer,\
			  share           integer,\
              school_id       integer,\
              subject_id      integer,\
              grade           integer,\
              elapsed         integer,\
              type            integer,\
              name            varchar(128),\
              rubric_id       integer,\
              userdata_id     varchar(1024),\
              state           integer,\
              created		  timestamp,\
              modified        timestamp,\
              description     varchar(1024),\
              aud_id          varchar(1024),\
              aq_id           integer\
            )";
            //jxi: aud_id, aq_id fields are added
            
			returncode = sqlite3_prepare_v2(database, createuserdata, -1, &statement, NULL);
			if (returncode == SQLITE_OK) {
				returncode = sqlite3_step(statement);
                if (returncode != SQLITE_DONE) NSLog(@"ERROR: failed to create userdata table with code %d", returncode);
			} else {
				NSLog(@"ERROR: failed to prepare userdata table with code %d", returncode);
			}
			sqlite3_finalize(statement);
			
			// Create table of rubric data
            // NOTE Sqlite does not restrict text inserted into varchar, so text field can remain as defined and accept 10000 characters
			const char *createrubricdata = "\
			create table rubricdata (\
			  district_id		integer,\
              userdata_id       varchar(1024),\
			  rubric_id         integer,\
              question_id       integer,\
              rating_id         integer,\
			  value     		float,\
			  text			    varchar(1024),\
              annot             integer,\
              user_id           integer,\
              modified          timestamp,\
              datevalue         timestamp\
			)";
			returncode = sqlite3_prepare_v2(database, createrubricdata, -1, &statement, NULL);
			if (returncode == SQLITE_OK) {
				returncode = sqlite3_step(statement);
                if (returncode != SQLITE_DONE) NSLog(@"ERROR: failed to create rubricdata table with code %d", returncode);
			} else {
				NSLog(@"ERROR: failed to prepare rubricdata table with code %d", returncode);
			}
			sqlite3_finalize(statement);
            
            // Create table of image data
            const char *createimagedata = "\
            create table imagedata (\
              district_id         integer,\
              userdata_id         varchar(1024),\
              type                integer,\
              width               integer,\
              height              integer,\
              format              varchar(128),\
              encoding            varchar(128),\
              user_id             integer,\
              modified            timestamp,\
              filename            varchar(1024),\
              origin              integer\
            )";
            returncode = sqlite3_prepare_v2(database, createimagedata, -1, &statement, NULL);
			if (returncode == SQLITE_OK) {
				returncode = sqlite3_step(statement);
                if (returncode != SQLITE_DONE) NSLog(@"ERROR: DB step failed with code %d", returncode);
			} else {
				NSLog(@"ERROR: failed to prepare imagedata table with code %d", returncode);
			}
			sqlite3_finalize(statement);
            
            // Create table of video data //jxi;
            const char *createvideodata = "\
            create table videodata (\
            district_id         integer,\
            userdata_id         varchar(1024),\
            type                integer,\
            width               integer,\
            height              integer,\
            format              varchar(128),\
            encoding            varchar(128),\
            user_id             integer,\
            modified            timestamp,\
            filename            varchar(1024),\
            origin              integer\
            )";
            returncode = sqlite3_prepare_v2(database, createvideodata, -1, &statement, NULL);
            if (returncode == SQLITE_OK) {
                returncode = sqlite3_step(statement);
                if (returncode != SQLITE_DONE) NSLog(@"ERROR: DB step failed with code %d", returncode);
            } else {
                NSLog(@"ERROR: failed to prepare videodata table with code %d", returncode);
            }
            sqlite3_finalize(statement);
            
            // create folder for images
            NSError *error;
            [[NSFileManager defaultManager] createDirectoryAtPath:imagesPath withIntermediateDirectories:YES attributes:nil error:&error];
            
            // create folder for videos
            [[NSFileManager defaultManager] createDirectoryAtPath:videosPath withIntermediateDirectories:YES attributes:nil error:&error];
            
            // Database indexation
            const char *create_userdata_userdataid_index = "CREATE INDEX idx_userdata_userdataid ON userdata (userdata_id)";
			returncode = sqlite3_prepare_v2(database, create_userdata_userdataid_index, -1, &statement, NULL);
			if (returncode == SQLITE_OK) {
				returncode = sqlite3_step(statement);
                if (returncode != SQLITE_DONE) NSLog(@"ERROR: failed to create index of the userdata table with code %d", returncode);
			} else {
				NSLog(@"ERROR: failed to prepare index for userdata table with code %d", returncode);
			}
			sqlite3_finalize(statement);

            const char *create_userdata_userid_index = "CREATE INDEX idx_userdata_userid ON userdata (user_id)";
			returncode = sqlite3_prepare_v2(database, create_userdata_userid_index, -1, &statement, NULL);
			if (returncode == SQLITE_OK) {
				returncode = sqlite3_step(statement);
                if (returncode != SQLITE_DONE) NSLog(@"ERROR: failed to create index of the userdata table with code %d", returncode);
			} else {
				NSLog(@"ERROR: failed to prepare index for userdata table with code %d", returncode);
			}
			sqlite3_finalize(statement);

            const char *create_rubricdata_userdataid_index = "CREATE INDEX idx_rubricdata_userdataid ON rubricdata (userdata_id)";
			returncode = sqlite3_prepare_v2(database, create_rubricdata_userdataid_index, -1, &statement, NULL);
			if (returncode == SQLITE_OK) {
				returncode = sqlite3_step(statement);
                if (returncode != SQLITE_DONE) NSLog(@"ERROR: failed to create index of the rubricdata table with code %d", returncode);
			} else {
				NSLog(@"ERROR: failed to prepare index for rubricdata table with code %d", returncode);
			}
			sqlite3_finalize(statement);
            
        } else {
            // Database exists, checking for annotation column and adding it if required
            if (debugDatabase) NSLog(@"TPDatabase database exists");
            
            NSString *sql;
            int returncode;
            sqlite3_stmt *statement;
            BOOL annotMissing = TRUE;
            BOOL useridMissing = TRUE;
            BOOL descriptionMissing = TRUE;
            BOOL imagedataTableMissing = TRUE;
            BOOL audidMissing = TRUE; //jxi
            BOOL aqidMissing = TRUE; //jxi
            BOOL videodataTableMissing = TRUE; //jxi;
            
            // check for annotation, user_id columns in database
            sql = @"PRAGMA table_info(rubricdata)";
            returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
            if (returncode == SQLITE_OK) {
                while (sqlite3_step(statement) == SQLITE_ROW) {
                    char *column_name = (char *)sqlite3_column_text(statement, 1);
                    if (debugDatabase) NSLog(@"%@ ", [NSString stringWithUTF8String:column_name]);
                    if (!strcmp(column_name, "annot")) {
                        annotMissing = FALSE;
                    }
                    if (!strcmp(column_name, "user_id")) {
                        useridMissing = FALSE;
                        break;
                    }
                }
            }
            sqlite3_finalize(statement);
            
            // check for description columns in userdata table
            sql = @"PRAGMA table_info(userdata)";
            returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
            if (returncode == SQLITE_OK) {
                while (sqlite3_step(statement) == SQLITE_ROW) {
                    char *column_name = (char *)sqlite3_column_text(statement, 1);
                    if (debugDatabase) NSLog(@"%@ ", [NSString stringWithUTF8String:column_name]);
                    if (!strcmp(column_name, "description")) {
                        descriptionMissing = FALSE;
                    }
                    
                    //jxi; check for aud_id and aq_id columns in userdata table
                    if (!strcmp(column_name, "aud_id")) {
                        audidMissing = FALSE;
                    }
                    if (!strcmp(column_name, "aq_id")) {
                        aqidMissing = FALSE;
                    }
                }
            }
            sqlite3_finalize(statement);
            
            // check for imagedata table in database
            sql = @"SELECT name FROM sqlite_master WHERE type='table'";
            returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
            if (returncode == SQLITE_OK) {
                while (sqlite3_step(statement) == SQLITE_ROW) {
                    char *table_name = (char *)sqlite3_column_text(statement, 0);
                    if (debugDatabase) NSLog(@"%@ ", [NSString stringWithUTF8String:table_name]);
                    if (!strcmp(table_name, "imagedata")) {
                        imagedataTableMissing = FALSE;
                    }
                }
            }
            sqlite3_finalize(statement);
            
            // check for videodata table in database //jxi;
            sql = @"SELECT name FROM sqlite_master WHERE type='table'";
            returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
            if (returncode == SQLITE_OK) {
                while (sqlite3_step(statement) == SQLITE_ROW) {
                    char *table_name = (char *)sqlite3_column_text(statement, 0);
                    if (debugDatabase) NSLog(@"%@ ", [NSString stringWithUTF8String:table_name]);
                    if (!strcmp(table_name, "videodata")) {
                        videodataTableMissing = FALSE;
                    }
                }
            }
            sqlite3_finalize(statement);

            // annot column is missing from the table (old database). Adding it
            if (annotMissing) {
                if (debugDatabase) NSLog(@"TPDatabase updating model add annot");
                
                // add annot column 
                sql = @"ALTER TABLE rubricdata ADD annot integer";
                returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
                if (returncode == SQLITE_OK) {
                    while (sqlite3_step(statement) == SQLITE_ROW) {
                    }
                }
                sqlite3_finalize(statement);
                
                // fill annot column with 0 
                sql = @"UPDATE rubricdata SET annot = 0";
                returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
                if (returncode == SQLITE_OK) {
                    while (sqlite3_step(statement) == SQLITE_ROW) {
                    }
                }
                sqlite3_finalize(statement);
            }
            
            // user_id and modified columns are missing from the table (old database). Adding them
            if (useridMissing) {
                
                if (debugDatabase) NSLog(@"TPDatabase updating model add user_id and timestamp");
                
                sql = @"ALTER TABLE rubricdata ADD user_id integer";
                returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
                if (returncode == SQLITE_OK) {
                    while (sqlite3_step(statement) == SQLITE_ROW) {
                    }
                }
                sqlite3_finalize(statement);
                
                sql = @"ALTER TABLE rubricdata ADD modified timestamp";
                returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
                if (returncode == SQLITE_OK) {
                    while (sqlite3_step(statement) == SQLITE_ROW) {
                    }
                }
                sqlite3_finalize(statement);

            }
            
            // description column is missing from the userdata table (old database). Adding it
            if (descriptionMissing) {
                if (debugDatabase) NSLog(@"TPDatabase updating model add description");
                
                // add description column 
                sql = @"ALTER TABLE userdata ADD description varchar(1024)";
                returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
                if (returncode == SQLITE_OK) {
                    while (sqlite3_step(statement) == SQLITE_ROW) {
                    }
                }
                sqlite3_finalize(statement);
            }
            
            //jxi; aud_id column is missing from the userdata table (old database). Adding it
            if (audidMissing) {
                if (debugDatabase) NSLog(@"TPDatabase updating model add aud_id");
                
                // add description column
                sql = @"ALTER TABLE userdata ADD aud_id varchar(1024)";
                returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
                if (returncode == SQLITE_OK) {
                    while (sqlite3_step(statement) == SQLITE_ROW) {
                    }
                }
                sqlite3_finalize(statement);
            }
            
            //jxi; aq_id column is missing from the userdata table (old database). Adding it
            if (aqidMissing) {
                if (debugDatabase) NSLog(@"TPDatabase updating model add aq_id");
                
                // add description column
                sql = @"ALTER TABLE userdata ADD aq_id integer";
                returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
                if (returncode == SQLITE_OK) {
                    while (sqlite3_step(statement) == SQLITE_ROW) {
                    }
                }
                sqlite3_finalize(statement);
            }
            
            /*
            // imagedata table is missing from the database (old database). Adding it
            if (imagedataTableMissing) {
                
                if (debugDatabase) NSLog(@"TPDatabase updating model and database");
                
                sql = @"create table imagedata (\
                       district_id         integer,\
                       userdata_id         varchar(1024),\
                       type                integer,\
                       width               integer,\
                       height              integer,\
                       format              varchar(128),\
                       encoding            varchar(128),\
                       user_id             integer,\
                       modified            timestamp,\
                       filename            varchar(1024),\
                       origin              integer\
                       )";
                
                returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
                if (returncode == SQLITE_OK) {
                    while (sqlite3_step(statement) == SQLITE_ROW) {
                        if (debugDatabase) NSLog(@"Image table added to DB");
                    }
                }
                sqlite3_finalize(statement);
                
                // create folder for images
                NSError *error;
                [[NSFileManager defaultManager] createDirectoryAtPath:imagesPath withIntermediateDirectories:YES attributes:nil error:&error];
                
                // datevalue column is missing from the rubricdata table (old database). Adding it
                if (debugDatabase) NSLog(@"TPDatabase updating model add description");

                sql = @"ALTER TABLE rubricdata ADD datevalue timestamp";
                returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
                if (returncode == SQLITE_OK) {
                    while (sqlite3_step(statement) == SQLITE_ROW) {
                    }
                }
                sqlite3_finalize(statement);
            }
            */
            
            //jxi;
            // imagedata table or videodata table is missing from the database (old database). Adding it
            if (imagedataTableMissing || videodataTableMissing) {
                
                if (debugDatabase) NSLog(@"TPDatabase updating model and database");
                
                NSError *error;
                
                // imagedata table is missing from the database (old database). Adding it
                if (imagedataTableMissing) {
                
                    sql = @"create table imagedata (\
                    district_id         integer,\
                    userdata_id         varchar(1024),\
                    type                integer,\
                    width               integer,\
                    height              integer,\
                    format              varchar(128),\
                    encoding            varchar(128),\
                    user_id             integer,\
                    modified            timestamp,\
                    filename            varchar(1024),\
                    origin              integer\
                    )";
                    
                    returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
                    if (returncode == SQLITE_OK) {
                        while (sqlite3_step(statement) == SQLITE_ROW) {
                            if (debugDatabase) NSLog(@"Image table added to DB");
                        }
                    }
                    sqlite3_finalize(statement);
                    
                    // create folder for images
                    [[NSFileManager defaultManager] createDirectoryAtPath:imagesPath withIntermediateDirectories:YES attributes:nil error:&error];
                }
                
                // videodata table is missing from the database (old database). Adding it
                if (videodataTableMissing) {
                    
                    if (debugDatabase) NSLog(@"TPDatabase updating model and database");
                    
                    sql = @"create table videodata (\
                    district_id         integer,\
                    userdata_id         varchar(1024),\
                    type                integer,\
                    width               integer,\
                    height              integer,\
                    format              varchar(128),\
                    encoding            varchar(128),\
                    user_id             integer,\
                    modified            timestamp,\
                    filename            varchar(1024),\
                    origin              integer\
                    )";
                    
                    returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
                    if (returncode == SQLITE_OK) {
                        while (sqlite3_step(statement) == SQLITE_ROW) {
                            if (debugDatabase) NSLog(@"Video table added to DB");
                        }
                    }
                    sqlite3_finalize(statement);
                    
                    // create folder for videos
                    [[NSFileManager defaultManager] createDirectoryAtPath:videosPath withIntermediateDirectories:YES attributes:nil error:&error];
                }
                
                // datevalue column is missing from the rubricdata table (old database). Adding it
                if (debugDatabase) NSLog(@"TPDatabase updating model add description");
                
                sql = @"ALTER TABLE rubricdata ADD datevalue timestamp";
                returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
                if (returncode == SQLITE_OK) {
                    while (sqlite3_step(statement) == SQLITE_ROW) {
                    }
                }
                sqlite3_finalize(statement);
            }
        }
        
	} else {
		NSLog(@"ERROR: DB opening current database");
		sqlite3_close(database);
		NSAssert1(0, @"Failed to open database with code '%s'.", sqlite3_errmsg(database));
	}
}

// ------------------------------------------------------------------------------------
- (void) closeDatabase {
    
    if (debugDatabaseControl) NSLog(@"TPDatabase closeDatabase");
    
    if (database != NULL) {
        
        // Delete all the known images
        [self deleteData:@"imagedata"];
        
        // Delete all the known videos //jxi;
        [self deleteData:@"videodata"];
        
        if (debugDatabaseControl) NSLog(@"TPDatabase closeDatabase CLOSING");
        int returncode;
        while ((returncode = sqlite3_close(database)) == SQLITE_BUSY) { 
            if (debugDatabase) NSLog(@"SQLITE_BUSY: not all statements cleanly finalized");
            sqlite3_stmt *stmt; 
            while ((stmt = sqlite3_next_stmt(database, 0x00)) != 0) {
                if (debugDatabaseControl) NSLog(@"WAITING for SQL statement: %s", sqlite3_sql(stmt));
                sqlite3_finalize(stmt); 
            }
            // Wait on other threads to finish SQL statements
            usleep(1000);
        }
        if (returncode == SQLITE_OK) {
            if (debugDatabaseControl) NSLog(@"TPDatabase database close SUCCESS");
        } else {
            NSLog(@"ERROR: closing database with code %i (%s).", returncode, sqlite3_errmsg(database));
        }
        database = NULL;
    } else {
        if (debugDatabaseControl) NSLog(@"TPDatabase closeDatabase NULL");
    }
    
    // Destroy database by deleting file
    [TPDatabase destroyDatabase];
}

// ------------------------------------------------------------------------------------
+ (void) destroyDatabase {
    if (debugDatabaseControl) NSLog(@"TPDatabase destroyDatabase");
    [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@/Documents/rubricdb.sql", NSHomeDirectory()] error:NULL];
}

// ------------------------------------------------------------------------------------
+ (void) deleteAllImageFiles {
    if (debugDatabase) NSLog(@"TPDatabase deleteAllImageFiles");
    int count;
    NSString *imageDir = [TPDatabase imagePathDir];
    if (debugDatabase) NSLog(@"TPDatabase deleteAllImageFiles path %@", imageDir);
    NSArray *directoryContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:imageDir error:NULL];
    for (count = 0; count < (int)[directoryContent count]; count++) {
        NSString *filename = (NSString *)[directoryContent objectAtIndex:count];
        if (debugDatabase) NSLog(@"TPDatabase deleteAllImageFiles file %@", filename);
        [[NSFileManager defaultManager] removeItemAtPath:filename error:NULL];
    }
}

//jxi;
// ------------------------------------------------------------------------------------
+ (void) deleteAllVideoFiles {
    if (debugDatabase) NSLog(@"TPDatabase deleteAllVideoFiles");
    int count;
    NSString *videoDir = [TPDatabase videoPathDir];
    if (debugDatabase) NSLog(@"TPDatabase deleteAllVideoFiles path %@", videoDir);
    NSArray *directoryContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:videoDir error:NULL];
    for (count = 0; count < (int)[directoryContent count]; count++) {
        NSString *filename = (NSString *)[directoryContent objectAtIndex:count];
        if (debugDatabase) NSLog(@"TPDatabase deleteAllVideoFiles file %@", filename);
        [[NSFileManager defaultManager] removeItemAtPath:filename error:NULL];
    }
}

// ------------------------------------------------------------------------------------
- (void) clear {
    if (debugDatabase) NSLog(@"TPDatabase clear");
    [self deleteData:@"userdata"];
	[self deleteData:@"rubricdata"];
    [self deleteData:@"imagedata"];
    [self deleteData:@"videodata"]; //jxi;
}

// ------------------------------------------------------------------------------------
- (void) dumpDatabase {
	
	NSLog(@"DUMP DB");
	
	NSString *sql;
	int returncode;
	sqlite3_stmt *statement;
	    
	// Dump user data
	sql = [NSString stringWithFormat:@"select district_id, user_id, target_id, share, school_id, subject_id, grade, \
           elapsed, type, rubric_id, name, userdata_id, state, created, modified, description, aud_id, aq_id from userdata order by user_id, created"];//jxi;
	returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
	if (returncode == SQLITE_OK) {
		NSLog(@" Userdata:");
		while (sqlite3_step(statement) == SQLITE_ROW) {
			int district_id   = (int)sqlite3_column_int(statement, 0);
            int user_id       = (int)sqlite3_column_int(statement, 1);
			int target_id     = (int)sqlite3_column_int(statement, 2);
            int share         = (int)sqlite3_column_int(statement, 3);
            int school_id     = (int)sqlite3_column_int(statement, 4);
            int subject_id    = (int)sqlite3_column_int(statement, 5);
            int grade         = (int)sqlite3_column_int(statement, 6);
            int elapsed       = (int)sqlite3_column_int(statement, 7);
            int type          = (int)sqlite3_column_int(statement, 8);
            int rubric_id     = (int)sqlite3_column_int(statement, 9);
            char *name        = (char *)sqlite3_column_text(statement, 10);
            char *userdata_id = (char *)sqlite3_column_text(statement, 11);
            int state         = (int)sqlite3_column_int(statement, 12);
            char *created     = (char *)sqlite3_column_text(statement, 13);
			char *modified    = (char *)sqlite3_column_text(statement, 14);
			char *description = (char *)sqlite3_column_text(statement, 15);
            char *aud_id      = (char *)sqlite3_column_text(statement, 16); //jxi;
			int aq_id         = (int)sqlite3_column_int(statement, 17); //jxi;
            NSLog(@"  user=%d created=%s ID=%s target=%d district=%d share=%d school=%d subject=%d grade=%d elapsed=%d type=%d rubric=%d name=%s state=%d modified=%s, description=%s AUD_ID=%s AQ_ID=%d",
				  user_id, created, userdata_id, target_id, district_id, share, school_id, subject_id, grade, elapsed, type, rubric_id, name, state, modified, description, aud_id, aq_id); //jxi;
		}
	} else {
		NSLog(@"ERROR: DB dumpDatabase 1 failed with code %d", returncode);
	}
	sqlite3_finalize(statement);
	
	// Dump rubric data
	sql = [NSString stringWithFormat:@"select district_id, userdata_id, rubric_id, question_id, rating_id, value, text, annot, user_id, modified, datevalue \
           from rubricdata order by userdata_id"];
	returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
	if (returncode == SQLITE_OK) {
		NSLog(@" Rubricdata:");
		while (sqlite3_step(statement) == SQLITE_ROW) {
			int district_id = (int)sqlite3_column_int(statement, 0);
            char *userdata_id = (char *)sqlite3_column_text(statement, 1);
			int rubric_id = (int)sqlite3_column_int(statement, 2);
            int question_id = (int)sqlite3_column_int(statement, 3);
            int rating_id = (int)sqlite3_column_int(statement, 4);
			float value = (float)sqlite3_column_int(statement, 5);
            char *text = (char *)sqlite3_column_text(statement, 6);
            int annot = (int)sqlite3_column_int(statement, 7);
            int user_id = (int)sqlite3_column_int(statement, 8);
			char *modified = (char *)sqlite3_column_text(statement, 9);
            char *datevalue = (char*)sqlite3_column_text(statement, 10);
			NSLog(@"  ID=%s rubric=%d question=%d rating=%d value=%f text=%s district=%d annot=%d user=%d modified=%s datevalue=%s",
				  userdata_id, rubric_id, question_id, rating_id, value, text, district_id, annot, user_id, modified, datevalue);			
		}
	} else {
		NSLog(@"ERROR: DB dumpDatabase 2 failed with code %d", returncode);
	}
	sqlite3_finalize(statement);

    // Dump image data
	sql = [NSString stringWithFormat:@"select district_id, userdata_id, type, width, height, format, encoding, user_id, modified, filename, origin \
           from imagedata order by user_id, type, userdata_id"];
	returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
	if (returncode == SQLITE_OK) {
		NSLog(@" Imagedata:");
		while (sqlite3_step(statement) == SQLITE_ROW) {
			int district_id = (int)sqlite3_column_int(statement, 0);
            char *userdata_id = (char *)sqlite3_column_text(statement, 1);
            int type = (int)sqlite3_column_int(statement, 2);
			int width = (int)sqlite3_column_int(statement, 3);
			int height = (int)sqlite3_column_int(statement, 4);
            char *format = (char *)sqlite3_column_text(statement, 5);
            char *encoding = (char *)sqlite3_column_text(statement, 6);
            int user_id = (int)sqlite3_column_int(statement, 7);
            char *modified = (char *)sqlite3_column_text(statement, 8);
            char *filename = (char *)sqlite3_column_text(statement, 9);
            int origin = (int)sqlite3_column_int(statement, 10);
            
			NSLog(@"  ID=%s district=%d type=%d width=%d height=%d format=%s encoding=%s user_id=%d modified=%s filename=%s, origin = %d",
				  userdata_id, district_id, type, width, height, format, encoding, user_id, modified, filename, origin);			
		}
	} else {
		NSLog(@"ERROR: DB dumpDatabase 3 failed with code %d", returncode);
	}
	sqlite3_finalize(statement);

	NSLog(@"DUMP DB COMPLETE");
    
    [TPDatabase dumpImageDirContents];
    
    // Dump video data //jxi;
    sql = [NSString stringWithFormat:@"select district_id, userdata_id, type, width, height, format, encoding, user_id, modified, filename, origin \
           from videodata order by user_id, type, userdata_id"];
    returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
    if (returncode == SQLITE_OK) {
        NSLog(@" Videodata:");
        while (sqlite3_step(statement) == SQLITE_ROW) {
            int district_id = (int)sqlite3_column_int(statement, 0);
            char *userdata_id = (char *)sqlite3_column_text(statement, 1);
            int type = (int)sqlite3_column_int(statement, 2);
            int width = (int)sqlite3_column_int(statement, 3);
            int height = (int)sqlite3_column_int(statement, 4);
            char *format = (char *)sqlite3_column_text(statement, 5);
            char *encoding = (char *)sqlite3_column_text(statement, 6);
            int user_id = (int)sqlite3_column_int(statement, 7);
            char *modified = (char *)sqlite3_column_text(statement, 8);
            char *filename = (char *)sqlite3_column_text(statement, 9);
            int origin = (int)sqlite3_column_int(statement, 10);
            
            NSLog(@"  ID=%s district=%d type=%d width=%d height=%d format=%s encoding=%s user_id=%d modified=%s filename=%s, origin = %d",
                  userdata_id, district_id, type, width, height, format, encoding, user_id, modified, filename, origin);
        }
    } else {
        NSLog(@"ERROR: DB dumpDatabase 3 failed with code %d", returncode);
    }
    sqlite3_finalize(statement);
    
    NSLog(@"DUMP DB COMPLETE");
    
    [TPDatabase dumpVideoDirContents];
}

// ------------------------------------------------------------------------------------
- (void) dumpDatabaseShort {
	
	NSLog(@"DUMP DB");
	
	NSString *sql;
	int returncode;
	sqlite3_stmt *statement;
    
	// Dump user data
	sql = [NSString stringWithFormat:@"select district_id, user_id, target_id, share, school_id, subject_id, grade, \
           elapsed, type, rubric_id, name, userdata_id, state, created, modified, description, aud_id, aq_id from userdata order by user_id, created"];//jxi;
	returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
	if (returncode == SQLITE_OK) {
		NSLog(@" Userdata:");
		while (sqlite3_step(statement) == SQLITE_ROW) {
			int district_id   = (int)sqlite3_column_int(statement, 0);
            int user_id       = (int)sqlite3_column_int(statement, 1);
			int target_id     = (int)sqlite3_column_int(statement, 2);
            int share         = (int)sqlite3_column_int(statement, 3);
            int type          = (int)sqlite3_column_int(statement, 8);
            char *name        = (char *)sqlite3_column_text(statement, 10);
            char *userdata_id = (char *)sqlite3_column_text(statement, 11);
            int state         = (int)sqlite3_column_int(statement, 12);
            char *created     = (char *)sqlite3_column_text(statement, 13);
            char *aud_id     = (char *)sqlite3_column_text(statement, 16); //jxi;
            int aq_id          = (int)sqlite3_column_int(statement, 17); //jxi;
			NSLog(@"  ID=%s district=%d user=%d target=%d created=%s share=%d type=%d name=%s state=%d AUD_ID=%s AQ_ID=%d",
				  userdata_id, district_id, user_id, target_id, created, share, type, name, state, aud_id, aq_id); //jxi;
		}
	} else {
		NSLog(@"ERROR: DB dumpDatabaseShort 1 failed with code %d", returncode);
	}
	sqlite3_finalize(statement);
    
    // Dump image data
	sql = [NSString stringWithFormat:@"select district_id, userdata_id, type, width, height, format, encoding, user_id, modified, filename, origin \
           from imagedata order by user_id, type, userdata_id"];
	returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
	if (returncode == SQLITE_OK) {
		NSLog(@" Imagedata:");
		while (sqlite3_step(statement) == SQLITE_ROW) {
			int district_id = (int)sqlite3_column_int(statement, 0);
            char *userdata_id = (char *)sqlite3_column_text(statement, 1);
            int type = (int)sqlite3_column_int(statement, 2);
            int user_id = (int)sqlite3_column_int(statement, 7);
            char *modified = (char *)sqlite3_column_text(statement, 8);
            char *filename = (char *)sqlite3_column_text(statement, 9);
            int origin = (int)sqlite3_column_int(statement, 10);
            
			NSLog(@"  ID=%s district=%d type=%d user_id=%d modified=%s filename=%s, origin = %d",
				  userdata_id, district_id, type, user_id, modified, filename, origin);
		}
	} else {
		NSLog(@"ERROR: DB dumpDatabaseShort 2 failed with code %d", returncode);
	}
	sqlite3_finalize(statement);
    
	NSLog(@"DUMP DB COMPLETE");
    
    [TPDatabase dumpImageDirContents];
}

// ------------------------------------------------------------------------------------
+ (void) dumpImageDirContents {
    
    NSLog(@"DUMP IMAGE FILES");
    int count;
    NSString *imageDir = [TPDatabase imagePathDir];
    NSArray *directoryContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:imageDir error:NULL];
    for (count = 0; count < (int)[directoryContent count]; count++) {
        NSLog(@"File %d: %@", (count + 1), [directoryContent objectAtIndex:count]);
    }
    NSLog(@"DUMP IMAGE FILES COMPLETE");
}

//jxi;
// ------------------------------------------------------------------------------------
+ (void) dumpVideoDirContents {
    
    NSLog(@"DUMP VIDEO FILES");
    int count;
    NSString *videoDir = [TPDatabase videoPathDir];
    NSArray *directoryContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:videoDir error:NULL];
    for (count = 0; count < (int)[directoryContent count]; count++) {
        NSLog(@"File %d: %@", (count + 1), [directoryContent objectAtIndex:count]);
    }
    NSLog(@"DUMP VIDEO FILES COMPLETE");
}

// ------------------------------------------------------------------------------------
// ------------------------------------------------------------------------------------
- (void) deleteData:(NSString *)tablename {
		
    if (debugDatabase) NSLog(@"TPDatabase deleteData %@", tablename);
    
	int returncode;
	sqlite3_stmt *statement;
	NSString *sql;
            
    // Remove all image files
    if ([tablename isEqualToString:@"imagedata"]) {
        NSMutableArray *filenames = [NSMutableArray array];
        sql = @"select filename from imagedata"; 
        returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
        if (returncode == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                char *filename = (char *)sqlite3_column_text(statement, 0);
                NSURL *url = [NSURL fileURLWithPath:[NSString stringWithUTF8String:filename] isDirectory:NO];
                [filenames addObject:url];
            }
        } else {
            NSLog(@"ERROR: DB deleteData 1 failed with code %d", returncode);
        }
        sqlite3_finalize(statement);
        
        for (NSURL *url in filenames) {
            if (debugDatabase) NSLog(@"TPDatabase deleteData removing %@", url.absoluteString);
            NSError *error;
            [[NSFileManager defaultManager] removeItemAtURL:url error:&error];
        }
    }
    
    // Remove all video files //jxi;
    if ([tablename isEqualToString:@"videodata"]) {
        NSMutableArray *filenames = [NSMutableArray array];
        sql = @"select filename from videodata";
        returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
        if (returncode == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                char *filename = (char *)sqlite3_column_text(statement, 0);
                NSURL *url = [NSURL fileURLWithPath:[NSString stringWithUTF8String:filename] isDirectory:NO];
                [filenames addObject:url];
            }
        } else {
            NSLog(@"ERROR: DB deleteData 1 failed with code %d", returncode);
        }
        sqlite3_finalize(statement);
        
        for (NSURL *url in filenames) {
            if (debugDatabase) NSLog(@"TPDatabase deleteData removing %@", url.absoluteString);
            NSError *error;
            [[NSFileManager defaultManager] removeItemAtURL:url error:&error];
        }
    }
    
    // Delete rows in database table
	sql = [NSString stringWithFormat:@"delete from %@", tablename];
	returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
	if (returncode == SQLITE_OK) {
		returncode = sqlite3_step(statement);
        if (returncode != SQLITE_DONE) NSLog(@"ERROR: DB step failed with code %d", returncode);
	} else {
		NSLog(@"ERROR: DB deleteData 2 failed with code %d", returncode);
	}
	sqlite3_finalize(statement);
	
}

// ------------------------------------------------------------------------------------
// ------------------------------------------------------------------------------------
- (int) numUserData {
		
	int returncode;
	int num_data;
	sqlite3_stmt *statement;
	        
	const char *sql = "select count(distinct userdata_id) from userdata";
	returncode = sqlite3_prepare_v2(database, sql, -1, &statement, NULL);
	if (returncode == SQLITE_OK) {
		returncode = sqlite3_step(statement);
		if (returncode == SQLITE_ROW) {
			num_data = (int)sqlite3_column_int(statement, 0);
			sqlite3_finalize(statement);
			return num_data;
		} else {
			sqlite3_finalize(statement);
			return 0;
		}
	} else {
		NSLog(@"ERROR: DB numUserData failed with code %d", returncode);
		sqlite3_finalize(statement);
		return -1;
	}
}


// ------------------------------------------------------------------------------------
// getUserData - get userdata, without rubricdata list, based on userdata ID
// ------------------------------------------------------------------------------------
- (TPUserData *) getUserData:(NSString *)userdata_id {
    
    int returncode;
	sqlite3_stmt *statement;
    NSString *sql;
    TPUserData *userdata = NULL;
    
	// Get userdata objects
    sql = [NSString stringWithFormat:@"select district_id, user_id, target_id, share, school_id, subject_id, grade, elapsed, \
           type, rubric_id, name, userdata_id, state, created, modified, description from userdata where userdata_id = '%@'", userdata_id];
	returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
	if (returncode == SQLITE_OK) {
		while (sqlite3_step(statement) == SQLITE_ROW) {
            userdata = [[[TPUserData alloc] init] autorelease];
			userdata.district_id = (int)sqlite3_column_int(statement, 0);
            userdata.user_id = (int)sqlite3_column_int(statement, 1);
			userdata.target_id = (int)sqlite3_column_int(statement, 2);
            userdata.share = (int)sqlite3_column_int(statement, 3);
            userdata.school_id = (int)sqlite3_column_int(statement, 4);
            userdata.subject_id = (int)sqlite3_column_int(statement, 5);
            userdata.grade = (int)sqlite3_column_int(statement, 6);
            userdata.elapsed = (int)sqlite3_column_int(statement, 7);
            userdata.type = (int)sqlite3_column_int(statement, 8);
            userdata.rubric_id = (int)sqlite3_column_int(statement, 9);
            userdata.name = [NSString stringWithFormat:@"%s", (char *)sqlite3_column_text(statement, 10)];
            userdata.userdata_id = [NSString stringWithFormat:@"%s", (char *)sqlite3_column_text(statement, 11)];
            userdata.state = (int)sqlite3_column_int(statement, 12);
            char *created = (char *)sqlite3_column_text(statement, 13);
            userdata.created = [self dateFromCharStr:created];
			char *modified = (char *)sqlite3_column_text(statement, 14);
            userdata.modified = [self dateFromCharStr:modified];
            userdata.description = [NSString stringWithFormat:@"%s", (char *)sqlite3_column_text(statement, 15)];
		}
	} else {
		NSLog(@"ERROR: DB getUserData failed with code %d", returncode);
	}
	sqlite3_finalize(statement);
    
    return userdata;
}


// ------------------------------------------------------------------------------------
// getTotalElapsedByUserId - get list of total elapsed times for all users
// ------------------------------------------------------------------------------------
- (NSDictionary *) getTotalElapsedByUserId:(int)filterUserId {
    
    int returncode;
	sqlite3_stmt *statement;
    NSString *sql;
    
    NSMutableDictionary *totalElapsedByUserId = [[[NSMutableDictionary alloc] initWithCapacity:100] autorelease];
    
    // Create only own data filter
    NSString *ownDataFilter;
    if (filterUserId > 0) {
        ownDataFilter = [NSString stringWithFormat:@" and userdata.user_id = %d", filterUserId];
    } else {
        ownDataFilter = @"";
    }
    
	// Get elapsed time
    sql = [NSString stringWithFormat:@"select target_id, sum(elapsed) from userdata where type = 1 %@ group by target_id", ownDataFilter];
	returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
	if (returncode == SQLITE_OK) {
		while (sqlite3_step(statement) == SQLITE_ROW) {
            int target_id = (int)sqlite3_column_int(statement, 0);
            int elapsed = (int)sqlite3_column_int(statement, 1);
            [totalElapsedByUserId setObject:[NSNumber numberWithInt: elapsed] forKey:[NSNumber numberWithInt:target_id]];
		}
	} else {
		NSLog(@"ERROR: DB getTotalElapsedList failed with code %d", returncode);
	}
	sqlite3_finalize(statement);
    
    return totalElapsedByUserId;
}


// ------------------------------------------------------------------------------------
// getTotalFormsByUserId - get list of total recorded forms for all users
// ------------------------------------------------------------------------------------
- (NSDictionary *) getTotalFormsByUserId:(int)filterUserId {
    
    int returncode;
	sqlite3_stmt *statement;
    NSString *sql;
    
    NSMutableDictionary *totalRubricsByUserId = [[[NSMutableDictionary alloc] initWithCapacity:100] autorelease];
    
    // Create only own data filter
    NSString *ownDataFilter;
    if (filterUserId > 0) {
        ownDataFilter = [NSString stringWithFormat:@" and userdata.user_id = %d", filterUserId];
    } else {
        ownDataFilter = @"";
    }
    
    // Get rubric data for each userdata object
    sql = [NSString stringWithFormat:@"select target_id, count(*) from userdata where type = 1 %@ group by target_id", ownDataFilter];
	returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
	if (returncode == SQLITE_OK) {
		while (sqlite3_step(statement) == SQLITE_ROW) {
            int target_id = (int)sqlite3_column_int(statement, 0);
            int num_forms = (int)sqlite3_column_int(statement, 1);
            [totalRubricsByUserId setObject:[NSNumber numberWithInt: num_forms] forKey:[NSNumber numberWithInt:target_id]];
		}
	} else {
		NSLog(@"ERROR: DB getTotalRubricsList failed with code %d", returncode);
	}
	sqlite3_finalize(statement);
    
    return totalRubricsByUserId;
}

// ------------------------------------------------------------------------------------
// getUserDataList - update list to include userdata for target user, filtered by userId
// ------------------------------------------------------------------------------------
- (void) getUserDataList:(NSMutableArray *)userdata_list target:(int)target_id filterUserId:(int)filterUserId {
    
    int returncode;
	sqlite3_stmt *statement;
    NSString *sql;
    TPUserData *userdata;
    TPRubricData *rubricdata;
    
    // Create only own data filter
    NSString *ownDataFilter;
    if (filterUserId > 0) {
        ownDataFilter = [NSString stringWithFormat:@" and userdata.user_id = %d ", filterUserId];
    } 
    else {
        ownDataFilter = @"";
    }
    
    // Clear list
    [userdata_list removeAllObjects];
    
	// Get userdata objects //jxi; aud_id, aq_id fiels added
    sql = [NSString stringWithFormat:@"\
           select district_id, user_id, target_id, share, school_id, subject_id, grade, elapsed, \
                  type, rubric_id, name, userdata_id, state, created, modified, description, aud_id, aq_id  \
            from userdata \
           where target_id = %d %@ \
        order by created desc", target_id, ownDataFilter];
	returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
	if (returncode == SQLITE_OK) {
		while (sqlite3_step(statement) == SQLITE_ROW) {
            userdata = [[TPUserData alloc] init];
			userdata.district_id = (int)sqlite3_column_int(statement, 0);
            userdata.user_id = (int)sqlite3_column_int(statement, 1);
			userdata.target_id = (int)sqlite3_column_int(statement, 2);
            userdata.share = (int)sqlite3_column_int(statement, 3);
            userdata.school_id = (int)sqlite3_column_int(statement, 4);
            userdata.subject_id = (int)sqlite3_column_int(statement, 5);
            userdata.grade = (int)sqlite3_column_int(statement, 6);
            userdata.elapsed = (int)sqlite3_column_int(statement, 7);
            userdata.type = (int)sqlite3_column_int(statement, 8);
            userdata.rubric_id = (int)sqlite3_column_int(statement, 9);
            userdata.name = [NSString stringWithFormat:@"%s", (char *)sqlite3_column_text(statement, 10)];
            userdata.userdata_id = [NSString stringWithFormat:@"%s", (char *)sqlite3_column_text(statement, 11)];
            userdata.state = (int)sqlite3_column_int(statement, 12);
            char *created = (char *)sqlite3_column_text(statement, 13);
            userdata.created = [self dateFromCharStr:created];
			char *modified = (char *)sqlite3_column_text(statement, 14);
            userdata.modified = [self dateFromCharStr:modified];
            userdata.description = [NSString stringWithFormat:@"%s", (char *)sqlite3_column_text(statement, 15)];
            userdata.aud_id = [NSString stringWithFormat:@"%s", (char *)sqlite3_column_text(statement, 16)]; //jxi
            userdata.aq_id = (int)sqlite3_column_int(statement, 17); //jxi
            
            [userdata_list addObject:userdata];
            [userdata release];
		}
	} else {
		NSLog(@"ERROR: DB getUserDataList 1 failed with code %d", returncode);
	}
	sqlite3_finalize(statement);
    
    
    // Get rubric data for each userdata object
    for (TPUserData *data in userdata_list) {
        sql = [NSString stringWithFormat:@"\
               select district_id, userdata_id, rubric_id, question_id, rating_id, value, text, annot, user_id, modified, datevalue \
                 from rubricdata \
                where userdata_id = '%@'", data.userdata_id];
        returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
        if (returncode == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                rubricdata = [[TPRubricData alloc] init];
                rubricdata.district_id = (int)sqlite3_column_int(statement, 0);
                rubricdata.userdata_id = [NSString stringWithFormat:@"%s", (char *)sqlite3_column_text(statement, 1)];
                rubricdata.rubric_id = (int)sqlite3_column_int(statement, 2);
                rubricdata.question_id = (int)sqlite3_column_int(statement, 3);
                rubricdata.rating_id = (int)sqlite3_column_int(statement, 4);
                rubricdata.value = (float)sqlite3_column_int(statement, 5);
                rubricdata.text = [NSString stringWithFormat:@"%s", (char *)sqlite3_column_text(statement, 6)];
                rubricdata.annotation = (int)sqlite3_column_int(statement, 7);
                rubricdata.user = (int)sqlite3_column_int(statement, 8);
                rubricdata.modified = [self dateFromCharStr:(char *)sqlite3_column_text(statement, 9)];
                rubricdata.datevalue = [self dateFromCharStr:(char *)sqlite3_column_text(statement, 10)];
                [data.rubricdata addObject:rubricdata];
                [rubricdata release];
            }
        } else {
            NSLog(@"ERROR: DB getUserDataList 2 failed with code %d", returncode);
        }
        sqlite3_finalize(statement);
    }
}

// ------------------------------------------------------------------------------------
// getImageList - update list to include images for target user, filtered by userId
// ------------------------------------------------------------------------------------
- (void) getImageList:(NSMutableArray *)image_list target:(int)target_id filterUserId:(int)filterUserId {

    int returncode;
	sqlite3_stmt *statement;
    NSString *sql;
    TPUserData *userdata;
    NSMutableArray *userdata_list = [NSMutableArray array];
    TPImage *image;
    
    // Clear image list
    [image_list removeAllObjects];
    
    // Create only own data filter
    NSString *ownDataFilter;
    if (filterUserId > 0) {
        ownDataFilter = [NSString stringWithFormat:@" and userdata.user_id = %d ", filterUserId];
    } else {
        ownDataFilter = @"";
    }
    
    // Get userdata objects
    sql = [NSString stringWithFormat:@"\
          select district_id, user_id, target_id, share, school_id, subject_id, grade, elapsed, \
                 type, rubric_id, name, userdata_id, state, created, modified, aud_id, aq_id \
            from userdata \
           where type = 3 \
             and target_id = %d %@ \
        order by created desc",
           target_id, ownDataFilter];
	returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
    if (returncode == SQLITE_OK) {
    	while (sqlite3_step(statement) == SQLITE_ROW) {
            userdata = [[TPUserData alloc] init];
			userdata.district_id = (int)sqlite3_column_int(statement, 0);
            userdata.user_id = (int)sqlite3_column_int(statement, 1);
			userdata.target_id = (int)sqlite3_column_int(statement, 2);
            userdata.share = (int)sqlite3_column_int(statement, 3);
            userdata.school_id = (int)sqlite3_column_int(statement, 4);
            userdata.subject_id = (int)sqlite3_column_int(statement, 5);
            userdata.grade = (int)sqlite3_column_int(statement, 6);
            userdata.elapsed = (int)sqlite3_column_int(statement, 7);
            userdata.type = (int)sqlite3_column_int(statement, 8);
            userdata.rubric_id = (int)sqlite3_column_int(statement, 9);
            userdata.name = [NSString stringWithFormat:@"%s", (char *)sqlite3_column_text(statement, 10)];
            userdata.userdata_id = [NSString stringWithFormat:@"%s", (char *)sqlite3_column_text(statement, 11)];
            userdata.state = (int)sqlite3_column_int(statement, 12);
            char *created = (char *)sqlite3_column_text(statement, 13);
            userdata.created = [self dateFromCharStr:created];
			char *modified = (char *)sqlite3_column_text(statement, 14);
            userdata.modified = [self dateFromCharStr:modified];
            userdata.aud_id = [NSString stringWithFormat:@"%s", (char *)sqlite3_column_text(statement, 15)]; //jxi
            userdata.aq_id = (int)sqlite3_column_int(statement, 16); //jxi
            [userdata_list addObject:userdata];
            [userdata release];
		}
	} else {
		NSLog(@"ERROR: DB getImageList 1 failed with code %d", returncode);
	}
	sqlite3_finalize(statement);
	// Get image data for each userdata object and put it in the image list
    for (TPUserData *userdata in userdata_list) {
        sql = [NSString stringWithFormat:@"select district_id, type, width, height, format, encoding, user_id, modified, filename, origin \
               from imagedata where userdata_id = '%@' order by user_id, type, userdata_id", userdata.userdata_id];
        returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
        if (returncode == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                // main image
                image = [[TPImage alloc] init];
                image.district_id = (int)sqlite3_column_int(statement, 0);
                image.userdata_id = userdata.userdata_id;
                image.type = (int)sqlite3_column_int(statement, 1);
                image.width = (int)sqlite3_column_int(statement, 2);
                image.height = (int)sqlite3_column_int(statement, 3);
                image.format = [NSString stringWithFormat:@"%s", (char *)sqlite3_column_text(statement, 4)];
                image.encoding = [NSString stringWithFormat:@"%s", (char *)sqlite3_column_text(statement, 5)];
                image.user_id = (int)sqlite3_column_int(statement, 6);
                char *modified = (char *)sqlite3_column_text(statement, 7);
                image.modified = [self dateFromCharStr:modified];
                image.filename = [NSString stringWithFormat:@"%s", (char *)sqlite3_column_text(statement, 8)];
                image.image = [UIImage imageWithContentsOfFile:image.filename];
                image.origin = (int)sqlite3_column_int(statement, 9);
                [image_list addObject:image];
                [image release];
            }
        } else {
            NSLog(@"ERROR: DB getImageList 2 failed with code %d", returncode);
        }
        sqlite3_finalize(statement);
    }
}

// ------------------------------------------------------------------------------------
// imageDataDoesExist - return TRUE if image data does exists (imagedata record and
// corresponding image file), given specified image type
// ------------------------------------------------------------------------------------
- (BOOL) imageDataDoesExist:(NSString *)userdataId imageType:(int)imageType {
    
    if (debugDatabase) NSLog(@"TPDatabase imageDataDoesExist %d %@", imageType, userdataId);
    
    int returncode;
	sqlite3_stmt *statement;
    NSString *sql;
    NSString *filename;
    BOOL found;
    
    // Get list of images
    found = NO;
    sql = [NSString stringWithFormat:@"select filename \
           from imagedata where userdata_id = '%@' and type = %d", userdataId, imageType];
    returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
    if (returncode == SQLITE_OK) {
        while (sqlite3_step(statement) == SQLITE_ROW) {
            filename = [NSString stringWithFormat:@"%s", (char *)sqlite3_column_text(statement, 0)];
            found = YES;
        }
    } else {
        NSLog(@"ERROR: DB imageDataDoesExist failed with code %d", returncode);
    }
    sqlite3_finalize(statement);
    
    if (!found) {
        if (debugDatabase) NSLog(@"TPDatabase imageDataDoesExist NO imagedata record not found");
        return NO;
    }
    
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:filename];
    if (fileExists) {
        if (debugDatabase) NSLog(@"TPDatabase imageDataDoesExist YES");
        return YES;
    } else {
        if (debugDatabase) NSLog(@"TPDatabase imageDataDoesExist NO - file not found %@", filename);
        return NO;
    }    
}

// ------------------------------------------------------------------------------------
// imageFileDoesExist - return TRUE if image file does exists.
// ------------------------------------------------------------------------------------
- (BOOL) imageFileDoesExist:(NSString *)userdataId imageType:(int)imageType {
    
    if (debugDatabase) NSLog(@"TPDatabase imageFileDoesExist %d %@", imageType, userdataId);
    
    // Get the image path
    NSString *imagePath = [TPDatabase imagePathWithUserdataID:userdataId
                                                      suffix:@"jpg"
                                                   imageType:imageType];
    
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:imagePath];
    if (fileExists) {
        if (debugDatabase) NSLog(@"TPDatabase imageFileDoesExist YES");
        return YES;
    } else {
        if (debugDatabase) NSLog(@"TPDatabase imageFileDoesExist NO - file with path not found %@", imagePath);
        return NO;
    }
}


// ------------------------------------------------------------------------------------
// getImageListByUserdataId - get list of image objects given userdata ID
// ------------------------------------------------------------------------------------
- (void) getImageListByUserdataId:(NSMutableArray *)image_list userdataId:(NSString *)userdataId {
    
    int returncode;
	sqlite3_stmt *statement;
    NSString *sql;
    
    // Clear image list
    [image_list removeAllObjects];
    
    // Get list of images
    sql = [NSString stringWithFormat:@"select district_id, userdata_id, type, width, height, format, encoding, user_id, modified, filename, origin \
           from imagedata where userdata_id = '%@'", userdataId];
    returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
    if (returncode == SQLITE_OK) {
        while (sqlite3_step(statement) == SQLITE_ROW) {
            TPImage *image = [[TPImage alloc] init];
            image.district_id = (int)sqlite3_column_int(statement, 0);
            image.userdata_id = [NSString stringWithFormat:@"%s", (char *)sqlite3_column_text(statement, 1)];
            image.type = (int)sqlite3_column_int(statement, 2);
            image.width = (int)sqlite3_column_int(statement, 3);
            image.height = (int)sqlite3_column_int(statement, 4);
            image.format = [NSString stringWithFormat:@"%s", (char *)sqlite3_column_text(statement, 5)];
            image.encoding = [NSString stringWithFormat:@"%s", (char *)sqlite3_column_text(statement, 6)];
            image.user_id = (int)sqlite3_column_int(statement, 7);
            char *modified = (char *)sqlite3_column_text(statement, 8);
            image.modified = [self dateFromCharStr:modified];
            image.filename = [NSString stringWithFormat:@"%s", (char *)sqlite3_column_text(statement, 9)];
            image.image = [UIImage imageWithContentsOfFile:image.filename];
            image.origin = (int)sqlite3_column_int(statement, 10);
            [image_list addObject:image];
            [image release];
        }
    } else {
        NSLog(@"ERROR: DB getImageListByUserdataId failed with code %d", returncode);
    }
    sqlite3_finalize(statement);
}

// ------------------------------------------------------------------------------------
// getVideoList - update list to include videos for target user, filtered by userId
// ------------------------------------------------------------------------------------
- (void) getVideoList:(NSMutableArray *)video_list target:(int)target_id filterUserId:(int)filterUserId {
    
    int returncode;
    sqlite3_stmt *statement;
    NSString *sql;
    TPUserData *userdata;
    NSMutableArray *userdata_list = [NSMutableArray array];
    TPVideo *video;
    
    // Clear image list
    [video_list removeAllObjects];
    
    // Create only own data filter
    NSString *ownDataFilter;
    if (filterUserId > 0) {
        ownDataFilter = [NSString stringWithFormat:@" and userdata.user_id = %d ", filterUserId];
    } else {
        ownDataFilter = @"";
    }
    
    // Get userdata objects
    sql = [NSString stringWithFormat:@"\
           select district_id, user_id, target_id, share, school_id, subject_id, grade, elapsed, \
           type, rubric_id, name, userdata_id, state, created, modified \
           from userdata \
           where type = 4 \
           and target_id = %d %@ \
           order by created desc",
           target_id, ownDataFilter];
    returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
    if (returncode == SQLITE_OK) {
        while (sqlite3_step(statement) == SQLITE_ROW) {
            userdata = [[TPUserData alloc] init];
            userdata.district_id = (int)sqlite3_column_int(statement, 0);
            userdata.user_id = (int)sqlite3_column_int(statement, 1);
            userdata.target_id = (int)sqlite3_column_int(statement, 2);
            userdata.share = (int)sqlite3_column_int(statement, 3);
            userdata.school_id = (int)sqlite3_column_int(statement, 4);
            userdata.subject_id = (int)sqlite3_column_int(statement, 5);
            userdata.grade = (int)sqlite3_column_int(statement, 6);
            userdata.elapsed = (int)sqlite3_column_int(statement, 7);
            userdata.type = (int)sqlite3_column_int(statement, 8);
            userdata.rubric_id = (int)sqlite3_column_int(statement, 9);
            userdata.name = [NSString stringWithFormat:@"%s", (char *)sqlite3_column_text(statement, 10)];
            userdata.userdata_id = [NSString stringWithFormat:@"%s", (char *)sqlite3_column_text(statement, 11)];
            userdata.state = (int)sqlite3_column_int(statement, 12);
            char *created = (char *)sqlite3_column_text(statement, 13);
            userdata.created = [self dateFromCharStr:created];
            char *modified = (char *)sqlite3_column_text(statement, 14);
            userdata.modified = [self dateFromCharStr:modified];
            [userdata_list addObject:userdata];
            [userdata release];
        }
    } else {
        NSLog(@"ERROR: DB getVideoList 1 failed with code %d", returncode);
    }
    sqlite3_finalize(statement);
    // Get image data for each userdata object and put it in the image list
    for (TPUserData *userdata in userdata_list) {
        sql = [NSString stringWithFormat:@"select district_id, type, width, height, format, encoding, user_id, modified, filename, origin \
               from videodata where userdata_id = '%@' order by user_id, type, userdata_id", userdata.userdata_id];
        returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
        if (returncode == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                // main image
                video = [[TPVideo alloc] init];
                video.district_id = (int)sqlite3_column_int(statement, 0);
                video.userdata_id = userdata.userdata_id;
                video.type = (int)sqlite3_column_int(statement, 1);
                video.width = (int)sqlite3_column_int(statement, 2);
                video.height = (int)sqlite3_column_int(statement, 3);
                video.format = [NSString stringWithFormat:@"%s", (char *)sqlite3_column_text(statement, 4)];
                video.encoding = [NSString stringWithFormat:@"%s", (char *)sqlite3_column_text(statement, 5)];
                video.user_id = (int)sqlite3_column_int(statement, 6);
                char *modified = (char *)sqlite3_column_text(statement, 7);
                video.modified = [self dateFromCharStr:modified];
                video.filename = [NSString stringWithFormat:@"%s", (char *)sqlite3_column_text(statement, 8)];
                NSURL *videoURL = [NSURL fileURLWithPath:video.filename];//self.videoUrl;
                
                MPMoviePlayerController *player = [[MPMoviePlayerController alloc] initWithContentURL:videoURL];
                
                video.thumbImage = [player thumbnailImageAtTime:1.0 timeOption:MPMovieTimeOptionNearestKeyFrame];
                
                //Player autoplays audio on init
                [player stop];
                [player release];
                //video.image = [UIImage imageWithContentsOfFile:image.filename];
                video.origin = (int)sqlite3_column_int(statement, 9);
                [video_list addObject:video];
                [video release];
            }
        } else {
            NSLog(@"ERROR: DB getImageList 2 failed with code %d", returncode);
        }
        sqlite3_finalize(statement);
    }
}

// ------------------------------------------------------------------------------------
// getVideoListByUserdataId - get list of video objects given userdata ID
// ------------------------------------------------------------------------------------
- (void) getVideoListByUserdataId:(NSMutableArray *)video_list userdataId:(NSString *)userdataId {
    
    int returncode;
    sqlite3_stmt *statement;
    NSString *sql;
    
    // Clear image list
    [video_list removeAllObjects];
    
    // Get list of images
    sql = [NSString stringWithFormat:@"select district_id, userdata_id, type, width, height, format, encoding, user_id, modified, filename, origin \
           from videodata where userdata_id = '%@'", userdataId];
    returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
    if (returncode == SQLITE_OK) {
        while (sqlite3_step(statement) == SQLITE_ROW) {
            TPVideo *video = [[TPVideo alloc] init];
            video.district_id = (int)sqlite3_column_int(statement, 0);
            video.userdata_id = [NSString stringWithFormat:@"%s", (char *)sqlite3_column_text(statement, 1)];
            video.type = (int)sqlite3_column_int(statement, 2);
            video.width = (int)sqlite3_column_int(statement, 3);
            video.height = (int)sqlite3_column_int(statement, 4);
            video.format = [NSString stringWithFormat:@"%s", (char *)sqlite3_column_text(statement, 5)];
            video.encoding = [NSString stringWithFormat:@"%s", (char *)sqlite3_column_text(statement, 6)];
            video.user_id = (int)sqlite3_column_int(statement, 7);
            char *modified = (char *)sqlite3_column_text(statement, 8);
            video.modified = [self dateFromCharStr:modified];
            video.filename = [NSString stringWithFormat:@"%s", (char *)sqlite3_column_text(statement, 9)];
            NSURL *videoURL = [NSURL fileURLWithPath:video.filename];//self.videoUrl;
            
            MPMoviePlayerController *player = [[MPMoviePlayerController alloc] initWithContentURL:videoURL];
            
            video.thumbImage = [player thumbnailImageAtTime:1.0 timeOption:MPMovieTimeOptionNearestKeyFrame];
            
            //Player autoplays audio on init
            [player stop];
            [player release];
            //image.image = [UIImage imageWithContentsOfFile:image.filename];
            video.origin = (int)sqlite3_column_int(statement, 10);
            [video_list addObject:video];
            [video release];
        }
    } else {
        NSLog(@"ERROR: DB getImageListByUserdataId failed with code %d", returncode);
    }
    sqlite3_finalize(statement);
}

// ------------------------------------------------------------------------------------
// videoDataDoesExist - return TRUE if image data does exists (videodata record and
//)
// ------------------------------------------------------------------------------------
- (BOOL) videoDataDoesExist:(NSString *)userdataId {
    
    if (debugDatabase) NSLog(@"TPDatabase videoDataDoesExist%@", userdataId);
    
    int returncode;
    sqlite3_stmt *statement;
    NSString *sql;
    NSString *filename;
    BOOL found;
    
    // Get list of images
    found = NO;
    sql = [NSString stringWithFormat:@"select filename \
           from videodata where userdata_id = '%@'", userdataId];
    returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
    if (returncode == SQLITE_OK) {
        while (sqlite3_step(statement) == SQLITE_ROW) {
            filename = [NSString stringWithFormat:@"%s", (char *)sqlite3_column_text(statement, 0)];
            found = YES;
        }
    } else {
        NSLog(@"ERROR: DB videoDataDoesExist failed with code %d", returncode);
    }
    sqlite3_finalize(statement);
    
    if (!found) {
        if (debugDatabase) NSLog(@"TPDatabase videoDataDoesExist NO videodata record not found");
        return NO;
    }
    
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:filename];
    if (fileExists) {
        if (debugDatabase) NSLog(@"TPDatabase videoDataDoesExist YES");
        return YES;
    } else {
        if (debugDatabase) NSLog(@"TPDatabase videoDataDoesExist NO - file not found %@", filename);
        return NO;
    }
}

// ------------------------------------------------------------------------------------
// videoFileDoesExist - return TRUE if video file does exists.
// ------------------------------------------------------------------------------------
- (BOOL) videoFileDoesExist:(NSString *)userdataId {
    
    if (debugDatabase) NSLog(@"TPDatabase videoFileDoesExist%@", userdataId);
    
    // Get the image path
    NSString *videoPath = [TPDatabase videoPathWithUserdataID:userdataId
                                                       suffix:@"MOV"];
    
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:videoPath];
    if (fileExists) {
        if (debugDatabase) NSLog(@"TPDatabase videoFileDoesExist YES");
        return YES;
    } else {
        if (debugDatabase) NSLog(@"TPDatabase videoFileDoesExist NO - file with path not found %@", videoPath);
        return NO;
    }
}

// ------------------------------------------------------------------------------------
- (int) getRubricIdFromUserdataID:(NSString *)userdata_id {
    
    int returncode;
	sqlite3_stmt *statement;
    int rubric_id = 0;
    
	// Get user data
	NSString *sql = [NSString stringWithFormat:@"select rubric_id from userdata where userdata_id = '%@'", userdata_id];
	returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
	if (returncode == SQLITE_OK) {
		while (sqlite3_step(statement) == SQLITE_ROW) {
            rubric_id = (int)sqlite3_column_int(statement, 0);
            break;
		}
	} else {
		NSLog(@"ERROR: DB getRubricIdFromUserdataID failed with code %d", returncode);
	}
	sqlite3_finalize(statement);
    
    return rubric_id;
}

// ------------------------------------------------------------------------------------
// purgeUserDataIfEmpty - if form then purge if no data recorded
// ------------------------------------------------------------------------------------
- (BOOL) purgeUserDataIfEmpty:(NSString *)userdata_id {
    
    if (debugDatabase) NSLog(@"TPDatabase purgeUserDataIfEmpty userdata_id %@", userdata_id);
    BOOL isForm = [self getRubricIdFromUserdataID:userdata_id] > 0;
    if (isForm && [self countUserDataEntries:userdata_id] == 0) {
        if (debugDatabase) NSLog(@"here");
        [self deleteUserData:userdata_id includingImages:YES];
        return YES;
    }
    return NO;
}

// ------------------------------------------------------------------------------------
- (int) countUserDataEntries:(NSString *)userdata_id {
    
    int returncode;
	sqlite3_stmt *statement;
    int count = 0;
    
	// Get user data
	NSString *sql = [NSString stringWithFormat:@"select count(*) from rubricdata where userdata_id = '%@' and (rating_id != 0 or (text is not null and text <> '') or (datevalue is not null and datevalue <> '(null)' ) )", userdata_id];
	returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
	if (returncode == SQLITE_OK) {
		while (sqlite3_step(statement) == SQLITE_ROW) {
            count = (int)sqlite3_column_int(statement, 0);
            break;
		}
	} else {
		NSLog(@"ERROR: DB countUserDataEntries failed with code %d", returncode);
	}
	sqlite3_finalize(statement);
    
    return count;
}

// ------------------------------------------------------------------------------------
// updateUserData - update user data
// ------------------------------------------------------------------------------------
- (void) updateUserData:(TPUserData *)userdata setModified:(BOOL)setModified {
    
    if (debugDatabase) NSLog(@"TPDatabase updateUserData %@ %d", userdata.userdata_id,  setModified);
    
    if (userdata == nil) {
        NSLog(@"ERROR TPDatabase updateUserData - userdata is nil");
        return;
    }
    
    // Delete existing data
	[self deleteUserData:userdata.userdata_id includingImages:NO];
    
	int returncode;
	sqlite3_stmt *statement;
	NSString *sql;
    
	NSString *created;
	NSString *modified;
	    
	// Convert dates to strings
	if (userdata.created) {
		created = [self stringFromDate:userdata.created];
	} else {
		created = @"";
	}
    
    // Set modified timestamp
    if (setModified) {
        userdata.modified = [NSDate date];
        modified = [self stringFromDate:userdata.modified];
	} else {
        if (userdata.modified) {
            modified = [self stringFromDate:userdata.modified];
        } else {
            modified = @"";
        }
    }
    
	// Insert form //jxi aud_id, aq_id fields are added
	sql = [NSString stringWithFormat:@"insert into userdata \
           (district_id, user_id, target_id, share, school_id, subject_id, grade, elapsed, type, rubric_id, name, userdata_id, state, created, modified, description, aud_id, aq_id) \
		   VALUES ('%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%@', '%@', '%d', '%@', '%@', '%@', '%@','%d')",
		   userdata.district_id,
           userdata.user_id,
           userdata.target_id,
           userdata.share,
           userdata.school_id,
           userdata.subject_id,
           userdata.grade,
           userdata.elapsed,
           userdata.type,
           userdata.rubric_id,
           [TPUtil escapeQuote:userdata.name maxLen:128],
           userdata.userdata_id,
           userdata.state,
           created,
           modified,
           [TPUtil escapeQuote:userdata.description maxLen:1024],
           userdata.aud_id,
           userdata.aq_id];
    if (debugDatabaseDetail) NSLog(@"%@", sql);
	returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
    if (returncode == SQLITE_OK) {
		returncode = sqlite3_step(statement);
        if (returncode != SQLITE_DONE) NSLog(@"ERROR: DB step failed with code %d", returncode);
	} else {
		NSLog(@"ERROR: DB updateUserData 1 failed with code %d", returncode);
	}
	sqlite3_finalize(statement);
	
	// Insert rubricdata
	for (TPRubricData *rubricdata in userdata.rubricdata) {
		sql = [NSString stringWithFormat:@"insert into rubricdata \
               (district_id, userdata_id, rubric_id, question_id, rating_id, value, text, annot, user_id, modified, datevalue) \
               VALUES ('%d', '%@', '%d', '%d','%d', '%f', '%@', '%d', '%d', '%@', '%@')",
			   rubricdata.district_id,
               rubricdata.userdata_id,
               rubricdata.rubric_id,
               rubricdata.question_id,
               rubricdata.rating_id,
               rubricdata.value,
               [TPUtil escapeQuote:rubricdata.text maxLen:10000],
               rubricdata.annotation,
               rubricdata.user,
               [self stringFromDate:rubricdata.modified],
               [self stringFromDate:rubricdata.datevalue]];
        if (debugDatabaseDetail) NSLog(@"%@", sql);
		returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
		if (returncode == SQLITE_OK) {
            returncode = sqlite3_step(statement);
            if (returncode != SQLITE_DONE) NSLog(@"ERROR: DB step failed with code %d", returncode);
        } else {
            NSLog(@"ERROR: DB updateUserData 2 failed with code %d", returncode);
        }
		sqlite3_finalize(statement);
    }
    if (debugDatabase) NSLog(@"TPDatabase updateUserData DONE");
}

// ------------------------------------------------------------------------------------
// updateImage - update image in database and on file
// ------------------------------------------------------------------------------------
- (void) updateImage:(TPImage *)image {
    
    if (debugDatabase) NSLog(@"TPDatabase updateImage %@ %@", image.userdata_id, image.filename);
    
    // Check that object, image, and filename aren't nil
    // Could happen if data from server is incomplete (no image data sent on sync request)
    if (image == nil) {
        if (debugDatabase) NSLog(@"TPDatabase updateImage abort due to nil object");
        return;
    }
    if (image.image == nil) {
        if (debugDatabase) NSLog(@"TPDatabase updateImage abort due to nil image");
        return;
    }
    if (image.filename == nil) {
        if (debugDatabase) NSLog(@"TPDatabase updateImage abort due to nil image filename");
        return;
    }

	int returncode;
	sqlite3_stmt *statement;
	NSString *sql;
    
    // Delete existing image file
    if (debugDatabase) NSLog(@"TPDatabase updateImage removing %@", image.filename);
    [[NSFileManager defaultManager] removeItemAtPath:image.filename error:NULL];
    
	// Delete existing image record from database
	[self deleteImage:image.userdata_id imageType:image.type];    
    
    // Insert new image record
    if (debugDatabase) NSLog(@"TPDatabase updateImage insert %@", image.userdata_id);
    sql = [NSString stringWithFormat:@"\
           insert into imagedata \
           (district_id, userdata_id, type, width, height, format, encoding, user_id, modified, filename, origin) \
		   VALUES (%d, '%@', %d, %d, %d, '%@', '%@', %d, '%@', '%@', %d)",
           image.district_id, image.userdata_id, image.type, image.width, image.height, image.format, image.encoding,
           image.user_id, [self stringFromDate:image.modified], image.filename, image.origin];
    if (debugDatabaseDetail) NSLog(@"%@", sql);
	returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
    if (returncode == SQLITE_OK) {
		returncode = sqlite3_step(statement);
        if (returncode != SQLITE_DONE) NSLog(@"ERROR: DB step failed with code %d", returncode);
	} else {
		NSLog(@"ERROR: DB updateImage failed with code %d", returncode);
	}
	sqlite3_finalize(statement);
    
    // write image to the file system
    if (debugDatabase) NSLog(@"TPDatabase updateImage writing file %@", image.filename);
    BOOL result = [[NSFileManager defaultManager] createFileAtPath:image.filename
                                                          contents:[NSData dataWithData:UIImageJPEGRepresentation(image.image, 0.8f)]
                                                        attributes:nil];
    if (!result) NSLog(@"ERROR: DB updateImage writing image to file at %@", image.filename);
}

//jxi;
// ------------------------------------------------------------------------------------
// updatevideo - update video in database and on file
// ------------------------------------------------------------------------------------
- (void) updateVideo:(TPVideo *)video {
    
    if (debugDatabase) NSLog(@"TPDatabase updateVideo %@ %@", video.userdata_id, video.filename);
    
    // Check that object, video, and filename aren't nil
    // Could happen if data from server is incomplete (no video data sent on sync request)
    if (video == nil) {
        if (debugDatabase) NSLog(@"TPDatabase updateVideo abort due to nil object");
        return;
    }
    if (video.filename == nil) {
        if (debugDatabase) NSLog(@"TPDatabase updateVideo abort due to nil video filename");
        return;
    }
    
    int returncode;
    sqlite3_stmt *statement;
    NSString *sql;
    
    // Delete existing video file
    /*if (debugDatabase) NSLog(@"TPDatabase updateVideo removing %@", video.filename);
     [[NSFileManager defaultManager] removeItemAtPath:video.filename error:NULL];
     
     // Delete existing video record from database
     [self deleteVideo:video.userdata_id];
     */
    // Insert new video record
    if (debugDatabase) NSLog(@"TPDatabase updateVideo insert %@", video.userdata_id);
    sql = [NSString stringWithFormat:@"\
           insert into videodata \
           (district_id, userdata_id, type, width, height, format, encoding, user_id, modified, filename, origin) \
           VALUES (%d, '%@', %d, %d, %d, '%@', '%@', %d, '%@', '%@', %d)",
           video.district_id, video.userdata_id, video.type, video.width, video.height, video.format, video.encoding,
           video.user_id, [self stringFromDate:video.modified], video.filename, video.origin];
    if (debugDatabaseDetail) NSLog(@"%@", sql);
    returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
    if (returncode == SQLITE_OK) {
        returncode = sqlite3_step(statement);
        if (returncode != SQLITE_DONE) NSLog(@"ERROR: DB step failed with code %d", returncode);
    } else {
        NSLog(@"ERROR: DB updateVideo failed with code %d", returncode);
    }
    sqlite3_finalize(statement);
    
    // write video to the file system
    if (debugDatabase) NSLog(@"TPDatabase updateVideo writing file %@", video.filename);
    NSURL *fileURL = [NSURL fileURLWithPath:video.filename];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:video.filename])
        return;
    
    if ( [[NSFileManager defaultManager] copyItemAtURL:video.videoUrl toURL:fileURL error:nil])
    {
        if (debugDatabase) NSLog(@"\nCOPIED");
    }
    else
    {
        if (debugDatabase) NSLog(@"\n COPY FAILED");
    }
    
}

// ------------------------------------------------------------------------------------
// updateImageData - update imagedata record in database
// ------------------------------------------------------------------------------------
- (void) updateImageData:(TPImage *)image {
    
    if (debugDatabase) NSLog(@"TPDatabase updateImageData %@ %@", image.userdata_id, image.filename);
    
    // Check that object, image, and filename aren't nil
    // Could happen if data from server is incomplete (no image data sent on sync request)
    if (image == nil) {
        if (debugDatabase) NSLog(@"TPDatabase updateImageData abort due to nil object");
        return;
    }
    if (image.image == nil) {
        if (debugDatabase) NSLog(@"TPDatabase updateImageData abort due to nil image");
        return;
    }
    if (image.filename == nil) {
        if (debugDatabase) NSLog(@"TPDatabase updateImageData abort due to nil image filename");
        return;
    }
    
	int returncode;
	sqlite3_stmt *statement;
	NSString *sql;
    
	// Delete existing image record from database
	[self deleteImage:image.userdata_id imageType:image.type];
    
    // Insert new image record
    if (debugDatabase) NSLog(@"TPDatabase updateImageData insert %@", image.userdata_id);
    sql = [NSString stringWithFormat:@"\
           insert into imagedata \
           (district_id, userdata_id, type, width, height, format, encoding, user_id, modified, filename, origin) \
		   VALUES (%d, '%@', %d, %d, %d, '%@', '%@', %d, '%@', '%@', %d)",
           image.district_id, image.userdata_id, image.type, image.width, image.height, image.format, image.encoding,
           image.user_id, [self stringFromDate:image.modified], image.filename, image.origin];
    if (debugDatabaseDetail) NSLog(@"%@", sql);
	returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
    if (returncode == SQLITE_OK) {
		returncode = sqlite3_step(statement);
        if (returncode != SQLITE_DONE) NSLog(@"ERROR: DB step failed with code %d", returncode);
	} else {
		NSLog(@"ERROR: DB updateImage failed with code %d", returncode);
	}
	sqlite3_finalize(statement);
}

//jxi;
// ------------------------------------------------------------------------------------
// updateVideoData - update videodata record in database
// ------------------------------------------------------------------------------------
- (void) updateVideoData:(TPVideo *)video {
    
    if (debugDatabase) NSLog(@"TPDatabase updateVideoData %@ %@", video.userdata_id, video.filename);
    
    // Check that object, video, and filename aren't nil
    // Could happen if data from server is incomplete (no video data sent on sync request)
    if (video == nil) {
        if (debugDatabase) NSLog(@"TPDatabase updateVideoData abort due to nil object");
        return;
    }
    if (video.filename == nil) {
        if (debugDatabase) NSLog(@"TPDatabase updateVideoData abort due to nil video filename");
        return;
    }
    
    int returncode;
    sqlite3_stmt *statement;
    NSString *sql;
    
    // Delete existing video record from database
    [self deleteVideo:video.userdata_id];
    
    // Insert new video record
    if (debugDatabase) NSLog(@"TPDatabase updateVideoData insert %@", video.userdata_id);
    sql = [NSString stringWithFormat:@"\
           insert into videodata \
           (district_id, userdata_id, type, width, height, format, encoding, user_id, modified, filename, origin) \
           VALUES (%d, '%@', %d, %d, %d, '%@', '%@', %d, '%@', '%@', %d)",
           video.district_id, video.userdata_id, video.type, video.width, video.height, video.format, video.encoding,
           video.user_id, [self stringFromDate:video.modified], video.filename, video.origin];
    if (debugDatabaseDetail) NSLog(@"%@", sql);
    returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
    if (returncode == SQLITE_OK) {
        returncode = sqlite3_step(statement);
        if (returncode != SQLITE_DONE) NSLog(@"ERROR: DB step failed with code %d", returncode);
    } else {
        NSLog(@"ERROR: DB updateVideo failed with code %d", returncode);
    }
    sqlite3_finalize(statement);
}

// ------------------------------------------------------------------------------------
// updateImageOrigin - update image origin value 
// ------------------------------------------------------------------------------------
- (void) updateImageOrigin:(NSString *)userdata_id type:(int)image_type origin:(int)neworigin {
    
	int returncode;
	sqlite3_stmt *statement;
	NSString *sql;
    
    sql = [NSString stringWithFormat:@"update imagedata set origin = %d where userdata_id = '%@' and type = %d", neworigin, userdata_id, image_type];
	returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
    if (returncode == SQLITE_OK) {
		returncode = sqlite3_step(statement);
        if (returncode != SQLITE_DONE) NSLog(@"ERROR: DB step failed with code %d", returncode);
	} else {
		NSLog(@"ERROR: DB updateImageOrigin failed with code %d", returncode);
	}
	sqlite3_finalize(statement);
}

// ------------------------------------------------------------------------------------
// jxi; updateVideoOrigin - update video origin value 
// ------------------------------------------------------------------------------------
- (void) updateVideoOrigin:(NSString *)userdata_id type:(int)image_type origin:(int)neworigin {
    int returncode;
	sqlite3_stmt *statement;
	NSString *sql;
    
    sql = [NSString stringWithFormat:@"update videodata set origin = %d where userdata_id = '%@' and type = %d", neworigin, userdata_id, image_type];
	returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
    if (returncode == SQLITE_OK) {
		returncode = sqlite3_step(statement);
        if (returncode != SQLITE_DONE) NSLog(@"ERROR: DB step failed with code %d", returncode);
	} else {
		NSLog(@"ERROR: DB updateVideoOrigin failed with code %d", returncode);
	}
	sqlite3_finalize(statement);
}

// ------------------------------------------------------------------------------------
// updateUserDataShare - update userdata share value
// ------------------------------------------------------------------------------------
- (void) updateUserDataShare:(NSString *)userdata_id share:(int)newshare {
    
	int returncode;
	sqlite3_stmt *statement;
	NSString *sql;
    
    // Set modified timestamp
    NSDate *modified = [NSDate date];
    NSString *modified_str = [self stringFromDate:modified];
	
	// Insert form
	sql = [NSString stringWithFormat:@"update userdata set share = %d, modified = '%@' where userdata_id = '%@'",
           newshare, modified_str, userdata_id];
    returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
	if (returncode == SQLITE_OK) {
        returncode = sqlite3_step(statement);
        if (returncode != SQLITE_DONE) NSLog(@"ERROR: DB step failed with code %d", returncode);
    } else {
        NSLog(@"ERROR: DB updateUserDataShare failed with code %d", returncode);
    }
	sqlite3_finalize(statement);
}

// ------------------------------------------------------------------------------------
// updateUserData:Name:share:description - update userdata share value
// ------------------------------------------------------------------------------------
- (void) updateUserData:(NSString *)userdata_id name:(NSString *)newname share:(int)newshare description:(NSString *)newdescription {
    
	int returncode;
	sqlite3_stmt *statement;
	NSString *sql;
    
    // Set modified timestamp
    NSDate *modified = [NSDate date];
    NSString *modified_str = [self stringFromDate:modified];
	
	// Insert form
	sql = [NSString stringWithFormat:@"update userdata set name = '%@', share = %d, description = '%@', modified = '%@' where userdata_id = '%@'",
           [TPUtil escapeQuote:newname maxLen:128],
           newshare,
           [TPUtil escapeQuote:newdescription maxLen:1024],
           modified_str,
           userdata_id];
    returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
	if (returncode == SQLITE_OK) {
        returncode = sqlite3_step(statement);
        if (returncode != SQLITE_DONE) NSLog(@"ERROR: DB step failed with code %d", returncode);
    } else {
        NSLog(@"ERROR: DB updateUserData failed with code %d", returncode);
    }
	sqlite3_finalize(statement);
}

// ------------------------------------------------------------------------------------
// getUserDataState - return the state value
// ------------------------------------------------------------------------------------
- (int) getUserDataState:(NSString *)userdata_id {
    
    int returncode;
	sqlite3_stmt *statement;
    int state = -1;
    
	// Get user data
	NSString *sql = [NSString stringWithFormat:@"select state from userdata where userdata_id = '%@'", userdata_id];
    returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
	if (returncode == SQLITE_OK) {
		while (sqlite3_step(statement) == SQLITE_ROW) {
            state = (int)sqlite3_column_int(statement, 0);
            break;
		}
	} else {
		NSLog(@"ERROR: DB getUserDataState failed with code %d", returncode);
	}
	sqlite3_finalize(statement);
    
    return state;
}

// ------------------------------------------------------------------------------------
// updateUserDataState - update user data state
// ------------------------------------------------------------------------------------
- (void) updateUserDataState:(NSString *)userdata_id state:(int)newstate {
    
    if (debugDatabase) NSLog(@"TPDatabase updateUserDataState %@ %d", userdata_id, newstate);
    
	int returncode;
	sqlite3_stmt *statement;
	NSString *sql;
    
    // Set modified timestamp
    NSDate *modified = [NSDate date];
    NSString *modified_str = [self stringFromDate:modified];
	
	// Insert form
	sql = [NSString stringWithFormat:@"update userdata set state = %d, modified = '%@' where userdata_id = '%@'",
           newstate, modified_str, userdata_id];
	returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
	if (returncode == SQLITE_OK) {
        returncode = sqlite3_step(statement);
        if (returncode != SQLITE_DONE) NSLog(@"ERROR: DB step failed with code %d", returncode);
    } else {
        NSLog(@"ERROR: DB updateUserDataState failed with code %d", returncode);
    }
	sqlite3_finalize(statement);
}

// ------------------------------------------------------------------------------------
// updateUserDataStateNoTimestamp - update user data state, but don't update the
// modified timestamp.
// ------------------------------------------------------------------------------------
- (void) updateUserDataStateNoTimestamp:(NSString *)userdata_id state:(int)newstate {
    
    if (debugDatabase) NSLog(@"TPDatabase updateUserDataStateNoTimestamp %@ %d", userdata_id, newstate);
    
	int returncode;
	sqlite3_stmt *statement;
	NSString *sql;
    	
	// Insert form
	sql = [NSString stringWithFormat:@"update userdata set state = %d where userdata_id = '%@'",
           newstate, userdata_id];
	returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
	if (returncode == SQLITE_OK) {
        returncode = sqlite3_step(statement);
        if (returncode != SQLITE_DONE) NSLog(@"ERROR: DB step failed with code %d", returncode);
    } else {
        NSLog(@"ERROR: DB updateUserDataStateNoTimestamp failed with code %d", returncode);
    }
	sqlite3_finalize(statement);
}

// ------------------------------------------------------------------------------------
// updateUserDataElapsed - update user data state
// ------------------------------------------------------------------------------------
- (void) updateUserDataElapsed:(NSString *)userdata_id elapsed:(int)newelapsed {
    
    if (debugDatabase) NSLog(@"TPDatabase updateUserDataElapsed %@ %d", userdata_id, newelapsed);
    
	int returncode;
	sqlite3_stmt *statement;
	NSString *sql;
    
    // Set modified timestamp
    NSDate *modified = [NSDate date];
    NSString *modified_str = [self stringFromDate:modified];
	
	// Insert form
	sql = [NSString stringWithFormat:@"update userdata set elapsed = %d, modified = '%@' where userdata_id = '%@'",
           newelapsed, modified_str, userdata_id];
	returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
	if (returncode == SQLITE_OK) {
        returncode = sqlite3_step(statement);
        if (returncode != SQLITE_DONE) NSLog(@"ERROR: DB step failed with code %d", returncode);
    } else {
        NSLog(@"ERROR: DB updateUserDataElapsed failed with code %d", returncode);
    }
	sqlite3_finalize(statement);
}

// ------------------------------------------------------------------------------------
// updateUserDataGrade - update user data grade
// ------------------------------------------------------------------------------------
- (void) updateUserDataGrade:(NSString *)userdata_id grade:(int)newgrade {
    
    if (debugDatabase) NSLog(@"TPDatabase updateUserDataGrade %@ %d", userdata_id, newgrade);
    
	int returncode;
	sqlite3_stmt *statement;
	NSString *sql;
    
    // Set modified timestamp
    NSDate *modified = [NSDate date];
    NSString *modified_str = [self stringFromDate:modified];
	
	// Insert form
	sql = [NSString stringWithFormat:@"update userdata set grade = %d, modified = '%@' where userdata_id = '%@'",
           newgrade, modified_str, userdata_id];
	returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
	if (returncode == SQLITE_OK) {
        returncode = sqlite3_step(statement);
        if (returncode != SQLITE_DONE) NSLog(@"ERROR: DB step failed with code %d", returncode);
    } else {
        NSLog(@"ERROR: DB updateUserDataGrade failed with code %d", returncode);
    }
	sqlite3_finalize(statement);
}

// ------------------------------------------------------------------------------------
// deleteUserData - delete all user data related to user data ID
// ------------------------------------------------------------------------------------
- (void) deleteUserData:(NSString *)userdata_id includingImages:(BOOL)includingImages {
	
    if (debugDatabase) NSLog(@"TPDatabase deleteUserData %@ includingimages=%d", userdata_id, includingImages);
    
	NSString *sql;
	int returncode;
	sqlite3_stmt *statement;	
	
    // Delete userdata
	sql = [NSString stringWithFormat:@"delete from userdata where userdata_id = '%@'", userdata_id];
	returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
	if (returncode == SQLITE_OK) {
		returncode = sqlite3_step(statement);
        if (returncode != SQLITE_DONE) NSLog(@"ERROR: DB step failed with code %d", returncode);
	} else {
		NSLog(@"ERROR: DB deleteUserData 1 failed with code %d", returncode);
	}
	sqlite3_finalize(statement);
    
    // Delete rubricdata
	sql = [NSString stringWithFormat:@"delete from rubricdata where userdata_id = '%@'", userdata_id];
	returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
	if (returncode == SQLITE_OK) {
		returncode = sqlite3_step(statement);
        if (returncode != SQLITE_DONE) NSLog(@"ERROR: DB step failed with code %d", returncode);
	} else {
		NSLog(@"ERROR: DB deleteUserData 2 failed with code %d", returncode);
	}
	sqlite3_finalize(statement);
    
    // If image flagged then delete these as well
    if (includingImages) {
        
        // Get list of images
        NSMutableArray *image_list = [[NSMutableArray alloc] init]; 
        [self getImageListByUserdataId:image_list userdataId:userdata_id];
        
        // Delete all image files
        for (TPImage *image in image_list) {
            if ([[NSFileManager defaultManager] fileExistsAtPath:image.filename]) {
                NSError *error;
                NSURL *url = [NSURL fileURLWithPath:image.filename isDirectory:NO];
                [[NSFileManager defaultManager] removeItemAtURL:url error:&error];
            }
        }
        [image_list release];
        
        // Delete image data
        sql = [NSString stringWithFormat:@"delete from imagedata where userdata_id = '%@'", userdata_id];
        returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
        if (returncode == SQLITE_OK) {
            returncode = sqlite3_step(statement);
            if (returncode != SQLITE_DONE) NSLog(@"ERROR: DB step failed with code %d", returncode);
        } else {
            NSLog(@"ERROR: DB deleteUserData 3 failed with code %d", returncode);
        }
        sqlite3_finalize(statement);
        
        // Get list of videos //jxi;
        NSMutableArray *video_list = [[NSMutableArray alloc] init];
        [self getVideoListByUserdataId:video_list userdataId:userdata_id];
        
        // Delete all video files
        for (TPVideo *video in video_list) {
            if ([[NSFileManager defaultManager] fileExistsAtPath:video.filename]) {
                NSError *error;
                NSURL *url = [NSURL fileURLWithPath:video.filename isDirectory:NO];
                [[NSFileManager defaultManager] removeItemAtURL:url error:&error];
            }
        }
        [video_list release];
        
        // Delete video data
        sql = [NSString stringWithFormat:@"delete from videodata where userdata_id = '%@'", userdata_id];
        returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
        if (returncode == SQLITE_OK) {
            returncode = sqlite3_step(statement);
            if (returncode != SQLITE_DONE) NSLog(@"ERROR: DB step failed with code %d", returncode);
        } else {
            NSLog(@"ERROR: DB deleteUserData 3 failed with code %d", returncode);
        }
        sqlite3_finalize(statement);
    }
    if (debugDatabase) NSLog(@"TPDatabase deleteUserData DONE");
}

// ------------------------------------------------------------------------------------
// deleteRubricData - delete all data related to ribric ID
// ------------------------------------------------------------------------------------
- (void) deleteRubricData:(int)rubric_id {
	
	NSString *sql;
	int returncode;
	sqlite3_stmt *statement;	
	
	sql = [NSString stringWithFormat:@"delete from userdata where rubric_id = %d", rubric_id];
	returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
	if (returncode == SQLITE_OK) {
		returncode = sqlite3_step(statement);
        if (returncode != SQLITE_DONE) NSLog(@"ERROR: DB step failed with code %d", returncode);
	} else {
		NSLog(@"ERROR: DB deleteRubricData 1 failed with code %d", returncode);
	}
	sqlite3_finalize(statement);
    
	sql = [NSString stringWithFormat:@"delete from rubricdata where rubric_id = %d", rubric_id];
	returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
	if (returncode == SQLITE_OK) {
		returncode = sqlite3_step(statement);
        if (returncode != SQLITE_DONE) NSLog(@"ERROR: DB step failed with code %d", returncode);
	} else {
		NSLog(@"ERROR: DB deleteRubricData 2 failed with code %d", returncode);
	}
	sqlite3_finalize(statement);
}

// ------------------------------------------------------------------------------------
// deleteImage - delete image database record
// ------------------------------------------------------------------------------------
- (void) deleteImage:(NSString *)userdata_id imageType:(int)imageType {
	
    if (debugDatabase) NSLog(@"TPDatabase deleteImage %@ type=%d", userdata_id, imageType);
    
	NSString *sql;
	int returncode;
	sqlite3_stmt *statement;	
	
	sql = [NSString stringWithFormat:@"delete from imagedata where userdata_id = '%@' and type = %d", userdata_id, imageType];
	returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
	if (returncode == SQLITE_OK) {
		returncode = sqlite3_step(statement);
        if (returncode != SQLITE_DONE) NSLog(@"ERROR: DB step failed with code %d", returncode);
	} else {
		NSLog(@"ERROR: DB deleteImage failed with code %d", returncode);
	}
	sqlite3_finalize(statement);
}

// ------------------------------------------------------------------------------------
// deleteVideo - delete video database record //jxi;
// ------------------------------------------------------------------------------------
- (void) deleteVideo:(NSString *)userdata_id {
    
    if (debugDatabase) NSLog(@"TPDatabase deleteImage %@", userdata_id);
    
    NSString *sql;
    int returncode;
    sqlite3_stmt *statement;
    
    sql = [NSString stringWithFormat:@"delete from videodata where userdata_id = '%@'", userdata_id];
    returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
    if (returncode == SQLITE_OK) {
        returncode = sqlite3_step(statement);
        if (returncode != SQLITE_DONE) NSLog(@"ERROR: DB step failed with code %d", returncode);
    } else {
        NSLog(@"ERROR: DB deleteVideo failed with code %d", returncode);
    }
    sqlite3_finalize(statement);
}

// ------------------------------------------------------------------------------------
// ratingIsSelected - return boolean based on whether specified rating is selected
// ------------------------------------------------------------------------------------
- (BOOL) ratingIsSelected:(TPRating *)rating question:(TPQuestion *)question userdata_id:(NSString *)userdata_id {
    
    int returncode;
	sqlite3_stmt *statement;
    int count = 0;
    
	// Get user data
	NSString *sql = [NSString stringWithFormat:@"select count(*) from rubricdata where userdata_id = '%@' and question_id = %d and rating_id = %d", userdata_id, question.question_id, rating.rating_id];
	returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
	if (returncode == SQLITE_OK) {
		while (sqlite3_step(statement) == SQLITE_ROW) {
            count = (int)sqlite3_column_int(statement, 0);
            break;
		}
	} else {
		NSLog(@"ERROR: DB ratingIsSelected failed with code %d", returncode);
	}
	sqlite3_finalize(statement);
    
    return count > 0;
}

// ------------------------------------------------------------------------------------
// ratingValue - return float value, corresponding to current rating in rubricdaa
// ------------------------------------------------------------------------------------
- (float) ratingValue:(TPRating *)rating question:(TPQuestion *)question userdata_id:(NSString *)userdata_id {
    
    int returncode;
	sqlite3_stmt *statement;
    float value = 0.0f;
    
	// Get user data
	NSString *sql = [NSString stringWithFormat:@"select value from rubricdata where userdata_id = '%@' and question_id = %d and rating_id = %d", userdata_id, question.question_id, rating.rating_id];
	returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
	if (returncode == SQLITE_OK) {
		while (sqlite3_step(statement) == SQLITE_ROW) {
            value = (float)sqlite3_column_int(statement, 0);
            break;
		}
	} else {
		NSLog(@"ERROR: DB ratingValue failed with code %d", returncode);
	}
	sqlite3_finalize(statement);
    
    return value;
}

// ------------------------------------------------------------------------------------
// questionText - return question text for specified question
// ------------------------------------------------------------------------------------
- (NSString *) questionText:(TPQuestion *)question userdata_id:(NSString *)userdata_id {
    
    int returncode;
	sqlite3_stmt *statement;
    NSString *answer = @"";
    
	// Get user data
	NSString *sql = [NSString stringWithFormat:@"select text from rubricdata where userdata_id = '%@' and question_id = %d and annot = 0",
                     userdata_id, question.question_id];
	returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
	if (returncode == SQLITE_OK) {
		while (sqlite3_step(statement) == SQLITE_ROW) {
            char *answer_str = (char *)sqlite3_column_text(statement, 0);
            answer = [NSString stringWithFormat:@"%s", answer_str];
            break;
		}
	} else {
		NSLog(@"ERROR: DB questionText failed with code %d", returncode);
	}
	sqlite3_finalize(statement);
    
    return answer;
}

// ------------------------------------------------------------------------------------
// questionAnnot - return annotation text for specified question
// ------------------------------------------------------------------------------------
- (NSString *) questionAnnot:(TPQuestion *)question userdata_id:(NSString *)userdata_id {
    
    int returncode;
	sqlite3_stmt *statement;
    NSString *answer = @"";
    
	// Get user data
	NSString *sql = [NSString stringWithFormat:@"select text from rubricdata where userdata_id = '%@' and question_id = %d and annot = 1",
                     userdata_id, question.question_id];
	returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
	if (returncode == SQLITE_OK) {
		while (sqlite3_step(statement) == SQLITE_ROW) {
            char *answer_str = (char *)sqlite3_column_text(statement, 0);
            answer = [NSString stringWithFormat:@"%s", answer_str];
            break;
		}
	} else {
		NSLog(@"ERROR: DB questionAnnot failed with code %d", returncode);
	}
	sqlite3_finalize(statement);
    
    return answer;
}

// ------------------------------------------------------------------------------------
// questionDatevalue - return date value for specified question
// ------------------------------------------------------------------------------------
- (NSDate *) questionDatevalue:(TPQuestion *)question userdata_id:(NSString *)userdata_id {
    int returncode;
	sqlite3_stmt *statement;
    NSDate *datevalue = nil;
    
	// Get user data
	NSString *sql = [NSString stringWithFormat:@"select datevalue from rubricdata where userdata_id = '%@' and question_id = %d",
                     userdata_id, question.question_id];
	returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
	if (returncode == SQLITE_OK) {
		while (sqlite3_step(statement) == SQLITE_ROW) {
            char *datevalue_str = (char *)sqlite3_column_text(statement, 0);
            datevalue = [model dateFromCharStr:datevalue_str];
            break;
		}
	} else {
		NSLog(@"ERROR: DB questionDatevalue failed with code %d", returncode);
	}
	sqlite3_finalize(statement);
    
    return datevalue;

}

// ------------------------------------------------------------------------------------
// getUserDataUnsyncedCount - return the number of local items that need syncing.
// ------------------------------------------------------------------------------------
- (int) getUserDataUnsyncedCount {
    
    int returncode;
	sqlite3_stmt *statement;
    int count = 0;
    
	// Get user data
	NSString *sql = [NSString stringWithFormat:@"select count(*) from userdata where state = 2 or state = 3"];
    returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
	if (returncode == SQLITE_OK) {
		while (sqlite3_step(statement) == SQLITE_ROW) {
            count = (int)sqlite3_column_int(statement, 0);
            break;
		}
	} else {
		NSLog(@"ERROR: DB getUserDataUnsyncedCount failed with code %d", returncode);
	}
	sqlite3_finalize(statement);
    
    return count;
}

/*
// ------------------------------------------------------------------------------------
// getUserDataUnsyncedDataList:localImagesList:includeCurrentUserdata - return lists of all 
// user data ID strings of previously unsynced data/images. 
// State must be one of (2=partial, 3=complete) to be considered unsynced and worth
// syncing.
// ------------------------------------------------------------------------------------
- (void) getUserDataUnsyncedDataList:(NSMutableArray *)userdata_queue 
                     localImagesList:(NSMutableArray *)local_images_queue
              includeCurrentUserdata:(BOOL)includeCurrentUserdata {
    
    int returncode;
	sqlite3_stmt *statement;

    // Clear arrays
    [userdata_queue removeAllObjects];
    [local_images_queue removeAllObjects];
    
	// Get user data
	NSString *sql = [NSString stringWithFormat:@"select userdata_id from userdata where type != 3 and (state = 2 or state = 3)"];
	returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
	if (returncode == SQLITE_OK) {
		while (sqlite3_step(statement) == SQLITE_ROW) {
            char *userdata_id_str = (char *)sqlite3_column_text(statement, 0);
            NSString *userdata_id = [NSString stringWithFormat:@"%s", userdata_id_str];
            if (includeCurrentUserdata || ![userdata_id isEqualToString:model.appstate.userdata_id]) {
              [userdata_queue addObject:userdata_id];
              if (debugDatabase) NSLog(@"add userdata_queue %@", userdata_id);
            }
		}
	} else {
		NSLog(@"ERROR: DB getUserDataUnsyncedDataList 1 failed with code %d", returncode);
	}
	sqlite3_finalize(statement);
    
	// Get image data
    NSMutableArray *temp_images_queue = [NSMutableArray array];
	sql = [NSString stringWithFormat:@"select userdata_id from userdata where type = 3 and (state = 2 or state = 3)"];
	returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
	if (returncode == SQLITE_OK) {
		while (sqlite3_step(statement) == SQLITE_ROW) {
            char *udid = (char *)sqlite3_column_text(statement, 0);
            NSString *userdata_id = [NSString stringWithFormat:@"%s", udid];
            [temp_images_queue addObject:userdata_id];
            if (debugDatabase) NSLog(@"add temp_images_queue %@", userdata_id);
		}
	} else {
		NSLog(@"ERROR: DB getUserDataUnsyncedDataList 2 failed with code %d", returncode);
	}
    
    // separate local and remote images
    BOOL found;
    for (NSString* userdata_id in temp_images_queue) {
        
        found = NO;
        sql = [NSString stringWithFormat:@"select origin from imagedata where userdata_id = '%@' and type = %d", userdata_id, TP_IMAGE_TYPE_FULL];
        if (debugDatabaseDetail) NSLog(@"%@", sql);
        returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
        if (returncode == SQLITE_OK) {
            if (sqlite3_step(statement) == SQLITE_ROW) {
                int origin = (int)sqlite3_column_int(statement, 0);
                if (origin == TP_IMAGE_ORIGIN_LOCAL) {
                    // If local origin then send to server
                    [local_images_queue addObject:userdata_id];
                    if (debugDatabase) NSLog(@"add local_images_queue %@", userdata_id);
                } else {
                    // Otherwise 
                    [userdata_queue addObject:userdata_id];
                    if (debugDatabase) NSLog(@"add userdata_queue %@", userdata_id);
                }
            } else {
                // If no row found then add to regular userdata sync queue (don't try to sync the image)
                [userdata_queue addObject:userdata_id];
                if (debugDatabase) NSLog(@"no image - add userdata_queue %@", userdata_id);
            }
        } else {
            NSLog(@"ERROR: DB getUserDataUnsyncedDataList 3 failed with code %d", returncode);
        }
    }
    sqlite3_finalize(statement);
}
*/

//jxi;
// ------------------------------------------------------------------------------------
// getUserDataUnsyncedDataList:localImagesList:includeCurrentUserdata - return lists of all
// user data ID strings of previously unsynced data/images.
// State must be one of (2=partial, 3=complete) to be considered unsynced and worth
// syncing.
// ------------------------------------------------------------------------------------
- (void) getUserDataUnsyncedDataList:(NSMutableArray *)userdata_queue
                     localImagesList:(NSMutableArray *)local_images_queue
                     localVideosList:(NSMutableArray *)local_videos_queue
              includeCurrentUserdata:(BOOL)includeCurrentUserdata {
    
    int returncode;
    sqlite3_stmt *statement;
    
    // Clear arrays
    [userdata_queue removeAllObjects];
    [local_images_queue removeAllObjects];
    [local_videos_queue removeAllObjects];
    
    // Get user data
    NSString *sql = [NSString stringWithFormat:@"select userdata_id from userdata where type != 3 and type != 4 and (state = 2 or state = 3)"];
    returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
    if (returncode == SQLITE_OK) {
        while (sqlite3_step(statement) == SQLITE_ROW) {
            char *userdata_id_str = (char *)sqlite3_column_text(statement, 0);
            NSString *userdata_id = [NSString stringWithFormat:@"%s", userdata_id_str];
            if (includeCurrentUserdata || ![userdata_id isEqualToString:model.appstate.userdata_id]) {
                [userdata_queue addObject:userdata_id];
                if (debugDatabase) NSLog(@"add userdata_queue %@", userdata_id);
            }
        }
    } else {
        NSLog(@"ERROR: DB getUserDataUnsyncedDataList 1 failed with code %d", returncode);
    }
    sqlite3_finalize(statement);
    
    // Get image data
    NSMutableArray *temp_images_queue = [NSMutableArray array];
    sql = [NSString stringWithFormat:@"select userdata_id from userdata where type = 3 and (state = 2 or state = 3)"];
    returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
    if (returncode == SQLITE_OK) {
        while (sqlite3_step(statement) == SQLITE_ROW) {
            char *udid = (char *)sqlite3_column_text(statement, 0);
            NSString *userdata_id = [NSString stringWithFormat:@"%s", udid];
            [temp_images_queue addObject:userdata_id];
            if (debugDatabase) NSLog(@"add temp_images_queue %@", userdata_id);
        }
    } else {
        NSLog(@"ERROR: DB getUserDataUnsyncedDataList 2 failed with code %d", returncode);
    }
    sqlite3_finalize(statement);
    
    // separate local and remote images
    
    for (NSString* userdata_id in temp_images_queue) {
        
        sql = [NSString stringWithFormat:@"select origin from imagedata where userdata_id = '%@' and type = %d", userdata_id, TP_IMAGE_TYPE_FULL];
        if (debugDatabaseDetail) NSLog(@"%@", sql);
        returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
        if (returncode == SQLITE_OK) {
            if (sqlite3_step(statement) == SQLITE_ROW) {
                int origin = (int)sqlite3_column_int(statement, 0);
                if (origin == TP_IMAGE_ORIGIN_LOCAL) {
                    // If local origin then send to server
                    [local_images_queue addObject:userdata_id];
                    if (debugDatabase) NSLog(@"add local_images_queue %@", userdata_id);
                } else {
                    // Otherwise
                    [userdata_queue addObject:userdata_id];
                    if (debugDatabase) NSLog(@"add userdata_queue %@", userdata_id);
                }
            } else {
                // If no row found then add to regular userdata sync queue (don't try to sync the image)
                [userdata_queue addObject:userdata_id];
                if (debugDatabase) NSLog(@"no image - add userdata_queue %@", userdata_id);
            }
        } else {
            NSLog(@"ERROR: DB getUserDataUnsyncedDataList 3 failed with code %d", returncode);
        }
    }
    
    // Get video data
    NSMutableArray *temp_video_queue = [NSMutableArray array];
    sql = [NSString stringWithFormat:@"select userdata_id from userdata where type = 4 and (state = 2 or state = 3)"];
    returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
    if (returncode == SQLITE_OK) {
        while (sqlite3_step(statement) == SQLITE_ROW) {
            char *udid = (char *)sqlite3_column_text(statement, 0);
            NSString *userdata_id = [NSString stringWithFormat:@"%s", udid];
            [temp_video_queue addObject:userdata_id];
            if (debugDatabase) NSLog(@"add temp_videos_queue %@", userdata_id);
        }
    } else {
        NSLog(@"ERROR: DB getUserDataUnsyncedDataList 2 failed with code %d", returncode);
    }
    
    // separate local and remote video
    for (NSString* userdata_id in temp_video_queue) {
        
        sql = [NSString stringWithFormat:@"select origin from videodata where userdata_id = '%@' and type = %d", userdata_id, TP_IMAGE_TYPE_FULL];
        if (debugDatabaseDetail) NSLog(@"%@", sql);
        returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
        if (returncode == SQLITE_OK) {
            if (sqlite3_step(statement) == SQLITE_ROW) {
                int origin = (int)sqlite3_column_int(statement, 0);
                if (origin == TP_IMAGE_ORIGIN_LOCAL) {
                    // If local origin then send to server
                    [local_videos_queue addObject:userdata_id];
                    if (debugDatabase) NSLog(@"add local_videos_queue %@", userdata_id);
                } else {
                    // Otherwise
                    [userdata_queue addObject:userdata_id];
                    if (debugDatabase) NSLog(@"add userdata_queue %@", userdata_id);
                }
            } else {
                // If no row found then add to regular userdata sync queue (don't try to sync the video)
                [userdata_queue addObject:userdata_id];
                if (debugDatabase) NSLog(@"no video - add userdata_queue %@", userdata_id);
            }
        } else {
            NSLog(@"ERROR: DB getUserDataUnsyncedDataList 3 failed with code %d", returncode);
        }
    }
    sqlite3_finalize(statement);
}

// ------------------------------------------------------------------------------------
// Encode user data into XML format for sync
// ------------------------------------------------------------------------------------
- (NSString *) getUserDataXMLEncoding:(NSString *)userdata_id {
		
    if (debugDatabase) NSLog(@"TPDatabase getUserDataXMLEncoding %@", userdata_id);
    
    int returncode;
	sqlite3_stmt *statement;
	NSString *sql;
	
    // Verify that we have an ID, otherwise return
    if (userdata_id == nil) { return nil; }
    
	NSMutableString *userdata = [NSMutableString stringWithString:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>"];
	    
	// Encode user data //jxi; aud_id, aq_id added
    sql = [NSString stringWithFormat:@"select district_id, user_id, target_id, share, school_id, subject_id, grade, elapsed, \
           type, rubric_id, name, userdata_id, state, created, modified, description, aud_id, aq_id from userdata where userdata_id = '%@'", userdata_id];
	returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
	if (returncode == SQLITE_OK) {
		while (sqlite3_step(statement) == SQLITE_ROW) {
			int district_id = (int)sqlite3_column_int(statement, 0);
            int user_id = (int)sqlite3_column_int(statement, 1);
			int target_id = (int)sqlite3_column_int(statement, 2);
            int share = (int)sqlite3_column_int(statement, 3);
            int school_id = (int)sqlite3_column_int(statement, 4);
            int subject_id = (int)sqlite3_column_int(statement, 5);
            int grade = (int)sqlite3_column_int(statement, 6);
            int elapsed = (int)sqlite3_column_int(statement, 7);
            int type = (int)sqlite3_column_int(statement, 8);
            int rubric_id = (int)sqlite3_column_int(statement, 9);
            char *name = (char *)sqlite3_column_text(statement, 10);
            char *userdata_id = (char *)sqlite3_column_text(statement, 11);
            int state = (int)sqlite3_column_int(statement, 12);
            char *created = (char *)sqlite3_column_text(statement, 13);
			char *modified = (char *)sqlite3_column_text(statement, 14);
            char *description = (char *)sqlite3_column_text(statement, 15);
            char *aud_id = (char *)sqlite3_column_text(statement, 16); //jxi
            int aq_id = (int)sqlite3_column_int(statement, 17); //jxi
			[userdata appendFormat:@"\n<userdata district=\"%d\" user=\"%d\" target=\"%d\" type=\"%d\" rubric=\"%d\" share=\"%d\" school=\"%d\" subject=\"%d\" grade=\"%d\" elapsed=\"%d\" state=\"%d\" aud_id=\"%s\" aq_id=\"%d\">",
             district_id, user_id, target_id, type, rubric_id, share, school_id, subject_id, grade, elapsed, state, aud_id, aq_id]; //jxi; aud_id, aq_id
            [userdata appendFormat:@"\n<userdata_id>%s</userdata_id>", userdata_id];
            [userdata appendFormat:@"\n<name>%@</name>", [model syncEncode:[NSString stringWithFormat:@"%s", name]]];
            [userdata appendFormat:@"\n<created>%s</created>", created];
            [userdata appendFormat:@"\n<modified>%s</modified>", modified];
            [userdata appendFormat:@"\n<description>%@</description>", [model syncEncode:[NSString stringWithFormat:@"%s", description]]];
		}
	} else {
		NSLog(@"ERROR: DB getUserDataXMLEncoding 1 failed with code %d", returncode);
	}
	sqlite3_finalize(statement);
	
	// Encode rubric data
	[userdata appendFormat:@"\n<data>"];
    
    sql = [NSString stringWithFormat:@"select rubric_id, question_id, rating_id, value, text, annot, user_id, modified, datevalue \
           from rubricdata where userdata_id = '%@'", userdata_id];
    returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
    if (returncode == SQLITE_OK) {
        while (sqlite3_step(statement) == SQLITE_ROW) {
            int rubric_id = (int)sqlite3_column_int(statement, 0);
            int question_id = (int)sqlite3_column_int(statement, 1);
            int rating_id = (int)sqlite3_column_int(statement, 2);
			float value = (float)sqlite3_column_int(statement, 3);
            char *text = (char *)sqlite3_column_text(statement, 4);
            int annot = (int)sqlite3_column_int(statement, 5);
            int user_id = (int)sqlite3_column_int(statement, 6);
            char *modified = (char *)sqlite3_column_text(statement, 7);
            char *datevalue = (char *)sqlite3_column_text(statement, 8);
            [userdata appendFormat:@"\n<rubricdata rubric=\"%d\" question=\"%d\" rating=\"%d\" annot=\"%d\" user=\"%d\">",
             rubric_id, question_id, rating_id, annot, user_id];
            [userdata appendFormat:@"\n<value>%f</value>", value];
            [userdata appendFormat:@"\n<text>%@</text>", [model syncEncode:[NSString stringWithFormat:@"%s", text]]];
            [userdata appendFormat:@"\n<modified>%s</modified>", modified];
            [userdata appendFormat:@"\n<datevalue>%s</datevalue>", datevalue];
            [userdata appendFormat:@"\n</rubricdata>"];
        }
    } else {
        NSLog(@"ERROR: DB getUserDataXMLEncoding 2 failed with code %d", returncode);
    }
    sqlite3_finalize(statement);
    
    // End form
	[userdata appendFormat:@"\n</data>"];
    [userdata appendFormat:@"\n</userdata>"];
	
	return userdata;
}

// ------------------------------------------------------------------------------------
// getLocalImageXMLEncoding - return XML encoding of captured image
// ------------------------------------------------------------------------------------
- (NSString *) getLocalImageXMLEncoding:(NSString *)userdata_id {
    
    if (debugDatabase) NSLog(@"TPDatabase getLocalImageXMLEncoding %@", userdata_id);
    
    int returncode;
	sqlite3_stmt *statement;
	NSString *sql;
	
    // Verify that we have an ID, otherwise return
    if (userdata_id == nil) { return nil; }
    
	NSMutableString *localimage = [NSMutableString stringWithString:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>"];
    
    // Encode user data
    sql = [NSString stringWithFormat:@"select district_id, user_id, target_id, share, school_id, subject_id, grade, elapsed, \
           type, rubric_id, name, userdata_id, state, created, modified, description, aud_id, aq_id from userdata where userdata_id = '%@'", userdata_id]; //jxi;
	returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
	if (returncode == SQLITE_OK) {
		while (sqlite3_step(statement) == SQLITE_ROW) {
			int district_id = (int)sqlite3_column_int(statement, 0);
            int user_id = (int)sqlite3_column_int(statement, 1);
			int target_id = (int)sqlite3_column_int(statement, 2);
            int share = (int)sqlite3_column_int(statement, 3);
            int school_id = (int)sqlite3_column_int(statement, 4);
            int subject_id = (int)sqlite3_column_int(statement, 5);
            int grade = (int)sqlite3_column_int(statement, 6);
            int elapsed = (int)sqlite3_column_int(statement, 7);
            int type = (int)sqlite3_column_int(statement, 8);
            int rubric_id = (int)sqlite3_column_int(statement, 9);
            char *name = (char *)sqlite3_column_text(statement, 10);
            char *userdata_id = (char *)sqlite3_column_text(statement, 11);
            int state = (int)sqlite3_column_int(statement, 12);
            char *created = (char *)sqlite3_column_text(statement, 13);
			char *modified = (char *)sqlite3_column_text(statement, 14);
            char *description = (char *)sqlite3_column_text(statement, 15);
            char *aud_id = (char *)sqlite3_column_text(statement, 16); //jxi;
            int aq_id = (int)sqlite3_column_int(statement, 17); //jxi;
			[localimage appendFormat:@"\n<userdata district=\"%d\" user=\"%d\" target=\"%d\" type=\"%d\" rubric=\"%d\" share=\"%d\" school=\"%d\" subject=\"%d\" grade=\"%d\" elapsed=\"%d\" state=\"%d\" aud_id=\"%s\" aq_id=\"%d\">",
             district_id, user_id, target_id, type, rubric_id, share, school_id, subject_id, grade, elapsed, state, aud_id, aq_id]; //jxi; aud_id, aq_id added :)
            [localimage appendFormat:@"\n<userdata_id>%s</userdata_id>", userdata_id];
            [localimage appendFormat:@"\n<name>%@</name>", [model syncEncode:[NSString stringWithFormat:@"%s", name]]];
            [localimage appendFormat:@"\n<created>%s</created>", created];
            [localimage appendFormat:@"\n<modified>%s</modified>", modified];
            [localimage appendFormat:@"\n<description>%@</description>", [model syncEncode:[NSString stringWithFormat:@"%s", description]]];
		}
	} else {
		NSLog(@"ERROR: DB getLocalImageXMLEncoding failed with code %d", returncode);
	}
	sqlite3_finalize(statement);

    // Get image data
    TPImage *image_object = [self getImageFull:userdata_id];
    
    // convert image to Base64 string
    NSData *imagedata = [NSData dataWithData:UIImageJPEGRepresentation(image_object.image, 0.8f)];
    NSString *imageB64String = [imagedata base64EncodedString];
    
    [localimage appendFormat:@"\n<data>%@</data>", imageB64String];
    
    // End form
    [localimage appendFormat:@"\n</userdata>"];
	
	return localimage;
}

//-------------------------------------------------------------------------------------
- (NSData *)generatePostDataForData:(NSData *)uploadData
{
    // Generate the post header:
    NSString *post = [NSString stringWithCString:"--AaB03x\r\nContent-Disposition: form-data; name=\"upload[file]\"; filename=\"somefile\"\r\nContent-Type: application/octet-stream\r\nContent-Transfer-Encoding: binary\r\n\r\n" encoding:NSASCIIStringEncoding];
    
    // Get the post header int ASCII format:
    NSData *postHeaderData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    
    // Generate the mutable data variable:
    NSMutableData *postData = [[NSMutableData alloc] initWithLength:[postHeaderData length] ];
    [postData setData:postHeaderData];
    
    // Add the image:
    [postData appendData: uploadData];
    
    // Add the closing boundry:
    [postData appendData: [@"\r\n--AaB03x--" dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES]];
    
    // Return the post data:
    return postData;
    return uploadData;
}

// ------------------------------------------------------------------------------------
// getLocalVideoXMLEncoding - return XML encoding of captured image
// ------------------------------------------------------------------------------------
- (NSString *) getLocalVideoInfoXMLEncoding:(NSString *)userdata_id {
    
    if (debugDatabase) NSLog(@"TPDatabase getLocalVideoXMLEncoding %@", userdata_id);
    
    int returncode;
    sqlite3_stmt *statement;
    NSString *sql;
    
    // Verify that we have an ID, otherwise return
    if (userdata_id == nil) { return nil; }
    
    NSMutableString *localvideo = [NSMutableString stringWithString:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>"];
    
    // Encode user data
    sql = [NSString stringWithFormat:@"select district_id, user_id, target_id, share, school_id, subject_id, grade, elapsed, \
           type, rubric_id, name, userdata_id, state, created, modified, description, aud_id, aq_id from userdata where userdata_id = '%@'", userdata_id]; //jxi;
    returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
    if (returncode == SQLITE_OK) {
        while (sqlite3_step(statement) == SQLITE_ROW) {
            int district_id = (int)sqlite3_column_int(statement, 0);
            int user_id = (int)sqlite3_column_int(statement, 1);
            int target_id = (int)sqlite3_column_int(statement, 2);
            int share = (int)sqlite3_column_int(statement, 3);
            int school_id = (int)sqlite3_column_int(statement, 4);
            int subject_id = (int)sqlite3_column_int(statement, 5);
            int grade = (int)sqlite3_column_int(statement, 6);
            int elapsed = (int)sqlite3_column_int(statement, 7);
            int type = (int)sqlite3_column_int(statement, 8);
            int rubric_id = (int)sqlite3_column_int(statement, 9);
            char *name = (char *)sqlite3_column_text(statement, 10);
            char *userdata_id = (char *)sqlite3_column_text(statement, 11);
            int state = (int)sqlite3_column_int(statement, 12);
            char *created = (char *)sqlite3_column_text(statement, 13);
            char *modified = (char *)sqlite3_column_text(statement, 14);
            char *description = (char *)sqlite3_column_text(statement, 15);
            char *aud_id = (char *)sqlite3_column_text(statement, 16); //jxi;
            int aq_id = (int)sqlite3_column_int(statement, 17); //jxi;
            [localvideo appendFormat:@"\n<userdata district=\"%d\" user=\"%d\" target=\"%d\" type=\"%d\" rubric=\"%d\" share=\"%d\" school=\"%d\" subject=\"%d\" grade=\"%d\" elapsed=\"%d\" state=\"%d\" aud_id=\"%s\" aq_id=\"%d\">",
             district_id, user_id, target_id, type, rubric_id, share, school_id, subject_id, grade, elapsed, state, aud_id, aq_id]; //jxi; aud_id, aq_id added
            [localvideo appendFormat:@"\n<userdata_id>%s</userdata_id>", userdata_id];
            [localvideo appendFormat:@"\n<name>%@</name>", [model syncEncode:[NSString stringWithFormat:@"%s", name]]];
            [localvideo appendFormat:@"\n<created>%s</created>", created];
            [localvideo appendFormat:@"\n<modified>%s</modified>", modified];
            [localvideo appendFormat:@"\n<description>%@</description>", [model syncEncode:[NSString stringWithFormat:@"%s", description]]];
        }
    } else {
        NSLog(@"ERROR: DB getLocalVIDEOXMLEncoding failed with code %d", returncode);
    }
    sqlite3_finalize(statement);
    
    /*
    // Get video data
    TPVideo *video_object = [self getVideoFull:userdata_id];
    NSURL *fileURL = [NSURL fileURLWithPath:video_object.filename];
    NSData *webData = [NSData dataWithContentsOfURL:fileURL];
    
    //NSData *videoData = [self generatePostDataForData:webData];
    // convert video to Base64 string
    NSString *videoB64String = [webData base64EncodedString]; */
    
    //jxi;
    // Get video data
    TPVideo *video_object = [self getVideoFull:userdata_id];
    // Get video data from video file
    NSData *videodata = [NSData dataWithContentsOfFile:video_object.filename];
    // Convert video to Base64 string
    NSString *videoB64String = [videodata base64EncodedString];
    
    [localvideo appendFormat:@"\n<data>%@</data>", videoB64String];
    //[localvideo appendFormat:@"\n<data>%@</data>", video_object.filename];
    
    // End form
    [localvideo appendFormat:@"\n</userdata>"];
    
    return localvideo;
}

-(NSData*)getLocalVideoXMLEncoding:(NSString *)userdata_id
{
    if (debugDatabase) NSLog(@"TPDatabase getLocalVideoXMLEncoding %@", userdata_id);
    
    if (userdata_id == nil) { return nil; }
    
    // Get video data
    TPVideo *video_object = [self getVideoFull:userdata_id];
    NSURL *fileURL = [NSURL fileURLWithPath:video_object.filename];
    NSData *webData = [NSData dataWithContentsOfURL:fileURL];
    NSData *videoData = [self generatePostDataForData:webData];
    
    return videoData;
    
}

// ------------------------------------------------------------------------------------
// getImageFull - return full image based on userdata ID
// ------------------------------------------------------------------------------------
- (TPImage *) getImageFull:(NSString *)userdataId {
    
    if (debugDatabase) NSLog(@"TPDatabase getImageFull %@", userdataId);
    
    int returncode;
	sqlite3_stmt *statement;
    NSString *sql;
    TPImage *image = NULL;
    
	// Get image data for each userdata object and put it in the image list
    
    sql = [NSString stringWithFormat:@"select district_id, type, width, height, \
           format, encoding, user_id, modified, filename, origin \
           from imagedata where userdata_id = '%@' and type = %d",
           userdataId, TP_IMAGE_TYPE_FULL];
    returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
    if (returncode == SQLITE_OK) {
        while (sqlite3_step(statement) == SQLITE_ROW) {
            // main image
            image = [[[TPImage alloc] init] autorelease];
            image.district_id = (int)sqlite3_column_int(statement, 0);
            image.userdata_id = userdataId;
            image.type = (int)sqlite3_column_int(statement, 1);
            image.width = (int)sqlite3_column_int(statement, 2);
            image.height = (int)sqlite3_column_int(statement, 3);
            image.format = [NSString stringWithFormat:@"%s", (char *)sqlite3_column_text(statement, 4)];
            image.encoding = [NSString stringWithFormat:@"%s", (char *)sqlite3_column_text(statement, 5)];
            image.user_id = (int)sqlite3_column_int(statement, 6);
            char *modified = (char *)sqlite3_column_text(statement, 7);
            image.modified = [self dateFromCharStr:modified];
            image.filename = [NSString stringWithFormat:@"%s", (char *)sqlite3_column_text(statement, 8)];
            image.image = [UIImage imageWithContentsOfFile:image.filename];
            image.origin = (int)sqlite3_column_int(statement, 9);
        }
    } else {
        NSLog(@"ERROR: DB getImageList 2 failed with code %d", returncode);
    }
    sqlite3_finalize(statement);
    return (image);
}

// ------------------------------------------------------------------------------------
// getVideoFull - return full video based on userdata ID //jxi;
// ------------------------------------------------------------------------------------
- (TPVideo *) getVideoFull:(NSString *)userdataId {
    
    if (debugDatabase) NSLog(@"TPDatabase getVideoFull %@", userdataId);
    
    int returncode;
    sqlite3_stmt *statement;
    NSString *sql;
    TPVideo *video = NULL;
    
    // Get image data for each userdata object and put it in the image list
    
    sql = [NSString stringWithFormat:@"select district_id, type, width, height, \
           format, encoding, user_id, modified, filename, origin \
           from videodata where userdata_id = '%@'",
           userdataId];
    returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
    if (returncode == SQLITE_OK) {
        while (sqlite3_step(statement) == SQLITE_ROW) {
            // main video
            video = [[[TPVideo alloc] init] autorelease];
            video.district_id = (int)sqlite3_column_int(statement, 0);
            video.userdata_id = userdataId;
            video.type = (int)sqlite3_column_int(statement, 1);
            video.width = (int)sqlite3_column_int(statement, 2);
            video.height = (int)sqlite3_column_int(statement, 3);
            video.format = [NSString stringWithFormat:@"%s", (char *)sqlite3_column_text(statement, 4)];
            video.encoding = [NSString stringWithFormat:@"%s", (char *)sqlite3_column_text(statement, 5)];
            video.user_id = (int)sqlite3_column_int(statement, 6);
            char *modified = (char *)sqlite3_column_text(statement, 7);
            video.modified = [self dateFromCharStr:modified];
            video.filename = [NSString stringWithFormat:@"%s", (char *)sqlite3_column_text(statement, 8)];
            //image.image = [UIImage imageWithContentsOfFile:image.filename];
            video.origin = (int)sqlite3_column_int(statement, 9);
        }
    } else {
        NSLog(@"ERROR: DB getImageList 2 failed with code %d", returncode);
    }
    sqlite3_finalize(statement);
    return (video);
}

// ------------------------------------------------------------------------------------
// tryRestoreImageData - try to restore image files by adding imagedata records
// ------------------------------------------------------------------------------------
- (BOOL) tryRestoreImageData:(NSString *)userdataId {
    
    if (debugDatabase) NSLog(@"TPDatabase tryRestoreImageData %@", userdataId);
    
    // Get userdata
    TPUserData *userdata = [self getUserData:userdataId];
    if (userdata == NULL) return NO; // Return if not found
    
    // Get the image if it exists in a file
    NSString *imagePath = [TPDatabase imagePathWithUserdataID:userdataId suffix:@"jpg" imageType:TP_IMAGE_TYPE_FULL];
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:imagePath]; // See if image exists
    if (!fileExists) return NO; // Return if no image file
    UIImage *fullimage = [UIImage imageWithContentsOfFile:imagePath]; // Get full image
    
    // Create image object
    TPImage *fullimageobj = [[TPImage alloc] initWithImage:fullimage
                                             districtId:userdata.district_id
                                             userdataID:userdata.userdata_id
                                                   type:TP_IMAGE_TYPE_FULL
                                                  width:fullimage.size.width
                                                 height:fullimage.size.height
                                                 format:@"jpg"
                                               encoding:@"binary"
                                                 userId:userdata.user_id
                                               modified:[NSDate date]
                                               filename:imagePath
                                                 origin:TP_IMAGE_ORIGIN_LOCAL];
    
    // Update imagedata record
    if (debugDatabase) NSLog(@"TPDatabase tryRestoreImageData - store full image");
    [self updateImageData:fullimageobj];
    
    // Create thumbnail and update database and related file
    imagePath = [TPDatabase imagePathWithUserdataID:userdataId suffix:@"jpg" imageType:TP_IMAGE_TYPE_THUMBNAIL];
    fileExists = [[NSFileManager defaultManager] fileExistsAtPath:imagePath]; // See if image exists
    if (!fileExists) return NO; // Return if no image file
    UIImage *thumbnail_image = [UIImage imageWithContentsOfFile:imagePath]; // Get image
        
    TPImage *thumbnail = [[TPImage alloc] initWithImage:thumbnail_image
                                             districtId:userdata.district_id
                                             userdataID:userdata.userdata_id
                                                   type:TP_IMAGE_TYPE_THUMBNAIL
                                                  width:thumbnail_image.size.width
                                                 height:thumbnail_image.size.height
                                                 format:@"jpg"
                                               encoding:@"binary"
                                                 userId:userdata.user_id
                                               modified:[NSDate date]
                                               filename:imagePath
                                                 origin:TP_IMAGE_ORIGIN_REMOTE];
    // Update imagedata record
    if (debugDatabase) NSLog(@"TPDatabase tryRestoreImageData - store thumb image");
    [self updateImageData:thumbnail];
    
    // Release images
    [fullimageobj release];
    [thumbnail release];
    return YES;
}

// ------------------------------------------------------------------------------------
// tryRestoreVideoData - try to restore video files by adding videodata records //jxi;
// ------------------------------------------------------------------------------------
- (BOOL) tryRestoreVideoData:(NSString *)userdataId {
    
    if (debugDatabase) NSLog(@"TPDatabase tryRestoreVideoData %@", userdataId);
    
    // Get userdata
    TPUserData *userdata = [self getUserData:userdataId];
    if (userdata == NULL) return NO; // Return if not found
    
    // Get the video if it exists in a file
    NSString *videoPath = [TPDatabase videoPathWithUserdataID:userdataId suffix:@"MOV"];
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:videoPath]; // See if image exists
    if (!fileExists) return NO; // Return if no video file
    
    NSURL *videoURL = [NSURL fileURLWithPath:videoPath];
    // Create image object
    TPVideo *video = [[TPVideo alloc] initWithImage:videoURL
                                         districtId:userdata.district_id
                                         userdataID:userdata.userdata_id
                                               type:TP_USERDATA_TYPE_VIDEO
                                              width:0
                                             height:0
                                             format:@"MOV"
                                           encoding:@"binary"
                                             userId:userdata.user_id
                                           modified:[NSDate date]
                                           filename:videoPath
                                             origin:TP_IMAGE_ORIGIN_LOCAL];
    
    // Update videodata record
    if (debugDatabase) NSLog(@"TPDatabase tryRestoreVideoData - store video");
    [self updateVideo:video];
    
    [video release];
    return YES;
}

// ------------------------------------------------------------------------------------
// getUserDataListXMLEncoding - return XML encoding of known rubrics
// ------------------------------------------------------------------------------------
- (NSString *) getUserDataListXMLEncoding {
    
    int returncode;
	sqlite3_stmt *statement;
	NSMutableString *content = [NSMutableString stringWithString:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>"];
    
    // Loop over all user data
    [content appendFormat:@"\n<objectlist>"];
	NSString *sql = [NSString stringWithFormat:@"select userdata_id, modified from userdata where state > 1"];
	returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
	if (returncode == SQLITE_OK) {
		while (sqlite3_step(statement) == SQLITE_ROW) {
            char *userdata_id_str = (char *)sqlite3_column_text(statement, 0);
            char *modified_str = (char *)sqlite3_column_text(statement, 1);
            [content appendFormat:@"\n<object id=\"0\" flag=\"0\" idstr=\"%s\">%s</object>", userdata_id_str, modified_str];
		}
	} else {
		NSLog(@"ERROR: DB getUserDataListXMLEncoding failed with code %d", returncode);
	}
	sqlite3_finalize(statement);
    [content appendFormat:@"\n</objectlist>"];
    
	return content;
}

// ------------------------------------------------------------------------------------
// ------------------------------------------------------------------------------------
- (void) getRecRubricList:(NSMutableArray *)userDataIdArray targetId:(int)target_id {
    
    int returncode;
	sqlite3_stmt *statement;
    
    // Clear the array
    [userDataIdArray removeAllObjects];
    
    NSString *sql = [NSString stringWithFormat:@"select distinct userdata.userdata_id from userdata, rubricdata \
                     where userdata.userdata_id = rubricdata.userdata_id and userdata.target_id = %d \
                     and rating_id > 0", target_id];
    if (debugDatabase) NSLog(@"getRecRubricList query %@", sql);
  	returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
	if (returncode == SQLITE_OK) {
		while (sqlite3_step(statement) == SQLITE_ROW) {
            NSString *userdata_id = [NSString stringWithFormat:@"%s", (char *)sqlite3_column_text(statement, 0)];
            [userDataIdArray addObject:userdata_id];
		}
	} else {
		NSLog(@"ERROR: DB getRecRubricList failed with code %d", returncode);
	}
	sqlite3_finalize(statement);
}

// ------------------------------------------------------------------------------------
// Savepoint operations
// ------------------------------------------------------------------------------------

- (void) setSavepointWithName:(NSString*) savepointName {
    // transaction variant
    int rc;
    rc = sqlite3_exec(database, [[NSString stringWithFormat:@"SAVEPOINT %@", savepointName] UTF8String], NULL, NULL, NULL);
    if (rc != 0) {
        NSLog(@"ERROR: DB setSavepointWithName setting savepoint %@. Error code : %i, '%s'", savepointName, rc, sqlite3_errmsg(database));
    } else {
        if (debugDatabase) NSLog(@"OK setting savepoint %@. OK code : %i", savepointName, rc);
    }
}

- (void) releaseSavepointWithName:(NSString*) savepointName {
    // transaction variant
    int rc;
    rc = sqlite3_exec(database, [[NSString stringWithFormat:@"RELEASE SAVEPOINT %@", savepointName] UTF8String], NULL, NULL, NULL);
    if (rc != 0) {
        NSLog(@"ERROR: DB releaseSavepointWithName releasing savepoint %@. Error code : %i, '%s'", savepointName, rc, sqlite3_errmsg(database));
    } else {
        if (debugDatabase) NSLog(@"OK releasing savepoint %@. OK code : %i",savepointName , rc);
    }
}

- (void) rollbackToSavepointWithName:(NSString*) savepointName {
    // transaction variant
    int rc;
    rc = sqlite3_exec(database, [[NSString stringWithFormat:@"ROLLBACK TO SAVEPOINT %@", savepointName] UTF8String], NULL, NULL, NULL);
    if (rc != 0) {
        NSLog(@"ERROR: DB rollbackToSavepointWithName rollbacking to savepoint %@. Error code : %i, '%s'", savepointName, rc, sqlite3_errmsg(database));
    } else {
        if (debugDatabase) NSLog(@"OK rollbacking to savepoint %@. OK code : %i",savepointName , rc);
    }
}


// ------------------------------------------------------------------------------------
// Utility methods
// ------------------------------------------------------------------------------------
- (NSString *) getTimestamp {
	
	NSString *timestamp = [NSString stringWithFormat:@"%s", [[self stringFromDate:[NSDate date]] UTF8String]];
		
	return timestamp;
}		

- (NSDate *) dateFromCharStr:(char *)date_str {
    //NSLog(@"dateFromCharStr");
    [model waitForLock:dateformatterLock]; // Use lock since NSDateFormatter is not thread safe
    NSDate *date = [dateformatter dateFromString:[NSString stringWithFormat:@"%s", date_str]];
    [model freeLock:dateformatterLock];
    return date;
}

- (NSString *) stringFromDate:(NSDate *)date {
    if (date == nil) return @"";
    [model waitForLock:dateformatterLock]; // Use lock since NSDateFormatter is not thread safe
	NSString *date_str = [NSString stringWithFormat:@"%s", [[dateformatter stringFromDate:date] UTF8String]];
    [model freeLock:dateformatterLock];
	return date_str;
}

// ------------------------------------------------------------------------------------
// imagePathWithUserdataID - construct file path to use when storing image
// ------------------------------------------------------------------------------------
+ (NSString *) imagePathWithUserdataID:(NSString *)userdata_id suffix:(NSString *)suffix imageType:(int)imageType {
    
    //NSLog(@"Image Path: %@", [TPDatabase imagePathDir]);
    
    NSString *imageDir = [TPDatabase imagePathDir];
    switch (imageType) {
        case TP_IMAGE_TYPE_FULL:
            return [NSString stringWithFormat:@"%@/%@.image.%@", imageDir, userdata_id, suffix];
        case TP_IMAGE_TYPE_THUMBNAIL:
            return [NSString stringWithFormat:@"%@/%@.thumb.%@", imageDir, userdata_id, suffix];
    }
    return nil;
}

// ------------------------------------------------------------------------------------
// videoPathWithUserdataID - construct file path to use when storing image //jxi;
// ------------------------------------------------------------------------------------
+ (NSString *) videoPathWithUserdataID:(NSString *)userdata_id suffix:(NSString *)suffix {
    
    NSString *videoDir = [TPDatabase videoPathDir];
    return [NSString stringWithFormat:@"%@/%@.%@", videoDir, userdata_id, suffix];
}

// ------------------------------------------------------------------------------------
// imagePathDir - construct directory path for storing image files
// ------------------------------------------------------------------------------------
+ (NSString *) imagePathDir {
    NSString *imageDir = [NSString stringWithFormat:@"%@/Documents/Images", NSHomeDirectory()];
    return imageDir;
}

// ------------------------------------------------------------------------------------
// videoPathDir - construct directory path for storing image files //jxi;
// ------------------------------------------------------------------------------------
+ (NSString *) videoPathDir {
    NSString *imageDir = [NSString stringWithFormat:@"%@/Documents/Videos", NSHomeDirectory()];
    return imageDir;
}

// ------------------------------------------------------------------------------------
// imageFileExistsWithUserdataID - construct file path to use when storing image
// ------------------------------------------------------------------------------------
+ (NSString *) imageFileExistsWithUserdataID:(NSString *)userdata_id suffix:(NSString *)suffix imageType:(int)imageType {
    
    NSString *imageDir = [TPDatabase imagePathDir];
    switch (imageType) {
        case TP_IMAGE_TYPE_FULL:
            return [NSString stringWithFormat:@"%@/%@.image.%@", imageDir, userdata_id, suffix];
        case TP_IMAGE_TYPE_THUMBNAIL:
            return [NSString stringWithFormat:@"%@/%@.thumb.%@", imageDir, userdata_id, suffix];
    }
    return nil;
}

// ------------------------------------------------------------------------------------
// jxi; getUserDataListXMLEncodingForUserDataSync
// Return XML encoding of known rubrics for the users in the userlist
// ------------------------------------------------------------------------------------
- (NSString *) getUserDataListXMLEncodingForUserDataSync:(NSMutableString *)strUserIdList {
    
    int returncode;
	sqlite3_stmt *statement;
	NSMutableString *content = [NSMutableString stringWithString:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>"];
    
    // Loop over all user data for the users in the userId List
    [content appendFormat:@"\n<objectlist>"];
	NSString *sql = [NSString stringWithFormat:@"select userdata_id, modified from userdata where state > 1 AND target_id IN %@", strUserIdList];
	returncode = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
	if (returncode == SQLITE_OK) {
		while (sqlite3_step(statement) == SQLITE_ROW) {
            char *userdata_id_str = (char *)sqlite3_column_text(statement, 0);
            char *modified_str = (char *)sqlite3_column_text(statement, 1);
            [content appendFormat:@"\n<object id=\"0\" flag=\"0\" idstr=\"%s\">%s</object>", userdata_id_str, modified_str];
		}
	} else {
		NSLog(@"ERROR: DB getUserDataListXMLEncodingForUserDataSync failed with code %d", returncode);
	}
	sqlite3_finalize(statement);
    [content appendFormat:@"\n</objectlist>"];
    
	return content;
}


@end


