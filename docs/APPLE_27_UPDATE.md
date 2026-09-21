# iOS 27 · macOS 27 대응

검증일: 2026-09-20. 작업 저장소: `/Users/mindw/Projects/Dday`.

Apple 공식 문서와 설치된 Xcode 27 SDK를 대조해 앱의 호환성, 접근성, 패키징을 보완했다. 기존 미커밋 변경을 포함한 소스를 임시 로컬 작업 폴더에 복사해 검증한 후, 원본 파일의 SHA-256이 작업 시작 시점과 같은지 확인하고 수정 파일만 반영했다.

## 반영 내용

### iPhone · iPad

- iOS 18 이상에서 타입이 있는 `Tab`과 `sidebarAdaptable` 스타일을 사용한다. iPhone의 시스템 탭과 iPad의 탭·사이드바 전환을 사용하며, 선택 값은 항상 실제로 표시되는 네 개 탭 중 하나다. iOS 17에서는 기존 탭 API로 동작한다.
- 대표 D-Day 숫자가 Dynamic Type 설정을 따라 커지도록 `@ScaledMetric`을 적용했다.
- 캘린더 추가 버튼과 그룹 펼침 버튼의 터치 영역을 최소 44pt로 확대했다. 그룹 펼침 애니메이션은 ‘동작 줄이기’를 따른다.
- 앱의 scene manifest 생성을 명시했다. 기존 launch screen 설정을 유지하고, 실제 빌드 결과에 launch screen과 scene manifest가 포함되는지 자동으로 검사한다.
- 빌드 산출물 검사에 캘린더 권한 설명, 앱·위젯 버전 일치, WidgetKit 메타데이터, 앱과 위젯의 UserDefaults/App Group 개인정보 선언을 포함했다. CI에서 같은 검사를 실행한다.

### macOS

- 메뉴 막대 배지를 `NSImage.lockFocus()` 대신 drawing handler로 그려 화면 배율에 맞춰 렌더링한다.
- 메뉴 막대 버튼과 미리보기의 실제 밝음·어두움 모양이 바뀌면 이미지를 갱신한다. 접근성 표시 설정 변경도 즉시 반영한다.
- ‘투명도 줄이기’에서는 배지 배경을 불투명하게 만든다. ‘대비 증가’에서는 불투명 배경과 대비가 높은 흑백 글씨를 사용한다. 일반 모드에서는 사용자가 지정한 색상과 투명 스타일을 유지한다.
- Swift 6.4의 빌드 출력 경로를 고정해서 가정하지 않고 `--show-bin-path`로 찾는다. AppKit 검사도 SwiftPM 내부 오브젝트 경로에 의존하지 않는다.
- Swift의 링커 드라이버에 SDK 경로를 명시적으로 전달한다. 이 환경에서는 `--sysroot`만 전달할 때 최종 Mach-O의 SDK 값이 배포 대상 버전인 13.0으로 기록되었다. Clang에 `-isysroot`를 전달한 뒤 `minos 13.0 / sdk 27.0`을 확인했다.
- `script/build_and_run.sh`와 Codex Run 동작을 추가했다. `--verify`는 저장된 Sparkle 설정을 바꾸지 않고 자동 업데이트를 비활성화한 상태로 로컬 실행을 확인한다.

## Apple 문서와 적용 판단

