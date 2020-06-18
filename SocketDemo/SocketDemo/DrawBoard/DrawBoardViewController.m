//
//  DrawBoardViewController.m
//  SocketDemo
//
//  Created by 刘李斌 on 2020/6/18.
//  Copyright © 2020 Brilliance. All rights reserved.
//

#import "DrawBoardViewController.h"
#import "DrawView.h"
#import "UIBezierPath+Point.h"

#import <GCDAsyncUdpSocket.h>




@interface DrawBoardViewController () <GCDAsyncUdpSocketDelegate>
@property (strong, nonatomic) IBOutlet DrawView *drawView;

/** udpSocket */
@property(nonatomic, strong) GCDAsyncUdpSocket *udpSocket;

@end

@implementation DrawBoardViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    [self setup];
}


- (void)setup {
    
    __weak typeof(self) weakSelf = self;
    self.drawView.onePathBlockEndBlock = ^(NSMutableDictionary * _Nonnull dict) {
        NSLog(@"绘制完一条线%@", dict);
        
        UIBezierPath *path = dict[@"drawPath"];
        NSString *lineColor = dict[@"lineColor"];
        CGFloat lineWidth = [dict[@"lineWidth"] floatValue];
        
        NSArray *points = [path points];
        NSMutableArray *temp = [NSMutableArray array];
        for (id value in points) {
            CGPoint p = [value CGPointValue];
            NSDictionary *pDict = @{@"x": @(p.x),@"y": @(p.y)};
            [temp addObject:pDict];
        }
        NSDictionary *sendDict = @{
            @"points": temp,
            @"lineWidth": @(lineWidth),
            @"lineColor": lineColor
        };
        NSData *sendData = [NSJSONSerialization dataWithJSONObject:sendDict options:NSJSONWritingPrettyPrinted error:nil];
        
        [weakSelf.udpSocket sendData:sendData toHost:@"127.0.0.1" port:8060 withTimeout:-1 tag:10011];
        
    };
    
    
    UIBarButtonItem *connectItem = [[UIBarButtonItem alloc] initWithTitle:@"连接" style:UIBarButtonItemStylePlain target:self action:@selector(creatSocket)];
    self.navigationItem.rightBarButtonItems = @[connectItem];
}


- (void)creatSocket {
    if (!self.udpSocket) {
        self.udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_global_queue(0, 0)];
    }
    NSError *err;
    [self.udpSocket bindToPort:8090 error:&err];
    if (err) {
        NSLog(@"udp error : %@",err);
        return;
    }
    NSLog(@"创建成功");
    [self.udpSocket beginReceiving:&err];
}

- (void)disconnnectSocket {
//    self.udpSocket
    [self.drawView.pathArr removeAllObjects];
    [self.drawView.currentPath removeAllPoints];
    [self.drawView setNeedsDisplay];
}

#pragma mark - GCDAsyncUdpSocketDelegate
- (void)udpSocket:(GCDAsyncUdpSocket *)sock didConnectToAddress:(NSData *)address {
    NSLog(@"udp连接成功");
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotConnect:(NSError * _Nullable)error {
    NSLog(@"udp连接失败");
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag {
    NSLog(@"udp发送数据成功 %ld", tag);
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError * _Nullable)error {
    NSLog(@"udp发送数据失败 %ld", tag);
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data
      fromAddress:(NSData *)address
withFilterContext:(nullable id)filterContext {
    NSLog(@"接受到数据");
    
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
    
    NSArray *pointArr = dict[@"points"];
    UIBezierPath *path = [UIBezierPath bezierPath];
    for (NSInteger i = 0; i < pointArr.count; i++) {
        NSDictionary *pointDict = pointArr[i];
        CGPoint point = CGPointMake([pointDict[@"x"] floatValue], [pointDict[@"y"] floatValue]);
        if (i == 0) {
            [path moveToPoint:point];
        } else {
            [path addLineToPoint:point];
        }
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        UIBezierPath *linePath = path;
        NSString *lineColor = dict[@"lineColor"];
        CGFloat lineWidth = [dict[@"lineWidth"] floatValue];
        
        [self.drawView dealWithData:linePath lineColor:lineColor lineWidth:lineWidth];
        [self.drawView setNeedsDisplay];
        
        
        
        
    });
}


- (void)udpSocketDidClose:(GCDAsyncUdpSocket *)sock withError:(NSError  * _Nullable)error {
    NSLog(@"断开socket连接");
}


@end
