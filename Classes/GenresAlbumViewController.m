//
//  CacheAlbumViewController.m
//  iSub
//
//  Created by Ben Baron on 6/16/10.
//  Copyright 2010 Ben Baron. All rights reserved.
//

#import "GenresAlbumViewController.h"
#import "iSubAppDelegate.h"
#import "ViewObjectsSingleton.h"
#import "MusicControlsSingleton.h"
#import "DatabaseControlsSingleton.h"
#import "iPhoneStreamingPlayerViewController.h"
#import "GenresAlbumUITableViewCell.h"
#import "GenresSongUITableViewCell.h"
#import "Artist.h"
#import "Album.h"
#import "Song.h"
#import "FMDatabase.h"
#import "FMDatabaseAdditions.h"
#import "NSString-md5.h"
#import "AsynchronousImageViewCached.h"

@implementation GenresAlbumViewController

@synthesize listOfAlbums, listOfSongs, segment, seg1, genre;

-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)inOrientation 
{
	if ([[[iSubAppDelegate sharedInstance].settingsDictionary objectForKey:@"lockRotationSetting"] isEqualToString:@"YES"] 
		&& inOrientation != UIDeviceOrientationPortrait)
		return NO;
	
    return YES;
}

- (void)viewDidLoad 
{
    [super viewDidLoad];
	
	appDelegate = (iSubAppDelegate *)[[UIApplication sharedApplication] delegate];
	viewObjects = [ViewObjectsSingleton sharedInstance];
	musicControls = [MusicControlsSingleton sharedInstance];
	databaseControls = [DatabaseControlsSingleton sharedInstance];
	
	//NSLog(@"segment %i", segment);
	//NSLog(@"listOfAlbums: %@", listOfAlbums);
	//NSLog(@"listOfSongs: %@", listOfSongs);
	
	// Add the table fade
	UIImageView *fadeTop = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"table-fade-top.png"]];
	fadeTop.frame =CGRectMake(0, -10, self.tableView.bounds.size.width, 10);
	fadeTop.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	[self.tableView addSubview:fadeTop];
	[fadeTop release];
	
	UIImageView *fadeBottom = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"table-fade-bottom.png"]] autorelease];
	fadeBottom.frame = CGRectMake(0, 0, self.tableView.bounds.size.width, 10);
	fadeBottom.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	self.tableView.tableFooterView = fadeBottom;
	
	
	// Add the play all button + shuffle button
	UIView *headerView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 50)] autorelease];
	headerView.backgroundColor = [UIColor colorWithRed:226.0/255.0 green:231.0/255.0 blue:238.0/255.0 alpha:1];
	
	UIImageView *playAllImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"play-all-note.png"]];
	playAllImage.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
	playAllImage.frame = CGRectMake(10, 10, 19, 30);
	[headerView addSubview:playAllImage];
	[playAllImage release];
	
	UILabel *playAllLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, 160, 50)];
	playAllLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth;
	playAllLabel.backgroundColor = [UIColor clearColor];
	playAllLabel.textColor = [UIColor colorWithRed:186.0/255.0 green:191.0/255.0 blue:198.0/255.0 alpha:1];
	playAllLabel.textAlignment = UITextAlignmentCenter;
	playAllLabel.font = [UIFont boldSystemFontOfSize:30];
	playAllLabel.text = @"Play All";
	[headerView addSubview:playAllLabel];
	[playAllLabel release];
	
	UIButton *playAllButton = [UIButton buttonWithType:UIButtonTypeCustom];
	playAllButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth;
	playAllButton.frame = CGRectMake(0, 0, 160, 40);
	[playAllButton addTarget:self action:@selector(playAllAction:) forControlEvents:UIControlEventTouchUpInside];
	[headerView addSubview:playAllButton];
	
	UILabel *spacerLabel = [[UILabel alloc] initWithFrame:CGRectMake(158, -2, 6, 50)];
	spacerLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
	spacerLabel.backgroundColor = [UIColor clearColor];
	spacerLabel.textColor = [UIColor colorWithRed:186.0/255.0 green:191.0/255.0 blue:198.0/255.0 alpha:1];
	spacerLabel.font = [UIFont systemFontOfSize:40];
	spacerLabel.text = @"|";
	[headerView addSubview:spacerLabel];
	[spacerLabel release];
	
	UIImageView *shuffleImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"shuffle-small.png"]];
	shuffleImage.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
	shuffleImage.frame = CGRectMake(180, 12, 24, 26);
	[headerView addSubview:shuffleImage];
	[shuffleImage release];
	
	UILabel *shuffleLabel = [[UILabel alloc] initWithFrame:CGRectMake(180, 0, 160, 50)];
	shuffleLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleWidth;
	shuffleLabel.backgroundColor = [UIColor clearColor];
	shuffleLabel.textColor = [UIColor colorWithRed:186.0/255.0 green:191.0/255.0 blue:198.0/255.0 alpha:1];
	shuffleLabel.textAlignment = UITextAlignmentCenter;
	shuffleLabel.font = [UIFont boldSystemFontOfSize:30];
	shuffleLabel.text = @"Shuffle";
	[headerView addSubview:shuffleLabel];
	[shuffleLabel release];
	
	UIButton *shuffleButton = [UIButton buttonWithType:UIButtonTypeCustom];
	shuffleButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleWidth;
	shuffleButton.frame = CGRectMake(160, 0, 160, 40);
	[shuffleButton addTarget:self action:@selector(shuffleAction:) forControlEvents:UIControlEventTouchUpInside];
	[headerView addSubview:shuffleButton];
	
	self.tableView.tableHeaderView = headerView;
}


