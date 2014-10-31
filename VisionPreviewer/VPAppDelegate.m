//
//  AppDelegate.m
//  VisionPreviewer
//
//  Created by Anton Legoo on 9/26/14.
//  Copyright (c) 2014 Anton Legoo. All rights reserved.
//


// TODO: Create app icon

// TODO: Add prompt to "drag and drop" on IKImageView



// TODO: Handle "recently opened" in menu
// TODO: Handle opening and drag-n-drop the same way Preview does: only d-n-d to app icon, opens new window

// TODO: Image Mode dropdown in menu doesn't populate until user clicks. Is problematic in keeping sync with Vision menu selection

// TODO: Add VisualDefect as git submodule?
// TODO: Add "Next / Previous Vision Type" to Vision Menu, with key shortcuts

// TODO: All Error handling, presenting it to the user where helpful

// BUG: Unable to show IKSaveOptions in NSSavePanel as accessoryView. Appears to be framework bug. Same bug happens in Apple's IKImageViewDemo

#import "VPAppDelegate.h"
#import "VisionDefectSimulation.h"

#define ZOOM_IN_FACTOR  1.414214
#define ZOOM_OUT_FACTOR 0.7071068

@interface VPAppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation VPAppDelegate
{
    NSDictionary *_imageProperties;
    NSString * _imageUTType;
    IKSaveOptions *_saveOptions;
    NSURL * _currentImageURL;
    
    VisionDefectType _currentVisionDefectType;
    VisionDefectType _defaultVisionDefectType;
}

@synthesize toolBar;
@synthesize toolBarItemOpen;
@synthesize toolBarItemExport;
@synthesize toolBarItemZoomIn;
@synthesize toolBarItemZoomOut;
@synthesize imageView;
@synthesize visionModePopup;
@synthesize scrollView;
@synthesize visionMenu;

static const NSOrderedSet * filters;

#pragma mark - NSApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Init supported filters
    filters = [NSOrderedSet orderedSetWithArray:@[
                                                  @(VisionDefectNone),
                                                  @(VisionDefectDeuteranopia),
                                                  @(VisionDefectProtanopia),
                                                  @(VisionDefectTritanopia)
                                                  ]];
    
    // Set the default VFType
    _defaultVisionDefectType = VisionDefectNone;
    
    // Set the current VFType to the default
    _currentVisionDefectType = _defaultVisionDefectType;
    
    // Register as ScrollViewWorkAround's delegate
    scrollView.delegate = self;
}

- (void) application:(NSApplication *)sender openFiles:(NSArray *)filenames
{
    // Called when file is dragged onto dock icon.
    // For now, we are only handling one file. So open the first file!
    
    // If there are any files in the array
    if( filenames.count > 0 )
    {
        // Get the first file name and load it
        NSString * firstFilename = (NSString *)filenames[0];
        [self loadFileAtURL:[NSURL fileURLWithPath:firstFilename]];
    }
    
}

