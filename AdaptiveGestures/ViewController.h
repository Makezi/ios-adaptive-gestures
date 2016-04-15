//
//  ViewController.h
//  AdaptiveGestures
//
//  Created by Marko Djordjevic on 13/04/2016.
//  Copyright © 2016 Marko Djordjevic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <opencv2/videoio/cap_ios.h>
#import <opencv2/imgproc.hpp>
#import "VideoCamera.h"

using namespace cv;

@interface ViewController : UIViewController<VideoCameraDelegate> {
    VideoCamera* camera;
}

@property (nonatomic, strong) VideoCamera* camera;
@property (weak, nonatomic) IBOutlet UIImageView* imageView;
@property (weak, nonatomic) IBOutlet UISlider *lowerHueSlider;
@property (weak, nonatomic) IBOutlet UISlider *upperHueSlider;
@property (weak, nonatomic) IBOutlet UISlider *lowerDilationSlider;
@property (weak, nonatomic) IBOutlet UISlider *upperDilationSlider;

@end

