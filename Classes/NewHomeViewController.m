//
//  NewHomeViewController.m
//  iSub
//
//  Created by bbaron on 11/6/10.
//  Copyright 2010 Ben Baron. All rights reserved.
//

#import "NewHomeViewController.h"
#import "ServerListViewController.h"
#import "iPhoneStreamingPlayerViewController.h"
#import "SearchXMLParser.h"
#import "iSubAppDelegate.h"
#import "ViewObjectsSingleton.h"
#import "MusicControlsSingleton.h"
#import "DatabaseControlsSingleton.h"
#import "ASIHTTPRequest.h"
#import "QuickAlbumsViewController.h"
#import "ChatViewController.h"
#import "MGSplitViewController.h"
#import "SearchSongsViewController.h"
#import "NSString-rfcEncode.h"
#import "StoreViewController.h"
#import "CustomUIAlertView.h"
#import "AsynchronousImageView.h"
#import "Song.h"
#import "NSString-md5.h"
#import "FMDatabase.h"
#import "FMDatabaseAdditions.h"

@implementation NewHomeViewController

-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)inOrientation 
{
	if ([[[iSubAppDelegate sharedInstance].settingsDictionary objectForKey:@"lockRotationSetting"] isEqualToString:@"YES"] 
		&& inOrientation != UIDeviceOrientationPortrait)
		return NO;
	
    return YES;
}

