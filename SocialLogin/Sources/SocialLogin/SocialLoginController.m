/*
 *  SocialLoginController.m
 *  Login UIViewController
 *  SocialLogin
 *
 *  Facebook, Google+, LinkedIn, Twitter, VK, OK login library for iOS and Mac OS X
 *
 *  Copyright (c) 2013 Exaud, Lda. All rights reserved.
 *
 *  Permission is hereby granted, free of charge, to any person obtaining a copy
 *  of this software and associated documentation files (the "Software"), to deal
 *  in the Software without restriction, including without limitation the rights
 *  to use, copy, modify, merge, publish, distribute
 *  copies of the Software, and to permit persons to whom the Software is
 *  furnished to do so, subject to the following conditions:
 *
 *  The above copyright notice and this permission notice shall be included in
 *  all copies or substantial portions of the Software.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 *  THE SOFTWARE.
 *
 */

#import "SocialLoginController.h"
#import "OAuth.h"

@interface SocialLoginController ()

@property (nonatomic, retain) NSString *appID;

@end

@implementation SocialLoginController

@synthesize delegate;
@synthesize webView;
@synthesize appID;
@synthesize secretKey;
@synthesize isClientOnly;
@synthesize redirectUri;

BOOL isTwitterLoginSuccess = NO;

#pragma mark - Web View Delegate

- (BOOL)webView:(UIWebView *)aWbView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    
    NSURL *URL = [request URL];
    NSString *absoluteString = [URL absoluteString];
    
    if (self.redirectUri && [absoluteString hasPrefix:self.redirectUri])
    {
        switch (lType) {
            case kLoginFacebook: {
                [self dismissViewControllerAnimated:YES completion:^(){
                    [Util handlingFBLogin:URL delegate:self.delegate];
                }];
                return NO;
			}
                
            case kLoginVK: {
                [self dismissViewControllerAnimated:YES completion:^(){
                    [Util handlingVKLogin:URL delegate:self.delegate clientOnly:isClientOnly];
                }];
                return NO;
			}
        }
        
        if ([absoluteString rangeOfString:@"code="].location != NSNotFound) {
            NSString *code = [Util stringBetweenString:@"code="
                                             andString:@"&"
                                           innerString:absoluteString];
            NSLog(@"login response: %@",absoluteString);
            if (code) {
                NSLog(@"Code: %@",code);
                if (isClientOnly) {
                    [self dismissViewControllerAnimated:YES completion:^(){
                        [Util getAccessToken:lType
                                        code:code
                                       appID:self.appID
                                   secretKey:self.secretKey
                                 redirectUri:self.redirectUri
                                    delegate:delegate];
                    }];
                }
                else {
                    [self dismissViewControllerAnimated:YES completion:^(){
                        [delegate socialLoginCompleted:YES credentials:@{@"token":code} loginType:lType];
                    }];
				}
            }
            else {
                NSLog(@"login zero code: %@", absoluteString);
                [self dismissViewControllerAnimated:YES completion:^(){
                    [delegate socialLoginCompleted:NO credentials:nil loginType:lType];
                }];
            }
            
        } else if ([absoluteString rangeOfString:@"error"].location != NSNotFound) {
            NSLog(@"login error: %@", absoluteString);
            [self dismissViewControllerAnimated:YES completion:^(){
                [delegate socialLoginCompleted:NO credentials:nil loginType:lType];
            }];
        }
        return NO;
    }
    
    // Cancelled by the user
    switch (lType) {
        case kLoginTwitter: {
            if (navigationType == UIWebViewNavigationTypeFormSubmitted) {
                NSString *Body = [[[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding] autorelease];
                if ([Body rangeOfString:@"&cancel"].location != NSNotFound) {
                    [self dismissViewControllerAnimated:YES completion:^(){
                        if([delegate respondsToSelector:@selector(socialLoginCancel)])
                            [delegate socialLoginCancel];
                    }];
                    return NO;
                }
            }
            
            if (([absoluteString rangeOfString:@"oauth_token="].location != NSNotFound) &&
               [absoluteString rangeOfString:@"&oauth_verifier="].location != NSNotFound) {
                
                NSDictionary *dic = [Util getUrlParams:URL];
                NSString *oauth_token = dic[@"oauth_token"];
                NSString *oauth_verifier = dic[@"oauth_verifier"];
                
                isTwitterLoginSuccess = YES;
                
                if (isClientOnly) {
                    [self dismissViewControllerAnimated:YES completion:^(){
                        [Util getTWAccessToken:oauth_token
                                      verifier:oauth_verifier
                                   consumerKey:self.appID
                                consumerSecret:self.secretKey
                                    completion:^(BOOL isSuccess, NSDictionary *credentials) {
                                        [delegate socialLoginCompleted:isSuccess
                                                           credentials:credentials
                                                             loginType:lType];
                                    }];
                    }];
				}
                
                else {
                    [self dismissViewControllerAnimated:YES completion:^(){
                        [delegate socialLoginCompleted:YES credentials:@{@"token":oauth_token,@"oauth_verifier":oauth_verifier}
                                             loginType:lType];
                    }];
				}
                return NO;
            }
            break;
		}
            
        case kLoginVK: {
            if ([absoluteString rangeOfString:@"cancel=1"].location != NSNotFound) {
                [self dismissViewControllerAnimated:YES completion:^(){
                    if([delegate respondsToSelector:@selector(socialLoginCancel)]) {
                        [delegate socialLoginCancel];
					}
                }];
                return NO;
            }
            break;
		}
            
        default:
            break;
    }
    NSLog(@"Request: %@", absoluteString);
    
	return YES;
}

