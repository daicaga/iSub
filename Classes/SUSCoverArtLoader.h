//
//  SUSCoverArtLoader.h
//  iSub
//
//  Created by Ben Baron on 11/1/11.
//  Copyright (c) 2011 Ben Baron. All rights reserved.
//

#import "SUSLoader.h"

@class FMDatabase;
@interface SUSCoverArtLoader : SUSLoader

@property (copy) NSString *coverArtId;
@property (readonly) BOOL isCoverArtCached;
@property (readonly) FMDatabase *db;
@property BOOL isLarge;

- (id)initWithDelegate:(NSObject<SUSLoaderDelegate>*)delegate coverArtId:(NSString *)artId isLarge:(BOOL)large;
- (BOOL)downloadArtIfNotExists;

@end