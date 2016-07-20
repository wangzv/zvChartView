//
//  ZVChartView.h
//  zvChartView
//
//  Created by wangziwei on 16/4/26.
//  Copyright © 2016年 zv. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ZVChartView;

@protocol ZVChartViewDataSource <NSObject>

@required
/**
 *  图表chartView中有多少条线
 *
 *  @param chartView 对应的chartView,(类型为：ZVChartView)
 *
 *  @return 线的数量
 */
-(NSInteger)numberOfLinesInChartView:(ZVChartView *)chartView;

/**
 *  图表chartView的数据源
 *
 *  @param chartView 对应的chartView,(类型为:ZVChartView)
 *
 *  @return 数据源，结构为数组包数组包数字，如@[@[@1,@2,@3],@[@1,@2,@3]]
 */
-(NSArray *)datasOfLinesInChartView:(ZVChartView *)chartView;

/**
 *  图表chartView的X轴显示字段
 *
 *  @param chartView chartView 对应的chartView,(类型为:ZVChartView)
 *
 *  @return X轴的显示字段数组，结构为数组包字符串：如@[@"2016-4-5",@"2016-5-5"]
 */
-(NSArray *)XIndexsInChartView:(ZVChartView *)chartView;

@optional
/**
 *  图表chartView中每条线的描述，描述用于显示在线的结尾
 *
 *  @param chartView 对应的chartView,(类型为:ZVChartView)
 *
 *  @return 描述数据源，结构为数组包字符串，如@[@"最大值",@"最小值",@"中间值"]
 */
-(NSArray *)introductionOfLinesInChartView:(ZVChartView *)chartView;

/**
 *  图表chartView中每条线的描述的在x方向的偏移，描述用于显示在线的结尾
 *
 *  @param chartView chartView 对应的chartView,(类型为:ZVChartView)
 *
 *  @return 偏移量数据源，结构为数组包字符串，如@[@0.5,@0.6,@0.7]
 */
-(NSArray *)introductionXInsetOfLinesInChartView:(ZVChartView *)chartView;

/**
 *  图表chartView中每条线的颜色
 *
 *  @param chartView 对应的chartView,(类型为:ZVChartView)
 *
 *  @return 线颜色的数组，结构为数组包颜色，如@[[UIColor redColor],[UIColor greenColor]]
 */
-(NSArray *)lineColorsForChartView:(ZVChartView *)chartView;

/**
 *  图表chartView中每条线的填充颜色
 *
 *  @param chartView 对应的chartView,(类型为:ZVChartView)
 *
 *  @return 填充色的数组，结构为数组包颜色，如@[[UIColor redColor],[UIColor greenColor]]
 */
-(NSArray *)fillColorsForChartView:(ZVChartView *)chartView;

@end

@interface ZVChartView : UIView

@property (nonatomic, assign) NSInteger xIndexCount; //<x轴的竖线数
@property (nonatomic, assign) NSInteger yIndexCount; //<y轴的横线数

@property (nonatomic, weak) id<ZVChartViewDataSource> dataSource;

-(void)reloadData;

@end
