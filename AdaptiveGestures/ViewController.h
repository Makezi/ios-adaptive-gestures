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

@interface ViewController : UIViewController<VideoCameraDelegate> {
    VideoCamera* camera;
    CascadeClassifier faceDetector;
}

enum State { FACE, HAND };

@property (nonatomic, strong) VideoCamera* camera;
@property (weak, nonatomic) IBOutlet UIImageView* imageView;
@property (weak, nonatomic) IBOutlet UILabel *fps;
@property (weak, nonatomic) IBOutlet UIButton *sampleSkinButton;

@end

