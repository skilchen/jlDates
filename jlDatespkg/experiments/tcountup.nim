import jlDates

var i = 0
var last_x: DateTime
for x in countUp(initDateTime(2017,1,1),initDateTime(2017,1,1,16,40,0), 1.Millisecond):
  last_x = x
  inc(i)
echo i
echo last_x