- (BOOL) application:(NSApplication *)sender openFile:(NSString *)filename
{
    // Called when file is dragged onto dock icon. Open the file!
    [self loadFileAtURL:[NSURL fileURLWithPath:filename]];
    
    //
    return YES;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
    // Insert code here to tear down your application
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed: (NSApplication *)sender
{
    // terminate when last window was closed
    return YES;
}

#pragma mark - NSObject

- (void) awakeFromNib
{
    // customize the IKImageView...
    [imageView setDoubleClickOpensImageEditPanel: YES];
    [imageView setCurrentToolMode: IKToolModeMove];
    [imageView zoomImageToActualSize: self];
    [imageView setDelegate: self];
    imageView.editable = YES;
    imageView.autoresizes = NO;
    imageView.autohidesScrollers = NO;
    imageView.hasHorizontalScroller = YES;
    imageView.hasVerticalScroller = YES;
    
    
    // Ref the main bundle so we can start loading images
    NSBundle * mb = [NSBundle mainBundle];
    
    // Set the image for Open Toolbar icon
    NSURL * toolBarItemOpenImage = [mb URLForResource:@"open-icon"
                                        withExtension:@"png"
                                         subdirectory:@"Resources/images/toolbar"
                                         localization:nil];
    [toolBarItemOpen setImage:[[NSImage alloc] initByReferencingURL:toolBarItemOpenImage]];
    
    // Set the image for Open Toolbar icon
    NSURL * toolBarItemExportImage = [mb URLForResource:@"export-icon"
                                          withExtension:@"png"
                                           subdirectory:@"Resources/images/toolbar"
                                           localization:nil];
    [toolBarItemExport setImage:[[NSImage alloc] initByReferencingURL:toolBarItemExportImage]];
    
    // Set the image for ZoomIn Toolbar icon
    NSURL * toolBarItemZoomInImage = [mb URLForResource:@"zoomin-icon"
                                          withExtension:@"png"
                                           subdirectory:@"Resources/images/toolbar"
                                           localization:nil];
    [toolBarItemZoomIn setImage:[[NSImage alloc] initByReferencingURL:toolBarItemZoomInImage]];
    
    // Set the image for ZoomIn Toolbar icon
    NSURL * toolBarItemZoomOutImage = [mb URLForResource:@"zoomout-icon"
                                          withExtension:@"png"
                                           subdirectory:@"Resources/images/toolbar"
                                           localization:nil];
    [toolBarItemZoomOut setImage:[[NSImage alloc] initByReferencingURL:toolBarItemZoomOutImage]];
    
    // Open test image
    NSURL * testImageURL = [mb URLForResource:@"test-image" withExtension:@"png" subdirectory:@"Resources/images/" localization:nil];
    [self loadFileAtURL:testImageURL];
    
    // Correct scrollview
    [[imageView enclosingScrollView] reflectScrolledClipView: [[imageView enclosingScrollView] contentView]];
    
}

#pragma mark - Open

- (void) presentOpenDialog
{
    // Create the open panel
    NSOpenPanel * openPanel = [NSOpenPanel openPanel];
    
    // Config the panel
    // Only allow types supported by NSImage
    NSArray * imageTypes = [NSImage imageTypes];
    [openPanel setAllowedFileTypes:imageTypes];
    
    
    // Present open sheet
    [openPanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result)
    {
        // If user hit OK
        if( result == NSFileHandlingPanelOKButton )
        {
            // If there was a file selected
            if( openPanel.URLs.count > 0 )
            {
                // Get the url and load it
                NSURL * url = [openPanel.URLs objectAtIndex:0];
                [self loadFileAtURL: url];
                
            }
        }
    }];
}

#pragma mark - Loading

- (void) loadFileAtURL:(NSURL *)_url
{
    // Get the image, it's properties and file type
    CGImageRef image = NULL;
    CGImageSourceRef imageRef = CGImageSourceCreateWithURL( (CFURLRef)_url, NULL);
    
    // If it exists...
    if( imageRef != NULL )
    {
        // Create image at index ( index=URL? )
        image = CGImageSourceCreateImageAtIndex( imageRef, 0, NULL );
        
        // If that worked...
        if( image != NULL )
        {
            // assign image props
            _imageProperties = (NSDictionary *)CFBridgingRelease(CGImageSourceCopyPropertiesAtIndex(imageRef, 0, (CFDictionaryRef)_imageProperties));
            
            // assign image type
            _imageUTType = (NSString *)CGImageSourceGetType(imageRef);
        }
    }
    
    // Set the image if it exists
    if( image != NULL )
    {
        // Load the image into the imageView
        [imageView setImage:image imageProperties:_imageProperties];
        
        // Zoom the image to fit the window
        [self zoomToFit];
        
        // Set Window title as file name
        [_window setTitleWithRepresentedFilename:_url.path];
        
        // Assign as the current image url
        _currentImageURL = _url;
        
        // Set the filter of the imageView
        [self setDisplayedVisionDefectType:_currentVisionDefectType];
    }
    else
    {
        // Handle error
    }
}

#pragma mark - Zooming

- (void) zoomIn
{
    // Zoom in the image
    [imageView setZoomFactor: ZOOM_IN_FACTOR * imageView.zoomFactor];
}

- (void) zoomOut
{
    // Zoom in the image
    [imageView setZoomFactor: ZOOM_OUT_FACTOR * imageView.zoomFactor];
}

- (void) zoomToActualSize
{
    // Zoom to the actual size of the image
    [imageView zoomImageToActualSize:self];
}

- (void) zoomToFit
{
    // Zoom to fit within the window
    [imageView zoomImageToFit:self];
}

#pragma mark - Filtering

