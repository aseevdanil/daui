//
//  DANavigationController.m
//  daui
//
//  Created by da on 16.03.12.
//  Copyright (c) 2012 Aseev Danil. All rights reserved.
//

#import "DANavigationController.h"



@interface DANavigationController () <UIGestureRecognizerDelegate>

- (void)updateNavigationStackWithPopedViewControllers:(NSArray*)popedViewControllers andPushedViewControllers:(NSArray*)pushedViewControllers;

@end


@implementation DANavigationController


#pragma mark -
#pragma mark Base


static char DANavigationControllerContext;


@synthesize navigationControllerDelegate = _navigationControllerDelegate;


- (instancetype)init
{
	return [self initWithNavigationBarClass:nil toolbarClass:nil];
}


- (instancetype)initWithNavigationBarClass:(Class)navigationBarClass toolbarClass:(Class)toolbarClass
{
	if ((self = [super initWithNavigationBarClass:navigationBarClass toolbarClass:toolbarClass]))
	{
		_daNavigationControllerFlags.navigationBarObserving = NO;
		_daNavigationControllerFlags.transitioning = _daNavigationControllerFlags.animationTransitioning = NO;
		_daNavigationControllerFlags.popViewController = _daNavigationControllerFlags.nestedPopViewController = NO;
		
		super.delegate = self;
		
		DASSERT(!_invocationQueue);
		_invocationQueue = [[NSMutableArray alloc] initWithCapacity:1];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
	}
	return self;
}


- (instancetype)initWithRootViewController:(UIViewController *)rootViewController
{
	if (self = [self initWithNavigationBarClass:nil toolbarClass:nil])
	{
		if (rootViewController)
			[self pushViewController:rootViewController animated:NO];
    }
    return self;
}


- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
	
	if (_daNavigationControllerFlags.navigationBarObserving)
	{
		_daNavigationControllerFlags.navigationBarObserving = NO;
		DASSERT([self isViewLoaded]);
		[self.navigationBar removeObserver:self forKeyPath:@"center" context:&DANavigationControllerContext];
		[self.navigationBar removeObserver:self forKeyPath:@"bounds" context:&DANavigationControllerContext];
	}
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (context == &DANavigationControllerContext)
	{
		if (object == self.navigationBar)
		{
			if ([keyPath isEqualToString:@"center"] || [keyPath isEqualToString:@"bounds"])
			{
				UIViewController *vc = self.topViewController;
				if (vc)
				{
					if ([vc isViewVisible])
						[vc.view setNeedsLayout];
					for (UIViewController *childVC in vc.childViewControllers)
					{
						if ([childVC isViewVisible])
							[childVC.view setNeedsLayout];
					}
				}
			}
		}
	}
	else
	{
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}


- (void)didReceiveMemoryWarning
{
	BOOL clearView = [self isViewLoaded] && !self.view.window && !self.presentedViewController && !self.presentingViewController;
	if (clearView)
		[self viewWillClear];
	
	[super didReceiveMemoryWarning];
	
	if ([self isViewLoaded] && !self.view.window)
		self.view = nil;
	
	if (clearView)
		[self viewDidClear];
}


- (void)applicationDidEnterBackground:(NSNotification*)notification
{
	BOOL clearView = [self isViewLoaded] && !self.view.window && !self.presentedViewController && !self.presentingViewController;
	if (clearView)
	{
		[self viewWillClear];
		self.view = nil;
		[self viewDidClear];
	}
}


- (BOOL)shouldAutorotate
{
	UIViewController *topViewController = self.topViewController;
	return topViewController ? [topViewController shouldAutorotate] : [super shouldAutorotate];
}


- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
	UIViewController *topViewController = self.topViewController;
	return topViewController ? [topViewController supportedInterfaceOrientations] : [super supportedInterfaceOrientations];
}


- (UIViewController *)childViewControllerForStatusBarHidden
{
	UIViewController *topViewController = self.topViewController;
	return topViewController ?: [super childViewControllerForStatusBarHidden];
}


- (UIViewController *)childViewControllerForStatusBarStyle
{
	UIViewController *topViewController = self.topViewController;
	return topViewController ?: [super childViewControllerForStatusBarStyle];
}


#pragma mark -
#pragma mark UIGestureRecognizerDelegate


- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
	return !_daNavigationControllerFlags.animationTransitioning && [self.viewControllers count] > 1;
	//id <UIGestureRecognizerDelegate> strongDelegate = _standardInteractivePopGestureRecognizerDelegate;
	//if (strongDelegate && [strongDelegate respondsToSelector:@selector(gestureRecognizerShouldBegin:)])
	//	return [strongDelegate gestureRecognizerShouldBegin:gestureRecognizer];
	//return YES;
}


- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
	id <UIGestureRecognizerDelegate> strongDelegate = _standardInteractivePopGestureRecognizerDelegate;
	if (strongDelegate && [strongDelegate respondsToSelector:@selector(gestureRecognizer:shouldRecognizeSimultaneouslyWithGestureRecognizer:)])
		return [strongDelegate gestureRecognizer:gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:otherGestureRecognizer];
	return NO;
}


- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRequireFailureOfGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
	id <UIGestureRecognizerDelegate> strongDelegate = _standardInteractivePopGestureRecognizerDelegate;
	if (strongDelegate && [strongDelegate respondsToSelector:@selector(gestureRecognizer:shouldRequireFailureOfGestureRecognizer:)])
		return [strongDelegate gestureRecognizer:gestureRecognizer shouldRequireFailureOfGestureRecognizer:otherGestureRecognizer];
	return NO;
}


- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
	id <UIGestureRecognizerDelegate> strongDelegate = _standardInteractivePopGestureRecognizerDelegate;
	if (strongDelegate && [strongDelegate respondsToSelector:@selector(gestureRecognizer:shouldBeRequiredToFailByGestureRecognizer:)])
		return [strongDelegate gestureRecognizer:gestureRecognizer shouldBeRequiredToFailByGestureRecognizer:otherGestureRecognizer];
	return NO;
}


- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch;
{
	return YES;
	//id <UIGestureRecognizerDelegate> strongDelegate = _standardInteractivePopGestureRecognizerDelegate;
	//if (strongDelegate && [strongDelegate respondsToSelector:@selector(gestureRecognizer:shouldReceiveTouch:)])
	//	return [strongDelegate gestureRecognizer:gestureRecognizer shouldReceiveTouch:touch];
	//return YES;
}


#pragma mark -
#pragma mark View And State


- (void)viewDidLoad
{
	[super viewDidLoad];
	
	if ([self respondsToSelector:@selector(interactivePopGestureRecognizer)])
	{
		DASSERT(self.interactivePopGestureRecognizer);
		_standardInteractivePopGestureRecognizerDelegate = self.interactivePopGestureRecognizer.delegate;
		self.interactivePopGestureRecognizer.delegate = self;
	}
	
	DASSERT(!_daNavigationControllerFlags.navigationBarObserving);
	if (!_daNavigationControllerFlags.navigationBarObserving)
	{
		[self.navigationBar addObserver:self forKeyPath:@"center" options:0 context:&DANavigationControllerContext];
		[self.navigationBar addObserver:self forKeyPath:@"bounds" options:0 context:&DANavigationControllerContext];
		_daNavigationControllerFlags.navigationBarObserving = YES;
	}
}


- (void)viewWillClear
{
	[super viewWillClear];
	
	if ([self respondsToSelector:@selector(interactivePopGestureRecognizer)])
	{
		self.interactivePopGestureRecognizer.delegate = _standardInteractivePopGestureRecognizerDelegate;
		_standardInteractivePopGestureRecognizerDelegate = nil;
	}
	
	DASSERT(_daNavigationControllerFlags.navigationBarObserving);
	if (_daNavigationControllerFlags.navigationBarObserving)
	{
		_daNavigationControllerFlags.navigationBarObserving = NO;
		[self.navigationBar removeObserver:self forKeyPath:@"center" context:&DANavigationControllerContext];
		[self.navigationBar removeObserver:self forKeyPath:@"bounds" context:&DANavigationControllerContext];
	}
}


#pragma mark -
#pragma mark Navigation Stack


- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated
{
	if (_daNavigationControllerFlags.transitioning)
	{
		DANavigationController * __weak weakSelf = self;
		[_invocationQueue addObject:[^{ DANavigationController *strongSelf = weakSelf; if (strongSelf) [strongSelf pushViewController:viewController animated:animated]; } copy]];
	}
	else
	{
		id <UIViewControllerTransitionCoordinator> transitionCoordinator = [self respondsToSelector:@selector(transitionCoordinator)] ? [self transitionCoordinator] : nil;
		if (transitionCoordinator)
		{
			DANavigationController * __weak weakSelf = self;
			[transitionCoordinator animateAlongsideTransition:nil completion:^(id <UIViewControllerTransitionCoordinatorContext> context)
			 {
				 DANavigationController *strongSelf = weakSelf;
				 if (strongSelf)
					 [strongSelf pushViewController:viewController animated:animated];
			 }];
			return;
		}
		
		[super pushViewController:viewController animated:animated];
		
		NSArray *popedViewControllers = [[NSArray alloc] init];
		NSArray *pushedViewControllers = viewController ? [[NSArray alloc] initWithObjects:&viewController count:1] : [[NSArray alloc] init];
		[self updateNavigationStackWithPopedViewControllers:popedViewControllers andPushedViewControllers:pushedViewControllers];
	}
}


- (UIViewController *)popViewControllerAnimated:(BOOL)animated
{
	if (_daNavigationControllerFlags.transitioning)
	{
		DANavigationController * __weak weakSelf = self;
		[_invocationQueue addObject:[^{ DANavigationController *strongSelf = weakSelf; if (strongSelf) [strongSelf popViewControllerAnimated:animated]; } copy]];
		return nil;
	}
	else
	{
		UIViewController *viewController = nil;
		BOOL updateNavigationStack = YES;
		if (_daNavigationControllerFlags.popViewController)
		{
			_daNavigationControllerFlags.nestedPopViewController = YES;
			viewController = [super popViewControllerAnimated:animated];
		}
		else
		{
			_daNavigationControllerFlags.popViewController = YES;
			viewController = [super popViewControllerAnimated:animated];
			_daNavigationControllerFlags.popViewController = NO;
			if (_daNavigationControllerFlags.nestedPopViewController)
			{
				_daNavigationControllerFlags.nestedPopViewController = NO;
				updateNavigationStack = NO;
			}
		}
		
		if (updateNavigationStack)
		{
			if (viewController)
			{
				NSArray *popedViewControllers = [[NSArray alloc] initWithObjects:&viewController count:1];
				NSArray *pushedViewControllers = [[NSArray alloc] init];
				[self updateNavigationStackWithPopedViewControllers:popedViewControllers andPushedViewControllers:pushedViewControllers];
			}
			else if (_invocationQueue.count > 0)
			{
				void (^invocation)(void) = (void(^)(void))[_invocationQueue objectAtIndex:0];
				[_invocationQueue removeObjectAtIndex:0];
				invocation();
			}
		}

		return viewController;
	}
}


- (NSArray *)popToRootViewControllerAnimated:(BOOL)animated
{
	if (_daNavigationControllerFlags.transitioning)
	{
		DANavigationController * __weak weakSelf = self;
		[_invocationQueue addObject:[^{ DANavigationController *strongSelf = weakSelf; if (strongSelf) [strongSelf popToRootViewControllerAnimated:animated]; } copy]];
		return nil;
	}
	else
	{
		NSArray *viewControllers = [super popToRootViewControllerAnimated:animated];
		
		if (viewControllers && viewControllers.count > 0)
		{
			NSArray *popedViewControllers = [viewControllers copy];
			NSArray *pushedViewControllers = [[NSArray alloc] init];
			[self updateNavigationStackWithPopedViewControllers:popedViewControllers andPushedViewControllers:pushedViewControllers];
		}
		else if (_invocationQueue.count > 0)
		{
			void (^invocation)(void) = (void(^)(void))[_invocationQueue objectAtIndex:0];
			[_invocationQueue removeObjectAtIndex:0];
			invocation();
		}
		
		return viewControllers;
	}
}


- (NSArray *)popToViewController:(UIViewController *)viewController animated:(BOOL)animated
{
	if (_daNavigationControllerFlags.transitioning)
	{
		DANavigationController * __weak weakSelf = self;
		[_invocationQueue addObject:[^{ DANavigationController *strongSelf = weakSelf; if (strongSelf) [strongSelf popToViewController:viewController animated:animated]; } copy]];
		return nil;
	}
	else
	{
		NSUInteger index = [self.viewControllers indexOfObjectIdenticalTo:viewController];
		NSArray *viewControllers = index != NSNotFound ? [super popToViewController:viewController animated:animated] : nil;
		
		if (viewControllers && viewControllers.count > 0)
		{
			NSArray *popedViewControllers = [viewControllers copy];
			NSArray *pushedViewControllers = [[NSArray alloc] init];
			[self updateNavigationStackWithPopedViewControllers:popedViewControllers andPushedViewControllers:pushedViewControllers];
		}
		else if (_invocationQueue.count > 0)
		{
			void (^invocation)(void) = (void(^)(void))[_invocationQueue objectAtIndex:0];
			[_invocationQueue removeObjectAtIndex:0];
			invocation();
		}
		
		return viewControllers;
	}
}


