import 'package:tencent_cloud_chat_sdk/enum/V2TimConversationListener.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_callback.dart'
    if (dart.library.html) 'package:tencent_cloud_chat_sdk/web/compatible_models/v2_tim_callback.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_conversation.dart'
    if (dart.library.html) 'package:tencent_cloud_chat_sdk/web/compatible_models/v2_tim_conversation.dart';
import 'package:tencent_cloud_chat_sdk/tencent_im_sdk_plugin.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_callback.dart';
import 'package:tencent_cloud_chat_uikit/data_services/conversation/wk_conversation_result.dart';
import 'package:tencent_cloud_chat_uikit/data_services/conversation/wk_conversation_services.dart';
import 'package:tencent_cloud_chat_uikit/data_services/core/core_services_implements.dart';
import 'package:tencent_cloud_chat_uikit/data_services/services_locatar.dart';

/// 会话服务实现类
/// 实现了 ConversationService 接口，提供会话相关的各种操作
class WKConversationServicesImpl extends WKConversationService {
  /// 核心服务实现，用于处理回调通知
  final CoreServicesImpl _coreService = serviceLocator<CoreServicesImpl>();

  /// 获取悟空会话列表
  ///
  /// @param nextSeq 下一个序列号
  /// @param count 获取数量
  /// @return 会话结果对象，如果失败返回null
  @override
  Future<WKConversationResult> getWKConversationList(
      {required String nextSeq, required int count}) async {
    final wkUIConversationMsgs =
        await TencentImSDKPlugin.wukongIMManager.conversationManager.getAll();
    print('悟空：getWKConversationList:$wkUIConversationMsgs');
    final result = WKConversationResult(
        isFinished: true, conversationList: wkUIConversationMsgs);
    return result;
  }

  /// 设置会话置顶状态
  ///
  /// @param conversationID 会话ID
  /// @param isPinned 是否置顶
  /// @return 操作结果回调
  @override
  Future<V2TimCallback> pinWKConversation({
    required String conversationID,
    required bool isPinned,
  }) async {
    print('悟空：我还没有实现');
    final result = await TencentImSDKPlugin.v2TIMManager
        .getConversationManager()
        .pinConversation(conversationID: conversationID, isPinned: isPinned);
    if (result.code != 0) {
      _coreService.callOnCallback(TIMCallback(
          type: TIMCallbackType.API_ERROR,
          errorMsg: result.desc,
          errorCode: result.code));
    }
    return result;
  }

  /// 删除会话
  ///
  /// @param conversationID 会话ID
  /// @return 操作结果回调
  @override
  Future<bool> deleteWKConversation(
      {required String channelID, required int channelType}) async {
    final result = await TencentImSDKPlugin.wukongIMManager.conversationManager
        .deleteMsg(channelID, channelType);
    if (result == false) {
      _coreService.callOnCallback(TIMCallback(
          type: TIMCallbackType.API_ERROR,
          errorMsg: '悟空：删除会话失败',
          errorCode: 910001));
    }
    return result;
  }

  /// 添加会话监听器
  ///
  /// @param listener 会话监听器
  /// @return 异步操作
  @override
  Future<void> addWKConversationListener({
    required V2TimConversationListener listener,
  }) {
    print('悟空：我还没有实现');
    return TencentImSDKPlugin.v2TIMManager
        .getConversationManager()
        .addConversationListener(listener: listener);
  }

  /// 获取指定会话
  ///
  /// @param conversationID 会话ID
  /// @return 会话对象，如果失败返回null
  @override
  Future<V2TimConversation?> getWKConversation({
    required String conversationID,
  }) async {
    print('悟空：我还没有实现');
    final res = await TencentImSDKPlugin.v2TIMManager
        .getConversationManager()
        .getConversation(conversationID: conversationID);
    if (res.code == 0) {
      return res.data;
    } else {
      _coreService.callOnCallback(TIMCallback(
          type: TIMCallbackType.API_ERROR,
          errorMsg: res.desc,
          errorCode: res.code));
    }
    return null;
  }

  /// 设置会话草稿
  ///
  /// @param conversationID 会话ID
  /// @param draftText 草稿文本
  /// @return 操作结果回调
  @override
  Future<V2TimCallback> setWKConversationDraft(
      {required String conversationID, String? draftText}) async {
    final result = await TencentImSDKPlugin.v2TIMManager
        .getConversationManager()
        .setConversationDraft(
            conversationID: conversationID, draftText: draftText);
    if (result.code != 0) {
      _coreService.callOnCallback(TIMCallback(
          type: TIMCallbackType.API_ERROR,
          errorMsg: result.desc,
          errorCode: result.code));
    }
    return result;
  }

  /// 移除会话监听器
  ///
  /// @param listener 会话监听器
  /// @return 异步操作
  @override
  Future<void> removeWKConversationListener(
      {V2TimConversationListener? listener}) {
    return TencentImSDKPlugin.v2TIMManager
        .getConversationManager()
        .removeConversationListener(listener: listener);
  }

  /// 根据会话ID获取会话列表
  ///
  /// @param convID 会话ID
  /// @return 会话对象，如果失败返回null
  @override
  Future<V2TimConversation?> getWKConversationListByConversationId(
      {required String convID}) async {
    final result = await TencentImSDKPlugin.v2TIMManager
        .getConversationManager()
        .getConversationListByConversationIds(conversationIDList: [convID]);
    if (result.code != 0) {
      _coreService.callOnCallback(TIMCallback(
          type: TIMCallbackType.API_ERROR,
          errorMsg: result.desc,
          errorCode: result.code));
    }
    return (result.data != null && result.data!.isNotEmpty)
        ? result.data![0]
        : null;
  }

  /// 获取总未读消息数
  ///
  /// @return 总未读消息数
  @override
  Future<int> getWKTotalUnreadCount() async {
    final res = await TencentImSDKPlugin.v2TIMManager
        .getConversationManager()
        .getTotalUnreadMessageCount();
    if (res.code == 0) {
      return res.data ?? 0;
    }
    _coreService.callOnCallback(TIMCallback(
        type: TIMCallbackType.API_ERROR,
        errorMsg: res.desc,
        errorCode: res.code));
    return 0;
  }
}
