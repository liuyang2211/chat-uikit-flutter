// ignore_for_file: unnecessary_getters_setters

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:tencent_cloud_chat_sdk/enum/V2TimConversationListener.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_callback.dart'
    if (dart.library.html) 'package:tencent_cloud_chat_sdk/web/compatible_models/v2_tim_callback.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_friend_search_param.dart'
    if (dart.library.html) 'package:tencent_cloud_chat_sdk/web/compatible_models/v2_tim_friend_search_param.dart';
import 'package:tencent_cloud_chat_sdk/tencent_im_sdk_plugin.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/life_cycle/wk_conversation_life_cycle.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/view_models/tui_chat_global_model.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/view_models/tui_self_info_view_model.dart';
import 'package:tencent_cloud_chat_uikit/data_services/conversation/wk_conversation_services.dart';
import 'package:tencent_cloud_chat_uikit/data_services/friendShip/friendship_services.dart';
import 'package:tencent_cloud_chat_uikit/data_services/message/message_services.dart';
import 'package:tencent_cloud_chat_uikit/data_services/services_locatar.dart';
import 'package:tencent_cloud_chat_uikit/tencent_cloud_chat_uikit.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/platform.dart';
import 'package:tencent_cloud_chat_uikit/wukong/wk_http_utils.dart';
import 'package:wukongimfluttersdk/entity/conversation.dart';

/// 移除列表中的重复项
///
/// @param list 要处理的列表
/// @param isEqual 比较两个元素是否相等的函数
/// @return 去重后的列表
List<T> removeDuplicates<T>(
    List<T> list, bool Function(T first, T second) isEqual) {
  List<T> output = [];
  for (var i = 0; i < list.length; i++) {
    bool found = false;
    for (var j = 0; j < output.length; j++) {
      if (isEqual(list[i], output[j])) {
        found = true;
      }
    }
    if (!found) {
      output.add(list[i]);
    }
  }

  return output;
}

class WKConversationViewModel extends ChangeNotifier {
  /// C2C会话类型
  static const int conversationC2C = 1;

  /// 群组会话类型
  static const int conversationGroup = 2;

  /// 自身信息视图模型，用于获取当前用户信息
  final TUISelfInfoViewModel selfInfoViewModel =
      serviceLocator<TUISelfInfoViewModel>();

  /// 会话服务，用于与后端交互获取会话数据
  final WKConversationService _conversationService =
      serviceLocator<WKConversationService>();

  /// 好友服务，用于搜索好友等操作
  final FriendshipServices _friendshipServices =
      serviceLocator<FriendshipServices>();

  /// 聊天全局模型，用于管理全局聊天状态
  final TUIChatGlobalModel _chatGlobalModel =
      serviceLocator<TUIChatGlobalModel>();

  /// 消息服务，用于处理消息相关操作
  final MessageService _messageService = serviceLocator<MessageService>();

  /// 会话监听器，用于监听会话变化事件
  late V2TimConversationListener _conversationListener;

  /// 会话列表，存储当前用户的会话信息
  List<WKUIConversationMsg?> _conversationList = [];

  /// 当前选中的会话
  static WKUIConversationMsg? _selectedConversation;

  /// Web端草稿映射，用于存储Web端会话草稿
  Map<String, String> webDraftMap = {};

  /// 是否还有更多数据可加载
  bool _haveMoreData = true;

  /// 总未读消息数
  int _totalUnReadCount = 0;

  /// 需要滚动到的会话ID
  String? _scrollToConversation;

  /// 全局聊天模型实例
  final TUIChatGlobalModel globalChatModel =
      serviceLocator<TUIChatGlobalModel>();

  /// 下一个序列号，用于分页加载会话列表
  String _nextSeq = "0";

  /// 会话生命周期管理器
  WKConversationLifeCycle? _lifeCycle;

