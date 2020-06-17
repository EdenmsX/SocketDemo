//
//  ViewController.m
//  SocketDemo
//
//  Created by 刘李斌 on 2020/6/16.
//  Copyright © 2020 Brilliance. All rights reserved.
//

#import "ViewController.h"
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>


//htons : 将一个无符号短整型的主机数值转换为网络字节顺序，不同cpu 是不同的顺序 (big-endian大尾顺序[01-02-03] , little-endian小尾顺序[06-05-04])
#define SocketPort htons(8040)
//inet_addr是一个计算机函数，功能是将一个点分十进制的IP转换成一个长整数型数
#define SocketIP   inet_addr("127.0.0.1")


@interface ViewController ()

@property (weak, nonatomic) IBOutlet UITextField *msgTextField;

@property (weak, nonatomic) IBOutlet UITextView *callbackTextView;

/** socketid */
@property(nonatomic, assign) int clientID;

/** index */
@property(nonatomic, assign) int index;

/** time */
@property (nonatomic, copy) NSString *recordTime;

/** attribute */
@property(nonatomic, strong) NSMutableAttributedString *totalAttributeStr;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    
}

- (IBAction)buildSocketBtnClick:(id)sender {
    /**
    1: 创建socket
    参数
    domain：协议域，又称协议族（family）。常用的协议族有AF_INET、AF_INET6、AF_LOCAL（或称AF_UNIX，Unix域Socket）、AF_ROUTE等。协议族决定了socket的地址类型，在通信中必须采用对应的地址，如AF_INET决定了要用ipv4地址（32位的）与端口号（16位的）的组合、AF_UNIX决定了要用一个绝对路径名作为地址。
    type：指定Socket类型。常用的socket类型有SOCK_STREAM、SOCK_DGRAM、SOCK_RAW、SOCK_PACKET、SOCK_SEQPACKET等。流式Socket（SOCK_STREAM）是一种面向连接的Socket，针对于面向连接的TCP服务应用。数据报式Socket（SOCK_DGRAM）是一种无连接的Socket，对应于无连接的UDP服务应用。
    protocol：指定协议。常用协议有IPPROTO_TCP、IPPROTO_UDP、IPPROTO_STCP、IPPROTO_TIPC等，分别对应TCP传输协议、UDP传输协议、STCP传输协议、TIPC传输协议。
    注意：1.type和protocol不可以随意组合，如SOCK_STREAM不可以跟IPPROTO_UDP组合。当第三个参数为0时，会自动选择第二个参数类型对应的默认协议。
    返回值:
    如果调用成功就返回新创建的套接字的描述符，如果失败就返回INVALID_SOCKET（Linux下失败返回-1）
    */
    int socketID = socket(AF_INET, SOCK_STREAM, 0);
    self.clientID = socketID;
    if (socketID == -1) {
        NSLog(@"创建socketID失败");
        return;
    }
    
    /**
    __uint8_t    sin_len;          假如没有这个成员，其所占的一个字节被并入到sin_family成员中
    sa_family_t    sin_family;     一般来说AF_INET（地址族）PF_INET（协议族）
    in_port_t    sin_port;         // 端口
    struct    in_addr sin_addr;    // ip
    char        sin_zero[8];       没有实际意义,只是为了　跟SOCKADDR结构在内存中对齐
    */
    struct sockaddr_in socketAdd;
    socketAdd.sin_family = AF_INET;
    socketAdd.sin_port   = SocketPort;
    struct in_addr socket_idAdd;
    socket_idAdd.s_addr  = SocketIP;
    socketAdd.sin_addr   = socket_idAdd;
    
    /**
    参数
    参数一：套接字描述符
    参数二：指向数据结构sockaddr的指针，其中包括目的端口和IP地址
    参数三：参数二sockaddr的长度，可以通过sizeof（struct sockaddr）获得
    返回值
    成功则返回0，失败返回非0，错误码GetLastError()。
    */
    int result = connect(socketID, (const struct sockaddr *)&socketAdd, sizeof(socketAdd));
    if (result != 0) {
        NSLog(@"连接失败");
        return;
    }
    NSLog(@"连接成功");
    
    //接受消息
    self.index = 0;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self recieveMsg];
    });
    
    
    
    
}
- (IBAction)sendMessageBtnClick:(id)sender {
    [self sendMsg];
    
}
- (IBAction)closeSocketBtnClick:(id)sender {
    close(self.clientID);
}

