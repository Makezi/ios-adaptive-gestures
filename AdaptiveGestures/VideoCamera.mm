//
//  VideoCamera.m
//  AdaptiveGestures
//
//  Created by Marko Djordjevic on 14/04/2016.
//  Copyright © 2016 Marko Djordjevic. All rights reserved.
//
//  Methods defined to fix camera orientation issues
//

#import <Foundation/Foundation.h>

#import "VideoCamera.h"
#define DEGREES_RADIANS(angle) ((angle) / 180.0 * M_PI)
@implementation VideoCamera

- (void)updateOrientation {
    self->customPreviewLayer.bounds = CGRectMake(0, 0, self.parentView.frame.size.width, self.parentView.frame.size.height);
    [self layoutPreviewLayer];
}

- (void)layoutPreviewLayer {
    if (self.parentView != nil)
    {
        CALayer* layer = self->customPreviewLayer;
        CGRect bounds = self->customPreviewLayer.bounds;
        int rotation_angle = 0;
        
        switch (defaultAVCaptureVideoOrientation) {
            case AVCaptureVideoOrientationLandscapeRight:
                rotation_angle = 270;
                break;
            case AVCaptureVideoOrientationPortraitUpsideDown:
                rotation_angle = 180;
                break;
            case AVCaptureVideoOrientationLandscapeLeft:
                rotation_angle = 90;
                break;
            case AVCaptureVideoOrientationPortrait:
            default:
                break;
        }
        
        layer.position = CGPointMake(self.parentView.frame.size.width/2., self.parentView.frame.size.height/2.);
        layer.affineTransform = CGAffineTransformMakeRotation( DEGREES_RADIANS(rotation_angle) );
        layer.bounds = bounds;
    }
}

@end