- (void) willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	[super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
	
	BOOL rotationDisabled = [[[iSubAppDelegate sharedInstance].settingsDictionary objectForKey:@"lockRotationSetting"] isEqualToString:@"YES"];
	
	if (UIDeviceOrientationIsPortrait(toInterfaceOrientation) && !rotationDisabled)
	{
		if (!IS_IPAD())
		{
			// Animate the segmented control off screen
			[UIView beginAnimations:nil context:NULL];
			[UIView setAnimationDuration:.3];
			[UIView setAnimationCurve:UIViewAnimationCurveLinear];
			quickLabel.alpha = 1.0;
			shuffleLabel.alpha = 1.0;
			jukeboxLabel.alpha = 1.0;
			settingsLabel.alpha = 1.0;
			chatLabel.alpha = 1.0;
			playerLabel.alpha = 1.0;
			
			coverArtBorder.alpha = 1.0;
			coverArtView.alpha = 1.0;
			artistLabel.alpha = 1.0;
			albumLabel.alpha = 1.0;
			songLabel.alpha = 1.0;
			[UIView commitAnimations];
		}
	}
	else if (UIDeviceOrientationIsLandscape(toInterfaceOrientation) && !rotationDisabled)
	{
		if (!IS_IPAD())
		{
			// Animate the segmented control off screen
			[UIView beginAnimations:nil context:NULL];
			[UIView setAnimationDuration:.3];
			[UIView setAnimationCurve:UIViewAnimationCurveLinear];
			quickLabel.alpha = 0.0;
			shuffleLabel.alpha = 0.0;
			jukeboxLabel.alpha = 0.0;
			settingsLabel.alpha = 0.0;
			chatLabel.alpha = 0.0;
			playerLabel.alpha = 0.0;
			
			coverArtBorder.alpha = 0.0;
			coverArtView.alpha = 0.0;
			artistLabel.alpha = 0.0;
			albumLabel.alpha = 0.0;
			songLabel.alpha = 0.0;
			[UIView commitAnimations];
		}
	}
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	appDelegate = (iSubAppDelegate*)[UIApplication sharedApplication].delegate;
	viewObjects = [ViewObjectsSingleton sharedInstance];
	musicControls = [MusicControlsSingleton sharedInstance];
	databaseControls = [DatabaseControlsSingleton sharedInstance];
	
	self.title = @"Home";
	//self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"gear.png"] style:UIBarButtonItemStyleBordered target:self action:@selector(settings)] autorelease];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(jukeboxOff) name:@"JukeboxTurnedOff" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(initSongInfo) name:@"initSongInfo" object:nil];

	if (!IS_IPAD())
	{
		coverArtBorder = [[UIView alloc] initWithFrame:CGRectMake(20, 158, 100, 100)];
		coverArtBorder.backgroundColor = [UIColor colorWithWhite:0.7 alpha:1.0];
		
		coverArtView = [[AsynchronousImageView alloc] init];
		coverArtView.frame = CGRectMake(2, 2, 96, 96);
		coverArtView.isForPlayer = YES;
		
		[coverArtBorder addSubview:coverArtView];
		[self.view addSubview:coverArtBorder];
		
		artistLabel = [[UILabel alloc] initWithFrame:CGRectMake(140, 165, 165, 30)];
		artistLabel.backgroundColor = [UIColor clearColor];
		artistLabel.textColor = [UIColor colorWithWhite:0.7 alpha:1.0];
		artistLabel.font = [UIFont boldSystemFontOfSize:24];
		artistLabel.adjustsFontSizeToFitWidth = YES;
		artistLabel.textAlignment = UITextAlignmentCenter;
		[self.view addSubview:artistLabel];
		
		albumLabel = [[UILabel alloc] initWithFrame:CGRectMake(140, 195, 165, 20)];
		albumLabel.backgroundColor = [UIColor clearColor];
		albumLabel.textColor = [UIColor colorWithWhite:0.7 alpha:1.0];
		albumLabel.font = [UIFont systemFontOfSize:24];
		albumLabel.adjustsFontSizeToFitWidth = YES;
		albumLabel.textAlignment = UITextAlignmentCenter;
		[self.view addSubview:albumLabel];
		
		songLabel = [[UILabel alloc] initWithFrame:CGRectMake(140, 215, 165, 30)];
		songLabel.backgroundColor = [UIColor clearColor];
		songLabel.textColor = [UIColor colorWithWhite:0.7 alpha:1.0];
		songLabel.font = [UIFont boldSystemFontOfSize:24];
		songLabel.adjustsFontSizeToFitWidth = YES;
		songLabel.textAlignment = UITextAlignmentCenter;
		[self.view addSubview:songLabel];				
		
		[self initSongInfo];
	}	
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	viewObjects.isSettingsShowing = NO;
	
	/*if (UIDeviceOrientationIsPortrait([UIDevice currentDevice].orientation))
	{
		if (!IS_IPAD())
			[[NSBundle mainBundle] loadNibNamed:@"NewHomeViewController" owner:self options:nil];
	}
	else if (UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation))
	{
		if (!IS_IPAD())
			[[NSBundle mainBundle] loadNibNamed:@"NewHomeViewControllerLandscape" owner:self options:nil];
	}*/
	
	if(musicControls.showPlayerIcon)
	{
		playerButton.enabled = YES;
		playerButton.alpha = 1.0;
		//self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"now-playing.png"] style:UIBarButtonItemStyleBordered target:self action:@selector(player)] autorelease];
	}
	else
	{
		playerButton.enabled = NO;
		playerButton.alpha = 0.5;
		//self.navigationItem.rightBarButtonItem = nil;
	}
	
	if (viewObjects.isJukebox)
	{
		if (IS_IPAD())
			[jukeboxButton setImage:[UIImage imageNamed:@"home-jukebox-on-ipad.png"] forState:UIControlStateNormal];
		else
			[jukeboxButton setImage:[UIImage imageNamed:@"home-jukebox-on.png"] forState:UIControlStateNormal];
	}
	else
	{
		if (IS_IPAD())
			[jukeboxButton setImage:[UIImage imageNamed:@"home-jukebox-off-ipad.png"] forState:UIControlStateNormal];
		else
			[jukeboxButton setImage:[UIImage imageNamed:@"home-jukebox-off.png"] forState:UIControlStateNormal];
	}
	
	searchSegment.alpha = 0.0;
	searchSegment.enabled = NO;
	searchSegmentBackground.alpha = 0.0;
	
	[appDelegate checkAPIVersion];
}