- (void)setViewControllers:(NSArray *)viewControllers animated:(BOOL)animated
{
	if (_daNavigationControllerFlags.transitioning)
	{
		DANavigationController * __weak weakSelf = self;
		[_invocationQueue addObject:[^{ DANavigationController *strongSelf = weakSelf; if (strongSelf) [strongSelf setViewControllers:viewControllers animated:animated]; } copy]];
	}
	else
	{
		NSArray *oldViewControllers = [self.viewControllers copy];
		[super setViewControllers:viewControllers animated:animated];
		
		NSMutableArray *popedViewControllers = [[NSMutableArray alloc] init];
		NSMutableArray *pushedViewControllers = [self.viewControllers mutableCopy];
		for (UIViewController *vc in oldViewControllers)
		{
			NSUInteger index = [pushedViewControllers indexOfObjectIdenticalTo:vc];
			if (index == NSNotFound)
				[popedViewControllers addObject:vc];
			else
				[pushedViewControllers removeObjectAtIndex:index];
		}
		[self updateNavigationStackWithPopedViewControllers:popedViewControllers andPushedViewControllers:pushedViewControllers];
	}
}


#pragma mark -
#pragma mark UINavigationControllerDelegate


/*
 Последовательность событий при обычной модификации стека:
 Вызов push/pop. НАЧАЛО
	Внутри вызываются navigationController:animationControllerForOperation:fromViewController:toViewController: и navigationController:interactionControllerForAnimationController:.
	[[self transitionCoordinator] isAnimated]
 __LOOP__
 Вызов navigationController:willShowViewController:animated:.
 __LOOP__
 Вызов navigationController:didShowViewController:animated:. КОНЕЦ
 
 Interactive Transition:
 Вызов popViewControllerAnimated: НАЧАЛО
 __LOOP__
 Вызов navigationController:willShowViewController:animated:.
 __LOOP__
 Если completed, то как в обычном случае:
	Вызов navigationController:didShowViewController:animated:. КОНЕЦ
 Если cancelled, то ничего не вызывается, поэтому сам делаю по окончанию транзакции для исходного viewController:
	Вызов navigationController:didShowViewController:animated:. КОНЕЦ
 
 После оконания перехода:
 __LOOP__
 invocation(); (в navigationController:didShowViewController:animated:. Делаю асинхронно, так как если вызвать сразу, то [self transitionCoordinator] будет старым)
 */


