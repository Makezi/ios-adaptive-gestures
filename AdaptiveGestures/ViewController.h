//
//  ViewController.h
//  AdaptiveGestures
//
//  Created by Marko Djordjevic on 13/04/2016.
//  Copyright © 2016 Marko Djordjevic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <opencv2/videoio/cap_ios.h>
#import <opencv2/objdetect/objdetect.hpp>
#import <opencv2/imgproc.hpp>
#import <opencv2/highgui.hpp>
#import <opencv2/video.hpp>
#import "VideoCamera.h"

using namespace cv;
using namespace std;

enum State { FACE, HAND, DETECT };
enum ImageState { NORMAL, SKIN };

@interface ViewController : UIViewController<VideoCameraDelegate> {
    VideoCamera* camera;
    CascadeClassifier faceDetector;
    MatND skinHist;
    int totalFrames;
    bool cascadeLoad;
    State state;
    ImageState imageState;
    vector<vector<cv::Point>> contours;
    vector<vector<cv::Point>> hullsP;
    vector<vector<int>> hullsI;
    vector<vector<Vec4i>> defects;
    int largestContourIndex;
    
    std::vector<cv::Mat> roiMat;
    std::vector<MatND> skinHists;
    
    std::vector<cv::Point> fingerTips;
    
    cv::Rect bRect;
}

@property (nonatomic, strong) VideoCamera* camera;
@property (weak, nonatomic) IBOutlet UIImageView* cameraView;
@property (weak, nonatomic) IBOutlet UILabel *fpsLabel;
@property (weak, nonatomic) IBOutlet UIButton *sampleSkinButton;
@property (weak, nonatomic) IBOutlet UISlider *hueSlider;
@property (weak, nonatomic) IBOutlet UILabel *hueLabel;
@property (weak, nonatomic) IBOutlet UISlider *satSlider;
@property (weak, nonatomic) IBOutlet UILabel *satLabel;
@property (weak, nonatomic) IBOutlet UISlider *dilateSlider;
@property (weak, nonatomic) IBOutlet UILabel *dilateLabel;
@property (weak, nonatomic) IBOutlet UISlider *erodeSlider;
@property (weak, nonatomic) IBOutlet UILabel *erodeLabel;
@property (weak, nonatomic) IBOutlet UISegmentedControl *imageControl;
@property (weak, nonatomic) IBOutlet UISegmentedControl *stateControl;

@end

