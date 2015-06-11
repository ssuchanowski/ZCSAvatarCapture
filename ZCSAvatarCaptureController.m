//
//  ZCSAvatarCaptureController.m
//  ZCSAvatarCaptureDemo
//
//  Created by Zane Shannon on 8/27/14.
//  Copyright (c) 2014 Zane Shannon. All rights reserved.
//

@import AVFoundation;

#import "ZCSAvatarCaptureController.h"

@interface ZCSAvatarCaptureController () {
    CGRect previousFrame;
    BOOL isCapturing;
}

@property (nonatomic, strong) UIImageView *avatarView;
@property (nonatomic, strong) UIView *captureView;
@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureStillImageOutput *stillImageOutput;
@property (nonatomic, strong) AVCaptureDevice *captureDevice;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;
@property (nonatomic, assign) BOOL isCapturingImage;
@property (nonatomic, strong) UIImageView *capturedImageView;
@property (nonatomic, strong) UIImagePickerController *picker;
@property (nonatomic, strong) UIView *imageSelectedView;
@property (nonatomic, strong) UIImage *selectedImage;

- (void)endCapture;

@end

@implementation ZCSAvatarCaptureController

- (void)viewDidLoad {
    [super viewDidLoad];
    isCapturing = NO;
    UITapGestureRecognizer *singleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(startCapture)];
    [self.view addGestureRecognizer:singleTapGestureRecognizer];
    self.avatarView = [[UIImageView alloc] initWithFrame:self.view.frame];
    self.avatarView.image = self.image;
    self.avatarView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.avatarView.contentMode = UIViewContentModeScaleAspectFill;
    self.avatarView.layer.masksToBounds = YES;
    self.avatarView.layer.cornerRadius = CGRectGetWidth(self.view.bounds) / 2;
    [self.view addSubview:self.avatarView];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    self.view.frame = self.view.superview.bounds;
    self.view.layer.cornerRadius = (CGFloat) (CGRectGetWidth(self.view.bounds) / 2.0);
    self.avatarView.layer.cornerRadius = (CGFloat) (CGRectGetWidth(self.view.bounds) / 2.0);
}

