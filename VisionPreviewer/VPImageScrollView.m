//
//  VPImageScrollView.m
//  VisionPreviewer
//
//  Created by Anton Legoo on 10/23/14.
//  Copyright (c) 2014 Anton Legoo. All rights reserved.
//

#import "VPImageScrollView.h"

@implementation VPImageScrollView

@synthesize delegate;

#pragma mark - Init

-(void) awakeFromNib
{
//    [self registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, nil]];
}

#pragma mark - Drag and Drop

// Drag and drop is now handled by [application:openFiles] on NSApplicationDelegate

//- (NSDragOperation) draggingEntered:(id<NSDraggingInfo>)sender
//{
//    NSPasteboard *pboard;
//    NSDragOperation sourceDragMask;
//    
//    // Get the operation and pasteboard from the sender
//    sourceDragMask = [sender draggingSourceOperationMask];
//    pboard = [sender draggingPasteboard];
//    
//    // Check to see if the pasteboard type is NSFilenamesPboardType
//    if ( [[pboard types] containsObject:NSFilenamesPboardType] )
//    {
//        // If the source operation is a link
//        if( sourceDragMask & NSDragOperationLink )
//        {
//            // Return the link operation
//            return NSDragOperationLink;
//        }
//        else if ( sourceDragMask & NSDragOperationCopy )
//        {
//            // Return the copy operation
//            return NSDragOperationCopy;
//        }
//    }
//    
//    return NSDragOperationNone;
//}
//
//- (void) draggingEnded:(id<NSDraggingInfo>)sender
//{
//    // Get the pasteboard
//    NSPasteboard *pboard = [sender draggingPasteboard];
//    
//    // Find the NSURL's in the pasteboard
//    NSArray *items = [pboard readObjectsForClasses:@[ [NSURL class] ] options:nil];
//    
//    // If there are any...
//    if( items != nil )
//    {
//        // If we have a delegate...
//        if( delegate != nil )
//        {
//            // ...tell it about the files that were dragged on
//            [delegate draggingDidEndWithFiles:items];
//        }
//    }
//    
//    //    NSLog(@"Items: %@ / count: %ld", items, pboard.pasteboardItems.count );
//}

@end
