//
//  VideoCamera.h
//  AdaptiveGestures
//
//  Created by Marko Djordjevic on 14/04/2016.
//  Copyright © 2016 Marko Djordjevic. All rights reserved.
//

#ifndef VideoCamera_h
#define VideoCamera_h


#endif /* VideoCamera_h */

#import <opencv2/videoio/cap_ios.h>

@protocol VideoCameraDelegate <CvVideoCameraDelegate>
@end

@interface VideoCamera : CvVideoCamera

- (void)updateOrientation;
- (void)layoutPreviewLayer;

@end
