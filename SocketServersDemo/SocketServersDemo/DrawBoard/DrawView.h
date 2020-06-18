//
//  DrawView.h
//  SocketServersDemo
//
//  Created by 刘李斌 on 2020/6/18.
//  Copyright © 2020 Brilliance. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
typedef void(^OnePathEndBlock)(NSMutableDictionary *dict);
@interface DrawView : UIView
//当前正在绘制的贝塞尔曲线
@property (strong, nonatomic) UIBezierPath *currentPath;
// 总的贝塞尔曲线合集
@property (strong, nonatomic) NSMutableArray *pathArray;
// 贝塞尔曲线线条颜色 HEX
@property (copy, nonatomic) NSString *lineColor;
// 贝塞尔曲线线条宽度
@property (assign, nonatomic) CGFloat lineWidth;
//一条贝塞尔曲线绘制完成后的回调Block
@property (copy, nonatomic) OnePathEndBlock onePathEndBlock;

- (void)dealwithData:(UIBezierPath *)path lineColor:(NSString *)lineColor lineWidth:(CGFloat)lineWidth;
@end

NS_ASSUME_NONNULL_END