  /// 获取会话列表，根据平台类型排序
  /// Web端按最后消息时间倒序排列，非Web端按orderkey排序
  List<WKUIConversationMsg?> get conversationList {
    if (PlatformUtils().isWeb) {
      try {
        _conversationList.sort((a, b) {
          return b!.lastMsgTimestamp.compareTo(a!.lastMsgTimestamp);
        });
        // 置顶相关处理
        // final pinnedConversation = _conversationList
        //     .where((element) => element?.isPinned == true)
        //     .toList();
        // _conversationList.removeWhere((element) => element?.isPinned == true);
        // _conversationList = [...pinnedConversation, ..._conversationList];
        // ignore: empty_catches
      } catch (e) {}
    } else {
      // 腾讯中orderkey表示活跃时间，悟空用 lastMsgTimestamp 代替
      _conversationList
          .sort((a, b) => b!.lastMsgTimestamp.compareTo(a!.lastMsgTimestamp));
    }
    return _conversationList;
  }

  /// 根据会话ID获取指定会话
  ///
  /// @param conversationID 会话ID
  /// @return 对应的会话对象，如果不存在则返回null
  WKUIConversationMsg? getConversation(String conversationID) {
    return _conversationList
        .firstWhereOrNull((element) => element?.channelID == conversationID);
  }

  /// 获取需要滚动到的会话ID
  String? get scrollToConversation => _scrollToConversation;

  /// 设置需要滚动到的会话ID
  ///
  /// @param value 会话ID
  set scrollToConversation(String? value) {
    _scrollToConversation = value;
    notifyListeners();
  }

  /// 清空需要滚动到的会话ID
  void clearScrollToConversation() {
    _scrollToConversation = null;
  }

  /// 获取是否有更多数据标志
  bool get haveMoreData {
    return _haveMoreData;
  }

  /// 获取总未读消息数
  int get totalUnReadCount => _totalUnReadCount;

  /// 设置总未读消息数
  ///
  /// @param value 未读消息数
  set totalUnReadCount(int value) {
    _totalUnReadCount = value;
  }

  /// 设置会话生命周期管理器
  ///
  /// @param value 生命周期管理器实例
  set lifeCycle(WKConversationLifeCycle? value) {
    _lifeCycle = value;
  }

  /// 设置会话列表
  ///
  /// @param conversationList 会话列表
  set conversationList(List<WKUIConversationMsg?> conversationList) {
    _conversationList = conversationList;
    notifyListeners();
  }

  /// 设置选中的会话
  ///
  /// @param value 会话对象
  set selectedConversation(WKUIConversationMsg? value) {
    _selectedConversation = value;
    notifyListeners();
  }

  /// 获取选中的会话
  WKUIConversationMsg? get selectedConversation {
    return _selectedConversation;
  }

  /// 获取当前选中的会话（静态方法）
  static WKUIConversationMsg? of() {
    return _selectedConversation;
  }

  /// 构造函数，初始化会话监听器
  WKConversationViewModel() {
    /// 添加会话列表刷新监听器
    TencentImSDKPlugin.wukongIMManager.conversationManager
        .addOnRefreshMsgListListener("chat_conversation",
            (conversationList) async {
      _onConversationListChanged(conversationList);
      TencentImSDKPlugin.wukongIMManager.conversationManager
          .getAllUnreadCount()
          .then((totalUnread) {
        _totalUnReadCount = totalUnread;
        _chatGlobalModel.totalUnReadCount = totalUnread;
        notifyListeners();
      });
    });

    /// 添加会话删除监听器
    TencentImSDKPlugin.wukongIMManager.conversationManager
        .addOnDeleteMsgListener('chat', (channelID, channelType) {
      _onConversationDeleted([channelID]);

      _chatGlobalModel.removeMessageList(channelID);

      TencentImSDKPlugin.wukongIMManager.conversationManager
          .getAllUnreadCount()
          .then((totalUnread) {
        _totalUnReadCount = totalUnread;
        _chatGlobalModel.totalUnReadCount = totalUnread;
        notifyListeners();
      });
    });

    /// 添加同步会话监听器
    TencentImSDKPlugin.wukongIMManager.conversationManager
        .addOnSyncConversationListener(
            (lastSsgSeqs, msgCount, version, back) async {
      await WKHttpUtils.syncConversation(lastSsgSeqs, msgCount, version, back);

      // Remove the process to load such a many of conversations after launching
      // 移除启动后加载大量会话的处理过程" 或 "移除应用启动后加载大量会话的逻辑
      if (!PlatformUtils().isWeb) {
        wkLoadInitConversation();
      }

      TencentImSDKPlugin.wukongIMManager.conversationManager
          .getAllUnreadCount()
          .then((totalUnread) {
        _totalUnReadCount = totalUnread;
        _chatGlobalModel.totalUnReadCount = totalUnread;
        notifyListeners();
      });
    });
  }