- (void)initSongInfo
{
	if (musicControls.currentSongObject != nil)
	{		
		if([musicControls.currentSongObject coverArtId])
		{		
			FMDatabase *coverArtCache = databaseControls.coverArtCacheDb320;
			
			if ([coverArtCache intForQuery:@"SELECT COUNT(*) FROM coverArtCache WHERE id = ?", [NSString md5:musicControls.currentSongObject.coverArtId]] == 1)
			{
				NSData *imageData = [coverArtCache dataForQuery:@"SELECT data FROM coverArtCache WHERE id = ?", [NSString md5:musicControls.currentSongObject.coverArtId]];
				if (appDelegate.isHighRez)
				{
					UIGraphicsBeginImageContextWithOptions(CGSizeMake(320.0,320.0), NO, 2.0);
					[[UIImage imageWithData:imageData] drawInRect:CGRectMake(0,0,320,320)];
					coverArtView.image = UIGraphicsGetImageFromCurrentImageContext();
					UIGraphicsEndImageContext();
				}
				else
				{
					coverArtView.image = [UIImage imageWithData:imageData];
				}
			}
			else 
			{
				[coverArtView loadImageFromCoverArtId:musicControls.currentSongObject.coverArtId isForPlayer:YES];
			}
		}
		else 
		{
			coverArtView.image = [UIImage imageNamed:@"default-album-art.png"];
		}
		
		artistLabel.text = @"";
		albumLabel.text = @"";
		songLabel.text = @"";
		
		if ([musicControls.currentSongObject artist])
		{
			artistLabel.text = [musicControls.currentSongObject artist];
		}
		
		if ([musicControls.currentSongObject album])
		{
			albumLabel.text = [musicControls.currentSongObject album];
		}
		
		if ([musicControls.currentSongObject title])
		{
			songLabel.text = [musicControls.currentSongObject title];
		}
	}
	else
	{
		coverArtView.image = [UIImage imageNamed:@"default-album-art.png"];
		artistLabel.text = @"Use the Folders tab to find music";
		albumLabel.text = @"";
		songLabel.text = @"";
	}
}

- (IBAction)quickAlbums
{
	QuickAlbumsViewController *quickAlbums = [[QuickAlbumsViewController alloc] init];
	quickAlbums.parent = self;
	//quickAlbums.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
	if ([quickAlbums respondsToSelector:@selector(setModalPresentationStyle:)])
		quickAlbums.modalPresentationStyle = UIModalPresentationFormSheet;
	
	if (IS_IPAD())
		[appDelegate.splitView presentModalViewController:quickAlbums animated:YES];
	else
		[self presentModalViewController:quickAlbums animated:YES];
}

- (void)pushViewController:(UIViewController *)viewController
{
	// Hide the loading screen
	[viewObjects hideLoadingScreen];
	
	// Push the view controller
	[self.navigationController pushViewController:viewController animated:YES];
}

- (IBAction)serverShuffle
{
	isSearch = NO;
	
	// Start the 100 record open search to create shuffle list
	NSString *urlString = [NSString stringWithFormat:@"%@&size=100", [appDelegate getBaseUrl:@"getRandomSongs.view"]];
	NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString] cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:kLoadingTimeout];
	NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
	if (connection)
	{
		// Create the NSMutableData to hold the received data.
		// receivedData is an instance variable declared elsewhere.
		receivedData = [[NSMutableData data] retain];
		
		// Display the loading screen
		[viewObjects showLoadingScreenOnMainWindow];
	} 
	else 
	{
		// Inform the user that the connection failed.
		CustomUIAlertView *alert = [[CustomUIAlertView alloc] initWithTitle:@"Error" message:@"There was an error creating the server shuffle list.\n\nThe connection could not be created" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:NO];
		[alert release];
	}
}

