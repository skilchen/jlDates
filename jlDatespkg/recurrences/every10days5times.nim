import ../jlDates

proc every10days5times[T: DateTime|Date](dtstart: T): seq[T] =
  var curr = dtstart
  result = @[curr]
  for i in 1..5:
    curr = dtstart + Days(i * 10)
    result.add(curr)

when isMainModule:
  import os
  let dtstart = strptime(paramStr(1), "%Y-%m-%d %H:%M:%S")
  for i in every10days5times(dtstart):
    echo $i

  
