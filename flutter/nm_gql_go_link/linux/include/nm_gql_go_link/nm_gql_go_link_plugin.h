#ifndef FLUTTER_PLUGIN_NM_GQL_GO_LINK_PLUGIN_H_
#define FLUTTER_PLUGIN_NM_GQL_GO_LINK_PLUGIN_H_

#include <flutter_linux/flutter_linux.h>

G_BEGIN_DECLS

#ifdef FLUTTER_PLUGIN_IMPL
#define FLUTTER_PLUGIN_EXPORT __attribute__((visibility("default")))
#else
#define FLUTTER_PLUGIN_EXPORT
#endif

typedef struct _NmGqlGoLinkPlugin NmGqlGoLinkPlugin;
typedef struct {
  GObjectClass parent_class;
} NmGqlGoLinkPluginClass;

FLUTTER_PLUGIN_EXPORT GType nm_gql_go_link_plugin_get_type();

FLUTTER_PLUGIN_EXPORT void nm_gql_go_link_plugin_register_with_registrar(
    FlPluginRegistrar* registrar);

G_END_DECLS

#endif  // FLUTTER_PLUGIN_NM_GQL_GO_LINK_PLUGIN_H_
