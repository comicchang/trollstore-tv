#import "TSRootViewController.h"
#import "TSAppTableViewController.h"
#if TARGET_OS_TV
#import "TSTVSettingsController.h"
#else
#import "TSSettingsListController.h"
#endif
#import <TSPresentationDelegate.h>

@implementation TSRootViewController

- (void)loadView {
	[super loadView];

	TSAppTableViewController* appTableVC = [[TSAppTableViewController alloc] init];
	appTableVC.title = @"Apps";

#if TARGET_OS_TV
	TSTVSettingsController* settingsListVC = [[TSTVSettingsController alloc] init];
#else
	TSSettingsListController* settingsListVC = [[TSSettingsListController alloc] init];
#endif
	settingsListVC.title = @"Settings";

	UINavigationController* appNavigationController = [[UINavigationController alloc] initWithRootViewController:appTableVC];
	UINavigationController* settingsNavigationController = [[UINavigationController alloc] initWithRootViewController:settingsListVC];
	
	appNavigationController.tabBarItem.image = [UIImage systemImageNamed:@"square.stack.3d.up.fill"];
	settingsNavigationController.tabBarItem.image = [UIImage systemImageNamed:@"gear"];

	self.title = @"Root View Controller";
	self.viewControllers = @[appNavigationController, settingsNavigationController];
}

- (void)viewDidLoad
{
	[super viewDidLoad];

	TSPresentationDelegate.presentationViewController = self;
}

@end