-(void)viewWillAppear:(BOOL)animated 
{
	[super viewWillAppear:animated];
	
	if(musicControls.showPlayerIcon)
	{
		self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"now-playing.png"] style:UIBarButtonItemStyleBordered target:self action:@selector(nowPlayingAction:)] autorelease];
	}
	else
	{
		self.navigationItem.rightBarButtonItem = nil;
	}
}


- (IBAction)nowPlayingAction:(id)sender
{
	musicControls.isNewSong = NO;
	iPhoneStreamingPlayerViewController *streamingPlayerViewController = [[iPhoneStreamingPlayerViewController alloc] initWithNibName:@"iPhoneStreamingPlayerViewController" bundle:nil];
	streamingPlayerViewController.hidesBottomBarWhenPushed = YES;
	[self.navigationController pushViewController:streamingPlayerViewController animated:YES];
	[streamingPlayerViewController release];
}


- (void)didReceiveMemoryWarning 
{
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
}


- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc 
{
	[seg1 release];
	[genre release];
	[listOfAlbums release];
	[listOfSongs release];
	//self.listOfAlbums = nil;
	//self.listOfSongs = nil;
    [super dealloc];
}


- (void)showPlayer
{
	// Start the player
	musicControls.isNewSong = YES;
	
	[musicControls playSongAtPosition:0];
	
	if (IS_IPAD())
	{
		[[NSNotificationCenter defaultCenter] postNotificationName:@"showPlayer" object:nil];
	}
	else
	{
		iPhoneStreamingPlayerViewController *streamingPlayerViewController = [[iPhoneStreamingPlayerViewController alloc] initWithNibName:@"iPhoneStreamingPlayerViewController" bundle:nil];
		streamingPlayerViewController.hidesBottomBarWhenPushed = YES;
		[self.navigationController pushViewController:streamingPlayerViewController animated:YES];
		[streamingPlayerViewController release];
	}	
}


