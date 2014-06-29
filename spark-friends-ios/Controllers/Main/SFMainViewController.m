//
//  SFMainViewController.m
//  spark-friends-ios
//
//  Created by Terry Worona on 6/10/14.
//  Copyright (c) 2014 Jawbone. All rights reserved.
//

#import "SFMainViewController.h"

// Views
#import "SFUserTableViewCell.h"

// Model
#import "SFDataModel.h"
#import "SFUser+Additions.h"
#import "SFStep.h"

// Controllers
#import "SFBaseNavigationController.h"
#import "SFChartViewController.h"

// Enums
typedef NS_ENUM(NSInteger, SFMainViewControllerSection){
    SFMainViewControllerSectionCurrentUser,
	SFMainViewControllerSectionFriends,
    SFMainViewControllerSectionCount
};

// Strings
NSString * const kSFMainViewControllerCellIdentifier = @"kSFMainViewControllerCellIdentifier";

// Numerics
CGFloat static const kSFMainViewControllerLineChartLineWidth = 2.0f;

@interface SFDataModel (Private)

- (NSArray *)users;

@end

@interface SFMainViewController () <SFLineChartViewDataSource, JBLineChartViewDelegate>

@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@end

@implementation SFMainViewController

#pragma mark - View Lifecycle

- (void)loadView
{
    [super loadView];

    self.title = kSFStringLabelProfile;
    self.view.backgroundColor = kSFColorBaseBackgroundColor;
    
    [self.tableView registerClass:[SFUserTableViewCell class] forCellReuseIdentifier:kSFMainViewControllerCellIdentifier];
    [self.tableView setSeparatorInset:UIEdgeInsetsZero];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return SFMainViewControllerSectionCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == SFMainViewControllerSectionCurrentUser)
    {
        return 1;
    }
    else if (section == SFMainViewControllerSectionFriends)
    {
        return [[[SFDataModel sharedInstance].currentUser friends] count];
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SFUserTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kSFMainViewControllerCellIdentifier forIndexPath:indexPath];
    
    SFUser *user;
    if (indexPath.section == SFMainViewControllerSectionCurrentUser)
    {
        user = [SFDataModel sharedInstance].currentUser;
        cell.lineChartView.tag = indexPath.row;
    }
    else if (indexPath.section == SFMainViewControllerSectionFriends)
    {
        user = [[[SFDataModel sharedInstance].currentUser friends] objectAtIndex:indexPath.row];
        cell.lineChartView.tag = indexPath.row + 1;
    }
    cell.userImageView.image = user.profileImage;
    cell.nameLabel.text = [user fullName];
    cell.dateLabel.text = [NSString stringWithFormat:@"Member since %@", [self.dateFormatter stringFromDate:user.createDate]];
    
    cell.lineChartView.delegate = self;
    cell.lineChartView.dataSource = self;
    
    [cell.lineChartView reloadData];
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == SFMainViewControllerSectionCurrentUser)
    {
        return kSFStringLabelCurrentUser;
    }
    else if (section == SFMainViewControllerSectionFriends)
    {
        return kSFStringLabelFriends;
    }
    return nil;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    SFUser *user;
    if (indexPath.section == SFMainViewControllerSectionCurrentUser)
    {
        user = [SFDataModel sharedInstance].currentUser;
    }
    else if (indexPath.section == SFMainViewControllerSectionFriends)
    {
        user = [[[SFDataModel sharedInstance].currentUser friends] objectAtIndex:indexPath.row];
    }
    
    SFChartViewController *chartViewController = [[SFChartViewController alloc] initWithUser:user];
    SFBaseNavigationController *navigationController = [[SFBaseNavigationController alloc] initWithRootViewController:chartViewController];
    [self.navigationController presentViewController:navigationController animated:YES completion:nil];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return kSFUserTableViewCellHeight;
}

#pragma mark - SFLineChartViewDataSource

- (NSUInteger)numberOfLinesInLineChartView:(JBLineChartView *)lineChartView;
{
    return 1;
}

- (NSUInteger)lineChartView:(JBLineChartView *)lineChartView numberOfVerticalValuesAtLineIndex:(NSUInteger)lineIndex
{
    SFUser *user = [[[SFDataModel sharedInstance] users] objectAtIndex:lineChartView.tag];
    return [user.steps count];
}

- (UIColor *)lineChartView:(JBLineChartView *)lineChartView colorForLineAtLineIndex:(NSUInteger)lineIndex
{
    return kSFColorChartLineColor;
}

- (CGFloat)lineChartView:(JBLineChartView *)lineChartView widthForLineAtLineIndex:(NSUInteger)lineIndex
{
    return kSFMainViewControllerLineChartLineWidth;
}

- (NSUInteger)minimumAverageInLineChartView:(JBLineChartView *)lineChartView
{
    SFUser *user = [[[SFDataModel sharedInstance] users] objectAtIndex:lineChartView.tag];
    return [user averageStepValue] + ceil([user averageStepValue] * 0.5);
}

- (NSUInteger)maximumAverageInLineChartView:(JBLineChartView *)lineChartView
{
    SFUser *user = [[[SFDataModel sharedInstance] users] objectAtIndex:lineChartView.tag];
    return [user averageStepValue] - ceil([user averageStepValue] * 0.5);
}

#pragma mark - JBLineChartViewDelegate

- (CGFloat)lineChartView:(JBLineChartView *)lineChartView verticalValueForHorizontalIndex:(NSUInteger)horizontalIndex atLineIndex:(NSUInteger)lineIndex
{
    SFUser *user = [[[SFDataModel sharedInstance] users] objectAtIndex:lineChartView.tag];
    SFStep *step = [user.steps objectAtIndex:horizontalIndex];
    return step.value;
}

- (BOOL)lineChartView:(JBLineChartView *)lineChartView smoothLineAtLineIndex:(NSUInteger)lineIndex
{
    return YES;
}

#pragma mark - Getters

- (NSDateFormatter *)dateFormatter
{
    if (_dateFormatter == nil)
    {
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setDateStyle:NSDateFormatterShortStyle];
    }
    return _dateFormatter;
}

@end
