//
//  ChatMessage.h
//  iSub
//
//  Created by bbaron on 8/16/10.
//  Copyright 2010 Ben Baron. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ChatMessage : NSObject <NSCopying> 
{
	NSInteger timestamp;
	NSString *user;
	NSString *message;
}

@property NSInteger timestamp;
@property (nonatomic, retain) NSString *user;
@property (nonatomic, retain) NSString *message;

-(id) copyWithZone: (NSZone *) zone;

@end