- (void)startCapture {
    if (isCapturing) return;
    isCapturing = YES;
    for (UIView *subview in [self.view.subviews copy]) {
        [subview removeFromSuperview];
    }
    previousFrame = [self.view convertRect:self.view.frame toView:nil];

    self.captureView = [[UIView alloc] initWithFrame:self.view.window.frame];
    [self.view.window addSubview:self.captureView];

    UIView *shadeView = [[UIView alloc] initWithFrame:self.captureView.frame];
    shadeView.alpha = 0.85f;
    shadeView.backgroundColor = [UIColor blackColor];
    [self.captureView addSubview:shadeView];

    self.captureSession = [[AVCaptureSession alloc] init];
    self.captureSession.sessionPreset = AVCaptureSessionPresetPhoto;

    self.capturedImageView = [[UIImageView alloc] init];
    self.capturedImageView.frame = previousFrame;
    self.capturedImageView.layer.cornerRadius = CGRectGetWidth(previousFrame) / 2;
    self.capturedImageView.layer.masksToBounds = YES;
    self.capturedImageView.backgroundColor = [UIColor clearColor];
    self.capturedImageView.userInteractionEnabled = YES;
    self.capturedImageView.contentMode = UIViewContentModeScaleAspectFill;

    self.captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];
    self.captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    self.captureVideoPreviewLayer.frame = previousFrame;
    self.captureVideoPreviewLayer.cornerRadius = CGRectGetWidth(self.captureVideoPreviewLayer.frame) / 2;
    [self.captureView.layer addSublayer:self.captureVideoPreviewLayer];

    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    if (devices.count > 0) {
        self.captureDevice = devices[0];
        for (AVCaptureDevice *device in devices) {
            if (device.position == AVCaptureDevicePositionFront) {
                self.captureDevice = device;
                break;
            }
        }

        NSError *error = nil;
        AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:self.captureDevice error:&error];

        if (input) {
            [self.captureSession addInput:input];

            self.stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
            NSDictionary *outputSettings = @{AVVideoCodecKey : AVVideoCodecJPEG};
            [self.stillImageOutput setOutputSettings:outputSettings];
            [self.captureSession addOutput:self.stillImageOutput];

            UIButton *shutterButton =
                    [[UIButton alloc] initWithFrame:CGRectMake(previousFrame.origin.x + (CGRectGetWidth(previousFrame) / 2) - 50, previousFrame.origin.y + CGRectGetHeight(previousFrame) + 10, 100, 100)];
            [shutterButton setImage:[UIImage imageNamed:@"PKImageBundle.bundle/take-snap"] forState:UIControlStateNormal];
            [shutterButton addTarget:self action:@selector(capturePhoto:) forControlEvents:UIControlEventTouchUpInside];
            [shutterButton setTintColor:[UIColor blueColor]];
            [shutterButton.layer setCornerRadius:20.0];
            [self.captureView addSubview:shutterButton];

            UIButton *swapCamerasButton =
                    [[UIButton alloc] initWithFrame:CGRectMake(previousFrame.origin.x, previousFrame.origin.y - 35, 47, 25)];
            [swapCamerasButton setImage:[UIImage imageNamed:@"PKImageBundle.bundle/front-camera"] forState:UIControlStateNormal];
            [swapCamerasButton addTarget:self action:@selector(swapCameras:) forControlEvents:UIControlEventTouchUpInside];
            [self.captureView addSubview:swapCamerasButton];
        }
    }

    UIButton *showImagePickerButton = [[UIButton alloc]
            initWithFrame:CGRectMake(previousFrame.origin.x + CGRectGetWidth(previousFrame) - 27, previousFrame.origin.y - 35, 27, 27)];
    [showImagePickerButton setImage:[UIImage imageNamed:@"PKImageBundle.bundle/library"] forState:UIControlStateNormal];
    [showImagePickerButton addTarget:self action:@selector(showImagePicker:) forControlEvents:UIControlEventTouchUpInside];
    [self.captureView addSubview:showImagePickerButton];

    UIButton *cancelButton = [[UIButton alloc] initWithFrame:CGRectMake(previousFrame.origin.x + (CGRectGetWidth(previousFrame) / 2) - 16,
            previousFrame.origin.y + CGRectGetHeight(previousFrame) + 120, 32, 32)];
    [cancelButton setImage:[UIImage imageNamed:@"PKImageBundle.bundle/cancel"] forState:UIControlStateNormal];
    [cancelButton addTarget:self action:@selector(cancel:) forControlEvents:UIControlEventTouchUpInside];
    [self.captureView addSubview:cancelButton];

    self.imageSelectedView = [[UIView alloc] initWithFrame:self.captureView.frame];
    [self.imageSelectedView setBackgroundColor:[UIColor clearColor]];
    [self.imageSelectedView addSubview:self.capturedImageView];

    UIView *overlayView = [[UIView alloc]
            initWithFrame:CGRectMake(0, previousFrame.origin.y + CGRectGetHeight(previousFrame), CGRectGetWidth(self.captureView.frame), 60)];
    [self.imageSelectedView addSubview:overlayView];
    UIButton *selectPhotoButton = [[UIButton alloc] initWithFrame:CGRectMake(previousFrame.origin.x, 0, 32, 32)];
    [selectPhotoButton setImage:[UIImage imageNamed:@"PKImageBundle.bundle/selected"] forState:UIControlStateNormal];
    [selectPhotoButton addTarget:self action:@selector(photoSelected:) forControlEvents:UIControlEventTouchUpInside];
    [overlayView addSubview:selectPhotoButton];

    UIButton *cancelSelectPhotoButton =
            [[UIButton alloc] initWithFrame:CGRectMake(previousFrame.origin.x + CGRectGetWidth(previousFrame) - 32, 0, 32, 32)];
    [cancelSelectPhotoButton setImage:[UIImage imageNamed:@"PKImageBundle.bundle/cancel"] forState:UIControlStateNormal];
    [cancelSelectPhotoButton addTarget:self action:@selector(cancelSelectedPhoto:) forControlEvents:UIControlEventTouchUpInside];
    [overlayView addSubview:cancelSelectPhotoButton];

    [self.captureSession startRunning];
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
}

- (void)endCapture {
    [self.captureSession stopRunning];
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    [self.captureVideoPreviewLayer removeFromSuperlayer];
    for (UIView *subview in [self.captureView.subviews copy]) {
        [subview removeFromSuperview];
    }
    self.avatarView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(previousFrame), CGRectGetHeight(previousFrame))];
    self.avatarView.image = self.image;
    self.avatarView.contentMode = UIViewContentModeScaleAspectFill;
    self.avatarView.layer.masksToBounds = YES;
    self.avatarView.layer.cornerRadius = CGRectGetWidth(self.avatarView.frame) / 2;
    [self.view addSubview:self.avatarView];
    self.view.layer.cornerRadius = CGRectGetWidth(self.view.frame) / 2;
    [self.captureView removeFromSuperview];
    isCapturing = NO;
}