- (void) setDisplayedVisionDefectType:(VisionDefectType) _visionDefectType
{
    // Keep track of the currently selected visionDefectType
    _currentVisionDefectType = _visionDefectType;
    
    // Get the filter
    CIFilter * filter = [VisionDefectSimulation filterForVisionDefect:_visionDefectType withBackingScaleFactor:[[self window] backingScaleFactor]];
    
    // Set the filter on the imageView's CALayer
    // Note:    This does not filter the actual CGImageRef in the imageView. It filters the imageView's CALayer.
    //          However, during export, the filter is applied directly to a copy of the imageView's image (CGImageRef)
    //          and thats what gets saved. See where [saveImageToFileAtURL:] uses [filteredImageWithFilter:fromSourceImage:];
    [imageView.layer setFilters:@[filter]];
    
    // Update the selection of the ImageMode popup menu in the toolbar
    [visionModePopup selectItemWithTag: (NSInteger)_visionDefectType];
    
    // Update the selection in the App's "Vision" Menu ( adds a checkmark the corresonding item )
    // First cycle thru all items...
    for( NSMenuItem * item in visionMenu.itemArray )
    {
        // ...and their state to off
        if( item.state == NSOnState ) [item setState:NSOffState];
    }
    // Then get the current one and select it
    NSMenuItem * currentItem = [visionMenu itemWithTag:(NSInteger)_visionDefectType];
    [currentItem setState: NSOnState];
    
}

-(CGImageRef) filteredImageWithFilter:(CIFilter *) _filter fromSourceImage:(CGImageRef) _sourceImage
{
    // Convert source image to a CIImage
    CIImage * inputImage = [[CIImage alloc] initWithCGImage:_sourceImage];
    
    // Set the image to filter
    [_filter setValue:inputImage forKey:@"inputImage"];
    
    // Get the filterd image
    CIImage * outputImage = [_filter valueForKey:@"outputImage"];
    
    
    // Convert CIImage to CGImageRef
    CIContext * context = [CIContext
                           contextWithCGContext:[[NSGraphicsContext currentContext] graphicsPort]
                           options:[NSDictionary dictionaryWithObject:
                                    [NSNumber numberWithBool:YES] 	forKey:kCIContextUseSoftwareRenderer]
                           ];
    
    CGImageRef filteredImage = [context createCGImage:outputImage fromRect:[outputImage extent]];
    

    //
    return filteredImage;
}

#pragma mark - Save

- (void) presentSaveDialog
{
    // Open the save dialog
    NSSavePanel * savePanel = [NSSavePanel savePanel];
    
    
    // Set the default name
    NSString * filename;
    NSString * currentFilename = [_currentImageURL.lastPathComponent stringByDeletingPathExtension];
    
    if( _currentVisionDefectType == VisionDefectNone )
    {
        // Go with the current file name
        filename = [NSString stringWithFormat:@"%@.%@", currentFilename, @"png"];
    }
    else
    {
        // Update the file name to include the vision defect type
        
        // Get the defect name from substring of VisionDefectType's name
        NSString * defectString = [VisionDefectSimulation nameForVisionDefect:_currentVisionDefectType];
            NSInteger index = ( (NSRange)[defectString rangeOfString:@" "] ).location;
            defectString = [defectString substringToIndex:index];
        
        // Piece together filename
        filename = [NSString stringWithFormat:@"%@_%@.%@", currentFilename, defectString, @"png" ];
    }
    
    // Update filename of save panel
    [savePanel setNameFieldStringValue:filename];
    
    // Update the saveOptions
    _saveOptions = [[IKSaveOptions alloc] initWithImageProperties:_imageProperties imageUTType:_imageUTType];
    
/*  BUG: Attaching accessory view to Save Panel in Yosemite causes auto-layout error.. waiting for fix or workaround?
    // Present IKImageView save options as accessory view of save panel
    [_saveOptions addSaveOptionsAccessoryViewToSavePanel:savePanel];
*/
    
    // Present save sheet
    [savePanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result)
    {
        if( result == NSFileHandlingPanelOKButton )
        {
            // Save the image at the URL returned from save dialog
            [self saveImageToFileAtURL:[savePanel URL]];
        }
    }];
    
    
}

- (void) saveImageToFileAtURL:(NSURL *)_url
{
    // Get the file type (UTType) from the save options
    NSString * type = [_saveOptions imageUTType];
    
    // Get the CIFilter for the current VDType
    CIFilter * filter = [VisionDefectSimulation filterForVisionDefect:_currentVisionDefectType withBackingScaleFactor:[[self window] backingScaleFactor]];

    // Get the filtered image of the iamgeView's current image
    // Note: filters do not apply to image, they are only applied to imageView's CALayer
    CGImageRef filteredImage = [self filteredImageWithFilter:filter fromSourceImage:imageView.image];
    
    
    // if it exists
    if( filteredImage != NULL )
    {
        // use image IO to save the image in the specified format ( UTType )
        
        // Create destination
        CGImageDestinationRef destination = CGImageDestinationCreateWithURL( (CFURLRef)_url, (CFStringRef)type, 1, NULL);
        
        // if the dest exists
        if( destination != NULL )
        {
            // Add the image to the destination
            CGImageDestinationAddImage( destination, filteredImage, (CFDictionaryRef)[_saveOptions imageProperties]);
            
            // Write the image and check for valid write
            if( !CGImageDestinationFinalize( destination ) )
            {
                // Destination not finalized, image write failed
                NSLog(@"Failed to write image to %@", _url.path );
            }
            
            // Release desitnation ref
            CFRelease( destination );
        }
        else
        {
            // dest doesn't exist and/or is null
            NSLog(@"Failed to create destination for %@", _url.path );
        }
        
    }
    
}


