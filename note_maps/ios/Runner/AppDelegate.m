// Copyright 2019 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#include "AppDelegate.h"
#include "GeneratedPluginRegistrant.h"
#include "Mobileapi/Mobileapi.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Set the storage location for the Note Maps database under a directory
    // that is automatically backed up.
    NSArray *pathComponents = [NSArray arrayWithObjects:NSHomeDirectory(), @"Documents", @"db", nil];
    MobileapiSetPath([NSString pathWithComponents:pathComponents]);

    FlutterViewController* controller = (FlutterViewController*)self.window.rootViewController;

    FlutterMethodChannel* queryChannel = [FlutterMethodChannel
                                          methodChannelWithName:@"github.com/google/note-maps/query"
                                          binaryMessenger:controller];
    [queryChannel setMethodCallHandler:^(FlutterMethodCall* call, FlutterResult result) {
        // Note: this method is invoked on the UI thread.
        FlutterStandardTypedData* request = call.arguments[@"request"];
        NSError* error = NULL;
        NSData* response = MobileapiQuery(call.method, request.data, &error);
        if (error != NULL) {
            result([FlutterError errorWithCode:@"ERROR"
                                       message:@"Query channel error"
                                       details:nil]);
        } else {
            result(response);
        }
    }];

    FlutterMethodChannel* commandChannel = [FlutterMethodChannel
                                            methodChannelWithName:@"github.com/google/note-maps/command"
                                            binaryMessenger:controller];
    [commandChannel setMethodCallHandler:^(FlutterMethodCall* call, FlutterResult result) {
        // Note: this method is invoked on the UI thread.
        FlutterStandardTypedData* request = call.arguments[@"request"];
        NSError* error = NULL;
        NSData* response = MobileapiCommand(call.method, request.data, &error);
        if (error != NULL) {
            result([FlutterError errorWithCode:@"ERROR"
                                       message:@"Command channel error"
                                       details:nil]);
        } else {
            result(response);
        }
    }];

    [GeneratedPluginRegistrant registerWithRegistry:self];
    return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

- (void)applicationDidEnterBackground:(UIApplication *)application{
    MobileapiClose();
    [super applicationDidEnterBackground:application];
}

@end
