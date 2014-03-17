/*
 *  SocialLogin.m
 *  Main class
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

#import "SocialLogin.h"
#import "SocialLoginController.h"

#import "FBPoster.h"
#import "Util.h"
#import <Accounts/Accounts.h>
#import "OAuth.h"
#import "ASIHTTPRequest.h"

#import <Social/Social.h>

@implementation SocialLogin

static NSString *vkAppKey = nil;
static NSString *odkAppKey = nil;
static NSString *odkSecretKey = nil;
static NSString *twAppKey = nil;
static NSString *twSecretKey = nil;
static NSString *gppAppKey = nil;
static NSString *gppSecretKey = nil;
static NSString *lnAppKey = nil;
static NSString *lnSecretKey = nil;
static NSString *fbAppKey = nil;

static NSString *vkRedirectUri = nil;
static NSString *odkRedirectUri = nil;

static id <SocialLoginDelegate> fbDelegate = nil; // global variable needed for fbLogin, handleFBLogin and fbKill methods

+ (void)load
{
    odkAppKey = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"ODKAppKey"];
    vkAppKey = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"VKAppKey"];
    twAppKey = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"TWAppKey"];
    twSecretKey = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"TWSecretAppKey"];
    gppAppKey = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"GPPAppKey"];
    lnAppKey = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"LNAppKey"];
    fbAppKey = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"FacebookAppID"];
    odkSecretKey = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"ODKSecretKey"];
    gppSecretKey = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"GPPSecretKey"];
    lnSecretKey = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"LNSecretKey"];
    
    vkRedirectUri = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"VKRedirectUri"];
    odkRedirectUri = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"ODKRedirectUri"];
}

+ (void)publishFBAppKey:(NSString *)key
{
    fbAppKey = key;
}

+ (void)publishVKAppKey:(NSString *)key
{
    vkAppKey = key;
}

+ (void)publishODKAppKey:(NSString *)key
{
    odkAppKey = key;
}

+ (void)publishTWAppKey:(NSString *)key secretKey:(NSString *)secretKey
{
    twAppKey = key;
    twSecretKey = secretKey;
}

+ (void)publishGPPAppKey:(NSString *)key
{
    gppAppKey = key;
}

+ (void)publishODKRedirectUri:(NSString *)uri
{
    odkRedirectUri = uri;
}

+ (void)publishVKRedirectUri:(NSString *)uri
{
    vkRedirectUri = uri;
}

+ (void)publishLNAppKey:(NSString *)key
{
    lnAppKey = key;
}

+ (void)publishODKSecretKey:(NSString *)key
{
    odkSecretKey = key;
}

+ (void)publishGPPSecretKey:(NSString *)key
{
    gppSecretKey = key;
}

+ (void)publishLNSecretKey:(NSString *)key
{
    lnSecretKey = key;
}

+ (void)postOnFacebook:(NSString *)name
               address:(NSString *)address
                  site:(NSString *)site
                picURL:(NSString *)picURL
               message:(NSString *)message
{
    if (![Util checkInternetConnction])
	{
        NSLog(@"Not connected!");
		return;
	}
    
    if (fbAppKey)
    {
        FBPoster *poster = [[FBPoster alloc] initWithName:name
                                                  address:address
                                                     site:site
                                                   picURL:picURL
                                                  message:message];
        [poster postMessage:[Util getValidFBToken] appKey:fbAppKey];
        [poster release];
    }
    else
	{
        NSLog(@"FB app key not set! Call publishFBAppKey or add a string valued key with the appropriate id named FacebookAppID to the bundle *.plist to set it.");
	}
}

+ (void)closeLoginSession
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:FB_TOKEN];
    [defaults removeObjectForKey:FB_TOKEN_LIFETIME];
    [defaults synchronize];
    
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSArray *cookies = [cookieStorage cookies];
    for (NSHTTPCookie *cookie in cookies) {
        [cookieStorage deleteCookie:cookie];
    }
}

+ (void) renewCredentials:(NSString *)accID
                 delegate:(id <SocialLoginDelegate>)delegate
                loginType:(socialLoginType)loginType
               clientOnly:(BOOL)isClientOnly
{
    
    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    ACAccount *account = [accountStore accountWithIdentifier:accID];
    [accountStore release];
    
    [accountStore renewCredentialsForAccount:account completion:^(ACAccountCredentialRenewResult renewResult, NSError *error){
        switch (renewResult) {
            case ACAccountCredentialRenewResultRenewed:
            {
                ACAccount *renewedAccount = [accountStore accountWithIdentifier:accID];
                NSString *token = renewedAccount.credential.oauthToken;
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (token)
                    {
                        [delegate socialLoginCompleted:YES
                                           credentials:@{@"token": token}
                                             loginType:loginType];
                    }
                    else
                    {
                        [SocialLogin makeSocalLoginController:loginType
                                                     delegate:delegate
                                                   clientOnly:isClientOnly];
                    }
                });
                break;
            }
            default:
                [SocialLogin makeSocalLoginController:loginType
                                             delegate:delegate
                                           clientOnly:isClientOnly];
                break;
        }
    }];
    
}

+ (void)loginWithAccountStoreDelegate:(id <SocialLoginDelegate>)delegate
                            loginType:(socialLoginType)loginType
{
    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    
    NSString *accountTypeID = nil;
    NSDictionary *options = nil;
    BOOL isClientOnly = NO;
    switch (loginType) {
        case kLoginFacebook: {
            accountTypeID = ACAccountTypeIdentifierFacebook;
            options = @{
                        ACFacebookAppIdKey:fbAppKey,
                        ACFacebookPermissionsKey:@[@"publish_actions"],
                        ACFacebookAudienceKey: ACFacebookAudienceFriends
                        };
            break;
        }
            
        case kLoginTwitter: {
            accountTypeID = ACAccountTypeIdentifierTwitter;
            isClientOnly = YES;
            break;
        }
            
#if !TARGET_OS_IPHONE
		case kLoginLinkedIn: {
            accountTypeID = ACAccountTypeIdentifierLinkedIn;
            isClientOnly = YES;
            options = @{
                        ACLinkedInAppIdKey:lnAppKey,
                        ACLinkedInPermissionsKey:@[@"r_basicprofile"]
                        };
            break;
        }
#endif
            
        default:
            break;
    }
    
    ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:accountTypeID];
    [accountStore requestAccessToAccountsWithType:accountType
                                          options:options
                                       completion:^(BOOL granted, NSError *e) {
                                           if (granted)
										   {
                                               NSArray *accounts = [accountStore accountsWithAccountType:accountType];
                                               if(!accounts.count)
                                               {
                                                   dispatch_async(dispatch_get_main_queue(), ^{
                                                       [SocialLogin makeSocalLoginController:loginType
                                                                                    delegate:delegate
                                                                                  clientOnly:isClientOnly];
                                                   });
                                               }
                                               else
                                               {
                                                   switch (loginType) {
                                                       case kLoginTwitter: {
                                                           [Util twReverseAuth:twAppKey
                                                                     secretKey:twSecretKey account:[[accounts objectAtIndex:0] identifier]
                                                                    completion:^(BOOL isSuccess, NSDictionary *credentials){
                                                                        if(isSuccess)
                                                                        {
                                                                            [delegate socialLoginCompleted:isSuccess
                                                                                               credentials:credentials
                                                                                                 loginType:loginType];
                                                                        }
                                                                        else
                                                                        {
                                                                            [SocialLogin makeSocalLoginController:loginType
                                                                                                         delegate:delegate
                                                                                                       clientOnly:isClientOnly];
                                                                        }
                                                                    }];
                                                           break;
                                                       }
                                                           
                                                       default: {
                                                           ACAccount *account = [accounts objectAtIndex:0];
                                                           NSString *token = account.credential.oauthToken;
                                                           dispatch_async(dispatch_get_main_queue(), ^{
                                                               if (token)
                                                               {
                                                                   [delegate socialLoginCompleted:YES
                                                                                      credentials:@{@"token": token}
                                                                                        loginType:loginType];
                                                               }
                                                               else
                                                               {
                                                                   [SocialLogin renewCredentials:account.identifier
                                                                                        delegate:delegate
                                                                                       loginType:loginType
                                                                                      clientOnly:isClientOnly];
                                                               }
                                                           });
                                                           break;
                                                       }
                                                   }
                                               }
                                           }
                                           else
										   {
                                               NSLog(@"%@", e);
                                               dispatch_async(dispatch_get_main_queue(), ^{
                                                   [SocialLogin makeSocalLoginController:loginType
                                                                                delegate:delegate
                                                                              clientOnly:isClientOnly];
                                               });
                                           }
                                       }];
    [accountStore release];
}

+ (void)fbLogin:(id <SocialLoginDelegate>)delegate
{
    if (![Util checkInternetConnction])
	{
        NSLog(@"Not connected!");
		return;
	}
    
    NSString *token = [Util getValidFBToken];
    if (token)
	{
        [delegate socialLoginCompleted:YES credentials:@{@"token": token} loginType:kLoginFacebook];
	}
    else
	{
        if (fbAppKey)
        {
            
#if TARGET_OS_IPHONE
            int version = [[[UIDevice currentDevice] systemVersion] intValue];
            if (version >= 6) { // in ACAccountStore Facebook supported in iOS 6 and later
#endif
                [SocialLogin loginWithAccountStoreDelegate:delegate
                                                 loginType:kLoginFacebook];
#if TARGET_OS_IPHONE
			}
            else
			{
                NSString *redirect = [NSString stringWithFormat:@"fb%@://authorize",fbAppKey];
                NSString *appURL = [NSString stringWithFormat:@"fbauth://authorize?redirect_uri=%@&client_id=%@&response_type=token",redirect,fbAppKey];
                NSURL *url = [NSURL URLWithString:appURL];
                
                // if facebook app is installed try login through it
                if ([[UIApplication sharedApplication] canOpenURL:url] &&
                   [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:redirect]])
				{
                    if (fbDelegate)
                    {
                        [fbDelegate release];
                        fbDelegate = nil;
                    }
                    
                    fbDelegate = [delegate retain];
                    [[UIApplication sharedApplication] openURL:url];
                    
                    // stop facebook login if handleFBLogin not called after 120 seconds
                    [NSTimer scheduledTimerWithTimeInterval:120 target:[SocialLogin class]
                                                   selector:@selector(fbKill)
                                                   userInfo:nil repeats:NO];
                }
                else
				{
                    [SocialLogin makeSocalLoginController:kLoginFacebook delegate:delegate clientOnly:NO];
                }
            }
#endif
        }
        else
		{
            NSLog(@"FB app key not set! Call publishFBAppKey or add a string valued key with the appropriate id named FacebookAppID to the bundle *.plist to set it.");
		}
	}
}

+ (void)fbKill
{
    // stop facebook login if handleFBLogin not called
	if (fbDelegate)
    {
        NSLog(@"Call handleFBLogin in your app delegate in method handleOpenURL");
		
        [fbDelegate socialLoginCompleted:NO credentials:nil loginType:kLoginFacebook];
        [fbDelegate release];
        fbDelegate = nil;
    }
}

+ (BOOL)handleFBLogin:(NSURL *)uri
{
    if ([uri.scheme isEqualToString:[NSString stringWithFormat:@"fb%@", fbAppKey]])
	{
        NSDictionary *params = [Util getUrlParams:uri];
        
        NSString *error = params[@"error"];
        if (!error)
		{
            error = params[@"error_type"];
		}
        if (!error)
		{
            error = params[@"error_code"];
		}
        
        if (error)
        {
            if(([error compare:@"access_denied" options:NSCaseInsensitiveSearch] == NSOrderedSame) ||
               ([error compare:@"OAuthAccessDeniedException" options:NSCaseInsensitiveSearch] == NSOrderedSame))
            {
                if([fbDelegate respondsToSelector:@selector(socialLoginCancel)])
				{
                    [fbDelegate socialLoginCancel];
				}
            }
            else
			{
                [fbDelegate socialLoginCompleted:NO credentials:nil loginType:kLoginFacebook];
			}
			
            NSLog(@"%@", [params objectForKey:@"error_message"]);
        }
        else
        {
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setObject:params[@"access_token"] forKey:FB_TOKEN];
            int timestamp = [params[@"expires_in"] intValue];
            [defaults setObject:[NSNumber numberWithLong:[[NSDate date] timeIntervalSince1970] + timestamp]
                         forKey:FB_TOKEN_LIFETIME];
            [defaults synchronize];
            [fbDelegate socialLoginCompleted:YES credentials:[params objectForKey:@"access_token"] loginType:kLoginFacebook];
        }
        [fbDelegate release];
        fbDelegate = nil;
		
        return YES;
    }
	
    return NO;
}

+ (void)vkLogin:(id <SocialLoginDelegate>)delegate clientOnly:(BOOL)clientOnly
{
    if (!vkAppKey)
    {
        NSLog(@"VK app key not set! Call publishVKAppKey or add a string valued key with the appropriate id named VKAppKey to the bundle *.plist to set it.");
        return;
    }
    
    if (!vkRedirectUri)
    {
        NSLog(@"VK redirect uri not set! Call publishVKRedirectUri or add a string valued key with the appropriate uri named VKRedirectUri to the bundle *.plist to set it.");
        return;
    }
    
    if (![Util checkInternetConnction])
	{
        NSLog(@"Not connected!");
		return;
	}
    
    if (clientOnly)
    {
        NSDictionary *credentials = [Util getValidVKCred];
        if (credentials)
        {
            [delegate socialLoginCompleted:YES credentials:credentials loginType:kLoginVK];
            return;
        }
    }
    
   [SocialLogin makeSocalLoginController:kLoginVK delegate:delegate clientOnly:clientOnly];
}

+ (void)odkLogin:(id <SocialLoginDelegate>)delegate clientOnly:(BOOL)clientOnly
{
    if(!odkAppKey)
    {
        NSLog(@"ODK app key not set! Call publishODKAppKey or add a string valued key with the appropriate id named ODKAppKey to the bundle *.plist to set it.");
        return;
    }
    
    if (!odkRedirectUri)
    {
        NSLog(@"ODK redirect uri not set! Call publishODKRedirectUri or add a string valued key with the appropriate uri named ODKRedirectUri to the bundle *.plist to set it.");
        return;
    }
    
    if (clientOnly && !odkSecretKey)
    {
        NSLog(@"ODK secret key not set! Call publishODKSecretKey or add a string valued key with the appropriate id named ODKSecretKey to the bundle *.plist to set it.");
        return;
    }
    
    if (![Util checkInternetConnction])
	{
        NSLog(@"Not connected!");
		return;
	}
    
    if (clientOnly)
    {
        [Util getValidODKToken:odkAppKey secretKey:odkSecretKey completion:^(NSString* token){
            if(token)
			{
                [delegate socialLoginCompleted:YES credentials:@{@"token":token} loginType:kLoginODK];
			}
            else
			{
                [SocialLogin makeSocalLoginController:kLoginODK delegate:delegate clientOnly:clientOnly];
			}
        }];
		
        return;
    }
    
    [SocialLogin makeSocalLoginController:kLoginODK delegate:delegate clientOnly:clientOnly];
}

+ (void)twLogin:(id <SocialLoginDelegate>)delegate clientOnly:(BOOL)clientOnly
{
    if (!twAppKey)
    {
        NSLog(@"TW app key not set! Call publishTWAppKey or add a string valued key with the appropriate id named TWAppKey to the bundle *.plist to set it.");
        return;
    }
    
    if (!twSecretKey)
    {
        NSLog(@"TW secret key not set! Call publishTWAppKey or add a string valued key with the appropriate id named TWSecretAppKey to the bundle *.plist to set it.");
		return;
    }
    
    if (![Util checkInternetConnction])
	{
        NSLog(@"Not connected!");
		return;
	}
    
    if (clientOnly)
    {
        NSDictionary *credentials = [Util getTWCredentials];
        if (credentials)
        {
            NSDictionary *dic = @{@"token": credentials[@"oauth_token"],@"token_secret":credentials[@"oauth_token_secret"]};
            [delegate socialLoginCompleted:YES credentials:dic loginType:kLoginTwitter];
            
			return;
        }
        [SocialLogin loginWithAccountStoreDelegate:delegate
                                         loginType:kLoginTwitter];
    }
    else
        [SocialLogin makeSocalLoginController:kLoginTwitter delegate:delegate clientOnly:clientOnly];
}

+ (void)gppLogin:(id<SocialLoginDelegate>)delegate clientOnly:(BOOL)clientOnly
{
    if (!gppAppKey)
    {
        NSLog(@"GPP app key not set! Call publishGPPAppKey or add a string valued key with the appropriate id named GPPAppKey to the bundle *.plist to set it.");
        return;
    }
    
    if (clientOnly && !gppSecretKey)
    {
        NSLog(@"GPP secret key not set! Call publishGPPSecretKey or add a string valued key with the appropriate id named GPPSecretKey to the bundle *.plist to set it.");
        return;
    }
    
    if (![Util checkInternetConnction])
	{
        NSLog(@"Not connected!");
		return;
	}
    
    if (clientOnly)
    {
        [Util getValidGPPToken:gppAppKey secretKey:gppSecretKey completion:^(NSString* token){
            if(token)
			{
                [delegate socialLoginCompleted:YES credentials:@{@"token":token} loginType:kLoginGPP];
			}
            else
			{
                [SocialLogin makeSocalLoginController:kLoginGPP delegate:delegate clientOnly:clientOnly];
			}
        }];
		
        return;
    }
    
    [SocialLogin makeSocalLoginController:kLoginGPP delegate:delegate clientOnly:clientOnly];
}

+ (void)lnLogin:(id<SocialLoginDelegate>)delegate clientOnly:(BOOL)clientOnly
{
    
    if (!lnAppKey)
    {
        NSLog(@"LinkedIn app key not set! Call publishLNAppKey or add a string valued key with the appropriate id named LNAppKey to the bundle *.plist to set it.");
        return;
    }
    
    if (clientOnly && !lnSecretKey)
    {
        NSLog(@"LN secret key not set! Call publishLNSecretKey or add a string valued key with the appropriate id named LNSecretKey to the bundle *.plist to set it.");
        return;
    }
    
    if (![Util checkInternetConnction])
	{
        NSLog(@"Not connected!");
		return;
	}
    
    if (clientOnly)
    {
        NSString *token = [Util getValidLNToken];
        if (token)
        {
            [delegate socialLoginCompleted:YES credentials:@{@"token":token} loginType:kLoginLinkedIn];
			
            return;
        }
    }
    
    [SocialLogin makeSocalLoginController:kLoginLinkedIn delegate:delegate clientOnly:clientOnly];
}

+ (void)makeSocalLoginController:(socialLoginType)lType delegate:(id<SocialLoginDelegate>)delegate clientOnly:(BOOL)clientOnly
{
    NSString *appKey = nil;
    NSString *secretKey = nil;
    NSString *redirectURI = nil;
    
    switch (lType) {
        case kLoginFacebook: {
            appKey = fbAppKey;
            break;
		}
            
        case kLoginTwitter: {
            appKey = twAppKey;
            secretKey = twSecretKey;
            break;
		}
            
        case kLoginODK: {
            appKey = odkAppKey;
            secretKey = odkSecretKey;
            redirectURI = odkRedirectUri;
            break;
		}
            
        case kLoginVK: {
            appKey = vkAppKey;
            redirectURI = vkRedirectUri;
            break;
		}
            
        case kLoginGPP: {
            appKey = gppAppKey;
            secretKey = gppSecretKey;
            break;
		}
            
        case kLoginLinkedIn: {
            appKey = lnAppKey;
            secretKey = lnSecretKey;
            break;
		}
		
		default: // add your new service
			break;
    }
    
    SocialLoginController *loginController;
    if (lType == kLoginTwitter)
    {
        loginController = [[SocialLoginController alloc] initWithTWLogin:appKey
                                                               secretKey:secretKey];
    }
    else
    {
        loginController = [[SocialLoginController alloc] initWithLogin:lType
                                                                appKey:appKey];
        loginController.secretKey = secretKey;
        
        if (redirectURI)
		{
            loginController.redirectUri = redirectURI;
		}
    }

    loginController.delegate = delegate;
    loginController.isClientOnly = clientOnly;
#if TARGET_OS_IPHONE
    [loginController showModal];
#else
    [loginController window];
#endif
    [loginController release];
}

+ (void)resetAuthorization
{
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSArray *cookies = [cookieStorage cookies];
    
    for (NSHTTPCookie *cookie in cookies) {
        if([cookie.domain hasSuffix:@"odnoklassniki.ru"] ||
           [cookie.domain hasSuffix:@"twitter.com"] ||
           [cookie.domain hasSuffix:@"linkedin.com"] ||
           [cookie.domain hasSuffix:@"facebook.com"] ||
           [cookie.domain hasSuffix:@"accounts.google.com"] ||
           [cookie.domain hasSuffix:@"oauth.vk.com"])
            [cookieStorage deleteCookie:cookie];
    }
    
    [Util resetTWAuthorization];
    [Util resetVKAuthorization];
    [Util resetODKAuthorization];
    [Util resetFBAuthorization];
    [Util resetGPPAuthorization];
    [Util resetLNAuthorization];
}

@end