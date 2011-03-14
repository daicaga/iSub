//
//  PlaylistSongsViewController.m
//  iSub
//
//  Created by Ben Baron on 4/2/10.
//  Copyright 2010 Ben Baron. All rights reserved.
//

#import "PlaylistSongsViewController.h"
#import "iSubAppDelegate.h"
#import "ViewObjectsSingleton.h"
#import "MusicControlsSingleton.h"
#import "DatabaseControlsSingleton.h"
#import "iPhoneStreamingPlayerViewController.h"
#import "ServerListViewController.h"
#import "PlaylistsXMLParser.h"
#import "PlaylistSongUITableViewCell.h"
#import "AsynchronousImageViewCached.h"
#import "Song.h"
#import "FMDatabase.h"
#import "FMDatabaseAdditions.h"
#import "NSString-md5.h"
#import "EGORefreshTableHeaderView.h"
#import "CustomUIAlertView.h"

@interface PlaylistSongsViewController (Private)

- (void)dataSourceDidFinishLoadingNewData;

@end


@implementation PlaylistSongsViewController

@synthesize md5;
@synthesize reloading=_reloading;

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

    if (viewObjects.isLocalPlaylist)
	{
		self.title = [databaseControls.localPlaylistsDb stringForQuery:@"SELECT playlist FROM localPlaylists WHERE md5 = ?", self.md5];
		
		UIImageView *fadeTop = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"table-fade-top.png"]];
		fadeTop.frame =CGRectMake(0, -10, self.tableView.bounds.size.width, 10);
		fadeTop.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		[self.tableView addSubview:fadeTop];
		[fadeTop release];
	}
	else
	{
		self.title = [viewObjects.subsonicPlaylist objectAtIndex:1];
		//playlistCount = [databaseControls.serverPlaylistsDb intForQuery:[NSString stringWithFormat:@"SELECT COUNT(*) FROM playlist%@", md5]];
		playlistCount = [databaseControls.localPlaylistsDb intForQuery:[NSString stringWithFormat:@"SELECT COUNT(*) FROM splaylist%@", md5]];
		[self.tableView reloadData];
		
		// Add the pull to refresh view
		refreshHeaderView = [[EGORefreshTableHeaderView alloc] initWithFrame:CGRectMake(0.0f, 0.0f - self.tableView.bounds.size.height, 320.0f, self.tableView.bounds.size.height)];
		refreshHeaderView.backgroundColor = [UIColor colorWithRed:226.0/255.0 green:231.0/255.0 blue:237.0/255.0 alpha:1.0];
		[self.tableView addSubview:refreshHeaderView];
		[refreshHeaderView release];
	}
	
	// Add the table fade
	UIImageView *fadeBottom = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"table-fade-bottom.png"]] autorelease];
	fadeBottom.frame = CGRectMake(0, 0, self.tableView.bounds.size.width, 10);
	fadeBottom.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	self.tableView.tableFooterView = fadeBottom;
}

-(void)loadData
{
	//viewObjects.listOfPlaylistSongs = nil;
	//[databaseControls removeServerPlaylistTable:md5];
	//playlistCount = 0;
	//[self.tableView reloadData];
	
	NSString *urlString = [NSString stringWithFormat:@"%@%@", [appDelegate getBaseUrl:@"getPlaylist.view"], [viewObjects.subsonicPlaylist objectAtIndex:0]];
	NSLog(@"server playlist urlString: %@", urlString);
	NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString] cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:kLoadingTimeout];
	connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
	if (connection)
	{
		// Create the NSMutableData to hold the received data.
		// receivedData is an instance variable declared elsewhere.
		receivedData = [[NSMutableData data] retain];
		
		self.tableView.scrollEnabled = NO;
		[viewObjects showAlbumLoadingScreen:self.view sender:self];
	} 
	else 
	{
		// Inform the user that the connection failed.
		CustomUIAlertView *alert = [[CustomUIAlertView alloc] initWithTitle:@"Error" message:@"There was an error grabbing the playlist.\n\nCould not create the network request." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:NO];
		[alert release];
	}
}	

- (void)cancelLoad
{
	[connection cancel];
	self.tableView.scrollEnabled = YES;
	[viewObjects hideLoadingScreen];
	[self dataSourceDidFinishLoadingNewData];
}

- (void)viewWillAppear:(BOOL)animated 
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
	
	if (viewObjects.isLocalPlaylist)
	{
		//appDelegate.listOfPlaylistSongs = [NSKeyedUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"%@%@List", appDelegate.defaultUrl, appDelegate.localPlaylist]]];
		//appDelegate.dictOfPlaylistSongs = [NSKeyedUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"%@%@Dict", appDelegate.defaultUrl, appDelegate.localPlaylist]]];
	}
	else
	{
		if (playlistCount == 0)
		{
			[self loadData];
		}
	}
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


