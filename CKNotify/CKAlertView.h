//
//  CKAlertView.h
//  cknotify
//
//  Created by Matthew Schettler (mschettler@gmail.com, mschettler.com) on 3/19/12.
//  Fork this project at https://github.com/mschettler/CKNotify
//  Copyright (c) 2012. All rights reserved.
//
//  Version: 1.1
//


#import <UIKit/UIKit.h>

#define RGBA(r, g, b, a) [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:a]

typedef enum {    
    CKNotifyAlertTypeSuccess,
    CKNotifyAlertTypeInfo,
    CKNotifyAlertTypeError
} CKNotifyAlertType;

typedef enum {    
    CKNotifyAlertLocationTop,
    CKNotifyAlertLocationBottom
} CKNotifyAlertLocation;


@interface CKAlertView : UIViewController {
 
    // a unique key assigned to this alert, based off the memory address of self
    NSString *uniqueID;

    // will be YES when this view has been told to dismiss
    BOOL isDismissing;
        
    IBOutlet UIImageView *imgViewBackround;
    IBOutlet UIImageView *imgViewIcon;
    IBOutlet UILabel *lblTitle;
    IBOutlet UILabel *lblBody;
    
    // involved in the swipe selectors/recognizers
    
    SEL swipeLeftSelector;
    id swipeLeftTarget;
    id swipeLeftObject;

    SEL swipeRightSelector;
    id swipeRightTarget;
    id swipeRightObject;

    SEL tapSelector;
    id tapTarget;
    id tapObject;
    
    UIView *inView;
    
    UISwipeGestureRecognizer *leftSwipe;
    UISwipeGestureRecognizer *rightSwipe;
    UITapGestureRecognizer *tap;
    
    CKNotifyAlertLocation myLocation;
    
    float extraDuration;

}

+ (void)setPanelHeight:(CGFloat)panelHeight;
+ (void)setImage:(UIImage*)image forNotifyAlertType:(CKNotifyAlertType)alertType;
+ (void)setAccessoryIcon:(UIImage*)icon forNotifyAlertType:(CKNotifyAlertType)alertType;
+ (void)setAlertFont:(UIFont*)font;
+ (void)setAlertTextColor:(UIColor*)color;

- (void)setSwipeRightAction:(SEL)selector onTarget:(id)target withObject:(id)obj;
- (void)setSwipeLeftAction:(SEL)selector onTarget:(id)target withObject:(id)obj;
- (void)setTapAction:(SEL)selector onTarget:(id)target withObject:(id)obj;


- (void)setTitle:(NSString *)title withBody:(NSString *)body andType:(CKNotifyAlertType)type;
- (void)autoDismissMe;

@property (nonatomic, retain) NSString *uniqueID;
@property (nonatomic, retain) UIView *inView;
@property (nonatomic, readwrite) SEL onTapSelector;
@property (nonatomic, assign) id selectorTarget;
@property (nonatomic, assign) id selectorObject;
@property (nonatomic, assign) CKNotifyAlertLocation myLocation;

@end
