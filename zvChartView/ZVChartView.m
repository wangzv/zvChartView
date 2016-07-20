//
//  ZVChartView.m
//  zvChartView
//
//  Created by wangziwei on 16/4/26.
//  Copyright © 2016年 zv. All rights reserved.
//

#import "ZVChartView.h"

#define IndexFont [UIFont systemFontOfSize:10]
#define coordinateLineColor [UIColor colorWithWhite:0.87 alpha:1]
#define IndexColor [UIColor colorWithWhite:0.6 alpha:1]
#define IntroductColor [UIColor colorWithWhite:0.4 alpha:1]

#define leftPadding 10
#define rightPadding 10
#define topPadding 10
#define bottomPadding 10

@interface ZVChartView ()
@property (nonatomic, strong) NSArray *lineCoordinates; //<线的实际每点坐标
@property (nonatomic, strong) NSArray *horizonLinesPoints; //<横线的坐标起始点和结束点
@property (nonatomic, strong) NSArray *verticalLinesPoints; //<竖线的坐标起始点和结束点
@property (nonatomic, strong) NSArray *yIndexStrings;//<y轴显示的文字
@property (nonatomic, assign) float maxValue;
@property (nonatomic, assign) float minValue;

@property (nonatomic, assign) CGFloat chartX;
@property (nonatomic, assign) CGFloat chartY;
@property (nonatomic, assign) CGFloat chartWidth;
@property (nonatomic, assign) CGFloat chartHeight;

@property (nonatomic, strong) NSMutableArray *fillLayers;
@property (nonatomic, strong) NSMutableArray *stokeLayers;
@end

@implementation ZVChartView

