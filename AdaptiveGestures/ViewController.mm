//
//  ViewController.m
//  AdaptiveGestures
//
//  Created by Marko Djordjevic on 13/04/2016.
//  Copyright © 2016 Marko Djordjevic. All rights reserved.
//

// PRE OPTIMIZATION: 15-17 FPS DURING FACE, 25-28 FPS DURING HAND
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController
@synthesize cameraView;
@synthesize camera;

// Global Variables
int channels[] = {0, 1};
float h_range[] = {0, 179};
float s_range[] = {0, 255};
const float *ranges[] = {h_range, s_range};

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Initialize camera settings
    [self initCamera];
    
    // Initialize face detector
    [self initFaceDetector];
    
    // Initialize variables
    [self initVars];
    
    // Start the camera
    self.camera.delegate = self;
    [self.camera start];
}

/* Initialise general variables regarding states and UI */
-(void)initVars {
    // Initialise states
    state = FACE;
    imageState = NORMAL;
    
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

/* Initialise face detector by loading cascade model */
-(void)initFaceDetector {
    NSString* cascadeModel = [[NSBundle mainBundle] pathForResource:@"lbpcascade_frontalface" ofType:@"xml"];
    const char* filePath = [cascadeModel fileSystemRepresentation];
    cascadeLoad = faceDetector.load(filePath);
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

/* Operations to perform on retrieved image */
- (void)processImage:(cv::Mat &)image {
    // Convert image to grayscale for face detection
    Mat grayImage;
    cvtColor(image, grayImage, CV_BGR2GRAY);
    
    // Normalize brightness and increase constrast of the image
    equalizeHist(grayImage, grayImage);
    
    // Convert image to HSV for back projection
    Mat hsvImage;
    cvtColor(image, hsvImage, CV_BGR2HSV);
    
    // Seperate HUE channel to be used for the histogram in back projection
    Mat hueImage;
    hueImage.create(hsvImage.size(), hsvImage.depth());
    int ch[] = {0, 0};
    mixChannels(&hsvImage, 1, &hueImage, 1, ch, 1);
    
    switch(state){
        case FACE:
        {
            // Detect face and retrieve face ROI
            cv::Rect face = [self detectFace:(image) :(grayImage)];
            Mat faceROIImage = [self getFaceROI:(image) :(face)];
            
            // Convert forehead ROI to HSV
            Mat roiHSV;
            cvtColor(faceROIImage, roiHSV, CV_BGR2HSV);
            
            // Get histogram of the HSV of the ROI
            skinHist = [self getHistogram:(roiHSV)];
            
            NSLog(@"FACE STATE");
            break;
        }
        case HAND:
        {
            // Get hand ROI
            Mat handROIImage = [self getHandROI:(image)];
            
            // Convert ROI to HSV
            Mat roiHSV;
            cvtColor(handROIImage, roiHSV, CV_BGR2HSV);
            
            // Get histogram of the HSV of the ROI
            skinHist = [self getHistogram:(roiHSV)];
            
            NSLog(@"HAND STATE");
            break;
        }
        case DETECT:
            NSLog(@"DETECT STATE");
            break;
        default:
            NSLog(@"INVALID STATE");
            break;
    }
    
    if(skinHist.empty()){
        return;
    }
    
    // Normalize the histogram
    normalize(skinHist, skinHist, 0, 255, NORM_MINMAX, -1, Mat());
    
    // Calculate a back projection of the hue image
    Mat backProjectedImage;
    calcBackProject(&hsvImage, 1, channels, skinHist, backProjectedImage, ranges, 1, true);
    
    // Blur the back projection
    Mat blur;
    medianBlur(backProjectedImage, blur, 9);
    Mat final;
    threshold(blur, final, 0, 255, THRESH_BINARY + THRESH_OTSU);
    
    // Erode and dilate the final image
    erode(final, final, getStructuringElement(MORPH_RECT, cvSize(self.erodeSlider.value, self.erodeSlider.value)));
    dilate(final, final, getStructuringElement(MORPH_RECT, cvSize(self.dilateSlider.value, self.dilateSlider.value)));
    
    switch(imageState){
        case NORMAL:
            if(state == DETECT){
                [self findAndDrawLargestContour:(final) :(image)];
                [self findAndDrawConvexHull:(final) :(image)];
            }
            break;
        case SKIN:
            final.copyTo(image);
            break;
        default:
            break;
    }
    
    //Add one frame
    totalFrames++;
}

/* Detects and returns the largest face using the passed gray image */
-(cv::Rect)detectFace:(cv::Mat) image :(cv::Mat) grayImage {
    cv::Rect face;
    try{
        if(cascadeLoad){
            int largestFaceArea = 0;
            int largestFaceIndex = 0;
            
            // Store faces found
            std::vector<cv::Rect> faces;
            
            // Find faces and store them
            faceDetector.detectMultiScale(grayImage, faces, 1.1, 3, CV_HAAR_FIND_BIGGEST_OBJECT | CV_HAAR_SCALE_IMAGE, cv::Size(50, 50));
            
            // Find largest face
            for(int i = 0; i < faces.size(); ++i){
                int area = faces[i].area();
                if(area > largestFaceArea){
                    largestFaceArea = area;
                    largestFaceIndex = i;
                }
            }
            
            if(!faces.empty()){
                // Draw rectangle around face
                Scalar color = Scalar(0, 255, 0);
                face = faces[largestFaceIndex];
                rectangle(image, face, color, 1);
            }
            
        }
    } catch(cv::Exception e){
        NSLog(@"FACE DETECTION ERROR: CASCADE FILES NOT LOADED");
    }
    return face;
}

/* Retrieves an ROI of the passed face image */
-(cv::Mat)getFaceROI:(cv::Mat)image :(cv::Rect) face {
    // Middle
    float topLeft_X = face.x + 0.35 * face.width;
    float topLeft_Y = face.y + 0.35 * face.height;
    float bottomRight_X = topLeft_X + 0.3 * face.width;
    float bottomRight_Y = topLeft_Y + 0.3 * face.height;
    
    // Forehead
//    float topLeft_X = face.x + face.width / 4;
//    float topLeft_Y = face.y + face.height / 16;
//    float bottomRight_X = topLeft_X + face.width / 2;
//    float bottomRight_Y = topLeft_Y + face.height / 6;
    
    cv::Point roiPoint1(topLeft_X, topLeft_Y);
    cv::Point roiPoint2(bottomRight_X, bottomRight_Y);
    
    Mat faceROIImage = image(cv::Rect(topLeft_X, topLeft_Y, bottomRight_X - topLeft_X, bottomRight_Y - topLeft_Y));
    
    // Draw rectangle around face ROI
    Scalar color = Scalar(0, 0, 255);
    rectangle(image, roiPoint1, roiPoint2, color, 1, 8, 0);
    
    return faceROIImage;
}

/* Find the largest contour from srcImage and then draw it on outputImage */
-(void)findAndDrawLargestContour:(cv::Mat) srcImage :(cv::Mat) outputImage {
    // Find contours
    findContours(srcImage, contours, RETR_EXTERNAL, CV_CHAIN_APPROX_SIMPLE);
    
    // Return if none exist
    if(contours.size() == 0){
        return;
        
    }
    // Find largest contour based on area
    int maxArea = 0;
    largestContourIndex = 0;
    for(int i = 0; i < contours.size(); i++){
        int area = (int)contourArea(contours[i]);
        if(area > maxArea){
            largestContourIndex = i;
            maxArea = area;
        }
    }
    
    // Simplify the largest contour
    approxPolyDP(Mat(contours[largestContourIndex]), contours[largestContourIndex], 5, true);
    
    // Draw largest contour (if it exists)
    if(!contours[largestContourIndex].empty()){
        Scalar color = Scalar(0, 255, 0);
        drawContours(outputImage, contours, largestContourIndex, color, CV_FILLED);
    }
}

/* Finds the convex hull from largest contour and draw its it to the toImage */
-(void)findAndDrawConvexHull:(cv::Mat) srcImage :(cv::Mat) outputImage {
    // Find convex hulls
    std::vector<std::vector<cv::Point>> hullsP(contours.size());
    std::vector<std::vector<int>> hullsI(contours.size());
    for(int i = 0; i < contours.size(); i++){
        convexHull(Mat(contours[i]), hullsP[i], true);
        convexHull(Mat(contours[i]), hullsI[i], true);
    }
    
    // Draw largest convex hull (if it exists)
    if(!hullsP.empty()){
        Scalar color = Scalar(150, 255, 0);
        for(int i = 0; i < contours.size(); i++){
            drawContours(outputImage, hullsP, largestContourIndex, color);
        }
    }
    
    
    
    
//    std::vector<std::vector<cv::Point>> hulls(contours.size());
//    std::vector<std::vector<int>> hullsI(contours.size());
//    std::vector<std::vector<Vec4i>> defects(contours.size());
//    
//    Scalar color = Scalar(150, 255, 0);
//    
//    // Find convex hulls
//    for(int i = 0; i < contours.size(); i++){
//        convexHull(Mat(contours[i]), hulls[i], true);
//        convexHull(Mat(contours[i]), hullsI[i], true);
//        drawContours(toImage, hulls, largestContourIndex, color);
    
//        convexityDefects(contours[i], hullsI[i], defects[i]);
        
        
        
        // Find convex defects
//        std::vector<Vec4i> defects;
//        if(hullsI[i].size() > 0){
//            cv::Point2f rect_points[4];
//            rect.points(rect_points);
//            for(int j = 0; j < 4; j++){
//                line(toImage, rect_points[j], rect_points[(j+1)%4], Scalar(255, 0, 0), 1, 8);
//                cv::Point rough_palm_center;
//                convexityDefects(contours[i], hulls[i], defects);
//            }
//        
//        }
        
//    }
    
    // Draw largest convex hull (if contour exists)
//    if(!hulls.empty()){
//        Scalar color = Scalar(150, 255, 0);
//        for(int i = 0; i < contours.size(); i++){
//            cv::drawContours(toImage, hulls, largestContourIndex, color);
//        }
//        
//    }
}

/* TEMP FUNCTION - COMPLETE LATER */
-(cv::Mat)getHandROI:(cv::Mat)image {
    int width = image.size().width;
    int height = image.size().height;
    int x = image.size().width/2;
    int y = image.size().height/2;
    
    float topLeft_X = x-width/10;
    float topLeft_Y = y-height/10;
    float bottomRight_X = x+width/20;
    float bottomRight_Y = y+height/20;
    
    cv::Point roiPoint1(topLeft_X, topLeft_Y);
    cv::Point roiPoint2(bottomRight_X, bottomRight_Y);
    
    Mat handROIImage = image(cv::Rect(topLeft_X, topLeft_Y, bottomRight_X - topLeft_X, bottomRight_Y - topLeft_Y));
    
    // Draw rectangle around hand ROI
    Scalar color = Scalar(0, 0, 255);
    rectangle(image, roiPoint1, roiPoint2, color, 1, 8, 0);
    
    return handROIImage;
}

/* Caclulates a hisogram of passed image with adjustable HUE and SATURATION channels (bins) */
-(cv::MatND)getHistogram:(cv::Mat) image {
    cv::MatND hist;
    int h_bins = self.hueSlider.value;
    int s_bins = self.satSlider.value;
    int histSize[] = { h_bins, s_bins };
    cv::calcHist(&image, 1, channels, Mat(), hist, 2, histSize, ranges);
    return hist;
}

/* Called every second to update the frames and update the FPS label */
- (void)computeFPS {
    [self.fpsLabel setText:[NSString stringWithFormat:@"FPS: %d", totalFrames]];
    totalFrames = 0;
}

/* UI Functions */

- (IBAction)onHueSliderChanged:(id)sender {
    self.hueSlider.value = roundf(self.hueSlider.value);
    self.hueLabel.text = [NSString stringWithFormat:@"HUE: %0.0f", self.hueSlider.value];
}

- (IBAction)onSatSliderChanged:(id)sender {
    self.satSlider.value = roundf(self.satSlider.value);
    self.satLabel.text = [NSString stringWithFormat:@"SAT: %0.0f", self.satSlider.value];
}

- (IBAction)onDilateSliderChanged:(id)sender {
    self.dilateSlider.value = roundf(self.dilateSlider.value);
    self.dilateLabel.text = [NSString stringWithFormat:@"DILATE: %0.0f", self.dilateSlider.value];
}

- (IBAction)onErodeSliderChanged:(id)sender {
    self.erodeSlider.value = roundf(self.erodeSlider.value);
    self.erodeLabel.text = [NSString stringWithFormat:@"ERODE: %0.0f", self.erodeSlider.value];
}

- (IBAction)onImageControlChange:(id)sender {
    NSInteger selectedSegment = self.imageControl.selectedSegmentIndex;
    
    if(selectedSegment == 0){
        imageState = NORMAL;
        self.hueSlider.hidden = true;
        self.hueLabel.hidden = true;
        self.satSlider.hidden = true;
        self.satLabel.hidden = true;
        self.dilateSlider.hidden = true;
        self.dilateLabel.hidden = true;
        self.erodeSlider.hidden = true;
        self.erodeLabel.hidden = true;
    }else if(selectedSegment == 1){
        imageState = SKIN;
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
        state = FACE;
        self.hueSlider.enabled = true;
        self.hueLabel.enabled = true;
        self.satSlider.enabled = true;
        self.satLabel.enabled = true;
    }else if(selectedSegment == 1){
        state = HAND;
        self.hueSlider.enabled = true;
        self.hueLabel.enabled = true;
        self.satSlider.enabled = true;
        self.satLabel.enabled = true;
    }else if(selectedSegment == 2){
        state = DETECT;
        self.hueSlider.enabled = false;
        self.hueLabel.enabled = false;
        self.satSlider.enabled = false;
        self.satLabel.enabled = false;
    }
}

@end