  /// 加载初始会话数据
  wkLoadInitConversation() async {
    await wkLoadData(count: 40);
    // Remove the process to load such a many of conversations after launching
    // if (selfInfoViewModel.globalConfig?.isPreloadMessagesAfterInit ?? true) {
    //   _chatGlobalModel.initMessageMapFromLocalDatabase(_conversationList);
    // }
  }

  /// 初始化会话
  initConversation() async {
    wkClearData();
    wkLoadInitConversation();
  }

  /// MARK: 加载悟空会话数据
  ///
  /// @param count 加载数量
  Future<void> wkLoadData({required int count}) async {
    _haveMoreData = true;
    final isRefresh = _nextSeq == "0";
    final conversationResult = await _conversationService.getWKConversationList(
        nextSeq: _nextSeq, count: count);
    _nextSeq = conversationResult.nextSeq ?? "";
    final conversationList = conversationResult.conversationList;
    if (conversationList != null) {
      if (conversationList.isEmpty || conversationList.length < count) {
        _haveMoreData = false;
      }
      List<WKUIConversationMsg?> combinedConversationList = [];
      if (isRefresh) {
        combinedConversationList = conversationList;
      } else {
        combinedConversationList = [..._conversationList, ...conversationList];
      }
      final List<WKUIConversationMsg?> finalConversationList = await _lifeCycle
              ?.conversationListWillMount(combinedConversationList) ??
          combinedConversationList;
      _conversationList = removeDuplicates<WKUIConversationMsg?>(
          finalConversationList,
          (item1, item2) => item1?.channelID == item2?.channelID);
      notifyListeners();
    }
    _totalUnReadCount = await _conversationService.getWKTotalUnreadCount();
    notifyListeners();
    return;
  }

  /// 设置选中的会话
  ///
  /// @param conversation 会话对象
  void setWKSelectedConversation(WKUIConversationMsg conversation) {
    _selectedConversation = conversation;
    notifyListeners();
  }

  /// 设置会话置顶状态
  ///
  /// @param conversationID 会话ID
  /// @param isPinned 是否置顶
  Future<V2TimCallback> pinWKConversation({
    required String conversationID,
    required bool isPinned,
  }) {
    return _conversationService.pinWKConversation(
        conversationID: conversationID, isPinned: isPinned);
  }

  /// 清除会话历史消息
  ///
  /// @param convID 会话ID
  /// @param convType 会话类型
  Future<V2TimCallback?> clearWKHistoryMessage(
      {required String channelID, required int channelType}) async {
    if (_lifeCycle?.shouldClearHistoricalMessageForConversation != null &&
        await _lifeCycle!
                .shouldClearHistoricalMessageForConversation(channelID) ==
            false) {
      return null;
    }

    globalChatModel.setMessageList(channelID, []);

    if (channelType == 1) {
      return _messageService.clearC2CHistoryMessage(userID: channelID);
    } else {
      return _messageService.clearGroupHistoryMessage(groupID: channelID);
    }
  }

  /// 搜索好友
  ///
  /// @param searchKey 搜索关键词
  wkSearchFriends(String searchKey) async {
    final res = await _friendshipServices.searchFriends(
        searchParam: V2TimFriendSearchParam(keywordList: [searchKey]));
    return res;
  }

  /// 删除会话
  ///
  /// @param conversationID 会话ID
  Future<bool?> deleteWKConversation(
      {required String channelID, required int channelType}) async {
    if (_lifeCycle?.shouldDeleteConversation != null &&
        await _lifeCycle!.shouldDeleteConversation(channelID) == false) {
      return null;
    }
    final res = await _conversationService.deleteWKConversation(
        channelID: channelID, channelType: channelType);
    if (res) {
      _conversationList
          .removeWhere((element) => element?.channelID == channelID);
      notifyListeners();
    }
    return res;
  }

