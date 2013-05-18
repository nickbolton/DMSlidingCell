//
//  DMSlidingTableViewCell.h
//  DMSlidingCell - UITableViewCell subclass that supports slide to reveal features
//                  as like in Twitter and many other programs
//
//  Created by Daniele Margutti on 6/29/12.
//  Software Engineering and UX Designer
//
//  Copyright (c) 2012 Daniele Margutti. All rights reserved.
//  Web:    http://www.danielemargutti.com
//  Email:  daniele.margutti@gmail.com
//  Skype:  daniele.margutti
//
//  HOW TO USE IT:
//  ==============
//  1. Just use this cell as base class for your sliding UITableViewCell
//  2. Put frontmost visible content on cell's contentView and hidden content inside the backgroundView
//  3. Set allowed swipe-to-reveal directions and you're done! The magic is here with a great animation


#import "DMSlidingTableViewCell.h"

@interface DMSlidingTableViewCell() {
    NSMutableArray*                     associatedSwipeRecognizer;
    DMSlidingTableViewCellSwipe         lastSwipeDirectionOccurred;
    DMSlidingTableViewCellEventHandler  eventHandler;
    BOOL                                isAnimating;
    BOOL                                _isPanning;
}

@property (nonatomic, strong) UIPanGestureRecognizer *panGesture;
@property (nonatomic, strong) UITapGestureRecognizer *tapGesture;

- (UIGestureRecognizer *) swipeGestureRecognizerWithDirection:(UISwipeGestureRecognizerDirection) dir;
- (void) setOffsetForView:(UIView *) targetView offset:(CGPoint) offset;

@end

@implementation DMSlidingTableViewCell

@synthesize swipeDirection,lastSwipeDirectionOccurred;
@synthesize eventHandler;
@synthesize backgroundIsRevealed;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        swipeDirection = DMSlidingTableViewCellSwipeNone;
        lastSwipeDirectionOccurred = DMSlidingTableViewCellSwipeNone;
        
        UIView *defaultBackgroundView = [[UIView alloc] initWithFrame:self.contentView.frame];
        defaultBackgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        defaultBackgroundView.backgroundColor = [UIColor darkGrayColor];
        self.backgroundView = defaultBackgroundView;
        
        self.swipeDirection = DMSlidingTableViewCellSwipeRight;
        self.cellBounce = 20.0f;
        self.slidingInAnimationDuration = 0.2f;
        self.slidingOutAnimationDuration = 0.1f;

    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self resetCell];
}

- (void)resetCell {
    CGRect frame = self.contentView.frame;
    frame.origin.x = 0.0f;
    self.contentView.frame = frame;
}

- (void) setSwipeDirection:(DMSlidingTableViewCellSwipe)newSwipeDirection {
    if (newSwipeDirection == swipeDirection) return;
    NSArray* loadedGestures = [self gestureRecognizers];
    [loadedGestures enumerateObjectsUsingBlock:^(UIGestureRecognizer* obj, NSUInteger idx, BOOL *stop) {
        [self removeGestureRecognizer:obj];
    }];
    
    swipeDirection = newSwipeDirection;
    if (swipeDirection != DMSlidingTableViewCellSwipeNone) {
        [self addGestureRecognizer:[self swipeGestureRecognizerWithDirection:
                                    UISwipeGestureRecognizerDirectionLeft]];
        
        [self addGestureRecognizer:[self swipeGestureRecognizerWithDirection:
                                    UISwipeGestureRecognizerDirectionRight]];

        self.panGesture =
        [[UIPanGestureRecognizer alloc]
         initWithTarget:self
         action:@selector(handlePan:)];
        _panGesture.delegate = self;

        [self addGestureRecognizer:_panGesture];
    }
}

- (UIGestureRecognizer *) swipeGestureRecognizerWithDirection:(UISwipeGestureRecognizerDirection) dir {
    UISwipeGestureRecognizer *swipeG = [[UISwipeGestureRecognizer alloc] initWithTarget:self
                                                                                 action:@selector(handleSwipeGesture:)];
    swipeG.delegate = self;
    swipeG.direction = dir;
    return swipeG;
}


