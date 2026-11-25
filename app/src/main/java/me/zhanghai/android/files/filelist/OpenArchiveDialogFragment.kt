package me.zhanghai.android.files.filelist

import android.app.Dialog
import android.os.Bundle
import android.widget.CheckBox
import android.widget.FrameLayout
import androidx.appcompat.app.AppCompatDialogFragment
import androidx.fragment.app.Fragment
import com.google.android.material.dialog.MaterialAlertDialogBuilder
import kotlinx.parcelize.Parcelize
import me.zhanghai.android.files.R
import me.zhanghai.android.files.file.FileItem
import me.zhanghai.android.files.settings.Settings
import me.zhanghai.android.files.util.ParcelableArgs
import me.zhanghai.android.files.util.args
import me.zhanghai.android.files.util.putArgs
import me.zhanghai.android.files.util.show

/**
 * Asks whether to browse an archive here or open it with another app (such
 * as Archives), and can remember the answer (Settings, "Open archive").
 */
class OpenArchiveDialogFragment : AppCompatDialogFragment() {
    private val args by args<Args>()

    private val listener: Listener
        get() = requireParentFragment() as Listener

    override fun onCreateDialog(savedInstanceState: Bundle?): Dialog {
        val context = requireContext()
        val remember = CheckBox(context).apply {
            id = R.id.open_archive_remember
            setText(R.string.file_open_archive_remember)
        }
        val padding = resources.getDimensionPixelSize(R.dimen.dialog_padding_minus_4dp)
        val box = FrameLayout(context).apply {
            setPadding(padding, padding / 2, padding, 0)
            addView(remember)
        }
        return MaterialAlertDialogBuilder(context, theme)
            .setMessage(R.string.file_open_archive_message)
            .setView(box)
            .setPositiveButton(R.string.file_open_archive_browse) { _, _ ->
                if (remember.isChecked) {
                    Settings.OPEN_ARCHIVE_DEFAULT_ACTION.putValue(OpenArchiveDefaultAction.BROWSE)
                }
                listener.browseArchive(args.file)
            }
            .setNegativeButton(R.string.file_open_archive_open_with) { _, _ ->
                if (remember.isChecked) {
                    Settings.OPEN_ARCHIVE_DEFAULT_ACTION.putValue(
                        OpenArchiveDefaultAction.OPEN_WITH
                    )
                }
                listener.openArchiveWithApp(args.file)
            }
            .setNeutralButton(android.R.string.cancel, null)
            .create()
    }

    companion object {
        fun show(file: FileItem, fragment: Fragment) {
            OpenArchiveDialogFragment().putArgs(Args(file)).show(fragment)
        }
    }

    @Parcelize
    class Args(val file: FileItem) : ParcelableArgs

    interface Listener {
        fun browseArchive(file: FileItem)
        fun openArchiveWithApp(file: FileItem)
    }
}
