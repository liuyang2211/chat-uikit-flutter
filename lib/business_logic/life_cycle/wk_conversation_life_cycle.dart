import 'package:tencent_cloud_chat_uikit/business_logic/life_cycle/wk_base_life_cycle.dart';

/// 会话生命周期管理类
class WKConversationLifeCycle {
  /// Before deleting a conversation, or a channel, from the conversation list,
  /// `true` means can delete continually, while `false` will not delete.
  /// You can make a second confirmation here by a modal, etc.
  /// 在从会话列表中删除会话或频道之前，
  /// `true` 表示可以继续删除，而 `false` 将不会删除。
  /// 您可以通过模态框等方式在这里进行二次确认。
  WKFutureBool Function(String conversationID) shouldDeleteConversation;

  /// Before clearing the historical message for a specific conversation, provided in parameter,
  /// `true` means can clear continually, while `false` will not clear.
  /// You can make a second confirmation here by a modal, etc.
  /// 在清除特定会话的历史消息之前，提供参数，
  /// `true` 表示可以继续清除，而 `false` 将不会清除。
  /// 您可以通过模态框等方式在这里进行二次确认。
  WKFutureBool Function(String conversationID)
      shouldClearHistoricalMessageForConversation;

  /// Before conversation list will mount or update to conversation page.
  /// 在会话列表将要挂载或更新到会话页面之前。
  WKConversationListFunction conversationListWillMount;

  WKConversationLifeCycle({
    this.conversationListWillMount =
        WKDefaultLifeCycle.defaultConversationListSolution,
    this.shouldClearHistoricalMessageForConversation =
        WKDefaultLifeCycle.defaultAsyncBooleanSolution,
    this.shouldDeleteConversation =
        WKDefaultLifeCycle.defaultAsyncBooleanSolution,
  });
}