- (void)handleSwipeGesture:(UISwipeGestureRecognizer *) gesture {

    if (isAnimating || _isPanning || [_delegate slidingCellShouldAcceptSwipe:self] == NO)
        return;

    NSLog(@"%s", __PRETTY_FUNCTION__);
    UISwipeGestureRecognizerDirection directionMade = gesture.direction;
    UISwipeGestureRecognizerDirection activeSwipe = self.swipeDirection;

    // If we allow both swipe direction allowed swipe used to slide out and bring back the contentView
    // is the last swipe taken: so if you swipe to the right to bring back the contentView you should
    // swipe to left, and viceversa.
    if (activeSwipe == DMSlidingTableViewCellSwipeBoth)
        activeSwipe = lastSwipeDirectionOccurred;
    if (lastSwipeDirectionOccurred == DMSlidingTableViewCellSwipeNone)
        lastSwipeDirectionOccurred = directionMade;
    
    // We can reveal background view only if background is not yet visible and:
    //  - swipe made = allowedSwipe
    //  - allowed swipe is DMSlidingTableViewCellSwipeBoth
    BOOL canRevealBack = ((directionMade == activeSwipe ||
                           self.swipeDirection == DMSlidingTableViewCellSwipeBoth)
                          && self.backgroundIsRevealed == NO);
    // You can hide backgroundView only if it's visible yet and
    // user's swipe is not the allowed (to reveal) swipe set.
    BOOL canHide = (self.backgroundIsRevealed && directionMade != activeSwipe);
    
    if (canRevealBack){
        [self setBackgroundVisible:YES animated:YES completion:nil];
        // save user's last swipe direction
        lastSwipeDirectionOccurred = directionMade;
    } else if (canHide) {
        [self setBackgroundVisible:NO animated:YES completion:nil];
        if (self.swipeDirection == DMSlidingTableViewCellSwipeBoth)
            lastSwipeDirectionOccurred = DMSlidingTableViewCellSwipeNone;
    }
}

- (BOOL) toggleCellStatus {
    if (lastSwipeDirectionOccurred == DMSlidingTableViewCellSwipeNone)
        return NO;

    [self
     setBackgroundVisible:(self.backgroundIsRevealed ? NO : YES)
     animated:YES
     completion:nil];
    
    return YES;
}

- (BOOL) backgroundIsRevealed {
    // Return YES if cell's contentView is not visible (backgroundView is revealed)
    return (self.contentView.frame.origin.x < 0 ||
            self.contentView.frame.origin.x >= (CGRectGetWidth(self.contentView.frame) - _shelfSize));
}

- (void)setBackgroundVisible:(BOOL)revealBackgroundView
                    animated:(BOOL)animated
                  completion:(void(^)(void))userCompletionBlock {

    if (animated && isAnimating) return;
    CGFloat offset_x = 0.0f;
    CGFloat bounce_distance = self.cellBounce;
    CGFloat contentViewWidth = self.contentView.frame.size.width;

    UISwipeGestureRecognizerDirection swipeMade = lastSwipeDirectionOccurred;
    if (swipeMade == UISwipeGestureRecognizerDirectionLeft) {
        offset_x = (revealBackgroundView ? -contentViewWidth : contentViewWidth);
        bounce_distance = (revealBackgroundView ? 0.0f : self.cellBounce);
    } else if (swipeMade == UISwipeGestureRecognizerDirectionRight) {
        offset_x = (revealBackgroundView ? contentViewWidth : - contentViewWidth);
        bounce_distance = (revealBackgroundView ? 0.0f : -self.cellBounce);
    }
    
    if (eventHandler)
        eventHandler(DMEventTypeWillOccurr,revealBackgroundView,lastSwipeDirectionOccurred);
    
    isAnimating = YES;
    if (revealBackgroundView) {

        void (^animationBlock)(void) = ^{
            [self setOffsetForView:self.contentView offset:CGPointMake(offset_x, 0.0f)];
	    };

        void (^completionBlock)(BOOL finished) = ^(BOOL finished) {
            if (finished) {
                isAnimating = NO;
                [_delegate slidingCellStoppedSliding:self];

                if (_shelfSize > 0.0f) {
                    self.tapGesture =
                    [[UITapGestureRecognizer alloc]
                     initWithTarget:self
                     action:@selector(handleTap:)];
                    [self.contentView addGestureRecognizer:_tapGesture];
                }
                if (eventHandler)
                    eventHandler(DMEventTypeDidOccurr,revealBackgroundView,lastSwipeDirectionOccurred);

                if (userCompletionBlock != nil) {
                    userCompletionBlock();
                }
            }
	    };

        if (animated) {
            [UIView
             animateWithDuration:self.slidingInAnimationDuration
             delay:0.0f
             options:UIViewAnimationOptionCurveEaseOut
             animations:animationBlock
             completion:completionBlock];
        } else {
            animationBlock();
            completionBlock(YES);
        }

    } else {

        if (eventHandler)
            eventHandler(DMEventTypeWillOccurr,revealBackgroundView,lastSwipeDirectionOccurred);

        void (^animationBlock)(void) = ^{
            CGRect frame = self.contentView.frame;
            frame.origin.x = 0.0f;
            self.contentView.frame = frame;
	    };

        void (^completionBlock)(BOOL finished) = ^(BOOL finished) {

            void (^innerCompletionBlock)(BOOL finished) = ^(BOOL finished) {
                if (eventHandler)
                    eventHandler(DMEventTypeDidOccurr,revealBackgroundView,lastSwipeDirectionOccurred);

                if (finished) {
                    isAnimating = NO;
                    [self.contentView removeGestureRecognizer:_tapGesture];
                    self.tapGesture = nil;
                    [_delegate slidingCellStoppedSliding:self];
                }

                if (userCompletionBlock != nil) {
                    userCompletionBlock();
                }
            };

            if (animated) {
                [UIView
                 animateWithDuration:self.slidingOutAnimationDuration
                 delay:0
                 options:UIViewAnimationCurveLinear
                 animations:^{
                     [self setOffsetForView:self.contentView
                                     offset:CGPointMake(bounce_distance, 0.0f)];
                 } completion:^(BOOL finished) {


                     [UIView
                      animateWithDuration:self.slidingOutAnimationDuration
                      delay:0.0f
                      options:UIViewAnimationCurveLinear
                      animations:^{

                      } completion:^(BOOL finished) {
                          [self setOffsetForView:self.contentView
                                          offset:CGPointMake(-bounce_distance, 0.0f)];

                          innerCompletionBlock(finished);
                      }];
                 }];
                
            } else {
                innerCompletionBlock(YES);
            }
	    };

        if (animated) {
            [UIView
             animateWithDuration:self.slidingOutAnimationDuration
             delay:0.0f
             options:(UIViewAnimationOptionCurveEaseOut|UIViewAnimationOptionAllowUserInteraction)
             animations:animationBlock
             completion:completionBlock];
        } else {
            animationBlock();
            completionBlock(YES);
        }
    }
}

