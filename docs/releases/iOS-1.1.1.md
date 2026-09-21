# AI Conference Dday 1.1.1

Build: 4. Minimum OS: iOS / iPadOS 17.

## 새로운 기능 — 한국어

- iOS 27과 iPadOS 27에 맞춰 시스템 탭과 iPad 사이드바 사용 경험을 개선했습니다.
- 큰 글씨 설정에 맞춰 D-Day 숫자가 조절되며, 주요 버튼의 터치 영역과 ‘동작 줄이기’ 지원을 개선했습니다.
- 알림을 가까운 일정부터 예약하고, 앱으로 돌아올 때 일정·알림·위젯 데이터를 갱신하도록 개선했습니다.
- 학회 데이터를 불러오지 못해도 저장된 사용자 D-Day를 확인할 수 있도록 수정했습니다.
- NAACL 2027 등 새로 발표된 AI 학회 마감일을 추가하고 기존 일정을 갱신했습니다.

## What's New — English

- Improved system tabs and the iPad sidebar for iOS 27 and iPadOS 27.
- Added better support for larger text, larger touch targets, and Reduce Motion.
- Improved reminder scheduling to prioritize upcoming deadlines and refresh deadline, reminder, and widget data when returning to the app.
- Fixed access to saved custom deadlines when the conference catalog cannot be loaded.
- Added newly announced AI conference deadlines, including NAACL 2027, and refreshed existing dates.

## App Review notes

This update improves compatibility and accessibility for iOS 27 and iPadOS 27 and fixes deadline selection, data recovery, and local reminder scheduling. No account or sign-in is required. Conference deadlines are loaded from the app's public GitHub catalog, with a bundled offline fallback. Custom deadlines, preferences, and local reminder settings are stored on the device and shared with the app's WidgetKit extension through an App Group. Calendar access is requested only when the user chooses to add a deadline to their calendar.
