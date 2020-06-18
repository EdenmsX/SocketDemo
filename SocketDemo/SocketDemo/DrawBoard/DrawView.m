//
//  DrawView.m
//  SocketDemo
//
//  Created by 刘李斌 on 2020/6/18.
//  Copyright © 2020 Brilliance. All rights reserved.
//

#import "DrawView.h"

@implementation DrawView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}


- (void)awakeFromNib {
    [super awakeFromNib];
    [self setup];
}

- (void)setup {
    self.lineWidth = 5;
    self.lineColor = @"0xFF0000";
}


- (void)drawRect:(CGRect)rect {
    if (self.pathArr.count) {
        for (NSMutableDictionary *dict in self.pathArr) {
            UIBezierPath *path = dict[@"drawPath"];
            NSString *lineColor = dict[@"lineColor"];
            CGFloat lineWidth = [dict[@"lineWidth"] floatValue];
            [[self colorWithHexString:lineColor] set];
            path.lineWidth = lineWidth;
            [path stroke];
        }
    }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    //获取起始坐标点
    CGPoint starPoint = [self getCurrentPointWithTouches:[event allTouches]];
    //初始化
    UIBezierPath *tempPath = [UIBezierPath bezierPath];
    //绘制起始点
    [tempPath moveToPoint:starPoint];
    //设置线条风格
    tempPath.lineCapStyle = kCGLineCapRound;
    //设置连接处效果
    tempPath.lineJoinStyle = kCGLineJoinRound;
    tempPath.lineWidth = self.lineWidth;
    self.currentPath = tempPath;
    
    [self dealWithData:tempPath lineColor:self.lineColor lineWidth:self.lineWidth];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    //获取坐标
    CGPoint movePoint = [self getCurrentPointWithTouches:event.allTouches];
    //填充图形
    [self.currentPath addLineToPoint:movePoint];
    [self setNeedsDisplay];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    //绘制完成回调block
    if (self.onePathBlockEndBlock) {
        self.onePathBlockEndBlock([self.pathArr lastObject]);
    }
}


- (CGPoint)getCurrentPointWithTouches:(NSSet *)touches {
    //获取所有对象
    UITouch *touch = [touches anyObject];
    //返回触摸点在视图中的坐标
    return [touch locationInView:touch.view];
}

- (void)dealWithData:(UIBezierPath *)path lineColor:(NSString *)lineColor lineWidth:(CGFloat)lineWidth {
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:3];
    [dict setValue:path forKey:@"drawPath"];
    [dict setValue:lineColor forKey:@"lineColor"];
    [dict setValue:@(lineWidth) forKey:@"lineWidth"];
    [self.pathArr addObject:dict];
}



- (UIColor *)colorWithHexString: (NSString *) hexString
{
    NSString *colorString = [[hexString stringByReplacingOccurrencesOfString: @"#" withString: @""] uppercaseString];
    CGFloat alpha, red, blue, green;
    switch ([colorString length]) {
        case 3: // #RGB
            alpha = 1.0f;
            red   = [self colorComponentFrom: colorString start: 0 length: 1];
            green = [self colorComponentFrom: colorString start: 1 length: 1];
            blue  = [self colorComponentFrom: colorString start: 2 length: 1];
            break;
        case 4: // #ARGB
            alpha = [self colorComponentFrom: colorString start: 0 length: 1];
            red   = [self colorComponentFrom: colorString start: 1 length: 1];
            green = [self colorComponentFrom: colorString start: 2 length: 1];
            blue  = [self colorComponentFrom: colorString start: 3 length: 1];
            break;
        case 6: // #RRGGBB
            alpha = 1.0f;
            red   = [self colorComponentFrom: colorString start: 0 length: 2];
            green = [self colorComponentFrom: colorString start: 2 length: 2];
            blue  = [self colorComponentFrom: colorString start: 4 length: 2];
            break;
        case 8: // #AARRGGBB
            alpha = [self colorComponentFrom: colorString start: 0 length: 2];
            red   = [self colorComponentFrom: colorString start: 2 length: 2];
            green = [self colorComponentFrom: colorString start: 4 length: 2];
            blue  = [self colorComponentFrom: colorString start: 6 length: 2];
            break;
        default:
            blue=0;
            green=0;
            red=0;
            alpha=0;
            break;
    }
    return [UIColor colorWithRed: red green: green blue: blue alpha: 1];
}

- (CGFloat) colorComponentFrom: (NSString *) string start: (NSUInteger) start length: (NSUInteger) length
{
    NSString *substring = [string substringWithRange: NSMakeRange(start, length)];
    NSString *fullHex = length == 2 ? substring : [NSString stringWithFormat: @"%@%@", substring, substring];
    unsigned hexComponent;
    [[NSScanner scannerWithString: fullHex] scanHexInt: &hexComponent];
    return hexComponent ;
}

- (NSMutableArray *)pathArr {
    if (!_pathArr) {
        _pathArr = [NSMutableArray array];
    }
    return _pathArr;
}

@end
