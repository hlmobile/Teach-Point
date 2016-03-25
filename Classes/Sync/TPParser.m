#import "TPParser.h"
#import "TPData.h"
#import "TPModel.h"
#import "TPDatabase.h"
#import "TPModelSync.h"
#import "NSData+Base64.h"

@implementation TPParser

// ---------------------------------------------------------------------------------------
- (id)initWithModel:(TPModel *)somemodel {
	    
	if (debugParser) NSLog(@"TWParser init");
	
	self = [super init];
	if (self != nil) {
		
		model = somemodel;
		
        publicstate = model.publicstate;
		appstate = model.appstate;
        
		users = model.tmp_user_array;
        info = model.tmp_info_array;
        categories = model.tmp_category_array;
        rubrics = model.tmp_rubric_array;
        questions = model.tmp_question_array;
        ratings = model.tmp_rating_array;
        userdata = model.tmp_userdata_array;
        
		current_appstate = nil;
		current_user = nil;
        current_info = nil;
        current_category = nil;
		current_rubric = nil;
        current_question = nil;
        current_rating = nil;
        current_userdata = nil;
        current_rubricdata = nil;
        current_image = nil;
        current_video = nil; //jxi;
        
		current_property = nil;
	}
	return self;
}

// ---------------------------------------------------------------------------------------
- (void)dealloc {
    
	if (current_appstate) {
		[current_appstate release];
		current_appstate = nil;
	}
	if (current_question) {
		[current_question release];
		current_question = nil;
	}
	if (current_rating) {
		[current_rating release];
		current_rating = nil;
	}
	[super dealloc];
}

// ---------------------------------------------------------------------------------------
- (void) resetparser {
    
	current_appstate = nil;
	current_user = nil;
    current_info = nil;
    current_category = nil;
	current_rubric = nil;
    current_question = nil;
    current_rating = nil;
    current_userdata = nil;
    current_rubricdata = nil;
    current_image = nil;
    current_video = nil; //jxi;
    
    current_property = nil;
}

