//
//  VPImageScrollView.h
//  VisionPreviewer
//
//  Created by Anton Legoo on 10/23/14.
//  Copyright (c) 2014 Anton Legoo. All rights reserved.
//

#import "ScrollViewWorkaround.h"

@protocol VPImageScrollViewDelegate <NSObject>

- (void) draggingDidEndWithFiles:(NSArray *)_files;

@end

@interface VPImageScrollView : ScrollViewWorkaround

@property (nonatomic, weak) id<VPImageScrollViewDelegate> delegate;

@end
