//
//  ResultsViewController.h
//  FaceFacts
//
//  Created by Jerrad Thramer on 5/12/14.
//  Copyright (c) 2014 JerradThramer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SFGaugeView.h"

@interface ResultsViewController : UIViewController
@property (nonatomic, strong) NSDictionary *resultsDict;
@property (nonatomic, weak) IBOutlet SFGaugeView *gaugeView;
@property (nonatomic, weak) IBOutlet UILabel *ageLabel;
@property (nonatomic, weak) IBOutlet UILabel *sexLabel;
@property (nonatomic, weak) IBOutlet UILabel *sexConfidenceLabel;
@property (nonatomic, weak) IBOutlet UILabel *raceLabel;
@property (nonatomic, weak) IBOutlet UILabel *raceConfidenceLabel;
-(IBAction)doneClicked:(id)sender;
@end
