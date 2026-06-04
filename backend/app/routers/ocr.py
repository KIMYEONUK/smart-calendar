from fastapi import APIRouter, Depends, UploadFile, File
from app.core.deps import get_current_user
from app.core.config import settings
from app.models.user import User
from google import genai
from google.genai import types
import json, uuid
from datetime import datetime

router = APIRouter(prefix="/ocr", tags=["ocr"])

@router.post("/extract")
async def extract(image: UploadFile = File(...), user: User = Depends(get_current_user)):
    if not settings.GEMINI_API_KEY:
        return []
    client = genai.Client(api_key=settings.GEMINI_API_KEY)
    contents = await image.read()
    today = datetime.now()
    today_str = today.strftime("%Y-%m-%dT09:00:00")
    today_display = today.strftime("%Y년 %m월 %d일")

    prompt = f"""당신은 포스터/공지문 이미지에서 일정 정보를 추출하는 전문가입니다.
오늘 날짜는 {today_display}입니다.
아래 예시를 참고하여 이미지에서 일정을 추출하세요.

=== 예시 1: 마감일만 있는 경우 ===
포스터 텍스트: "모집기간: ~2026. 3. 27.(금) 17:00까지"
올바른 출력:
[{{"title": "참여자 모집 마감", "start_at": "2026-03-27T17:00:00", "end_at": "2026-03-27T17:00:00", "is_all_day": false, "category": "personal", "location": null, "memo": "모집 마감: 2026년 3월 27일 17시", "link": null}}]

=== 예시 2: 시작일~종료일 모두 있는 경우 ===
포스터 텍스트: "접수기간: 2026. 6. 15.(월) ~ 9. 30.(수)"
올바른 출력:
[{{"title": "공모전 접수", "start_at": "2026-06-15T09:00:00", "end_at": "2026-09-30T18:00:00", "is_all_day": true, "category": "personal", "location": null, "memo": "접수기간: 2026년 6월 15일 ~ 9월 30일", "link": null}}]

=== 예시 3: 날짜가 전혀 없는 경우 ===
포스터 텍스트: "동아리 신입 부원 모집 - 관심있는 분 연락주세요"
올바른 출력:
[{{"title": "동아리 신입 부원 모집", "start_at": "{today_str}", "end_at": null, "is_all_day": true, "category": "personal", "location": null, "memo": "관심있는 분 연락", "link": null}}]

=== 예시 4: URL 링크가 있는 경우 ===
포스터 텍스트: "신청: https://forms.gle/abc123 / 마감: 2026. 5. 31."
올바른 출력:
[{{"title": "신청 모집", "start_at": "{today_str}", "end_at": "2026-05-31T23:59:00", "is_all_day": true, "category": "personal", "location": null, "memo": "신청 링크 참고", "link": "https://forms.gle/abc123"}}]

=== 예시 5: 일정이 여러 개인 경우 ===
포스터 텍스트: "1차 접수: 3월 1일~3월 31일 / 2차 접수: 4월 1일~4월 30일"
올바른 출력:
[
  {{"title": "1차 접수", "start_at": "2026-03-01T09:00:00", "end_at": "2026-03-31T18:00:00", "is_all_day": true, "category": "personal", "location": null, "memo": "1차 접수기간", "link": null}},
  {{"title": "2차 접수", "start_at": "2026-04-01T09:00:00", "end_at": "2026-04-30T18:00:00", "is_all_day": true, "category": "personal", "location": null, "memo": "2차 접수기간", "link": null}}
]

=== 실제 추출 규칙 ===
- title: 이미지에서 가장 크거나 핵심적인 제목 사용
- start_at: 명시된 시작일. "~날짜까지"처럼 마감일만 있으면 title에 '마감' 추가하고 start_at = end_at = 마감일로 설정
- end_at: 명시된 마감일/종료일. 없으면 null
- is_all_day: 시간 정보 없으면 true, 시간이 있으면 false
- memo: 참여 대상, 혜택, 신청 방법, 주최 기관 등 핵심 정보를 줄바꿈 없이 한 문단으로 요약
- link: 포스터에 URL(https://...)이 보이면 그대로 입력. QR코드만 있으면 null
- 연도가 없으면 오늘 기준 가장 가까운 미래 연도 사용
- 일정이 없으면 빈 배열 []

JSON 배열만 반환하세요. 마크다운 없이 순수 JSON만."""

    try:
        response = client.models.generate_content(
            model="gemini-2.5-flash",
            contents=[
                types.Part.from_bytes(data=contents, mime_type=image.content_type),
                prompt
            ]
        )
        text = response.text.strip().replace("```json","").replace("```","")
        events = json.loads(text)

        result = []
        for e in events:
            title = e.get("title") or "제목 없음"
            start_at = e.get("start_at") or today_str
            end_at = e.get("end_at")

            if not isinstance(start_at, str):
                start_at = today_str

            result.append({
                "id": str(uuid.uuid4()),
                "is_verified": True,
                "title": title,
                "start_at": start_at,
                "end_at": end_at,
                "is_all_day": e.get("is_all_day") or False,
                "category": e.get("category") or "personal",
                "location": e.get("location"),
                "memo": e.get("memo"),
                "link": e.get("link"),
            })
        return result
    except Exception as e:
        print(f"OCR error: {e}")
        return []