- (IBAction)chat
{
	ChatViewController *chat = [[ChatViewController alloc] initWithNibName:@"ChatViewController" bundle:nil];
	//playlists.isHomeTab = YES;
	[self.navigationController pushViewController:chat animated:YES];
	[chat release];
}

- (IBAction)settings
{
	ServerListViewController *serverListViewController = [[ServerListViewController alloc] initWithNibName:@"ServerListViewController" bundle:nil];
	serverListViewController.hidesBottomBarWhenPushed = YES;
	[self.navigationController pushViewController:serverListViewController animated:YES];
	[serverListViewController release];
}

- (IBAction)player
{
	musicControls.isNewSong = NO;
	iPhoneStreamingPlayerViewController *streamingPlayerViewController = [[iPhoneStreamingPlayerViewController alloc] initWithNibName:@"iPhoneStreamingPlayerViewController" bundle:nil];
	streamingPlayerViewController.hidesBottomBarWhenPushed = YES;
	[self.navigationController pushViewController:streamingPlayerViewController animated:YES];
	[streamingPlayerViewController release];
}

- (void)jukeboxOff
{
	if (IS_IPAD())
		[jukeboxButton setImage:[UIImage imageNamed:@"home-jukebox-off-ipad.png"] forState:UIControlStateNormal];
	else
		[jukeboxButton setImage:[UIImage imageNamed:@"home-jukebox-off.png"] forState:UIControlStateNormal];
}

- (IBAction)jukebox
{
	if (viewObjects.isJukeboxUnlocked)
	{
		if (viewObjects.isJukebox)
		{
			// Jukebox mode is on, turn it off
			if (IS_IPAD())
				[jukeboxButton setImage:[UIImage imageNamed:@"home-jukebox-off-ipad.png"] forState:UIControlStateNormal];
			else
				[jukeboxButton setImage:[UIImage imageNamed:@"home-jukebox-off.png"] forState:UIControlStateNormal];
			viewObjects.isJukebox = NO;
			
			musicControls.currentSongObject = nil;
			
			appDelegate.window.backgroundColor = viewObjects.windowColor;
		}
		else
		{
			[musicControls destroyStreamer];
			
			// Jukebox mode is off, turn it on
			if (IS_IPAD())
				[jukeboxButton setImage:[UIImage imageNamed:@"home-jukebox-on-ipad.png"] forState:UIControlStateNormal];
			else
				[jukeboxButton setImage:[UIImage imageNamed:@"home-jukebox-on.png"] forState:UIControlStateNormal];
			viewObjects.isJukebox = YES;
			
			[musicControls jukeboxGetInfo];
			
			appDelegate.window.backgroundColor = viewObjects.jukeboxColor;
		}	
	}
	else
	{
		StoreViewController *store = [[StoreViewController alloc] init];
		[self.navigationController pushViewController:store animated:YES];
		[store release];
	}
}


- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
	
	[coverArtBorder release];
	[coverArtView release];
	[artistLabel release];
	[albumLabel release];
	[songLabel release];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"JukeboxTurnedOff" object:nil];
}


- (void)dealloc {
    [super dealloc];
}

#pragma mark -
#pragma mark Search Bar Delgate

