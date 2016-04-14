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
//    Mat image_copy;
//    flip(image, image_copy, -1);
//    Mat image_copy;
    
//    flip(image, image_copy, 1);
    
//    cv::flip(image, image_copy, 1);
//    cvtColor(image, image, CV_BGR2HSV);
    
    
//    Mat image_copy;
//    cvtColor(image, image_copy, CV_BGRA2BGR);
//    
//    flip(image_copy, image_copy, 1);
//    
    // invert image
//    bitwise_not(image_copy, image_copy);
//    cvtColor(image_copy, image, CV_BGR2BGRA);
    
}

@end
