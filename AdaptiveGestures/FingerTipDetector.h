//
// Created by Marko Djordjevic on 7/06/2016.
// Copyright (c) 2016 Marko Djordjevic. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <opencv2/videoio/cap_ios.h>
#import <opencv2/imgproc.hpp>
#import <opencv2/highgui.hpp>
#import <opencv2/video.hpp>
#import "FaceDetector.h"

using namespace std;
using namespace cv;

enum AppState { FACE_SAMPLE, HAND_SAMPLE, DETECT };
enum ImageState { NORMAL, SKIN };

@interface FingerTipDetector : NSObject {
    AppState appState;
    ImageState imageState;

    FaceDetector *detector;

    MatND skinHist;
    int channels[2];
    float hueRange[2];
    float satRange[2];
    const float *ranges[2];
    int hueBins;
    int satBins;
    int erosion;
    int dilation;

    std::vector<Mat> handROIs;
    std::vector<MatND> skinHists;

    std::vector<std::vector<cv::Point>> contours;
    int largestContourIndex;

    cv::Rect bRect;

    std::vector<std::vector<cv::Point>> hullsP;
    std::vector<std::vector<int>> hullsI;
    std::vector<std::vector<Vec4i>> defects;

    std::vector<cv::Point> fingerTips;
    std::vector<cv::Point> depthPoints;

    cv::Point2f palmCenter;
}

/* Initialises variables */
-(id)init;

/* Performs operations on images captured */
-(void)processImage:(Mat &) image;

/* Creates a ROI from the given detected face */
-(Mat)createFaceROI:(Mat) srcImage :(cv::Rect) face;

/* Creates 7 ROIs for hand skin sampling method */
-(void)createHandROI:(Mat) srcImage;

/* Calculates a histogram of passed image with adjustable HUE and SATURATION channels */
-(cv::MatND)getHistogram:(Mat) image;

/* Finds contours in an image */
-(void)createContours:(Mat) srcImage;

/* Finds the largest contour and returns its index */
-(void)findLargestContourIndex;

/* Draws the largest contour */
-(void)drawLargestContour:(Mat) outputImage;

/* Creates a bounding box around found contours */
-(void)createBoundingBox;

/* Draws the bounding box */
-(void)drawBoundingBox:(Mat) outputImage;

/* Detect if a hand exists within the bounding box */
-(bool)isHand:(Mat) srcImage;

/* Creates convex hulls for contours found and find convexity defects */
-(void)createConvexHulls;

/* Draw convex hulls found */
-(void)drawConvexHulls:(Mat) outputImage;

/* Create finger tips from convexity defects found */
-(void)createFingerTips:(Mat) srcImage;

/* Determine if points is close to the boundary box */
-(bool)isPointCloseToBoundary:(cv::Point) pt;

/* Check if only one finger exists */
-(void)checkForOneFinger:(Mat) srcImage;

/* Remove fingers that are close to each other */
-(void)removeFalseFingerTips;

/* Get the distance between two points */
-(float)distanceBetweenPoints:(cv::Point) pt1 :(cv::Point) pt2;

/* Draw the finger tips */
-(void)drawFingerTips:(Mat) outputImage;

/* Create the palm using minimum enclosing circle from depth points */
-(void)createPalm;

/* Getter and Setter for HUE bins */
-(void)setHueBins:(int) hue;
-(int)hueBins;

/* Getter and Setter for SATURATION bins */
-(void)setSatBins:(int) sat;
-(int)satBins;

/* Getter and Setter for erosion */
-(void)setErosion:(int) theErosion;
-(int)erosion;

/* Getter and Setter for dilation */
-(void)setDilation:(int) theDilation;
-(int)dilation;

/* Getter and Setter for app state */
-(void)setAppState:(AppState) theAppState;
-(AppState)appSate;

/* Getter and Setter for image state */
-(void)setImageState:(ImageState) theImageState;
-(ImageState)imageState;

@end