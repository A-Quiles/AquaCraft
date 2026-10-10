package com.aquiles.aquanotify;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.os.Build;

/** Muestra el aviso cuando salta la alarma. Tocarlo abre el juego. */
public class NotifyReceiver extends BroadcastReceiver {
    private static final String CHANNEL = "aquacraft";

    @Override
    public void onReceive(Context c, Intent in) {
        NotificationManager nm = (NotificationManager) c.getSystemService(Context.NOTIFICATION_SERVICE);
        if (nm == null) return;
        if (Build.VERSION.SDK_INT >= 26) {
            nm.createNotificationChannel(new NotificationChannel(CHANNEL, "Tu acuario", NotificationManager.IMPORTANCE_DEFAULT));
        }
        Intent open = c.getPackageManager().getLaunchIntentForPackage(c.getPackageName());
        PendingIntent pi = open == null ? null
                : PendingIntent.getActivity(c, 0, open, PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);
        Notification.Builder b = Build.VERSION.SDK_INT >= 26 ? new Notification.Builder(c, CHANNEL) : new Notification.Builder(c);
        b.setSmallIcon(c.getApplicationInfo().icon)
                .setContentTitle(in.getStringExtra("title"))
                .setContentText(in.getStringExtra("text"))
                .setAutoCancel(true);
        if (pi != null) b.setContentIntent(pi);
        try {
            nm.notify(in.getIntExtra("id", 0), b.build());
        } catch (SecurityException e) {
            // Sin permiso de notificaciones: no pasa nada.
        }
    }
}
