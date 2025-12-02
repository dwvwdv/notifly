package com.lazyrhythm.hookfy

import android.util.Log
import org.json.JSONArray
import org.json.JSONObject

/**
 * 通知數據類
 */
data class NotificationData(
    val packageName: String,
    val appName: String,
    val title: String,
    val text: String,
    val subText: String,
    val bigText: String
)

/**
 * 匹配結果
 */
data class MatchResult(
    val matched: Boolean,
    val extractedFields: Map<String, String> = emptyMap()
)

/**
 * 過濾條件匹配器
 * 負責根據配置的規則匹配通知並提取 placeholder
 */
class FilterMatcher {

    companion object {
        private const val TAG = "FilterMatcher"

        /**
         * 檢查通知是否匹配任一過濾規則
         * @return MatchResult 包含是否匹配和提取的字段
         */
        fun matchNotification(
            notification: NotificationData,
            filterRules: List<FilterRule>
        ): MatchResult {
            // 如果沒有配置規則，默認匹配所有通知
            if (filterRules.isEmpty()) {
                return MatchResult(matched = true)
            }

            // 遍歷所有規則，找到第一個匹配的規則
            for (rule in filterRules) {
                if (!rule.enabled) {
                    continue
                }

                // 檢查所有條件是否滿足（AND 邏輯）
                val allConditionsMet = rule.conditions.all { condition ->
                    matchCondition(notification, condition)
                }

                if (allConditionsMet) {
                    // 提取 placeholders
                    val extractedFields = extractPlaceholders(notification, rule.extractors)
                    Log.d(TAG, "Notification matched rule: ${rule.name}, extracted: $extractedFields")
                    return MatchResult(matched = true, extractedFields = extractedFields)
                }
            }

            // 沒有匹配任何規則
            Log.d(TAG, "Notification did not match any rules")
            return MatchResult(matched = false)
        }

        /**
         * 匹配單個條件
         */
        private fun matchCondition(
            notification: NotificationData,
            condition: FilterCondition
        ): Boolean {
            val fieldValue = getFieldValue(notification, condition.field)
            val targetValue = condition.value

            return when (condition.operator) {
                "contains" -> fieldValue.contains(targetValue, ignoreCase = false)
                "notContains" -> !fieldValue.contains(targetValue, ignoreCase = false)
                "equals" -> fieldValue.equals(targetValue, ignoreCase = false)
                "notEquals" -> !fieldValue.equals(targetValue, ignoreCase = false)
                "startsWith" -> fieldValue.startsWith(targetValue, ignoreCase = false)
                "endsWith" -> fieldValue.endsWith(targetValue, ignoreCase = false)
                "matches" -> {
                    try {
                        fieldValue.matches(Regex(targetValue))
                    } catch (e: Exception) {
                        Log.e(TAG, "Invalid regex pattern: $targetValue", e)
                        false
                    }
                }
                else -> {
                    Log.w(TAG, "Unknown operator: ${condition.operator}")
                    false
                }
            }
        }

        /**
         * 根據字段名獲取通知的字段值
         */
        private fun getFieldValue(notification: NotificationData, field: String): String {
            return when (field) {
                "packageName" -> notification.packageName
                "appName" -> notification.appName
                "title" -> notification.title
                "text" -> notification.text
                "subText" -> notification.subText
                "bigText" -> notification.bigText
                else -> {
                    Log.w(TAG, "Unknown field: $field")
                    ""
                }
            }
        }

        /**
         * 提取 placeholders
         */
        private fun extractPlaceholders(
            notification: NotificationData,
            extractors: List<PlaceholderExtractor>
        ): Map<String, String> {
            val result = mutableMapOf<String, String>()

            for (extractor in extractors) {
                try {
                    val sourceValue = getFieldValue(notification, extractor.sourceField)
                    val regex = Regex(extractor.pattern)
                    val matchResult = regex.find(sourceValue)

                    if (matchResult != null) {
                        val groupIndex = extractor.group.coerceIn(0, matchResult.groupValues.size - 1)
                        val extractedValue = matchResult.groupValues[groupIndex]
                        result[extractor.name] = extractedValue
                        Log.d(TAG, "Extracted ${extractor.name}: $extractedValue")
                    } else {
                        Log.d(TAG, "No match found for extractor: ${extractor.name}")
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Error extracting placeholder: ${extractor.name}", e)
                }
            }

            return result
        }

        /**
         * 從 JSON 解析過濾規則列表
         */
        fun parseFilterRules(jsonArray: JSONArray): List<FilterRule> {
            val rules = mutableListOf<FilterRule>()

            for (i in 0 until jsonArray.length()) {
                try {
                    val ruleJson = jsonArray.getJSONObject(i)
                    val rule = FilterRule.fromJson(ruleJson)
                    rules.add(rule)
                } catch (e: Exception) {
                    Log.e(TAG, "Error parsing filter rule at index $i", e)
                }
            }

            return rules
        }
    }
}

/**
 * 過濾條件
 */
data class FilterCondition(
    val field: String,
    val operator: String,
    val value: String
) {
    companion object {
        fun fromJson(json: JSONObject): FilterCondition {
            return FilterCondition(
                field = json.getString("field"),
                operator = json.getString("operator"),
                value = json.getString("value")
            )
        }
    }
}

/**
 * Placeholder 提取器
 */
data class PlaceholderExtractor(
    val name: String,
    val sourceField: String,
    val pattern: String,
    val group: Int
) {
    companion object {
        fun fromJson(json: JSONObject): PlaceholderExtractor {
            return PlaceholderExtractor(
                name = json.getString("name"),
                sourceField = json.getString("sourceField"),
                pattern = json.getString("pattern"),
                group = json.optInt("group", 1)
            )
        }
    }
}

/**
 * 過濾規則
 */
data class FilterRule(
    val id: String,
    val name: String,
    val enabled: Boolean,
    val conditions: List<FilterCondition>,
    val extractors: List<PlaceholderExtractor>
) {
    companion object {
        fun fromJson(json: JSONObject): FilterRule {
            val conditions = mutableListOf<FilterCondition>()
            val conditionsArray = json.optJSONArray("conditions")
            if (conditionsArray != null) {
                for (i in 0 until conditionsArray.length()) {
                    conditions.add(FilterCondition.fromJson(conditionsArray.getJSONObject(i)))
                }
            }

            val extractors = mutableListOf<PlaceholderExtractor>()
            val extractorsArray = json.optJSONArray("extractors")
            if (extractorsArray != null) {
                for (i in 0 until extractorsArray.length()) {
                    extractors.add(PlaceholderExtractor.fromJson(extractorsArray.getJSONObject(i)))
                }
            }

            return FilterRule(
                id = json.getString("id"),
                name = json.getString("name"),
                enabled = json.optBoolean("enabled", true),
                conditions = conditions,
                extractors = extractors
            )
        }
    }
}
