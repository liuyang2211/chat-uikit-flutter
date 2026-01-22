import 'package:tencent_cloud_chat_sdk/models/v2_tim_callback.dart'
    if (dart.library.html) 'package:tencent_cloud_chat_sdk/web/compatible_models/v2_tim_callback.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/view_models/wk_conversation_view_model.dart';
import 'package:wukongimfluttersdk/entity/conversation.dart';

class WKUIKitConversationController {
  late WKConversationViewModel model;

  /// Get the selected conversation currently
  WKUIConversationMsg? get selectedConversation {
    return model.selectedConversation;
  }

  /// Set the selected conversation currently
  set selectedConversation(WKUIConversationMsg? conversation) {
    model.selectedConversation = conversation;
  }

  /// Get the conversation list
  List<WKUIConversationMsg?> get conversationList {
    return model.conversationList;
  }

  /// Set the conversation list
  set conversationList(List<WKUIConversationMsg?> conversationList) {
    model.conversationList = conversationList;
  }

  /// Load the conversation list to UI
  loadData({int count = 40}) {
    model.wkLoadData(count: count);
  }

  /// Reload the conversation list to UI
  reloadData({int count = 100}) {
    model.wkRefresh(count: count);
  }

  /// Pin one conversation to the top
  Future<V2TimCallback> pinWKConversation(
      {required String conversationID, required bool isPinned}) {
    return model.pinWKConversation(
        conversationID: conversationID, isPinned: isPinned);
  }

  /// Set the draft for a conversation
  Future<V2TimCallback> setWKConversationDraft(
      {required String conversationID, String? draftText}) {
    return model.setWKConversationDraft(
        conversationID: conversationID, draftText: draftText);
  }

  /// Clear the historical message in a specific conversation
  Future<V2TimCallback?>? clearWKHistoryMessage(
      {required WKUIConversationMsg conversation}) {
    return model.clearWKHistoryMessage(
        channelID: conversation.channelID,
        channelType: conversation.channelType);
  }

  /// Delete a conversation
  Future<bool?> deleteWKConversation(
      {required String channelID, required int channelType}) {
    return model.deleteWKConversation(
        channelID: channelID, channelType: channelType);
  }

  /// Clear the conversation list from UI
  dispose() {
    model.wkClearData();
  }

  /// Scroll to a specific conversation, this conversation must be existed in conversation list.
  /// If not exist, invoking `loadData` recursively, until find the target conversation.
  scrollToConversation(String conversationID) {
    model.scrollToConversation = conversationID;
  }
}
