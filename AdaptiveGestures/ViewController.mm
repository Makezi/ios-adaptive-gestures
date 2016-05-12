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

// Flag to determine if cascade file has been loaded
bool cascadeLoad;

State currentState = FACE;

int totalFrames;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // Initialize camera settings
    [self initCamera];
    
    // Initialize face detector
    [self initFaceDetector];
    
    // Start the camera
    self.camera.delegate = self;
    [self.camera start];
    
    // Init frames to 0 and start timer to refresh the frames each second
    totalFrames = 0;
    [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(computeFPS) userInfo:nil repeats:YES];
}

-(void)initCamera {
    // Assign camera to imageView
    self.camera = [[VideoCamera alloc] initWithParentView:imageView];
    
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

-(void)initFaceDetector {
    // Load Cascade Model for Face Detection
    NSString* cascadeModel = [[NSBundle mainBundle] pathForResource:@"haarcascade_frontalface_default" ofType:@"xml"];
    const char* filePath = [cascadeModel fileSystemRepresentation];
    
    if(faceDetector.load(filePath)){
        cascadeLoad = true;
    }else{
        cascadeLoad = false;
    }
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

// Function called every second to update the frames and update the FPS label
- (void)computeFPS {
    [self.fps setText:[NSString stringWithFormat:@"FPS: %d", totalFrames]];
    totalFrames = 0;
}

- (void)processImage:(cv::Mat &)image;
{
    cv::Rect faceSample;
    switch(currentState){
        case FACE:
            [self faceDetection:(faceSample) :(image)];

            self.sampleSkinButton.enabled = faceSample.area() > 0;
            
            NSLog(@"FACE STATE");
            break;
        case HAND:
            NSLog(@"HAND STATE");
            break;
        default:
            NSLog(@"INVALID STATE");
            break;
    }
    
    
    // BEFORE TRYING THE YCRCB TECHNIQUE DO:
    // FACE DETECTION WITH INNER RECT
    // GET PIXEL VALUES OF INNER RECT
    // USE MIN/MAX/AVERAGE AS THRESHOLDS (RGB OR HSV)
    // PERFORM SKIN THINGY (EROSION, DILATION, CONTRAST? BLUR?)
    
    // 1. Detecting the face
    // In order to lighten the computational burden, the skin values are extracted only once for every detected face (new face).
    // As long there isn't any changes in illumination, the model doesn't have to be updated.
    
//    cv::Rect faceSample;
    
    
    
//
//    try{
//        if(cascadeLoad && !image.empty()){
//            int largestFaceArea = 0;
//            int largestFaceIndex = 0;
//            vector<cv::Rect> faces;
//            faceDetector.detectMultiScale(image, faces, 1.2, 2, 0, cv::Size(50, 50));
//            for (int i = 0; i < faces.size(); i++) {
//                int area = faces[i].area();
//                if(area > largestFaceArea){
//                    largestFaceArea = area;
//                    largestFaceIndex = i;
//                }
//            }
//            if(!faces.empty()){
//                Scalar outerRectColor = Scalar(0, 255, 0);
//                Scalar innerRectColor = Scalar(150, 150, 0);
//                // Draw outer rectangle
//                rectangle(image, faces[largestFaceIndex], outerRectColor, 1);
//                // Draw innner rectangle
//                faceSample = cv::Rect(faces[largestFaceIndex].x + 0.25*faces[largestFaceIndex].width,
//                                      faces[largestFaceIndex].y + 0.25*faces[largestFaceIndex].height,
//                                      0.5*faces[largestFaceIndex].width,
//                                      0.5*faces[largestFaceIndex].height);
//                rectangle(image, faceSample, innerRectColor, 1);
//            }
//        }
//    } catch (cv::Exception e) {
//        NSLog(@"FACE DETECTION ERROR: CASCADE FILES NOT LOADED");
//    }

    // 2. Extract pixel values from faceSample
    
    // Convert to HSV?
    
//    Mat hsv;
//    
//    cvtColor(image, image, COLOR_BGR2HSV);
    
    
    
    
    
    
    
    
//    Mat YCrCb;
//    Mat YCrCb_planes[3];
//    
//    cvtColor(image, YCrCb, COLOR_BGR2YCrCb);
//    
//    split(YCrCb, YCrCb_planes);
//    
//    Mat y = YCrCb_planes[0];
//    Mat cb = YCrCb_planes[1];
//    Mat cr = YCrCb_planes[2];
//    
////    Y > 80
////    85 < Cb <135
////    135 < Cr < 180,
//    
////    splitycbcr[0] = self.ySlider.value;
////    splitycbcr[1] = self.crSlider.value;
////    splitycbcr[2] = self.cbSlider.value;
//    
////    NSLog(@"Test: %a", splitycbcr[0]);
//    
//    Mat YCrCb_merged;
//    merge(YCrCb_planes, 3, YCrCb_merged);
//    
//    YCrCb_merged.copyTo(image);
    
    
    
    
    // Convert to HSV
//    cvtColor(image, image, CV_BGR2HSV);
//    // Create mask for HSV image thresholds
//    Mat mask;
//    
//    // Hue (angle, 0-180), Saturation (intensity of color, 0-255), Value (brightness, 0-100)
//    Scalar lower = Scalar(0, 15, 120);
//    Scalar upper = Scalar(33, 250, 255);
//    
//    // Apply HSV thresholds for skin color
//    inRange(image, lower, upper, mask);
//    
//    // Convert original image back to RGB
//    cvtColor(image, image, CV_HSV2RGB);
//    
//    // Erode THEN dilate to remove noise from HSV mask
//    erode(mask, mask, getStructuringElement(MORPH_RECT, cvSize(3, 3)));
//    dilate(mask, mask, getStructuringElement(MORPH_RECT, cvSize(3, 3)));
//    
//    // Find contours
//    std::vector<std::vector<cv::Point> > contours;
//    cv::findContours(mask, contours, cv::RETR_LIST, cv::CHAIN_APPROX_NONE);
//    
//    // Retreive largest contour
//    double largestContour = 0;
//    int largestIndex = 0;
//    for(int i=0; i<contours.size(); i++){
//        if(contours[i].size() > largestContour){
//            largestContour = contours[i].size();
//            largestIndex = i;
//        }
//    }
//    
//    // Draw largest contour (if exists)
//    if(!contours.empty()){
//        cv::drawContours(image, contours, largestIndex, Scalar(255, 0, 0));
//        cv::Rect brect = cv::boundingRect(contours[largestIndex]);
//        cv::rectangle(image, brect, Scalar(255, 0, 0));
//    }
    
    
    
//    
//    // Face detection (THIS USES ALOT OF CPU - 160+%)
//
    //Add one frame
    totalFrames++;
//
    
    
    
    
    
    
    
//    Mat hsv;
//    cvtColor(image, hsv, COLOR_BGR2HSV);
//    
// 
//    
//
//    faceDetector.detectMultiScale(hsv, faces);
//    Scalar color = Scalar(0, 255, 0);
//    for (int i = 0; i < faces.size(); i++) {
//        rectangle(image, faces[i], color, 1);
//    }
    
//    Mat gray;
//    std::vector<cv::Rect> faces;
//    Scalar color = Scalar(0, 255, 0);
//    cvtColor(image, gray, COLOR_BGR2GRAY);
//    faceDetector.detectMultiScale(gray, faces, 1.15, 2, 0, cv::Size(30, 30));
//    for (int i = 0; i < faces.size(); i++) {
//        rectangle(image, faces[i], color, 1);
//    }
    
//    std::vector<cv::Rect> faces;
//    faceDetector.detectMultiScale(img, faces, 1.1, 2, 0|CV_HAAR_SCALE_IMAGE, cv::Size(30, 30));
    
//    for(int i=0; i<faces.size(); ++i){
//        cv::Point center(faces[i].x +)
//    }
//    [self setupFaceDectector];
  
//    if(!faceDetector.empty()){
//    NSString *path = [[NSBundle mainBundle] pathForResource:@"haarcascade_frontalface_default" ofType:@"xml"];
//    const char *filePath = [path cStringUsingEncoding:NSUTF8StringEncoding];
//    //    faceDetector.load("/Users/markodjordjevic/Downloads/opencv-master/data/haarcascades_cuda/haarcascade_frontalface_default.xml");
//    
//    CascadeClassifier faceDetector;
//    if(faceDetector.load(filePath)){
    
    
//    if(faceDetector.load(filePath)){
    
//    Mat gray;
//    std::vector<cv::Rect> faces;
//    Scalar color = Scalar(0, 255, 0);
//    cvtColor(image, gray, COLOR_BGR2GRAY);
//    faceDetector.detectMultiScale(gray, faces, 1.15, 2, 0, cv::Size(30, 30));
//    for (int i = 0; i < faces.size(); i++) {
//        rectangle(image, faces[i], color, 1);
//    }
    
    
//    faces.clear();

    
    
    
//    cv::Mat img, fgmask;
//    cv::Ptr<cv::BackgroundSubtractor> bg_model;
//    bg_model = createBackgroundSubtractorMOG2();
//    bool update_bg_model;
//    
//    cv:cvtColor(image, img, cv::COLOR_BGRA2RGB);
//    int fixedWidth = 270;
//    cv::resize(img, img, cv::Size(fixedWidth,(int)((fixedWidth*1.0f)*   (image.rows/(image.cols*1.0f)))),cv::INTER_NEAREST);
//    
//    //update the model
//    bg_model->apply(img, fgmask, update_bg_model ? -1 : 0);
//    
//    GaussianBlur(fgmask, fgmask, cv::Size(7, 7), 2.5, 2.5);
//    threshold(fgmask, fgmask, 10, 255, cv::THRESH_BINARY);
//    
//    image = cv::Scalar::all(0);
//    img.copyTo(image, fgmask);
//    
//    bg_model->getBackgroundImage(image);
    
    
//    image.copyTo(image, fgmask);
    
    
    
    
//    bg->apply(fgmask, image);
//    
//    image.copyTo(image, fgmask);
    
    
    
//    Mat bgMask;
//    Mat fgMask;
//    Mat img;
//    
//    Ptr<BackgroundSubtractorMOG2> bg;
//    bg = createBackgroundSubtractorMOG2(40);
//    bool update_bg_model;
//    
////    cvtColor(image, image, CV_BGRA2RGB);
////    
////    bg->apply(image,fgMask,update_bg_model ? -1 : 0);
////    GaussianBlur(fgMask, fgMask, cv::Size(7, 7), 2.5, 2.5);
////    
////    threshold(fgMask,fgMask,10, 255, THRESH_BINARY);
////    
////    image=cv::Scalar::all(0);
////    image.copyTo(image, fgMask);
//    
//    cvtColor(image, img, CV_BGRA2RGB);
//    
//    bg->apply(img, fgMask);
//    
//    img.copyTo(image, fgMask);
//    bg_model = createBackgroundSubtractorMOG2(40);
//    
//    bg_model->apply(image, fgmask);
//    
//    Mat foreground = Mat::zeros(image.rows, image.cols, image.type());
//    image.copyTo(foreground, fgmask);
    
//    
//    cv::cvtColor(image, img, cv::COLOR_BGRA2RGB);
//    int fixedWidth = 270;
//    cv::resize(img, img, cv::Size(fixedWidth,(int)((fixedWidth*1.0f)*   (image.rows/(image.cols*1.0f)))),cv::INTER_NEAREST);
//    
//    bg_model->apply(img, fgmask);
//    GaussianBlur(fgmask, fgmask, cv::Size(7, 7), 2.5, 2.5);
//    threshold(fgmask, fgmask, 10, 255, cv::THRESH_BINARY);
//    
//    image = cv::Scalar::all(0);
//    img.copyTo(image, fgmask);
//    image.copyTo(image,fgmask);
    
    
    
    

    
    
    
//    Mat gray;
//    
//    cvtColor(image, gray, CV_BGR2GRAY);
//    
//    Mat blur;
//    
//    GaussianBlur(gray, blur, cv::Size(5, 5), 0);
//    
//    threshold(blur, image, 0, 33, THRESH_BINARY_INV+THRESH_OTSU);
//    
////     Convert to HSV
//    cvtColor(image, image, CV_BGR2HSV);
////     Create mask for HSV image thresholds
//    Mat mask;
//    
////     Hue (angle, 0-180), Saturation (intensity of color, 0-255), Value (brightness, 0-100)
//    Scalar lower = Scalar(0, 15, 120);
//    Scalar upper = Scalar(33, 250, 255);
//    Scalar lower = Scalar(self.lowerHueSlider.value,
//                          self.lowerSatSlider.value,
//                          self.lowerValSlider.value);
//    Scalar upper = Scalar(self.upperHueSlider.value,
//                          self.upperSatSlider.value,
//                          self.upperValSlider.value);
    
//    self.hueLabel.text = [NSString stringWithFormat:@"HUE (MIN:%MAX:%)", self.lowerHueSlider.value, self.upperHueSlider];
    
    
//    // Apply HSV thresholds for skin color
//    inRange(image, lower, upper, mask);
//    inRange(image, lower, upper, image);
    
    // Testing slider values
////    NSLog(@"LOWERSliderValue ... %d",(int)[self.lowerHueSlider value]);
////    NSLog(@"UPPERSliderValue ... %d",(int)[self.upperHueSlider value]);
//    
//    // Convert original image back to RGB
//    cvtColor(image, image, CV_HSV2RGB);
//
//    // Erode THEN dilate to remove noise from HSV mask
//    erode(mask, mask, getStructuringElement(MORPH_RECT, cvSize(3, 3)));
//    dilate(mask, mask, getStructuringElement(MORPH_RECT, cvSize(3, 3)));
//    
//    // Find contours
//    std::vector<std::vector<cv::Point> > contours;
//    cv::findContours(mask, contours, cv::RETR_LIST, cv::CHAIN_APPROX_NONE);
//    cv::findContours(image, contours, cv::RETR_LIST, cv::CHAIN_APPROX_NONE);
    
    // Find the largest contour and draw it
//    int index = [self findLargestContour:contours];
//    [self drawLargestContour:image :contours :index];
    
    
    
    
    
    
    
    
    
    
    
    
    // Convex Hull
//    std::vector<std::vector<Vec4i>> defects;
//    std::vector<std::vector<int>> hull(contours.size());
//    std::vector<std::vector<int>> hullsI(contours.size());
//    std::vector<std::vector<cv::Point>> hullsP(contours.size());
////
////    
////    
////    
////    // Retreive largest contour
//    double largestContour = 0;
//    int largestIndex = 0;
//    for(int i=0; i<contours.size(); i++){
//        if(contours[i].size() > largestContour){
//            largestContour = contours[i].size();
//            largestIndex = i;
//        }
//        convexHull(contours[i], hullsI[i], false);
//        convexHull(contours[i], hullsP[i], false);
//    }
//
//   
//    
//  
//    
//    
//    
//    // Draw largest contour (if exists)
//    if(!contours.empty()){
//        cv::drawContours(image, contours, largestIndex, Scalar(255, 0, 0));
//        cv::Rect brect = cv::boundingRect(contours[largestIndex]);
//        cv::rectangle(image, brect, Scalar(255, 0, 0));
//        cv::drawContours(image, hullsP, largestIndex, Scalar(255, 255, 0));
////        cv::drawContours(image, hull, largestIndex, Scalar(255, 255, 0));
////
////        
//////        
//    }
//    if(!hull.empty()){
//       
//    }
    
}

//- (int)findLargestContour:(std::vector<std::vector<cv::Point>>)contours;
//{
//    double largestContour = 0;
//    int indexOfLargestContour = -1;
//    for(int i=0; i<contours.size();++i){
//        if(contours[i].size() > largestContour){
//            largestContour = contours[i].size();
//            indexOfLargestContour = i;
//        }
//    }
//    return indexOfLargestContour;
//}
//
//- (void)drawLargestContour:(cv::Mat)image :(std::vector<std::vector<cv::Point>>)contours :(int)largestContourIndex;
//{
//    if(contours.empty()){
//        return;
//    }
//    Scalar color = Scalar(255, 0, 0);
//    cv::drawContours(image, contours, largestContourIndex, color);
//    cv::Rect brect = cv::boundingRect(contours[largestContourIndex]);
//    cv::rectangle(image, brect, color);
//}

-(void)faceDetection:(cv::Rect &)sample :(cv::Mat &)image{
        try{
            if(cascadeLoad && !image.empty()){
                int largestFaceArea = 0;
                int largestFaceIndex = 0;
                vector<cv::Rect> faces;
                faceDetector.detectMultiScale(image, faces, 1.2, 2, 0, cv::Size(50, 50));
                
                for (int i = 0; i < faces.size(); i++) {
                    int area = faces[i].area();
                    if(area > largestFaceArea){
                        largestFaceArea = area;
                        largestFaceIndex = i;
                    }
                }
                
                if(!faces.empty()){
                    Scalar outerRectColor = Scalar(0, 255, 0);
                    Scalar innerRectColor = Scalar(150, 150, 0);
                    // Draw outer rectangle
                    rectangle(image, faces[largestFaceIndex], outerRectColor, 1);
                    // Draw innner rectangle
                    sample = cv::Rect(faces[largestFaceIndex].x + 0.25*faces[largestFaceIndex].width,
                                          faces[largestFaceIndex].y + 0.25*faces[largestFaceIndex].height,
                                          0.5*faces[largestFaceIndex].width,
                                          0.5*faces[largestFaceIndex].height);
                    rectangle(image, sample, innerRectColor, 1);
                }
            }
        } catch (cv::Exception e) {
            NSLog(@"FACE DETECTION ERROR: CASCADE FILES NOT LOADED");
        }
}

- (IBAction)sampleButtonPressed:(id)sender {
    currentState = HAND;
    
    // Analyse pixels of inner rect sample
}

@end
