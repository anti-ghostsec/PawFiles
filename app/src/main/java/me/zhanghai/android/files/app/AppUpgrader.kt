/*
 * Copyright (c) 2020 Hai Zhang <dreaming.in.code.zh@gmail.com>
 * All Rights Reserved.
 */

package me.zhanghai.android.files.app

import androidx.core.content.edit
import me.zhanghai.android.files.BuildConfig

private const val KEY_VERSION_CODE = "key_version_code"

private const val VERSION_CODE_LATEST = BuildConfig.VERSION_CODE

private var lastVersionCode: Int
    get() {
        if (defaultSharedPreferences.all.isEmpty()) {
            // This is a new install.
            lastVersionCode = VERSION_CODE_LATEST
            return VERSION_CODE_LATEST
        }
        return defaultSharedPreferences.getInt(KEY_VERSION_CODE, VERSION_CODE_LATEST)
    }
    set(value) {
        defaultSharedPreferences.edit { putInt(KEY_VERSION_CODE, value) }
    }

fun upgradeApp() {
    upgradeAppFrom(lastVersionCode)
    lastVersionCode = VERSION_CODE_LATEST
}

// Files is a new app: there are no older versions' settings to move on.
@Suppress("UNUSED_PARAMETER")
private fun upgradeAppFrom(lastVersionCode: Int) {
    // Continue with `if`s on lastVersionCode when settings change.
}
