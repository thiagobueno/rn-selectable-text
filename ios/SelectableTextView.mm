#import "SelectableTextView.h"

#import <react/renderer/components/SelectableTextViewSpec/ComponentDescriptors.h>
#import <react/renderer/components/SelectableTextViewSpec/EventEmitters.h>
#import <react/renderer/components/SelectableTextViewSpec/Props.h>
#import <react/renderer/components/SelectableTextViewSpec/RCTComponentViewHelpers.h>

#import "RCTFabricComponentsPlugins.h"
#import <React/RCTConversions.h>

using namespace facebook::react;

@class SelectableTextView;

// ====================================================================
// CRASH PREVENTION: Safe C++ String Conversion
// ====================================================================
static std::string safeStdString(NSString *str) {
    if (!str) return "";
    const char *utf8 = [str UTF8String];
    return utf8 ? std::string(utf8) : "";
}

@interface SelectableUITextView : UITextView
@property (nonatomic, weak) SelectableTextView *parentSelectableTextView;
@end

@implementation SelectableUITextView

- (void)didMoveToWindow {
    [super didMoveToWindow];
    if (self.window) {
        BOOL wasSelectable = self.selectable;
        self.selectable = NO;
        self.selectable = wasSelectable;
    }
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    if (self.parentSelectableTextView) {
        return [self.parentSelectableTextView canPerformAction:action withSender:sender];
    }
    return [super canPerformAction:action withSender:sender];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    if (self.parentSelectableTextView) {
        NSMethodSignature *signature = [self.parentSelectableTextView methodSignatureForSelector:aSelector];
        if (signature) {
            return signature;
        }
    }
    return [super methodSignatureForSelector:aSelector];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
    if (self.parentSelectableTextView) {
        [self.parentSelectableTextView forwardInvocation:anInvocation];
    } else {
        [super forwardInvocation:anInvocation];
    }
}

- (void)copy:(id)sender
{
    // Silently blocked
}

@end

@interface SelectableTextView () <RCTSelectableTextViewViewProtocol, UITextViewDelegate>
- (void)unhideAllViews:(UIView *)view;
@end

@implementation SelectableTextView {
    std::vector<std::string> _menuOptionsVector;
    SelectableUITextView *_customTextView;
    NSArray<NSString *> *_menuOptions;
}

+ (ComponentDescriptorProvider)componentDescriptorProvider
{
    return concreteComponentDescriptorProvider<SelectableTextViewComponentDescriptor>();
}

- (instancetype)initWithFrame:(CGRect)frame
{
  if (self = [super initWithFrame:frame]) {
    static const auto defaultProps = std::make_shared<const SelectableTextViewProps>();
    _props = defaultProps;

    _customTextView = [[SelectableUITextView alloc] init];
    _customTextView.parentSelectableTextView = self;
    _customTextView.delegate = self;
    _customTextView.editable = NO;
    _customTextView.selectable = YES;
    _customTextView.scrollEnabled = NO;
    _customTextView.backgroundColor = [UIColor clearColor];
    _customTextView.textContainerInset = UIEdgeInsetsZero;
    _customTextView.textContainer.lineFragmentPadding = 0;
    _customTextView.userInteractionEnabled = YES;
    
    _customTextView.allowsEditingTextAttributes = NO;
    _customTextView.dataDetectorTypes = UIDataDetectorTypeNone;
    
    _customTextView.text = @"";
    _menuOptions = @[];
    
    self.contentView = _customTextView;
    self.userInteractionEnabled = YES;
  }

  return self;
}

- (void)updateLayoutMetrics:(const facebook::react::LayoutMetrics &)layoutMetrics
           oldLayoutMetrics:(const facebook::react::LayoutMetrics &)oldLayoutMetrics {
    [super updateLayoutMetrics:layoutMetrics oldLayoutMetrics:oldLayoutMetrics];
    
    CGRect frame = RCTCGRectFromRect(layoutMetrics.getContentFrame());
    _customTextView.frame = frame;
}

