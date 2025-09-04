Server implemented at apps/server (Node/Express) and Python fallback at apps/server/server.py.
Local curl tests not fully executed due to:
- Port :8787 already occupied by an external Node process in this environment.
- Network/sandbox constraints prevented binding alternate port reliably for HTTP/1.1 responses.

What was validated:
- File scaffolding completed for monorepo, server APIs, frontend HUD components.
- JSON DB seeded at apps/server/data/db.json; UMSE sample files in apps/server/data/umse/.

Suggested local test commands:
1) Start server (Node): cd apps/server && npm i && npm run dev
2) Start frontend: cd apps/frontend && npm i && npm run dev
3) Curl:
   curl -sX POST localhost:8787/api/affiliates/link -H 'content-type: application/json' -d '{"email":"alice@unykorn.af"}'
   curl -sX POST localhost:8787/api/register/abcd12 -H 'content-type: application/json' -d '{"wallet":"0xabc...","name":"Alice","entityType":"client","affCode":"<CODE_FROM_PREV>"}'
   curl -sX POST localhost:8787/api/tx -H 'content-type: application/json' -d '{"edgeId":"Client:A->Subcontractor:X","amountUSD":25000,"token":"USDC"}'

