//
// HP Inc.
// All rights reserved.
//
// This file, its contents, concepts, methods, behavior, and operation
// (collectively the "Software") are protected by trade secret, patent,
// and copyright laws. The use of the Software is governed by a license
// agreement. Disclosure of the Software to third parties, in any form,
// in whole or in part, is expressly prohibited except as authorized by
// the license agreement.
//

#import "MPBTPairedAccessoriesViewController.h"
#import "MPBTSessionController.h"
#import "MPBTSprocket.h"
#import "MP.h"
#import "NSBundle+MPLocalizable.h"
#import "MPBTDeviceInfoTableViewController.h"
#import "MPBTFirmwareProgressView.h"
#import <ExternalAccessory/ExternalAccessory.h>

static const NSString *kMPBTLastPrinterNameSetting = @"kMPBTLastPrinterNameSetting";

@interface MPBTPairedAccessoriesViewController () <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSArray *pairedDevices;
@property (weak, nonatomic) IBOutlet UIView *topView;
@property (weak, nonatomic) IBOutlet UIView *bottomView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet UIView *noDevicesView;
@property (weak, nonatomic) IBOutlet UILabel *noDevicesLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topViewHeightConstraint;
@property (strong, nonatomic) UIImage *image;
@property (weak, nonatomic) UIViewController *hostController;

@end

@implementation MPBTPairedAccessoriesViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    [self setTitle:@"Devices"];
    self.bottomView.backgroundColor = [[MP sharedInstance].appearance.settings objectForKey:kMPGeneralBackgroundColor];
    self.tableView.backgroundColor = [[MP sharedInstance].appearance.settings objectForKey:kMPGeneralBackgroundColor];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.separatorColor = [[MP sharedInstance].appearance.settings objectForKey:kMPGeneralTableSeparatorColor];
    
    self.topView.backgroundColor = [[MP sharedInstance].appearance.settings objectForKey:kMPSelectionOptionsBackgroundColor];
    self.containerView.backgroundColor = [[MP sharedInstance].appearance.settings objectForKey:kMPSelectionOptionsBackgroundColor];
    if ([UINavigationBar appearance].barTintColor) {
        self.topView.backgroundColor = [UINavigationBar appearance].barTintColor;
        self.containerView.backgroundColor = [UINavigationBar appearance].barTintColor;
    }

    if ([UINavigationBar appearance].titleTextAttributes) {
        self.titleLabel.font = [[UINavigationBar appearance].titleTextAttributes objectForKey:NSFontAttributeName];
        self.titleLabel.textColor = [[UINavigationBar appearance].titleTextAttributes objectForKey:NSForegroundColorAttributeName];
    } else {
        self.titleLabel.font = [[MP sharedInstance].appearance.settings objectForKey:kMPSelectionOptionsPrimaryFont];
        self.titleLabel.textColor = [[MP sharedInstance].appearance.settings objectForKey:kMPSelectionOptionsPrimaryFontColor];
    }

    self.noDevicesLabel.font = [[MP sharedInstance].appearance.settings objectForKey:kMPSelectionOptionsPrimaryFont];
    self.noDevicesLabel.textColor = [[MP sharedInstance].appearance.settings objectForKey:kMPSelectionOptionsPrimaryFontColor];
    self.descriptionLabel.font = [[MP sharedInstance].appearance.settings objectForKey:kMPSelectionOptionsSecondaryFont];
    self.descriptionLabel.textColor = [[MP sharedInstance].appearance.settings objectForKey:kMPSelectionOptionsSecondaryFontColor];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(becomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    self.image = nil;
    self.hostController = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
 
    if ([UINavigationController class] == [self.parentViewController class]) {
        self.topViewHeightConstraint.constant = 0;
        self.topView.hidden = YES;
    }
    
    [self didPressRefreshButton:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

+ (void)presentAnimatedForDeviceInfo:(BOOL)animated usingController:(UIViewController *)hostController andCompletion:(void(^)(void))completion
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MP" bundle:nil];
    UINavigationController *navigationController = (UINavigationController *)[storyboard instantiateViewControllerWithIdentifier:@"MPBTPairedAccessoriesNavigationController"];
    [hostController presentViewController:navigationController animated:animated completion:^{
        if (completion) {
            completion();
        }
    }];
}

+ (void)presentAnimatedForPrint:(BOOL)animated image:(UIImage *)image usingController:(UIViewController *)hostController andCompletion:(void(^)(void))completion
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MP" bundle:nil];
    UINavigationController *navigationController = (UINavigationController *)[storyboard instantiateViewControllerWithIdentifier:@"MPBTPairedAccessoriesNavigationController"];
    [hostController presentViewController:navigationController animated:animated completion:^{
        if (completion) {
            completion();
        }
        
        if ([MPBTPairedAccessoriesViewController class] == [[navigationController topViewController] class]) {
            MPBTPairedAccessoriesViewController *vc = (MPBTPairedAccessoriesViewController *)[navigationController topViewController];
            vc.image = image;
            vc.hostController = hostController;
            [vc.tableView reloadData];
        }
    }];
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell	*cell;
    static NSString *cellID = @"EAAccessoryList";
    
    cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
    }
    
    EAAccessory *accessory = (EAAccessory *)[self.pairedDevices objectAtIndex:indexPath.row];
    if ([self numberOfSectionsInTableView:tableView] > 1  &&  0 == indexPath.section) {
        accessory = [self lastPrinterUsed];
    }
    
    [[cell textLabel] setText:[MPBTSprocket displayNameForAccessory:accessory]];
    cell.backgroundColor = [[MP sharedInstance].appearance.settings objectForKey:kMPSelectionOptionsBackgroundColor];
    cell.textLabel.font = [[MP sharedInstance].appearance.settings objectForKey:kMPSelectionOptionsPrimaryFont];
    cell.textLabel.textColor = [[MP sharedInstance].appearance.settings objectForKey:kMPSelectionOptionsPrimaryFontColor];
    if (self.image) {
        cell.accessoryType = UITableViewCellAccessoryNone;
    } else {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    return cell;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger numSections = (self.image && [self lastPrinterUsedIsPaired]) ? 2 : 1;
    
    return numSections;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *title = @"";
    if ([self numberOfSectionsInTableView:tableView] > 1) {
        if (0 == section) {
            title = MPLocalizedString(@"Recent Printer", @"Table heading for the printer that has most recently been printed to");
        } else if (1 == section) {
            title = MPLocalizedString(@"All Printers", @"Table heading for list of available printers");
        }
    }
    
    return title;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger numRows = self.pairedDevices.count;
    self.noDevicesView.hidden = (0 == numRows) ? NO : YES;
    
    if ([self numberOfSectionsInTableView:tableView] > 1) {
        self.noDevicesView.hidden = YES;
        
        if (0 == section) {
            numRows = 1;
        }
    }
    
    return numRows;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    CGFloat height = tableView.sectionHeaderHeight;
    
    if ([self numberOfSectionsInTableView:tableView] > 1) {
        height = 35.0F;
    }
    
    return height;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    CGFloat height = tableView.sectionHeaderHeight;
    
    if ([self numberOfSectionsInTableView:tableView] > 1) {
        height = 10.0F;
    }
    
    return height;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    header.contentView.backgroundColor = [[MP sharedInstance].appearance.settings objectForKey:kMPGeneralBackgroundColor];
    header.textLabel.textColor = [[MP sharedInstance].appearance.settings objectForKey:kMPMainActionInactiveLinkFontColor];
    header.textLabel.font = [[MP sharedInstance].appearance.settings objectForKey:kMPSelectionOptionsPrimaryFont];
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section {
    UITableViewHeaderFooterView *footer = (UITableViewHeaderFooterView *)view;
    footer.contentView.backgroundColor = [[MP sharedInstance].appearance.settings objectForKey:kMPGeneralBackgroundColor];
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // ensure that the device is still connected
    BOOL stillConnected = NO;
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    NSString *displayName = cell.textLabel.text;
    NSArray *currentlyPairedDevices = [MPBTSprocket pairedSprockets];
    for (EAAccessory *acc in currentlyPairedDevices) {
        if ([displayName isEqualToString:[MPBTSprocket displayNameForAccessory:acc]]) {
            stillConnected = YES;
        }
    }
    
    if (stillConnected) {
        EAAccessory *device = (EAAccessory *)[self.pairedDevices objectAtIndex:indexPath.row];
        MPBTSprocket *sprocket = [MPBTSprocket sharedInstance];
        sprocket.accessory = device;
        
        if (self.image  &&  self.hostController) {
            [self dismissViewControllerAnimated:YES completion:^{
                MPBTFirmwareProgressView *progressView = [[MPBTFirmwareProgressView alloc] initWithFrame:self.hostController.view.frame];
                progressView.viewController = self.hostController;
                [progressView printToDevice:self.image];
            }];
        }
        else if (self.delegate  &&  [self.delegate respondsToSelector:@selector(didSelectSprocket:)]) {
            void (^completionBlock)(void) = ^{
                [self.delegate didSelectSprocket:sprocket];
                
                if (self.completionBlock) {
                    self.completionBlock(YES);
                }
            };
            
            if (nil == self.parentViewController) {
                [self dismissViewControllerAnimated:YES completion:completionBlock];
            } else {
                completionBlock();
            }
        } else {
            // show device info screen
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MP" bundle:[NSBundle bundleForClass:[MP class]]];
            MPBTDeviceInfoTableViewController *settingsViewController = (MPBTDeviceInfoTableViewController *)[storyboard instantiateViewControllerWithIdentifier:@"MPBTDeviceInfoTableViewController"];
            settingsViewController.device = sprocket.accessory;
            
            UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;
            
            while (topController.presentedViewController) {
                topController = topController.presentedViewController;
            }
            
            [((UINavigationController *)topController) pushViewController:settingsViewController animated:YES];
        }
    } else {
        [self refreshPairedDevices];
    }
}

#pragma mark - Button Listeners

- (IBAction)didPressRefreshButton:(id)sender {
    [self refreshPairedDevices];
    
    if (0 == self.pairedDevices.count) {
        [MPBTPairedAccessoriesViewController presentNoPrinterConnectedAlert:self];
    }
}

- (IBAction)didPressCancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Util

+ (void)setLastPrinterUsed:(NSString *)lastPrinterUsed
{
    [[NSUserDefaults standardUserDefaults] setObject:lastPrinterUsed forKey:kMPBTLastPrinterNameSetting];
}

+ (NSString *)lastPrinterUsed
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:kMPBTLastPrinterNameSetting];
}