-(instancetype)initWithFrame:(CGRect)frame
{
    if (self =[super initWithFrame:frame])
    {
        _fillLayers = [NSMutableArray array];
        _stokeLayers = [NSMutableArray array];
    }
    return self;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    if (!self.dataSource)
    {
        return;
    }
    [self calculateCoordinate];
    
    typeof(self)weakself = self;
    
    
    //移除原来的layer
    [_fillLayers enumerateObjectsUsingBlock:^(CAShapeLayer *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj removeFromSuperlayer];
    }];
    [_stokeLayers enumerateObjectsUsingBlock:^(CAShapeLayer *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj removeFromSuperlayer];
    }];
    [_fillLayers removeAllObjects];
    [_stokeLayers removeAllObjects];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    //    CGContextSetRGBStrokeColor(context,0.5,0.5,0.5,1.0);//画笔线的颜色
    CGContextSetStrokeColorWithColor(context, coordinateLineColor.CGColor);
    CGContextSetShouldAntialias(context, NO); //此处要设置抗锯齿为NO，否则不能将线宽设置为1以下（设置1以下无效果）
    CGContextSetLineWidth(context, 0.5);//线的宽度
    CGContextSetLineCap(context, kCGLineCapRound);
    
    //画坐标系
    [_horizonLinesPoints enumerateObjectsUsingBlock:^(NSDictionary *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        CGPoint startValue = [[obj objectForKey:@"start"] CGPointValue];
        CGPoint endValue = [[obj objectForKey:@"end"] CGPointValue];
        CGContextMoveToPoint(context, startValue.x, startValue.y);
        CGContextAddLineToPoint(context, endValue.x, endValue.y);
        CGContextStrokePath(context);
    }];
    
        [_verticalLinesPoints enumerateObjectsUsingBlock:^(NSDictionary *obj, NSUInteger idx, BOOL * _Nonnull stop) {
            CGPoint startValue = [[obj objectForKey:@"start"] CGPointValue];
            CGPoint endValue = [[obj objectForKey:@"end"] CGPointValue];
            CGContextMoveToPoint(context, startValue.x, startValue.y);
            CGContextAddLineToPoint(context, endValue.x, endValue.y);
            CGContextStrokePath(context);
        }];
    
    
    CGContextSetShouldAntialias(context, YES);//写文字之前要将抗锯齿设置为YES，否则文字为锯齿状
    
    //写文字
    CGFloat stringWidth = (_chartX-3-leftPadding);
    [_horizonLinesPoints enumerateObjectsUsingBlock:^(NSDictionary *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        CGPoint startValue = [[obj objectForKey:@"start"] CGPointValue];
        NSString *text = _yIndexStrings[weakself.yIndexCount-1-idx];
        CGRect textRect = CGRectMake(leftPadding, startValue.y-6, stringWidth, 12);
        
        NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        paragraphStyle.lineBreakMode = NSLineBreakByClipping;
        paragraphStyle.alignment = NSTextAlignmentRight;
        
        [text drawInRect:textRect
          withAttributes:@{NSFontAttributeName:IndexFont,
                           NSForegroundColorAttributeName:IndexColor,
                           NSParagraphStyleAttributeName:paragraphStyle}];
    }];
    
    NSArray *xIndexStrings = [self.dataSource XIndexsInChartView:self];
    CGFloat xIndexY = self.frame.size.height-bottomPadding-12;
    [xIndexStrings enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        CGFloat width = [obj boundingRectWithSize:CGSizeMake(100, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:IndexFont} context:nil].size.width;
        CGPoint startValue = [[weakself.verticalLinesPoints[idx] objectForKey:@"start"] CGPointValue];
        CGFloat xIndexX = startValue.x - width/2;
        if (xIndexX<leftPadding)
        {
            xIndexX = leftPadding;
        }
        if (xIndexX+width+2>weakself.frame.size.width)
        {
            xIndexX = weakself.frame.size.width-width-2;
        }
        
        CGRect xIndexRect = CGRectMake(xIndexX, xIndexY, width, 12);
        
        //如果是最后一个判断是否重叠
        if (idx == xIndexStrings.count -1 && xIndexStrings.count > 1)
        {
            CGFloat frontWidth = [[xIndexStrings objectAtIndex:xIndexStrings.count-2] boundingRectWithSize:CGSizeMake(100, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:IndexFont} context:nil].size.width;
            CGFloat frontX = [[weakself.verticalLinesPoints[idx -1] objectForKey:@"start"] CGPointValue].x- frontWidth/2;
            
            //如果重叠(间隔小于5)，不画
            if (xIndexX > frontX+frontWidth+5)
            {
                [obj drawInRect:xIndexRect withAttributes:@{NSFontAttributeName:IndexFont,
                                                            NSForegroundColorAttributeName:IndexColor}];
            }
        }
        else
        {
            [obj drawInRect:xIndexRect withAttributes:@{NSFontAttributeName:IndexFont,
                                                        NSForegroundColorAttributeName:IndexColor}];
        }
    }];
    
    __block NSMutableArray *introductRectArr = [NSMutableArray arrayWithCapacity:_lineCoordinates.count];
    //    CGContextSetLineWidth(context, 1);//线的宽度
    
    /*画填充色*/
    [_lineCoordinates enumerateObjectsUsingBlock:^(NSArray *linePoints, NSUInteger idx, BOOL * _Nonnull stop) {
        
        UIColor *lineColor = [UIColor clearColor];
        UIColor *fillColor;
        
        if ([weakself.dataSource respondsToSelector:@selector(fillColorsForChartView:)])
        {
            fillColor = [weakself.dataSource fillColorsForChartView:weakself][idx];
        }
        else
        {
            fillColor = [UIColor colorWithRed:arc4random()%100/100.f green:arc4random()%100/100.f blue:arc4random()%100/100.f alpha:0.2];
        }
        
        if (linePoints.count == 2)
        {
            CGContextSetStrokeColorWithColor(context, lineColor.CGColor);
            CGContextSetFillColorWithColor(context, fillColor.CGColor);
            CGContextMoveToPoint(context, [[linePoints firstObject] CGPointValue].x, [[linePoints firstObject] CGPointValue].y);
            CGContextAddLineToPoint(context, [[linePoints lastObject] CGPointValue].x, [[linePoints lastObject] CGPointValue].y);
            CGContextAddLineToPoint(context, [[linePoints lastObject] CGPointValue].x, weakself.chartY+weakself.chartHeight);
            CGContextAddLineToPoint(context, weakself.chartX, weakself.chartY+_chartHeight);
            CGContextClosePath(context);
            CGContextFillPath(context);
            
        }
        //如果超过两个点，画曲线
        else if (linePoints.count > 2)
        {
            UIBezierPath *bezierPath = [UIBezierPath bezierPath];
            UIBezierPath *noBezierPath = [UIBezierPath bezierPath];
            //            [fillColor setFill];
            //            bezierPath.lineWidth = 1;
            //            bezierPath.lineCapStyle = kCGLineCapRound;
            //            bezierPath.lineJoinStyle = kCGLineCapRound;
            
            [linePoints enumerateObjectsUsingBlock:^(NSValue *pointValue, NSUInteger idx1, BOOL * _Nonnull stop) {
                CGPoint frontPoint;
                CGPoint point1;
                CGPoint point2;
                CGPoint backPoint;
                
                if (idx1 == 0)
                {
                    frontPoint = [pointValue CGPointValue];
                    point1 = [pointValue CGPointValue];
                    point2 = [linePoints[idx1+1] CGPointValue];
                    backPoint = [linePoints[idx1+2] CGPointValue];
                }
                else if (idx1 == linePoints.count-2)
                {
                    frontPoint = [linePoints[idx1-1] CGPointValue];
                    point1 = [pointValue CGPointValue];
                    point2 = [linePoints[idx1+1] CGPointValue];
                    backPoint = [linePoints[idx1+1] CGPointValue];
                }
                else if (idx1 == linePoints.count -1)
                {
                    frontPoint = [linePoints[idx1-1] CGPointValue];
                    point1 = [pointValue CGPointValue];
                    point2 = [pointValue CGPointValue];
                    backPoint = [pointValue CGPointValue];
                }
                else
                {
                    frontPoint = [linePoints[idx1-1] CGPointValue];
                    point1 = [pointValue CGPointValue];
                    point2 = [linePoints[idx1+1] CGPointValue];
                    backPoint = [linePoints[idx1+2] CGPointValue];
                }
                
                if (idx1 == 0 )
                {
                    [bezierPath moveToPoint:point1];
                    NSDictionary *ControlDic = [weakself controlPointOfBezierWithPointFront:frontPoint Point1:point1 Point2:point2 PointBack:backPoint];
                    CGPoint controlA = [ControlDic[@"A"] CGPointValue];
                    CGPoint controlB = [ControlDic[@"B"] CGPointValue];
                    
                    [bezierPath addCurveToPoint:point2 controlPoint1:controlA controlPoint2:controlB];
                    
                    [noBezierPath moveToPoint:CGPointMake(weakself.chartX, weakself.chartY+weakself.chartHeight)];
                    [noBezierPath addLineToPoint:CGPointMake(point2.x, weakself.chartY+weakself.chartHeight)];
                }
                else if (idx1 == linePoints.count-1)
                {
                    [bezierPath addLineToPoint:CGPointMake(point2.x, weakself.chartY+weakself.chartHeight)];
                    [bezierPath addLineToPoint:CGPointMake(weakself.chartX, weakself.chartY+_chartHeight)];
                    [bezierPath closePath];
                    
                    [noBezierPath addLineToPoint:CGPointMake(point2.x, weakself.chartY+weakself.chartHeight)];
                    [noBezierPath addLineToPoint:CGPointMake(weakself.chartX, weakself.chartY+_chartHeight)];
                    [noBezierPath closePath];
                    
                    
                    CAShapeLayer *fillLayer = [CAShapeLayer layer];
                    
                    fillLayer = [CAShapeLayer layer];
                    fillLayer.frame = weakself.bounds;
                    fillLayer.path = bezierPath.CGPath;
                    fillLayer.strokeColor = nil;
                    fillLayer.fillColor = [fillColor CGColor];
                    fillLayer.lineWidth = 0;
                    fillLayer.lineJoin = kCALineJoinRound;
                    
                    CABasicAnimation *fillAnimation = [CABasicAnimation animationWithKeyPath:@"path"];
                    fillAnimation.duration = 0.25;
                    fillAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
                    fillAnimation.fillMode = kCAFillModeForwards;
                    fillAnimation.fromValue = (id)noBezierPath.CGPath;
                    fillAnimation.toValue = (id)bezierPath.CGPath;
                    [fillLayer addAnimation:fillAnimation forKey:@"path"];
                    
                    [weakself.layer addSublayer:fillLayer];
                    [weakself.fillLayers addObject:fillLayer];
                }
                else
                {
                    NSDictionary *ControlDic = [weakself controlPointOfBezierWithPointFront:frontPoint Point1:point1 Point2:point2 PointBack:backPoint];
                    CGPoint controlA = [ControlDic[@"A"] CGPointValue];
                    CGPoint controlB = [ControlDic[@"B"] CGPointValue];
                    
                    [bezierPath addCurveToPoint:point2 controlPoint1:controlA controlPoint2:controlB];
                    
                    [noBezierPath addLineToPoint:CGPointMake(point2.x, weakself.chartY+weakself.chartHeight)];
                }
            }];
        }
        
        //        //如果结尾有字显示则计算位置
        //        if ([weakself.dataSource respondsToSelector:@selector(introductionOfLinesInChartView:)])
        //        {
        //            CGFloat inset = 0;
        //            if ([weakself.dataSource respondsToSelector:@selector(introductionXInsetOfLinesInChartView:)])
        //            {
        //                inset = [[weakself.dataSource introductionXInsetOfLinesInChartView:self][idx] floatValue];
        //            }
        //            NSString *introduction = [weakself.dataSource introductionOfLinesInChartView:self][idx];
        //            CGFloat introductWidth = [introduction boundingRectWithSize:CGSizeMake(100, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:IndexFont} context:nil].size.width;
        //            CGRect introductRect = CGRectMake(weakself.chartX+weakself.chartWidth-introductWidth-3+inset, [[linePoints lastObject] CGPointValue].y-6, introductWidth, 12);
        //            [introductRectArr addObject:[NSValue valueWithCGRect:introductRect]];
        //
        //            UIBezierPath *circlePath = [UIBezierPath bezierPathWithArcCenter:CGPointMake(introductRect.origin.x+introductRect.size.width/2, introductRect.origin.y+introductRect.size.height/2) radius:introductWidth/1.8 startAngle:0 endAngle:2*M_PI clockwise:YES];
        //            circlePath.lineWidth = 0.5;
        //            [fillColor setFill];
        //            [circlePath fill];
        //            if ([weakself.dataSource respondsToSelector:@selector(lineColorsForChartView:)])
        //            {
        //                UIColor *circleLineColor = [weakself.dataSource lineColorsForChartView:self][idx];
        //                [circleLineColor set];
        //                [circlePath stroke];
        //            }
        //        }
        
        
    }];
    
    /*画折线*/
    
    
    [_lineCoordinates enumerateObjectsUsingBlock:^(NSArray *linePoints, NSUInteger idx, BOOL * _Nonnull stop) {
        
        //如果有设置线的颜色，则设置线的颜色
        UIColor *lineColor;
        if ([weakself.dataSource respondsToSelector:@selector(lineColorsForChartView:)])
        {
            lineColor = [weakself.dataSource lineColorsForChartView:weakself][idx];
        }
        else
        {
            lineColor = [UIColor redColor];
        }
        
        //如果只有2个点，直接画直线
        if (linePoints.count == 2)
        {
            CGContextSetStrokeColorWithColor(context, lineColor.CGColor);
            CGContextMoveToPoint(context, [[linePoints firstObject] CGPointValue].x, [[linePoints firstObject] CGPointValue].y);
            CGContextAddLineToPoint(context, [[linePoints lastObject] CGPointValue].x, [[linePoints lastObject] CGPointValue].y);
            CGContextStrokePath(context);
        }
        //如果超过两个点，画曲线
        else if (linePoints.count >2)
        {
            UIBezierPath *bezierPath = [UIBezierPath bezierPath];
            UIBezierPath *noBezierPath = [UIBezierPath bezierPath];
            //            [lineColor set];
            //            bezierPath.lineWidth = 1;
            //            bezierPath.lineCapStyle = kCGLineCapRound;
            //            bezierPath.lineJoinStyle = kCGLineCapRound;
            
            [linePoints enumerateObjectsUsingBlock:^(NSValue *pointValue, NSUInteger idx1, BOOL * _Nonnull stop) {
                CGPoint frontPoint;
                CGPoint point1;
                CGPoint point2;
                CGPoint backPoint;
                
                if (idx1 == 0)
                {
                    frontPoint = [pointValue CGPointValue];
                    point1 = [pointValue CGPointValue];
                    point2 = [linePoints[idx1+1] CGPointValue];
                    backPoint = [linePoints[idx1+2] CGPointValue];
                }
                else if (idx1 == linePoints.count-2)
                {
                    frontPoint = [linePoints[idx1-1] CGPointValue];
                    point1 = [pointValue CGPointValue];
                    point2 = [linePoints[idx1+1] CGPointValue];
                    backPoint = [linePoints[idx1+1] CGPointValue];
                }
                else if (idx1 == linePoints.count -1)
                {
                    frontPoint = [linePoints[idx1-1] CGPointValue];
                    point1 = [pointValue CGPointValue];
                    point2 = [pointValue CGPointValue];
                    backPoint = [pointValue CGPointValue];
                }
                else
                {
                    frontPoint = [linePoints[idx1-1] CGPointValue];
                    point1 = [pointValue CGPointValue];
                    point2 = [linePoints[idx1+1] CGPointValue];
                    backPoint = [linePoints[idx1+2] CGPointValue];
                }
                
                if (idx1 == 0)
                {
                    [bezierPath moveToPoint:point1];
                    NSDictionary *ControlDic = [weakself controlPointOfBezierWithPointFront:frontPoint Point1:point1 Point2:point2 PointBack:backPoint];
                    CGPoint controlA = [ControlDic[@"A"] CGPointValue];
                    CGPoint controlB = [ControlDic[@"B"] CGPointValue];
                    
                    [bezierPath addCurveToPoint:point2 controlPoint1:controlA controlPoint2:controlB];
                    
                    [noBezierPath moveToPoint:CGPointMake(weakself.chartX, weakself.chartY+weakself.chartHeight)];
                    [noBezierPath addLineToPoint:CGPointMake(point2.x, weakself.chartY+weakself.chartHeight)];
                }
                else if (idx1 == linePoints.count-1)
                {
                    //                    [bezierPath stroke];
                    
                    CAShapeLayer *strokeLayer = [CAShapeLayer layer];
                    strokeLayer = [CAShapeLayer layer];
                    strokeLayer.frame = weakself.bounds;
                    strokeLayer.path = bezierPath.CGPath;
                    strokeLayer.strokeColor = [lineColor CGColor];
                    strokeLayer.fillColor = nil;
                    strokeLayer.lineWidth = 1;
                    strokeLayer.lineJoin = kCALineJoinRound;
                    CABasicAnimation *strokeAnimation = [CABasicAnimation animationWithKeyPath:@"path"];
                    strokeAnimation.duration = 0.25;
                    strokeAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
                    strokeAnimation.fillMode = kCAFillModeForwards;
                    strokeAnimation.fromValue = (id)noBezierPath.CGPath;
                    strokeAnimation.toValue = (id)bezierPath.CGPath;
                    [strokeLayer addAnimation:strokeAnimation forKey:@"path"];
                    
                    [weakself.layer addSublayer:strokeLayer];
                    [weakself.stokeLayers addObject:strokeLayer];
                }
                else
                {
                    NSDictionary *ControlDic = [weakself controlPointOfBezierWithPointFront:frontPoint Point1:point1 Point2:point2 PointBack:backPoint];
                    CGPoint controlA = [ControlDic[@"A"] CGPointValue];
                    CGPoint controlB = [ControlDic[@"B"] CGPointValue];
                    
                    [bezierPath addCurveToPoint:point2 controlPoint1:controlA controlPoint2:controlB];
                    
                    [noBezierPath addLineToPoint:CGPointMake(point2.x, weakself.chartY+weakself.chartHeight)];
                }
            }];
        }
    }];
    
    [introductRectArr enumerateObjectsUsingBlock:^(NSValue *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *introduction = [weakself.dataSource introductionOfLinesInChartView:weakself][idx];
        [introduction drawInRect:[obj CGRectValue] withAttributes:@{NSFontAttributeName:IndexFont,NSForegroundColorAttributeName:IntroductColor}];
    }];
}

