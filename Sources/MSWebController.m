//
//  MSWebController.m
//  MSWebController
//
//  Created by Maxwell on 2017/5/7.
//  Copyright © 2017年 Maxwell. All rights reserved.
//

#import "MSWebController.h"
#import "MSWebActivitySafari.h"
#import "MSWebActivityChrome.h"

@interface MSWebController ()

@property (nonatomic, strong, readwrite) MSWebView *webView;

@property (nonatomic, strong) UIBarButtonItem *backBarButtonItem;
@property (nonatomic, strong) UIBarButtonItem *forwardBarButtonItem;
@property (nonatomic, strong) UIBarButtonItem *refreshBarButtonItem;
@property (nonatomic, strong) UIBarButtonItem *stopBarButtonItem;
@property (nonatomic, strong) UIBarButtonItem *actionBarButtonItem;
@property (nonatomic, strong, readwrite) NSURLRequest *originalRequest;

@property (nonatomic, strong) UIBarButtonItem *leftBackButtonItem;
@property (nonatomic, strong) UIBarButtonItem *leftCloseButtonItem;

@end

@implementation MSWebController

- (instancetype)init {
    self = [super init];
    if (self) {
        [self initialize];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    [self initialize];
}

- (void)loadView {
    [super loadView];
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.extendedLayoutIncludesOpaqueBars = YES;
    [self.view addSubview:self.webView];
    id topLayoutGuide = self.topLayoutGuide;
    id bottomLayoutGuide = self.bottomLayoutGuide;
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_webView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_webView)]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[topLayoutGuide][_webView][bottomLayoutGuide]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_webView, topLayoutGuide,bottomLayoutGuide)]];
}

- (void)setShowToolBar:(BOOL)showToolBar {
    if (_showToolBar == showToolBar) {
        return;
    }
    _showToolBar = showToolBar;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        if (!showToolBar) {
            self.navigationItem.rightBarButtonItems = @[];
        } else {
            [self updateToolbarItems];
        }
    } else {
        [self.navigationController setToolbarHidden:!showToolBar animated:NO];
    }
}

- (void)loadWebView {
    _webView = [[MSWebView alloc] initWithFrame:CGRectZero usingUIWebView:self.useUIWebView];
    _webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
}

- (UIBarButtonItem *)backBarButtonItem {
    if (!_backBarButtonItem) {
        _backBarButtonItem = [[UIBarButtonItem alloc]
                              initWithImage:[MSWebActivity ms_imageNamed:@"MSWebViewControllerBack"]
                              style:UIBarButtonItemStylePlain
                              target:self
                              action:@selector(goBackTapped:)];
        _backBarButtonItem.width = 18.0f;
    }
    return _backBarButtonItem;
}



- (UIBarButtonItem *)forwardBarButtonItem {
    if (!_forwardBarButtonItem) {
        _forwardBarButtonItem = [[UIBarButtonItem alloc]
                                 initWithImage:[MSWebActivity ms_imageNamed:@"MSWebViewControllerNext"]
                                 style:UIBarButtonItemStylePlain
                                 target:self
                                 action:@selector(goForwardTapped:)];
        _forwardBarButtonItem.width = 18.0f;
    }
    return _forwardBarButtonItem;
}

- (UIBarButtonItem *)leftBackButtonItem {
    if (!_leftBackButtonItem) {
        _leftBackButtonItem = [[UIBarButtonItem alloc]
                               initWithImage:[MSWebActivity ms_imageNamed:@"MSWebViewControllerBack"]
                               style:UIBarButtonItemStylePlain
                               target:self
                               action:@selector(goBackTapped:)];
    }
    return _leftBackButtonItem;
}

- (UIBarButtonItem *)leftCloseButtonItem {
    if (!_leftCloseButtonItem) {
        _leftCloseButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(closeTapped:)];
    }
    return _leftCloseButtonItem;
}

- (UIBarButtonItem *)refreshBarButtonItem {
    if (!_refreshBarButtonItem) {
        _refreshBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(reloadTapped:)];
    }
    return _refreshBarButtonItem;
}

- (UIBarButtonItem *)stopBarButtonItem {
    if (!_stopBarButtonItem) {
        _stopBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(stopTapped:)];
    }
    return _stopBarButtonItem;
}

- (UIBarButtonItem *)actionBarButtonItem {
    if (!_actionBarButtonItem) {
        _actionBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(actionButtonTapped:)];
    }
    return _actionBarButtonItem;
}

