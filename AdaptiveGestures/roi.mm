//
// Created by Marko Djordjevic on 27/05/2016.
// Copyright (c) 2016 Marko Djordjevic. All rights reserved.
//

#import "ROI.h"


@implementation ROI

/* Initialisation */
-(id)init {
    if(self = [super init]){
        topLeft = cv::Point(0, 0);
        bottomRight = cv::Point(0, 0);
        borderThickness = 2;
    }
    return self;
}

-(Mat)setROI:(cv::Point) topLeft :(cv::Point) bottomRight :(Mat) srcImage {
    self.topLeft = topLeft;
    self.bottomRight = bottomRight;
    roi = srcImage(cv::Rect(
            self.topLeft.x,
            self.topLeft.y,
            bottomRight.x - topLeft.x,
            bottomRight.y - topLeft.y)
    );
    return roi;
}
-(void)drawROI:(Mat) srcImage :(Scalar) color {
    rectangle(srcImage, topLeft, bottomRight, color, borderThickness, 8, 0);
}


@end