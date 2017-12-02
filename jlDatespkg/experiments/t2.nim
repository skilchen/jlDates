import jlDates

proc enumerate_one_day(dt: DateTime) =
  var count = 0
  var c1 = 0
  var startp = adjust(proc(x:DateTime):bool = millisecond(x) == 0 and second(x) == 0 and minute(x) == 0, dt, step = 1.Millisecond, limit=1_000_000)
  echo "start: ", startp
  var endp = startp + 1000.Year
  for ms in countUp(startp, endp, step = 5.Seconds):
    inc(count)
    if dayofweek(ms) == 7:
      if hour(ms) >=  10 and hour(ms) <= 11:
        #echo ms  
        inc(c1)
  echo count, " ", c1

when isMainModule:
  enumerate_one_day(now())

