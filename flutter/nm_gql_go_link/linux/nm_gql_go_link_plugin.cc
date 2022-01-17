// Copyright 2020-2021 Google LLC
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

#include "include/nm_gql_go_link/nm_gql_go_link_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>
#include <sys/utsname.h>

#define NM_GQL_GO_LINK_PLUGIN(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), nm_gql_go_link_plugin_get_type(), \
                              NmGqlGoLinkPlugin))

struct _NmGqlGoLinkPlugin {
  GObject parent_instance;
};

G_DEFINE_TYPE(NmGqlGoLinkPlugin, nm_gql_go_link_plugin, g_object_get_type())

// Called when a method call is received from Flutter.
static void nm_gql_go_link_plugin_handle_method_call(
    NmGqlGoLinkPlugin* self,
    FlMethodCall* method_call) {
  g_autoptr(FlMethodResponse) response = nullptr;

  const gchar* method = fl_method_call_get_name(method_call);

  if (strcmp(method, "getPlatformVersion") == 0) {
    struct utsname uname_data = {};
    uname(&uname_data);
    g_autofree gchar *version = g_strdup_printf("Linux %s", uname_data.version);
    g_autoptr(FlValue) result = fl_value_new_string(version);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  fl_method_call_respond(method_call, response, nullptr);
}

static void nm_gql_go_link_plugin_dispose(GObject* object) {
  G_OBJECT_CLASS(nm_gql_go_link_plugin_parent_class)->dispose(object);
}

static void nm_gql_go_link_plugin_class_init(NmGqlGoLinkPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = nm_gql_go_link_plugin_dispose;
}

static void nm_gql_go_link_plugin_init(NmGqlGoLinkPlugin* self) {}

static void method_call_cb(FlMethodChannel* channel, FlMethodCall* method_call,
                           gpointer user_data) {
  NmGqlGoLinkPlugin* plugin = NM_GQL_GO_LINK_PLUGIN(user_data);
  nm_gql_go_link_plugin_handle_method_call(plugin, method_call);
}

void nm_gql_go_link_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  NmGqlGoLinkPlugin* plugin = NM_GQL_GO_LINK_PLUGIN(
      g_object_new(nm_gql_go_link_plugin_get_type(), nullptr));

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) channel =
      fl_method_channel_new(fl_plugin_registrar_get_messenger(registrar),
                            "nm_gql_go_link",
                            FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(channel, method_call_cb,
                                            g_object_ref(plugin),
                                            g_object_unref);

  g_object_unref(plugin);
}
