//
// Created by Marko Djordjevic on 7/06/2016.
// Copyright (c) 2016 Marko Djordjevic. All rights reserved.
//

#import "FingerTipDetector.h"

@implementation FingerTipDetector

-(id)init {
    if ( self = [super init] ) {
        // Set default states
        appState = FACE_SAMPLE;
        imageState = NORMAL;

        // Load face detector
        detector = [[FaceDetector alloc] init];
        [detector loadCascade];

        // Set default values for HSV histogram
        channels[0] = {0}; channels[1] = {1};
        hueRange[0] = {0}; hueRange[1] = {179};
        satRange[0] = {0}; satRange[1] = {255};
        ranges[0] = {hueRange}; ranges[1] = {satRange};
        hueBins = 4;
        satBins = 4;
        erosion = 1;
        dilation = 1;
    }
    return self;
}

-(void)processImage:(Mat &) image {

    switch(appState){
        case FACE_SAMPLE:
        {
            // Create grayscale image and then improve global contrast by histogram equalization
            Mat grayImage;
            cvtColor(image, grayImage, CV_BGR2GRAY);
            equalizeHist(grayImage, grayImage);

            // Detect face and retrieve face ROI
            cv::Rect face = [detector detectFace:(grayImage):(image)];
            Mat faceROIImage = [self createFaceROI:(image):(face)];

            // Convert ROI to HSV
            Mat roiHSV;
            cvtColor(faceROIImage, roiHSV, CV_BGR2HSV);

            // Get histogram of the ROI
            skinHist = [self getHistogram:(roiHSV)];

            break;
        }
        case HAND_SAMPLE:
        {
            skinHists.clear();

            // Create hand ROIs
            [self createHandROI:(image)];

            // Get histogram for all hand ROIs
            for(int i = 0; i < handROIs.size(); i++){
                Mat roiHSV;
                cvtColor(handROIs[i], roiHSV, CV_BGR2HSV);
                skinHists.push_back([self getHistogram:(roiHSV)]);
            }

            // Merge all histograms into one skin colour model
            cv::merge(skinHists, skinHist);

            break;
        }
        case DETECT:
            break;
        default:
            break;
    }

    // If the generated skin colour histogram model is empty, return
    if(skinHist.empty()) return;

    // Convert image to HSV for back projection
    Mat hsvImage;
    cvtColor(image, hsvImage, CV_BGR2HSV);

    // Separate HUE channel to be used for the histogram in back projection
    Mat hueImage;
    hueImage.create(hsvImage.size(), hsvImage.depth());
    int ch[] = {0, 0};
    mixChannels(&hsvImage, 1, &hueImage, 1, ch, 1);

    // Normalize the skin colour histogram
    normalize(skinHist, skinHist, 0, 255, NORM_MINMAX, -1, Mat());

    // Calculate a back projection of the hue image
    Mat backProjectionImage;
    calcBackProject(&hsvImage, 1, channels, skinHist, backProjectionImage, ranges, 1, true);

    // Blur the back projection
    medianBlur(backProjectionImage, backProjectionImage, 9);

    // Convert back projection to binary image
    Mat binary;
    threshold(backProjectionImage, binary, 0, 255, THRESH_BINARY + THRESH_OTSU);

    // Erode and dilate the binary image for noise reduction
    erode(binary, binary, getStructuringElement(MORPH_RECT, cvSize(erosion, erosion)));
    dilate(binary, binary, getStructuringElement(MORPH_RECT, cvSize(dilation, dilation)));

    switch(imageState){
        case NORMAL:
        {
            if(appState == DETECT){
                [self createContours:(binary)];
                [self drawLargestContour:(image)];
                [self createBoundingBox];
                [self drawBoundingBox:(image)];
                if([self isHand:(image)]){
                    [self createConvexHulls];
                    [self drawConvexHulls:(image)];
                    [self createFingerTips:(image)];
                    [self createPalm];
                    [self drawFingerTips:(image)];
                }
            }
            break;
        }
        case SKIN:
            binary.copyTo(image);
            break;
        default:
            break;
    }
}

