//
//  DATableViewController.m
//  daui
//
//  Created by da on 03.04.14.
//  Copyright (c) 2014 Aseev Danil. All rights reserved.
//

#import "DATableViewController.h"



@implementation DATableViewController


#pragma mark -
#pragma mark Base


#define _tableView ((UITableView*) self.scrollView)


- (instancetype)init
{
	return [self initWithStyle:UITableViewStylePlain];
}


- (instancetype)initWithStyle:(UITableViewStyle)style
{
	if ((self = [super init]))
	{
		_daTableViewControllerFlags.tableViewStyle = style;
		_daTableViewControllerFlags.tableViewReady = NO;
		_daTableViewControllerFlags.autoscrollToCellWithFirstResponder = YES;
	}
	return self;
}


- (void)dealloc
{
	if (_daTableViewControllerFlags.tableViewReady)
	{
		_daTableViewControllerFlags.tableViewReady = NO;
		_tableView.dataSource = nil;
		_tableView.delegate = nil;
	}
}


- (UITableViewStyle)tableViewStyle
{
	return _daTableViewControllerFlags.tableViewStyle;
}


- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
	[super setEditing:editing animated:animated];
	
	if ([self isViewLoaded])
		[self.tableView setEditing:editing animated:animated];
}


- (void)dockedKeyboardFrameWillChangeWithDuration:(NSTimeInterval)duration curve:(UIViewAnimationCurve)curve
{
	[super dockedKeyboardFrameWillChangeWithDuration:duration curve:curve];

	if (_daTableViewControllerFlags.autoscrollToCellWithFirstResponder)
	{
		if (!CGRectIsNull([DAViewController dockedKeyboardFrame]))
		{
			UIView *firstResponder = [self.tableView findFirstResponder];
			UITableViewCell *cell = firstResponder ? (UITableViewCell*) firstResponder.superview : nil;
			while (cell && ![cell isKindOfClass:[UITableViewCell class]])
				cell = (UITableViewCell*) cell.superview;
			if (cell)
			{
				NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
				DASSERT(indexPath);
				if (indexPath)
					[self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionNone animated:YES];
			}
		}
	}
}


- (BOOL)isAutoscrollToCellWithFirstResponder
{
	return _daTableViewControllerFlags.autoscrollToCellWithFirstResponder;
}


- (void)setAutoscrollToCellWithFirstResponder:(BOOL)autoscrollToCellWithFirstResponder
{
	_daTableViewControllerFlags.autoscrollToCellWithFirstResponder = autoscrollToCellWithFirstResponder;
}


#pragma mark -
#pragma mark View


- (UITableView*)tableView
{
	return _tableView;
}


- (void)loadScrollView
{
	self.scrollView = [[UITableView alloc] initWithFrame:CGRectZero style:_daTableViewControllerFlags.tableViewStyle];
}


- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.tableView.editing = self.isEditing;
}


- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	if (!_daTableViewControllerFlags.tableViewReady)
	{
		[self updateTableViewLayout];
		_daTableViewControllerFlags.tableViewReady = YES;
		_tableView.dataSource = self;
		_tableView.delegate = self;
		[_tableView reloadData];
		[self tableViewDidReady];
	}
}


- (void)didLayoutScrollView
{
	[super didLayoutScrollView];
	
	if (!_daTableViewControllerFlags.tableViewReady)
	{
		[self updateTableViewLayout];
		_daTableViewControllerFlags.tableViewReady = YES;
		_tableView.dataSource = self;
		_tableView.delegate = self;
		[_tableView reloadData];
		[self tableViewDidReady];
	}
}


- (BOOL)isTableViewReady
{
	return _daTableViewControllerFlags.tableViewReady;
}


- (void)tableViewDidReady
{
}


- (void)updateTableViewLayout
{
}


- (void)viewWillClear
{
	[super viewWillClear];
	
	if (_daTableViewControllerFlags.tableViewReady)
	{
		_daTableViewControllerFlags.tableViewReady = NO;
		_tableView.dataSource = nil;
		_tableView.delegate = nil;
	}
}


#pragma mark -
#pragma mark UITableViewDataSource & UITableViewDelegate


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	DASSERT(NO);
	return 0;
}


- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	DASSERT(NO);
	return nil;
}


@end
