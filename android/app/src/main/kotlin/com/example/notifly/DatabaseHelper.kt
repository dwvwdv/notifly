package com.example.notifly

import android.content.ContentValues
import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper
import android.util.Log

class DatabaseHelper(context: Context) : SQLiteOpenHelper(context, DATABASE_NAME, null, DATABASE_VERSION) {

    companion object {
        private const val DATABASE_NAME = "notifications.db"
        private const val DATABASE_VERSION = 3
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
                $COLUMN_KEY TEXT
            )
        """.trimIndent()

        db.execSQL(createTable)

        // Create indices
        db.execSQL("CREATE INDEX idx_timestamp ON $TABLE_NOTIFICATIONS($COLUMN_TIMESTAMP DESC)")
        db.execSQL("CREATE INDEX idx_package_name ON $TABLE_NOTIFICATIONS($COLUMN_PACKAGE_NAME)")

        Log.d(TAG, "Database created successfully")
    }

    override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) {
        db.execSQL("DROP TABLE IF EXISTS $TABLE_NOTIFICATIONS")
        onCreate(db)
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