- (void) settingsAction:(id)sender 
{
	ServerListViewController *serverListViewController = [[ServerListViewController alloc] initWithNibName:@"ServerListViewController" bundle:nil];
	serverListViewController.hidesBottomBarWhenPushed = YES;
	[self.navigationController pushViewController:serverListViewController animated:YES];
	[serverListViewController release];
}


- (IBAction)nowPlayingAction:(id)sender
{
	musicControls.isNewSong = NO;
	iPhoneStreamingPlayerViewController *streamingPlayerViewController = [[iPhoneStreamingPlayerViewController alloc] initWithNibName:@"iPhoneStreamingPlayerViewController" bundle:nil];
	streamingPlayerViewController.hidesBottomBarWhenPushed = YES;
	[self.navigationController pushViewController:streamingPlayerViewController animated:YES];
	[streamingPlayerViewController release];  
}

#pragma mark Connection Delegate

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)space 
{
	if([[space authenticationMethod] isEqualToString:NSURLAuthenticationMethodServerTrust]) 
		return YES; // Self-signed cert will be accepted
	
	return NO;
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{	
	if([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust])
	{
		[challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge]; 
	}
	[challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	[receivedData setLength:0];
}

- (void)connection:(NSURLConnection *)theConnection didReceiveData:(NSData *)incrementalData 
{
    [receivedData appendData:incrementalData];
}

- (void)connection:(NSURLConnection *)theConnection didFailWithError:(NSError *)error
{
	// Inform the user that the connection failed.
	NSString *message = [NSString stringWithFormat:@"There was an error loading the playlist.\n\nError %i: %@", [error code], [error localizedDescription]];
	CustomUIAlertView *alert = [[CustomUIAlertView alloc] initWithTitle:@"Error" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[alert performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:NO];
	[alert release];
	
	self.tableView.scrollEnabled = YES;
	[viewObjects hideLoadingScreen];
	
	[theConnection release];
	[receivedData release];
	
	[self dataSourceDidFinishLoadingNewData];
}	

- (void)connectionDidFinishLoading:(NSURLConnection *)theConnection 
{	
	NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithData:receivedData];
	PlaylistsXMLParser *parser = [[PlaylistsXMLParser alloc] initXMLParser];
	[xmlParser setDelegate:parser];
	[xmlParser parse];
	[xmlParser release];
	[parser release];
	
	self.tableView.scrollEnabled = YES;
	[viewObjects hideLoadingScreen];
	
	[theConnection release];
	[receivedData release];

	//playlistCount = [databaseControls.serverPlaylistsDb intForQuery:[NSString stringWithFormat:@"SELECT COUNT(*) FROM playlist%@", md5]];
	playlistCount = [databaseControls.localPlaylistsDb intForQuery:[NSString stringWithFormat:@"SELECT COUNT(*) FROM splaylist%@", md5]];
	[self.tableView reloadData];
	
	[self dataSourceDidFinishLoadingNewData];
}


#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	if (viewObjects.isLocalPlaylist)
	{
		return [databaseControls.localPlaylistsDb intForQuery:[NSString stringWithFormat:@"SELECT COUNT(*) FROM playlist%@", self.md5]];
	}
	else
	{
		return playlistCount;
		//return [viewObjects.listOfPlaylistSongs count];
	}
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
	PlaylistSongUITableViewCell *cell = [[[PlaylistSongUITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
	cell.indexPath = indexPath;
	
	// Set up the cell...
	Song *aSong;
	if (viewObjects.isLocalPlaylist)
	{
		aSong = [databaseControls songFromDbRow:indexPath.row inTable:[NSString stringWithFormat:@"playlist%@", self.md5] inDatabase:databaseControls.localPlaylistsDb];
		//NSLog(@"aSong: %@", aSong);
	}
	else
	{
		//aSong = [viewObjects.listOfPlaylistSongs objectAtIndex:indexPath.row];
		aSong = [databaseControls songFromServerPlaylistId:md5 row:indexPath.row];
	}
	
	if (aSong.coverArtId)
	{
		if (aSong.coverArtId)
		{
			if ([databaseControls.coverArtCacheDb60 intForQuery:@"SELECT COUNT(*) FROM coverArtCache WHERE id = ?", [NSString md5:aSong.coverArtId]] == 1)
			{
				// If the image is already in the cache database, load it
				cell.coverArtView.image = [UIImage imageWithData:[databaseControls.coverArtCacheDb60 dataForQuery:@"SELECT data FROM coverArtCache WHERE id = ?", [NSString md5:aSong.coverArtId]]];
			}
			else 
			{			
				// If not, grab it from the url and cache it
				NSString *imgUrlString;
				if (appDelegate.isHighRez)
				{
					imgUrlString = [NSString stringWithFormat:@"%@%@&size=120", [appDelegate getBaseUrl:@"getCoverArt.view"], aSong.coverArtId];
				}
				else
				{
					imgUrlString = [NSString stringWithFormat:@"%@%@&size=60", [appDelegate getBaseUrl:@"getCoverArt.view"], aSong.coverArtId];
				}
				[cell.coverArtView loadImageFromURLString:imgUrlString coverArtId:aSong.coverArtId];
			}
		}
		else
		{
			cell.coverArtView.image = [UIImage imageNamed:@"default-album-art-small.png"];
		}
	}
	else
	{
		cell.coverArtView.image = [UIImage imageNamed:@"default-album-art-small.png"];
	}
	
	cell.backgroundView = [[[UIView alloc] init] autorelease];
	if(indexPath.row % 2 == 0)
	{
		if ([databaseControls.songCacheDb stringForQuery:@"SELECT md5 FROM cachedSongs WHERE md5 = ? and finished = 'YES'", [NSString md5:aSong.path]] != nil)
			cell.backgroundView.backgroundColor = [viewObjects currentLightColor];
		else
			cell.backgroundView.backgroundColor = viewObjects.lightNormal;
	}
	else
	{
		if ([databaseControls.songCacheDb stringForQuery:@"SELECT md5 FROM cachedSongs WHERE md5 = ? and finished = 'YES'", [NSString md5:aSong.path]] != nil)
			cell.backgroundView.backgroundColor = [viewObjects currentDarkColor];
		else
			cell.backgroundView.backgroundColor = viewObjects.darkNormal;
	}
	
	[cell.numberLabel setText:[NSString stringWithFormat:@"%i", (indexPath.row + 1)]];
	[cell.songNameLabel setText:aSong.title];
	if (aSong.album)
		[cell.artistNameLabel setText:[NSString stringWithFormat:@"%@ - %@", aSong.artist, aSong.album]];
	else
		[cell.artistNameLabel setText:aSong.artist];
	
	return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
	if (viewObjects.isCellEnabled)
	{
		[musicControls destroyStreamer];
		
		/*if (viewObjects.isLocalPlaylist)
		{
			musicControls.currentSongObject = nil; musicControls.currentSongObject = [databaseControls songFromDbRow:indexPath.row inTable:[NSString stringWithFormat:@"playlist%@", self.md5] inDatabase:databaseControls.localPlaylistsDb];
			musicControls.nextSongObject = nil; musicControls.nextSongObject = [databaseControls songFromDbRow:(indexPath.row + 1) inTable:[NSString stringWithFormat:@"playlist%@", self.md5] inDatabase:databaseControls.localPlaylistsDb];
		}
		else
		{
			musicControls.currentSongObject = nil; musicControls.currentSongObject = [viewObjects.listOfPlaylistSongs objectAtIndex:indexPath.row];
			musicControls.nextSongObject = nil; musicControls.nextSongObject = [viewObjects.listOfPlaylistSongs objectAtIndex:(indexPath.row + 1)];
		}*/
		
		[databaseControls resetCurrentPlaylistDb];
		
		if (viewObjects.isLocalPlaylist)
		{			
			[databaseControls.localPlaylistsDb executeUpdate:@"ATTACH DATABASE ? AS ?", [NSString stringWithFormat:@"%@/%@currentPlaylist.db", databaseControls.databaseFolderPath, [NSString md5:appDelegate.defaultUrl]], @"currentPlaylistDb"];
			if ([databaseControls.localPlaylistsDb hadError]) { NSLog(@"Err attaching the localPlaylistsDb %d: %@", [databaseControls.localPlaylistsDb lastErrorCode], [databaseControls.localPlaylistsDb lastErrorMessage]); }
			[databaseControls.localPlaylistsDb executeUpdate:[NSString stringWithFormat:@"INSERT INTO currentPlaylist SELECT * FROM playlist%@", self.md5]];
			[databaseControls.localPlaylistsDb executeUpdate:@"DETACH DATABASE currentPlaylistDb"];
		}
		else
		{
			/*for (Song *aSong in viewObjects.listOfPlaylistSongs)
			{
				[databaseControls.currentPlaylistDb executeUpdate:@"INSERT INTO currentPlaylist (title, songId, artist, album, genre, coverArtId, path, suffix, transcodedSuffix, duration, bitRate, track, year, size) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", aSong.title, aSong.songId, aSong.artist, aSong.album, aSong.genre, aSong.coverArtId, aSong.path, aSong.suffix, aSong.transcodedSuffix, aSong.duration, aSong.bitRate, aSong.track, aSong.year, aSong.size];
			}*/
			
			/*NSLog(@"ATTACH DATABASE \"%@\" AS serverPlaylistsDb", [NSString stringWithFormat:@"%@/%@serverPlaylists.db", databaseControls.databaseFolderPath, [NSString md5:appDelegate.defaultUrl]]);
			[databaseControls.localPlaylistsDb executeUpdate:@"ATTACH DATABASE ? AS ?", [NSString stringWithFormat:@"%@/%@serverPlaylists.db", databaseControls.databaseFolderPath, [NSString md5:appDelegate.defaultUrl]], @"serverPlaylistsDb"];
			if ([databaseControls.localPlaylistsDb hadError]) { NSLog(@"Err attaching the serverPlaylistsDb %d: %@", [databaseControls.localPlaylistsDb lastErrorCode], [databaseControls.localPlaylistsDb lastErrorMessage]); }
			NSLog(@"count: %i", [databaseControls.localPlaylistsDb intForQuery:[NSString stringWithFormat:@"SELECT COUNT(*) FROM playlist%@", self.md5]]);
			
			[databaseControls.localPlaylistsDb executeUpdate:[NSString stringWithFormat:@"INSERT INTO currentPlaylist SELECT * FROM playlist%@", self.md5]];
			NSLog(@"%@", [NSString stringWithFormat:@"INSERT INTO currentPlaylist SELECT * FROM playlist%@", self.md5]);
			[databaseControls.localPlaylistsDb executeUpdate:@"DETACH DATABASE serverPlaylistsDb"];*/
			
			[databaseControls.localPlaylistsDb executeUpdate:@"ATTACH DATABASE ? AS ?", [NSString stringWithFormat:@"%@/%@currentPlaylist.db", databaseControls.databaseFolderPath, [NSString md5:appDelegate.defaultUrl]], @"currentPlaylistDb"];
			if ([databaseControls.localPlaylistsDb hadError]) { NSLog(@"Err attaching the localPlaylistsDb %d: %@", [databaseControls.localPlaylistsDb lastErrorCode], [databaseControls.localPlaylistsDb lastErrorMessage]); }
			[databaseControls.localPlaylistsDb executeUpdate:[NSString stringWithFormat:@"INSERT INTO currentPlaylist SELECT * FROM splaylist%@", self.md5]];
			[databaseControls.localPlaylistsDb executeUpdate:@"DETACH DATABASE currentPlaylistDb"];
		}
		
		musicControls.currentPlaylistPosition = indexPath.row;
	
		musicControls.isNewSong = YES;
		musicControls.isShuffle = NO;
		
		musicControls.seekTime = 0.0;
		[musicControls playSongAtPosition:musicControls.currentPlaylistPosition];
		
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
	else
	{
		[self.tableView deselectRowAtIndexPath:indexPath animated:NO];
	}
}


- (void)dealloc {
    [super dealloc];
}


#pragma mark -
#pragma mark Pull to refresh methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{	
	if (scrollView.isDragging && !viewObjects.isLocalPlaylist) 
	{
		if (refreshHeaderView.state == EGOOPullRefreshPulling && scrollView.contentOffset.y > -65.0f && scrollView.contentOffset.y < 0.0f && !_reloading) 
		{
			[refreshHeaderView setState:EGOOPullRefreshNormal];
		} 
		else if (refreshHeaderView.state == EGOOPullRefreshNormal && scrollView.contentOffset.y < -65.0f && !_reloading) 
		{
			[refreshHeaderView setState:EGOOPullRefreshPulling];
		}
	}
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
	
	if (scrollView.contentOffset.y <= - 65.0f && !_reloading && !viewObjects.isLocalPlaylist) 
	{
		_reloading = YES;
		//[self reloadAction:nil];
		[self loadData];
		[refreshHeaderView setState:EGOOPullRefreshLoading];
		[UIView beginAnimations:nil context:NULL];
		[UIView setAnimationDuration:0.2];
		self.tableView.contentInset = UIEdgeInsetsMake(60.0f, 0.0f, 0.0f, 0.0f);
		[UIView commitAnimations];
	}
}

- (void)dataSourceDidFinishLoadingNewData
{
	_reloading = NO;
	
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:.3];
	[self.tableView setContentInset:UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f)];
	[UIView commitAnimations];
	
	[refreshHeaderView setState:EGOOPullRefreshNormal];
}



@end
