//
//  ViewController.h
//  AdaptiveGestures
//
//  Created by Marko Djordjevic on 13/04/2016.
//  Copyright © 2016 Marko Djordjevic. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "VideoCamera.h"
#import "FaceDetector.h"
#import "FingerTipDetector.h"

using namespace cv;
using namespace std;

@interface ViewController : UIViewController<VideoCameraDelegate> {
    VideoCamera *camera;
    FaceDetector *detector;
    FingerTipDetector *ftd;
    int totalFrames;
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

