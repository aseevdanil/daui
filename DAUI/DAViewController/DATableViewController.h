//
//  DATableViewController.h
//  daui
//
//  Created by da on 03.04.14.
//  Copyright (c) 2014 Aseev Danil. All rights reserved.
//

#import "DAScrollViewController.h"



@interface DATableViewController : DAScrollViewController <UITableViewDataSource, UITableViewDelegate>
{
	struct
	{
		unsigned int tableViewStyle : 1;
		unsigned int tableViewReady : 1;
		unsigned int autoscrollToCellWithFirstResponder : 1;
	}
	_daTableViewControllerFlags;
}

- (instancetype)initWithStyle:(UITableViewStyle)style;
@property (nonatomic, assign, readonly) UITableViewStyle tableViewStyle;

@property(nonatomic, strong, readonly) UITableView *tableView;
- (BOOL)isTableViewReady;
- (void)tableViewDidReady;
- (void)updateTableViewLayout;

@property (nonatomic, assign, getter = isAutoscrollToCellWithFirstResponder) BOOL autoscrollToCellWithFirstResponder;

@end
