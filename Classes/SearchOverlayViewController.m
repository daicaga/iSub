//
//  SearchOverlayViewController.m
//  iSub
//
//  Created by Ben Baron on 4/1/10.
//  Copyright 2010 Ben Baron. All rights reserved.
//

#import "SearchOverlayViewController.h"
//#import "RootViewController.h"
//#import "AllAlbumsViewController.h"
//#import "AllSongsViewController.h"
//#import "iSubAppDelegate.h"

@implementation SearchOverlayViewController

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event 
{	
	//iSubAppDelegate *appDelegate = (iSubAppDelegate*)[[UIApplication sharedApplication] delegate];
	//[appDelegate.rootViewController doneSearching_Clicked:nil];
	//[(AllAlbumsViewController *) appDelegate.allAlbumsNavigationController.topViewController doneSearching_Clicked:nil];
	//[(AllSongsViewController *) appDelegate.allSongsNavigationController.topViewController doneSearching_Clicked:nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"endSearch" object:self];
}


- (void)didReceiveMemoryWarning 
{
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
}


- (void)dealloc 
{
    [super dealloc];
}


@end