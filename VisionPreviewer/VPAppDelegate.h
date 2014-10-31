//
//  AppDelegate.h
//  VisionPreviewer
//
//  Created by Anton Legoo on 9/26/14.
//  Copyright (c) 2014 Anton Legoo. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
#import "VPImageScrollView.h"

@import CoreServices;

@interface VPAppDelegate : NSObject <NSApplicationDelegate, NSMenuDelegate, VPImageScrollViewDelegate>

@property (nonatomic, retain) IBOutlet NSToolbar * toolBar;
@property (nonatomic, retain) IBOutlet VPImageScrollView * scrollView;
@property (nonatomic, retain) IBOutlet NSToolbarItem * toolBarItemOpen;
@property (nonatomic, retain) IBOutlet NSToolbarItem * toolBarItemExport;
@property (nonatomic, retain) IBOutlet NSToolbarItem * toolBarItemZoomIn;
@property (nonatomic, retain) IBOutlet NSToolbarItem * toolBarItemZoomOut;
@property (nonatomic, retain) IBOutlet NSPopUpButton * visionModePopup;
@property (nonatomic, retain) IBOutlet IKImageView * imageView;
@property (nonatomic, retain) IBOutlet NSMenu * visionMenu;

@end