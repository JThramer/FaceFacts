//
//  ResultsViewController.m
//  FaceFacts
//
//  Created by Jerrad Thramer on 5/12/14.
//  Copyright (c) 2014 JerradThramer. All rights reserved.
//

#import "ResultsViewController.h"

@interface ResultsViewController ()

@end

@implementation ResultsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
- (void)viewWillAppear:(BOOL)animated
{
    NSLog(@"resultsDict:%@", [self resultsDict]);
    
    NSString *sex = [self resultsDict][@"gender"][@"value"];
    float sexConfidence = [[self resultsDict][@"gender"][@"confidence"] floatValue];
    NSString *race = [self resultsDict][@"race"][@"value"];
    float raceConfidence = [[self resultsDict][@"race"][@"confidence"] floatValue];
    
    NSInteger smileValue = [[self resultsDict][@"smiling"][@"value"] integerValue];
    
    [[self ageLabel] setText:[self ageString]];
   
    [[self sexLabel] setText:sex];
    [[self sexConfidenceLabel] setText:[self confidenceStringFromValue:sexConfidence]];
  
    [[self raceLabel] setText:race];
    [[self raceConfidenceLabel] setText:[self confidenceStringFromValue:raceConfidence]];
    
    [[self gaugeView] setMaxlevel:100];
    [[self gaugeView] setMinImage:@"minImage"];
    [[self gaugeView] setMaxImage:@"maxImage"];
    [[self gaugeView] setHideLevel:YES];
    [[self gaugeView] setCurrentLevel:smileValue];
}
- (NSString*)ageString
{
    NSInteger range = [[self resultsDict][@"age"][@"range"] integerValue];
    NSInteger age = [[self resultsDict][@"age"][@"value"] integerValue];
    NSInteger lowerBound = age - range;
    NSInteger upperBound = age + range;
    return [NSString stringWithFormat:@"%ld-%ld", (long)lowerBound, (long)upperBound];
}
- (NSString *)confidenceStringFromValue:(float)value
{
    return [NSString stringWithFormat:@"%.1f%% Confidence", value];
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)doneClicked:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