-(void)calculateCoordinate
{
    NSArray *dataSourceValues = [self.dataSource datasOfLinesInChartView:self];
    
    //取出数据源数组最大数和最小数
    _maxValue = FLT_MIN;
    _minValue = FLT_MAX;
    typeof (self)weakself = self;
    [dataSourceValues enumerateObjectsUsingBlock:^(NSArray *lineDatas, NSUInteger idx, BOOL * _Nonnull stop) {
        [lineDatas enumerateObjectsUsingBlock:^(NSNumber *value, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([value floatValue]>weakself.maxValue)
            {
                weakself.maxValue = [value floatValue];
            }
            if ([value floatValue]<weakself.minValue)
            {
                weakself.minValue = [value floatValue];
            }
        }];
    }];
    
    NSLog(@"%f",_maxValue);
    //计算大概步长
    if (_yIndexCount < 3)
    {
        _yIndexCount = 3;
    }
    float yStep = (_maxValue - _minValue)/(_yIndexCount - 2);
    
    //计算步长的位数
    int OrderOfMagnitude = 1;
    while (yStep>=OrderOfMagnitude*10)
    {
        OrderOfMagnitude *= 10;
    }
    
    //计算实际步长
    int yStepInt = roundf(yStep*10/OrderOfMagnitude)*(OrderOfMagnitude/10);
    
    float theMinValue = floorf(_minValue/yStepInt)*yStepInt;
    
    if (_minValue-theMinValue < yStepInt/2)
    {
        _minValue = theMinValue - yStepInt/2;
    }
    else
    {
        _minValue = theMinValue;
    }
    
    if (_maxValue > _minValue + (_yIndexCount-1)*yStepInt - yStepInt/2)
    {
        yStepInt += (int)(yStepInt*0.1);
    }
    
    _maxValue = _minValue + (_yIndexCount-1)*yStepInt;
    
    NSMutableArray *valueArr = [NSMutableArray arrayWithCapacity:_yIndexCount];
    for (int i=0; i<_yIndexCount; i++)
    {
        [valueArr addObject:[NSString stringWithFormat:@"%d",(int)(_minValue + i*yStepInt)]];
    }
    _yIndexStrings = valueArr;
    
    //计算点的位置，先考虑偏移量
    __block CGFloat yIndexPadding = 0.f;
    [valueArr enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        CGFloat padding = [obj boundingRectWithSize:CGSizeMake(100, CGFLOAT_MAX)
                                            options:NSStringDrawingUsesLineFragmentOrigin
                                         attributes:@{NSFontAttributeName:IndexFont}
                                            context:nil].size.width;
        if (padding > yIndexPadding)
        {
            yIndexPadding = padding;
        }
    }];
    
    //图表实际位置
    _chartX = leftPadding + yIndexPadding + 3;
    _chartY = topPadding;
    _chartWidth = self.frame.size.width - _chartX - rightPadding;
    _chartHeight = self.frame.size.height - topPadding - bottomPadding - 20;
    
    //重组线的位置转换为坐标
    __block NSMutableArray *lineCoordinates = [NSMutableArray arrayWithCapacity:dataSourceValues.count];
    
    //先获得所有线中横坐标最长的那个
    __block int xIndexCount = 0;
    [dataSourceValues enumerateObjectsUsingBlock:^(NSArray *lineDatas, NSUInteger idx, BOOL * _Nonnull stop) {
        if (lineDatas.count > xIndexCount)
        {
            xIndexCount = (int)lineDatas.count;
        }
    }];
    
    CGFloat Xstep = _chartWidth/(xIndexCount-1);
    //计算坐标位置
    [dataSourceValues enumerateObjectsUsingBlock:^(NSArray *lineDatas, NSUInteger idx1, BOOL * _Nonnull stop) {
        __block NSMutableArray *linePoints = [NSMutableArray arrayWithCapacity:lineDatas.count];
        [lineDatas enumerateObjectsUsingBlock:^(NSNumber *value, NSUInteger idx2, BOOL * _Nonnull stop) {
            CGFloat x = Xstep*idx2+weakself.chartX;
            CGFloat y = ((weakself.maxValue-value.floatValue)/(weakself.maxValue-weakself.minValue))*_chartHeight+weakself.chartY;
            CGPoint valuePoint = CGPointMake(x, y);
            [linePoints addObject:[NSValue valueWithCGPoint:valuePoint]];
        }];
        [lineCoordinates addObject:linePoints];
    }];
    
    _lineCoordinates = lineCoordinates;
    
    //计算水平线的位置
    NSMutableArray *horizonLinesPoints = [NSMutableArray arrayWithCapacity:self.yIndexCount];
    for (int i = 0; i<self.yIndexCount; i++)
    {
        CGPoint startValue = CGPointMake(_chartX, _chartY+i*_chartHeight/(self.yIndexCount-1));
        CGPoint endValue = CGPointMake(_chartX+_chartWidth, _chartY+i*_chartHeight/(self.yIndexCount-1));
        [horizonLinesPoints addObject:@{@"start":[NSValue valueWithCGPoint:startValue],
                                        @"end":[NSValue valueWithCGPoint:endValue]}];
    }
    _horizonLinesPoints = horizonLinesPoints;
    
    //计算垂直线的位置
    NSMutableArray *verticalLinesPoints = [NSMutableArray arrayWithCapacity:[self.dataSource XIndexsInChartView:self].count];
    CGFloat XlineStep = ((xIndexCount-1)/([self.dataSource XIndexsInChartView:self].count-1))*Xstep;
    for (int i = 0; i<[self.dataSource XIndexsInChartView:self].count; i++)
    {
        CGPoint startValue = CGPointMake(_chartX+XlineStep*i, _chartY);
        CGPoint endValue = CGPointMake(_chartX+XlineStep*i, _chartY+_chartHeight);
        [verticalLinesPoints addObject:@{@"start":[NSValue valueWithCGPoint:startValue],
                                         @"end":[NSValue valueWithCGPoint:endValue]}];
    }
    _verticalLinesPoints = verticalLinesPoints;
    
}

-(void)reloadData
{
    [self setNeedsDisplay];
}

-(NSDictionary *)controlPointOfBezierWithPointFront:(CGPoint )frontPoint Point1:(CGPoint )point1 Point2:(CGPoint )point2 PointBack:(CGPoint )backPoint
{
    float ControlAx = point1.x+(point2.x-frontPoint.x)*.25;
    float ControlAy = point1.y+(point2.y-frontPoint.y)*.25;
    float ControlBx = point2.x-(backPoint.x-point1.x)*.25;
    float ControlBy = point2.y-(backPoint.y-point1.y)*.25;
    CGPoint ControlA = CGPointMake(ControlAx, ControlAy);
    CGPoint ControlB = CGPointMake(ControlBx, ControlBy);
    return  @{@"A":[NSValue valueWithCGPoint:ControlA],
              @"B":[NSValue valueWithCGPoint:ControlB]};
}

@end
