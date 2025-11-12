-- 檢查 pg_net 表結構
-- 用於確定正確的欄位名稱

-- 檢查 _http_response 表結構
SELECT 
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_schema = 'net'
  AND table_name = '_http_response'
ORDER BY ordinal_position;

-- 檢查 http_request_queue 表結構（如果存在）
SELECT 
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_schema = 'net'
  AND table_name = 'http_request_queue'
ORDER BY ordinal_position;

-- 查看最近的 HTTP 響應記錄（前 3 條）
SELECT *
FROM net._http_response
ORDER BY created DESC
LIMIT 3;

