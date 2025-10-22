源工程地址：https://pub.dev/packages/notification_listener_service
使用方法一样，引用修改为：
dependencies:
  notification_listener_service:
    git:
      url: https://github.com/zss5599/notification_listen_server.git
      ref: main
修改了源工程问题：
1.授予权限页面返回闪退
2.app图标不显示问题
3.同一个通知收到重复广播消息问题
4.增加应用名称信息
5.增加通知推送时间信息
6.增加获取当前系统通知方法（源工程只有方法，没有是原生实现）
