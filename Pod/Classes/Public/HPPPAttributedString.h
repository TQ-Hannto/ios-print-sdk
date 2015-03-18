//
// Hewlett-Packard Company
// All rights reserved.
//
// This file, its contents, concepts, methods, behavior, and operation
// (collectively the "Software") are protected by trade secret, patent,
// and copyright laws. The use of the Software is governed by a license
// agreement. Disclosure of the Software to third parties, in any form,
// in whole or in part, is expressly prohibited except as authorized by
// the license agreement.
//

#import <Foundation/Foundation.h>

extern NSString *const HPPPAddPrintLaterJobScreenAddToPrintQFontAttribute;
extern NSString *const HPPPAddPrintLaterJobScreenAddToPrintQColorAttribute;
extern NSString *const HPPPAddPrintLaterJobScreenNotificationDescriptionFontAttribute;
extern NSString *const HPPPAddPrintLaterJobScreenNotificationDescriptionColorAttribute;
extern NSString *const HPPPAddPrintLaterJobScreenJobNameFontAttribute;
extern NSString *const HPPPAddPrintLaterJobScreenJobNameColorAttribute;
extern NSString *const HPPPAddPrintLaterJobScreenDateFontAttribute;
extern NSString *const HPPPAddPrintLaterJobScreenDateColorAttribute;
extern NSString *const HPPPAddPrintLaterJobScreenPrinterNameTitleFontAttribute;
extern NSString *const HPPPAddPrintLaterJobScreenPrinterNameTitleColorAttribute;
extern NSString *const HPPPAddPrintLaterJobScreenPrinterNameFontAttribute;
extern NSString *const HPPPAddPrintLaterJobScreenPrinterNameColorAttribute;

@interface HPPPAttributedString : NSObject

/*!
 * @abstract Fonts and colors use in the Add Print Later Job Screen
 * @description Used to set the fonts and colors of the Add Print Later Job Screen
 */
@property (strong, nonatomic) NSDictionary *addPrintLaterJobScreenAttributes;

@end