-(void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    if (isTwitterLoginSuccess && isTwitter) {
        return;
	}
    
    if (error.code == NSURLErrorCancelled) {
        return;
	}
    
    if (error.code == 102 && [error.domain isEqual:@"WebKitErrorDomain"]) {
        return;
	}
    
    NSLog(@"login Error: %@", [error localizedDescription]);
    
	[delegate socialLoginCompleted:NO credentials:nil loginType:lType];
    [self dismissModalViewControllerAnimated:YES];
}


#pragma mark - init
- (id)initWithLogin:(socialLoginType)l appKey:(NSString *)appKey
{
    self = [super init];
    if (self) {
        lType = l;
        self.appID = appKey;
    }
    return self;
}

- (id)initWithTWLogin:(NSString *)appKey secretKey:(NSString *)twSKey
{
    self = [super init];
    if (self) {
        lType = kLoginTwitter;
        self.appID = appKey;
        self.secretKey = twSKey;
    }
    return self;
}

#pragma mark - View lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIBarButtonItem *bnCancel = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                              target:self
                                                                              action:@selector(bnCancelClick)];
    
    self.navigationItem.rightBarButtonItem = bnCancel;
    [bnCancel release];
}

- (void) viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [webView stopLoading];
    webView.delegate = nil;
}

- (void) bnCancelClick
{
    if ([delegate respondsToSelector:@selector(socialLoginCancel)]) {
        [delegate socialLoginCancel];
	}
    
    [self.navigationController dismissModalViewControllerAnimated:YES];
}

- (void) startLogin
{
    if (!webView) {
        int version = [[[UIDevice currentDevice] systemVersion] intValue];
        
        if (version >= 7) {
            CGRect navBarFrame = self.navigationController.navigationBar.frame;
            CGRect webViewFrame = self.view.bounds;
            webViewFrame.origin.y = navBarFrame.origin.y + navBarFrame.size.height;
            webViewFrame.size.height = webViewFrame.size.height - webViewFrame.origin.y;
            webView = [[UIWebView alloc] initWithFrame:webViewFrame];
        }
        else {
            webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
        }
        
        webView.delegate = self;
        webView.scalesPageToFit = YES;
        [self.view addSubview:webView];
    }
    
    if (!self.appID) {
        [self dismissModalViewControllerAnimated:YES];
        return;
    }
    
    NSString *urlStr = nil;
    
    switch (lType) {
            
        case kLoginTwitter: {
            [Util twitterLogin:self.appID consumerSecret:self.secretKey completion:^(NSString* link){
                if (link) {
                    [webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:link]]];
				}
                else {
                    [self dismissModalViewControllerAnimated:NO];
                    [self.delegate socialLoginCompleted:NO credentials:nil loginType:kLoginTwitter];
                }
            }];
            return;
		}
            
        case kLoginVK: {
            NSString *rType = (isClientOnly) ? @"token" : @"code";
            urlStr = [NSString stringWithFormat:@"https://oauth.vk.com/authorize?client_id=%@&redirect_uri=%@&display=mobile&response_type=%@", self.appID,self.redirectUri,rType];
            break;
        }
            
        case kLoginODK: {
            urlStr = [NSString stringWithFormat:@"https://www.odnoklassniki.ru/oauth/authorize?client_id=%@&response_type=code&redirect_uri=%@&layout=m",self.appID,self.redirectUri];
            break;
		}
            
        case kLoginGPP: {
            self.redirectUri = @"http://localhost";
            urlStr = [NSString stringWithFormat:@"https://accounts.google.com/o/oauth2/auth?"
                      @"response_type=code&client_id=%@"
                      @"&scope=https://www.googleapis.com/auth/plus.login&redirect_uri=%@",self.appID,self.redirectUri];
            break;
		}
            
        case kLoginLinkedIn: {
            self.redirectUri = @"http://localhost";
            urlStr = [NSString stringWithFormat:
                      @"https://www.linkedin.com/uas/oauth2/authorization?response_type=code"
                      @"&client_id=%@"
                      @"&state=%@"
                      @"&redirect_uri=%@",self.appID,[Util genRandString],self.redirectUri];
            break;
		}
            
        case kLoginFacebook: {
            self.redirectUri = @"fbconnect://success";
            urlStr = [NSString stringWithFormat:@"https://m.facebook.com/dialog/oauth?display=touch&e2e=%@"
                      @"&client_id=%@&type=user_agent&redirect_uri=%@"
                      @"&state=%@&response_type=token&scope=publish_actions",[Util getE2E],
                      self.appID,self.redirectUri,[Util genRandString]];
            break;
		}
    }
    urlStr = [urlStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    [webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlStr]]];
}

- (void)showModal
{
    UIWindow *win = [[UIApplication sharedApplication] keyWindow];
    UIViewController *rootViewController = [win rootViewController];
	
	if (!rootViewController) {
        id c = [[win subviews][0] nextResponder];
        if ([c isKindOfClass:[UIViewController class]]) {
            rootViewController = c;
		}
    }
    
    if (rootViewController) {
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:self];
        nav.navigationBar.barStyle = UIBarStyleBlack;
        nav.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        [rootViewController presentViewController:nav animated:YES completion:^(){
            [self startLogin];
        }];
        [nav release];
    }
    else {
        NSLog(@"Root view controller not found!");
	}
}

- (void)dealloc
{
    [delegate release];
    [appID release];
    webView.delegate = nil;
    [webView release];
    [super dealloc];
}

@end