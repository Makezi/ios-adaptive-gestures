//
// Created by Marko Djordjevic on 7/06/2016.
// Copyright (c) 2016 Marko Djordjevic. All rights reserved.
//

#import <opencv2/videoio/cap_ios.h>
#import <opencv2/objdetect/objdetect.hpp>
#import <opencv2/imgproc.hpp>

using namespace cv;
using namespace std;

@interface FaceDetector : NSObject {
    CascadeClassifier detector;
    bool cascadeLoaded;
}

/* Initialises face detector by loading a cascade model */
-(void)loadCascade;

/* Detects and returns the largest face found using the passed gray image */
-(cv::Rect)detectFace:(Mat) grayImage :(Mat)outputImage;

@end