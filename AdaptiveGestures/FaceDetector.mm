//
// Created by Marko Djordjevic on 7/06/2016.
// Copyright (c) 2016 Marko Djordjevic. All rights reserved.
//

#import "FaceDetector.h"


@implementation FaceDetector

-(void)loadCascade {
//    NSString* cascadeModel = [[NSBundle mainBundle] pathForResource:@"lbpcascade_frontalface" ofType:@"xml"];
    NSString* cascadeModel = [[NSBundle mainBundle] pathForResource:@"haarcascade_frontalface_default" ofType:@"xml"];
    const char* filePath = [cascadeModel fileSystemRepresentation];
    cascadeLoaded = detector.load(filePath);
}

-(cv::Rect)detectFace:(Mat) grayImage :(Mat)outputImage {
    cv::Rect face;
    try{
        if(cascadeLoaded){
            // Store faces found
            std::vector<cv::Rect> faces;
            detector.detectMultiScale(grayImage, faces, 1.1, 3, CV_HAAR_FIND_BIGGEST_OBJECT | CV_HAAR_SCALE_IMAGE, cv::Size(50, 50));

            // Find largest face in image
            int largestFaceArea = 0;
            int largestFaceIndex = 0;
            for(int i = 0; i < faces.size(); i++){
                int area = faces[i].area();
                if(area > largestFaceArea){
                    largestFaceArea = area;
                    largestFaceIndex = i;
                }
            }

            // Draw rect around detected face if it exists
            if(!faces.empty()){
                face = faces[largestFaceIndex];
                Scalar color = Scalar(0, 255, 0); // Red
                rectangle(outputImage, face, color, 2);
            }
        }
    } catch(cv::Exception e){
        NSLog(@"FACE DETECTION ERROR: Cascade file did not load.");
    }
    return face;
}

@end