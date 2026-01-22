// MARK: 消息类型
class WKMessageContentType {
  /// 未知消息类型
  static const unknown = -1;

  /// 文本消息
  static const text = 1;

  /// 图片消息
  static const image = 2;

  /// 动图消息
  static const gif = 3;

  /// 语音消息
  static const voice = 4;

  /// 视频消息
  static const video = 5;

  /// 位置消息
  static const location = 6;

  /// 名片消息
  static const card = 7;

  /// 文件消息
  static const file = 8;

  /// 内容格式错误
  static const contentFormatError = 97;

  /// 内部消息
  static const insideMsg = 99;
}
