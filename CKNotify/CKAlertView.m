//
//  CKAlertView.m
//  cknotify
//
//  Created by Matthew Schettler (mschettler@gmail.com, mschettler.com) on 3/19/12.
//  Fork this project at https://github.com/mschettler/CKNotify
//  Copyright (c) 2012. All rights reserved.
//
//  Version: 1.1
//


#import "CKAlertView.h"
#import "CKNotify.h"

static CGFloat panelHeight;
static UIImage* successImage;
static UIImage* errorImage;
static UIImage* infoImage;
static UIImage* successAccessoryIcon;
static UIImage* infoAccessoryIcon;
static UIImage* errorAccessoryIcon;

static UIFont *alertTitleFont;
static UIColor *alertTextColor;

@implementation CKAlertView
@synthesize uniqueID, selectorTarget, onTapSelector, selectorObject, myLocation, inView;

+ (void)initialize
{
    panelHeight = 60.f;
    successImage = [[[UIImage imageNamed:@"CKGreenPanel"] stretchableImageWithLeftCapWidth:1 topCapHeight:5] retain];
    infoImage = [[[UIImage imageNamed:@"CKBluePanel"] stretchableImageWithLeftCapWidth:1 topCapHeight:5] retain];
    errorImage = [[[UIImage imageNamed:@"CKRedPanel.png"] stretchableImageWithLeftCapWidth:1 topCapHeight:5] retain];
    successAccessoryIcon = [[UIImage imageNamed:@"CKTickIcon"] retain];
    infoAccessoryIcon = [[UIImage imageNamed:@"CKInfoIcon"] retain];
    errorAccessoryIcon = [[UIImage imageNamed:@"CKWarningIcon"] retain];
    alertTitleFont = [[UIFont systemFontOfSize:15.f] retain];
    alertTextColor = [RGBA(250, 250, 250, 1.0) retain];

}

+ (void)setAccessoryIcon:(UIImage *)icon forNotifyAlertType:(CKNotifyAlertType)alertType
{
    if (alertType == CKNotifyAlertTypeError){
        [errorAccessoryIcon release];
        errorAccessoryIcon = [icon retain];
    } else if (alertType == CKNotifyAlertTypeInfo){
        [infoAccessoryIcon release];
        infoAccessoryIcon = [icon retain];
    } else if (alertType == CKNotifyAlertTypeSuccess){
        [successAccessoryIcon release];
        successAccessoryIcon = [icon retain];
    }
}

+ (void)setImage:(UIImage *)image forNotifyAlertType:(CKNotifyAlertType)alertType
{
    if (alertType == CKNotifyAlertTypeError){
        [errorImage release];
        errorImage = [image retain];
    } else if (alertType == CKNotifyAlertTypeInfo){
        [infoImage release];
        infoImage = [image retain];
    } else if (alertType == CKNotifyAlertTypeSuccess){
        [successImage release];
        successImage = [image retain];
    }
}

+ (void)setAlertFont:(UIFont*)font
{
    [alertTitleFont release];
    alertTitleFont = [font retain];
}

+ (void)setAlertTextColor:(UIColor*)color
{
    [alertTextColor release];
    alertTextColor = [color retain];
}

+ (void)setPanelHeight:(CGFloat)newPanelHeight
{
    panelHeight = newPanelHeight;
}

- (id)init {
    
    if (!(self = [super init])) return nil;

    self.uniqueID = [NSString stringWithFormat:@"%p", self];
//    NSLog(@"new alert with uniqueID = %@", self.uniqueID);

    isDismissing = NO;
    
    extraDuration = 0.0;
    
    // set default action on tap to dismiss the alert
    tapSelector = @selector(autoDismissMe);
    tapTarget = self;
    
    leftSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(didSwipeLeft:)];
    leftSwipe.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.view addGestureRecognizer:leftSwipe];
    
    rightSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(didSwipeRight:)];
    rightSwipe.direction = UISwipeGestureRecognizerDirectionRight;
    [self.view addGestureRecognizer:rightSwipe];
        
    tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapMe:)];
    [self.view addGestureRecognizer:tap];
    
    return self;
}

