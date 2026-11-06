# Conference data update — 2026-11-07

2026년 11월 7일 기준 공식 CFP·일정표·프로그램을 대조했습니다.
공개 목록을 **43개 학회·250개 일정 → 45개 학회·264개 일정**으로 갱신합니다.
기존 23개 학회를 재확인했고, 나머지 20개 학회는 변경하지 않았습니다.

## 신규 학회

| 학회 | 확정된 제출 일정 | 행사 | 공식 근거 |
| --- | --- | --- | --- |
| COLT 2027 | 본문 2027-01-29 AoE | 도쿄 2027-06-28–07-02, `Asia/Tokyo` | [CFP](https://learningtheory.org/colt2027/cfp.html), [홈페이지](https://learningtheory.org/colt2027/) |
| SIGIR 2027 | 초록 2027-01-14, 본문 01-21, 결과 04-05, 최종본 04-30, 모두 AoE | San Jose 2027-07-19–24, `America/Los_Angeles` | [Full Paper CFP](https://sigir2027.org/pages/submit-full.html), [홈페이지](https://sigir2027.org/) |

SIGIR CFP의 기존 `PROPOSED` 표시가 사라져 확정 목록에 추가했습니다.
COLT 결과 발표는 CFP에 '5월 3일 또는 그 이전'으로 명시되어 있고 별도 시간대가 없습니다.
예상 rebuttal 기간과 함께 기록으로만 남기고, 확정 카운트다운에는 추가하지 않았습니다.

새 COLT·SIGIR 일정과 NeurIPS 최종본 마감은 공식 페이지에 날짜·AoE만 있어 `time: null`로 저장합니다.
앱의 기존 날짜 전용 계산은 해당 시간대 23:59를 사용합니다. 이 계산 기준으로 COLT 제출은
한국 시간 2027-01-30 20:59, SIGIR 초록·본문은 각각 01-15·01-22 20:59입니다.
이는 별도의 공식 시각 발표를 의미하지 않습니다.

## 기존 학회 변경

| 학회 | 반영 사항 | 공식 근거 |
| --- | --- | --- |
| ACML 2026 | 미확정으로 제거했던 `camera-ready` 복원: **2026-11-01 23:59 AoE**. Conference Track임을 표시. | [CFP](https://www.acml-conf.org/2026/calls/papers/) |
| NeurIPS 2026 | `camera-ready` **2026-11-06 AoE** 추가. 앱 날짜 전용 계산 기준 한국 시간 11-07 20:59. | [Dates](https://neurips.cc/Conferences/2026/Dates) |
| NAACL 2027 | `meta-reviews-released` **2026-12-18 AoE** 추가. 공개 시각은 명시되지 않아 `time: null`. | [Main Conference CFP](https://2027.naacl.org/calls/main_conference_papers/) |
| IJCAI 2027 | `phase-1-notification` **2027-02-25**, `camera-ready` **2027-05-07**, 모두 **23:59 AoE** 추가. `sourceUrl`을 상세 CFP로 변경. | [Main Track CFP](https://2027.ijcai.org/ijcai-2027-call-for-papers-main-track/) |
| AACL-IJCNLP 2026 | `main-conference-end` **2026-11-10 → 2026-11-08**. 본회의 11-06–08과 워크숍·튜토리얼 11-09–10을 구분. | [CFP](https://2026.aaclnet.org/calls/main_conference_papers/), [프로그램](https://2026.aaclnet.org/program/) |
| 3DV 2027 | 날짜는 유지하고 전체 일정·시각 근거가 있는 전용 일정표로 `sourceUrl` 변경. | [Dates](https://3dvconf.github.io/2027/dates/) |

ACML 최종본 마감은 이미 지난 일정의 확정 기록입니다. Journal Track의 12월 25일과 구분합니다.
NeurIPS [Poster Instructions](https://neurips.cc/Conferences/2026/PosterInstructions)는 camera-ready가 닫혔다고 안내합니다.
공개 일정표의 날짜를 보존하되 현재 제출창이 열려 있다는 의미로 해석하지 않습니다.
모든 기존 학회·일정 ID와 대표 마감은 보존했으며 기존 항목을 삭제하지 않았습니다.

## 재확인 범위

아래 23개 기존 학회의 `sourceCheckedAt`을 `2026-11-07`로 갱신했습니다.
위 표에 명시한 변경 외 기존 날짜·시각·대표 마감은 그대로입니다.

- ML 6개: ACML 2026, NeurIPS 2026, ICLR 2027, AISTATS 2027, ALT 2027, KDD 2027.
- NLP 7개: ACL 2027, NAACL 2027, COLING 2027, EACL 2027, AACL-IJCNLP 2026, EMNLP 2026, COLM 2026.
- CV 6개: CVPR 2027, WACV 2027, 3DV 2027, ACCV 2026, ACM MM 2026, BMVC 2026.
- General AI 4개: AAAI 2027, AAMAS 2027, ICAPS 2027, IJCAI 2027.

[CVPR 2027](https://cvpr.thecvf.com/Conferences/2027/CallForPapers)은 등록 2026-11-10,
본문 11-16, 보충자료 11-23 **23:59 AoE**로 변경이 없습니다.
한국 시간은 각각 **11-11·11-17·11-24 20:59**이며 CFP는 연장이 없다고 명시합니다.

## 보류 및 출처 차이

- [ECAI 2027](https://ecai2027.org/): 본문 2027-04-14, 1차 결과 05-15, 최종 결과 07-15는 발표됐지만
  시간대가 없습니다. 시간대가 필수인 기존 카탈로그에 임의의 AoE·개최지 시간대를 넣지 않았습니다.
- [ICML 2027](https://icml.cc/Conferences/2027/CallForPapers)은 CFP 준비 중,
  [KDD 2027 두 번째 회차](https://kdd2027.kdd.org/frequently-asked-questions/)는 2월만 안내합니다.
- [ECML PKDD 2027](https://ecmlpkdd.org/2027/submissions-journal-track/)의 1월 31일 마감은
  정원에 따라 조기 종료할 수 있는 별도 Journal Track입니다. Research Track 마감으로 넣지 않았습니다.
- ICCV·ACM MM·BMVC·EMNLP·COLM·UAI·ACML·NeurIPS·KR 2027은 이번 조사에서
  정확한 공식 본회의 논문 제출 마감을 확인하지 못해 보류했습니다.
- AAAI Main Track의 취소선 최종본 마감은 추가하지 않았습니다. 특별 트랙의 날짜로 대체하지 않습니다.
- ACM MM 2026 CFP의 오래된 결과 발표일 7월 7일 대신, CFP가 가리키는 전용 일정표의 7월 9일을 유지합니다.
- 3DV 공식 문구의 Pacific/PDT 및 CEST 약어에는 날짜·개최지와의 모호함이 남아 있습니다.
  새로 발표된 변경은 없으므로 기존 `America/Los_Angeles`·`Europe/Athens`를 유지합니다.
- COLING의 별도 온라인 행사, 워크숍·참가 등록·결제 일정은 본회의 기간·논문 제출 마감에 합치지 않았습니다.

## 반영 및 검증

변경 파일은 공개 원본/iOS 리소스 `data/conferences.json`, macOS 리소스
`Sources/DdayApp/Resources/conferences.json`, Android 리소스
`Apps/Android/app/src/main/assets/conferences.json` 및 이 문서입니다.
세 데이터 파일은 바이트 단위로 같고, 앱 코드·데이터 스키마·테스트·설정은 변경하지 않았습니다.

- 실제 `DdayCoreChecks` 실행 통과: 카탈로그 파싱, 공개 피드 스키마, 유효한 날짜·시각·시간대, 중복 ID, 캐시 검증 등.
- 기존 모든 학회·일정 ID와 대표 마감 보존, 재확인하지 않은 20개 학회 내용 보존 확인.
- 학회별 대표 마감 1개, 플랫폼 복사본 일치, 실제 추가 데이터의 한국 시간 변환 확인.

데이터 SHA-256: `d740d68134adbfcf4b4b8e3cc9c6e663de305e4bfe76c79432ab176ffdcc9833`.
공개 `main` 반영 후 기존 앱의 **학회 목록 업데이트 확인**에서 받을 수 있습니다.
