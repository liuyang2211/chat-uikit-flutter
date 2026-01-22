import 'package:tencent_cloud_chat_sdk/enum/V2TimConversationListener.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_callback.dart'
    if (dart.library.html) 'package:tencent_cloud_chat_sdk/web/compatible_models/v2_tim_callback.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_conversation.dart'
    if (dart.library.html) 'package:tencent_cloud_chat_sdk/web/compatible_models/v2_tim_conversation.dart';

import 'package:tencent_cloud_chat_uikit/data_services/conversation/wk_conversation_result.dart';

abstract class WKConversationService {
  Future<WKConversationResult> getWKConversationList({
    required String nextSeq,
    required int count,
  });

  Future<V2TimConversation?> getWKConversation({
    required String conversationID,
  });

  Future<V2TimCallback> pinWKConversation({
    required String conversationID,
    required bool isPinned,
  });

  Future<bool> deleteWKConversation(
      {required String channelID, required int channelType});

  Future<void> addWKConversationListener({
    required V2TimConversationListener listener,
  });

  Future<V2TimCallback> setWKConversationDraft(
      {required String conversationID, String? draftText});

  Future<void> removeWKConversationListener(
      {V2TimConversationListener? listener});

  Future<int> getWKTotalUnreadCount();

  Future<V2TimConversation?> getWKConversationListByConversationId(
      {required String convID});
}
