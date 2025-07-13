#!/usr/bin/env bash
cd "$(dirname "$0")"

# Daftar elemen acak
declare -a methods=(GET POST PUT DELETE)
declare -a endpoints=("/api/items" "/api/items/1" "/api/items/2" "/api/users" "/api/users/42")
declare -a users=("guest" "user123" "admin" "alice" "bob")
declare -a statuses=(200 201 204 400 401 403 404 500)
declare -a referrers=("-" "https://app.example.com/dashboard" "https://app.example.com/login")
declare -a user_agents=(
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.5790.170 Safari/537.36"
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.4 Safari/605.1.15"
  "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Firefox/102.0"
)

# Base timestamp (akan dipakai sama untuk semua; bisa kamu modifikasi menjadi dinamis)
base_ts="2025-07-13T04:00:00+07:00"

for i in {1..30}; do
  m=${methods[$((RANDOM % ${#methods[@]}))]}
  e=${endpoints[$((RANDOM % ${#endpoints[@]}))]}
  u=${users[$((RANDOM % ${#users[@]}))]}
  s=${statuses[$((RANDOM % ${#statuses[@]}))]}
  size=$((RANDOM % 500 + 20))
  latency=$((RANDOM % 200 + 10))
  ref=${referrers[$((RANDOM % ${#referrers[@]}))]}
  ua=${user_agents[$((RANDOM % ${#user_agents[@]}))]}
  ip="192.168.$((RANDOM % 255)).$((RANDOM % 255))"

  echo "${ip} - ${u} [${base_ts}] \"${m} ${e} HTTP/1.1\" ${s} ${size} ${latency}ms \"${ref}\" \"${ua}\"" \
    >> logs/access.log
done

echo "30 baris CRUD log REST API ditambahkan ke logs/access.log"