// ---------------------------------------------------------------------------------------
- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {

	if (debugParser) NSLog(@"didStartElement %@", elementName);
    if (debugParser) NSLog(@"  attributes %@", attributeDict.description);
	
    // If inside a TOP LEVEL element then set property for sub tag and get attributes
    
	// Parse login user
	if (current_appstate) {
		if ([elementName isEqualToString:@"first_name"] ||
			[elementName isEqualToString:@"last_name"] ||
            [elementName isEqualToString:@"district"]) {
			current_property = [NSMutableString string];
		}
				
	// Parse a user
	} else if (current_user) {
		if ([elementName isEqualToString:@"first_name"] ||
            [elementName isEqualToString:@"last_name"] ||
			[elementName isEqualToString:@"schools"] ||
            [elementName isEqualToString:@"subjects"] ||
            [elementName isEqualToString:@"modified"] ||
            [elementName isEqualToString:@"info"]) {
			current_property = [NSMutableString string];
		}
        
    // Parse a user info 
	} else if (current_info) {
		if ([elementName isEqualToString:@"info"] ||
            [elementName isEqualToString:@"modified"]) {
			current_property = [NSMutableString string];
		}
    
    // Parse a category 
	} else if (current_category) {
		if ([elementName isEqualToString:@"name"] ||
            [elementName isEqualToString:@"modified"]) {
			current_property = [NSMutableString string];
        }
        
    // Parse a rubric
	} else if (current_rubric) {
		if ([elementName isEqualToString:@"group"] ||
            [elementName isEqualToString:@"title"] ||
            [elementName isEqualToString:@"modified"]) {
			current_property = [NSMutableString string];
            
        } else if ([elementName isEqualToString:@"question"]) {
			current_question = [[TPQuestion alloc] init];
			current_question.question_id = [[attributeDict objectForKey:@"question_id"] intValue];
            current_question.order = [[attributeDict objectForKey:@"qorder"] intValue];
            current_question.type = [[attributeDict objectForKey:@"qtype"] intValue];
            current_question.subtype = [[attributeDict objectForKey:@"qsubtype"] intValue];
            current_question.category = [[attributeDict objectForKey:@"qcategory"] intValue];
            current_question.optional = [[attributeDict objectForKey:@"qoptional"] intValue];
            current_question.style = [TPQuestion styleWithString:[attributeDict objectForKey:@"qstyle"]];
            current_question.annotation = [[attributeDict objectForKey:@"qannot"] intValue];
            current_question.rubric_id = current_rubric.rubric_id;
            
        } else if ([elementName isEqualToString:@"qtitle"]) {
            current_property = [NSMutableString string];
            current_question.title_style = [TPQuestion styleWithString:[attributeDict objectForKey:@"qtstyle"]];
            
        } else if ([elementName isEqualToString:@"qprompt"]) {
            current_property = [NSMutableString string];
            current_question.prompt_style = [TPQuestion styleWithString:[attributeDict objectForKey:@"qpstyle"]];
            
        } else if ([elementName isEqualToString:@"rating"]) {
			current_rating = [[TPRating alloc] init];
			current_rating.rating_id = [[attributeDict objectForKey:@"rating_id"] intValue];
            current_rating.rorder = [[attributeDict objectForKey:@"rorder"] intValue];
            current_rating.value = [[attributeDict objectForKey:@"rvalue"] floatValue];
            current_rating.question_id = current_question.question_id;
            current_rating.rubric_id = current_rubric.rubric_id;
            current_property = [NSMutableString string];
            
        } else if ([elementName isEqualToString:@"rtitle"]) {
            current_property = [NSMutableString string];
            
        } else if ([elementName isEqualToString:@"rtext"]) {
            current_property = [NSMutableString string];
		}

    // Parse a userdata object
	} else if (current_userdata) {
		if ([elementName isEqualToString:@"userdata_id"] ||
            [elementName isEqualToString:@"name"] ||
            [elementName isEqualToString:@"description"] ||
            [elementName isEqualToString:@"created"] ||
            [elementName isEqualToString:@"modified"]) {
			current_property = [NSMutableString string];
            
        } else if ([elementName isEqualToString:@"rubricdata"]) {
			current_rubricdata = [[TPRubricData alloc] init];
			current_rubricdata.rubric_id = [[attributeDict objectForKey:@"rubric"] intValue];
            current_rubricdata.question_id = [[attributeDict objectForKey:@"question"] intValue];
            current_rubricdata.rating_id = [[attributeDict objectForKey:@"rating"] intValue];
            current_rubricdata.userdata_id = current_userdata.userdata_id;
            current_rubricdata.annotation = [[attributeDict objectForKey:@"annot"] intValue];
            if ([attributeDict objectForKey:@"user"]) {
                current_rubricdata.user = [[attributeDict objectForKey:@"user"] intValue];
            }
            
        } else if ([elementName isEqualToString:@"value"]) {
            current_property = [NSMutableString string];
            
        } else if ([elementName isEqualToString:@"text"]) {
            current_property = [NSMutableString string];
            
		} else if ([elementName isEqualToString:@"datevalue"]) {
            current_property = [NSMutableString string];
        }

    // Parse an image from server
    } else if (current_image) {
        if ([elementName isEqualToString:@"userdata_id"] ||
            [elementName isEqualToString:@"created"] ||
            [elementName isEqualToString:@"data"]) {
            current_property = [NSMutableString string];
        }
        
    // Parse a video from server //jxi;
    } else if (current_video) {
        if ([elementName isEqualToString:@"userdata_id"] ||
            [elementName isEqualToString:@"created"] ||
            [elementName isEqualToString:@"data"]) {
            current_property = [NSMutableString string];
        }
        
    // If outside a TOP LEVEL element then set the top level element
	} else {
		
		if ([elementName isEqualToString:@"loginuser"]) {
            current_appstate = [[TPAppState alloc] init];
			current_appstate.user_id = [[attributeDict objectForKey:@"user_id"] intValue];
            current_appstate.district_id = [[attributeDict objectForKey:@"district_id"] intValue];
						
		} else if ([elementName isEqualToString:@"user"]) {
			current_user = [[TPUser alloc] init];
			current_user.user_id = [[attributeDict objectForKey:@"user_id"] intValue];
            current_user.type = [[attributeDict objectForKey:@"type"] intValue];
            current_user.school_id = [[attributeDict objectForKey:@"school"] intValue];
            current_user.subject_id = [[attributeDict objectForKey:@"subject"] intValue];
            current_user.permission = [[attributeDict objectForKey:@"permission"] intValue];
            current_user.grade_min = [[attributeDict objectForKey:@"grade_min"] intValue];
            current_user.grade_max = [[attributeDict objectForKey:@"grade_max"] intValue];
            current_user.state = [[attributeDict objectForKey:@"state"] intValue];
						
        } else if ([elementName isEqualToString:@"userinfo"]) {
			current_info = [[TPUserInfo alloc] init];
			current_info.user_id = [[attributeDict objectForKey:@"user_id"] intValue];
            current_info.type = [[attributeDict objectForKey:@"type"] intValue];

        } else if ([elementName isEqualToString:@"category"]) {
			current_category = [[TPCategory alloc] init];
			current_category.category_id = [[attributeDict objectForKey:@"category_id"] intValue];
            current_category.corder = [[attributeDict objectForKey:@"corder"] intValue];
            current_category.state = [[attributeDict objectForKey:@"state"] intValue];
            
        } else if ([elementName isEqualToString:@"rubric"]) {
			current_rubric = [[TPRubric alloc] init];
			current_rubric.rubric_id = [[attributeDict objectForKey:@"rubric_id"] intValue];
            current_rubric.state = [[attributeDict objectForKey:@"state"] intValue];
            current_rubric.rec_stats = [[attributeDict objectForKey:@"stats"] intValue];
            current_rubric.rec_elapsed = [[attributeDict objectForKey:@"elapsed"] intValue];
            current_rubric.rorder = [[attributeDict objectForKey:@"order"] intValue];
            current_rubric.type = [[attributeDict objectForKey:@"type"] intValue];
            current_rubric.version = 0;
            
        } else if ([elementName isEqualToString:@"userdata"]) {
			current_userdata = [[TPUserData alloc] init];
			current_userdata.district_id = [[attributeDict objectForKey:@"district"] intValue];
            current_userdata.user_id = [[attributeDict objectForKey:@"user"] intValue];
            current_userdata.target_id = [[attributeDict objectForKey:@"target"] intValue];
            current_userdata.share = [[attributeDict objectForKey:@"share"] intValue];
            current_userdata.school_id = [[attributeDict objectForKey:@"school"] intValue];
            current_userdata.subject_id = [[attributeDict objectForKey:@"subject"] intValue];
            current_userdata.grade = [[attributeDict objectForKey:@"grade"] intValue];
            current_userdata.elapsed = [[attributeDict objectForKey:@"elapsed"] intValue];
            current_userdata.type = [[attributeDict objectForKey:@"type"] intValue];
            current_userdata.rubric_id = [[attributeDict objectForKey:@"rubric"] intValue];
            current_userdata.state = [[attributeDict objectForKey:@"state"] intValue];
            current_userdata.aud_id = [attributeDict objectForKey:@"aud_id"]; //jxi
            current_userdata.aq_id = [[attributeDict objectForKey:@"aq_id"] intValue]; //jxi

		} else if ([elementName isEqualToString:@"imagedata"]) {
            current_image = [[TPImage alloc] init];
            current_image.district_id = [[attributeDict objectForKey:@"district"] intValue];
            current_image.type = [[attributeDict objectForKey:@"type"] intValue];
            current_image.width = [[attributeDict objectForKey:@"width"] intValue];
            current_image.height = [[attributeDict objectForKey:@"height"] intValue];
            current_image.format = [attributeDict objectForKey:@"format"];
            current_image.encoding = [attributeDict objectForKey:@"encoding"];
            current_image.user_id = [[attributeDict objectForKey:@"user"] intValue];
            
        } else if ([elementName isEqualToString:@"videodata"]) { //jxi;
            current_video = [[TPVideo alloc] init];
            current_video.district_id = [[attributeDict objectForKey:@"district"] intValue];
            current_video.type = [[attributeDict objectForKey:@"type"] intValue];
            current_video.width = [[attributeDict objectForKey:@"width"] intValue];
            current_video.height = [[attributeDict objectForKey:@"height"] intValue];
            current_video.format = [attributeDict objectForKey:@"format"];
            current_video.encoding = [attributeDict objectForKey:@"encoding"];
            current_video.user_id = [[attributeDict objectForKey:@"user"] intValue];
        } else if ([elementName isEqualToString:@"syncstatus"]) {
			current_property = [NSMutableString string];
			
		} else if ([elementName isEqualToString:@"syncmessage"]) {
			current_property = [NSMutableString string];
            
		} else if ([elementName isEqualToString:@"userdatalist"]) { //jxi;
            // Get value of status attribute of userdatalist tag, which indicates the response is partial or complete
            model.userdata_sync_step_response = [[attributeDict objectForKey:@"status"] intValue];
            
        }
	}
}

