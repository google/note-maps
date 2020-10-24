//
//  Generated file. Do not edit.
//

#include "generated_plugin_registrant.h"

#include <nm_gql_go_link/nm_gql_go_link_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) nm_gql_go_link_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "NmGqlGoLinkPlugin");
  nm_gql_go_link_plugin_register_with_registrar(nm_gql_go_link_registrar);
}