-(Mat)createFaceROI:(Mat) srcImage :(cv::Rect) face {
    // Centre of face
    float topLeft_X = face.x + 0.25 * face.width;
    float topLeft_Y = face.y + 0.25 * face.height;
    float bottomRight_X = topLeft_X + 0.5 * face.width;
    float bottomRight_Y = topLeft_Y + 0.5 * face.height;

    // Forehead
//    float topLeft_X = face.x + face.width / 4;
//    float topLeft_Y = face.y + face.height / 16;
//    float bottomRight_X = topLeft_X + face.width / 2;
//    float bottomRight_Y = topLeft_Y + face.height / 6;

    // Create topLeft and bottomRight points
    cv::Point roiPoint1(topLeft_X, topLeft_Y);
    cv::Point roiPoint2(bottomRight_X, bottomRight_Y);

    // Create our roi image
    cv::Rect roiRect = cv::Rect(topLeft_X, topLeft_Y, bottomRight_X - topLeft_X, bottomRight_Y - topLeft_Y);
    Mat roi = srcImage(roiRect);

    // Draw a rectangle around the ROI
    Scalar color = Scalar(0, 0, 255); // Green
    rectangle(srcImage, roiRect, color, 2);

    return roi;
}

-(void)createHandROI:(Mat) srcImage {
    handROIs.clear();
    int squareLen = 20;
    Scalar color = Scalar(0, 0, 255); // Red

    // ROI 1
    cv::Point roi1Point1(srcImage.cols*0.5, srcImage.rows*0.3);
    cv::Point roi1Point2(srcImage.cols*0.5+squareLen, srcImage.rows*0.3+squareLen);
    cv::Rect roi1Rect = cv::Rect(cv::Rect(roi1Point1.x, roi1Point1.y, roi1Point2.x - roi1Point1.x, roi1Point2.y - roi1Point1.y));
    rectangle(srcImage, roi1Rect, color, 2, 8, 0);
    Mat roi1Mat = srcImage(roi1Rect);

    // ROI 2
    cv::Point roi2Point1(srcImage.cols*0.5, srcImage.rows*0.5);
    cv::Point roi2Point2(srcImage.cols*0.5+squareLen, srcImage.rows*0.5+squareLen);
    cv::Rect roi2Rect = cv::Rect(roi2Point1.x, roi2Point1.y, roi2Point2.x - roi2Point1.x, roi2Point2.y - roi2Point1.y);
    rectangle(srcImage, roi2Rect, color, 2, 8, 0);
    Mat roi2Mat = srcImage(roi2Rect);

    // ROI 3
    cv::Point roi3Point1(srcImage.cols*0.4, srcImage.rows*0.4);
    cv::Point roi3Point2(srcImage.cols*0.4+squareLen, srcImage.rows*0.4+squareLen);
    cv::Rect roi3Rect = cv::Rect(roi3Point1.x, roi3Point1.y, roi3Point2.x - roi3Point1.x, roi3Point2.y - roi3Point1.y);
    rectangle(srcImage, roi3Rect, color, 2, 8, 0);
    Mat roi3Mat = srcImage(roi3Rect);

    // ROI 4
    cv::Point roi4Point1(srcImage.cols*0.6, srcImage.rows*0.4);
    cv::Point roi4Point2(srcImage.cols*0.6+squareLen, srcImage.rows*0.4+squareLen);
    cv::Rect roi4Rect = cv::Rect(roi4Point1.x, roi4Point1.y, roi4Point2.x - roi4Point1.x, roi4Point2.y - roi4Point1.y);
    rectangle(srcImage, roi4Rect, color, 2, 8, 0);
    Mat roi4Mat = srcImage(roi4Rect);

    // ROI 5
    cv::Point roi5Point1(srcImage.cols*0.4, srcImage.rows*0.6);
    cv::Point roi5Point2(srcImage.cols*0.4+squareLen, srcImage.rows*0.6+squareLen);
    cv::Rect roi5Rect = cv::Rect(roi5Point1.x, roi5Point1.y, roi5Point2.x - roi5Point1.x, roi5Point2.y - roi5Point1.y);
    rectangle(srcImage, roi5Rect, color, 2, 8, 0);
    Mat roi5Mat = srcImage(roi5Rect);

    // ROI 6
    cv::Point roi6Point1(srcImage.cols*0.6, srcImage.rows*0.6);
    cv::Point roi6Point2(srcImage.cols*0.6+squareLen, srcImage.rows*0.6+squareLen);
    cv::Rect roi6Rect = cv::Rect(roi6Point1.x, roi6Point1.y, roi6Point2.x - roi6Point1.x, roi6Point2.y - roi6Point1.y);
    rectangle(srcImage, roi6Rect, color, 2, 8, 0);
    Mat roi6Mat = srcImage(roi6Rect);

    // ROI 7
    cv::Point roi7Point1(srcImage.cols*0.3, srcImage.rows*0.5);
    cv::Point roi7Point2(srcImage.cols*0.3+squareLen, srcImage.rows*0.5+squareLen);
    cv::Rect roi7Rect = cv::Rect(roi7Point1.x, roi7Point1.y, roi7Point2.x - roi7Point1.x, roi7Point2.y - roi7Point1.y);
    rectangle(srcImage, roi7Rect, color, 2, 8, 0);
    Mat roi7Mat = srcImage(roi7Rect);

    handROIs.push_back(roi1Mat);
    handROIs.push_back(roi2Mat);
    handROIs.push_back(roi3Mat);
    handROIs.push_back(roi4Mat);
    handROIs.push_back(roi5Mat);
    handROIs.push_back(roi6Mat);
    handROIs.push_back(roi7Mat);
}