- (void)searchBarTextDidBeginEditing:(UISearchBar *)theSearchBar
{	
	// Create search overlay
	searchOverlay = [[UIView alloc] init];
	if (viewObjects.isNewSearchAPI)
	{
		if (IS_IPAD())
			searchOverlay.frame = CGRectMake(0, 86, 1024, 1024);
		else
			searchOverlay.frame = CGRectMake(0, 82, 480, 480);
	}
	else
	{
		if (IS_IPAD())
			searchOverlay.frame = CGRectMake(0, 44, 1024, 1024);
		else
			searchOverlay.frame = CGRectMake(0, 44, 480, 480);
	}
	
	searchOverlay.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	searchOverlay.backgroundColor = [UIColor colorWithWhite:0 alpha:.80];
	searchOverlay.alpha = 0.0;
	[self.view addSubview:searchOverlay];
	[searchOverlay release];
		
	dismissButton = [UIButton buttonWithType:UIButtonTypeCustom];
	dismissButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	[dismissButton addTarget:searchBar action:@selector(resignFirstResponder) forControlEvents:UIControlEventTouchUpInside];
	dismissButton.frame = self.view.bounds;
	dismissButton.enabled = NO;
	[searchOverlay addSubview:dismissButton];
	
	// Animate the segmented control on screen
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:.5];
	[UIView setAnimationCurve:UIViewAnimationCurveLinear];
	if (viewObjects.isNewSearchAPI)
	{
		
		searchSegment.alpha = 1;
		searchSegment.enabled = YES;
		searchSegmentBackground.alpha = 1;
	}
	searchOverlay.alpha = 1;
	dismissButton.enabled = YES;
	[UIView commitAnimations];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)theSearchBar
{
	// Animate the segmented control off screen
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:.3];
	[UIView setAnimationCurve:UIViewAnimationCurveLinear];
	if (viewObjects.isNewSearchAPI)
	{
		searchSegment.alpha = 0;
		searchSegment.enabled = NO;
		searchSegmentBackground.alpha = 0;
	}
	searchOverlay.alpha = 0;
	dismissButton.enabled = NO;
	[UIView commitAnimations];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)theSearchBar
{
	isSearch = YES;
	
	[searchBar resignFirstResponder];
	
	// Perform the search
	NSString *urlString;
	
	if (viewObjects.isNewSearchAPI)
	{
		if (searchSegment.selectedSegmentIndex == 0)
		{
			urlString = [NSString stringWithFormat:@"%@&artistCount=20&albumCount=0&songCount=0&query=%@*", 
						 [appDelegate getBaseUrl:@"search2.view"], [searchBar.text stringByAddingRFC3875PercentEscapesUsingEncoding:NSUTF8StringEncoding]];
		}
		else if (searchSegment.selectedSegmentIndex == 1)
		{
			urlString = [NSString stringWithFormat:@"%@&artistCount=0&albumCount=20&songCount=0&query=%@*", 
						 [appDelegate getBaseUrl:@"search2.view"], [searchBar.text stringByAddingRFC3875PercentEscapesUsingEncoding:NSUTF8StringEncoding]];
		}
		else
		{
			urlString = [NSString stringWithFormat:@"%@&artistCount=0&albumCount=0&songCount=20&query=%@*", 
						 [appDelegate getBaseUrl:@"search2.view"], [searchBar.text stringByAddingRFC3875PercentEscapesUsingEncoding:NSUTF8StringEncoding]];
		}
	}
	else
	{
		urlString = [NSString stringWithFormat:@"%@&count=20&any=%@", 
					 [appDelegate getBaseUrl:@"search.view"], [searchBar.text stringByAddingRFC3875PercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	}
	
	//NSLog(@"search url: %@", urlString);
	
	NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString] cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:kLoadingTimeout];
	NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
	if (connection)
	{
		// Create the NSMutableData to hold the received data.
		// receivedData is an instance variable declared elsewhere.
		receivedData = [[NSMutableData data] retain];
		
		// Display the loading screen
		[viewObjects showLoadingScreenOnMainWindow];
	} 
	else 
	{
		// Inform the user that the connection failed.
		CustomUIAlertView *alert = [[CustomUIAlertView alloc] initWithTitle:@"Error" message:@"There was an error performing the search.\n\nThe connection could not be created" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:NO];
		[alert release];
	}
}

