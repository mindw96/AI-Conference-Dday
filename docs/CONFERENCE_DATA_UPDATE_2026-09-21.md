# Conference catalog update — 2026-09-21

공식 CFP와 일정표를 2026-09-21에 확인했습니다. 학회 7개를 추가하여 총 41개,
마감·발표·행사 일정은 총 240개입니다. 기존 학회 14개의 출처를 재확인했습니다.
기존 학회 및 마감 ID는 모두 유지하여 저장된 선택 항목이 계속 연결되도록 했습니다.

## 새로 추가한 2027년 학회

아래 제출 마감은 모두 **23:59 AoE (UTC−12)** 기준입니다. 한국에서는 다음 날
20:59입니다. 발표일은 공식 페이지에 시각이 따로 없는 경우 `time: null`로 저장했습니다.
행사 날짜에는 개최지의 IANA 시간대를 사용합니다.

| 학회 | 초록 / ARR 제출 | 본문 / 학회 commitment | 행사 일정 및 개최지 | 공식 출처 |
| --- | --- | --- | --- | --- |
| AISTATS 2027 | 초록 2026-09-29 | 본문·보충자료 모두 2026-10-06 | 2027-05-03–06, Montreal | [CFP](https://virtual.aistats.org/Conferences/2027/CallForPapers) |
| ALT 2027 | 별도 초록 마감 없음 | 본문 2026-10-12 | 2027-03-09–12, Leiden | [CFP](https://algorithmiclearningtheory.org/alt2027/call-for-papers/) |
| CVPR 2027 | 논문 등록 2026-11-10 | 본문 2026-11-16, 보충자료 2026-11-23 | 본회의 2027-06-22–25, Seattle | [일정](https://cvpr.thecvf.com/Conferences/2027/Dates), [개최지](https://cvpr.thecvf.com/Conferences/2027) |
| EACL 2027 | ARR August: 2026-08-03 | EACL commitment 2026-10-11 | 2027-03-09–14, Athens | [CFP](https://2027.eacl.org/calls/papers/), [개최지](https://2027.eacl.org/) |
| NAACL 2027 | ARR October: 2026-10-12 | NAACL commitment 2026-12-23 | 2027-06-01–05, San Francisco | [CFP](https://2027.naacl.org/calls/main_conference_papers/) |
| COLING 2027 | ARR October: 2026-10-12 | COLING commitment 2026-12-23 | 현장 행사 2027-05-09–14, Macau | [공식 일정](https://2027.coling-iccl.org/) |
| ICAPS 2027 | 초록 2026-12-07 | 본문 2026-12-14 | 2027-06-27–07-02, Columbia, SC | [CFP](https://icaps27.icaps-conference.org/calls/cfp/) |

추가한 주요 발표일은 AISTATS 2027-01-20, ALT 2027-01-05, CVPR 2027-02-25,
EACL 2026-11-12, NAACL/COLING 2027-02-10, ICAPS 2027-02-26입니다.
EACL camera-ready는 2026-11-26이며, 다른 신규 학회의 미발표 camera-ready 날짜는 넣지 않았습니다.

### NAACL / COLING의 두 단계

- `arr-submission`: 2026-10-12 23:59 AoE → **한국 2026-10-13 20:59**.
- `commitment`: 2026-12-23 23:59 AoE → **한국 2026-12-24 20:59**.
- 앱의 대표 마감은 ARR 논문 제출이며, venue commitment는 별도 선택 가능한 제출 일정입니다.
- 두 학회는 같은 ARR October 주기를 사용합니다. 논문을 심사받은 뒤 commitment 단계에서
  주 학회를 하나 선택하며, 두 곳에 동시에 commitment할 수 없습니다.
  [NAACL의 commitment 안내](https://2027.naacl.org/calls/main_conference_papers/),
  [ARR venue 일정](https://aclrollingreview.org/dates)
- NAACL CFP와 ARR 일정표의 reviewer registration / meta-review 발표일에는 차이가 있어
  해당 부가 일정을 이번 데이터에 넣지 않았습니다. ARR 제출일과 commitment 날짜는 두 출처가 일치합니다.

## 기존 일정 수정

| 학회 | 반영한 수정 | 공식 출처 |
| --- | --- | --- |
| 3DV 2027 | 본문·보충자료의 `11:00 America/Los_Angeles`를 `23:59 AoE`로 수정. 2026-08-28 초록 등록 추가. 발표 일정은 기존 Pacific Time 설정 유지. | [공식 일정](https://3dvconf.github.io/2027/) |
| ACML 2026 | 논문 2026-07-05, 리뷰 공개 2026-08-30, 결과 발표 2026-09-22로 갱신. | [CFP](https://www.acml-conf.org/2026/calls/papers/) |
| AACL-IJCNLP 2026 | 1차 commitment 연장일 2026-08-07 적용, 2차 commitment 2026-08-25 추가. 학회 CFP의 연장 공지가 ARR venue 표보다 구체적이므로 학회 공지를 적용. | [CFP](https://2026.aaclnet.org/calls/main_conference_papers/) |
| EMNLP 2026 | camera-ready를 공식 본회의 CFP와 홈페이지의 2026-08-30로 수정. | [CFP](https://2026.emnlp.org/calls/main_conference_papers/), [홈페이지](https://2026.emnlp.org/) |
| NeurIPS 2026 | Sydney 본회의 12-08–10에 현지 시간대를 적용하고, Atlanta·Paris 본회의 12-09–11을 각 도시의 시간대로 추가. 도시 이름을 함께 표시. | [공식 일정](https://neurips.cc/Conferences/2026/Dates) |
| KDD 2027 | 기존 제출·발표 마감이 Research Track **First Cycle**임을 라벨에 명시. 개최일 2027-08-01–05 재확인. | [CFP](https://kdd2027.kdd.org/research-track-call-for-papers/), [개최 일정](https://kdd2027.kdd.org/) |
| COLM 2026 | 이전 홈페이지에서 현재 `colm.cc` 주소로 출처 갱신. 발표일은 공식 일정표의 현지 날짜로 저장. 기존 행사 종료일 10-09는 워크숍 포함임을 명시. | [공식 일정](https://colm.cc/Conferences/2026/Dates) |
| AAMAS 2027 | 출처 링크를 실제 Main Track CFP로 구체화. | [CFP](https://warwick.ac.uk/fac/sci/dcs/aamas2027/calls/call-for-main-track/) |

기존 날짜가 일치한 [AAAI 2027](https://aaai.org/conference/aaai/aaai-27/main-technical-track-call/),
[ICLR 2027](https://iclr.cc/Conferences/2027/CallForPapers),
[WACV 2027](https://wacv.thecvf.com/Conferences/2027/CallForPapers),
[ACCV 2026](https://accv2026.org/),
[ACM MM 2026](https://2026.acmmm.org/site/important-dates.html),
[BMVC 2026](https://bmvc2026.bmva.org/dates/)도 확인일을 갱신했습니다.
ICLR 2027 본문 마감은 **2026-09-25 23:59 AoE**로 유지됩니다.

## 미확정 항목

- **ACML 2026 camera-ready**: 공식 페이지는 2026-09-29를 제시하면서 변경 예정임을
  알리고 있습니다. 기존 날짜를 유지하고 앱 라벨에 `Pending Revision`을 명시했습니다.
- **SIGIR 2027**: [Full Paper CFP](https://sigir2027.org/pages/submit-full.html)는
  초록 2027-01-14, 본문 2027-01-21 AoE를 **PROPOSED**로 표시합니다. 홈페이지의
  요약보다 구체적인 CFP 상태를 우선하여 이번 확정 카탈로그에는 추가하지 않았습니다.
- **ACL 2027**: [ARR 표](https://aclrollingreview.org/dates)에는 January 2027만 있으며
  [학회 홈페이지](https://2027.aclweb.org/)의 정확한 제출일·commitment는 TBA입니다.
- **ICML, UAI, COLT, ECML PKDD, IJCAI, KR, ICCV, EMNLP, COLM 2027**: 확인한 공식 사이트와
  CFP 검색에서 정확한 2027 본회의 논문 제출 마감을 확인하지 못해 추정 날짜를 넣지 않았습니다.
  이는 발표가 전혀 없다는 단정이 아니라 이번 확인 범위에서의 보류 기록입니다.
- **ICLR 2027 행사**: [일정표](https://iclr.cc/Conferences/2027/Dates)에 본회의
  2027-04-26–28이 있지만 개최지 안내는 TBA여서 개최지 시간대가 필요한 행사 항목은 보류했습니다.
- 취소선으로 제거된 AAAI camera-ready 날짜, 부가 트랙·워크숍별 마감,
  COLING의 별도 가상 행사 일정은 새 본회의 마감으로 섞지 않았습니다.

## 반영 대상과 검증

- 공개 원본 / iOS 리소스: `data/conferences.json`
- macOS 리소스: `Sources/DdayApp/Resources/conferences.json`
- Android 리소스: `Apps/Android/app/src/main/assets/conferences.json`
- JSON 스키마의 필드·필수값·열거형, 날짜·시간·시간대, 고유 ID, 대표 마감 검사 통과:
  41개 학회, 240개 일정, 학회마다 대표 마감 1개.
- 기존 학회와 마감 ID 보존 검사 통과. 확인 범위 밖인 기존 학회 20개는 내용이 동일합니다.
- 현재 `DdayCore` 및 `DdayCoreChecks` 소스를 복사한 임시 SwiftPM 패키지에서
  실제 카탈로그 로딩, 잘못된 데이터 거부, 세 리소스의 바이트 일치, AoE 변환 등
  기존 검증 전체 통과 (`DdayCoreChecks passed`). 외부 UI 의존성인 Sparkle은 검증 패키지에서 제외했습니다.
- NAACL과 COLING의 실제 제출·commitment 데이터에 대한 한국 시간 변환 검사 통과.
  이 데이터 변경에는 SDK 설정이나 앱 로직 변경이 포함되지 않습니다.

기존 설치 앱의 새로고침은 GitHub `main`의 공개 원본을 읽습니다. 로컬 파일 반영과
공개 피드 게시 상태는 구분해야 하며, 파일을 바꾼 것만으로 기존 설치 앱에 배포되지는 않습니다.