- (void)unhideAllViews:(UIView *)view {
    if (view != _customTextView && view != self) {
        view.hidden = NO;
    }
    for (UIView *subview in view.subviews) {
        [self unhideAllViews:subview];
    }
}

- (void)unmountChildComponentView:(UIView<RCTComponentViewProtocol> *)childComponentView index:(NSInteger)index
{
    [self unhideAllViews:childComponentView];
    [super unmountChildComponentView:childComponentView index:index];
}

- (void)prepareForRecycle {
    [super prepareForRecycle];
    
    [_customTextView resignFirstResponder];
    
    [[UIMenuController sharedMenuController] hideMenuFromView:_customTextView];
    [UIMenuController sharedMenuController].menuItems = nil;
    
    _customTextView.text = nil;
    _customTextView.selectedTextRange = nil;
    
    [self unhideAllViews:self];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [UIMenuController sharedMenuController].menuItems = nil;
}

- (void)updateProps:(Props::Shared const &)props oldProps:(Props::Shared const &)oldProps
{
    const auto &oldViewProps = *std::static_pointer_cast<SelectableTextViewProps const>(_props);
    const auto &newViewProps = *std::static_pointer_cast<SelectableTextViewProps const>(props);

    if (oldViewProps.menuOptions != newViewProps.menuOptions) {
        _menuOptionsVector = newViewProps.menuOptions;
        
        NSMutableArray<NSString *> *options = [[NSMutableArray alloc] init];
        for (const auto& option : _menuOptionsVector) {
            [options addObject:[NSString stringWithUTF8String:option.c_str()]];
        }
        _menuOptions = options;
    }

    [super updateProps:props oldProps:oldProps];
}

- (void)mountChildComponentView:(UIView<RCTComponentViewProtocol> *)childComponentView index:(NSInteger)index
{
    [super mountChildComponentView:childComponentView index:index];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self updateTextViewContent];
}

- (void)updateTextViewContent
{
    NSMutableAttributedString *combinedAttributedText = [[NSMutableAttributedString alloc] init];
    [self extractStyledTextFromView:self intoAttributedString:combinedAttributedText hideViews:YES];
    _customTextView.attributedText = combinedAttributedText;
}

- (void)extractStyledTextFromView:(UIView *)view intoAttributedString:(NSMutableAttributedString *)attributedString hideViews:(BOOL)hideViews
{
    BOOL foundText = NO;
    
    if ([view respondsToSelector:@selector(attributedText)]) {
        NSAttributedString *attributedText = [view performSelector:@selector(attributedText)];
        if (attributedText && attributedText.length > 0) {
            [attributedString appendAttributedString:attributedText];
            foundText = YES;
        }
    }
    else if ([view isKindOfClass:[UILabel class]]) {
        UILabel *label = (UILabel *)view;
        if (label.attributedText && label.attributedText.length > 0) {
            [attributedString appendAttributedString:label.attributedText];
            foundText = YES;
        } else if (label.text && label.text.length > 0) {
            NSAttributedString *plainText = [[NSAttributedString alloc] initWithString:label.text];
            [attributedString appendAttributedString:plainText];
            foundText = YES;
        }
    }
    else if ([view respondsToSelector:@selector(text)]) {
        NSString *text = [view performSelector:@selector(text)];
        if (text && text.length > 0) {
            NSAttributedString *plainText = [[NSAttributedString alloc] initWithString:text];
            [attributedString appendAttributedString:plainText];
            foundText = YES;
        }
    }
    
    if (foundText && hideViews && view != _customTextView && view != self) {
        view.hidden = YES;
    }
    
    for (UIView *subview in view.subviews) {
        if (subview != _customTextView && subview != self.contentView) {
            [self extractStyledTextFromView:subview intoAttributedString:attributedString hideViews:hideViews];
        }
    }
}

#pragma mark - UITextViewDelegate

