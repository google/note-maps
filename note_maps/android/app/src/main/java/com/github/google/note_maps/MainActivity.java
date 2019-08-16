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

package com.github.google.note_maps;

import android.os.Bundle;

import io.flutter.app.FlutterActivity;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugins.GeneratedPluginRegistrant;

import java.io.File;

public class MainActivity extends FlutterActivity {
  private static final String QUERY_CHANNEL = "github.com/google/note-maps/query";
  private static final String COMMAND_CHANNEL = "github.com/google/note-maps/command";

  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    GeneratedPluginRegistrant.registerWith(this);
    File dir = new File(MainActivity.this.getFilesDir(), "db");
    if (dir.exists()) {
      if (!dir.isDirectory()) {
        // if dir.delete() fails, let the app entirely fail to start.
        dir.delete();
      }
    }
    if (!dir.exists()) {
      dir.mkdirs();
    }
    mobileapi.Mobileapi.setPath(dir.getAbsolutePath());
    new MethodChannel(getFlutterView(), QUERY_CHANNEL).setMethodCallHandler(
        new MethodChannel.MethodCallHandler() {
          @Override
          public void onMethodCall(MethodCall call, MethodChannel.Result result) {
            try {
              byte[] bytes = mobileapi.Mobileapi.query(call.method, call.argument("request"));
              if (bytes == null) {
                bytes = new byte[]{};
              }
              result.success(bytes);
            } catch (Exception e) {
              result.error(e.getMessage(), e.getLocalizedMessage(), null);
            }
          }
        }
    );
    new MethodChannel(getFlutterView(), COMMAND_CHANNEL).setMethodCallHandler(
        new MethodChannel.MethodCallHandler() {
          @Override
          public void onMethodCall(MethodCall call, MethodChannel.Result result) {
            try {
              result.success(mobileapi.Mobileapi.command(call.method, call.argument("request")));
            } catch (Exception e) {
              result.error(e.getMessage(), e.getLocalizedMessage(), null);
            }
          }
        }
    );
  }

  @Override
  protected void onPause() {
    mobileapi.Mobileapi.close();
    super.onPause();
  }
}
