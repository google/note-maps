// Copyright 2020 Google LLC
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

#import "NmGqlGoLinkPlugin.h"

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

#import "../Frameworks/GoNmgql.framework/Headers/GoNmgql.h"

@implementation NmGqlGoLinkPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
            methodChannelWithName:@"nm_gql_go_link"
                  binaryMessenger:[registrar messenger]];
    NmGqlGoLinkPlugin* instance = [[NmGqlGoLinkPlugin alloc] init];
    [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([@"getPlatformVersion" isEqualToString:call.method]) {
        result([[NSProcessInfo processInfo] operatingSystemVersionString]);
    } else if ([@"getGoVersion" isEqualToString:call.method]) {
        NSString* response = GoNmgqlGetGoVersion();
        result(response);
    } else if ([@"gqlRequest" isEqualToString:call.method]) {
        FlutterStandardTypedData* request = call.arguments[@"request"];
        NSError* error = NULL;
        NSData* response = GoNmgqlRequest(request.data, &error);
        if (error != NULL) {
            result([FlutterError errorWithCode:@"UNAVAILABLE"
                                 message:[error localizedDescription]
                                 details:nil]);
        } else {
            result(response);
        }
    } else {
        result(FlutterMethodNotImplemented);
    }
}

@end