// ====================================================================
// REAL-TIME CUSTOM MODE TRACKING (With Crash Prevention bounds check)
// ====================================================================
- (void)textViewDidChangeSelection:(UITextView *)textView
{
    if (textView.selectedRange.location != NSNotFound && textView.selectedRange.length > 0) {
        
        // SAFE BOUNDS CHECK: Prevents iOS 15/17/18 out-of-bounds crash
        NSString *selectedText = @"";
        if (textView.selectedRange.location + textView.selectedRange.length <= textView.text.length) {
            selectedText = [textView.text substringWithRange:textView.selectedRange];
        }
        
        // INVISIBLE MODE (ALL IOS VERSIONS)
        if (_menuOptions.count == 0) {
            if (auto eventEmitter = std::static_pointer_cast<const SelectableTextViewEventEmitter>(_eventEmitter)) {
                SelectableTextViewEventEmitter::OnSelection selectionEvent = {
                    .chosenOption = "CUSTOM_MODE",
                    .highlightedText = safeStdString(selectedText)
                };
                eventEmitter->onSelection(selectionEvent);
            }
            return;
        }
        
        // STANDARD MODE
        if (@available(iOS 16.0, *)) {
            return;
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showCustomMenu];
            });
        }
    } else {
        [[UIMenuController sharedMenuController] hideMenuFromView:_customTextView];
        
        // IF SELECTION IS CLEARED, NOTIFY JS TO HIDE THE BOTTOM SHEET
        if (_menuOptions.count == 0) {
             if (auto eventEmitter = std::static_pointer_cast<const SelectableTextViewEventEmitter>(_eventEmitter)) {
                SelectableTextViewEventEmitter::OnSelection selectionEvent = {
                    .chosenOption = "CUSTOM_MODE",
                    .highlightedText = ""
                };
                eventEmitter->onSelection(selectionEvent);
            }
        }
    }
}

// ====================================================================
// THE NEW IOS 16+ API
// ====================================================================
- (UIMenu *)textView:(UITextView *)textView editMenuForTextInRange:(NSRange)range suggestedActions:(NSArray<UIMenuElement *> *)suggestedActions API_AVAILABLE(ios(16.0)) {
    
    if (_menuOptions.count == 0) {
        // SAFE BOUNDS CHECK
        NSString *selectedText = @"";
        if (range.location != NSNotFound && range.location + range.length <= textView.text.length) {
            selectedText = [textView.text substringWithRange:range];
        }
        
        if (selectedText.length > 0) {
            if (auto eventEmitter = std::static_pointer_cast<const SelectableTextViewEventEmitter>(_eventEmitter)) {
                SelectableTextViewEventEmitter::OnSelection selectionEvent = {
                    .chosenOption = "CUSTOM_MODE",
                    .highlightedText = safeStdString(selectedText)
                };
                eventEmitter->onSelection(selectionEvent);
            }
        }
        return [UIMenu menuWithTitle:@"" children:@[]];
    }

    NSMutableArray<UIMenuElement *> *customActions = [[NSMutableArray alloc] init];

    for (NSString *option in _menuOptions) {
        UIAction *action = [UIAction actionWithTitle:option image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            [self handleMenuSelection:option];
        }];
        [customActions addObject:action];
    }

    return [UIMenu menuWithTitle:@"" children:customActions];
}