-(cv::MatND)getHistogram:(cv::Mat) image {
    cv::MatND hist;
    int histSize[] = { hueBins, satBins };
    cv::calcHist(&image, 1, channels, Mat(), hist, 2, histSize, ranges);
    return hist;
}

-(void)createContours:(Mat) srcImage {
    // Find contours in the source image
    contours.clear();
    findContours(srcImage, contours, CV_RETR_EXTERNAL, CV_CHAIN_APPROX_NONE);

    // Return if no contours found
    if(contours.size() == 0) return;

    // Find the index of the largest contour and return if none were found
    [self findLargestContourIndex];
    if(largestContourIndex == -1) return;
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

-(void)drawLargestContour:(Mat) outputImage {
    Scalar color = Scalar(0, 0, 255); // Red
    drawContours(outputImage, contours, largestContourIndex, color, 2);
}

-(void)createBoundingBox {
    // Create bounding box around the largest contour if it exists
    if(contours.size() == 0 || largestContourIndex == -1) return;
    bRect = boundingRect(Mat(contours[largestContourIndex]));
}

/* Draws the bounding box */
-(void)drawBoundingBox:(Mat) outputImage {
    Scalar color = Scalar(255, 255, 255); // White
    rectangle(outputImage, bRect, color, 2);
}

-(bool)isHand:(Mat) srcImage {
    int centerX = 0;
    int centerY = 0;
    if(bRect.area() > 0){
        centerX = bRect.x + bRect.width / 2;
        centerY = bRect.y + bRect.height / 2;
    }

    if(largestContourIndex == -1) return false;
    if(bRect.area() <= 0) return false;
    if(bRect.height == 0 || bRect.width == 0) return false;
    if(centerX < srcImage.cols / 4 || centerX > srcImage.cols * 3 / 4) return false;
    return true;
}

-(void)createConvexHulls {
    // Initialise vectors if contours exists
    if(contours.size() == 0 || largestContourIndex == -1) return;
    hullsP = std::vector<std::vector<cv::Point>>(contours.size());
    hullsI = std::vector<std::vector<int>>(contours.size());
    defects = std::vector<std::vector<Vec4i>>(contours.size());

    // Find convex hulls
    convexHull(Mat(contours[largestContourIndex]), hullsP[largestContourIndex], false, true);
    convexHull(Mat(contours[largestContourIndex]), hullsI[largestContourIndex], false, false);

    // Find convexity defects within the hulls
    if(contours[largestContourIndex].size() > 3){
        convexityDefects(contours[largestContourIndex], hullsI[largestContourIndex], defects[largestContourIndex]);
    }

    // Smooth out hulls
    approxPolyDP(Mat(hullsP[largestContourIndex]), hullsP[largestContourIndex], 18, true);
}

-(void)drawConvexHulls:(Mat) outputImage {
    if(hullsP.empty()) return;
    Scalar color = Scalar(255, 255, 0); // Cyan
    drawContours(outputImage, hullsP, largestContourIndex, color, 2);
}

-(void)createFingerTips:(Mat) srcImage {
    fingerTips.clear();
    depthPoints.clear();

    // Loop through defects to find finger tips
    for(int i = 0; i < contours.size(); i++){
        for(const Vec4i& v : defects[i]){
            float depth = v[3] / 256;

            // Only worry about defect points with depth larger than 20
            if(depth > 20 && i == largestContourIndex){
                int startIndex = v[0];
                cv::Point ptStart(contours[i][startIndex]);
                int endIndex = v[1];
                cv::Point ptEnd(contours[i][endIndex]);
                int farIndex = v[2];
                cv::Point ptFar(contours[i][farIndex]);

                // Only insert a maximum of 5 finger tips
                if(fingerTips.size() <= 5){
                    fingerTips.push_back(ptEnd);
                }

                // Store depth points (for palm tracking)
                if(![self isPointCloseToBoundary:(ptFar)]){
                    depthPoints.push_back(ptFar);
                }
            }
        }
    }

    // Check for one finger
    if(fingerTips.size() == 0){
        [self checkForOneFinger:(srcImage)];
    }

    [self removeFalseFingerTips];
}

-(bool)isPointCloseToBoundary:(cv::Point) pt {
    int margin = 10;
    if(pt.x > (bRect.br().x - margin)) return true;
    if(pt.x < (bRect.tl().x + margin)) return true;
    if(pt.y > (bRect.br().y - margin)) return true;
    if(pt.y < (bRect.tl().y + margin)) return true;
    return false;
}

-(void)checkForOneFinger:(Mat) srcImage {
    int yTolerance = bRect.height / 6;
    cv::Point highestPt;
    highestPt.y = srcImage.rows;
    std::vector<cv::Point>::iterator d = contours[largestContourIndex].begin();

    // Loop through all the points in contours found
    while(d != contours[largestContourIndex].end()){
        cv::Point v = (*d);
        if(v.y < highestPt.y){
            highestPt = v;
        }
        d++;
    }

    // See if there's only one point within the convex hull
    int n = 0;
    d = hullsP[largestContourIndex].begin();
    while(d != hullsP[largestContourIndex].end()) {
        cv::Point v = (*d);
        if (v.y < highestPt.y + yTolerance && v.y != highestPt.y && v.x != highestPt.x) {
            n++;
        }
        d++;
    }
    if(n == 0){
        fingerTips.push_back(highestPt);
    }
}

-(void)removeFalseFingerTips {
    if(fingerTips.size() == 0) return;

    // Loop through all finger tips found and remove and finger tips if they're close together
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
    return sqrt(fabs(pow(pt1.x - pt2.x, 2) + pow(pt2.y - pt2.y, 2)));
}

-(void)drawFingerTips:(Mat) outputImage {
    if(fingerTips.size() == 0) return;
    Scalar color = Scalar(255, 0, 0); // Blue
    for(int i = 0; i < fingerTips.size(); i++){
        if([self distanceBetweenPoints:(fingerTips[i]):(palmCenter)] > 100){
            circle(outputImage, fingerTips[i], 10, color, 2);
        }
    }
}

-(void)createPalm {
    if(depthPoints.empty()) return;
    float radius;
    minEnclosingCircle(depthPoints, palmCenter, radius);
}

-(void)setHueBins:(int) hue {
    hueBins = hue;
}

-(int)hueBins {
    return hueBins;
}

-(void)setSatBins:(int) sat {
    satBins = sat;
}

-(int)satBins {
    return satBins;
}

-(void)setErosion:(int) theErosion {
    erosion = theErosion;
}

-(int)erosion {
    return erosion;
}

-(void)setDilation:(int) theDilation {
    dilation = theDilation;
}
-(int)dilation{
    return dilation;
}

-(void)setAppState:(AppState) theAppState {
    appState = theAppState;
}

-(AppState)appSate {
    return appState;
}

-(void)setImageState:(ImageState) theImageState {
    imageState = theImageState;
}

-(ImageState)imageState{
    return imageState;
}

@end