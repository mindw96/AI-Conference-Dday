# Conference data update — 2026-10-13

공식 학회 홈페이지·CFP·일정표를 2026-10-13에 대조했습니다.
기존 41개 학회·240개 일정에서 **43개 학회·250개 일정**으로 갱신합니다.
기존 학회 22개의 출처를 재확인했으며, 확인하지 않은 과거 학회의 확인일은 바꾸지 않았습니다.

## 새로 추가한 학회

제출 마감은 **23:59 AoE (UTC−12)**이며 한국 시간으로 다음 날 20:59입니다.
행사 날짜에는 개최지의 IANA 시간대를 사용합니다.

| 학회 | 제출 및 발표 일정 | 행사 일정 | 공식 출처 |
| --- | --- | --- | --- |
| ACL 2027 | ARR 제출 2027-01-04. Commitment·결과 발표·camera-ready는 아직 TBA이므로 제외. | 교토 본회의 2027-08-20–22, `Asia/Tokyo` | [Main Conference CFP](https://2027.aclweb.org/calls/main/), [개최지](https://2027.aclweb.org/) |
| IJCAI 2027 | 초록 2027-01-04, 본문 2027-01-11, 결과 발표 2027-04-21 | 교토 행사 2027-08-07–13, `Asia/Tokyo` | [공식 홈페이지 및 일정](https://2027.ijcai.org/) |

ACL은 ARR 심사 제출과 학회 commitment가 별개입니다. 새 대표 마감은 ARR 제출입니다.
IJCAI의 8월 15–17일 Hengqin satellite event는 교토 행사 기간에 합치지 않았습니다.

## 기존 일정 변경

| 학회 | 변경 | 공식 근거 |
| --- | --- | --- |
| NAACL 2027 | Camera-ready **2027-03-03 23:59 AoE** 추가 | [Main Conference CFP](https://2027.naacl.org/calls/main_conference_papers/) |
| WACV 2027 | 결과 발표 **2026-10-09 → 2026-10-14 AoE**. 출처 URL을 전용 일정표로 변경. | [Dates](https://wacv.thecvf.com/Conferences/2027/Dates), [홈페이지](https://wacv.thecvf.com/Conferences/2027) |
| AACL-IJCNLP 2026 | Camera-ready **2026-09-30 → 2026-10-02 23:59 AoE** 연장 | [Main Conference CFP](https://2026.aaclnet.org/calls/main_conference_papers/) |
| ECML PKDD 2026 | Research Track camera-ready **2026-06-18 → 2026-06-20 23:59 AoE** 연장 | [Research Track](https://ecmlpkdd.org/2026/submissions-research-track/) |
| ICLR 2027 | 개최지 `TBA → California, USA`. 본회의 **2027-04-26–28**, `America/Los_Angeles` 추가. | [홈페이지](https://iclr.cc/Conferences/2027), [Dates](https://iclr.cc/Conferences/2027/Dates) |
| ACML 2026 | 철회된 Conference Track camera-ready **2026-09-29** 제거. 새 확정일이 발표될 때 다시 추가. | [Conference Track Dates](https://www.acml-conf.org/2026/calls/papers/) |

### 출처 간 차이와 미확정 값 처리

- WACV의 CFP·reviewer guide에는 10월 9일이 남아 있지만, 홈페이지와 전용 일정표가
  모두 10월 14일을 안내하므로 두 곳에서 일치한 변경 날짜를 적용했습니다.
  본회의 camera-ready 11월 2일과 워크숍 camera-ready 11월 20일은 구분합니다.
- ACML CFP는 9월 29일을 취소선으로 표시하고 `To Be Confirmed Soon!`을 명시합니다.
  홈페이지의 12월 29일도 미확정입니다. Journal Track의 12월 25일로 대체하지 않습니다.
  현재 스키마에서 날짜 없는 일정을 표현할 수 없어 `acml-2026/camera-ready`만 제거했습니다.
  이 항목을 직접 선택했던 사용자는 새로고침 후 다른 마감을 선택해야 할 수 있습니다.
- ICLR 홈페이지는 California와 전체 4월 26–30일을 안내하며, 일정표는 본회의 26–28일과
  워크숍 29–30일을 구분합니다. 행사장·도시는 확정값으로 넣지 않았습니다.
  기존 리뷰 공개 11월 5일·최종 결정 12월 16일은 날짜를 유지하고, 공식 시각이 없는 두 항목의
  `time`을 `null`로 정리했습니다. 앱의 날짜 전용 일정 계산은 기존처럼 해당 시간대의 일말을 사용합니다.
- NAACL·COLING의 ARR 2026-10-12와 commitment 2026-12-23은 그대로 유지합니다.
  날짜가 지났다는 이유로 ARR 마감 ID나 대표 마감을 commitment로 바꾸지 않았습니다.
- 기존 학회 ID 전체와 철회된 ACML 항목 이외의 기존 일정 ID·대표 마감은 보존했습니다.

## 재확인 범위

아래 22개 기존 학회의 `sourceCheckedAt`만 확인 결과에 맞추어 2026-10-13으로 갱신했습니다.
위 표에 명시된 변경 외의 기존 날짜는 유지합니다.

- ML: ACML 2026, ECML PKDD 2026, NeurIPS 2026, KDD 2027, ICLR 2027, AISTATS 2027, ALT 2027.
- CV: ACCV 2026, ACM MM 2026, BMVC 2026, 3DV 2027, WACV 2027, CVPR 2027.
- NLP: AACL-IJCNLP 2026, COLM 2026, EMNLP 2026, EACL 2027, NAACL 2027, COLING 2027.
- General AI: AAAI 2027, AAMAS 2027, ICAPS 2027.

각 학회의 `sourceUrl`에 공식 근거를 보존했습니다. 신규 ACL·IJCAI의 확인일도 2026-10-13입니다.

## 보류한 학회 및 일정

- [SIGIR 2027 Full Paper CFP](https://sigir2027.org/pages/submit-full.html): 날짜가 여전히
  `PROPOSED`로 표시되어 확정 카탈로그에 추가하지 않았습니다.
- [KDD 2027 Second Cycle](https://kdd2027.kdd.org/research-track-call-for-papers/):
  February 2027이라는 월만 확인되어 정확한 초록·본문 날짜를 추정하지 않았습니다.
- [KR 2027](https://kr.org/KR2027/), [ICCV 2027](https://iccv.thecvf.com/Conferences/2027/Dates):
  행사 안내는 있지만 공식 본회의 논문 제출 마감을 확인하지 못했습니다.
- ICML, COLT, UAI, ECML PKDD, ACML, EMNLP, COLM, ACM MM, BMVC의 2027년판도
  이번 조사에서 정확한 공식 본회의 제출 마감을 확인하지 못한 경우 추가하지 않았습니다.
  이는 확인 범위를 기록한 것이며, 다른 곳에 공지가 전혀 없다는 단정은 아닙니다.
- AAAI의 취소선 camera-ready, 부가 트랙·워크숍·Journal Track의 별도 마감은 본회의 일정과 섞지 않았습니다.

## 반영 대상

- 공개 원본 및 iOS 리소스: `data/conferences.json`
- macOS 리소스: `Sources/DdayApp/Resources/conferences.json`
- Android 리소스: `Apps/Android/app/src/main/assets/conferences.json`

세 파일은 바이트 단위로 동일합니다. 앱 코드와 데이터 스키마는 변경하지 않습니다.
기존 설치 앱은 공개 `main` 데이터가 갱신된 후 학회 목록 새로고침으로 받을 수 있습니다.

## 검증

- JSON Schema Draft 2020-12와 날짜·URI 형식 검사 통과.
- 학회·일정 ID 중복, 유효한 날짜·시간·IANA 시간대, 학회당 대표 마감 1개 검사 통과.
- 기존 학회 ID 전체와 철회된 ACML 항목을 제외한 기존 일정 ID·대표 마감 보존 검사 통과.
- 재확인한 기존 22개 이외의 19개 학회는 내용이 동일함을 확인.
- 세 플랫폼 데이터 파일의 바이트 일치 검사 통과.
- 실제 `DdayCoreChecks` 실행 통과. 카탈로그 파싱, 잘못된 날짜·캐시 거부, AoE 계산 등 포함.
- ACL·IJCAI 제출, NAACL camera-ready, WACV 발표의 실제 데이터로 한국 시간 변환 검사 통과.

데이터 SHA-256: `19d831e53e3d7063832a8f38b02be60ca582c43c5fe7b3dbe66837795e5a4923`.
