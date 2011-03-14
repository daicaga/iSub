//
//  PlaylistsUITableViewCell.m
//  iSub
//
//  Created by Ben Baron on 4/2/10.
//  Copyright 2010 Ben Baron. All rights reserved.
//

#import "PlaylistsUITableViewCell.h"
#import "iSubAppDelegate.h"
#import "ViewObjectsSingleton.h"
#import "MusicControlsSingleton.h"
#import "DatabaseControlsSingleton.h"
#import "PlaylistsXMLParser.h"
#import "CellOverlay.h"
#import "NSString-md5.h"

@implementation PlaylistsUITableViewCell

@synthesize indexPath, playlistNameScrollView, playlistNameLabel, isOverlayShowing, overlayView;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier 
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) 
	{
        // Initialization code
		appDelegate = (iSubAppDelegate *)[[UIApplication sharedApplication] delegate];
		viewObjects = [ViewObjectsSingleton sharedInstance];
		musicControls = [MusicControlsSingleton sharedInstance];
		databaseControls = [DatabaseControlsSingleton sharedInstance];
		
		isOverlayShowing = NO;
		
		playlistNameScrollView = [[UIScrollView alloc] init];
		playlistNameScrollView.frame = CGRectMake(5, 10, 290, 44);
		playlistNameScrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		playlistNameScrollView.showsVerticalScrollIndicator = NO;
		playlistNameScrollView.showsHorizontalScrollIndicator = NO;
		playlistNameScrollView.userInteractionEnabled = NO;
		playlistNameScrollView.decelerationRate = UIScrollViewDecelerationRateFast;
		[self.contentView addSubview:playlistNameScrollView];
		[playlistNameScrollView release];
		
		playlistNameLabel = [[UILabel alloc] init];
		playlistNameLabel.backgroundColor = [UIColor clearColor];
		playlistNameLabel.textAlignment = UITextAlignmentLeft; // default
		playlistNameLabel.font = [UIFont boldSystemFontOfSize:20];
		[playlistNameScrollView addSubview:playlistNameLabel];
		[playlistNameLabel release];
    }
    return self;
}


// Empty function
- (void)toggleDelete
{
}


- (void)downloadAction
{
	[viewObjects showLoadingScreenOnMainWindow];
	[self performSelectorInBackground:@selector(downloadAllSongs) withObject:nil];
	
	overlayView.downloadButton.alpha = .3;
	overlayView.downloadButton.enabled = NO;
	
	[self hideOverlay];
}


- (void)downloadAllSongs
{
	// Create an autorelease pool because this method runs in a background thread and can't use the main thread's pool
	NSAutoreleasePool *autoreleasePool = [[NSAutoreleasePool alloc] init];
	
	viewObjects.subsonicPlaylist = [viewObjects.listOfPlaylists objectAtIndex:indexPath.row];
	
	NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@", [appDelegate getBaseUrl:@"getPlaylist.view"], [[viewObjects.listOfPlaylists objectAtIndex:indexPath.row] objectAtIndex:0]]]];
	PlaylistsXMLParser *parser = [[PlaylistsXMLParser alloc] initXMLParser];
	[xmlParser setDelegate:parser];
	[xmlParser parse];
	[xmlParser release];
	[parser release];
	
	// Add each song to cache queue
	NSString *md5 = [NSString md5:[viewObjects.subsonicPlaylist objectAtIndex:0]];
	int count = [databaseControls serverPlaylistCount:md5];
	for (int i = 0; i < count; i++)
	{
		Song *aSong = [databaseControls songFromServerPlaylistId:md5 row:i];
		[databaseControls addSongToCacheQueue:aSong];
	}
	
	if (musicControls.isQueueListDownloading == NO)
	{
		[musicControls performSelectorOnMainThread:@selector(downloadNextQueuedSong) withObject:nil waitUntilDone:NO];
	}	
	
	// Hide the loading screen
	[viewObjects performSelectorOnMainThread:@selector(hideLoadingScreen) withObject:nil waitUntilDone:YES];
	
	[autoreleasePool release];
}


