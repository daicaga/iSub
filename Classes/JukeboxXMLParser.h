//
//  JukeboxXMLParser.h
//  iSub
//
//  Created by bbaron on 11/5/10.
//  Copyright 2010 Ben Baron. All rights reserved.
//

#import <Foundation/Foundation.h>

@class iSubAppDelegate, ViewObjectsSingleton, DatabaseControlsSingleton;

@interface JukeboxXMLParser : NSObject <NSXMLParserDelegate>
{	
	iSubAppDelegate *appDelegate; 
	/*DatabaseControlsSingleton *databaseControls;
	ViewObjectsSingleton *viewObjects;*/

	NSUInteger currentIndex;
	BOOL isPlaying;
	float gain;
	
	NSMutableArray *listOfSongs;
}

@property NSUInteger currentIndex;
@property BOOL isPlaying;
@property float gain;

@property (nonatomic, retain) NSMutableArray *listOfSongs;

- (id) initXMLParser;

@end