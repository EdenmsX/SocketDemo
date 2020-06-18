//
//  DrawView.h
//  SocketDemo
//
//  Created by 刘李斌 on 2020/6/18.
//  Copyright © 2020 Brilliance. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN


typedef void(^OnePathEndBlock)(NSMutableDictionary *dict);

@interface DrawView : UIView

/** 当前正在绘制的贝塞尔曲线 */
@property(nonatomic, strong) UIBezierPath *currentPath;

/** 所有贝塞尔曲线 */
@property(nonatomic, strong) NSMutableArray *pathArr;

/** 曲线颜色 */
@property (nonatomic, copy) NSString *lineColor;

/** 曲线宽度 */
@property(nonatomic, assign) CGFloat lineWidth;

/** 一条曲线绘制完成后的回调 */
@property (nonatomic, copy) OnePathEndBlock onePathBlockEndBlock;

- (void)dealWithData:(UIBezierPath *)path lineColor:(NSString *)lineColor lineWidth:(CGFloat)lineWidth;

@end

NS_ASSUME_NONNULL_END