- (void)queueAction
{
	[viewObjects showLoadingScreenOnMainWindow];
	[self performSelectorInBackground:@selector(queueAllSongs) withObject:nil];
	[self hideOverlay];
}


- (void)queueAllSongs
{
	// Create an autorelease pool because this method runs in a background thread and can't use the main thread's pool
	NSAutoreleasePool *autoreleasePool = [[NSAutoreleasePool alloc] init];
	
	viewObjects.subsonicPlaylist = [viewObjects.listOfPlaylists objectAtIndex:indexPath.row];
		
	NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@", [appDelegate getBaseUrl:@"getPlaylist.view"], [[viewObjects.listOfPlaylists objectAtIndex:indexPath.row] objectAtIndex:0]]]];
	PlaylistsXMLParser *parser = [[PlaylistsXMLParser alloc] initXMLParser];
	[xmlParser setDelegate:parser];
	[xmlParser parse];
	[xmlParser release];
	[parser release];
	
	// Add each song to playlist
	NSString *md5 = [NSString md5:[viewObjects.subsonicPlaylist objectAtIndex:0]];
	int count = [databaseControls serverPlaylistCount:md5];
	for (int i = 0; i < count; i++)
	{
		Song *aSong = [databaseControls songFromServerPlaylistId:md5 row:i];
		[databaseControls addSongToPlaylistQueue:aSong];
	}
	
	[viewObjects performSelectorOnMainThread:@selector(hideLoadingScreen) withObject:nil waitUntilDone:YES];
	
	[autoreleasePool release];
}


- (void)blockerAction
{
	//NSLog(@"blockerAction");
	[self hideOverlay];
}


- (void)hideOverlay
{
	if (overlayView)
	{
		[UIView beginAnimations:nil context:NULL];
		[UIView setAnimationDuration:.5];
		overlayView.alpha = 0.0;
		[UIView commitAnimations];
		
		isOverlayShowing = NO;
		
		//[self.downloadButton removeFromSuperview];
		//[self.queueButton removeFromSuperview];
		//[self.overlayView removeFromSuperview];
	}
}