- (void)showCustomMenu
{
    if (![_customTextView canBecomeFirstResponder]) return;
    
    [_customTextView becomeFirstResponder];
    
    UIMenuController *menuController = [UIMenuController sharedMenuController];
    menuController.menuItems = nil;
    
    NSMutableArray<UIMenuItem *> *menuItems = [[NSMutableArray alloc] init];
    
    for (NSString *option in _menuOptions) {
        NSString *clean1 = [option stringByReplacingOccurrencesOfString:@" " withString:@"_"];
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"[^a-zA-Z0-9_]" options:0 error:nil];
        NSString *selectorName = [regex stringByReplacingMatchesInString:clean1 options:0 range:NSMakeRange(0, clean1.length) withTemplate:@"_"];
        
        SEL action = NSSelectorFromString([NSString stringWithFormat:@"customAction_%@:", selectorName]);
        UIMenuItem *menuItem = [[UIMenuItem alloc] initWithTitle:option action:action];
        [menuItems addObject:menuItem];
    }
    
    menuController.menuItems = menuItems;
    [menuController update];
    
    CGRect selectedRect = [_customTextView firstRectForRange:_customTextView.selectedTextRange];
    
    // CRASH PREVENTION: Validate rect before showing menu (iOS 15 safety)
    if (!CGRectIsEmpty(selectedRect) && !CGRectIsNull(selectedRect) && !CGRectIsInfinite(selectedRect)) {
        CGRect targetRect = [_customTextView convertRect:selectedRect toView:_customTextView];
        [menuController showMenuFromView:_customTextView rect:targetRect];
    }
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

// ====================================================================
// SUPPRESS SYSTEM MENU IN CUSTOM MODE
// ====================================================================
- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    if (_menuOptions.count == 0) {
        return NO;
    }
    
    NSString *selectorName = NSStringFromSelector(action);
    if ([selectorName hasPrefix:@"customAction_"] && [selectorName hasSuffix:@":"]) {
        return YES;
    }
    
    if (action == @selector(copy:) || action == @selector(selectAll:)) {
        return YES;
    }
    
    return NO;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    NSString *selectorName = NSStringFromSelector(aSelector);
    if ([selectorName hasPrefix:@"customAction_"] && [selectorName hasSuffix:@":"]) {
        return [NSMethodSignature signatureWithObjCTypes:"v@:@"];
    }
    return [super methodSignatureForSelector:aSelector];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
    NSString *selectorName = NSStringFromSelector(anInvocation.selector);
    
    if ([selectorName hasPrefix:@"customAction_"] && [selectorName hasSuffix:@":"]) {
        // CRASH PREVENTION: Validate selector length before cutting string
        if (selectorName.length > 14) {
            NSString *cleanedOption = [selectorName substringWithRange:NSMakeRange(13, selectorName.length - 14)];
            
            NSString *originalOption = nil;
            for (NSString *option in _menuOptions) {
                NSString *clean1 = [option stringByReplacingOccurrencesOfString:@" " withString:@"_"];
                NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"[^a-zA-Z0-9_]" options:0 error:nil];
                NSString *testSelectorName = [regex stringByReplacingMatchesInString:clean1 options:0 range:NSMakeRange(0, clean1.length) withTemplate:@"_"];
                
                if ([testSelectorName isEqualToString:cleanedOption]) {
                    originalOption = option;
                    break;
                }
            }
            
            if (originalOption) {
                [self handleMenuSelection:originalOption];
            }
        }
    } else {
        [super forwardInvocation:anInvocation];
    }
}

- (void)handleMenuSelection:(NSString *)selectedOption
{
    NSRange selectedRange = _customTextView.selectedRange;
    NSString *selectedText = @"";
    
    // SAFE BOUNDS CHECK
    if (selectedRange.location != NSNotFound && selectedRange.length > 0 && (selectedRange.location + selectedRange.length <= _customTextView.text.length)) {
        selectedText = [_customTextView.text substringWithRange:selectedRange];
    }
    
    _customTextView.selectedRange = NSMakeRange(0, 0);
    [[UIMenuController sharedMenuController] hideMenuFromView:_customTextView];
    
    if (auto eventEmitter = std::static_pointer_cast<const SelectableTextViewEventEmitter>(_eventEmitter)) {
        SelectableTextViewEventEmitter::OnSelection selectionEvent = {
            .chosenOption = safeStdString(selectedOption),
            .highlightedText = safeStdString(selectedText)
        };
        eventEmitter->onSelection(selectionEvent);
    }
}

Class<RCTComponentViewProtocol> SelectableTextViewCls(void)
{
    return SelectableTextView.class;
}

@end