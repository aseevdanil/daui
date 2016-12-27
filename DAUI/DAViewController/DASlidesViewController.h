//
//  DASlidesViewController.h
//  daui
//
//  Created by da on 03.04.14.
//  Copyright (c) 2014 Aseev Danil. All rights reserved.
//

#import "DAViewController.h"



@interface DASlidesViewController : DAViewController <DASlidesViewDataSource, DASlidesViewDelegate>
{
	DASlidesView *_slidesView;
	
	struct
	{
		unsigned int slidesViewReady : 1;
	}
	_daSlidesViewController;
}

@property (nonatomic, strong, readonly) DASlidesView *slidesView;
- (BOOL)isSlidesViewReady;
- (void)slidesViewDidReady;

@end
