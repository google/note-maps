#import "NmGqlGoLinkPlugin.h"
#if __has_include(<nm_gql_go_link/nm_gql_go_link-Swift.h>)
#import <nm_gql_go_link/nm_gql_go_link-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "nm_gql_go_link-Swift.h"
#endif

@implementation NmGqlGoLinkPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftNmGqlGoLinkPlugin registerWithRegistrar:registrar];
}
@end