- (void)playAllSongs
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	// Turn off shuffle mode in case it's on
	musicControls.isShuffle = NO;
	
	// Reset the current playlist
	[databaseControls resetCurrentPlaylistDb];
	
	// Get the ID of all matching records (everything in genre ordered by artist)
	FMResultSet *result;
	if (viewObjects.isOfflineMode)
		result = [databaseControls.songCacheDb executeQuery:[NSString stringWithFormat:@"SELECT md5 FROM cachedSongsLayout WHERE seg1 = ? AND seg%i = ? AND genre = ? ORDER BY seg%i COLLATE NOCASE", (segment - 1), segment], seg1, self.title, genre];
	else
		result = [databaseControls.genresDb executeQuery:[NSString stringWithFormat:@"SELECT md5 FROM genresLayout WHERE seg1 = ? AND seg%i = ? AND genre = ? ORDER BY seg%i COLLATE NOCASE", (segment - 1), segment], seg1, self.title, genre];
	
	while ([result next])
	{
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		NSString *songIdMD5 = [result stringForColumnIndex:0];
		Song *aSong = [databaseControls songFromGenreDb:songIdMD5];
		
		[databaseControls addSongToPlaylistQueue:aSong];
		
		[pool release];
	}
	
	[result close];
	
	if (viewObjects.isJukebox)
		[musicControls jukeboxReplacePlaylistWithLocal];
	
	// Hide loading screen
	[viewObjects performSelectorOnMainThread:@selector(hideLoadingScreen) withObject:nil waitUntilDone:NO];
	
	// Show the player
	[self performSelectorOnMainThread:@selector(showPlayer) withObject:nil waitUntilDone:NO];
	
	[pool release];
}

- (void)shuffleSongs
{	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	// Turn off shuffle mode to reduce inserts
	musicControls.isShuffle = NO;
	
	// Reset the current playlist
	[databaseControls resetCurrentPlaylistDb];
	
	// Get the ID of all matching records (everything in genre ordered by artist)
	FMResultSet *result;
	if (viewObjects.isOfflineMode)
		result = [databaseControls.songCacheDb executeQuery:[NSString stringWithFormat:@"SELECT md5 FROM cachedSongsLayout WHERE seg1 = ? AND seg%i = ? AND genre = ? ORDER BY seg%i COLLATE NOCASE", (segment - 1), segment], seg1, self.title, genre];
	else
		result = [databaseControls.genresDb executeQuery:[NSString stringWithFormat:@"SELECT md5 FROM genresLayout WHERE seg1 = ? AND seg%i = ? AND genre = ? ORDER BY seg%i COLLATE NOCASE", (segment - 1), segment], seg1, self.title, genre];
	
	while ([result next])
	{
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		NSString *songIdMD5 = [result stringForColumnIndex:0];
		Song *aSong = [databaseControls songFromGenreDb:songIdMD5];
		
		[databaseControls addSongToPlaylistQueue:aSong];
		
		[pool release];
	}
	
	[result close];
	
	// Shuffle the playlist
	[databaseControls shufflePlaylist];
	
	if (viewObjects.isJukebox)
		[musicControls jukeboxReplacePlaylistWithLocal];
	
	// Set the isShuffle flag
	musicControls.isShuffle = YES;
	
	// Hide loading screen
	[viewObjects performSelectorOnMainThread:@selector(hideLoadingScreen) withObject:nil waitUntilDone:NO];
	
	// Show the player
	[self performSelectorOnMainThread:@selector(showPlayer) withObject:nil waitUntilDone:NO];
	
	[pool release];
}

- (void)playAllAction:(id)sender
{
	[viewObjects showLoadingScreen:self.view.superview blockInput:YES mainWindow:NO];
	
	[self performSelectorInBackground:@selector(playAllSongs) withObject:nil];
}

- (void)shuffleAction:(id)sender
{
	[viewObjects showLoadingScreen:self.view.superview blockInput:YES mainWindow:NO];
	
	[self performSelectorInBackground:@selector(shuffleSongs) withObject:nil];
}


#pragma mark Table view methods

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	return ([self.listOfAlbums count] + [self.listOfSongs count]);
}