- (IBAction)capturePhoto:(id)sender {
    self.isCapturingImage = YES;
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    if (!self.captureDevice || devices.count < 2) {
        return;
    }

    bool isFrontFacing = self.captureDevice == devices[1];
    AVCaptureConnection *videoConnection = nil;
    for (AVCaptureConnection *connection in _stillImageOutput.connections) {
        for (AVCaptureInputPort *port in [connection inputPorts]) {
            if ([[port mediaType] isEqual:AVMediaTypeVideo]) {
                videoConnection = connection;
                break;
            }
        }
        if (videoConnection) {
            break;
        }
    }

    [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection
                                                       completionHandler:^(CMSampleBufferRef imageSampleBuffer, NSError *error) {

                                                           if (imageSampleBuffer != NULL) {

                                                               NSData *imageData = [AVCaptureStillImageOutput
                                                                       jpegStillImageNSDataRepresentation:imageSampleBuffer];
                                                               UIImage *capturedImage = [[UIImage alloc] initWithData:imageData scale:1];

                                                               if (isFrontFacing) {
                                                                   capturedImage = [UIImage imageWithCGImage:capturedImage.CGImage
                                                                                                       scale:capturedImage.scale
                                                                                                 orientation:UIImageOrientationLeftMirrored];
                                                               }

                                                               self.isCapturingImage = NO;
                                                               self.capturedImageView.image = capturedImage;
                                                               for (UIView *view in self.captureView.subviews) {
                                                                   if ([view class] == [UIButton class]) view.hidden = YES;
                                                               }
                                                               [self.captureView addSubview:self.imageSelectedView];
                                                               self.selectedImage = capturedImage;
                                                           }
                                                       }];
}

- (IBAction)swapCameras:(id)sender {
    if (!self.isCapturingImage) {
        NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
        if (devices.count == 0) {
            return;
        }

        if (devices.count > 1) {
            if ([self.captureDevice isEqual:devices[0]]) {
                // rear active, switch to front
                self.captureDevice = devices[1];
                [self.captureSession beginConfiguration];

                for (AVCaptureInput *oldInput in self.captureSession.inputs) {
                    [self.captureSession removeInput:oldInput];
                }

                AVCaptureDeviceInput *newInput = [AVCaptureDeviceInput deviceInputWithDevice:self.captureDevice error:nil];
                if (newInput) {
                    [self.captureSession addInput:newInput];
                }

                [self.captureSession commitConfiguration];

            } else if (self.captureDevice == devices[1]) {
                // front active, switch to rear
                self.captureDevice = devices[0];
                [self.captureSession beginConfiguration];

                for (AVCaptureInput *oldInput in self.captureSession.inputs) {
                    [self.captureSession removeInput:oldInput];
                }

                AVCaptureDeviceInput *newInput = [AVCaptureDeviceInput deviceInputWithDevice:self.captureDevice error:nil];
                if (newInput) {
                    [self.captureSession addInput:newInput];
                }

                [self.captureSession commitConfiguration];
            }
        }

        // Need to reset flash btn
    }
}

- (IBAction)showImagePicker:(id)sender {
    self.picker = [[UIImagePickerController alloc] init];
    self.picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    self.picker.delegate = self;
    [self presentViewController:self.picker animated:YES completion:nil];
}

- (IBAction)photoSelected:(id)sender {
    self.image = self.selectedImage;
    [self endCapture];
    if ([self.delegate respondsToSelector:@selector(imageSelected:)]) {
        [self.delegate imageSelected:self.image];
    }
}

- (IBAction)cancelSelectedPhoto:(id)sender {
    [self.imageSelectedView removeFromSuperview];
    for (UIView *view in self.captureView.subviews) {
        if ([view class] == [UIButton class]) view.hidden = NO;
    }
}

- (IBAction)cancel:(id)sender {
    [self endCapture];
    if ([self.delegate respondsToSelector:@selector(imageSelectionCancelled)]) {
        [self.delegate imageSelectionCancelled];
    }
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    self.selectedImage = info[UIImagePickerControllerOriginalImage];

    [self dismissViewControllerAnimated:YES
                             completion:^{
                                 self.capturedImageView.image = self.selectedImage;
                                 for (UIView *view in self.captureView.subviews) {
                                     if ([view class] == [UIButton class]) view.hidden = YES;
                                 }
                                 [self.captureView addSubview:self.imageSelectedView];
                             }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
