//
//  GCDAsynSocketViewController.m
//  SocketDemo
//
//  Created by 刘李斌 on 2020/6/17.
//  Copyright © 2020 Brilliance. All rights reserved.
//

#import "GCDAsynSocketViewController.h"
#import <GCDAsyncSocket.h>

#define kHost   @"127.0.0.1"
#define kPort   8090
#define kTag    10086

#define kDataTypeImage  0x00000001
#define kDataTypevideo  0x00000002

@interface GCDAsynSocketViewController () <GCDAsyncSocketDelegate>

@property (weak, nonatomic) IBOutlet UITextField *sendMsgTextField;

/** socket */
@property(nonatomic, strong) GCDAsyncSocket *socket;


@end

@implementation GCDAsynSocketViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (IBAction)connectSocketBtnClick:(id)sender {
    //创建socket
    if (!self.socket) {
        self.socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_global_queue(0, 0)];
    }
    
    //连接socket
    if (!self.socket.isConnected) {
        NSError *err;
        [self.socket connectToHost:kHost onPort:kPort error:&err];
        if (err) {
            NSLog(@"连接失败: %@",err);
        }
    }
}

- (IBAction)reConnectSocketBtnClick:(id)sender {
    if (!self.socket) {
        self.socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_global_queue(0, 0)];
    }
    
    if (!self.socket.isConnected) {
        NSError *err;
        [self.socket connectToHost:kHost onPort:kPort error:&err];
        if (err) {
            NSLog(@"重连异常: %@",err);
        }
    }
}

- (IBAction)disconnectSocketBtnSocket:(id)sender {
    [self.socket disconnect];
    self.socket = nil;
    
}
- (IBAction)sendMsgBtnClick:(id)sender {
    /*
    NSData *sendData = [self.sendMsgTextField.text dataUsingEncoding:NSUTF8StringEncoding];
    [self.socket writeData:sendData withTimeout:-1 tag:kTag];
     */
    
    UIImage *img = [UIImage imageNamed:@"logo"];
    NSData *data = UIImagePNGRepresentation(img);
    [self sendData:data dataType:kDataTypeImage];
    
}


- (void)sendData:(NSData *)data dataType:(NSInteger)dataType {
    //数据粘包  数据长度+数据类型+数据
    NSMutableData *sendData = [NSMutableData data];
    //计算并拼接数据长度 4字节长度+4字节类型+数据
    int dataLength = (int)data.length + 4 + 4;
    NSData *lengthData = [NSData dataWithBytes:&dataLength length:4];
    [sendData appendData:lengthData];
    
    //拼接数据类型
    NSData *typeData = [NSData dataWithBytes:&dataType length:4];
    [sendData appendData:typeData];
    
    //拼接数据
    [sendData appendData:data];
    NSLog(@"发送数据: %@", sendData);
    [self.socket writeData:[sendData copy] withTimeout:-1 tag:kTag];
}

///解析返回的数据
- (void)analysisData:(NSData *)data {
    //获取数据包大小
    NSData *lengthData = [data subdataWithRange:NSMakeRange(0, 4)];
    int totoalSize = 0;
    [lengthData getBytes:&totoalSize length:4];
    NSLog(@"数据包长度为: %d", totoalSize);
    
    //获取数据类型
    NSData *typeData = [data subdataWithRange:NSMakeRange(4, 4)];
    int type = 0;
    [typeData getBytes:&type length:4];
    NSLog(@"数据类型为: %d", type);
    
    //数据
    NSData *resultData = [data subdataWithRange:NSMakeRange(8, totoalSize-8)];
    if (type == kDataTypeImage) {
        UIImage *image = [UIImage imageWithData:resultData];
        dispatch_async(dispatch_get_main_queue(), ^{
           //回到主线程刷新UI
        });
    } else if (type == kDataTypevideo) {
        
    }
}


#pragma mark - GCDAsyncSocketDelegate
///连接到服务器
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
    NSLog(@"连接服务器成功: %@ -- %d", host, port);
    [self.socket readDataWithTimeout:-1 tag:kTag];
}
///收到数据
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"接收到来自tag=%ld 的数据: %@", tag, str);
    
    [self analysisData:data];
    //持续接收服务器数据
    [self.socket readDataWithTimeout:-1 tag:kTag];
}
///向服务器发送数据
- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
    NSLog(@"tag=%ld  数据发送成功",tag);
}
///断开连接
- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(nullable NSError *)err {
    if (err) {
        NSLog(@"断开失败: %@", err);
        return;
    }
    
    NSLog(@"断开成功");
}

@end
