## 2024-06-10 - GraphQL Payload Compression
**Learning:** GraphQL endpoints can easily return large JSON payloads, especially for lists of sets or cards. Without compression, these payloads unnecessarily consume bandwidth and increase load times for frontend clients.
**Action:** Added `GZipMiddleware` to the FastAPI backend to automatically compress large API responses (above 1000 bytes) and significantly reduce transfer sizes.
