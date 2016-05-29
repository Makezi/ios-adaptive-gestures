//
// Created by Marko Djordjevic on 27/05/2016.
// Copyright (c) 2016 Marko Djordjevic. All rights reserved.
//

#import <Foundation/Foundation.h>

#include <opencv2/imgproc/imgproc.hpp>
#include <opencv2/opencv.hpp>

using namespace cv;

@interface ROI : NSObject {
    cv::Point topLeft;
    cv::Point bottomRight;
    Mat roi;
    Scalar color;
    int borderThickness;
}

-(id)init;
-(Mat)setROI:(Mat) srcImage;
-(void)drawROI:(Mat) srcImage;

@property (nonatomic) cv::Point topLeft;
@property (nonatomic) cv::Point bottomRight;
//@property (nonatomic) Mat roi;
//@property (nonatomic) Scalar color;
//@property (nonatomic) int borderThickness;


@end