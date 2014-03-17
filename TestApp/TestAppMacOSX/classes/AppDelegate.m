/*
 *  AppDelegate.m
 *  Application delegate class
 *  TestAppMacOSX
 *
 *  Facebook, Google+, LinkedIn, Twitter, VK, OK login library test application for Mac OS X
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

#import "AppDelegate.h"
#import <SocialLoginMacOSX/OAuth.h>
#import <CommonCrypto/CommonDigest.h>
#import "ProfileScreen.h"

#define IS_CLIENT_ONLY YES

@implementation AppDelegate

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    return YES;
}

- (IBAction)bnFBClick:(id)sender
{
    [SocialLogin fbLogin:self];
}

- (IBAction)bnTWClick:(id)sender
{
    [SocialLogin twLogin:self clientOnly:IS_CLIENT_ONLY];
}

- (IBAction)bnGPPClick:(id)sender
{
    [SocialLogin gppLogin:self clientOnly:IS_CLIENT_ONLY];
}

- (IBAction)bnLNClick:(id)sender
{
    [SocialLogin lnLogin:self clientOnly:IS_CLIENT_ONLY];
}

- (IBAction)bnVKClick:(id)sender
{
    [SocialLogin vkLogin:self clientOnly:IS_CLIENT_ONLY];
}

- (IBAction)bnODKClick:(id)sender
{
    [SocialLogin odkLogin:self clientOnly:IS_CLIENT_ONLY];
}

- (IBAction)bnPostClick:(id)sender
{
    [SocialLogin postOnFacebook:@"test name"
                        address:@"test addres"
                           site:@"http://test.com"
                         picURL:@"http://test.com/test.jpg"
                        message:@"test message"];
}

- (IBAction)bnResetClick:(id)sender
{
    [SocialLogin resetAuthorization];
    NSAlert *alert = [NSAlert alertWithMessageText:@"Authorization successfully reseted"
                                     defaultButton:@"OK"
                                   alternateButton:nil
                                       otherButton:nil
                         informativeTextWithFormat:@""];
    [alert runModal];
}

- (NSString *)MD5:(NSString *)params
{
    const char *ptr = [params UTF8String];
    unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];
    CC_MD5(ptr, (CC_LONG)strlen(ptr), md5Buffer);
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [output appendFormat:@"%02x",md5Buffer[i]];
	}
    
	return output;
}

- (NSString *)sig:(NSString *)token
{
    NSString *params = @"application_key=CBAEDHPMABABABABAformat=jsonmethod=users.getCurrentUser";
    NSString *sec = [NSString stringWithFormat:@"%@B10AC1CCBA826E92E0A31058",token];
    
	return [self MD5:[params stringByAppendingString:[self MD5:sec]]];
}

#pragma mark SocialLogin delegate

- (void)socialLoginCompleted:(BOOL)successful credentials:(NSDictionary *)credentials loginType:(socialLoginType)loginType
{
    if (successful) {
        if (IS_CLIENT_ONLY) {
            NSString *link;
            NSMutableURLRequest *request;
            
            switch (loginType) {
                    
                case kLoginTwitter: {
                    OAuth *oauth = [[OAuth alloc] initWithConsumerKey:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"TWAppKey"]
                                                    andConsumerSecret:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"TWSecretAppKey"]];
                    NSDictionary *params = @{@"oauth_token":credentials[@"token"]};
                    link = @"https://api.twitter.com/1.1/account/settings.json";
                    
                    NSString *oauth_header = [oauth oAuthHeaderForMethod:@"GET"
                                                                  andUrl:link
                                                               andParams:params
                                                          andTokenSecret:credentials[@"token_secret"]];
                    
                    request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:link]];
                    [request addValue:oauth_header forHTTPHeaderField:@"Authorization"];
                    break;
                }
                    
                case kLoginFacebook: {
                    link = [NSString stringWithFormat:@"https://graph.facebook.com/me?access_token=%@",
                            credentials[@"token"]];
                    request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:link]];
                    break;
				}
                    
                case kLoginODK: {
                    link = [NSString stringWithFormat:@"http://api.odnoklassniki.ru/fb.do?"
                            @"access_token=%@"
                            @"&sig=%@"
                            @"&application_key=CBAEDHPMABABABABA"
                            @"&method=users.getCurrentUser&format=json",
                            credentials[@"token"],[self sig:credentials[@"token"]]];
                    request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:link]];
                    break;
				}
                    
                case kLoginVK: {
                    link = [NSString stringWithFormat:@"https://api.vk.com/method/getProfiles?uid=%@&access_token=%@",
                            credentials[@"user_id"],credentials[@"token"]];
                    request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:link]];
                    break;
                }
                    
                case kLoginGPP: {
                    link = [NSString stringWithFormat:@"https://www.googleapis.com/plus/v1/people/me?access_token=%@",
                            credentials[@"token"]];
                    request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:link]];
                    break;
				}
                    
                case kLoginLinkedIn: {
                    link = [NSString stringWithFormat:@"https://api.linkedin.com/v1/people/~?oauth2_access_token=%@",
                            credentials[@"token"]];
                    request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:link]];
                    [request addValue:@"json" forHTTPHeaderField:@"x-li-format"];
                    break;
				}
            }
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSError *error = nil;
                NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:&error];
                if (!error) {
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        NSLog(@"Successful credentials: %@",credentials);
                        NSString *responseStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                        ProfileScreen *scr = [[ProfileScreen alloc] initWithText:responseStr];
                        [scr window];
                    });
                }
            });
        }
        else {
            NSLog(@"Successful credentials: %@",credentials);
            NSAlert *alert = [NSAlert alertWithMessageText:[NSString stringWithFormat:@"Successful credentials: %@",credentials]
                                             defaultButton:@"OK"
                                           alternateButton:nil
                                               otherButton:nil
                                 informativeTextWithFormat:@""];
            [alert runModal];
        }
    }
    else {
        NSLog(@"Login error");
        NSAlert *alert = [NSAlert alertWithMessageText:@"Login error"
                                         defaultButton:@"OK"
                                       alternateButton:nil
                                           otherButton:nil
                             informativeTextWithFormat:@""];
        [alert runModal];
    }
}

@end