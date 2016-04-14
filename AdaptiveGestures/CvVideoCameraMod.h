//
//  CvVideoCameraMod.h
//  AdaptiveGestures
//
//  Created by Marko Djordjevic on 14/04/2016.
//  Copyright © 2016 Marko Djordjevic. All rights reserved.
//

#ifndef CvVideoCameraMod_h
#define CvVideoCameraMod_h


#endif /* CvVideoCameraMod_h */

#import <opencv2/videoio/cap_ios.h>

@protocol CvVideoCameraDelegateMod <CvVideoCameraDelegate>
@end

@interface CvVideoCameraMod : CvVideoCamera

- (void)updateOrientation;
- (void)layoutPreviewLayer;

@property (nonatomic, retain) CALayer* customPreviewLayer;

@end
