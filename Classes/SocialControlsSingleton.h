//
//  SocialControlsSingleton.h
//  iSub
//
//  Created by Ben Baron on 10/15/10.
//  Copyright 2010 Ben Baron. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SA_OAuthTwitterController.h"

@class SA_OAuthTwitterEngine;

@interface SocialControlsSingleton : NSObject <SA_OAuthTwitterControllerDelegate>
{
	
	SA_OAuthTwitterEngine *twitterEngine;

}

@property (nonatomic, retain) SA_OAuthTwitterEngine *twitterEngine;

+ (SocialControlsSingleton*)sharedInstance;

- (void) createTwitterEngine;

@end