- (void)updateToolbarItems {
    if (self.showToolBar) {
        
        self.backBarButtonItem.enabled = self.webView.canGoBack;
        self.forwardBarButtonItem.enabled = self.webView.canGoForward;
        
        UIBarButtonItem *refreshStopBarButtonItem = self.webView.isLoading ? self.stopBarButtonItem : self.refreshBarButtonItem;
        
        UIBarButtonItem *fixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
        UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            CGFloat toolbarWidth = 250.0f;
            fixedSpace.width = 35.0f;
            
            NSArray *items = [NSArray arrayWithObjects:
                              fixedSpace,
                              refreshStopBarButtonItem,
                              fixedSpace,
                              self.backBarButtonItem,
                              fixedSpace,
                              self.forwardBarButtonItem,
                              fixedSpace,
                              self.actionBarButtonItem,
                              nil];
            
            UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, toolbarWidth, 44.0f)];
            toolbar.items = items;
            toolbar.barStyle = self.navigationController.navigationBar.barStyle;
            toolbar.tintColor = self.navigationController.navigationBar.tintColor;
            self.navigationItem.rightBarButtonItems = items.reverseObjectEnumerator.allObjects;
        } else {
            NSArray *items = [NSArray arrayWithObjects:
                              fixedSpace,
                              self.backBarButtonItem,
                              flexibleSpace,
                              self.forwardBarButtonItem,
                              flexibleSpace,
                              refreshStopBarButtonItem,
                              flexibleSpace,
                              self.actionBarButtonItem,
                              fixedSpace,
                              nil];
            
            self.navigationController.toolbar.barStyle = self.navigationController.navigationBar.barStyle;
            self.navigationController.toolbar.tintColor = self.navigationController.navigationBar.tintColor;
            self.toolbarItems = items;
        }
    }
    
    if (self.showNavToolBar) {
        if (self.navigationController.viewControllers.count > 1) {
            NSArray *items = [NSArray arrayWithObjects:
                              self.leftBackButtonItem,
                              (self.webView.canGoBack ? self.leftCloseButtonItem : nil),
                              nil];
            self.navigationItem.leftBarButtonItems = items;
        }
    }
}

- (MSWebView *)webView {
    if (!_webView) {
        [self loadWebView];
    }
    return _webView;
}

- (void)initialize {
    self.showToolBar = YES;
    self.networkActivityIndicatorVisible = YES;
    self.showNavToolBar = YES;
}

- (void)loadRequest:(NSURLRequest *)request {
    if (!_webView) {
        self.originalRequest = request;
    } else {
        [self.webView loadRequest:request];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self updateToolbarItems];
    
    self.webView.delegate = self;
    self.view.backgroundColor = [UIColor whiteColor];
    NSParameterAssert(self.originalRequest);
    [self.webView loadRequest:self.originalRequest];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
}

- (void)setNetworkActivityIndicatorVisible:(BOOL)networkActivityIndicatorVisible {
    _networkActivityIndicatorVisible = networkActivityIndicatorVisible;
    
    [self endNetworkActivity];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [self.navigationController setToolbarHidden:!self.showToolBar animated:animated];
    } else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [self.navigationController setToolbarHidden:self.showToolBar animated:animated];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if ([UIApplication sharedApplication].networkActivityIndicatorVisible) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    }
}

- (void)startNetworkActivity {
    if (self.networkActivityIndicatorVisible) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    }
}

- (void)endNetworkActivity {
    if ([UIApplication sharedApplication].networkActivityIndicatorVisible) {
        if (self.networkActivityIndicatorVisible) {
            
        }
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    }
}

#pragma mark - MSWebViewDelegate

- (BOOL)webView:(MSWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    return YES;
}

- (void)webViewDidStartLoad:(MSWebView *)webView {
    [self startNetworkActivity];
    [self updateToolbarItems];
}

- (void)webViewDidFinishLoad:(MSWebView *)webView {
    [self endNetworkActivity];
    [self updateToolbarItems];
    
    NSString *title = webView.title;
    if (title.length > 10) {
        title = [[title substringToIndex:9] stringByAppendingString:@"…"];
    }
    
    self.title = title;
    if (self.navigationItem.title == nil) {
        self.navigationItem.title = title;
    }
}

- (void)webView:(MSWebView *)webView didFailLoadWithError:(NSError *)error {
    [self endNetworkActivity];
    [self updateToolbarItems];
}

- (void)dealloc {
    [self endNetworkActivity];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Target actions

- (void)closeTapped:(UIBarButtonItem *)sender {
    NSParameterAssert(sender);
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)goBackTapped:(UIBarButtonItem *)sender {
    NSParameterAssert(sender);
    if (self.webView.canGoBack) {
        [self.webView goBack];
    } else {
        [self closeTapped:sender];
    }
}

- (void)goForwardTapped:(UIBarButtonItem *)sender {
    NSParameterAssert(sender);
    [self.webView goForward];
}

- (void)reloadTapped:(UIBarButtonItem *)sender {
    NSParameterAssert(sender);
    [self.webView reload];
}

- (void)stopTapped:(UIBarButtonItem *)sender {
    NSParameterAssert(sender);
    [self.webView stopLoading];
    [self updateToolbarItems];
}

- (void)actionButtonTapped:(id)sender {
    NSParameterAssert(sender);
    NSURL *url = self.webView.currentRequest.URL ?: self.webView.originRequest.URL;
    if (url != nil) {
        NSArray *activities = @[[[MSWebActivitySafari alloc] init], [[MSWebActivityChrome alloc] init]];
        
        if ([[url absoluteString] hasPrefix:@"file:///"]) {
            UIDocumentInteractionController *dc = [UIDocumentInteractionController interactionControllerWithURL:url];
            [dc presentOptionsMenuFromRect:self.view.bounds inView:self.view animated:YES];
        } else {
            UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:@[url] applicationActivities:activities];
            
#ifdef __IPHONE_8_0
            if ([UIDevice currentDevice].systemVersion.floatValue >= 8.0 && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                UIPopoverPresentationController *ctrl = activityController.popoverPresentationController;
                ctrl.sourceView = self.view;
                ctrl.barButtonItem = sender;
            }
#endif
            [self presentViewController:activityController animated:YES completion:nil];
        }
    }
}

- (void)doneButtonTapped:(id)sender {
    NSParameterAssert(sender);
    [self dismissViewControllerAnimated:YES completion:NULL];
}

@end
