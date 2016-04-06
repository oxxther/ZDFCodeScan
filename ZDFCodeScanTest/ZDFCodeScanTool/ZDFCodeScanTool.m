//
//  ZDFCodeScanTool.m
//  ZDFCodeScanTest
//
//  Created by yeyuban on 16/3/24.
//  Copyright © 2016年 yeyuban. All rights reserved.
//

#import "ZDFCodeScanTool.h"
#import <AVFoundation/AVFoundation.h>

@interface ZDFCodeScanTool ()<AVCaptureMetadataOutputObjectsDelegate>

@property (nonatomic,strong) UIView *rectView;
@property (nonatomic,assign) BOOL isReading;
@property (nonatomic,strong) CALayer *scanLayer;

- (BOOL)startReading;
- (void)stopReading;

//捕捉会话 -- capture:捕获
@property (nonatomic,strong) AVCaptureSession *captureSession;
//展示layer
@property (nonatomic,strong) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;
@end

@implementation ZDFCodeScanTool

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _captureSession = nil;
    _isReading = NO;
}

- (BOOL)startReading{
    NSError *error = nil;
    
    //1.初始化捕捉设备（AVCaptureDevice）,类型为AVMediaTypeVideo
    AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    //2.用captureDevice创建输入流
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
    
    if (!input) {
        NSLog(@"%@",[error localizedDescription]);
        return NO;
    }
    
    //3.创建媒体数据输出流
    AVCaptureMetadataOutput *captureMetadataOutput = [[AVCaptureMetadataOutput alloc]init];
    
    //4.实例化捕捉会话
    _captureSession = [[AVCaptureSession alloc]init];
    //4.1将输入流添加到会话中
    [_captureSession addInput:input];
    //4.2将输出流添加到会话中
    [_captureSession addOutput:captureMetadataOutput];
    
    //5.创建串行队列，并把媒体输出流添加到队列中
    dispatch_queue_t dispatchQueue;
    dispatchQueue = dispatch_queue_create("outputQueue", NULL);
    //5.1设置代理
    [captureMetadataOutput setMetadataObjectsDelegate:self queue:dispatchQueue];
    //5.2设置输出媒体数据类型为QRCode -- 二维码可用QRCode(Quick Response Code)生成
    [captureMetadataOutput setMetadataObjectTypes:[NSArray arrayWithObject:AVMetadataObjectTypeQRCode]];
    
    //6.实例化预览图层
    _captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc]initWithSession:_captureSession];
    
    //7.设置预览图层填充方式
    [_captureVideoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
   
#warning
    //8.设置图层的frame
    [_captureVideoPreviewLayer setFrame:self.view.layer.bounds];
    
    //9.将图层添加到预览的view的图层上
    [self.view.layer addSublayer:_captureVideoPreviewLayer];
    
    //10.设置扫描范围
    captureMetadataOutput.rectOfInterest = CGRectMake(.2f, .2f, .8f, .8f);
    //10.1扫描框
    _rectView = [[UIView alloc]initWithFrame:CGRectMake(self.view.bounds.size.width * .2f, self.view.bounds.size.height * .2f, self.view.bounds.size.width - self.view.bounds.size.width * .4f, self.view.bounds.size.height - self.view.bounds.size.height * .4f)];
    _rectView.layer.borderColor = [UIColor greenColor].CGColor;
    _rectView.layer.borderWidth = 1.f;
    [self.view addSubview:_rectView];
    //10.2扫描线
    _scanLayer = [[CALayer alloc]init];
    _scanLayer.frame = CGRectMake(0, 0, _rectView.bounds.size.width, 1);
    _scanLayer.backgroundColor = [UIColor brownColor].CGColor;
    [_rectView.layer addSublayer:_scanLayer];
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:.2f target:self selector:@selector(moveScanLayer:) userInfo:nil repeats:YES];
    [timer fire];
    
    //11.开始扫描
    [_captureSession startRunning];
    return YES;
}

#pragma mark - 实现AVCaptureMetadataOutputObjectsDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection{
    //判断是否有数据
    if (metadataObjects != nil && [metadataObjects count] > 0) {
        AVMetadataMachineReadableCodeObject *metadataObj = [metadataObjects firstObject];
        //判断回传的数据类型
        if ([[metadataObj type] isEqualToString:AVMetadataObjectTypeQRCode]) {
            NSLog(@"%@",[metadataObj stringValue]);
            //停止扫描
            [self performSelectorOnMainThread:@selector(stopReading) withObject:nil waitUntilDone:NO];
            _isReading = NO;
        }
    }
}

- (void)moveScanLayer:(NSTimer *)timer{
    CGRect frame = _scanLayer.frame;
    if (_rectView.frame.size.height < _scanLayer.frame.origin.y) {
        frame.origin.y = 0;
        _scanLayer.frame = frame;
    }else{
        frame.origin.y += 5;
        [UIView animateWithDuration:.1 animations:^{
            _scanLayer.frame = frame;
        }];
    }
}

- (void)stopReading{
    [_captureSession stopRunning];
    _captureSession = nil;
    [_scanLayer removeFromSuperlayer];
    [_captureVideoPreviewLayer removeFromSuperlayer];
}

- (IBAction)startOrStopReading:(id)sender{
    if (!_isReading) {
        if ([self startReading]){
            ;
        }
    }else{
        [self stopReading];
    }
    _isReading = !_isReading;
}
@end