// ---------------------------------------------------------------------------------------
- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {

	if (debugParser) NSLog(@"didEndElement %@", elementName);

	// Inside user tag
	if (current_appstate) {
		if ([elementName isEqualToString:@"first_name"]) {
			current_appstate.first_name = [model syncDecode:current_property];
		} else if ([elementName isEqualToString:@"last_name"]) {
			current_appstate.last_name = [model syncDecode:current_property];
        } else if ([elementName isEqualToString:@"district"]) {
			current_appstate.district_name = [model syncDecode:current_property];
		} else if ([elementName isEqualToString:@"loginuser"]) {
			appstate.user_id = current_appstate.user_id;
            if (appstate.target_id == 0) { // If subject not set then set to self
                appstate.target_id = current_appstate.user_id;
            }
            appstate.district_id = current_appstate.district_id;
			appstate.first_name = [NSString stringWithString:current_appstate.first_name];
			appstate.last_name = [NSString stringWithString:current_appstate.last_name];
            appstate.district_name = [NSString stringWithString:current_appstate.district_name];
            publicstate.district_name = appstate.district_name;
            publicstate.first_name = appstate.first_name;
            publicstate.last_name = appstate.last_name;
			current_appstate = nil;
		}
				
	// Inside user tag
	} else if (current_user) {
		if ([elementName isEqualToString:@"first_name"]) {
			current_user.first_name = [model syncDecode:current_property];
		} else if ([elementName isEqualToString:@"last_name"]) {
			current_user.last_name = [model syncDecode:current_property];
        } else if ([elementName isEqualToString:@"schools"]) {
			current_user.schools = [model syncDecode:current_property];
        } else if ([elementName isEqualToString:@"subjects"]) {
			current_user.subjects = [model syncDecode:current_property];
        } else if ([elementName isEqualToString:@"modified"]) {
            NSString *modified_str = [model syncDecode:current_property];
			current_user.modified = [model dateFromStr:modified_str];
		} else if ([elementName isEqualToString:@"user"]) {
			[users addObject:current_user];
			current_user = nil;
		}
		
    // Inside user info tag
	} else if (current_info) {
		if ([elementName isEqualToString:@"info"]) {
			current_info.info = [model syncDecode:current_property];
        } else if ([elementName isEqualToString:@"modified"]) {
            NSString *modified_str = [model syncDecode:current_property];
			current_info.modified = [model dateFromStr:modified_str];
		} else if ([elementName isEqualToString:@"userinfo"]) {
			[info addObject:current_info];
			current_info = nil;
		}
        
    // Inside category tag
	} else if (current_category) {
		if ([elementName isEqualToString:@"name"]) {
			current_category.name = [model syncDecode:current_property];
        } else if ([elementName isEqualToString:@"modified"]) {
            NSString *modified_str = [model syncDecode:current_property];
			current_category.modified = [model dateFromStr:modified_str];
		} else if ([elementName isEqualToString:@"category"]) {
			[categories addObject:current_category];
			current_category = nil;
		}

    // Inside rubric tag
	} else if (current_rubric) {
        
        // Process rubric tag (these tags must be unique to rubric tag, not used in subtags)
		if ([elementName isEqualToString:@"title"]) {
			current_rubric.title = [model syncDecode:current_property];
        } else if ([elementName isEqualToString:@"group"]) {
            current_rubric.group = [model syncDecode:current_property];
        } else if ([elementName isEqualToString:@"modified"]) {
            NSString *modified_str = [model syncDecode:current_property];
			current_rubric.modified = [model dateFromStr:modified_str];
        } else if ([elementName isEqualToString:@"rubric"]) {
			[rubrics addObject:current_rubric];
			current_rubric = nil;
		}
        
        // Process question tag
        if (current_question) {
            if ([elementName isEqualToString:@"qtitle"]) {
                current_question.title = [model syncDecode:current_property];
            } else if ([elementName isEqualToString:@"qprompt"]) {
                current_question.prompt = [model syncDecode:current_property];
            } else if ([elementName isEqualToString:@"question"]) {
                [questions addObject:current_question];
                current_question = nil;
            }
        }
        
        // Process rating tag
        if (current_rating) {
            if ([elementName isEqualToString:@"rtitle"]) {
                current_rating.title = [model syncDecode:current_property];
            } else if ([elementName isEqualToString:@"rtext"]) {
                current_rating.text = [model syncDecode:current_property];
            } else if ([elementName isEqualToString:@"rating"]) {
                [ratings addObject:current_rating];
                current_rating = nil;
            }
        }
    
    // Inside userdata tag
	} else if (current_userdata) {
        
        // Process userdata tag (these tags must be unique to userdata tag, not used in subtags)
		if ([elementName isEqualToString:@"userdata_id"]) {
			current_userdata.userdata_id = [model syncDecode:current_property];
        } else if ([elementName isEqualToString:@"name"]) {
			current_userdata.name = [model syncDecode:current_property];
        } else if ([elementName isEqualToString:@"description"]) {
			current_userdata.description = [model syncDecode:current_property];
        } else if ([elementName isEqualToString:@"created"]) {
            NSString *created_str = [model syncDecode:current_property];
			current_userdata.created = [model dateFromStr:created_str];
        } else if ([elementName isEqualToString:@"modified"] && !current_rubricdata) {
            NSString *modified_str = [model syncDecode:current_property];
			current_userdata.modified = [model dateFromStr:modified_str];
        } else if ([elementName isEqualToString:@"userdata"]) {
			[userdata addObject:current_userdata];
			current_userdata = nil;
		}
        
        // Process rubricdata tag
        if (current_rubricdata) {
            if ([elementName isEqualToString:@"value"]) {
                current_rubricdata.value = [[model syncDecode:current_property] floatValue];
            } else if ([elementName isEqualToString:@"text"]) {
                current_rubricdata.text = [model syncDecode:current_property];
            } else if ([elementName isEqualToString:@"modified"]) {
                NSString *modified_str = [model syncDecode:current_property];
                current_rubricdata.modified = [model dateFromStr:modified_str];
            } else if ([elementName isEqualToString:@"datevalue"]) {
                NSString *datevalue_str = [model syncDecode:current_property];
                current_rubricdata.datevalue = [model dateFromStr:datevalue_str];
            } else if ([elementName isEqualToString:@"rubricdata"]) {
                [current_userdata.rubricdata addObject:current_rubricdata];
                current_rubricdata = nil;
            }
        }
        
    } else if (current_image) {
        if ([elementName isEqualToString:@"userdata_id"]) {
            current_image.userdata_id = [model syncDecode:current_property];
        } else if ([elementName isEqualToString:@"modified"]) {
            NSString *modified_str = [model syncDecode:current_property];
			current_image.modified = [model dateFromStr:modified_str];
        } else if ([elementName isEqualToString:@"data"]) {
            NSData *image_data = [NSData dataFromBase64String:current_property];
            current_image.image = [[[UIImage alloc] initWithData:image_data] autorelease];
            NSString *filename = [NSString stringWithString:[TPDatabase imagePathWithUserdataID:current_image.userdata_id suffix:@"jpg" imageType:TP_IMAGE_TYPE_FULL]];
            current_image.filename = filename;
            current_image.origin = TP_IMAGE_ORIGIN_REMOTE;
            model.image_current = current_image;
            current_image = nil;
        }
    } else if (current_video) { //jxi;
        //risin bai
        if ([elementName isEqualToString:@"userdata_id"]) {
            current_video.userdata_id = [model syncDecode:current_property];
        } else if ([elementName isEqualToString:@"modified"]) {
            NSString *modified_str = [model syncDecode:current_property];
            current_video.modified = [model dateFromStr:modified_str];
        } else if ([elementName isEqualToString:@"data"]) {
            NSData *video_data = [NSData dataFromBase64String:current_property];
            //current_image.image = [[[UIImage alloc] initWithData:image_data] autorelease];
            NSString *filename = [NSString stringWithString:[TPDatabase videoPathWithUserdataID:current_video.userdata_id suffix:@"MOV"]];
            //[video_data writeToFile:filename atomically:YES];
            if([[NSFileManager defaultManager] createFileAtPath:filename contents:video_data attributes:nil])
                NSLog(@"success");
            else
                NSLog(@"failed");
            
            current_video.filename = filename;
            current_video.videoUrl = [NSURL fileURLWithPath:filename];
            current_video.origin = TP_IMAGE_ORIGIN_REMOTE;
            model.video_current = current_video;
            current_video = nil;
        }// End test on ending tag
    }
	
	if ([elementName isEqualToString:@"syncstatus"]) {
		appstate.sync_status = [NSString stringWithString:current_property];
	}
	if ([elementName isEqualToString:@"syncmessage"]) {
		appstate.sync_message = [NSString stringWithString:current_property];
	}
    if ([elementName isEqualToString:@"district"]) {
		appstate.district_name = [NSString stringWithString:current_property];
	}
	
	current_property = nil;
}

// ---------------------------------------------------------------------------------------
- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
	
     //NSLog(@"foundCharacters %@", string);
    
    // Skip newlines
	if ([string isEqualToString:@"\n"]) { return; }
	
    // Store property
	if (current_property) { [current_property appendString:string]; }
}

// ---------------------------------------------------------------------------------------
- (void)parser:(NSXMLParser *)parser foundUnparsedEntityDeclarationWithName:(NSString *)name publicID:(NSString *)publicID systemID:(NSString *)systemID notationName:(NSString *)notationName {
    NSLog(@"Warning foundUnparsedEntityDeclarationWithName %@", name);
}

// ---------------------------------------------------------------------------------------
- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
    NSLog(@"ERROR parsing XML: %@ %@", [parseError localizedDescription], current_property);
}

@end