- (void)setTitle:(NSString *)title withBody:(NSString *)body andType:(CKNotifyAlertType)type {
    
    assert(lblTitle && lblBody);
    
    // if they gave a body and no title, switch 'em
    if (body && !title) {
        title = body;
        body = nil;
    }

    lblBody.text = body;
    lblTitle.text = title;
    
    switch (type) {
        case CKNotifyAlertTypeSuccess:
            // to-do finish success type
            imgViewBackround.image = successImage;
            imgViewIcon.image = successAccessoryIcon;
            lblTitle.font = alertTitleFont;
            lblBody.textColor = alertTextColor;
            lblBody.font = [UIFont fontWithName:@"Helvetica Neue" size:14];
            break;
        case CKNotifyAlertTypeInfo:
            imgViewBackround.image = infoImage;
            imgViewIcon.image = infoAccessoryIcon;
            lblTitle.font = alertTitleFont;
            lblBody.textColor = alertTextColor;
            break;
        case CKNotifyAlertTypeError:
            imgViewBackround.image = errorImage;
            imgViewIcon.image = errorAccessoryIcon;
            imgViewIcon.alpha = 0.9;
            lblBody.textColor = alertTextColor;
            lblTitle.font = alertTitleFont;
            lblBody.font = [UIFont fontWithName:@"Helvetica Neue" size:14];
            break;
        default:
            assert(0); // impossible case
    }
    
    assert(imgViewBackround.image);
    assert(imgViewIcon.image);
        
    if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
        // iPhone/iPod
        self.view.frame = CGRectMake(0, self.view.frame.origin.y, 320, panelHeight);
        if (body.length == 0){
            CGSize size = [lblTitle sizeThatFits:lblTitle.frame.size];
            lblTitle.frame = CGRectMake(57.f, size.height/2 - lblTitle.frame.size.height/2, size.width, size.height);
        } else {
            lblBody.frame = CGRectMake(57, 19, 253, 38);
            lblTitle.frame = CGRectMake(57, 1, 253, 21);
        }
        // fixme if body only has one line, adjust title label down slightly
    }

    if (!lblBody.text.length) {
        // no body text
        lblBody.hidden = YES;
        if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
            // iPhone/iPod
            lblTitle.center = CGPointMake(lblTitle.center.x, (self.view.frame.size.height / 2) - 2);
        } else {
            // iPad
            lblTitle.center = CGPointMake(lblTitle.center.x, (self.view.frame.size.height / 2) - 4);
        }
    }

}


- (void)autoDismissMe {
    
    // if extraDuration is non-zero, this alert still has some life in it
    if (extraDuration > 0.9) {
//        NSLog(@"obeying extraDuration of %.1f", extraDuration);
        [self performSelector:@selector(autoDismissMe) withObject:nil afterDelay:extraDuration];
        extraDuration = 0.0;
        return;
    }
    
//    NSLog(@"dismissing...");
    
    self.view.userInteractionEnabled = NO; // prevent any actions on this alert once its been told to dismiss
    isDismissing = YES;
    [self.view removeGestureRecognizer:leftSwipe];
    [self.view removeGestureRecognizer:rightSwipe];
    [self.view removeGestureRecognizer:tap];
    [[CKNotify sharedInstance] dismissAlert:self];
}


#pragma mark SwipeSelectors

- (void)didSwipeLeft:(id)sender {
    
    if (swipeLeftTarget && [swipeLeftTarget respondsToSelector:swipeLeftSelector] && !isDismissing) {
        if (swipeLeftObject) {
            [swipeLeftTarget performSelector:swipeLeftSelector withObject:swipeLeftObject];
        } else {
            [swipeLeftTarget performSelector:swipeLeftSelector];
        }
        if (swipeLeftSelector != @selector(autoDismissMe)) extraDuration = 1.1;
    }
    
}


- (void)didSwipeRight:(id)sender {
    
    if (swipeRightTarget && [swipeRightTarget respondsToSelector:swipeRightSelector] && !isDismissing) {
        if (swipeRightObject) {
            [swipeRightTarget performSelector:swipeRightSelector withObject:swipeRightObject];
        } else {
            [swipeRightTarget performSelector:swipeRightSelector];
        }
        if (swipeRightSelector != @selector(autoDismissMe)) extraDuration = 1.1;
    }
    
}


- (void)didTapMe:(id)sender {
    
    if (tapTarget && [tapTarget respondsToSelector:tapSelector] && !isDismissing) {
        if (tapObject) {
            [tapTarget performSelector:tapSelector withObject:tapObject];
        } else {
            [tapTarget performSelector:tapSelector];
        }
        if (tapSelector != @selector(autoDismissMe)) extraDuration = 1.1;
    }
    
}


- (void)setSwipeRightAction:(SEL)selector onTarget:(id)target withObject:(id)obj {
    
    if (selector) assert(target);
    if (target) assert(selector);
    
    swipeRightSelector = selector;
    swipeRightTarget = target;
    swipeRightObject = obj;
    
}


- (void)setSwipeLeftAction:(SEL)selector onTarget:(id)target withObject:(id)obj {
    
    if (selector) assert(target);
    if (target) assert(selector);
    
    swipeLeftSelector = selector;
    swipeLeftTarget = target;
    swipeLeftObject = obj;
    
}


- (void)setTapAction:(SEL)selector onTarget:(id)target withObject:(id)obj {
    
    if (selector) assert(target);
    if (target) assert(selector);
    
    tapSelector = selector;
    tapTarget = target;
    tapObject = obj;
    
}

#pragma mark Memory

- (void)dealloc {
//    NSLog(@"CKAlertView dealloc()");
    [imgViewBackround release];
    [imgViewIcon release];
    [lblTitle release];
    [lblBody release];
    [leftSwipe release];
    [rightSwipe release];
    [tap release];
    [uniqueID release];
    [inView release];
    [super dealloc];
}


- (void)viewDidUnload {
    [imgViewBackround release];
    imgViewBackround = nil;
    [imgViewIcon release];
    imgViewIcon = nil;
    [lblTitle release];
    lblTitle = nil;
    [lblBody release];
    lblBody = nil;
    [super viewDidUnload];
}

@end

