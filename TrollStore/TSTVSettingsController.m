#import "TSTVSettingsController.h"
#import "TSUtil.h"

@implementation TSTVSettingsController
{
	NSArray<NSArray<NSDictionary*>*>* _sections;
}

- (NSString*)versionString
{
	return [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleVersion"] ?: @"unknown";
}

- (void)viewDidLoad
{
	[super viewDidLoad];

	NSString* helper = rootHelperPath() ?: @"(missing)";

	_sections = @[
		@[
			@{ @"title" : [NSString stringWithFormat:@"TrollStore TV %@", [self versionString]], @"action" : @"none", @"detail" : @"non-Lite build" },
			@{ @"title" : @"Root Helper", @"action" : @"none", @"detail" : helper },
		],
		@[
			@{ @"title" : @"Rebuild Icon Cache", @"action" : @"refresh-all" },
			@{ @"title" : @"Refresh App Registrations", @"action" : @"refresh" },
			@{ @"title" : @"Respring", @"action" : @"respring" },
		],
		@[
			@{ @"title" : @"Signing", @"action" : @"none", @"detail" : @"Built-in ChOma ad-hoc" },
		],
		@[
			@{ @"title" : @"Uninstall TrollStore", @"action" : @"uninstall-trollstore", @"destructive" : @YES },
		],
	];

	self.title = @"Settings";
	[self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
	return _sections.count;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
	return _sections[section].count;
}

- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
	switch(section)
	{
		case 0: return @"About";
		case 1: return @"Utilities";
		case 2: return @"Signing";
		case 3: return @"Danger Zone";
		default: return nil;
	}
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
	UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
	NSDictionary* item = _sections[indexPath.section][indexPath.row];

	UIListContentConfiguration* content = [UIListContentConfiguration cellConfiguration];
	content.text = item[@"title"];
	content.secondaryText = item[@"detail"];
	cell.contentConfiguration = content;
	cell.accessoryType = [item[@"action"] isEqualToString:@"none"] ? UITableViewCellAccessoryNone : UITableViewCellAccessoryDisclosureIndicator;

	return cell;
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];

	NSDictionary* item = _sections[indexPath.section][indexPath.row];
	NSString* action = item[@"action"];
	if([action isEqualToString:@"none"]) return;

	NSString* title = item[@"title"];
	if([action isEqualToString:@"respring"])
	{
		respring();
		return;
	}

	UIAlertController* alert = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleAlert];
	[alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
	[alert addAction:[UIAlertAction actionWithTitle:@"Run" style:[item[@"destructive"] boolValue] ? UIAlertActionStyleDestructive : UIAlertActionStyleDefault handler:^(UIAlertAction* a)
	{
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
		{
			int ret = spawnRoot(rootHelperPath(), @[action], nil, nil);

			if([action isEqualToString:@"refresh"])
			{
				respring();
				return;
			}

			dispatch_async(dispatch_get_main_queue(), ^
			{
				UIAlertController* resultAlert = [UIAlertController alertControllerWithTitle:title message:[NSString stringWithFormat:@"Finished (exit code %d)", ret] preferredStyle:UIAlertControllerStyleAlert];
				[resultAlert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
				[self presentViewController:resultAlert animated:YES completion:nil];
			});
		});
	}]];
	[self presentViewController:alert animated:YES completion:nil];
}

@end
