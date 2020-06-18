//
//  UIBezierPath+Point.h
//  SocketDemo
//
//  Created by 刘李斌 on 2020/6/18.
//  Copyright © 2020 Brilliance. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIBezierPath (Point)


/// 获取UIBezierPath上的所有坐标点
- (NSArray *)points;
@end

NS_ASSUME_NONNULL_END