- [iOS & iPadOS 27 Release Notes](https://developer.apple.com/documentation/ios-ipados-release-notes/ios-ipados-27-release-notes): SDK 27 빌드의 launch screen 요구, 보이는 탭만 선택해야 하는 `TabView` 조건, 새로운 `@State` 동작을 확인했다. 현재 코드에는 `@State`의 초기화 방식 때문에 필요한 추가 마이그레이션이 없었다.
- [macOS 27 Release Notes](https://developer.apple.com/documentation/macos-release-notes/macos-27-release-notes), [Menus HIG](https://developer.apple.com/design/human-interface-guidelines/menus): 메뉴 이미지 노출 축소를 검토했다. 현재 AppKit 메뉴는 텍스트와 체크 표시로 동작하므로 아이콘 강제 표시를 추가하지 않았다.
- [Adopting Liquid Glass](https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass): 표준 탭, 내비게이션, 컨트롤을 최신 SDK로 빌드해 시스템 표현을 따르게 했다. 메뉴 막대의 사용자 색상 배지는 별도 렌더러다.
- [Accessibility HIG](https://developer.apple.com/design/human-interface-guidelines/accessibility): Dynamic Type, 터치 영역, 동작 줄이기, 대비와 투명도 설정을 반영했다.
- [Xcode 27 Release Notes](https://developer.apple.com/documentation/xcode-release-notes/xcode-27-release-notes): 설치된 Xcode와 Swift 도구 체인 변경을 확인했다. `NSImage` 교체는 설치 SDK의 AppKit `NSImage.h`에 있는 비권장 안내와 drawing handler 설명도 확인했다.

## 검증 결과

환경: macOS 27.0(26A428), Xcode 27.0(27A266a), Swift 6.4, iOS/macOS SDK 27.0. iOS SDK 빌드는 24A430, 추가 설치 후 검증한 iOS 27 시뮬레이터 빌드는 24A434다.

| 항목 | 결과 |
| --- | --- |
| DdayCoreChecks | 통과 |
| 모바일 모델·알림 회귀 검사 | 10/10 통과 |
| macOS 메뉴 회귀 검사 | 18/18 통과 |
| macOS 배지 접근성·2배율 렌더링 검사 | 10/10 통과 |
| macOS Debug 및 Release 빌드 | 통과 |
| macOS 27에서 로컬 앱 실행·서명 검사 | 통과, 로컬 ad-hoc 서명 |
| macOS 실행 파일 SDK / 최소 OS | 27.0 / 13.0 |
| iOS 27 SDK 기기용 Release 앱·위젯 빌드 | 통과, 배포 서명 생략 |
| iOS 27 SDK 시뮬레이터용 Debug 앱·위젯 빌드 | 통과 |
| 실제 iOS 앱·위젯 번들 요구사항 검사 | 기기용·시뮬레이터용 모두 통과 |
| iPhone 17 Pro, iOS 26.5 UI 검사 | 탭 4개 이동·일정 추가 시트 1/1 통과 |
| iPhone 최대 접근성 글씨·다크 모드·고대비 | 대표 일정 선택과 배지 표시 1/1 통과, 화면 직접 확인 |
| iPad Pro 11 M5, iPadOS 26.5 UI 검사 | 탭 4개 이동·일정 추가 시트 1/1 통과 |
| iPhone 17 Pro, iOS 27.0 UI 검사 | 탭 4개 이동·일정 추가 시트 1/1 통과 |
| iPhone iOS 27.0 최대 접근성 글씨·다크 모드·고대비 | 대표 일정 선택과 배지 표시 1/1 통과, 화면 직접 확인 |
| iPad Pro 11 M5, iPadOS 27.0 UI 검사 | 탭 4개 이동·일정 추가 시트·사이드바 열기/닫기 1/1 통과 |

배지 대비 검사는 밝음·어두움 각각 64가지 사용자 배경색을 검사해 4.5:1 이상을 확인한다. 보장 대상은 ‘대비 증가’를 켠 불투명 모드다. 일반 투명 모드는 실제 바탕화면에 따라 대비가 달라질 수 있다.

iOS 27 iPad 검사의 첫 시도는 XCTest runner가 준비 중 종료되었다. 단독 재실행에서 앱 화면은 정상 동작했고, 추가한 사이드바 검사에서는 열기와 닫기 버튼의 서로 다른 시스템 식별자(`ToggleSideBar` / `ToggleSidebar`)를 반영해야 했다. 검사 코드를 보정한 최종 실행은 통과했으며, 이 과정에서 앱 소스의 추가 변경은 없었다. 이전 실패 로그와 최종 통과 결과를 함께 보관한다.

검증 로그, UI 검사 소스·결과, 화면과 빌드 정보는 로컬 `dist/apple-27/2026-09-20/`에 보관한다. 이 경로는 Git에서 제외된다. 작업 전 파일 백업과 반영 전후 해시도 함께 보관한다.

## 검증 범위와 출시

- 최소 지원 버전은 iOS 17 / macOS 13을 유지했다. 이 두 최소 버전의 실제 기기·런타임 실행은 이번에 수행하지 않았다.
- iOS/iPadOS 26.5와 27.0 시뮬레이터에서 앱 실행과 주요 화면을 검증했다. 물리 iPhone·iPad에서의 실행 검증은 별도다.
- 위젯 빌드·메타데이터와 기존 저장소 검사는 통과했다. 이번 UI 검사는 앱에 한정되며, 홈 화면 위젯 갱신과 실제 알림·캘린더 권한 동작을 입증하지 않는다.
- iOS 앱 버전은 기존 1.1.0(3)을 유지했다. macOS 검증 번들은 `Support/Info.plist`의 개발용 기본 버전으로 만들었으며 배포용 버전 번호를 정한 산출물이 아니다. 정식 macOS 패키징은 기존 `APP_VERSION` / `APP_BUILD_VERSION` 설정을 사용한다.
- 이번 작업은 코드·로컬 빌드 검증이며 App Store Connect 업로드, Developer ID 배포 서명, 공증, Sparkle 업데이트 게시를 수행하지 않았다.

## 재검증 명령

```bash
swift build --product DdayCoreChecks
"$(swift build --show-bin-path)/DdayCoreChecks"
bash Apps/Mobile/Checks/run.sh
./scripts/check_macos_menu.sh
./script/build_and_run.sh --verify
xcrun vtool -show-build build/Dday.app/Contents/MacOS/Dday

xcodebuild -project Apps/Mobile/DdayMobile.xcodeproj \
  -scheme DdayMobile -configuration Release \
  -destination 'generic/platform=iOS' -derivedDataPath build/iOS27 \
  CODE_SIGNING_ALLOWED=NO build
python3 scripts/check_ios_bundle.py build/iOS27/Build/Products/Release-iphoneos/DdayMobile.app
```
