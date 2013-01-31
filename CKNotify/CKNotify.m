//
//  CKNotify.m
//  cknotify
//
//  Created by Matthew Schettler (mschettler@gmail.com, mschettler.com) on 3/19/12.
//  Fork this project at https://github.com/mschettler/CKNotify
//  Copyright (c) 2012. All rights reserved.
//
//  Version: 1.1
//



#import "CKNotify.h"

static CKNotify *sharedInstance = nil;

@implementation CKNotify 

- (id)init {
    
    if (self = [super init]) {
        currentAlerts = [[NSMutableDictionary alloc] initWithCapacity:20];
        currentAlertsOrdered = [[NSMutableArray alloc] initWithCapacity:20];
    }
    
    return self;
}


- (CKAlertView *)presentAlert:(CKNotifyAlertType)type 
                    withTitle:(NSString *)title
                      andBody:(NSString *)body 
                       inView:(UIView *)view 
                  forDuration:(float)duration {
    
    return [self presentAlert:type withTitle:title andBody:body inView:view forDuration:duration fromLocation:CKNotifyAlertLocationTop];
    
}


- (CKAlertView *)presentAlert:(CKNotifyAlertType)type 
                    withTitle:(NSString *)title
                      andBody:(NSString *)body 
                       inView:(UIView *)view 
                  forDuration:(float)duration
                 fromLocation:(CKNotifyAlertLocation)location {
    
    CKAlertView *cav = [CKAlertView new];
    cav.myLocation = location;
    cav.inView = view;
    
    [self showAlert:cav usingView:view forDuration:duration];
    [cav setTitle:title withBody:body andType:type];
    
    return [cav autorelease];
    
}


- (void)dismissAllAlerts {

    // we copy the pointer list to avoid potential synchronization issues
    NSArray *alertListCopy = [currentAlertsOrdered copy];

    for (CKAlertView *alert in alertListCopy) { 
        [self dismissAlert:alert];
    }
    
    [alertListCopy release];

}


// dismiss all alerts for a given view
- (void)dismissAllAlertsInView:(UIView *)view {

    if (!view) return;

    // we copy the pointer list to avoid potential synchronization issues
    NSArray *alertListCopy = [currentAlertsOrdered copy];

    for (CKAlertView *alert in alertListCopy) {
        if ([view.subviews containsObject:alert.view]) {
            [self dismissAlert:alert];
        }
    }
    
    [alertListCopy release];

}


// returns the first available alert location y coordinate
- (int)returnFirstAvailableYForAlert:(CKAlertView *)alert {

    assert(alert);
    
    const CGFloat alertHeight = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? 71 : 60;
    const CGFloat viewHeight = alert.inView.frame.size.height;
    const CGFloat startHeight = viewHeight == [[[UIApplication sharedApplication] keyWindow] frame].size.height ? [[UIApplication sharedApplication] statusBarFrame].size.height : 0.f;
    for (int i = 0;; i++) {
        
        const int y = (alert.myLocation == CKNotifyAlertLocationBottom) ? viewHeight - (alertHeight * (i + 1)) : alertHeight * i + startHeight;
        
        // return early if there are no other alerts
        if (i == 0 && currentAlertsOrdered.count == 0) return y;

        BOOL overlapping = NO;

        // check if this y coordinate overrides any already placed panels
        for (NSString *key in [currentAlerts allKeys]) {
            CKAlertView *a = [currentAlerts objectForKey:key];
            
            // if this alert is not from the same location (top/bottom), then ignore
            // also discard if they are in different views
            if (a.myLocation != alert.myLocation) continue;
            if (a.inView != alert.inView) continue;

            if (CGRectContainsPoint(a.view.frame, CGPointMake(0, y))) {
                overlapping = YES;
                break;
            }
        }
        
        // if this position does not overlap, we have found a good one
        if (!overlapping) return y;
    }
    
    // edge case; should never happen
    assert(0);
    return 0;
}


