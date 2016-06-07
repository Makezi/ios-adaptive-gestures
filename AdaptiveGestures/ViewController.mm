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
@synthesize cameraView;
@synthesize camera;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Initialize camera settings
    [self initCamera];
    
    // Initialize face detector
    detector = [[FaceDetector alloc] init];
    [detector loadCascade];

    // Initialize finger tip detection
    ftd = [[FingerTipDetector alloc] init];
    
    // Initialize variables
    [self initVars];
    
    // Start the camera
    self.camera.delegate = self;
    [self.camera start];
}

/* Initialise general variables regarding states and UI */
-(void)initVars {
    // Initialise user interface
    self.hueSlider.hidden = true;
    self.hueLabel.hidden = true;
    self.satSlider.hidden = true;
    self.satLabel.hidden = true;
    self.dilateSlider.hidden = true;
    self.dilateLabel.hidden = true;
    self.erodeSlider.hidden = true;
    self.erodeLabel.hidden = true;
    
    // Initialise frames to 0 and start timer to refresh the frames each second
    totalFrames = 0;
    [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(computeFPS) userInfo:nil repeats:YES];
}

/* Initialise camera settings */
-(void)initCamera {
    // Assign camera to cameraView
    self.camera = [[VideoCamera alloc] initWithParentView:cameraView];
    
    // Set to use the front camera
    self.camera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionFront;
    
    // Set the resolution to 352x288
    self.camera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset640x480;
    
    // Camera orientation is set to portrait
    self.camera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
    
    // REQUIRED?
    //    self.camera.rotateVideo = YES;
    
    // Set default FPS to 30
    self.camera.defaultFPS = 30;

    // Set grayscale to NO
    self.camera.grayscaleMode = NO;
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // Update the camera orientation after view has loaded
    [self.camera updateOrientation];
}

/* Set status bar to light theme */
- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)processImage:(Mat &) image {
    [ftd processImage:(image)];

    totalFrames++;
}

/* Called every second to update the frames and update the FPS label */
- (void)computeFPS {
    [self.fpsLabel setText:[NSString stringWithFormat:@"FPS: %d", totalFrames]];
    totalFrames = 0;
}

/* UI Functions */

- (IBAction)onHueSliderChanged:(id)sender {
    self.hueSlider.value = roundf(self.hueSlider.value);
    [ftd setHueBins:(self.hueSlider.value)];
    self.hueLabel.text = [NSString stringWithFormat:@"HUE: %0.0f", self.hueSlider.value];
}

- (IBAction)onSatSliderChanged:(id)sender {
    self.satSlider.value = roundf(self.satSlider.value);
    [ftd setSatBins:(self.satSlider.value)];
    self.satLabel.text = [NSString stringWithFormat:@"SAT: %0.0f", self.satSlider.value];
}

- (IBAction)onDilateSliderChanged:(id)sender {
    self.dilateSlider.value = roundf(self.dilateSlider.value);
    [ftd setDilation:(self.dilateSlider.value)];
    self.dilateLabel.text = [NSString stringWithFormat:@"DILATE: %0.0f", self.dilateSlider.value];
}

- (IBAction)onErodeSliderChanged:(id)sender {
    self.erodeSlider.value = roundf(self.erodeSlider.value);
    [ftd setErosion:(self.erodeSlider.value)];
    self.erodeLabel.text = [NSString stringWithFormat:@"ERODE: %0.0f", self.erodeSlider.value];
}

- (IBAction)onImageControlChange:(id)sender {
    NSInteger selectedSegment = self.imageControl.selectedSegmentIndex;
    if(selectedSegment == 0){
        [ftd setImageState:(NORMAL)];
        self.hueSlider.hidden = true;
        self.hueLabel.hidden = true;
        self.satSlider.hidden = true;
        self.satLabel.hidden = true;
        self.dilateSlider.hidden = true;
        self.dilateLabel.hidden = true;
        self.erodeSlider.hidden = true;
        self.erodeLabel.hidden = true;
    }else if(selectedSegment == 1){
        [ftd setImageState:(SKIN)];
        self.hueSlider.hidden = false;
        self.hueLabel.hidden = false;
        self.satSlider.hidden = false;
        self.satLabel.hidden = false;
        self.dilateSlider.hidden = false;
        self.dilateLabel.hidden = false;
        self.erodeSlider.hidden = false;
        self.erodeLabel.hidden = false;
    }
}
- (IBAction)onStateControlChange:(id)sender {
    NSInteger selectedSegment = self.stateControl.selectedSegmentIndex;
    if(selectedSegment == 0){
       [ftd setAppState:(FACE_SAMPLE)];
        self.hueSlider.enabled = true;
        self.hueLabel.enabled = true;
        self.satSlider.enabled = true;
        self.satLabel.enabled = true;
    }else if(selectedSegment == 1){
        [ftd setAppState:(HAND_SAMPLE)];
        self.hueSlider.enabled = true;
        self.hueLabel.enabled = true;
        self.satSlider.enabled = true;
        self.satLabel.enabled = true;
    }else if(selectedSegment == 2){
        [ftd setAppState:(DETECT)];
        self.hueSlider.enabled = false;
        self.hueLabel.enabled = false;
        self.satSlider.enabled = false;
        self.satLabel.enabled = false;
    }
}

@end
