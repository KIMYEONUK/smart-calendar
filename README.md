# SmartCalendar

OCR 기반 일정 관리 앱 — Flutter (iOS) + FastAPI 백엔드

## 빠른 시작

### 1. 프론트엔드 설정
```bash
cd frontend
cp .env .env  # GEMINI_API_KEY, BACKEND_BASE_URL 입력
flutter pub get
flutter run
```

### 2. iOS 빌드 (Xcode 26 + Flutter 3.44)
```bash
cd frontend/ios
pod install --repo-update
cd ..
flutter run --release
```

### 3. 백엔드
```bash
cd backend
pip install -r requirements.txt
cp .env.example .env  # 설정 입력
uvicorn main:app --reload --port 8000
```

## 주요 패키지 (문제 패키지 제거됨)

| 제거됨 | 이유 |
|--------|------|
| `google_mlkit_text_recognition` | Xcode 26 호환 문제 |
| `google_mlkit_commons` | 동일 |
| `flutter_local_notifications` | 불필요 (알림 기능 미구현) |

OCR은 **Gemini API** (`/api/ocr/extract` 엔드포인트)로만 처리.

## Podfile 핵심 설정
```ruby
platform :ios, '15.5'
# post_install에서 IPHONEOS_DEPLOYMENT_TARGET = '15.5' 강제 설정
```
