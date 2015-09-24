//
//  GDVExternalScreen.m
//  MultiScreenPlugin
//
//  Created by wenfeng on 2015/9/24.
//
//
// THIS SOFTWARE IS PROVIDED BY THE ANDREW TRICE "AS IS" AND ANY EXPRESS OR
// IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
// MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
// EVENT SHALL ANDREW TRICE OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
// INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
// BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
// LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
// OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
// ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

#import "CDVExternalScreen.h"


@implementation CDVExternalScreen

@synthesize callbackID;

NSString* WEBVIEW_UNAVAILABLE = @"External Web View Unavailable";
NSString* WEBVIEW_OK = @"OK";
NSString* SCREEN_NOTIFICATION_HANDLERS_OK =@"External screen notification handlers initialized";

//used to load an HTML file in external screen web view
- (void) loadHTMLResource:(CDVInvokedUrlCommand*)command
{
    self.callbackID = command.callbackId;
    NSArray *arguments = command.arguments;
    CDVPluginResult* pluginResult;
    
    if (webView)
    {
        NSString *stringObtainedFromJavascript = [arguments objectAtIndex:0];
        
        NSRange textRange;
        textRange =[[stringObtainedFromJavascript lowercaseString] rangeOfString:@"http://"];
        NSError *error = nil;
        NSURL *url;
        
        //found "http://", so load remote resource
        if(textRange.location != NSNotFound)
        {
            url = [NSURL URLWithString:stringObtainedFromJavascript];
        }
        //load local resource
        else
        {
            
            NSString* path = [NSString stringWithFormat:@"%@/%@", baseURLAddress, stringObtainedFromJavascript];
            url = [NSURL fileURLWithPath:path isDirectory:NO];
        }
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        [webView loadRequest:request];
        
        if(error) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: [error localizedDescription]];

            [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackID];
        }
        else
        {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString: WEBVIEW_OK];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackID];
        }
    }
    else
    {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: WEBVIEW_UNAVAILABLE];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackID];
    }
}

//used to load an HTML string in external screen web view
- (void) loadHTML:(CDVInvokedUrlCommand*)command
{
    
    self.callbackID = command.callbackId;
    NSArray *arguments = command.arguments;
    CDVPluginResult* pluginResult;
    
    if (webView)
    {
        NSString *stringObtainedFromJavascript = [arguments objectAtIndex:0];
        [webView loadHTMLString:stringObtainedFromJavascript baseURL:baseURL];
        
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString: WEBVIEW_OK];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackID];
    }
    else
    {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: WEBVIEW_UNAVAILABLE];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackID];
    }
    
}


//used to invoke javascript in external screen web view
- (void) invokeJavaScript:(CDVInvokedUrlCommand*)command
{
    self.callbackID = command.callbackId;
    NSArray *arguments = command.arguments;
    CDVPluginResult* pluginResult;
    
    if (webView)
    {
        NSString *stringObtainedFromJavascript = [arguments objectAtIndex:0];
        [webView stringByEvaluatingJavaScriptFromString: stringObtainedFromJavascript];
        
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString: WEBVIEW_OK];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackID];
    }
    else
    {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: WEBVIEW_UNAVAILABLE];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackID];
    }
    
}

//used to initialize monitoring of external screen
- (void) setupScreenConnectionNotificationHandlers:(CDVInvokedUrlCommand*)command
{
    self.callbackID = command.callbackId;
    
    NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
    
    [center addObserver:self selector:@selector(handleScreenConnectNotification:)
                   name:UIScreenDidConnectNotification object:nil];
    [center addObserver:self selector:@selector(handleScreenDisconnectNotification:)
                   name:UIScreenDidDisconnectNotification object:nil];
    
    [self attemptSecondScreenView];
    
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString: SCREEN_NOTIFICATION_HANDLERS_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackID];
}

//used to determine if an external screen is available
- (void) checkExternalScreenAvailable:(CDVInvokedUrlCommand*)command
{
    self.callbackID = command.callbackId;
    
    NSString* result = nil;
    if ([[UIScreen screens] count] > 1) {  
        result = @"YES";
    }
    else
    {
        result = @"NO";
    }

    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString: result];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackID];
}



//invoked when an additional screen is connected to iOS device (VGA or Airplay)
- (void)handleScreenConnectNotification:(NSNotification*)aNotification
{
    if (!externalWindow)
    {
        [self attemptSecondScreenView];
    }
}

//invoked when an additional screen is disconnected 
- (void)handleScreenDisconnectNotification:(NSNotification*)aNotification
{
    if (externalWindow)
    {
        externalWindow.hidden = YES;
        externalWindow = nil;
    }
    
    if (webView)
    {
        webView = nil;
    }
    
}


- (void) attemptSecondScreenView
{
    if ([[UIScreen screens] count] > 1) {
        
		// Internal display is 0, external is 1.
		externalScreen = [[UIScreen screens] objectAtIndex:1];
        
        CGRect screenBounds = externalScreen.bounds;
        
        externalWindow = [[UIWindow alloc] initWithFrame:screenBounds];
        externalWindow.screen = externalScreen;
        
        externalWindow.frame = screenBounds;
        externalWindow.clipsToBounds = YES;
        
        webView = [[UIWebView alloc] initWithFrame:screenBounds];
        
        baseURLAddress = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"www"];
        
        baseURL = [NSURL URLWithString:baseURLAddress];
        
        [webView loadHTMLString:@"loading..." baseURL:baseURL];
        
        [externalWindow addSubview:webView];
        [externalWindow makeKeyAndVisible];
        externalWindow.hidden = NO;
    }
    else
    {
        externalWindow.hidden = YES;
    }
}


@end
