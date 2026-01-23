import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_easyrefresh/easy_refresh.dart';
import 'package:flutter_slidable_plus_plus/flutter_slidable_plus_plus.dart';
import 'package:provider/provider.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:tencent_chat_i18n_tool/tencent_chat_i18n_tool.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_user_status.dart'
    if (dart.library.html) 'package:tencent_cloud_chat_sdk/web/compatible_models/v2_tim_user_status.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_base.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_state.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_statelesswidget.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/life_cycle/wk_conversation_life_cycle.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/view_models/tui_friendship_view_model.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/listener_model/tui_group_listener_model.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/view_models/wk_conversation_view_model.dart';
import 'package:tencent_cloud_chat_uikit/data_services/core/tim_uikit_wide_modal_operation_key.dart';
import 'package:tencent_cloud_chat_uikit/data_services/services_locatar.dart';
import 'package:tencent_cloud_chat_uikit/tencent_cloud_chat_uikit.dart';
import 'package:tencent_cloud_chat_uikit/ui/controller/wk_uikit_conversation_controller.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/platform.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/screen_utils.dart';
import 'package:tencent_cloud_chat_uikit/ui/views/TIMUIKitConversation/wk_uikit_conversation_item.dart';
import 'package:tencent_cloud_chat_uikit/ui/widgets/customize_ball_pulse_header.dart';
import 'package:tencent_cloud_chat_uikit/ui/widgets/wide_popup.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_callback.dart';
import 'package:tencent_cloud_chat_uikit/theme/color.dart';
import 'package:tencent_cloud_chat_uikit/theme/tui_theme_view_model.dart';
import 'package:wukongimfluttersdk/entity/conversation.dart';
import 'package:wukongimfluttersdk/entity/msg.dart';

/// 用于构建会话项的函数类型
typedef WKConversationItemBuilder = Widget Function(
    WKUIConversationMsg conversationItem,
    [V2TimUserStatus? onlineStatus]);

/// 用于构建滑动操作面板的函数类型
typedef WKConversationItemSlideBuilder = List<ConversationItemSlidePanel>
    Function(WKUIConversationMsg conversationItem);

/// 用于构建二级菜单的函数类型
typedef WKConversationItemSecondaryMenuBuilder = Widget Function(
    WKUIConversationMsg conversationItem, VoidCallback onClose);

class WKUIKitConversation extends StatefulWidget {
  /// 点击会话项后的回调函数
  final ValueChanged<WKUIConversationMsg>? onTapItem;

  /// 会话控制器
  final WKUIKitConversationController? controller;

  /// 会话项构建器
  final WKConversationItemBuilder? itemBuilder;

  /// 每个会话项的滑动操作构建器，在窄屏幕上显示
  final WKConversationItemSlideBuilder? itemSlideBuilder;

  /// 每个会话项的二级点击菜单构建器，在宽屏幕上显示
  final WKConversationItemSecondaryMenuBuilder? itemSecondaryMenuBuilder;

  /// 当没有会话时显示的组件
  final Widget Function()? emptyBuilder;

  /// 会话过滤器
  final bool Function(WKUIConversationMsg? conversation)? conversationCollector;

  /// 每个会话项第二行的构建器，
  /// 通常显示最后一条消息的摘要
  final WKLastMessageBuilder? lastMessageBuilder;

  /// `TIMUIKitConversation` 的生命周期钩子
  final WKConversationLifeCycle? lifeCycle;

  /// 控制是否在头像上显示用户的在线状态
  final bool isShowOnlineStatus;

  /// 控制是否显示会话有草稿文本的标识符
  final bool isShowDraft;

  const WKUIKitConversation(
      {Key? key,
      this.lifeCycle,
      this.onTapItem,
      this.controller,
      this.itemSecondaryMenuBuilder,
      this.itemBuilder,
      this.isShowDraft = true,
      this.itemSlideBuilder,
      this.conversationCollector,
      this.emptyBuilder,
      this.lastMessageBuilder,
      this.isShowOnlineStatus = true})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _WKUIKitConversationState();
  }
}

