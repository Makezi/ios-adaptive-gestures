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
//    NSString* cascadeModel = [[NSBundle mainBundle] pathForResource:@"lbpcascade_frontalface" ofType:@"xml"];
    NSString* cascadeModel = [[NSBundle mainBundle] pathForResource:@"haarcascade_frontalface_default" ofType:@"xml"];
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
- (void)processImage:(Mat &)image {

    skinHists.clear();
    
    Mat grayImage;
    cvtColor(image, grayImage, CV_BGR2GRAY);
    equalizeHist(grayImage, grayImage);
    
    switch(state){
        case FACE:
        {
            // Detect face and retrieve face ROI
            cv::Rect face = [self detectFace:(image) :(grayImage)];
            Mat faceROIImage = [self getFaceROI:(image) :(face)];
            
            // Convert ROI to HSV
            Mat roiHSV;
            cvtColor(faceROIImage, roiHSV, CV_BGR2HSV);
            
            // Get histogram of the HSV of the ROI
            skinHist = [self getHistogram:(roiHSV)];
            
            NSLog(@"FACE STATE");
            break;
        }
        case HAND:
        {
            [self getPalmROI:(image)];
            for(int i = 0; i < roiMat.size(); i++){
                Mat roiHSV;
                cvtColor(roiMat[i], roiHSV, CV_BGR2HSV);
                skinHists.push_back([self getHistogram:(roiHSV)]);
            }
            cv::merge(skinHists, skinHist);
            break;
        }
        case DETECT:
            NSLog(@"DETECT STATE");
            break;
        default:
            NSLog(@"INVALID STATE");
            break;
    }
    
    if(skinHist.empty()) return;
    
    // Convert image to HSV for back projection
    Mat hsvImage;
    cvtColor(image, hsvImage, CV_BGR2HSV);
    
    // Seperate HUE channel to be used for the histogram in back projection
    Mat hueImage;
    hueImage.create(hsvImage.size(), hsvImage.depth());
    int ch[] = {0, 0};
    mixChannels(&hsvImage, 1, &hueImage, 1, ch, 1);
    
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
    
    switch(imageState) {
        case NORMAL:
            if (state == DETECT) {
                [self createContours:(final) :(image)];
                [self createBoundingBox:(image)];
                if([self detectIsHand:(image)]){
                    [self createConvexHulls:(image)];
                    [self createFingerTips:(image)];
                    [self drawPalm:(image)];
                    
                    Scalar color = Scalar(255, 0, 0); // Blue (BGR)
                    for(int i = 0; i < fingerTips.size(); i++){
                        if([self distanceBetweenPoints:(fingerTips[i]):(palmCenter)] > 100){
                            circle(image, fingerTips[i], 10, color, 2);
                        }
                    }
                }

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
    float topLeft_X = face.x + 0.25 * face.width;
    float topLeft_Y = face.y + 0.25 * face.height;
    float bottomRight_X = topLeft_X + 0.5 * face.width;
    float bottomRight_Y = topLeft_Y + 0.5 * face.height;
    
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

-(void)createContours:(Mat) srcImage :(Mat) outputImage {
    // Find contours and return if no contours were found
    contours.clear();
    findContours(srcImage, contours, CV_RETR_EXTERNAL, CV_CHAIN_APPROX_NONE);
    if(contours.size() == 0) return;
    
    // Find the index of the largest contour and return if none were found
    [self findLargestContourIndex];
    if(largestContourIndex == -1) return;
    
    // Draw the largest contour
//    Scalar color = Scalar(0, 0, 255); // Red (BGR)
//    drawContours(outputImage, contours, largestContourIndex, color, 2);
}

-(void)findLargestContourIndex {
    int maxArea = 0;
    largestContourIndex = -1;
    for(int i = 0; i < contours.size(); i++){
        int area = (int)contourArea(contours[i]);
        if(area > maxArea){
            maxArea = area;
            largestContourIndex = i;
        }
    }
}

-(void)createBoundingBox:(Mat) outputImage {
    // Create a bounding box around the largest contour if it exists
    if(contours.size() == 0 || largestContourIndex == -1) return;
    bRect = boundingRect(Mat(contours[largestContourIndex]));
    
    // Draw the bounding box
//    Scalar color = Scalar(255, 255, 255); // White
//    rectangle(outputImage, bRect.tl(), bRect.br(), color, 2);
}

-(void)createConvexHulls:(Mat) outputImage {
    // Init vectors if contours exist, otherwise return
    if(contours.size() == 0) return;
    hullsP = vector<vector<cv::Point>>(contours.size());
    hullsI = vector<vector<int>>(contours.size());
    defects = vector<vector<Vec4i>>(contours.size());
    
    if(largestContourIndex == -1) return;
    
    convexHull(Mat(contours[largestContourIndex]), hullsP[largestContourIndex], false, true);
    convexHull(Mat(contours[largestContourIndex]), hullsI[largestContourIndex], false, false);
    
    if(contours[largestContourIndex].size() > 3){
        convexityDefects(contours[largestContourIndex], hullsI[largestContourIndex], defects[largestContourIndex]);
        
    }
    
    if(hullsP.empty()) return;
//    Scalar color = Scalar(255, 255, 0); // Yellow (BGR)
    approxPolyDP(Mat(hullsP[largestContourIndex]), hullsP[largestContourIndex], 18, true);
//    drawContours(outputImage, hullsP, largestContourIndex, color, 2);
}

-(void)createFingerTips:(Mat) outputImage {    
    fingerTips.clear();
    depthPoints.clear();
    for(int i = 0; i < contours.size(); i++){
        for(const Vec4i& v : defects[i]){
            float depth = v[3] / 256;
            if(depth > 20 && i == largestContourIndex){
                int startidx = v[0]; cv::Point ptStart(contours[i][startidx]);
                int endidx = v[1]; cv::Point ptEnd(contours[i][endidx]);
                int faridx = v[2]; cv::Point ptFar(contours[i][faridx]);
                
                if(fingerTips.size() <= 5){
                    fingerTips.push_back(ptEnd);
                }
                
                if(![self isCloseToBoundary:(ptFar) :(outputImage)]){
                    depthPoints.push_back(ptFar);
                }
            }
        }
    }
    
    if(fingerTips.size() == 0){
        // CHECK FOR ONE FINGER!
    }
    
    [self deleteFalseFingerTips];
    
//    color = Scalar(0, 255, 0);
//    for(int i = 0; i < depthPoints.size(); i++){
//        circle(outputImage, depthPoints[i], 5, color, 2);
//    }
}

-(void)deleteFalseFingerTips {
    if(fingerTips.size() == 0) return;
    
    std::vector<cv::Point> newFingerTips;
    for(int i = 0; i < fingerTips.size(); i++){
        for(int j = i; j < fingerTips.size(); j++){
            if([self distanceBetweenPoints:(fingerTips[i]) :(fingerTips[j])] >= 10 && i != j){
                newFingerTips.push_back(fingerTips[i]);
                break;
            }
        }
    }
    
    
    
    fingerTips.swap(newFingerTips);
}

-(float)distanceBetweenPoints:(cv::Point) pt1 :(cv::Point) pt2 {
    return sqrt(fabs(pow(pt1.x - pt2.x, 2) + pow(pt1.y - pt2.y, 2)));
}

-(bool) isCloseToBoundary:(cv::Point) pt :(Mat) srcImage {
    int margin = 10;
    
    if(pt.x > (bRect.br().x - margin)){
        return true;
    }
    
    if(pt.x < (bRect.tl().x + margin)){
        return true;
    }
    
    if(pt.y > (bRect.br().y - margin)){
        return true;
    }
    
    if(pt.y < (bRect.tl().y + margin)){
        return true;
    }
    
    return false;
}

-(float)findShortestDistance:(cv::Point) pt :(std::vector<cv::Point>) dPts {
    float shortest = 9999;
    for(int i = 0; i < dPts.size(); i++){
        float distance = [self distanceBetweenPoints:(pt) :(dPts[i])];
        if(distance < shortest){
            shortest = distance;
        }
    }
    return shortest;
}

-(bool)detectIsHand:(Mat) srcImage {
    bool isHand = true;
    int centerX = 0;
    int centerY = 0;
    if(bRect.area() > 0){
        centerX = bRect.x + bRect.width/2;
        centerY = bRect.y + bRect.height/2;
    }
    
    if(largestContourIndex == -1){
        isHand = false;
    }else if(bRect.area() <= 0){
        isHand = false;
    }else if(bRect.height == 0 || bRect.width == 0){
        isHand = false;
    }else if(centerX < srcImage.cols/4 || centerX > srcImage.cols*3/4){
        isHand = false;
    }
    
    return isHand;
}

-(void)drawPalm:(Mat) outputImage {
    
    float radius;
    
    if(depthPoints.empty()) return;
    minEnclosingCircle(depthPoints, palmCenter, radius);
    
//    circle(outputImage, palmCenter, radius, Scalar(255, 0, 0), 2);
    
//    for(int i = 0; i < depthPoints.size(); i++){
//        circle(outputImage, depthPoints[i], 2, Scalar(255, 255, 0), 2);
//    }
}

-(void)getPalmROI: (Mat) srcImage {
    
    roiMat.clear();
    
    int squareLen = 20;
    
    Scalar color = Scalar(0, 0, 255);
    
    // Middle Top
    cv::Point roi1Point1(srcImage.cols*0.5, srcImage.rows*0.3);
    cv::Point roi1Point2(srcImage.cols*0.5+squareLen, srcImage.rows*0.3+squareLen);
    rectangle(srcImage, roi1Point1, roi1Point2, color, 2, 8, 0);
    cv::Mat roi1Mat = srcImage(cv::Rect(roi1Point1.x, roi1Point1.y, roi1Point2.x - roi1Point1.x, roi1Point2.y - roi1Point1.y));
    
    // Middle
    cv::Point roi2Point1(srcImage.cols*0.5, srcImage.rows*0.5);
    cv::Point roi2Point2(srcImage.cols*0.5+squareLen, srcImage.rows*0.5+squareLen);
    rectangle(srcImage, roi2Point1, roi2Point2, color, 2, 8, 0);
    cv::Mat roi2Mat = srcImage(cv::Rect(roi2Point1.x, roi2Point1.y, roi2Point2.x - roi2Point1.x, roi2Point2.y - roi2Point1.y));
    
    // Top Left
    cv::Point roi3Point1(srcImage.cols*0.4, srcImage.rows*0.4);
    cv::Point roi3Point2(srcImage.cols*0.4+squareLen, srcImage.rows*0.4+squareLen);
    rectangle(srcImage, roi3Point1, roi3Point2, color, 2, 8, 0);
    cv::Mat roi3Mat = srcImage(cv::Rect(roi3Point1.x, roi3Point1.y, roi3Point2.x - roi3Point1.x, roi3Point2.y - roi3Point1.y));
    
    // Top Right
    cv::Point roi4Point1(srcImage.cols*0.6, srcImage.rows*0.4);
    cv::Point roi4Point2(srcImage.cols*0.6+squareLen, srcImage.rows*0.4+squareLen);
    rectangle(srcImage, roi4Point1, roi4Point2, color, 2, 8, 0);
    cv::Mat roi4Mat = srcImage(cv::Rect(roi4Point1.x, roi4Point1.y, roi4Point2.x - roi4Point1.x, roi4Point2.y - roi4Point1.y));
    
    // Bottom Left
    cv::Point roi5Point1(srcImage.cols*0.4, srcImage.rows*0.6);
    cv::Point roi5Point2(srcImage.cols*0.4+squareLen, srcImage.rows*0.6+squareLen);
    rectangle(srcImage, roi5Point1, roi5Point2, color, 2, 8, 0);
    cv::Mat roi5Mat = srcImage(cv::Rect(roi5Point1.x, roi5Point1.y, roi5Point2.x - roi5Point1.x, roi5Point2.y - roi5Point1.y));
    
    // Bottom Right
    cv::Point roi6Point1(srcImage.cols*0.6, srcImage.rows*0.6);
    cv::Point roi6Point2(srcImage.cols*0.6+squareLen, srcImage.rows*0.6+squareLen);
    rectangle(srcImage, roi6Point1, roi6Point2, color, 2, 8, 0);
    cv::Mat roi6Mat = srcImage(cv::Rect(roi6Point1.x, roi6Point1.y, roi6Point2.x - roi6Point1.x, roi6Point2.y - roi6Point1.y));
    
    // Middle Left
    cv::Point roi7Point1(srcImage.cols*0.3, srcImage.rows*0.5);
    cv::Point roi7Point2(srcImage.cols*0.3+squareLen, srcImage.rows*0.5+squareLen);
    rectangle(srcImage, roi7Point1, roi7Point2, color, 2, 8, 0);
    cv::Mat roi7Mat = srcImage(cv::Rect(roi7Point1.x, roi7Point1.y, roi7Point2.x - roi7Point1.x, roi7Point2.y - roi7Point1.y));
    
    roiMat.push_back(roi1Mat);
    roiMat.push_back(roi2Mat);
    roiMat.push_back(roi3Mat);
    roiMat.push_back(roi4Mat);
    roiMat.push_back(roi5Mat);
    roiMat.push_back(roi6Mat);
    roiMat.push_back(roi7Mat);
    
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
