//
//  ViewController.m
//  AdaptiveGestures
//
//  Created by Marko Djordjevic on 13/04/2016.
//  Copyright © 2016 Marko Djordjevic. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController
@synthesize imageView;
@synthesize camera;


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // Assign camera to imageView
    self.camera = [[VideoCamera alloc] initWithParentView:imageView];
    
    // Set to use the front camera
    self.camera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionFront;
    
    // Set the resolution to 352x288
    self.camera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset352x288;
    
    // Camera orientation is set to portrait
    self.camera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
    
    // REQUIRED?
//    self.camera.rotateVideo = YES;
    
    // Set default FPS to 30
    self.camera.defaultFPS = 30;
    
    // Set grayscale to NO
    self.camera.grayscaleMode = NO;
    
    // Start the camera
    self.camera.delegate = self;
    [self.camera start];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    // Update the camera orientation after view has loaded
    [self.camera updateOrientation];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)processImage:(cv::Mat &)image;
{
    // Convert to HSV
    cvtColor(image, image, CV_BGR2HSV);
    // Create mask for HSV image thresholds
    Mat mask;
    
    // Hue (angle, 0-180), Saturation (intensity of color, 0-255), Value (brightness, 0-100)
    Scalar lower = Scalar(0, 15, 120);
    Scalar upper = Scalar(33, 250, 255);
    
    // Apply HSV thresholds for skin color
    inRange(image, lower, upper, mask);
    
    // Testing slider values
    NSLog(@"LOWERSliderValue ... %d",(int)[self.lowerHueSlider value]);
    NSLog(@"UPPERSliderValue ... %d",(int)[self.upperHueSlider value]);
    NSLog(@"LOWERDILATESliderValue ... %d",(int)[self.lowerDilationSlider value]);
    NSLog(@"UPPERDILATESliderValue ... %d",(int)[self.upperDilationSlider value]);
    
    // Convert original image back to RGB
    cvtColor(image, image, CV_HSV2RGB);

    // Erode THEN dilate to remove noise from HSV mask
    erode(mask, mask, getStructuringElement(MORPH_RECT, cvSize(3, 3)));
    dilate(mask, mask, getStructuringElement(MORPH_RECT, cvSize(3, 3)));
    
    // Find contours
    std::vector<std::vector<cv::Point> > contours;
    cv::findContours(mask, contours, cv::RETR_LIST, cv::CHAIN_APPROX_NONE);
    
    // Retreive largest contour
    double largestContour = 0;
    int largestIndex = 0;
    for(int i=0; i<contours.size(); i++){
        if(contours[i].size() > largestContour){
            largestContour = contours[i].size();
            largestIndex = i;
        }
    }
    
    // Draw largest contour (if exists)
    if(!contours.empty()){
        cv::drawContours(image, contours, largestIndex, Scalar(255, 0, 0));
        cv::Rect brect = cv::boundingRect(contours[largestIndex]);
        cv::rectangle(image, brect, Scalar(255, 0, 0));
    }
    
}

@end
