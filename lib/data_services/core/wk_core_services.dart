import 'package:flutter/cupertino.dart';
import 'package:tencent_cloud_chat_sdk/enum/V2TimSDKListener.dart';
import 'package:tencent_cloud_chat_sdk/enum/log_level_enum.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_callback.dart'
    if (dart.library.html) 'package:tencent_cloud_chat_sdk/web/compatible_models/v2_tim_callback.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_user_full_info.dart'
    if (dart.library.html) 'package:tencent_cloud_chat_sdk/web/compatible_models/v2_tim_user_full_info.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_value_callback.dart'
    if (dart.library.html) 'package:tencent_cloud_chat_sdk/web/compatible_models/v2_tim_value_callback.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_callback.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/screen_utils.dart';
import 'package:tencent_cloud_chat_uikit/data_services/core/tim_uikit_config.dart';
import 'package:tencent_cloud_chat_uikit/theme/tui_theme.dart';

enum WKAppStatus { foreground, background }

enum WKLanguageEnum {
  /// Chinese, Traditional
  zhHant,

  /// Chinese, Simplified
  zhHans,

  /// English
  en,

  /// Korean
  ko,

  /// Japanese
  ja,
}

const wkLanguageEnumToString = {
  WKLanguageEnum.zhHant: "zh-Hant",
  WKLanguageEnum.zhHans: "zh-Hans",
  WKLanguageEnum.en: "en",
  WKLanguageEnum.ja: "ja",
  WKLanguageEnum.ko: "ko",
};

abstract class WKCoreServices {
  Future<bool?> init({
    required V2TimSDKListener listener,

    /// Callback from TUIKit invoke, includes IM SDK API error, notify information, Flutter error.
    ValueChanged<TIMCallback>? onTUIKitCallbackListener,
    TIMUIKitConfig? config,

    /// only support "en" and "zh" temporally
    WKLanguageEnum? language,
  });

  Future<void> setWKDataFromNative({
    required String userId,

    /// Callback from TUIKit invoke, includes IM SDK API error, notify information, Flutter error.
    ValueChanged<TIMCallback>? onTUIKitCallbackListener,
    TIMUIKitConfig? config,

    /// only support "en" and "zh" temporally
    WKLanguageEnum? language,
  });

  // 悟空 IM SDK 登录
  Future wkLogin({
    required String uid,
    required String token,
  });

  // 悟空 IM SDK 登出
  Future wkLogout();

  Future wkLogoutWithoutClearData();

  Future wkUnInit();

  Future<V2TimValueCallback<List<V2TimUserFullInfo>>> getWKUsersInfo({
    required List<String> userIDList,
  });

  // 注意：uikit的离线推送不支持TPNS
  // Note: uikit's offline push do not supports TPNS
  Future<V2TimCallback> setWKOfflinePushConfig({
    bool isTPNSToken = false,
    int businessID,
    required String token,
  });

  Future<V2TimCallback> setWKSelfInfo({
    required V2TimUserFullInfo userFullInfo,
  });

  Future<V2TimCallback> setWKOfflinePushStatus({
    required WKAppStatus status,
    int? totalCount,
  });

  setWKTheme({required TUITheme theme});

  setWKDarkTheme();

  setWKLightTheme();

  setWKDeviceType(DeviceType deviceType);
}
