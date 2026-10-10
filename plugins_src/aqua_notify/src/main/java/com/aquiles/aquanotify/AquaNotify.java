package com.aquiles.aquanotify;

import android.Manifest;
import android.app.Activity;
import android.app.AlarmManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.os.Build;

import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.UsedByGodot;

/** Notificaciones locales programadas (sin servidor): hambre, huevos, mantenimiento, racha. */
public class AquaNotify extends GodotPlugin {
    private static final int MAX_IDS = 16;

    public AquaNotify(Godot godot) {
        super(godot);
    }

    @Override
    public String getPluginName() {
        return "AquaNotify";
    }

    private Context ctx() {
        Activity a = getActivity();
        return a != null ? a.getApplicationContext() : null;
    }

    private PendingIntent intent(Context c, int id, String title, String text) {
        Intent i = new Intent(c, NotifyReceiver.class);
        i.putExtra("id", id);
        i.putExtra("title", title);
        i.putExtra("text", text);
        return PendingIntent.getBroadcast(c, id, i, PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);
    }

    /** Programa un aviso dentro de delaySec segundos (inexacto: Android lo agrupa para ahorrar batería). */
    @UsedByGodot
    public void schedule(int id, String title, String text, int delaySec) {
        Context c = ctx();
        if (c == null || id < 0 || id >= MAX_IDS) return;
        AlarmManager am = (AlarmManager) c.getSystemService(Context.ALARM_SERVICE);
        if (am == null) return;
        am.set(AlarmManager.RTC_WAKEUP, System.currentTimeMillis() + delaySec * 1000L, intent(c, id, title, text));
    }

    @UsedByGodot
    public void cancelAll() {
        Context c = ctx();
        if (c == null) return;
        AlarmManager am = (AlarmManager) c.getSystemService(Context.ALARM_SERVICE);
        for (int id = 0; id < MAX_IDS; id++) {
            if (am != null) am.cancel(intent(c, id, "", ""));
        }
        android.app.NotificationManager nm = (android.app.NotificationManager) c.getSystemService(Context.NOTIFICATION_SERVICE);
        if (nm != null) nm.cancelAll();
    }

    /** Android 13+: pide permiso para mostrar notificaciones (una vez). */
    @UsedByGodot
    public void requestPermission() {
        Activity a = getActivity();
        if (a == null || Build.VERSION.SDK_INT < 33) return;
        if (a.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
            a.requestPermissions(new String[]{Manifest.permission.POST_NOTIFICATIONS}, 4711);
        }
    }
}
