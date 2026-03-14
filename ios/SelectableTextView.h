#import <React/RCTViewComponentView.h>
#import <UIKit/UIKit.h>

#ifndef SelectableTextViewNativeComponent_h
#define SelectableTextViewNativeComponent_h

NS_ASSUME_NONNULL_BEGIN

@interface SelectableTextView : RCTViewComponentView <UITextViewDelegate>
@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) NSArray<NSString *> *menuOptions;
@end

NS_ASSUME_NONNULL_END

#endif /* SelectableTextViewNativeComponent_h */
