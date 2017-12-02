import jlDates

proc enumerate_one_day(dt: DateTime) =
  var count = 0
  var c1 = 0
  #var startp = adjust(proc(x:DateTime):bool = millisecond(x) == 0 and second(x) == 0 and minute(x) == 0, dt, step = 1.Millisecond, limit=1_000_000_000)
  var startp = tonext(dt, 7)
  echo startp
  startp = trunc(startp, TDay) + 10.Hours
  echo "start: ", startp
  var endp = startp + 1000.Year
  for ms in countUp(startp, endp, step = 7.Day):
    inc(count)
    if dayofweek(ms) == 7:
      let (y, m, d) = yearmonthday(ms)
      let s1 = initDateTime(y, m, d, 10, 0, 0)
      let s2 = s1 + 1.Hour
      for xx in countUp(s1, s2, step = 5.Minutes):
      #if hour(ms) >=  10 and hour(ms) <= 11:
        echo xx
        inc(c1)
  echo count, " ", c1

when isMainModule:
  enumerate_one_day(now())