#pragma mark - Toolbar Actions

- (IBAction)onToolbarOpen:(id)sender
{
    [self presentOpenDialog];
}

- (IBAction)onToolbarExport:(id)sender
{
    [self presentSaveDialog];
}

- (IBAction)onZoomIn:(id)sender
{
    [self zoomIn];
}

- (IBAction)onZoomOut:(id)sender
{
    [self zoomOut];
}

- (IBAction)onZoomActualSize:(id)sender
{
    [self zoomToActualSize];
}

- (IBAction)onZoomFit:(id)sender
{
    [self zoomToFit];
}

- (IBAction)onToolbarImageMode:(id)sender
{
    // Return if this isnt the menu
    if( [sender isMemberOfClass:[NSPopUpButton class]] == NO  ) return;
    
    // Get the selected item from the popup menu
    NSMenuItem * item = [visionModePopup.menu itemAtIndex:visionModePopup.indexOfSelectedItem];
    
    // Get the tag, which is assigned the corresponding VDType enumIndex
    NSInteger enumIndex = item.tag;
    
    // Filter the imageView with the VDType
    [self setDisplayedVisionDefectType:(VisionDefectType)enumIndex];
}

- (IBAction)onVisionMenuItemSelect:(id)sender
{
    // Return if this isnt a menu item
    if( [sender isMemberOfClass:[NSMenuItem class]] == NO  ) return;
    
    NSMenuItem * item = ( NSMenuItem * )sender;
    
    // Get the tag, which is assigned the corresponding VDType enumIndex
    NSInteger enumIndex = item.tag;
    
    // Filter the imageView with the VDType
    [self setDisplayedVisionDefectType:(VisionDefectType)enumIndex];
}

#pragma mark - NSMenuDelegate

- (NSInteger) numberOfItemsInMenu:(NSMenu *)menu
{
    // if coming from Toolbar popupmenu for filters
    // or if coming from the "Vision" menu in statusbar, also for filters
    if( menu == visionModePopup.menu || menu == visionMenu )
    {
        // Return the number of filters in Filters orderedSet
        return filters.count;
    }
    
    //
    return 0;
}

- (BOOL) menu:(NSMenu *)menu updateItem:(NSMenuItem *)item atIndex:(NSInteger)index shouldCancel:(BOOL)shouldCancel
{

    // if coming from Toolbar popupmenu for filters
    // or if coming from the "Vision" menu in statusbar, also for filters
    if( menu == visionModePopup.menu || menu == visionMenu )
    {
        // Get defectType struct for index
        NSInteger enumIndex = ((NSNumber *)[filters objectAtIndex:index]).integerValue;
        VisionDefectType s = (VisionDefectType) enumIndex;
        
        // Give the item a title
        item.title = [VisionDefectSimulation nameForVisionDefect:s];
        
        // Store the VDType enumIndex in the tag for retrieval after selection
        item.tag = enumIndex;
        
        // Assign its key shortcut
        [item setKeyEquivalent:[NSString stringWithFormat:@"%ld", index+1]];
        [item setKeyEquivalentModifierMask:NSCommandKeyMask|NSAlternateKeyMask];
        
        // Set on state for item if current VDType, all else off state
        item.state = ( _currentVisionDefectType == enumIndex ) ? NSOnState : NSOffState;
        
        // Only for the Vision Menu
        if( menu == visionMenu )
        {
            // Set an action for each menu item to respond to user selection
            [item setAction:@selector(onVisionMenuItemSelect:)];
        }
        
        // Continue calling this method
        return YES;
    }
    
    return NO;
}

#pragma mark - ScrollViewWorkAroundDelegate

- (void) draggingDidEndWithFiles:(NSArray *)_files
{
    // Get the first URL ( so far we're only showing one image )
    NSURL *url = (NSURL *)_files[0];
    
    // If it exist...
    if( url != nil )
    {
        // ..load it
        [self loadFileAtURL:url];
    }
}


@end