- (void)updateNavigationStackWithPopedViewControllers:(NSArray*)popedViewControllers andPushedViewControllers:(NSArray*)pushedViewControllers
{
	DASSERT(!_daNavigationControllerFlags.transitioning && !_daNavigationControllerFlags.animationTransitioning);
	_daNavigationControllerFlags.transitioning = YES;
	id <UIViewControllerTransitionCoordinator> transitionCoordinator = [self respondsToSelector:@selector(transitionCoordinator)] ? [self transitionCoordinator] : nil;
	if (transitionCoordinator)
	{
		UIViewController *parentViewController = self.parentViewController;
		id <UIViewControllerTransitionCoordinator> parentTransitionCoordinator = parentViewController ? [parentViewController transitionCoordinator] : nil;
		if (parentTransitionCoordinator && parentTransitionCoordinator == transitionCoordinator)
			transitionCoordinator = nil;
	}
	if (transitionCoordinator && [transitionCoordinator isAnimated])
	{
		_daNavigationControllerFlags.animationTransitioning = YES;
		if ([transitionCoordinator initiallyInteractive])
		{
			[transitionCoordinator notifyWhenInteractionEndsUsingBlock:^(id <UIViewControllerTransitionCoordinatorContext> context)
			 {
				 if (![context isCancelled])
				 {
					 id <UINavigationControllerDelegate> strongDelegate = _navigationControllerDelegate;
					 if (strongDelegate && [strongDelegate respondsToSelector:@selector(navigationController:didUpdateNavigationStackWithPopedViewControllers:andPushedViewControllers:)])
						 [(id <DANavigationControllerDelegate>) strongDelegate navigationController:self didUpdateNavigationStackWithPopedViewControllers:popedViewControllers andPushedViewControllers:pushedViewControllers];
				 }
			 }];
		}
		else
		{
			id <UINavigationControllerDelegate> strongDelegate = _navigationControllerDelegate;
			if (strongDelegate && [strongDelegate respondsToSelector:@selector(navigationController:didUpdateNavigationStackWithPopedViewControllers:andPushedViewControllers:)])
				[(id <DANavigationControllerDelegate>) strongDelegate navigationController:self didUpdateNavigationStackWithPopedViewControllers:popedViewControllers andPushedViewControllers:pushedViewControllers];
		}
		[transitionCoordinator animateAlongsideTransition:nil completion:^(id <UIViewControllerTransitionCoordinatorContext> context)
		 {
			 if ([context initiallyInteractive] && [context isCancelled])
			 {
				 [self updateNavigationBarAppearance:context.isAnimated];
				 UIViewController *fromViewController = [context viewControllerForKey:UITransitionContextFromViewControllerKey];
				 [self navigationController:self didShowViewController:fromViewController animated:context.isAnimated];
			 }
			 _daNavigationControllerFlags.transitioning = _daNavigationControllerFlags.animationTransitioning = NO;
			 if (_invocationQueue.count > 0)
			 {
				 void (^invocation)(void) = (void(^)(void))[_invocationQueue objectAtIndex:0];
				 [_invocationQueue removeObjectAtIndex:0];
				 invocation();
			 }
		 }];
	}
	else
	{
		id <UINavigationControllerDelegate> strongDelegate = _navigationControllerDelegate;
		if (strongDelegate && [strongDelegate respondsToSelector:@selector(navigationController:didUpdateNavigationStackWithPopedViewControllers:andPushedViewControllers:)])
			[(id <DANavigationControllerDelegate>) strongDelegate navigationController:self didUpdateNavigationStackWithPopedViewControllers:popedViewControllers andPushedViewControllers:pushedViewControllers];
		
		_daNavigationControllerFlags.transitioning = NO;
		if ([_invocationQueue count] > 0)
		{
			void (^invocation)(void) = (void(^)(void))[_invocationQueue objectAtIndex:0];
			[_invocationQueue removeObjectAtIndex:0];
			invocation();
		}
	}
}


- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
	id <UINavigationControllerDelegate> strongDelegate = _navigationControllerDelegate;
	if (strongDelegate && [strongDelegate respondsToSelector:@selector(navigationController:willShowViewController:animated:)])
		[strongDelegate navigationController:navigationController willShowViewController:viewController animated:animated];
	
	[self updateNavigationBarAppearance:animated];
}


- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
	[[NSNotificationCenter defaultCenter] postNotificationName:DAViewControllerStatusBarAppearanceDidUpdateNotification object:viewController userInfo:nil];
	
	id <UINavigationControllerDelegate> strongDelegate = _navigationControllerDelegate;
	if (strongDelegate && [strongDelegate respondsToSelector:@selector(navigationController:didShowViewController:animated:)])
		[strongDelegate navigationController:navigationController didShowViewController:viewController animated:animated];
}


- (id <UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController
                                   animationControllerForOperation:(UINavigationControllerOperation)operation
                                                fromViewController:(UIViewController *)fromVC
                                                  toViewController:(UIViewController *)toVC
{
	id <UINavigationControllerDelegate> strongDelegate = _navigationControllerDelegate;
	return strongDelegate && [strongDelegate respondsToSelector:@selector(navigationController:animationControllerForOperation:fromViewController:toViewController:)]
	? [strongDelegate navigationController:navigationController animationControllerForOperation:operation fromViewController:fromVC toViewController:toVC]
	: nil;
}


- (id <UIViewControllerInteractiveTransitioning>)navigationController:(UINavigationController *)navigationController
                          interactionControllerForAnimationController:(id <UIViewControllerAnimatedTransitioning>) animationController
{
	id <UINavigationControllerDelegate> strongDelegate = _navigationControllerDelegate;
	return strongDelegate && [strongDelegate respondsToSelector:@selector(navigationController:interactionControllerForAnimationController:)]
	? [strongDelegate navigationController:navigationController interactionControllerForAnimationController:animationController]
	: nil;
}


@end
