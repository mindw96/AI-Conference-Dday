import DdayCore
import Foundation

struct MobileAppText {
    let language: AppLanguage

    private var korean: Bool {
        switch language {
        case .korean:
            return true
        case .english:
            return false
        case .system:
            return Locale.preferredLanguages.first?.hasPrefix("ko") ?? false
        }
    }

    var homeTab: String { korean ? "홈" : "Home" }
    var conferencesTab: String { korean ? "학회" : "Conferences" }
    var customTab: String { korean ? "사용자 D-Day" : "Custom" }
    var settingsTab: String { korean ? "설정" : "Settings" }

    var homeTitle: String { "Dday" }
    var mainDeadline: String { korean ? "메인 D-Day" : "Main D-Day" }
    var upcoming: String { korean ? "다가오는 일정" : "Upcoming" }
    var noMainDday: String { korean ? "메인 D-Day를 선택해 주세요" : "Choose a main D-Day" }
    var noMainDdayDescription: String {
        korean
            ? "학회 상세에서 원하는 마감을 메인 D-Day로 설정하면 홈과 위젯에 표시됩니다."
            : "Set a deadline as your main D-Day from a conference detail to show it on Home and widgets."
    }
    var noUpcomingDeadlines: String { korean ? "다가오는 마감이 없습니다" : "No upcoming deadlines" }
    var conferenceDataUnavailable: String { korean ? "학회 데이터를 불러올 수 없습니다" : "Conference data unavailable" }

    var categories: String { korean ? "카테고리" : "Categories" }
    var selectedCategories: String { korean ? "선택한 카테고리" : "Selected Categories" }
    var deadlines: String { korean ? "마감일" : "Deadlines" }
    var upcomingConferences: String { korean ? "다가오는 학회" : "Upcoming" }
    var pastConferences: String { korean ? "지난 학회" : "Past Conferences" }
    var noConferences: String { korean ? "학회가 없습니다" : "No conferences" }
    var selected: String { korean ? "선택됨" : "Selected" }
    var setMainDday: String { korean ? "메인 D-Day로 설정" : "Set as main D-Day" }
    var openConferenceWebsite: String { korean ? "학회 홈페이지 열기" : "Open conference website" }
    var openSourcePage: String { korean ? "출처 페이지 열기" : "Open source page" }

    var customTitle: String { korean ? "사용자 D-Day" : "Custom D-Day" }
    var addCustomDday: String { korean ? "사용자 D-Day 추가" : "Add Custom D-Day" }
    var noCustomDeadlines: String { korean ? "추가한 사용자 D-Day가 없습니다" : "No custom D-Days" }
    var name: String { korean ? "이름" : "Name" }
    var label: String { korean ? "라벨" : "Label" }
    var date: String { korean ? "날짜" : "Date" }
    var timezone: String { korean ? "타임존" : "Timezone" }
    var localTimezone: String { korean ? "로컬 타임존" : "Local timezone" }
    var save: String { korean ? "저장" : "Save" }
    var cancel: String { korean ? "취소" : "Cancel" }
    var delete: String { korean ? "삭제" : "Delete" }
    var ok: String { korean ? "확인" : "OK" }
    var addToCalendar: String { korean ? "캘린더에 추가" : "Add to Calendar" }
    var calendarEventAdded: String { korean ? "캘린더에 추가했습니다." : "Added to Calendar." }
    var calendarAccessDenied: String {
        korean
            ? "캘린더 권한이 허용되지 않았습니다. iOS 설정에서 Dday 캘린더 접근을 허용해 주세요."
            : "Calendar access was not granted. Please allow Dday calendar access in iOS Settings."
    }
    var calendarEventAddFailed: String { korean ? "캘린더 추가 실패" : "Could not add to Calendar" }
    var conferencePeriod: String { korean ? "학회 기간" : "Conference Period" }
    var localTime: String { korean ? "로컬 시간" : "Local Time" }
    var sourceTime: String { korean ? "원본 시간" : "Source Time" }
    var conferenceWebsite: String { korean ? "학회 홈페이지" : "Conference Website" }