// Customize the height of individual rows to make the album rows taller to accomidate the album art.
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath 
{
	if (indexPath.row < [listOfAlbums count])
		return 60.0;
	else
		return 50.0;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{	
	static NSString *CellIdentifier = @"Cell";
	
	// Set up the cell...
	if (indexPath.row < [listOfAlbums count])
	{
		GenresAlbumUITableViewCell *cell = [[[GenresAlbumUITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		cell.segment = self.segment;
		cell.seg1 = self.seg1;
		cell.genre = genre;
		
		NSString *md5 = [[listOfAlbums objectAtIndex:indexPath.row] objectAtIndex:0];
		NSString *coverArtId;
		if (viewObjects.isOfflineMode) {
			coverArtId = [databaseControls.songCacheDb stringForQuery:@"SELECT coverArtId FROM genresSongs WHERE md5 = ?", md5];
		}
		else {
			coverArtId = [databaseControls.genresDb stringForQuery:@"SELECT coverArtId FROM genresSongs WHERE md5 = ?", md5];
		}
		NSString *name = [[listOfAlbums objectAtIndex:indexPath.row] objectAtIndex:1];
		
		if (coverArtId)
		{
			if ([databaseControls.coverArtCacheDb60 intForQuery:@"SELECT COUNT(*) FROM coverArtCache WHERE id = ?", [NSString md5:coverArtId]] == 1)
			{
				// If the image is already in the cache database, load it
				cell.coverArtView.image = [UIImage imageWithData:[databaseControls.coverArtCacheDb60 dataForQuery:@"SELECT data FROM coverArtCache WHERE id = ?", [NSString md5:coverArtId]]];
			}
			else 
			{	
				if (viewObjects.isOfflineMode)
				{
					// Image not cached and we're offline so display the default image
					cell.coverArtView.image = [UIImage imageNamed:@"default-album-art-small.png"];
				}
				else 
				{
					// Image not cached, grab it from the url and cache it
					NSString *imgUrlString;
					if (appDelegate.isHighRez)
					{
						imgUrlString = [NSString stringWithFormat:@"%@%@&size=120", [appDelegate getBaseUrl:@"getCoverArt.view"], coverArtId];
					}
					else
					{
						imgUrlString = [NSString stringWithFormat:@"%@%@&size=60", [appDelegate getBaseUrl:@"getCoverArt.view"], coverArtId];
					}
					[cell.coverArtView loadImageFromURLString:imgUrlString coverArtId:coverArtId];
				}
			}
		}
		else
		{
			// If there's no cover art at all, display the default image
			cell.coverArtView.image = [UIImage imageNamed:@"default-album-art-small.png"];
		}
		
		[cell.albumNameLabel setText:name];
		cell.backgroundView = [[[UIView alloc] init] autorelease];
		if(indexPath.row % 2 == 0)
			cell.backgroundView.backgroundColor = [UIColor whiteColor];
		else
			cell.backgroundView.backgroundColor = [UIColor colorWithRed:226.0/255.0 green:231.0/255.0 blue:238.0/255.0 alpha:1];		
		
		return cell;
	}
	else
	{
		GenresSongUITableViewCell *cell = [[[GenresSongUITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
		cell.accessoryType = UITableViewCellAccessoryNone;
		NSUInteger a = indexPath.row - [listOfAlbums count];
		cell.md5 = [listOfSongs objectAtIndex:a];
		
		Song *aSong = [databaseControls songFromGenreDb:cell.md5];
		
		if (aSong.track)
		{
			cell.trackNumberLabel.text = [NSString stringWithFormat:@"%i", [aSong.track intValue]];
		}
		else
		{	
			cell.trackNumberLabel.text = @"";
		}
			
		cell.songNameLabel.text = aSong.title;
		
		if (aSong.artist)
			cell.artistNameLabel.text = aSong.artist;
		else
			cell.artistNameLabel.text = @"";		
		
		if (aSong.duration)
			cell.songDurationLabel.text = [appDelegate formatTime:[aSong.duration floatValue]];
		else
			cell.songDurationLabel.text = @"";
		
		cell.backgroundView = [[[UIView alloc] init] autorelease];
		if (viewObjects.isOfflineMode)
		{
			if(indexPath.row % 2 == 0)
			{
				cell.backgroundView.backgroundColor = viewObjects.lightNormal;
			}
			else
			{
				cell.backgroundView.backgroundColor = viewObjects.darkNormal;
			}	
		}
		else
		{
			if(indexPath.row % 2 == 0)
			{
				if ([databaseControls.songCacheDb stringForQuery:@"SELECT md5 FROM cachedSongs WHERE md5 = ? and finished = 'YES'", cell.md5] != nil)
					cell.backgroundView.backgroundColor = [viewObjects currentLightColor];
				else
					cell.backgroundView.backgroundColor = viewObjects.lightNormal;
			}
			else
			{
				if ([databaseControls.songCacheDb stringForQuery:@"SELECT md5 FROM cachedSongs WHERE md5 = ? and finished = 'YES'", cell.md5] != nil)
					cell.backgroundView.backgroundColor = [viewObjects currentDarkColor];
				else
					cell.backgroundView.backgroundColor = viewObjects.darkNormal;
			}
		}
		
		return cell;
	}
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{	
	if (viewObjects.isCellEnabled)
	{
		if (indexPath.row < [listOfAlbums count])
		{		
			GenresAlbumViewController *genresAlbumViewController = [[GenresAlbumViewController alloc] initWithNibName:@"GenresAlbumViewController" bundle:nil];
			genresAlbumViewController.title = [[listOfAlbums objectAtIndex:indexPath.row] objectAtIndex:1];
			genresAlbumViewController.listOfAlbums = [NSMutableArray arrayWithCapacity:1];
			genresAlbumViewController.listOfSongs = [NSMutableArray arrayWithCapacity:1];
			//genresAlbumViewController.listOfAlbums = [[NSMutableArray alloc] init];
			//genresAlbumViewController.listOfSongs = [[NSMutableArray alloc] init];
			genresAlbumViewController.segment = (self.segment + 1);
			genresAlbumViewController.seg1 = self.seg1;
			genresAlbumViewController.genre = [NSString stringWithString:genre];
			FMResultSet *result;
			if (viewObjects.isOfflineMode) 
			{
				result = [databaseControls.songCacheDb executeQuery:[NSString stringWithFormat:@"SELECT md5, segs, seg%i FROM cachedSongsLayout WHERE seg1 = ? AND seg%i = ? AND genre = ? GROUP BY seg%i ORDER BY seg%i COLLATE NOCASE", (segment + 1), segment, (segment + 1), (segment + 1)], seg1, [[listOfAlbums objectAtIndex:indexPath.row] objectAtIndex:1], genre];
			}
			else 
			{
				result = [databaseControls.genresDb executeQuery:[NSString stringWithFormat:@"SELECT md5, segs, seg%i FROM genresLayout WHERE seg1 = ? AND seg%i = ? AND genre = ? GROUP BY seg%i ORDER BY seg%i COLLATE NOCASE", (segment + 1), segment, (segment + 1), (segment + 1)], seg1, [[listOfAlbums objectAtIndex:indexPath.row] objectAtIndex:1], genre];
			}
			while ([result next])
			{
				if ([result intForColumnIndex:1] > (segment + 1))
				{
					[genresAlbumViewController.listOfAlbums addObject:[NSArray arrayWithObjects:[NSString stringWithString:[result stringForColumnIndex:0]], [NSString stringWithString:[result stringForColumnIndex:2]], nil]];
				}
				else
				{
					[genresAlbumViewController.listOfSongs addObject:[NSString stringWithString:[result stringForColumnIndex:0]]];
				}
			}
			[result close];
			//NSLog(@"genresAlbumViewController.listOfSongs: %@", genresAlbumViewController.listOfSongs);
						
			[self.navigationController pushViewController:genresAlbumViewController animated:YES];
			[genresAlbumViewController release];
		}
		else
		{
			/*NSUInteger a = indexPath.row - [listOfAlbums count];
			musicControls.currentSongObject = nil; musicControls.currentSongObject = [databaseControls songFromGenreDb:[listOfSongs objectAtIndex:a]];
			
			musicControls.currentPlaylistPosition = a;
			[databaseControls resetCurrentPlaylistDb];
			for(NSString *songMD5 in listOfSongs)
			{
				//NSLog(@"songMD5: %@", songMD5);
				Song *aSong = [databaseControls songFromGenreDb:songMD5];
				//NSLog(@"aSong: %@", aSong);
				[databaseControls insertSong:aSong intoTable:@"currentPlaylist" inDatabase:databaseControls.currentPlaylistDb];
			}
			
			musicControls.nextSongObject = nil; musicControls.nextSongObject = [databaseControls songFromDbRow:(a + 1) inTable:@"currentPlaylist" inDatabase:databaseControls.currentPlaylistDb];
			
			musicControls.isNewSong = YES;
			musicControls.isShuffle = NO;
			
			[musicControls destroyStreamer];
			musicControls.seekTime = 0.0;
			[musicControls playPauseSong];
			
			if (IS_IPAD())
			{
				[[NSNotificationCenter defaultCenter] postNotificationName:@"showPlayer" object:nil];
			}
			else
			{
				iPhoneStreamingPlayerViewController *streamingPlayerViewController = [[iPhoneStreamingPlayerViewController alloc] initWithNibName:@"iPhoneStreamingPlayerViewController" bundle:nil];
				streamingPlayerViewController.hidesBottomBarWhenPushed = YES;
				[self.navigationController pushViewController:streamingPlayerViewController animated:YES];
				[streamingPlayerViewController release];
			}*/
			
			// Kill the streamer if it's playing
			[musicControls destroyStreamer];
			
			// Find the new playlist position
			NSUInteger songRow = indexPath.row - [listOfAlbums count];
			musicControls.currentPlaylistPosition = songRow;
			
			// Clear the current playlist
			if (viewObjects.isJukebox)
				[databaseControls resetJukeboxPlaylist];
			else
				[databaseControls resetCurrentPlaylistDb];
			
			// Add the songs to the playlist 
			NSMutableArray *songIds = [[NSMutableArray alloc] init];
			for(NSString *songMD5 in listOfSongs)
			{
				NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
				
				Song *aSong = [databaseControls songFromGenreDb:songMD5];

				[databaseControls addSongToPlaylistQueue:aSong];
				
				// In jukebox mode, collect the song ids to send to the server
				if (viewObjects.isJukebox)
					[songIds addObject:aSong.songId];
				
				[pool release];
			}
			
			// If jukebox mode, send song ids to server
			if (viewObjects.isJukebox)
			{
				[musicControls jukeboxStop];
				[musicControls jukeboxClearPlaylist];
				[musicControls jukeboxAddSongs:songIds];
			}
			[songIds release];
			
			// Set the current and next song objects
			if (viewObjects.isJukebox)
			{
				musicControls.currentSongObject = [databaseControls songFromDbRow:songRow inTable:@"jukeboxCurrentPlaylist" inDatabase:databaseControls.currentPlaylistDb];
				musicControls.nextSongObject = [databaseControls songFromDbRow:(songRow + 1) inTable:@"jukeboxCurrentPlaylist" inDatabase:databaseControls.currentPlaylistDb];
			}
			else
			{
				musicControls.currentSongObject = [databaseControls songFromDbRow:songRow inTable:@"currentPlaylist" inDatabase:databaseControls.currentPlaylistDb];
				musicControls.nextSongObject = [databaseControls songFromDbRow:(songRow + 1) inTable:@"currentPlaylist" inDatabase:databaseControls.currentPlaylistDb];
			}
			
			// Set player defaults
			musicControls.isNewSong = YES;
			musicControls.isShuffle = NO;
			
			
			// Start the song
			musicControls.seekTime = 0.0;
			[musicControls playSongAtPosition:songRow];
			
			// Show the player
			if (IS_IPAD())
			{
				[[NSNotificationCenter defaultCenter] postNotificationName:@"showPlayer" object:nil];
			}
			else
			{
				iPhoneStreamingPlayerViewController *streamingPlayerViewController = [[iPhoneStreamingPlayerViewController alloc] initWithNibName:@"iPhoneStreamingPlayerViewController" bundle:nil];
				streamingPlayerViewController.hidesBottomBarWhenPushed = YES;
				[self.navigationController pushViewController:streamingPlayerViewController animated:YES];
				[streamingPlayerViewController release];
			}
		}
	}
	else
	{
		[self.tableView deselectRowAtIndexPath:indexPath animated:NO];
	}
}


@end
