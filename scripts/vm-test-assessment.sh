#!/bin/bash
TOKEN=$(curl -sf -X POST http://localhost:3333/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"demo@vitalis.vm","password":"Demo1234!"}' \
  | sed -n 's/.*"accessToken":"\([^"]*\)".*/\1/p')

curl -sf -X POST http://localhost:3333/assessments \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"age":28,"gender":"Male","heightCm":175,"weightKg":80,"dailySteps":8500,"caloriesIntake":2200,"hoursOfSleep":7.5,"exerciseHoursPerWeek":3,"smoker":"No","alcoholPerWeek":2,"diabetic":"No","heartDisease":"No"}'