    var languageLabel: String { korean ? "언어" : "Language" }
    var systemLanguage: String { korean ? "시스템" : "System" }
    var english: String { korean ? "영어" : "English" }
    var koreanLanguage: String { korean ? "한국어" : "Korean" }
    var data: String { korean ? "데이터" : "Data" }
    var checkConferenceListUpdates: String { korean ? "학회 목록 업데이트 확인" : "Check Conference List Updates" }
    var updating: String { korean ? "업데이트 중..." : "Updating..." }
    var updateSucceeded: String { korean ? "학회 목록을 업데이트했습니다." : "Conference list updated." }
    var widgetAppearance: String { korean ? "위젯 외형" : "Widget Appearance" }
    var widgetBackground: String { korean ? "배경색" : "Background" }
    var widgetTextColor: String { korean ? "글씨색" : "Text Color" }
    var widgetGlassTint: String { korean ? "글래스 색상" : "Glass Tint" }
    var widgetCustomTextColor: String { korean ? "사용자 지정 글씨색" : "Custom Text Color" }
    var chooseColor: String { korean ? "색상 선택" : "Choose Color" }
    var rgbValues: String { "RGB" }
    var widgetAppearanceDescription: String {
        korean
            ? "전체 색상 모드에서는 절제된 글래스 색상과 글씨색을 RGB로 조정할 수 있습니다. iOS 26의 투명·틴트 모드에서는 시스템 Liquid Glass 외형을 따릅니다."
            : "Customize the subtle glass tint and text color with RGB values in Full Color mode. Clear and Tinted appearances follow the system Liquid Glass style on iOS 26."
    }
    var notifications: String { korean ? "알림" : "Notifications" }
    var enableNotifications: String { korean ? "마감 알림 켜기" : "Enable deadline reminders" }
    var notificationDescription: String {
        korean
            ? "홈과 위젯에 보이는 메인 D-Day와 사용자 D-Day에 대해 7일 전, 3일 전, 1일 전, 당일 알림을 예약합니다."
            : "Schedules reminders for the main D-Day shown on Home/widgets and custom D-Days at 7 days, 3 days, 1 day, and deadline day."
    }
    var notificationPermissionDenied: String {
        korean
            ? "알림 권한이 허용되지 않았습니다. iOS 설정에서 Dday 알림을 허용해 주세요."
            : "Notification permission was not granted. Please allow Dday notifications in iOS Settings."
    }
    var notificationsDisabled: String { korean ? "알림을 껐습니다." : "Notifications disabled." }
    var noNotificationsToSchedule: String {
        korean
            ? "예약할 예정 마감이 없습니다."
            : "There are no upcoming deadlines to schedule."
    }
    var privacy: String { korean ? "개인정보" : "Privacy" }
    var privacyBody: String {
        korean
            ? "계정, 분석, 추적 없이 로컬 설정과 학회 데이터만 사용합니다. 알림과 캘린더 추가는 사용자가 선택한 경우에만 기기에서 처리되며 외부로 전송되지 않습니다."
            : "No account, analytics, or tracking. Notifications and Calendar additions are processed on device only when you choose to use them, and are not sent anywhere."
    }

    func updateFailed(_ message: String) -> String {
        korean ? "업데이트 실패: \(message)" : "Update failed: \(message)"
    }

    func notificationsScheduled(_ count: Int) -> String {
        korean ? "\(count)개의 알림을 예약했습니다." : "Scheduled \(count) reminders."
    }

    func notificationSchedulingFailed(_ message: String) -> String {
        korean ? "알림 예약 실패: \(message)" : "Reminder scheduling failed: \(message)"
    }

    func languageTitle(_ language: AppLanguage) -> String {
        switch language {
        case .system:
            return systemLanguage
        case .english:
            return english
        case .korean:
            return koreanLanguage
        }
    }

    func widgetBackgroundTitle(_ background: MobileWidgetBackground) -> String {
        switch background {
        case .system:
            return korean ? "시스템" : "System"
        case .glass:
            return korean ? "글래스" : "Glass"
        case .white:
            return korean ? "흰색" : "White"
        case .black:
            return korean ? "검정" : "Black"
        case .navy:
            return korean ? "네이비" : "Navy"
        }
    }

    func widgetTextColorTitle(_ textColor: MobileWidgetTextColor) -> String {
        switch textColor {
        case .automatic:
            return korean ? "자동" : "Auto"
        case .black:
            return korean ? "검정" : "Black"
        case .white:
            return korean ? "흰색" : "White"
        case .custom:
            return korean ? "사용자 지정" : "Custom"
        }
    }

    func subcategoryTitle(_ subcategory: ConferenceSubcategory) -> String {
        switch subcategory {
        case .ml:
            return korean ? "머신러닝" : "Machine Learning"
        case .cv:
            return korean ? "컴퓨터 비전" : "Computer Vision"
        case .nlp:
            return "NLP"
        case .generalAI:
            return korean ? "일반 AI" : "General AI"
        }
    }
}