// Animate the alert to become visible
- (void)showAlert:(CKAlertView *)alert usingView:(UIView *)view forDuration:(float)duration {
    
    assert(view && alert);
    
    CGFloat viewWidth = view.frame.size.width;
    CGFloat viewHeight = view.frame.size.height;
    CGFloat alertHeight = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? 71 : 60;
    
    CGAffineTransform trans = view.transform;
    if (trans.b == -1 || trans.c == -1){
        viewWidth = viewHeight;
    }
    
    assert(![currentAlerts objectForKey:alert.uniqueID]);

    
    
    const int y = (alert.myLocation == CKNotifyAlertLocationBottom) ? viewHeight : -alertHeight;

    // start here
    alert.view.frame = CGRectMake(0, y, viewWidth, alertHeight);

    [view addSubview:alert.view];
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.3];
    [UIView setAnimationBeginsFromCurrentState:YES];
    alert.view.frame = CGRectMake(0, [self returnFirstAvailableYForAlert:alert], viewWidth, alertHeight);
//    NSLog(@"alert.view.frame = %@", NSStringFromCGRect(alert.view.frame));
    [UIView commitAnimations];

    [currentAlerts setObject:alert forKey:alert.uniqueID];
    [currentAlertsOrdered addObject:alert];

    if (duration > 0) {
        // negative or zero durations will never auto-dismiss
        [alert performSelector:@selector(autoDismissMe) withObject:nil afterDelay:duration];        
    }

}


// Animate away the alert (if visible)
- (void)dismissAlert:(CKAlertView *)alert {

    assert(alert);
    
    @synchronized(self) {

        if ([currentAlerts objectForKey:alert.uniqueID]) {
            
            // disable input to this view -- we are about to animate it away
            alert.view.userInteractionEnabled = NO;
            
            const CGFloat viewWidth = alert.inView.frame.size.width;
            const CGFloat viewHeight = alert.inView.frame.size.height;
            const CGFloat alertHeight = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? 71 : 60;
            
            [UIView beginAnimations:alert.uniqueID context:nil];
            [UIView setAnimationDelegate:self];
            [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
            [UIView setAnimationDuration:0.3];
            [UIView setAnimationBeginsFromCurrentState:YES];
            
            const int y = (alert.myLocation == CKNotifyAlertLocationBottom) ? viewHeight : -alertHeight;

            alert.view.frame = CGRectMake(0, y, viewWidth, alertHeight);

            alert.view.alpha = 0.0;

            // cascade effect
            for (int idx = [currentAlertsOrdered indexOfObject:alert] + 1; idx < [currentAlertsOrdered count]; idx++) {
                
                CKAlertView *currAlert = [currentAlertsOrdered objectAtIndex:idx];
                
                // if this alert is not from the same location (top/bottom), then ignore
                // also ignore if they are targeting different views
                if (currAlert.myLocation != alert.myLocation) continue;
                if (currAlert.inView != alert.inView) continue;
                                
                const int y = (currAlert.myLocation == CKNotifyAlertLocationBottom) ? currAlert.view.frame.origin.y + alertHeight : currAlert.view.frame.origin.y - alertHeight;
                
                currAlert.view.frame = CGRectMake(0, y, currAlert.view.frame.size.width, currAlert.view.frame.size.height);
                
            }
            
            [UIView commitAnimations];

        } 
        
    }

}


- (void)animationDidStop:(NSString *)animationID finished:(BOOL)finished context:(void *)sender {

    if (!finished || !animationID) return;
    
    CKAlertView *alert = [currentAlerts objectForKey:animationID];
    if (alert) {
        [alert.view removeFromSuperview];
        [currentAlerts removeObjectForKey:alert.uniqueID];
        [currentAlertsOrdered removeObject:alert];        
    }
    
}


// -------------------------------------------------------------------------------------------------------------------------
// Singleton Code
// -------------------------------------------------------------------------------------------------------------------------
+ (CKNotify *)sharedInstance {
    @synchronized(self) {if (!sharedInstance) sharedInstance = [CKNotify new];}
    return sharedInstance;
}


+ (id)allocWithZone:(NSZone *)zone {
    @synchronized(self) {
        if (!sharedInstance) {
            sharedInstance = [super allocWithZone:zone];
            return sharedInstance; // assignment and return on first allocation
        }
    }
    return nil; // on subsequent allocation attempts return nil
}

- (id)copyWithZone:(NSZone *)zone { return self; }
- (id)retain { return self; }
- (unsigned)retainCount { return UINT_MAX; }
- (oneway void)release {}
- (id)autorelease { return self; }


@end