class ConversationItemSlidePanel extends TIMUIKitStatelessWidget {
  ConversationItemSlidePanel({
    Key? key,
    this.flex = 1,
    this.backgroundColor = Colors.white,
    this.foregroundColor,
    this.autoClose = true,
    required this.onPressed,
    this.icon,
    this.spacing = 4,
    this.label,
  })  : assert(flex > 0),
        assert(icon != null || label != null),
        super(key: key);

  /// 滑动操作面板的弹性系数
  final int flex;

  /// 滑动操作面板的背景颜色
  final Color backgroundColor;

  /// 滑动操作面板的前景颜色
  final Color? foregroundColor;

  /// 滑动操作面板是否自动关闭
  final bool autoClose;

  /// 滑动操作面板的点击回调
  final SlidableActionCallback? onPressed;

  /// 显示在[label]上方的图标
  final IconData? icon;

  /// [icon] 和 [label] 之间的间距
  ///
  /// 默认值为 4。
  final double spacing;

  /// 显示在 [icon] 下方的标签
  final String? label;

  @override
  Widget tuiBuild(BuildContext context, TUIKitBuildValue value) {
    return SlidableAction(
      onPressed: onPressed,
      flex: flex,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      autoClose: autoClose,
      label: label,
      spacing: spacing,
    );
  }
}

class _WKUIKitConversationState extends TIMUIKitState<WKUIKitConversation> {
  /// 会话视图模型
  final WKConversationViewModel model =
      serviceLocator<WKConversationViewModel>();

  /// 会话控制器
  late WKUIKitConversationController _wkuiKitConversationController;

  /// 主题视图模型
  final TUIThemeViewModel themeViewModel = serviceLocator<TUIThemeViewModel>();

  /// 好友关系视图模型
  final TUIFriendShipViewModel friendShipViewModel =
      serviceLocator<TUIFriendShipViewModel>();

  /// 群组监听器模型
  final TUIGroupListenerModel groupListenerModel =
      serviceLocator<TUIGroupListenerModel>();

  /// 自动滚动控制器
  late AutoScrollController _autoScrollController;

  @override

  /// 初始化状态
  void initState() {
    super.initState();
    final controller = getController();
    _wkuiKitConversationController = controller;
    _wkuiKitConversationController.model = model;
    _autoScrollController = AutoScrollController();
  }

  /// 获取会话控制器实例
  WKUIKitConversationController getController() {
    return widget.controller ?? WKUIKitConversationController();
  }

  /// 处理会话项点击事件
  void onTapConvItem(WKUIConversationMsg conversation) {
    if (widget.onTapItem != null) {
      widget.onTapItem!(conversation);
    }
    model.setWKSelectedConversation(conversation);
  }

  /// 清除会话历史消息
  _clearHistory(WKUIConversationMsg conversationItem) {
    _wkuiKitConversationController.clearWKHistoryMessage(
        conversation: conversationItem);
  }

  /// 置顶/取消置顶会话
  _pinConversation(WKUIConversationMsg conversation) {
    print("悟空：我暂时还没有实现");
    // _wkuiKitConversationController.pinWKConversation(
    //     conversationID: conversation.conversationID,
    //     isPinned: !conversation.isPinned!);
  }

  /// 删除会话
  _deleteConversation(WKUIConversationMsg conversation) {
    _wkuiKitConversationController.deleteWKConversation(
        channelID: conversation.channelID,
        channelType: conversation.channelType);
  }

  /// 获取过滤后的会话列表
  List<WKUIConversationMsg?> getFilteredConversation() {
    List<WKUIConversationMsg?> filteredConversationList = model.conversationList
        .where((element) => (element?.channelID != null))
        .toList();
    if (widget.conversationCollector != null) {
      filteredConversationList = filteredConversationList
          .where(widget.conversationCollector!)
          .toList();
    }
    return filteredConversationList;
  }

