//
//  ViewController.m
//  zvChartView
//
//  Created by wangziwei on 16/4/26.
//  Copyright © 2016年 zv. All rights reserved.
//

#import "ViewController.h"
#import "ZVChartView.h"

@interface ViewController ()<ZVChartViewDataSource>
@property (nonatomic, strong) ZVChartView *chartView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.chartView = [[ZVChartView alloc] initWithFrame:CGRectMake(5, 60, self.view.bounds.size.width-10, 150)];
    self.chartView.backgroundColor = [UIColor whiteColor];
    self.chartView.yIndexCount = 6;
    self.chartView.dataSource = self;
    [self.view addSubview:self.chartView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(NSInteger)numberOfLinesInChartView:(ZVChartView *)chartView
{
    return 4;
}

-(NSArray *)datasOfLinesInChartView:(ZVChartView *)chartView
{
    NSMutableArray *arr = [NSMutableArray arrayWithCapacity:5];
    for (int i = 0 ; i<4; i++)
    {
        NSMutableArray *numArr = [NSMutableArray arrayWithCapacity:100];
        int randamNum = 1500;
        NSNumber *num = [NSNumber numberWithInteger:randamNum];
        [numArr addObject:num];
        switch (i)
        {
            case 0:
            {
                for (int i = 0; i<100; i++)
                {
                    int code = arc4random()%2;
                    if (code == 0)
                    {
                        code = -1;
                    }
                    randamNum = randamNum + arc4random()%6*3 + code*3;
                    NSNumber *num = [NSNumber numberWithInteger:randamNum];
                    [numArr addObject:num];
                }
            }
                break;
            case 1:
            {
                float code = 1+arc4random()%10/10.f;
                [numArr replaceObjectAtIndex:0 withObject:[NSNumber numberWithInteger:1500*code]];
                for (int i = 0; i<100; i++)
                {
                    NSNumber *num = [NSNumber numberWithInteger:1500*code];
                    [numArr addObject:num];
                }
            }
                break;
            case 2:
            {
                for (int i = 0; i<100; i++)
                {
                    int code = arc4random()%2;
                    if (code == 0)
                    {
                        code = -1;
                    }
                    randamNum = randamNum + code*arc4random()%5*2;
                    NSNumber *num = [NSNumber numberWithInteger:randamNum];
                    [numArr addObject:num];
                }
            }
                break;
            default:
            {
                for (int i = 0; i<100; i++)
                {
                    int code = arc4random()%2;
                    if (code == 0)
                    {
                        code = -1;
                    }
                    randamNum = randamNum - arc4random()%4*2 - code*2;
                    NSNumber *num = [NSNumber numberWithInteger:randamNum];
                    [numArr addObject:num];
                }
            }
                break;
        }
        [arr addObject:numArr];
    }
    return arr;
//    return @[@[@40.5,@62.2,@43.6,@64.8,@46.5,@48.5,@51.2,@55.6,@60.8,@66.8,@78.3],
//             @[@60,@60,@60,@60,@60,@60,@60,@60,@60,@60,@60],
//             @[@50.2,@42.5,@44.6,@47.2,@52.8,@60.8,@64.5,@67.6,@69.4,@71.7,@72.5],
//             @[@25.5,@38.5,@37.6,@36.2,@36.8,@38.8,@40.5,@41.6,@43.4,@42.7,@45.5]];
}

-(NSArray *)XIndexsInChartView:(ZVChartView *)chartView
{
    return @[@"2016-4",@"2016-8",@"2016-12",@"2017-4",@"2017-8"];
}

-(NSArray *)lineColorsForChartView:(ZVChartView *)chartView
{
    return @[[UIColor colorWithRed:85.f/255.f green:199.f/255.f blue:236.f/255.f alpha:1]/*蓝色*/,
             [UIColor colorWithRed:69.f/255.f green:193.f/255.f blue:52.f/255.f alpha:1]/*绿色*/,
             [UIColor colorWithRed:170.f/255.f green:143.f/255.f blue:247.f/255.f alpha:1]/*紫色*/,
             [UIColor colorWithRed:255.f/255.f green:111.f/255.f blue:14.f/255.f alpha:1]/*红色*/];

}

-(NSArray *)fillColorsForChartView:(ZVChartView *)chartView
{
    return @[[UIColor colorWithRed:85.f/255.f green:199.f/255.f blue:236.f/255.f alpha:0.2]/*蓝色*/,
             [UIColor colorWithRed:59.f/255.f green:170.f/255.f blue:223.f/255.f alpha:0.2]/*绿色*/,
             [UIColor colorWithRed:170.f/255.f green:143.f/255.f blue:247.f/255.f alpha:0.2]/*紫色*/,
             [UIColor colorWithRed:30.f/255.f green:145.f/255.f blue:200.f/255.f alpha:0.2]/*红色*/];
}

-(NSArray *)introductionOfLinesInChartView:(ZVChartView *)chartView
{
    return @[@"最大值",@"目标",@"平均值",@"最低值"];
}

-(NSArray *)introductionXInsetOfLinesInChartView:(ZVChartView *)chartView
{
    return @[@-30,@-14,@10,@-10];
}


- (IBAction)reload:(id)sender
{
    [self.chartView reloadData];
}


@end