- (void)sendMsg {
    if (self.msgTextField.text.length == 0) {
        NSLog(@"发送的消息为空");
        return;
    }
    
    const char *msg = self.msgTextField.text.UTF8String;
    /**
    发送消息
    s：一个用于标识已连接套接口的描述字。
    buf：包含待发送数据的缓冲区。
    len：缓冲区中数据的长度。
    flags：调用执行方式。
    
    返回值
    如果成功，则返回发送的字节数，失败则返回SOCKET_ERROR
    一个中文对应 3 个字节！UTF8 编码！
    */
    ssize_t sendMsgLen = send(self.clientID, msg, strlen(msg), 0);
    NSLog(@"发送了长度为: %ld 的数据",sendMsgLen);
    [self showMsg:self.msgTextField.text msgType:0];
    
    self.msgTextField.text = @"";
}

- (void)recieveMsg {
    while (1) {
        uint8_t buffer[1024];
        /**
         参数
         1> 客户端socket
         2> 接收内容缓冲区地址
         3> 接收内容缓存区长度
         4> 接收方式，0表示阻塞，必须等待服务器返回数据
         
         返回值
         如果成功，则返回读入的字节数，失败则返回SOCKET_ERROR
         */
        ssize_t recieveLen = recv(self.clientID, buffer, sizeof(buffer), 0);
        NSLog(@"接收到了 %ld 字节数据", recieveLen);
        
        if (recieveLen == 0) {
            self.index++;
            if (self.index > 5) {
                return;
            }
        }
        
        NSData *data = [NSData dataWithBytes:buffer length:recieveLen];
        NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"收到数据: %@", str);
        self.index = 0;
        //切换回主线程刷新UI
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showMsg:str msgType:1];
        });
    }
}


/// 处理接受和发送的数据
/// @param msg 数据
/// @param msgType 类型  0-发送的数据; 1-接受的数据
- (void)showMsg:(NSString *)msg msgType:(int)msgType {
    NSString *timeStr = [self getCurrentTime];
    if (timeStr.length>0) {
        NSMutableAttributedString *dateAttributeStr = [[NSMutableAttributedString alloc] initWithString:timeStr];
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        //对齐方式
        paragraphStyle.alignment = NSTextAlignmentCenter;
        [dateAttributeStr addAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:13],NSForegroundColorAttributeName:[UIColor blackColor],NSParagraphStyleAttributeName:paragraphStyle} range:NSMakeRange(0, timeStr.length)];
        [self.totalAttributeStr appendAttributedString:dateAttributeStr];
        [self.totalAttributeStr appendAttributedString:[[NSMutableAttributedString alloc] initWithString:@"\n"]];
    }
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.headIndent = 20.f;
    NSMutableAttributedString * attributeStr = nil;
    if (msgType == 0) { //发送的数据
        attributeStr = [[NSMutableAttributedString alloc] initWithString:msg];
        paragraphStyle.alignment = NSTextAlignmentRight;
        [attributeStr addAttributes:@{
            NSFontAttributeName:[UIFont systemFontOfSize:15],
            NSForegroundColorAttributeName:[UIColor whiteColor],
            NSBackgroundColorAttributeName:[UIColor blueColor],
            NSParagraphStyleAttributeName:paragraphStyle
        } range:NSMakeRange(0, msg.length)];
        
    } else if (msgType == 1) {  //接受的数据
        msg = [msg substringToIndex:msg.length-1];
        attributeStr = [[NSMutableAttributedString alloc] initWithString:msg];
        [attributeStr addAttributes:@{
            NSFontAttributeName:[UIFont systemFontOfSize:15],
            NSForegroundColorAttributeName:[UIColor blackColor],
            NSBackgroundColorAttributeName:[UIColor whiteColor],
            NSParagraphStyleAttributeName:paragraphStyle
        } range:NSMakeRange(0, msg.length)];

    }
    
    [self.totalAttributeStr appendAttributedString:attributeStr];
    [self.totalAttributeStr appendAttributedString:[[NSMutableAttributedString alloc] initWithString:@"\n"]];
    
    self.callbackTextView.attributedText = self.totalAttributeStr;
}

- (NSString *)getCurrentTime {
    NSDate *date = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    NSString *dateStr = [dateFormatter stringFromDate:date];
    if (!self.recordTime || self.recordTime.length == 0) {
        self.recordTime = dateStr;
        return dateStr;
    }
    
    NSDate *recordeDate = [dateFormatter dateFromString:self.recordTime];
    self.recordTime = dateStr;
    NSTimeInterval timeInterval = [date timeIntervalSinceDate:recordeDate];
    NSLog(@"%@--%@ -- %f",date,recordeDate,timeInterval);
    if (timeInterval < 6) {
        return @"";
    }
    return dateStr;
}

- (NSMutableAttributedString *)totalAttributeStr {
    if (!_totalAttributeStr) {
        _totalAttributeStr = [[NSMutableAttributedString alloc] init];
    }
    return _totalAttributeStr;
}

@end
