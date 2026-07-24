package dev.mindw.dday.ui

import dev.mindw.dday.model.AppLanguage
import dev.mindw.dday.model.ConferenceSubcategory
import dev.mindw.dday.model.WidgetBackground
import dev.mindw.dday.model.WidgetTextColor
import java.util.Locale

class AppStrings(language: AppLanguage) {
    val korean = when (language) {
        AppLanguage.Korean -> true
        AppLanguage.English -> false
        AppLanguage.System -> Locale.getDefault().language == "ko"
    }
    val locale: Locale = if (korean) Locale.KOREAN else Locale.ENGLISH

    val home = if (korean) "홈" else "Home"
    val conferences = if (korean) "학회" else "Conferences"
    val custom = if (korean) "사용자 D-Day" else "Custom"
    val settings = if (korean) "설정" else "Settings"
    val appTitle = "Dday"
    val mainDday = if (korean) "메인 D-Day" else "Main D-Day"
    val upcoming = if (korean) "다가오는 일정" else "Upcoming"
    val chooseMain = if (korean) "메인 D-Day를 선택해 주세요" else "Choose a main D-Day"
    val chooseMainDescription = if (korean) {
        "학회 상세에서 원하는 마감을 메인 D-Day로 설정하면 홈에 표시됩니다."
    } else {
        "Set a deadline as your main D-Day from a conference detail to show it on Home."
    }
    val noUpcoming = if (korean) "다가오는 마감이 없습니다" else "No upcoming deadlines"
    val categories = if (korean) "카테고리" else "Categories"
    val selectedCategories = if (korean) "선택한 카테고리" else "Selected Categories"
    val deadlines = if (korean) "마감일" else "Deadlines"
    val pastConferences = if (korean) "지난 학회" else "Past Conferences"
    val noConferences = if (korean) "학회가 없습니다" else "No conferences"
    val selected = if (korean) "선택됨" else "Selected"
    val setMainDday = if (korean) "메인 D-Day로 설정" else "Set as main D-Day"
    val conferenceWebsite = if (korean) "학회 홈페이지 열기" else "Open conference website"
    val sourcePage = if (korean) "출처 페이지 열기" else "Open source page"
    val addCustom = if (korean) "사용자 D-Day 추가" else "Add Custom D-Day"
    val noCustom = if (korean) "추가한 사용자 D-Day가 없습니다" else "No custom D-Days"
    val name = if (korean) "이름" else "Name"
    val label = if (korean) "라벨" else "Label"
    val date = if (korean) "날짜" else "Date"
    val time = if (korean) "시간" else "Time"
    val timezone = if (korean) "타임존" else "Timezone"
    val localTimezone = if (korean) "로컬 타임존" else "Local timezone"
    val save = if (korean) "저장" else "Save"
    val cancel = if (korean) "취소" else "Cancel"
    val delete = if (korean) "삭제" else "Delete"
    val addToCalendar = if (korean) "캘린더에 추가" else "Add to Calendar"
    val calendarUnavailable = if (korean) "캘린더 앱을 열 수 없습니다." else "No Calendar app is available."
    val conferencePeriod = if (korean) "학회 기간" else "Conference Period"
    val localTime = if (korean) "현지 시간" else "Local Time"
    val sourceTime = if (korean) "원본 시간" else "Source Time"
    val conferenceWebsiteLabel = if (korean) "학회 홈페이지" else "Conference Website"
    val language = if (korean) "언어" else "Language"
    val system = if (korean) "시스템" else "System"
    val english = if (korean) "영어" else "English"
    val koreanLanguage = if (korean) "한국어" else "Korean"
    val data = if (korean) "데이터" else "Data"
    val checkUpdates = if (korean) "학회 목록 업데이트 확인" else "Check Conference List Updates"
    val updating = if (korean) "업데이트 중..." else "Updating..."
    val updateSucceeded = if (korean) "학회 목록을 업데이트했습니다." else "Conference list updated."
    val widgetAppearance = if (korean) "위젯 외형" else "Widget Appearance"
    val widgetAppearanceDescription = if (korean) {
        "홈 화면 위젯의 배경색과 글씨색을 선택합니다."
    } else {
        "Choose the Home Screen widget background and text color."
    }
    val background = if (korean) "배경색" else "Background"
    val textColor = if (korean) "글씨색" else "Text Color"
    val auto = if (korean) "자동" else "Auto"
    val white = if (korean) "흰색" else "White"
    val black = if (korean) "검정" else "Black"
    val navy = if (korean) "네이비" else "Navy"
    val privacy = if (korean) "개인정보" else "Privacy"
    val privacyBody = if (korean) {
        "계정, 분석, 추적 없이 로컬 설정과 학회 데이터만 사용합니다. 캘린더 추가는 사용자가 선택한 경우에만 기기에서 처리됩니다."
    } else {
        "No account, analytics, or tracking. Calendar additions are processed on device only when you choose to use them."
    }
    val conferenceDataUnavailable =
        if (korean) "학회 데이터를 불러올 수 없습니다" else "Conference data unavailable"
    val location = if (korean) "장소" else "Location"

    fun updateFailed(message: String): String =
        if (korean) "업데이트 실패: $message" else "Update failed: $message"

    fun categoryTitle(category: ConferenceSubcategory): String =
        when (category) {
            ConferenceSubcategory.MachineLearning ->
                if (korean) "머신러닝" else "Machine Learning"
            ConferenceSubcategory.ComputerVision ->
                if (korean) "컴퓨터 비전" else "Computer Vision"
            ConferenceSubcategory.Nlp -> "NLP"
            ConferenceSubcategory.GeneralAi ->
                if (korean) "일반 AI" else "General AI"
        }

    fun languageTitle(language: AppLanguage): String =
        when (language) {
            AppLanguage.System -> system
            AppLanguage.English -> english
            AppLanguage.Korean -> koreanLanguage
        }

    fun widgetBackgroundTitle(background: WidgetBackground): String =
        when (background) {
            WidgetBackground.System -> system
            WidgetBackground.White -> white
            WidgetBackground.Black -> black
            WidgetBackground.Navy -> navy
        }

    fun widgetTextColorTitle(textColor: WidgetTextColor): String =
        when (textColor) {
            WidgetTextColor.Auto -> auto
            WidgetTextColor.Black -> black
            WidgetTextColor.White -> white
        }
}
