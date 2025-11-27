package com.lazyrhythm.hookfy

import android.content.ContentValues
import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper
import android.util.Log

class DatabaseHelper(context: Context) : SQLiteOpenHelper(context, DATABASE_NAME, null, DATABASE_VERSION) {

    companion object {
        private const val DATABASE_NAME = "notifications.db"
        private const val DATABASE_VERSION = 4
        private const val TABLE_NOTIFICATIONS = "notifications"
        private const val TAG = "DatabaseHelper"

        // Column names
        private const val COLUMN_ID = "id"
        private const val COLUMN_PACKAGE_NAME = "package_name"
        private const val COLUMN_APP_NAME = "app_name"
        private const val COLUMN_TITLE = "title"
        private const val COLUMN_TEXT = "text"
        private const val COLUMN_SUB_TEXT = "sub_text"
        private const val COLUMN_BIG_TEXT = "big_text"
        private const val COLUMN_TIMESTAMP = "timestamp"
        private const val COLUMN_KEY = "key"
        private const val COLUMN_WEBHOOK_STATUS = "webhook_status"

        @Volatile
        private var instance: DatabaseHelper? = null

        fun getInstance(context: Context): DatabaseHelper {
            return instance ?: synchronized(this) {
                instance ?: DatabaseHelper(context.applicationContext).also { instance = it }
            }
        }
    }

    override fun onCreate(db: SQLiteDatabase) {
        val createTable = """
            CREATE TABLE $TABLE_NOTIFICATIONS (
                $COLUMN_ID INTEGER PRIMARY KEY AUTOINCREMENT,
                $COLUMN_PACKAGE_NAME TEXT NOT NULL,
                $COLUMN_APP_NAME TEXT NOT NULL,
                $COLUMN_TITLE TEXT NOT NULL,
                $COLUMN_TEXT TEXT NOT NULL,
                $COLUMN_SUB_TEXT TEXT,
                $COLUMN_BIG_TEXT TEXT,
                $COLUMN_TIMESTAMP INTEGER NOT NULL,
                $COLUMN_KEY TEXT,
                $COLUMN_WEBHOOK_STATUS TEXT
            )
        """.trimIndent()

        db.execSQL(createTable)

        // Create indices
        db.execSQL("CREATE INDEX idx_timestamp ON $TABLE_NOTIFICATIONS($COLUMN_TIMESTAMP DESC)")
        db.execSQL("CREATE INDEX idx_package_name ON $TABLE_NOTIFICATIONS($COLUMN_PACKAGE_NAME)")

        Log.d(TAG, "Database created successfully")
    }

    override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) {
        Log.d(TAG, "Upgrading database from version $oldVersion to $newVersion")

        when {
            oldVersion < 4 -> {
                // Add webhook_status column if upgrading from version < 4
                try {
                    db.execSQL("ALTER TABLE $TABLE_NOTIFICATIONS ADD COLUMN $COLUMN_WEBHOOK_STATUS TEXT")
                    Log.d(TAG, "Added webhook_status column")
                } catch (e: Exception) {
                    Log.e(TAG, "Error adding webhook_status column", e)
                }
            }
        }
    }

    fun insertNotification(
        packageName: String,
        appName: String,
        title: String,
        text: String,
        subText: String = "",
        bigText: String = "",
        timestamp: Long,
        key: String = ""
    ): Long {
        return try {
            val db = writableDatabase
            val values = ContentValues().apply {
                put(COLUMN_PACKAGE_NAME, packageName)
                put(COLUMN_APP_NAME, appName)
                put(COLUMN_TITLE, title)
                put(COLUMN_TEXT, text)
                put(COLUMN_SUB_TEXT, subText)
                put(COLUMN_BIG_TEXT, bigText)
                put(COLUMN_TIMESTAMP, timestamp)
                put(COLUMN_KEY, key)
            }

            // Insert all notifications, including duplicates
            val id = db.insert(TABLE_NOTIFICATIONS, null, values)
            Log.d(TAG, "Notification inserted with id: $id")
            id
        } catch (e: Exception) {
            Log.e(TAG, "Error inserting notification", e)
            -1L
        }
    }
}
