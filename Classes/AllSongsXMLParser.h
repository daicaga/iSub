//
//  AllSongsXMLParser.h
//  XML
//
//  Created by iPhone SDK Articles on 11/23/08.
//  Copyright 2008 www.iPhoneSDKArticles.com.
//

#import <UIKit/UIKit.h>

@class iSubAppDelegate, ViewObjectsSingleton, Song, DatabaseControlsSingleton;

@interface AllSongsXMLParser : NSObject <NSXMLParserDelegate>
{

	NSMutableString *currentElementValue;
	
	iSubAppDelegate *appDelegate; 
	ViewObjectsSingleton *viewObjects;
	DatabaseControlsSingleton *databaseControls;
	
	NSInteger iteration;
	NSString *albumName;
}

@property NSInteger iteration;
@property (nonatomic, retain) NSString *albumName;

- (AllSongsXMLParser *) initXMLParser;

@end