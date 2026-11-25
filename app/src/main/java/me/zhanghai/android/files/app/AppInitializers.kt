/*
 * Copyright (c) 2020 Hai Zhang <dreaming.in.code.zh@gmail.com>
 * All Rights Reserved.
 */

package me.zhanghai.android.files.app

import android.os.Build
import android.webkit.WebView
import me.zhanghai.android.files.BuildConfig
import me.zhanghai.android.files.coil.initializeCoil
import me.zhanghai.android.files.filejob.fileJobNotificationTemplate
import me.zhanghai.android.files.hiddenapi.HiddenApi
import me.zhanghai.android.files.provider.FileSystemProviders
import me.zhanghai.android.files.settings.Settings
import me.zhanghai.android.files.storage.StorageVolumeListLiveData
import me.zhanghai.android.files.theme.custom.CustomThemeHelper
import me.zhanghai.android.files.theme.night.NightModeHelper

val appInitializers = listOf(
    ::initializeQuietCrashes,
    ::disableHiddenApiChecks,
    ::initializeWebViewDebugging,
    ::initializeCoil,
    ::initializeFileSystemProviders,
    ::upgradeApp,
    ::initializeLiveDataObjects,
    ::initializeCustomTheme,
    ::initializeNightMode,
    ::createNotificationChannels
)

/**
 * No logs: if Files ever crashes, it just closes. Android's own crash
 * handler would write what went wrong (which can name your files) to the
 * phone's log, where other tools can read it; this one writes nothing.
 */
private fun initializeQuietCrashes() {
    Thread.setDefaultUncaughtExceptionHandler { _, _ ->
        android.os.Process.killProcess(android.os.Process.myPid())
        kotlin.system.exitProcess(10)
    }
}

private fun disableHiddenApiChecks() {
    HiddenApi.disableHiddenApiChecks()
}

private fun initializeWebViewDebugging() {
    if (BuildConfig.DEBUG) {
        WebView.setWebContentsDebuggingEnabled(true)
    }
}

private fun initializeFileSystemProviders() {
    FileSystemProviders.install()
    FileSystemProviders.overflowWatchEvents = true
}

private fun initializeLiveDataObjects() {
    // Force initialization of LiveData objects so that it won't happen on a background thread.
    StorageVolumeListLiveData.value
    Settings.FILE_LIST_DEFAULT_DIRECTORY.value
}

private fun initializeCustomTheme() {
    CustomThemeHelper.initialize(application)
}

private fun initializeNightMode() {
    NightModeHelper.initialize(application)
}

private fun createNotificationChannels() {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
        notificationManager.createNotificationChannels(
            listOf(
                backgroundActivityStartNotificationTemplate.channelTemplate,
                fileJobNotificationTemplate.channelTemplate
            ).map { it.create(application) }
        )
    }
}