#pragma mark -
#pragma mark Connection delegate

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
	NSString *message;
	if (isSearch)
	{
		message = [NSString stringWithFormat:@"There was an error completing the search.\n\nError:%@", error.localizedDescription];
	}
	else
	{
		message = [NSString stringWithFormat:@"There was an error creating the server shuffle list.\n\nError:%@", error.localizedDescription];
	}
	
	CustomUIAlertView *alert = [[CustomUIAlertView alloc] initWithTitle:@"Error" message:message delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[alert performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:NO];
	[alert release];
	
	[theConnection release];
	[receivedData release];
	
	[viewObjects hideLoadingScreen];
}	

- (void)connectionDidFinishLoading:(NSURLConnection *)theConnection 
{	
	if (isSearch)
	{
		// It's a search
		
		NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithData:receivedData];
		SearchXMLParser *parser = (SearchXMLParser*)[[SearchXMLParser alloc] initXMLParser];
		[xmlParser setDelegate:parser];
		[xmlParser parse];
				
		SearchSongsViewController *searchViewController = [[SearchSongsViewController alloc] initWithNibName:@"SearchSongsViewController" bundle:nil];
		searchViewController.title = @"Search";
		if (viewObjects.isNewSearchAPI)
		{
			if (searchSegment.selectedSegmentIndex == 0)
			{
				searchViewController.listOfArtists = [NSMutableArray arrayWithArray:parser.listOfArtists];
				//NSLog(@"%@", searchViewController.listOfArtists);
			}
			else if (searchSegment.selectedSegmentIndex == 1)
			{
				searchViewController.listOfAlbums = [NSMutableArray arrayWithArray:parser.listOfAlbums];
				//NSLog(@"%@", searchViewController.listOfAlbums);
			}
			else
			{
				searchViewController.listOfSongs = [NSMutableArray arrayWithArray:parser.listOfSongs];
				//NSLog(@"%@", searchViewController.listOfSongs);
			}
			
			searchViewController.searchType = searchSegment.selectedSegmentIndex;
		}
		else
		{
			searchViewController.listOfSongs = [NSMutableArray arrayWithArray:parser.listOfSongs];
			searchViewController.searchType = 2;
		}
		
		if (viewObjects.isNewSearchAPI)
			searchViewController.query = [NSString stringWithFormat:@"%@*", searchBar.text];
		else
			searchViewController.query = searchBar.text;
			
		[xmlParser release];
		[parser release];
		
		[self.navigationController pushViewController:searchViewController animated:YES];
		
		[searchViewController release];
				
		// Hide the loading screen
		[viewObjects hideLoadingScreen];
	}
	else
	{
		// It's generating the 100 random songs list

		NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithData:receivedData];
		SearchXMLParser *parser = (SearchXMLParser*)[[SearchXMLParser alloc] initXMLParser];
		[xmlParser setDelegate:parser];
		[xmlParser parse];
		
		[musicControls destroyStreamer];
		
		musicControls.currentPlaylistPosition = 0;
		[databaseControls resetCurrentPlaylistDb];
		for(Song *aSong in parser.listOfSongs)
		{
			[databaseControls addSongToPlaylistQueue:aSong];
			//[databaseControls insertSong:aSong intoTable:@"currentPlaylist" inDatabase:databaseControls.currentPlaylistDb];
		}
		
		if (viewObjects.isJukebox)
			[musicControls jukeboxReplacePlaylistWithLocal];
		
		//musicControls.currentSongObject = [databaseControls songFromDbRow:0 inTable:@"currentPlaylist" inDatabase:databaseControls.currentPlaylistDb];
		//musicControls.nextSongObject = [databaseControls songFromDbRow:1 inTable:@"currentPlaylist" inDatabase:databaseControls.currentPlaylistDb];
		
		musicControls.isNewSong = YES;
		musicControls.isShuffle = NO;
		musicControls.seekTime = 0.0;
		
		// Hide the loading screen
		[viewObjects hideLoadingScreen];
		
		[musicControls playSongAtPosition:0];
		
		[xmlParser release];
		[parser release];
		
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
	
	[theConnection release];
	[receivedData release];
}


@end