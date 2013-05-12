//
//  DMViewController.m
//  DMSlidingCell
//
//  Created by Daniele Margutti on 6/29/12.
//  Copyright (c) 2012 Daniele Margutti. All rights reserved.
//

#import "DMViewController.h"
#import "DMSlidingTableViewCell.h"

@interface DMViewController () <UITableViewDelegate> {
    IBOutlet    UITableView* mainTableView;
    IBOutlet    UISwitch*   resetStateOnScrolling;
    NSMutableIndexSet*      revealedCells;
    BOOL _swipeEnabled;
}
- (IBAction)btn_toggleManually:(id)sender;
- (IBAction)btn_webSite:(id)sender;
- (void) resetCellsState;

@end

@implementation DMViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    revealedCells= [[NSMutableIndexSet alloc] init];

    _swipeEnabled = YES;
    
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (IBAction)btn_webSite:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.danielemargutti.com"]];
}

- (IBAction)btn_toggleManually:(id)sender {
    DMSlidingTableViewCell *cell = (DMSlidingTableViewCell*)[mainTableView cellForRowAtIndexPath:
                                                             [NSIndexPath indexPathForRow:0 inSection:0]];
    if([cell toggleCellStatus] == NO) {
        UIAlertView *a = [[UIAlertView alloc] initWithTitle:@"Swipe to a direction before"
                                                    message:@"Toggle will reset and re-apply your swipe"
                                                   delegate:nil
                                          cancelButtonTitle:@"Ok" otherButtonTitles:nil];
        [a show];
    }
}

- (void) resetCellsState {
    [revealedCells enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        DMSlidingTableViewCell *cell = ((DMSlidingTableViewCell*)[mainTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:idx inSection:0]]);
        [cell setBackgroundVisible:NO];
    }];
}

#pragma mark -

/** Any swiped cell should be reset when we start to scroll. */
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    NSLog(@"%s", __PRETTY_FUNCTION__);

    if (resetStateOnScrolling.isOn)
        [self resetCellsState];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    _swipeEnabled = NO;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    _swipeEnabled = YES;
}

- (BOOL)slidingCellShouldAcceptSwipe {
    return _swipeEnabled;
}

- (void)slidingCellStartedSliding {
    mainTableView.scrollEnabled = NO;
}

- (void)slidingCellStoppedSliding {
    mainTableView.scrollEnabled = YES;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60.0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 30;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"CELL_IDENTIFIER";
    
    DMSlidingTableViewCell *cell = (DMSlidingTableViewCell *)[tableView dequeueReusableCellWithIdentifier:identifier];
    
    if (cell == nil) {
        cell = [[DMSlidingTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                             reuseIdentifier:identifier];
        cell.swipeDirection = DMSlidingTableViewCellSwipeBoth;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.delegate = self;
        cell.shelfSize = 40.0f;
    }
    
    cell.eventHandler = ^(DMEventType eventType, BOOL backgroundRevealed, DMSlidingTableViewCellSwipe swipeDirection) {
        if (eventType == DMEventTypeDidOccurr) {
            if (backgroundRevealed)
                [revealedCells addIndex:indexPath.row];
            else [revealedCells removeIndex:indexPath.row];
        }
    };
    
    cell.contentView.backgroundColor = [UIColor whiteColor];
    cell.textLabel.text = [NSString stringWithFormat:@"Cell #%d", indexPath.row];
    cell.detailTextLabel.text = @"Swipe me to right/left to see the magic!";
    
    return cell;
}

@end
