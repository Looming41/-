-- 이미 news-seed.sql(구버전, 키워드 없이)을 실행해서 뉴스 6개가 이미 들어가 있는 경우에만 실행하세요.
-- 먼저 supabase-schema.sql을 다시 실행해서 news_posts.keyword 컬럼을 추가한 뒤 이 파일을 실행합니다.
-- 아직 뉴스 6개를 넣지 않았다면 이 파일 대신 news-seed.sql(키워드 포함 최신 버전)을 실행하세요.

update news_posts set keyword = '국제학교' where title = '국제학교, 인가와 비인가는 뭐가 다를까?';
update news_posts set keyword = 'AP' where title = 'AP 몇 개면 충분할까? 아이비리그 합격생 데이터로 보는 학년별 로드맵';
update news_posts set keyword = '지원전략' where title = '아이비리그만 노리면 전멸합니다 — 안정권 리스트 짜는 법';
update news_posts set keyword = '입시트렌드' where title = '이번 입시 시즌, 합격과 불합격을 가른 것들';
update news_posts set keyword = '컨설팅철학' where title = '합격의 시작은 "분석"입니다 — 아이비리그가 정말 원하는 것';
update news_posts set keyword = '여름방학' where title = 'Rising G11·G12, 이번 여름방학이 마지막 기회입니다';