  /// 处理会话列表变更事件
  ///
  /// @param list 会话列表
  _onConversationListChanged(List<WKUIConversationMsg> list) {
    for (int element = 0; element < list.length; element++) {
      int index = _conversationList
          .indexWhere((item) => item!.channelID == list[element].channelID);
      if (index > -1) {
        _conversationList.setAll(
            index, [list[element]] as List<WKUIConversationMsg?>);
      } else {
        _conversationList.add(list[element]);
      }
    }

    notifyListeners();
  }

  /// 处理会话删除事件
  ///
  /// @param list 会话ID列表
  _onConversationDeleted(List<String> list) {
    for (int i = 0; i < list.length; i++) {
      int index =
          _conversationList.indexWhere((item) => item!.channelID == list[i]);
      if (index > -1) {
        _conversationList.removeAt(index);
        _conversationList = removeDuplicates<WKUIConversationMsg?>(
            _conversationList,
            (item1, item2) => item1?.channelID == item2?.channelID);
      }
    }
    notifyListeners();
  }

  // /// 添加新会话
  // ///
  // /// @param list 会话列表
  // _addNewConversation(List<WKUIConversationMsg> list) {
  //   _conversationList.addAll(list);
  //   _conversationList = removeDuplicates<WKUIConversationMsg?>(
  //       _conversationList,
  //       (item1, item2) => item1?.channelID == item2?.channelID);
  //   notifyListeners();
  // }

  /// 设置会话监听器
  setWKConversationListener() {
    _conversationService.addWKConversationListener(
        listener: _conversationListener);
  }

  /// 移除会话监听器
  removeWKConversationListener() {
    _conversationService.removeWKConversationListener(
        listener: _conversationListener);
  }

  /// 设置会话草稿
  ///
  /// @param conversationID 会话ID
  /// @param draftText 草稿文本
  /// @param isTopic 是否为话题
  /// @param groupID 群组ID
  /// @param isAllowWeb 是否允许Web端设置
  Future<V2TimCallback> setWKConversationDraft({
    required String conversationID,
    String? draftText,
    bool isTopic = false,
    String? groupID,
    bool isAllowWeb = true,
  }) async {
    assert(!isTopic || (groupID != null && groupID.isNotEmpty),
        "When 'isTopic' is true, 'groupID' must not be null or empty.");
    if (PlatformUtils().isWeb && isAllowWeb) {
      webDraftMap[conversationID] = draftText ?? "";
      return V2TimCallback(code: 0, desc: "");
    } else {
      if (isTopic) {
        final topicInfoList = await TencentImSDKPlugin.v2TIMManager
            .getGroupManager()
            .getTopicInfoList(groupID: groupID!, topicIDList: [conversationID]);
        final topicInfo = topicInfoList.data?.first.topicInfo;
        topicInfo?.draftText = draftText;
        final res = await TencentImSDKPlugin.v2TIMManager
            .getGroupManager()
            .setTopicInfo(topicInfo: topicInfo!);
        return res;
      } else {
        return _conversationService.setWKConversationDraft(
            conversationID: conversationID, draftText: draftText);
      }
    }
  }

  /// 清除Web端草稿
  ///
  /// @param conversationID 会话ID
  clearWebDraft({
    required String conversationID,
  }) {
    webDraftMap[conversationID] = "";
  }

  /// 获取Web端草稿
  ///
  /// @param conversationID 会话ID
  String? getWKWebDraft({
    required String conversationID,
  }) {
    return TencentUtils.checkString(webDraftMap[conversationID]);
  }

  /// 清空数据
  wkClearData() {
    _conversationList = [];
    _selectedConversation = null;
    _nextSeq = "0";
    _haveMoreData = true;
    notifyListeners();
  }

  /// 刷新会话列表
  ///
  /// @param count 加载数量
  wkRefresh({int count = 100}) {
    _nextSeq = "0";
    _haveMoreData = true;
    wkLoadData(count: count);
  }
}
