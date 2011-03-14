//
//  Artist.h
//  iSub
//
//  Created by Ben Baron on 2/27/10.
//  Copyright 2010 Ben Baron. All rights reserved.
//


@interface Artist : NSObject <NSCoding, NSCopying> {
	
	NSString *name;
	NSString *artistId;
}

@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *artistId;

+ (Artist *) artistWithName:(NSString *)theName andArtistId:(NSString *)theId;

-(void) encodeWithCoder: (NSCoder *) encoder;
-(id) initWithCoder: (NSCoder *) decoder;

- (id) initWithAttributeDict:(NSDictionary *)attributeDict;

@end