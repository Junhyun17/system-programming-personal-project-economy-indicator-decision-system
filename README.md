\# 경제 지표 기반 소비·투자 판단 시스템



Linux Shell Script를 이용해 달러 환율, 비트코인, 코스피, S\&P 500, 금 가격을 조회하고, 사용자가 설정한 기준에 따라 소비·투자 판단을 보조하는 프로그램입니다.



\## 주요 기능



\- 달러 환율, 비트코인, 코스피, S\&P 500, 금 가격 조회

\- 최근 데이터 기반 그래프 생성

\- 기준값 직접 비교

\- 평균 대비 차이 비교

\- 평균 대비 퍼센트 비교

\- 자동 알림 기준 등록

\- PowerShell 화면 알림

\- SMTP 이메일 알림

\- 조회 및 알림 기록 저장

\- 백그라운드 자동 감시 실행



\## 사용한 명령어 및 도구



\- Bash Shell Script

\- curl

\- jq

\- bc

\- gnuplot

\- msmtp

\- PowerShell



\## 사용 API



\- Frankfurter API: 달러 환율 조회

\- Upbit API: 비트코인 KRW-BTC 가격 조회

\- Yahoo Finance chart API: 코스피, S\&P 500, 금 가격 조회



\## 프로젝트 구조



```text

economy\_project/

├── main.sh

├── alert\_watch.sh

├── config.txt

├── alerts.txt

├── lib/

│   ├── api.sh

│   ├── lookup.sh

│   ├── compare.sh

│   ├── graph.sh

│   ├── alert.sh

│   ├── settings.sh

│   └── util.sh

├── data/

└── graph/