  /// 滚动到指定会话
  _onScrollToConversation(String conversationID) {
    final msgList = getFilteredConversation();
    bool isFound = false;
    int targetIndex = 1;
    for (int i = msgList.length - 1; i >= 0; i--) {
      final currentConversation = msgList[i];
      if (currentConversation?.channelID == conversationID) {
        isFound = true;
        targetIndex = i;
        break;
      }
    }

    if (isFound) {
      _autoScrollController.scrollToIndex(
        targetIndex,
        preferPosition: AutoScrollPosition.begin,
      );
    }
  }

  /// 构建默认的二级菜单
  Widget _defaultSecondaryMenu(
      WKUIConversationMsg conversationItem, VoidCallback onClose) {
    return TUIKitColumnMenu(data: [
      if (!PlatformUtils().isWeb)
        ColumnMenuItem(
            label: TIM_t("清除消息"),
            icon: const Icon(Icons.clear_all, size: 16),
            onClick: () {
              onClose();
              _clearHistory(conversationItem);
            }),
      // 悟空 字段中 无 置顶 字段 暂时注掉
      // ColumnMenuItem(
      //     label: conversationItem.isPinned! ? TIM_t("取消置顶") : TIM_t("置顶"),
      //     icon: Icon(
      //         conversationItem.isPinned!
      //             ? Icons.vertical_align_bottom
      //             : Icons.vertical_align_top,
      //         size: 16),
      //     onClick: () {
      //       onClose();
      // _pinConversation(conversationItem);
      //     }),
      ColumnMenuItem(
          label: TIM_t("删除会话"),
          icon: const Icon(Icons.delete_outline, size: 16),
          onClick: () {
            onClose();
            _deleteConversation(conversationItem);
          }),
    ]);
  }

  /// 构建默认的滑动操作面板
  List<ConversationItemSlidePanel> _defaultSlideBuilder(
    WKUIConversationMsg conversationItem,
  ) {
    final theme = themeViewModel.theme;
    return [
      if (!PlatformUtils().isWeb)
        ConversationItemSlidePanel(
          onPressed: (context) {
            _clearHistory(conversationItem);
          },
          backgroundColor: theme.conversationItemSliderClearBgColor ??
              CommonColor.primaryColor,
          foregroundColor: theme.conversationItemSliderTextColor,
          label: TIM_t("清除"),
          spacing: 0,
          autoClose: true,
        ),
      // ConversationItemSlidePanel(
      //   onPressed: (context) {
      //     _pinConversation(conversationItem);
      //   },
      //   backgroundColor:
      //       theme.conversationItemSliderPinBgColor ?? CommonColor.infoColor,
      //   foregroundColor: theme.conversationItemSliderTextColor,
      //   label: conversationItem.isPinned! ? TIM_t("取消置顶") : TIM_t("置顶"),
      // ),
      ConversationItemSlidePanel(
        onPressed: (context) {
          _deleteConversation(conversationItem);
        },
        backgroundColor:
            theme.conversationItemSliderDeleteBgColor ?? Colors.red,
        foregroundColor: theme.conversationItemSliderTextColor,
        label: TIM_t("删除"),
      )
    ];
  }

  /// 获取二级菜单
  Widget _getSecondaryMenu(
      WKUIConversationMsg conversation, VoidCallback onClose) {
    if (widget.itemSecondaryMenuBuilder != null) {
      return widget.itemSecondaryMenuBuilder!(conversation, onClose);
    }
    return _defaultSecondaryMenu(conversation, onClose);
  }

  /// 获取滑动操作面板构建器
  WKConversationItemSlideBuilder _getSlideBuilder() {
    return widget.itemSlideBuilder ?? _defaultSlideBuilder;
  }

  @override

  /// 释放资源
  void dispose() {
    super.dispose();
  }

  @override

