# Web Island · 웹 아일랜드

> 노치가 다이나믹 아일랜드가 되어 브라우저가 되는 macOS 메뉴바 앱
> _Your browser in the notch._

MacBook의 노치에 마우스를 가져가면 좌우로 펼쳐지고, 클릭하면 노치 아래에 미니 브라우저가 **Seamless**하게 자라나는 메뉴바 브라우저. **탭 1개 = 사이트 1개.**

- 영어 공식 명칭: **Web Island** · 부제: Your browser in the notch
- 한국어 공식 명칭: **웹 아일랜드** · 부제: 노치 속 작은 브라우저

---

## 핵심 UX

| 상태 | 동작 |
|---|---|
| **IDLE** | 노치 안에 현재 사이트 파비콘이 작게 펄스 |
| **HOVER** | 노치가 180px → 420px로 확장, 파비콘 탭 스트립 표시 |
| **EXPANDED** | 노치에서 브라우저 패널이 하나의 덩어리로 자라남 (gap 0) |
| **DETACHED** | 브라우저 패널을 떼어 자유 이동, 위치 기억 |

### 두 가지 윈도우 모드 (설정)
- **Attached (기본)**: 노치와 브라우저가 하나의 윈도우 · 하나의 모양. Seamless.
- **Detached**: 노치(탭 스트립) + 브라우저(플로팅 윈도우) 분리.

---

## 주요 기능

- **노치 오버레이**: `NSScreen.auxiliaryTopLeftArea`로 실제 노치 프레임 감지, 메뉴바 위 오버레이
- **탭 관리**: 탭 = 사이트 1개, 추가/삭제/이름 변경/고정, 마지막 탭 기억, `⌘1~5` 전환
- **파비콘**: `link[rel=icon]` → `/favicon.ico` → Google S2 → **첫 글자 그라데이션 아바타** 순 폴백
- **WKWebView Pool**: 활성 1개 + 캐시, 로그인 유지를 위한 공유 쿠키 스토리지
- **다운로드 트레이**: 진행률 · 용량 · 속도 · 잔여/경과 시간, 임시파일 rename/삭제, `ESC` 닫기
- **인증서 처리**: 사설/비신뢰 인증서 트러스트 핸들러 + 안전한 공급기(default) 복원
- **설정**: Dock 아이콘 토글, 로그인 시 자동 실행, 윈도우 모드(Attached/Detached), 단축키
- **디버그 패널**: `⌘⇧D` — 실시간 로그(다중 선택·복사), 메모리/성능, 캐시 히트율, 오프라인 큐
- **손쉬운 사용 접근성**: 호버 감지용 Accessibility 권한 온보딩 랜딩

### 기본 단축키
| 단축키 | 동작 |
|---|---|
| ⌘⇧W | 브라우저 패널 토글 |
| ⌘⇧D | 디버그 패널 토글 |
| ⌘W / ⌘1~5 | 탭 닫기 / 전환 |

---

## 기술 스택

- macOS 14+ · Swift 5.9 · **SwiftUI 주도 + AppKit 예외**(윈도우/호버 계층 한정)
- `WKWebView` Pool, `NSScreen.auxiliaryTopLeftArea` 노치 감지
- `NSWindow.level = .screenSaver` 메뉴바 오버레이, 글로벌 마우스 모니터(호버)
- `KeyboardShortcuts` 패키지, 번들 ID `com.borasarang.WebIsland`
- 레이아웃: Panel R 20px (Attached 24px), Material `.hudWindow`, spring(response: 0.35, damping: 0.75)

---

## 프로젝트 구조

```
Sources/
  Controllers/   윈도우 생성·레벨·노치/호버 추적 (AppKit 예외 허용)
  Models/        WebTab · NotchViewModel · DownloadItem
  Services/      TabManager · WebViewPool · DownloadManager/Routing/FileStore ·
                 FaviconService · CertTrustService · AccessibilityService · LogStore ...
  Utils/         NotchDetector · HostPort · 화면상수 · AppSettingsKeys ...
  Views/         NotchRoot · WebContainer · Settings · DownloadTray · BrowserChrome ...
Resources/       Localizable.strings(ko/en) · InfoPlist.strings(ko/en)
Tests/           unit 테스트 16개 파일 (63건)
Assets/          WebIsland.xcassets (AppIcon)
Mockups/         상호작용 HTML 목업
scripts/         patch-resources.py (xcodegen 리소스 누락 보정)
docs/            PRD · DESIGN · ARCHITECTURE · CHANGELOG · TODO · plans · e2e
```

> 단일 플랫폼(macos) 네이티브 앱. 모노레포 · turbo · pnpm 규칙 비적용.

---

## 요구사항 & 빌드

- macOS 14+ · Xcode 16+ · [xcodegen](https://github.com/yonaskolb/XcodeGen) (빌드 스크립트가 자동 구동)

```bash
# 빌드 (검증 게이트 포함: lint → unit → build → 재시작)
./build_and_run.sh build macos

# 단위 테스트
./build_and_run.sh test macos unit

# E2E smoke (프로세스 기동 · 시작 로그 · 단축키 패널)
./build_and_run.sh e2e macos smoke
```

- 산출물은 `~/Applications/WebIsland.app`에 설치·재실행됩니다 (기존 있다면 교체).
- `xcodegen generate` 후 `scripts/patch-resources.py`가 리소스 참조를 보정합니다 (스크립트가 자동 수행).
- **주의**: `swift build/test` 금지 — `xcodebuild`만 정식 산출물.

### 검증 게이트
- `swiftlint` error 0 + 경고 0, unit 63건, E2E smoke 4/4
- 성능 예산: 노치 호버→브라우저 300ms 이내, 메모리 300MB 이하(WKWebView 3개 풀)

---

## 로컬라이제이션

시스템 언어에 따라 표시명이 자동 전환됩니다 (`LSHasLocalizedDisplayName` + 번들명 정합).

| 로케일 | 표시명 | 부제 |
|---|---|---|
| 한국어 | 웹 아일랜드 | 노치 속 작은 브라우저 (아이슬렌드 웹) |
| English | Web Island | Your browser in the notch |

- `Resources/ko.lproj/InfoPlist.strings` · `Resources/en.lproj/InfoPlist.strings`
- 메뉴·설정 전체는 `Localizable.strings (ko/en)`으로 현지화

---

## 문서

- `docs/PRD.md` — 요구사항 · UI 스펙
- `docs/DESIGN.md` — 디자인 시스템 · UX 결정
- `docs/ARCHITECTURE.md` — 아키텍처 설명
- `docs/CHANGELOG.md` — 플랫폼/에러코드/성능 영향 포함 변경 이력
- `docs/TODO.md` — 작업 추적 (T-번호 ↔ bd ID 패시브 미러)
- `docs/plans/PLAN_v0.9_macos.md` — 최근 작업 계획
- `.agent/session-*.md` — 세션 로그

---

## 라이선스

준비 중 · 코드는 비공개 저장소에서 관리됩니다.