+ (void)presentNoPrinterConnectedAlert:(UIViewController *)hostController
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:MPLocalizedString(@"Printer not connected to device", @"Title of dialog letting the user know that there is no sprocket paired with their phone")
                                                                   message:MPLocalizedString(@"Make sure the printer is turned on and check the Bluetooth connection.", @"Body of dialog letting the user know that there is no sprocket paired with their phone")
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* settingsAction = [UIAlertAction actionWithTitle:MPLocalizedString(@"Settings", @"Button that takes the user to the phone's Settings screen")
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * action) {
                                                               NSURL *url = [NSURL URLWithString:@"prefs:root=Bluetooth"];
                                                               [[UIApplication sharedApplication] openURL:url];
                                                           }];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:MPLocalizedString(@"OK", @"Dismisses dialog without taking action")
                                                       style:UIAlertActionStyleCancel
                                                     handler:nil];
    [alert addAction:okAction];
    [alert addAction:settingsAction];
    
    [hostController presentViewController:alert animated:YES completion:nil];
}

- (BOOL)lastPrinterUsedIsPaired
{
    return ([self lastPrinterUsed] != nil);
}

- (EAAccessory *)lastPrinterUsed
{
    EAAccessory *lastPrinterUsedAcc = nil;
    NSString *lastPrinterUsedName = [MPBTPairedAccessoriesViewController lastPrinterUsed];
    
    for (EAAccessory *acc in self.pairedDevices) {
        if ([[MPBTSprocket displayNameForAccessory:acc] isEqualToString:lastPrinterUsedName]) {
            lastPrinterUsedAcc = acc;
            break;
        }
    }
    
    return lastPrinterUsedAcc;
}

- (void)becomeActive:(NSNotification *)notification {
    [self refreshPairedDevices];
}

- (void)refreshPairedDevices
{
    self.pairedDevices = [MPBTSprocket pairedSprockets];
    [self.tableView reloadData];
}

@end