- (void)showOverlay
{
	if (!isOverlayShowing)
	{
		overlayView = [CellOverlay cellOverlayWithTableCell:self];
		[self.contentView addSubview:overlayView];
		
		[UIView beginAnimations:nil context:NULL];
		[UIView setAnimationDuration:.5];
		overlayView.alpha = 1.0;
		[UIView commitAnimations];		
		
		isOverlayShowing = YES;
	}
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {

    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


- (void)layoutSubviews 
{
    [super layoutSubviews];
	
	// Automatically set the width based on the width of the text
	playlistNameLabel.frame = CGRectMake(0, 0, 290, 44);
	CGSize expectedLabelSize = [playlistNameLabel.text sizeWithFont:playlistNameLabel.font constrainedToSize:CGSizeMake(1000,44) lineBreakMode:playlistNameLabel.lineBreakMode]; 
	CGRect newFrame = playlistNameLabel.frame;
	newFrame.size.width = expectedLabelSize.width;
	playlistNameLabel.frame = newFrame;
}


#pragma mark Touch gestures for custom cell view

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event 
{
	UITouch *touch = [touches anyObject];
    startTouchPosition = [touch locationInView:self];
	swiping = NO;
	hasSwiped = NO;
	fingerIsMovingLeftOrRight = NO;
	fingerMovingVertically = NO;
	[self.nextResponder touchesBegan:touches withEvent:event];
}


- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event 
{
	if ([self isTouchGoingLeftOrRight:[touches anyObject]]) 
	{
		[self lookForSwipeGestureInTouches:(NSSet *)touches withEvent:(UIEvent *)event];
		[super touchesMoved:touches withEvent:event];
	} 
	else 
	{
		[self.nextResponder touchesMoved:touches withEvent:event];
	}
}


// Determine what kind of gesture the finger event is generating
- (BOOL)isTouchGoingLeftOrRight:(UITouch *)touch 
{
    CGPoint currentTouchPosition = [touch locationInView:self];
	if (fabsf(startTouchPosition.x - currentTouchPosition.x) >= 1.0) 
	{
		fingerIsMovingLeftOrRight = YES;
		return YES;
    } 
	else 
	{
		fingerIsMovingLeftOrRight = NO;
		return NO;
	}
	
	if (fabsf(startTouchPosition.y - currentTouchPosition.y) >= 2.0) 
	{
		fingerMovingVertically = YES;
	} 
	else 
	{
		fingerMovingVertically = NO;
	}
}


- (BOOL)fingerIsMoving {
	return fingerIsMovingLeftOrRight;
}

- (BOOL)fingerIsMovingVertically {
	return fingerMovingVertically;
}

// Check for swipe gestures
- (void)lookForSwipeGestureInTouches:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint currentTouchPosition = [touch locationInView:self];
	
	[self setSelected:NO];
	swiping = YES;
	
	//ShoppingAppDelegate *appDelegate = (ShoppingAppDelegate *)[[UIApplication sharedApplication] delegate];
	
	if (hasSwiped == NO) 
	{
		// If the swipe tracks correctly.
		if (fabsf(startTouchPosition.x - currentTouchPosition.x) >= viewObjects.kHorizSwipeDragMin &&
			fabsf(startTouchPosition.y - currentTouchPosition.y) <= viewObjects.kVertSwipeDragMax)
		{
			// It appears to be a swipe.
			if (startTouchPosition.x < currentTouchPosition.x) 
			{
				// Right swipe
				// Disable the cells so we don't get accidental selections
				viewObjects.isCellEnabled = NO;
				
				hasSwiped = YES;
				swiping = NO;
				
				[self showOverlay];
				
				// Re-enable cell touches in 1 second
				viewObjects.cellEnabledTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:viewObjects selector:@selector(enableCells) userInfo:nil repeats:NO];
			} 
			else 
			{
				// Left Swipe
				// Disable the cells so we don't get accidental selections
				viewObjects.isCellEnabled = NO;
				
				hasSwiped = YES;
				swiping = NO;
				
				if (playlistNameLabel.frame.size.width > playlistNameScrollView.frame.size.width)
				{
					[playlistNameScrollView setContentOffset:CGPointMake(playlistNameLabel.frame.size.width - playlistNameScrollView.frame.size.width, 0) animated:YES];
					[UIView beginAnimations:@"scroll" context:nil];
					[UIView setAnimationDelegate:self];
					[UIView setAnimationDidStopSelector:@selector(textScrollingStopped)];
					[UIView setAnimationDuration:playlistNameLabel.frame.size.width/(float)150];
					playlistNameScrollView.contentOffset = CGPointMake(playlistNameLabel.frame.size.width - playlistNameScrollView.frame.size.width, 0);
					[UIView commitAnimations];
				}
				
				// Re-enable cell touches in 1 second
				viewObjects.cellEnabledTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:viewObjects selector:@selector(enableCells) userInfo:nil repeats:NO];
			}
		} 
		else 
		{
			// Process a non-swipe event.
		}
		
	}
}


- (void)textScrollingStopped
{
	[UIView beginAnimations:@"scroll" context:nil];
	[UIView setAnimationDuration:playlistNameLabel.frame.size.width/(float)150];
	playlistNameScrollView.contentOffset = CGPointZero;
	[UIView commitAnimations];
}


- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event 
{
	swiping = NO;
	hasSwiped = NO;
	fingerMovingVertically = NO;
	[self.nextResponder touchesEnded:touches withEvent:event];
}


- (void)dealloc {
	[indexPath release];
	//[playlistNameLabel release];
	[super dealloc];
}


@end