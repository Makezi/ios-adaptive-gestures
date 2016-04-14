//
//  MyCvVideoCamera.h
//  AdaptiveGestures
//
//  Created by Marko Djordjevic on 13/04/2016.
//  Copyright © 2016 Marko Djordjevic. All rights reserved.
//

#ifndef MyCvVideoCamera_h
#define MyCvVideoCamera_h


#endif /* MyCvVideoCamera_h */

#import <opencv2/videoio/cap_ios.h>

@interface MyCvVideoCamera : CvVideoCamera

- (void)updateOrientation;
- (void)layoutPreviewLayer;

@property (nonatomic, retain) CALayer* customPreviewLayer;
