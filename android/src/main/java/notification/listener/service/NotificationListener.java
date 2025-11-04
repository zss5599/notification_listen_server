package notification.listener.service;

import static notification.listener.service.NotificationUtils.getBitmapFromDrawable;
import static notification.listener.service.models.ActionCache.cachedNotifications;

import android.annotation.SuppressLint;
import android.app.Notification;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.graphics.Bitmap;
import android.graphics.drawable.BitmapDrawable;
import android.graphics.drawable.Drawable;
import android.graphics.drawable.Icon;
import android.os.Build;
import android.os.Build.VERSION_CODES;
import android.os.Bundle;
import android.service.notification.NotificationListenerService;
import android.service.notification.StatusBarNotification;
import android.util.Log;
import java.util.List;
import java.util.Map;
import java.util.ArrayList;
import java.util.HashMap;

import androidx.annotation.RequiresApi;
import androidx.localbroadcastmanager.content.LocalBroadcastManager;

import java.io.ByteArrayOutputStream;

import notification.listener.service.models.Action;


@SuppressLint("OverrideAbstract")
@RequiresApi(api = VERSION_CODES.JELLY_BEAN_MR2)
public class NotificationListener extends NotificationListenerService {
    private static NotificationListener instance;

    public static NotificationListener getInstance() {
        return instance;
    }

    @Override
    public void onListenerConnected() {
        super.onListenerConnected();
        instance = this;
        Log.d("NotificationListener", "onListenerConnected()");
    }

    @RequiresApi(api = VERSION_CODES.KITKAT)
    @Override
    public void onNotificationPosted(StatusBarNotification notification) {
        handleNotification(notification, false);
        Log.d("NotificationListener", "onNotificationPosted");
    }

    @RequiresApi(api = VERSION_CODES.KITKAT)
    @Override
    public void onNotificationRemoved(StatusBarNotification sbn) {
        handleNotification(sbn, true);
        Log.d("NotificationListener", "onNotificationRemoved");
    }

    @RequiresApi(api = VERSION_CODES.KITKAT)
    private void handleNotification(StatusBarNotification notification, boolean isRemoved) {
        String packageName = notification.getPackageName();
        Bundle extras = notification.getNotification().extras;
        byte[] appIcon = getAppIcon(packageName);
        byte[] largeIcon = null;
        Action action = NotificationUtils.getQuickReplyAction(notification.getNotification(), packageName);
        long postTime = notification.getPostTime();
        if (Build.VERSION.SDK_INT >= VERSION_CODES.M) {
            largeIcon = getNotificationLargeIcon(getApplicationContext(), notification.getNotification());
        }

        Intent intent = new Intent(NotificationConstants.INTENT);
        intent.putExtra(NotificationConstants.PACKAGE_NAME, packageName);
        intent.putExtra(NotificationConstants.APP_NAME, getAppNameFromPackageName(packageName));
        intent.putExtra(NotificationConstants.POST_TIME, postTime);
        intent.putExtra(NotificationConstants.ID, notification.getId());
        intent.putExtra(NotificationConstants.CAN_REPLY, action != null);

        // 添加分组通知相关字段
        String groupKey = notification.getNotification().getGroup();
        boolean isGroupSummary = (notification.getNotification().flags & Notification.FLAG_GROUP_SUMMARY) != 0;
        
        intent.putExtra(NotificationConstants.NOTIFICATIONS_ICON, appIcon);
        intent.putExtra(NotificationConstants.NOTIFICATIONS_LARGE_ICON, largeIcon);
        intent.putExtra(NotificationConstants.GROUP_KEY, groupKey);
        intent.putExtra(NotificationConstants.IS_GROUP_SUMMARY, isGroupSummary);

        if (NotificationUtils.getQuickReplyAction(notification.getNotification(), packageName) != null) {
            cachedNotifications.put(notification.getId(), action);
        }

        if (extras != null) {
            CharSequence title = extras.getCharSequence(Notification.EXTRA_TITLE);
            CharSequence text = extras.getCharSequence(Notification.EXTRA_TEXT);

            intent.putExtra(NotificationConstants.NOTIFICATION_TITLE, title == null ? null : title.toString());
            intent.putExtra(NotificationConstants.NOTIFICATION_CONTENT, text == null ? null : text.toString());
            intent.putExtra(NotificationConstants.IS_REMOVED, isRemoved);
            intent.putExtra(NotificationConstants.HAVE_EXTRA_PICTURE, extras.containsKey(Notification.EXTRA_PICTURE));

            if (extras.containsKey(Notification.EXTRA_PICTURE)) {
                Bitmap bmp = (Bitmap) extras.get(Notification.EXTRA_PICTURE);
                if (bmp != null) {
                    ByteArrayOutputStream stream = new ByteArrayOutputStream();
                    bmp.compress(Bitmap.CompressFormat.PNG, 100, stream);
                    intent.putExtra(NotificationConstants.EXTRAS_PICTURE, stream.toByteArray());
                } else {
                    Log.w("NotificationListener", "Notification.EXTRA_PICTURE exists but is null.");
                }
            }
        }
        LocalBroadcastManager.getInstance(getBaseContext()).sendBroadcast(intent);
    }