- (void)handlePan:(UIPanGestureRecognizer *)gesture {

    if ([_delegate slidingCellShouldAcceptSwipe:self] == NO) return;

    switch (gesture.state) {
        case UIGestureRecognizerStateBegan:
        case UIGestureRecognizerStateChanged: {

            CGPoint translation =
            [gesture translationInView:gesture.view];

            if (_isPanning) {

                [self
                 setOffsetForView:self.contentView
                 offset:CGPointMake(translation.x, 0.0f)];

                CGFloat percentOpen =
                (CGRectGetMinX(self.contentView.frame) / (CGRectGetWidth(self.contentView.frame) - _shelfSize));

                [_delegate slidingCellPanning:self percentOpen:percentOpen];

                [gesture
                 setTranslation:CGPointMake(0.0f, 0.0f)
                 inView:gesture.view];

            } else {

                if (fabs(translation.x) >= _panningThreshold) {
                    [_delegate slidingCellStartedSliding:self];
                    _isPanning = YES;
                }
            }

        } break;

        default: {

            static CGFloat const velocityThreshold = 1000.0f;

            CGPoint velocity = [gesture velocityInView:gesture.view];

            CGFloat minX = CGRectGetMinX(self.contentView.frame);

            if (minX > 0) {

                if (velocity.x > 0.0f) {
                    lastSwipeDirectionOccurred = UISwipeGestureRecognizerDirectionRight;
                }

                BOOL visible =
                velocity.x > 0.0f &&
                (minX > .25*CGRectGetWidth(self.contentView.frame) ||
                velocity.x > -velocityThreshold);

                [self setBackgroundVisible:visible animated:YES completion:nil];

            } else if (minX < 0) {

                if (velocity.x < 0.0f) {
                    lastSwipeDirectionOccurred = UISwipeGestureRecognizerDirectionLeft;
                }

                BOOL visible =
                velocity.x < 0.0f &&
                (minX < .25*CGRectGetWidth(self.contentView.frame) ||
                velocity.x < -velocityThreshold);

                [self setBackgroundVisible:visible animated:YES completion:nil];
            } else {
                [_delegate slidingCellStoppedSliding:self];
            }

            _isPanning = NO;

        } break;
    }
}

- (void)handleTap:(UITapGestureRecognizer *)gesture {
    [self setBackgroundVisible:NO animated:YES completion:nil];
}

- (void) setOffsetForView:(UIView *) targetView offset:(CGPoint) offset {

    CGRect frame = CGRectOffset(targetView.frame, offset.x, offset.y);
    CGFloat minX = CGRectGetMinX(frame);

    if ((swipeDirection == DMSlidingTableViewCellSwipeBoth ||
         swipeDirection == DMSlidingTableViewCellSwipeRight) && minX > 0) {

        frame.origin.x = MAX(0.0f, frame.origin.x);

        frame.origin.x = MIN(CGRectGetWidth(frame) - _shelfSize, frame.origin.x);

        targetView.frame = frame;

    } else if ((swipeDirection == DMSlidingTableViewCellSwipeBoth ||
                swipeDirection == DMSlidingTableViewCellSwipeLeft) && minX < 0) {

        frame.origin.x = MIN(0.0f, frame.origin.x);

        frame.origin.x = MAX( _shelfSize - CGRectGetWidth(frame), frame.origin.x);

        targetView.frame = frame;
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

@end