  /// 构建UI界面
  Widget tuiBuild(BuildContext context, TUIKitBuildValue value) {
    final theme = value.theme;
    final isDesktopScreen =
        TUIKitScreenUtils.getFormFactor(context) == DeviceType.Desktop;
    return MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: model),
          ChangeNotifierProvider.value(value: friendShipViewModel),
          ChangeNotifierProvider.value(value: groupListenerModel)
        ],
        builder: (BuildContext context, Widget? w) {
          final _model = Provider.of<WKConversationViewModel>(context);
          bool haveMoreData = _model.haveMoreData;
          final _friendShipViewModel =
              Provider.of<TUIFriendShipViewModel>(context);
          _model.lifeCycle = widget.lifeCycle;

          final TUIGroupListenerModel groupListenerModel =
              Provider.of<TUIGroupListenerModel>(context, listen: true);
          final NeedUpdate? needUpdate = groupListenerModel.needUpdate;
          if (needUpdate != null) {
            groupListenerModel.needUpdate = null;
            if (needUpdate.updateType == UpdateType.groupDismissed) {
              onTIMCallback(TIMCallback(
                  type: TIMCallbackType.INFO,
                  infoRecommendText: "${needUpdate!.extraData}${TIM_t("已解散")}",
                  infoCode: 6661402));
            } else if (needUpdate.updateType == UpdateType.kickedFromGroup) {
              onTIMCallback(TIMCallback(
                  type: TIMCallbackType.INFO,
                  infoRecommendText:
                      "${TIM_t("您已被踢出")}${needUpdate!.extraData}",
                  infoCode: 6661402));
            }
          }

          List<WKUIConversationMsg?> filteredConversationList =
              getFilteredConversation();

          if (TencentUtils.checkString(_model.scrollToConversation) != null) {
            _onScrollToConversation(_model.scrollToConversation!);
            _model.clearScrollToConversation();
          }

          Widget conversationList() {
            return filteredConversationList.isNotEmpty
                ? ListView.builder(
                    controller: _autoScrollController,
                    shrinkWrap: true,
                    itemCount: filteredConversationList.length,
                    itemBuilder: (context, index) {
                      if (index == filteredConversationList.length - 1) {
                        if (haveMoreData) {
                          _wkuiKitConversationController.loadData();
                        }
                      }

                      final conversationItem = filteredConversationList[index];

                      // TODO: channelID 存在疑点
                      final V2TimUserStatus? onlineStatus =
                          _friendShipViewModel.userStatusList.firstWhere(
                              (item) =>
                                  item.userID == conversationItem?.channelID,
                              orElse: () => V2TimUserStatus(statusType: 0));

                      if (widget.itemBuilder != null) {
                        return widget.itemBuilder!(
                            conversationItem!, onlineStatus);
                      }

                      final slideChildren =
                          _getSlideBuilder()(conversationItem!);

                      final isCurrent = conversationItem.channelID ==
                          model.selectedConversation?.channelID;

                      // 先注掉,使用默认值
                      // final isPined = conversationItem.isPined ?? false;
                      final isPined = false;

                      /// 构建会话项
                      Widget conversationLineItem() {
                        return Material(
                          color: (isCurrent && isDesktopScreen)
                              ? theme.conversationItemChooseBgColor
                              : isPined
                                  ? theme.conversationItemPinedBgColor
                                  : theme.conversationItemBgColor,
                          child: GestureDetector(
                            // child: TIMUIKitConversationItem(
                            //     isCurrent: isCurrent,
                            //     lastMessageBuilder: widget.lastMessageBuilder,
                            //     faceUrl: conversationItem.faceUrl ?? "",
                            //     nickName: conversationItem.showName ?? "",
                            //     isDisturb:
                            //         (conversationItem.groupType == "Meeting"
                            //             ? false
                            //             : conversationItem.recvOpt != 0),
                            //     lastMsg: conversationItem.lastMessage,
                            //     isPined: isPined,
                            //     groupAtInfoList:
                            //         conversationItem.groupAtInfoList ?? [],
                            //     unreadCount: conversationItem.unreadCount ?? 0,
                            //     draftText: conversationItem.draftText,
                            //     onlineStatus: (widget.isShowOnlineStatus &&
                            //             conversationItem.userID != null &&
                            //             conversationItem.userID!.isNotEmpty)
                            //         ? onlineStatus
                            //         : null,
                            //     draftTimestamp: conversationItem.draftTimestamp,
                            //     convType: conversationItem.type),
                            // onTap: () => onTapConvItem(conversationItem),
                            // MARK: 暂时数据有限注掉原有，使用建议
                            child: FutureBuilder<WKMsg?>(
                              future: conversationItem.getWkMsg(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  // 可选：显示加载状态，或空内容
                                  return _buildConversationItem(
                                    conversationItem: conversationItem,
                                    lastMsg: null,
                                    onlineStatus: onlineStatus,
                                    isCurrent: isCurrent,
                                    isPined: isPined,
                                    isDesktopScreen: isDesktopScreen,
                                  );
                                } else {
                                  final lastMsg = snapshot.data;
                                  return _buildConversationItem(
                                    conversationItem: conversationItem,
                                    lastMsg: lastMsg,
                                    onlineStatus: onlineStatus,
                                    isCurrent: isCurrent,
                                    isPined: isPined,
                                    isDesktopScreen: isDesktopScreen,
                                  );
                                }
                              },
                            ),
                            onTap: () => onTapConvItem(conversationItem),
                          ),
                        );
                      }

                      return TUIKitScreenUtils.getDeviceWidget(
                          context: context,
                          desktopWidget: AutoScrollTag(
                            key: ValueKey(conversationItem.channelID),
                            controller: _autoScrollController,
                            index: index,
                            child: InkWell(
                              onSecondaryTapDown: (details) {
                                TUIKitWidePopup.showPopupWindow(
                                    operationKey: TUIKitWideModalOperationKey
                                        .conversationSecondaryMenu,
                                    isDarkBackground: false,
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(4)),
                                    context: context,
                                    offset: Offset(
                                        min(
                                            details.globalPosition.dx,
                                            MediaQuery.of(context).size.width -
                                                80),
                                        min(
                                            details.globalPosition.dy,
                                            MediaQuery.of(context).size.height -
                                                130)),
                                    child: (onClose) => _getSecondaryMenu(
                                        conversationItem, onClose));
                              },
                              child: conversationLineItem(),
                            ),
                          ),
                          defaultWidget: AutoScrollTag(
                            key: ValueKey(conversationItem.channelID),
                            controller: _autoScrollController,
                            index: index,
                            child: Slidable(
                                groupTag: 'conversation-list',
                                child: conversationLineItem(),
                                endActionPane: ActionPane(
                                    extentRatio:
                                        slideChildren.length > 2 ? 0.77 : 0.5,
                                    motion: const DrawerMotion(),
                                    children: slideChildren)),
                          ));
                    })
                : (widget.emptyBuilder != null
                    ? widget.emptyBuilder!()
                    : Container());
          }

          /// 返回设备适配的会话列表
          return TUIKitScreenUtils.getDeviceWidget(
              context: context,
              defaultWidget: SlidableAutoCloseBehavior(
                child: EasyRefresh(
                  header: CustomizeBallPulseHeader(color: theme.primaryColor),
                  onRefresh: () async {
                    model.wkRefresh();
                  },
                  child: conversationList(),
                ),
              ),
              desktopWidget: Scrollbar(
                  controller: _autoScrollController,
                  child: conversationList()));
        });
  }

  Widget _buildConversationItem({
    required WKUIConversationMsg conversationItem,
    required WKMsg? lastMsg,
    required V2TimUserStatus? onlineStatus,
    required bool isCurrent,
    required bool isPined,
    required bool isDesktopScreen,
  }) {
    return WKUIKitConversationItem(
      isCurrent: isCurrent,
      lastMessageBuilder: widget.lastMessageBuilder,
      faceUrl: "",
      nickName: conversationItem.channelID,
      isDisturb: false,
      lastMsg: lastMsg,
      isPined: false,
      groupAtInfoList: [],
      unreadCount: conversationItem.unreadCount,
      draftText: '暂无草稿',
      onlineStatus:
          (widget.isShowOnlineStatus && conversationItem.channelID.isNotEmpty)
              ? onlineStatus
              : null,
      draftTimestamp: 0,
      convType: conversationItem.channelType,
    );
  }
}