    public byte[] getAppIcon(String packageName) {
        try {
            PackageManager manager = getBaseContext().getPackageManager();
            Drawable icon = manager.getApplicationIcon(packageName);
            ByteArrayOutputStream stream = new ByteArrayOutputStream();
            getBitmapFromDrawable(icon).compress(Bitmap.CompressFormat.PNG, 100, stream);
            return stream.toByteArray();
        } catch (PackageManager.NameNotFoundException e) {
            e.printStackTrace();
            return null;
        }
    }

    // 根据包名获取应用名称的辅助方法
    private String getAppNameFromPackageName(String packageName) {
        try {
            // 获取PackageManager实例
            PackageManager packageManager = getBaseContext().getPackageManager();

            // 获取应用信息
            android.content.pm.ApplicationInfo appInfo =
                    packageManager.getApplicationInfo(packageName, 0);

            // 获取应用名称
            CharSequence appName = packageManager.getApplicationLabel(appInfo);
            Log.d("BleSdkPlugin", "get appName: " + appName);
            return appName != null ? appName.toString() : packageName;
        } catch (android.content.pm.PackageManager.NameNotFoundException e) {
            // 如果找不到应用，返回包名
            Log.e("BleSdkPlugin", "NameNotFoundException " + packageName);

            return packageName;
        } catch (Exception e) {
            Log.w("BleSdkPlugin", "Failed to get app name for package: " + packageName, e);
            // 其他异常情况，返回包名
            return packageName;
        }
    }

    @RequiresApi(api = VERSION_CODES.M)
    private byte[] getNotificationLargeIcon(Context context, Notification notification) {
        try {
            Icon largeIcon = notification.getLargeIcon();
            if (largeIcon == null) {
                return null;
            }
            Drawable iconDrawable = largeIcon.loadDrawable(context);
            Bitmap iconBitmap = ((BitmapDrawable) iconDrawable).getBitmap();
            ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
            iconBitmap.compress(Bitmap.CompressFormat.PNG, 100, outputStream);

            return outputStream.toByteArray();
        } catch (Exception e) {
            e.printStackTrace();
            Log.d("ERROR LARGE ICON", "getNotificationLargeIcon: " + e.getMessage());
            return null;
        }
    }

    @RequiresApi(api = Build.VERSION_CODES.KITKAT)
    public List<Map<String, Object>> getActiveNotificationData() {
        List<Map<String, Object>> notificationList = new ArrayList<>();
        StatusBarNotification[] activeNotifications = getActiveNotifications();

        for (StatusBarNotification notification : activeNotifications) {
            Map<String, Object> notifData = new HashMap<>();

            String packageName = notification.getPackageName();
            Bundle extras = notification.getNotification().extras;
            byte[] appIcon = getAppIcon(packageName);
            byte[] largeIcon = null;
            Action action = NotificationUtils.getQuickReplyAction(notification.getNotification(), packageName);
            long postTime = notification.getPostTime();
            if (Build.VERSION.SDK_INT >= VERSION_CODES.M) {
                largeIcon = getNotificationLargeIcon(getApplicationContext(), notification.getNotification());
            }

            notifData.put("packageName", packageName);
            notifData.put("appName", getAppNameFromPackageName(packageName));
            notifData.put("postTime", postTime);
            notifData.put("id", notification.getId());
            notifData.put("canReply", action != null);

            // 添加分组通知相关字段
            String groupKey = notification.getNotification().getGroup();
            boolean isGroupSummary = (notification.getNotification().flags & Notification.FLAG_GROUP_SUMMARY) != 0;
            
            notifData.put("groupKey", groupKey);
            notifData.put("isGroupSummary", isGroupSummary);

            if (NotificationUtils.getQuickReplyAction(notification.getNotification(), packageName) != null) {
                cachedNotifications.put(notification.getId(), action);
            }

            notifData.put("appIcon", appIcon);
            notifData.put("largeIcon", largeIcon);

            if (extras != null) {
                CharSequence title = extras.getCharSequence(Notification.EXTRA_TITLE);
                CharSequence text = extras.getCharSequence(Notification.EXTRA_TEXT);

                notifData.put("title", title == null ? null : title.toString());
                notifData.put("content", text == null ? null : text.toString());
                notifData.put("hasRemoved", false);
                notifData.put("haveExtraPicture", extras.containsKey(Notification.EXTRA_PICTURE));

                if (extras.containsKey(Notification.EXTRA_PICTURE)) {
                    Bitmap bmp = (Bitmap) extras.get(Notification.EXTRA_PICTURE);
                    if (bmp != null) {
                        ByteArrayOutputStream stream = new ByteArrayOutputStream();
                        bmp.compress(Bitmap.CompressFormat.PNG, 100, stream);
                        notifData.put("notificationExtrasPicture", stream.toByteArray());
                    } else {
                        Log.w("NotificationListener", "Notification.EXTRA_PICTURE exists but is null.");
                    }
                }
            }

            notificationList.add(notifData);
        }
        return notificationList;
    }

}
