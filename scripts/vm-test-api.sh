#!/bin/bash
set -e
BASE=http://localhost:3333

echo "=== Health ==="
curl -sf "$BASE/health/ready"
echo ""

echo "=== Register ==="
curl -sf -X POST "$BASE/auth/register" \
  -H "Content-Type: application/json" \
  -d '{"email":"demo@vitalis.vm","password":"Demo1234!","name":"Demo VM"}'
echo ""

echo "=== Login ==="
TOKEN=$(curl -sf -X POST "$BASE/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"demo@vitalis.vm","password":"Demo1234!"}' | grep -o '"accessToken":"[^"]*"' | cut -d'"' -f4)
echo "Token: ${TOKEN:0:40}..."

echo "=== ML Assessment ==="
curl -sf -X POST "$BASE/assessments" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"age":28,"gender":"Male","heightCm":175,"weightKg":80,"dailySteps":8500,"caloriesIntake":2200,"hoursOfSleep":7.5,"exerciseHoursPerWeek":3,"smoker":"No","alcoholPerWeek":2,"diabetic":"No","heartDisease":"No"}'
echo ""
