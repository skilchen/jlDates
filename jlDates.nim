import math
import typetraits
import strutils
import parseutils
import tables

when not defined(js):
  import os
  export sleep
else:
  {.push overflowChecks:off.}

import jlDatespkg/epochTime


export epochTime

# Date Locales

type DateLocale = object
  months: array[1..12, string]
  months_abbr: array[1..12, string]
  days_of_week: array[1..7, string]
  days_of_week_abbr: array[1..7, string]
  month_value: Table[string, int]
  month_abbr_value: Table[string, int]
  day_of_week_value: Table[string, int]
  day_of_week_abbr_value: Table[string, int]

proc locale_dict(names: openArray[string]): Table[string, int] =
  result = initTable[string, int]()
  # Keep both the common case-sensitive version of the name and an all lowercase
  # version for case-insensitive matches. Storing both allows us to avoid using the
  # lowercase function during parsing.
  for i in 0..(len(names) - 1):
      var name = names[i]
      result[name] = i + 1
      result[toLowerAscii(name)] = i + 1

proc initDateLocale*(months, months_abbr: array[1..12, string],
                    days_of_week, days_of_week_abbr: array[1..7, string]): DateLocale =
    DateLocale(months: months, months_abbr: months_abbr,
               days_of_week: days_of_week,
               days_of_week_abbr: days_of_week_abbr,
               month_value: locale_dict(months),
               month_abbr_value: locale_dict(months_abbr),
               day_of_week_value: locale_dict(days_of_week),
               day_of_week_abbr_value: locale_dict(days_of_week_abbr))

var ENGLISH = initDateLocale(
    ["January", "February", "March", "April", "May", "June",
     "July", "August", "September", "October", "November", "December"],
    ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
     "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"],
    ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"],
    ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"],
)

var LOCALES* = initTable[string, DateLocale]()
LOCALES["english"] = ENGLISH

proc dayname_to_value*(word: string, locale: DateLocale): int =
  var value = getOrDefault(locale.day_of_week_value, word)
  if value == 0:
    value = getOrDefault(locale.day_of_week_value, toLowerAscii(word))
  result = value

proc dayabbr_to_value*(word: string, locale: DateLocale): int =
  var value = getOrDefault(locale.day_of_week_abbr_value, word)
  if value == 0:
    value = getOrDefault(locale.day_of_week_abbr_value, toLowerAscii(word))
  result = value

proc monthname_to_value*(word: string, locale: DateLocale): int =
  var value = getOrDefault(locale.month_value, word)
  if value == 0:
    value = getOrDefault(locale.month_value, toLowerAscii(word))
  result = value

proc monthabbr_to_value*(word: string, locale: DateLocale): int =
  var value = getOrDefault(locale.month_abbr_value, word)
  if value == 0:
    value = getOrDefault(locale.month_abbr_value, toLowerAscii(word))
  result = value

proc dayname*(day: int, locale: DateLocale): string = locale.days_of_week[day]
proc dayabbr*(day: int, locale: DateLocale): string = locale.days_of_week_abbr[day]
proc dayname*(day: int; locale: string = "english"): string = dayname(day, LOCALES[locale])
proc dayabbr*(day: int; locale: string = "english"): string = dayabbr(day, LOCALES[locale])

proc monthname*(month: int, locale: DateLocale): string = locale.months[month]
proc monthabbr*(month: int, locale: DateLocale): string = locale.months_abbr[month]
proc monthname*(month: int; locale: string = "english"):string = monthname(month, LOCALES[locale])
proc monthabbr*(month: int; locale: string = "english"):string = monthabbr(month, LOCALES[locale])

type PeriodKind* = enum
  pkYear, pkQuarter, pkMonth, pkWeek, pkDay,
  pkHour, pkMinute, pkSecond,
  pkMillisecond, pkMicrosecond, pkNanosecond

type
  AbstractTime = object of RootObj
  Period* = object of AbstractTime
    kind*: PeriodKind
    value*: int64
  DatePeriod = object of Period
  TimePeriod = object of Period

  TYear* = object of DatePeriod
  TMonth* = object of DatePeriod
  TWeek* = object of DatePeriod
  TDay* = object of DatePeriod

  THour* = object of TimePeriod
  TMinute* = object of TimePeriod
  TSecond* = object of TimePeriod
  TMillisecond* = object of TimePeriod
  TMicrosecond* = object of TimePeriod
  TNanosecond* = object of TimePeriod

type TCompoundPeriod* = object
  years*: TYear
  months*: TMonth
  weeks*: TWeek
  days*: TDay
  hours*: THour
  minutes*: TMinute
  seconds*: TSecond
  milliseconds*: TMillisecond
  microseconds*: TMicrosecond
  nanoseconds*: TNanosecond

type
  Instant = object of AbstractTime
  UTInstant = object# of Instant
    periods*: Period

proc UTM*(x: SomeNumber): UTInstant =
  result = UTInstant(periods: TMillisecond(value: int64(x)))

proc UTD*(x: SomeNumber): UTInstant =
  result = UTInstant(periods: TDay(value: int64(x)))

# type
#   Calendar = object of AbstractTime
#   ISOCalendar* = object of Calendar

type
  Timezone = object of RootObj
  UTC* = object of Timezone

type
  TimeType* = object of AbstractTime
    instant*: UTInstant
  DateTime* = object #of TimeType
    instant*: UTInstant
  Date* = object #of TimeType
    instant*: UTInstant
  Time* = object #of TimeType
    instant*: UTInstant

type ISOWeekDate* = object
  year*: int64
  week*: int64
  weekday*: int64

#type gPeriod = TYear|TMonth|TDay|THour|TMinute|TSecond|TMillisecond|TMicrosecond|TNanosecond

proc Year*(y: SomeNumber): TYear =
  result = TYear(kind: pkYear, value: int64(y))
template Years*(y: SomeNumber): TYear = Year(y)

proc `$`*(x: TYear): string =
  let x = x.value
  if abs(x) != 1:
    result = $x & " years"
  else:
    result = $x & " year"
proc value*(x: TYear): int64 = x.value

proc Month*(m: SomeNumber): TMonth =
  result = TMonth(kind: pkMonth, value: int64(m))
template Months*(m: SomeNumber): TMonth = Month(m)
proc `$`*(y: TMonth): string =
  let y = y.value
  if abs(y) != 1:
    result = $y & " months"
  else:
    result = $y & " month"
proc value*(x: TMonth): int64 = x.value

proc Week*(w: SomeNumber): TWeek = TWeek(kind: pkWeek, value: int64(w))
template Weeks*(w: SomeNumber): Tweek = Week(w)
proc `$`*(y: TWeek): string =
  let y = y.value
  if abs(y) != 1:
    result = $y & " weeks"
  else:
    result = $y & " week"
proc value*(x: Tweek): int64 = x.value

proc Day*(d: SomeNumber): TDay =
  result = TDay(kind: pkDay, value: int64(d))
template Days*(d: SomeNumber):TDay = Day(d)
proc `$`*(x: TDay): string =
  let x = x.value
  if abs(x) != 1:
    result = $x & " days"
  else:
    result = $x & " day"
proc value*(d: TDay): int64 = d.value

proc Hour*(h: SomeNumber): THour =
  result = THour(kind: pkHour, value: int64(h))
template Hours*(h: SomeNumber): THour = Hour(h)
proc `$`*(x: THour): string =
  let x = x.value
  if abs(x) != 1:
    result = $x & " hours"
  else:
    result = $x & " hour"
proc value*(x: THour): int64 = x.value

proc Minute*(m: SomeNumber): TMinute =
  result = TMinute(kind: pkMinute, value: int64(m))
template Minutes*(m: SomeNumber): TMinute = Minute(m)
proc `$`*(x: TMinute): string =
  let x = x.value
  if abs(x) != 1:
    result = $x & " minutes"
  else:
    result = $x & " minute"
proc value*(x: TMinute): int64 = x.value

proc Second*(s: SomeNumber): TSecond =
  result = TSecond(kind: pkSecond, value: int64(s))
template Seconds*(s: SomeNumber): TSecond = Second(s)
proc `$`*(x: TSecond): string =
  let x = x.value
  if abs(x) != 1:
    result = $x & " seconds"
  else:
    result = $x & " second"
proc value*(x: TSecond): int64 = x.value

proc Millisecond*(ms: SomeNumber): TMillisecond =
  result = TMillisecond(kind: pkMillisecond, value: int64(ms))
template Milliseconds*(ms: SomeNumber): TMillisecond = Millisecond(ms)
proc `$`*(x: TMillisecond): string =
  let x = x.value
  if abs(x) != 1:
    result = $x & " milliseconds"
  else:
    result = $x & " millisecond"
proc value*(x: TMillisecond): int64 = x.value

proc Microsecond*(us: SomeNumber): TMicrosecond =
  result = TMicrosecond(kind: pkMicrosecond, value: int64(us))
template Microseonds*(us: SomeNumber): TMicrosecond = Microsecond(us)
proc `$`*(x: TMicrosecond): string =
  let x = x.value
  if abs(x) != 1:
    result = $x & " microseconds"
  else:
    result = $x & " microsecond"
proc value*(x: TMicrosecond): int64 = x.value

proc Nanosecond*(ns: SomeNumber): TNanosecond =
  result = TNanosecond(kind: pkNanosecond, value: int64(ns))
template Nanoseconds*(ns: SomeNumber): TNanosecond = Nanosecond(ns)
proc `$`*(x: TNanosecond): string =
  let x = x.value
  if abs(x) != 1:
    result = $x & " nanoseconds"
  else:
    result = $x & " nanosecond"
proc value*(x: TNanosecond): int64 = x.value

proc fld[T, U](x: T, y: U): int64 =
  return int64(floor(float(x) / float(y)))

proc modulo[T, U](x: T, y: U): int =
  when defined(js):
    return int(x.float64 - float64(y) * float64(fld(x, y)))
  else:
    return int(x - int(y) * fld(x, y))

proc CompoundPeriod*(years = Year(0), months = Month(0), weeks = Week(0), days = Day(0),
                    hours = Hour(0), minutes = Minute(0), seconds = Second(0),
                    milliseconds = Millisecond(0)): TCompoundPeriod =
  var carry: int64 = 0
  result.milliseconds = Millisecond(`mod`(milliseconds.value, 1000))
  carry = `div`(milliseconds.value, 1000)
  result.seconds = Second(`mod`(carry + seconds.value, 60))
  carry = `div`(carry + seconds.value, 60)
  result.minutes = Minute(`mod`(carry + minutes.value, 60))
  carry = `div`(carry + minutes.value, 60)
  result.hours = Hour(`mod`(carry + hours.value, 24))
  carry = `div`(carry + hours.value, 24)
  result.days = Day(`mod`(carry + days.value, 7))
  carry = `div`(carry + days.value, 7)
  result.weeks = Week(carry + weeks.value)

  result.months = Month(`mod`(months.value, 12))
  carry = `div`(months.value, 12)
  result.years = Year(carry + years.value)

proc CompoundPeriod_b*(years = Year(0), months = Month(0), days = Day(0),
                     hours = Hour(0), minutes = Minute(0), seconds = Second(0),
                     milliseconds = Millisecond(0)): TCompoundPeriod =
  var carry: int64 = 0
  result.milliseconds = Millisecond(modulo(milliseconds.value, 1000))
  carry = fld(milliseconds.value, 1000)
  result.seconds = Second(modulo(carry + seconds.value, 60))
  carry = fld(carry + seconds.value, 60)
  result.minutes = Minute(modulo(carry + minutes.value, 60))
  carry = fld(carry + minutes.value, 60)
  result.hours = Hour(modulo(carry + hours.value, 24))
  carry = fld(carry + hours.value, 24)
  result.days = Day(carry + days.value)

  result.months = Month(modulo(months.value, 12))
  carry = fld(months.value, 12)
  result.years = Year(carry + years.value)

proc `$`*(cp: TCompoundPeriod): string =
  result = ""
  if value(cp.years) != 0:
    result.add($cp.years)
  if value(cp.months) != 0:
    if len(result) > 0:
      result.add(", ")
    result.add($cp.months)
  if value(cp.weeks) != 0:
    if len(result) > 0:
      result.add(", ")
    result.add($cp.weeks)
  if value(cp.days) != 0:
    if len(result) > 0:
      result.add(", ")
    result.add($cp.days)
  if value(cp.hours) != 0:
    if len(result) > 0:
      result.add(", ")
    result.add($cp.hours)
  if value(cp.minutes) != 0:
    if len(result) > 0:
      result.add(", ")
    result.add($cp.minutes)
  if value(cp.seconds) != 0:
    if len(result) > 0:
      result.add(", ")
    result.add($cp.seconds)
  if value(cp.milliseconds) != 0:
    if len(result) > 0:
      result.add(", ")
    result.add($cp.milliseconds)
  if len(result) == 0:
    result = "empty period"

proc canonicalize*(cp: TCompoundPeriod): TCompoundPeriod =
  var carry: int64 = 0
  result.milliseconds = Millisecond(`mod`(cp.milliseconds.value, 1000))
  carry = `div`(cp.milliseconds.value, 1000)
  result.seconds = Second(`mod`(carry + cp.seconds.value, 60))
  carry = `div`(carry + cp.seconds.value, 60)
  result.minutes = Minute(`mod`(carry + cp.minutes.value, 60))
  carry = `div`(carry + cp.minutes.value, 60)
  result.hours = Hour(`mod`(carry + cp.hours.value, 24))
  carry = `div`(carry + cp.hours.value, 24)
  result.days = Day(`mod`(carry + cp.days.value, 7))
  carry = `div`(carry + cp.days.value, 7)
  result.weeks = Week(carry + cp.weeks.value)

  result.months = Month(`mod`(cp.months.value, 12))
  carry = `div`(cp.months.value, 12)
  result.years = Year(carry + cp.years.value)

proc canonicalize_b*(cp: TCompoundPeriod): TCompoundPeriod =
  var carry: int64 = 0
  result.milliseconds = Millisecond(modulo(cp.milliseconds.value, 1000))
  carry = fld(cp.milliseconds.value, 1000)
  result.seconds = Second(modulo(carry + cp.seconds.value, 60))
  carry = fld(carry + cp.seconds.value, 60)
  result.minutes = Minute(modulo(carry + cp.minutes.value, 60))
  carry = fld(carry + cp.minutes.value, 60)
  result.hours = Hour(modulo(carry + cp.hours.value, 24))
  carry = fld(carry + cp.hours.value, 24)
  result.days = Day(modulo(carry + cp.days.value, 7))
  carry = fld(carry + cp.days.value, 7)
  result.weeks = Week(carry + cp.weeks.value)

  result.months = Month(modulo(cp.months.value, 12))
  carry = fld(cp.months.value, 12)
  result.years = Year(carry + cp.years.value)

proc `+`*(cp1, cp2: TCompoundPeriod): TCompoundPeriod =
  var carry: int64 = 0
  var sm: int64 = 0
  sm = cp1.milliseconds.value + cp2.milliseconds.value
  result.milliseconds = Millisecond(modulo(sm, 1000))
  carry = fld(sm, 1000)
  sm = carry + cp1.seconds.value + cp2.seconds.value
  result.seconds = Second(modulo(sm, 60))
  carry = fld(sm, 60)
  sm = carry + cp1.minutes.value + cp2.minutes.value
  result.minutes = Minute(modulo(sm, 60))
  carry = fld(sm, 60)
  sm = carry + cp1.hours.value + cp2.hours.value
  result.hours = Hour(modulo(sm, 24))
  carry = fld(sm, 24)
  sm = carry + cp1.days.value + cp2.days.value
  result.days = Day(modulo(sm, 7))
  carry = fld(sm, 7)
  sm = carry + cp1.weeks.value + cp2.weeks.value
  result.weeks = Week(sm)

  sm = cp1.months.value + cp2.months.value
  result.months = Month(modulo(sm, 12))
  carry = fld(sm, 12)
  sm = carry + cp1.years.value + cp2.years.value
  result.years = Year(sm)

proc initCompoundPeriod*(p: Period): TCompoundPeriod =
  case p.kind
  of pkYear:
    result.years = Year(p.value)
  of pkMonth:
    result.months = Month(p.value)
  of pkWeek:
    result.weeks = Week(p.value)
  of pkDay:
    result.days = Day(p.value)
  of pkHour:
    result.hours = Hour(p.value)
  of pkMinute:
    result.minutes = Minute(p.value)
  of pkSecond:
    result.seconds = Second(p.value)
  of pkMillisecond:
    result.milliseconds = Millisecond(p.value)
  of pkMicrosecond:
    result.microseconds = Microsecond(p.value)
  of pkNanosecond:
    result.nanoseconds = Nanosecond(p.value)
  else:
    raise newException(ValueError, "can't construct CompoundPeriod from unkown period kind: " & $p.kind)

proc `+`*(p1, p2: Period): TCompoundPeriod =
  result = initCompoundPeriod(p1) + initCompoundPeriod(p2)

proc `-`*[T](x: T): T =
  result.kind = x.kind
  result.value = -x.value

template `-`*(p1, p2: Period): TCompoundPeriod =
  p1 + (-p2)

proc `+`*[P: Period](cp: TCompoundPeriod, p: P): TCompoundPeriod =
  var newCp: TCompoundPeriod
  case p.kind
  of pkYear:
    newCp = CompoundPeriod(years = Year(p.value))
  of pkMonth:
    newCp = CompoundPeriod(months = Month(p.value))
  of pkWeek:
    newCp = CompoundPeriod(weeks = Week(p.value))
  of pkDay:
    newCp = CompoundPeriod(days = Day(p.value))
  of pkHour:
    newCp = CompoundPeriod(hours = Hour(p.value))
  of pkMinute:
    newCp = CompoundPeriod(minutes = Minute(p.value))
  of pkSecond:
    newCp = CompoundPeriod(seconds = Second(p.value))
  of pkMillisecond:
    newCp = CompoundPeriod(milliseconds = Millisecond(p.value))
  else:
    raise newException(ValueError, "can't add period of kind " & $p.kind & " to compound period")
  result = cp + newCp

template `+`*(p: Period, cp: TCompoundPeriod): TCompoundPeriod =
  cp + p

proc `-`*(cp: TCompoundPeriod): TCompoundPeriod =
  result = cp
  result.years.value = -cp.years.value
  result.months.value = -cp.months.value
  result.weeks.value = -cp.weeks.value
  result.days.value = -cp.days.value
  result.hours.value = -cp.hours.value
  result.minutes.value = -cp.minutes.value
  result.seconds.value = -cp.seconds.value
  result.milliseconds.value = -cp.milliseconds.value
#  result = canonicalize(result)

proc `-`*(cp1, cp2: TCompoundPeriod): TCompoundPeriod =
  result = cp1 + (-cp2)

proc `-`*(cp: TCompoundPeriod, p: Period): TCompoundPeriod =
  result = cp + (-p)

proc `-`*(p: Period, cp: TCompoundPeriod): TCompoundPeriod =
  result = initCompoundPeriod(p) - cp

proc `*`*(cp1: TCompoundperiod, m: int64): TCompoundPeriod =
  result = cp1
  result.years.value = result.years.value * m
  result.months.value = result.months.value * m
  result.weeks.value = result.weeks.value * m
  result.days.value = result.days.value * m
  result.hours.value = result.hours.value * m
  result.minutes.value = result.minutes.value * m
  result.seconds.value = result.seconds.value * m
  result.milliseconds.value = result.milliseconds.value * m
  result = canonicalize(result)


const SHIFTEDMONTHDAYS: array[1..12, int] = [306, 337, 0, 31, 61, 92, 122, 153, 184, 214, 245, 275]

proc totaldays_orig*(y, m, d: SomeInteger): int64 =
  let z = (if m < 3: y - 1 else: y)
  let mdays = SHIFTEDMONTHDAYS[m]
  return d + mdays + 365 * z + fld(z, 4) - fld(z, 100) + fld(z, 400) - 306

proc isleapyear*(y: int64): bool =
  result = ((y mod 4 == 0) and (y mod 100 != 0)) or (y mod 400 == 0)

proc toOrdinalFromYMD*(year, month, day: SomeInteger): int64 =
  ##| return the ordinal day number in the proleptic gregorian calendar
  ##| 0001-01-01 is day number 1
  ##| algorithm from CommonLisp calendrica-3.0
  ##
  result = 0
  var year = year
  var month = month
  var day = day
  if month < 0:
    month += 1
  year += int(fld(month, 12))
  month = modulo(month, 12)
  if day < 0:
    day += 1
  result += (365 * (year - 1))
  result += fld(year - 1, 4)
  result -= fld(year - 1, 100)
  result += fld(year - 1, 400)
  result += fld((367 * month) - 362, 12)
  if month <= 2:
    result += 0
  else:
    if isLeapYear(year):
      result -= 1
    else:
      result -= 2
  result += day

proc totaldays*(y, m, d: SomeInteger): int64 = toOrdinalFromYMD(y, m, d)

const DAYSINMONTH: array[1..12, int] = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

proc daysinmonth*(y, m: SomeInteger): int = DAYSINMONTH[m] + int(m == 2 and isleapyear(y))

proc initDateTime*(y: SomeInteger, m, d: SomeInteger = 1, h, mi, s, ms: SomeInteger = 0): DateTime =
  when defined(js):
    let rata = int64(ms.float64 + 1000 * (s.float64 + 60 * mi.float64 + 3600 * h.float64 + 86400 * totaldays(y, m, d).float64))
  else:
    let rata = ms + 1000 * (s + 60 * mi + 3600 * h + 86400 * totaldays(y, m, d).int64)
  result.instant = UTM(rata)

proc initDate*(y: int64, m, d: int64 = 1): Date =
  return Date(instant: UTD(totaldays(y, m, d)))

proc initTime*(hours, minutes, seconds, milliseconds,
               microseconds, nanoseconds: int64 = 0): Time =
  let (h, mi, s, ms, us, ns) = (hours, minutes, seconds, milliseconds, microseconds, nanoseconds)
  when defined(js):
    let instant = TNanosecond(value: int64(ns.float64 + 1000.0 * us.float64 + 1000000.0 * ms.float64 + 1000000000.0 * s.float64 + 60000000000.0 * mi.float64 + 3600000000000.0 * h.float64))
  else:
    let instant = TNanosecond(value: ns + 1000 * us + 1000000 * ms + 1000000000 * s + 60000000000 * mi + 3600000000000 * h)
  return Time(instant: UTInstant(periods: instant))

proc initDateTime*(y:TYear, m:TMonth = Month(1), d:TDay = Day(1),
                  h:THour = Hour(0), mi:TMinute = Minute(0),
                  s:TSecond = Second(0), ms:TMillisecond = Millisecond(0)): DateTime =
  return initDateTime(y.value, m.value, d.value, h.value, mi.value, s.value, ms.value)

proc initDate*(y:TYear, m:TMonth = Month(1), d:TDay = Day(1)): Date =
  return initDate(y.value, m.value, d.value)

#proc value(dt:TimeType): int64 =
proc value(dt:Date|Time|DateTime): int64 =
  result = dt.instant.periods.value

proc `cmp`*(dt1, dt2: Date|DateTime|Time): int = value(dt1) - value(dt2)
proc `==`*(dt1, dt2: Date|DateTime|Time): bool = value(dt1) == value(dt2)
proc `!=`*(dt1, dt2: Date|Datetime|Time): bool = value(dt1) != value(dt2)
proc `<=`*(dt1, dt2: DateTime|Date|Time): bool = value(dt1) <= value(dt2)
proc `>=`*(dt1, dt2: DateTime|Date|Time): bool = value(dt1) >= value(dt2)
proc `<`*(dt1, dt2: DateTime|Date|Time): bool = value(dt1) < value(dt2)
proc `>`*(dt1, dt2: DateTime|Date|Time): bool = value(dt1) > value(dt2)

proc days*(dt:Date):int64 = value(dt)
proc days*(dt:DateTime):int64 = fld(value(dt), 86400000)

proc yearmonthday*(days: SomeInteger): tuple[year: int, month: int, day: int] =
  let z = days + 306
  let h = 100 * z - 25
  let a = fld(h, 3652425)
  let b = a - fld(a, 4)
  let y = fld(100 * b + h, 36525)
  let c = b + z - 365 * y  - fld(y, 4)
  let m = `div`(5 * c + 456, 153)
  let d = c - `div`(153 * m - 457, 5)
  if m > 12:
    result.year = int(y + 1)
    result.month = int(m - 12)
  else:
    result.year = int(y)
    result.month = int(m)
  result.day = int(d)

proc year*(days: SomeInteger): int =
  let z = days + 306
  let h = 100 * z - 25
  let a = fld(h, 3652425)
  let b = a - fld(a, 4)
  let y = fld(100 * b + h, 36525)
  let c = b + z - 365 * y - fld(y, 4)
  let m = `div`(5 * c + 456, 153)
  if m > 12:
    result = int(y + 1)
  else:
    result = int(y)

proc yearmonth*(days: int64): tuple[year: int, month: int] =
  let z = days + 306
  let h = 100 * z - 25
  let a = fld(h, 3652425)
  let b = a - fld(a, 4)
  let y = fld(100 * b + h, 36525)
  let c = b + z - 365 * y - fld(y, 4)
  let m = `div`(5 * c + 456, 153)
  if m > 12:
    result.year = int(y + 1)
    result.month = int(m - 12)
  else:
    result.year = int(y)
    result.month = int(m)

proc month*(days: int64): int =
  let z = days + 306
  let h = 100 * z - 25
  let a = fld(h, 3652425)
  let b = a - fld(a, 4)
  let y = fld(100 * b + h, 36525)
  let c = b + z - 365 * y - fld(y, 4)
  let m = `div`(5 * c + 456, 153)
  if m > 12:
    result = int(m - 12)
  else:
    result = int(m)

proc monthday*(days: int64): tuple[month: int, day: int] =
  let z = days + 306
  let h = 100 * z - 25
  let a = fld(h, 3652425)
  let b = a - fld(a, 4)
  let y = fld(100 * b + h, 36525)
  let c = b + z - 365 * y - fld(y, 4)
  let m = `div`(5 * c + 456, 153)
  let d = c - `div`(153 * m - 457, 5)
  if m > 12:
    result.month = int(m - 12)
  else:
    result.month = int(m)
  result.day = int(d)

proc day*(days: int64): int =
  let z = days + 306
  let h = 100 * z - 25
  let a = fld(h, 3652425)
  let b = a - fld(a, 4)
  let y = fld(100 * b + h, 36525)
  let c = b + z - 365 * y - fld(y, 4)
  let m = `div`(5 * c + 456, 153)
  let d = c - `div`(153 * m - 457, 5)
  result = int(d)

proc divrem[T, U](x: T, y: U): (int64, int64) =
  let x = int64(x)
  let y = int64(y)
  result[0] = x div y
  result[1] = x mod y

# https://en.wikipedia.org/wiki/Talk:ISO_week_date#Algorithms
const WEEK_INDEX = [0, 15, 23, 3, 11]
proc week*(days: int64): int64 =
  var w = `div`(abs(days - 1), 7) mod 20871
  var c: int64
  (c, w) = divrem((w + int(w >= 10435)), 5218)
  w = (w * 28 + WEEK_INDEX[c + 1]) mod 1461
  result = `div`(w, 28) + 1

proc toDateTime*(d: Date): DateTime =
  result.instant.periods.value = d.instant.periods.value * 86400000'i64

proc toDate*(dt: DateTime): Date =
  result.instant.periods.value = fld(dt.instant.periods.value, 86400000'i64)

proc toDate*(d: TDay): Date =
  result.instant.periods.value = d.value

proc toDay*(dt: DateTime|Date): TDay =
  result.value = days(dt)


converter toTime*(dt: DateTime): Time =
  when defined(js):
    Time(instant: UTInstant(periods: TNanosecond(value: int64((value(dt).float64 mod 86400000.0).float64 * 1000000.0))))
  else:
    Time(instant: UTInstant(periods: TNanosecond(value: (value(dt) mod 86400000) * 1000000)))

# Accessor functions
proc value*(d: Date): int64 = d.instant.periods.value
proc value*(d: DateTime): int64 = d.instant.periods.value
proc value*(t: Time): int64 = t.instant.periods.value

proc year*(dt: DateTime|Date): int64 = year(days(dt))
proc Year*(dt:DateTime|Date): TYear = TYear(kind: pkYear, value: year(dt))
proc month*(dt: DateTime|Date): int64 = month(days(dt))
proc Month*(dt:DateTime|Date): TMonth = TMonth(kind: pkMonth, value: month(dt))
proc week*(dt: DateTime|Date): int64 = week(days(dt))
proc Week*(dt:DateTime|Date): TWeek = TWeek(kind: pkWeek, value: week(dt))
proc day*(dt: DateTime|Date): int64 = day(days(dt))
proc Day*(dt:DateTime|Date): TDay = TDay(kind: pkDay, value: day(dt))
proc hour*(dt:DateTime): int64 = modulo(fld(value(dt), 3600000), 24)
proc Hour*(dt:DateTime): THour = THour(kind: pkHour, value: hour(dt))
proc minute*(dt:DateTime): int64 = modulo(fld(value(dt), 60000), 60)
proc Minute*(dt:DateTime): TMinute = TMinute(kind: pkMinute, value: minute(dt))
proc second*(dt:DateTime): int64 = modulo(fld(value(dt), 1000), 60)
proc Second*(dt:DateTime): TSecond = TSecond(kind: pkSecond, value: second(dt))
proc millisecond*(dt:DateTime): int64 = modulo(value(dt), 1000.0)
proc Milliecond*(dt:DateTime): TMillisecond = TMillisecond(kind: pkMillisecond, value: millisecond(dt))
#proc hour*(t:Time): int64 = modulo(fld(value(t), 3600000000000), int64(24))
proc hour*(t:Time): int64 = fld(value(t), 3600000000000)
proc Hour*(t:Time): THour = THour(kind: pkHour, value: hour(t))
proc minute*(t:Time): int64 = modulo(fld(value(t), 60000000000), int64(60))
proc Minute*(t:Time): TMinute = TMinute(kind: pkMinute, value: minute(t))
proc second*(t:Time): int64 = modulo(fld(value(t), 1000000000), int64(60))
proc Second*(t:Time): TSecond = TSecond(kind: pkSecond, value: second(t))
proc millisecond*(t:Time): int64 = modulo(fld(value(t), int64(1000000)), int64(1000))
proc Millisecond*(t:Time): TMillisecond = TMillisecond(kind: pkMillisecond, value: millisecond(t))
when defined(js):
  proc microsecond*(t:Time): int64 =
    result = modulo(fld(value(t), 1000.0), 1000.0)
else:
  proc microsecond*(t:Time): int64 = modulo(fld(value(t), 1000), 1000)
proc Microsecond*(t:Time): TMicrosecond = TMicrosecond(kind: pkMicrosecond, value: microsecond(t))
proc nanosecond*(t:Time): int64 = modulo(value(t), int64(1000))
proc Nanosecond*(t:Time): TNanosecond = TNanosecond(kind: pkNanosecond, value: nanosecond(t))

proc dayofmonth*(dt:DateTime|Date): int64 = day(dt)
proc yearmonth*(dt: DateTime|Date): tuple[year: int, month: int] = yearmonth(days(dt))
proc monthday*(dt: DateTime|Date): tuple[month, day: int] = monthday(days(dt))
proc yearmonthday*(dt: DateTime|Date): tuple[year, month, day: int] = yearmonthday(days(dt))

proc isleapyear*(dt: DateTime|Date): bool = isleapyear(year(dt))

proc mod1[T, U](x: T, y: U): int =
  let m = modulo(x, y)
  if m == 0:
    result = int(y)
  else:
    result = m

# Monday = 1....Sunday = 7
proc dayofweek*(days: int64): int = mod1(days, 7)
proc dayofweek*(dt: DateTime|Date): int = dayofweek(days(dt))

proc dayofweekofmonth*(dt: DateTime|Date): int =
    let d = day(dt)
    if d < 8:
      result = 1
    elif d < 15:
      result = 2
    elif d < 22:
      result = 3
    elif d < 29:
      result = 4
    else:
      result = 5

# Total number of a day of week in the month
# e.g. are there 4 or 5 Mondays in this month?
const TWENTYNINE = {1, 8, 15, 22, 29}
const THIRTY = {1, 2, 8, 9, 15, 16, 22, 23, 29, 30}
const THIRTYONE = {1, 2, 3, 8, 9, 10, 15, 16, 17, 22, 23, 24, 29, 30, 31}

proc daysofweekinmonth*(dt: DateTime|Date): int =
  let (y, m, d) = yearmonthday(dt)
  let ld = daysinmonth(y, m)
  if ld == 28:
    result = 4
  elif ld == 29:
    if d in TWENTYNINE:
      result = 5
    else:
      result = 4
  elif ld == 30:
    if d in THIRTY:
      result = 5
    else:
      result = 4
  else:
    if d in THIRTYONE:
      result = 5
    else:
      result = 4

proc daysinyear*(y: int64): int64 = 365 + int(isleapyear(y))

# Convenience methods for each day
proc ismonday*(dt: DateTime|Date): bool = dayofweek(dt) == 1
proc istuesday*(dt: DateTime|Date): bool = dayofweek(dt) == 2
proc iswednesday*(dt: DateTime|Date): bool = dayofweek(dt) == 3
proc isthursday*(dt: DateTime|Date): bool = dayofweek(dt) == 4
proc isfriday*(dt: DateTime|Date): bool = dayofweek(dt) == 5
proc issaturday*(dt: DateTime|Date): bool = dayofweek(dt) == 6
proc issunday*(dt: DateTime|Date): bool = dayofweek(dt) == 7

# Day of the year
const MONTHDAYS: array[1..12, int] = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334]
proc dayofyear*(y, m, d: int64): int64 = MONTHDAYS[m] + d + int(m > 2 and isleapyear(y))
proc dayofyear*(dt: DateTime|Date): int64 =
  result = dayofyear(year(dt), month(dt), day(dt))

proc `$`*(d: Date): string =
  result = intToStr(year(d).int, 4)
  result.add("-")
  result.add(intToStr(int(month(d)), 2))
  result.add("-")
  result.add(intToStr(int(day(d)), 2))

proc `$`*(dt: DateTime): string =
  result = intToStr(year(dt).int, 4)
  result.add("-")
  result.add(intToStr(int(month(dt)), 2))
  result.add("-")
  result.add(intToStr(int(day(dt)), 2))
  result.add("T")
  result.add(intToStr(int(hour(dt)), 2))
  result.add(":")
  result.add(intToStr(int(minute(dt)), 2))
  result.add(":")
  result.add(intToStr(int(second(dt)), 2))
  result.add(".")
  result.add(intToStr(int(millisecond(dt)), 3).strip(chars = {'0'}, leading=false))
  result = result.strip(chars = {'.'}, leading=false)

proc `$`*(t: Time): string =
  result = intToStr(hour(t).int, 2)
  result.add(":")
  result.add(intToStr(int(minute(t)), 2))
  result.add(":")
  result.add(intToStr(int(second(t)), 2))
  result.add(".")
  let ns = millisecond(t) * 1_000_000 + microsecond(t) * 1000 + nanosecond(t)
  result.add(intToStr(int(ns),9).strip(chars = {'0'}, leading=false))
  result = result.strip(chars = {'.'}, leading=false)

proc monthname*(dt: DateTime|Date, locale: string = "english"): string =
  monthname(int(month(dt)), locale=locale)

proc monthabbr*(dt: DateTime|Date, locale: string = "english"): string =
  monthabbr(int(month(dt)), locale=locale)

proc dayname*(dt: DateTime|Date, locale: string = "english"): string =
  dayname(int(dayofweek(dt)), locale=locale)

proc dayabbr*(dt: DateTime|Date, locale: string = "english"): string =
  dayabbr(int(dayofweek(dt)), locale=locale)

proc daysinyear*(dt: DateTime|Date): int =
  result = int(daysinyear(year(dt)))

proc daysinmonth*(dt: DateTime|Date): int =
  let (y, m) = yearmonth(dt)
  result = int(daysinmonth(int(y), int(m)))

proc quarterofyear*(dt: DateTime|Date): int =
  let m = month(dt)
  if m < 4:
    result = 1
  elif m < 7:
    result = 2
  elif m < 10:
    result = 3
  else:
    result = 4

const QUARTERDAYS: array[1..4, int] = [0, 90, 181, 273]

proc dayofquarter*(dt: DateTime|Date): int =
  int(dayofyear(dt) - QUARTERDAYS[quarterofyear(dt)])

# Instant arithmetic
proc `-`*[T: Instant|UTInstant](x, y: T): T =
  result = x.periods - y.periods

# Time arithmetic
proc `-`*[T: TimeType|Time](x, y: T): Time =
  result.instant.periods.value = x.instant.periods.value - y.instant.periods.value

# Date-Time arithmetic
proc `+`*(dt: Date, t: Time): DateTime =
  let (y, m, d) = yearmonthday(dt)
  result = initDateTime(y, m, d, int(hour(t)), int(minute(t)), int(second(t)), int(millisecond(t)))

template `+`*(t: Time, dt: Date) = dt + t


# TimeType-Year arithmetic
proc `+`*(dt: DateTime, y: TYear): DateTime =
  let (oy, m, d) = yearmonthday(dt)
  let ny = oy + value(y)
  let ld = daysinmonth(ny, m)
  result = initDateTime(ny, m, (if d <= ld: d else: ld), hour(dt), minute(dt), second(dt), millisecond(dt))

proc `+`*(dt: Date, y: TYear): Date =
  let (oy, m, d) = yearmonthday(dt)
  let ny = oy + value(y)
  let ld = daysinmonth(ny, m)
  result = initDate(ny, m, (if d <= ld: d else: ld))

proc `-`*(dt: DateTime, y: TYear): DateTime =
  let (oy, m, d) = yearmonthday(dt)
  let ny = oy - value(y)
  let ld = daysinmonth(ny, m)
  result = initDateTime(ny, m, min(d, ld), hour(dt), minute(dt), second(dt), millisecond(dt))

proc `-`*(dt: Date, y: TYear): Date =
  let (oy, m, d) = yearmonthday(dt)
  let ny = oy - value(y)
  let ld = daysinmonth(ny, m)
  result =  initDate(ny, m, min(d, ld))

# TimeType-Month arithmetic
# monthwrap adds two months with wraparound behavior (i.e. 12 + 1 == 1)
proc monthwrap*(m1, m2: int64): int64 =
  let v = mod1(m1 + m2, 12)
  if v < 0:
    result = 12 + v
  else:
    result = v

# yearwrap takes a starting year/month and a month to add and returns
# the resulting year with wraparound behavior (i.e. 2000-12 + 1 == 2001)
proc yearwrap*(y, m1, m2: int64): int64 =
  result = y + fld(m1 + m2 - 1, 12)

proc `+`*(dt: DateTime, z: TMonth): DateTime =
  let (y,m,d) = yearmonthday(dt)
  let ny = yearwrap(y, m, value(z))
  let mm = monthwrap(m, value(z))
  let ld = daysinmonth(ny, mm)
  result = initDateTime(ny, mm, min(d, ld), hour(dt), minute(dt), second(dt), millisecond(dt))

proc `+`*(dt: Date, z: TMonth): Date =
  let (y,m,d) = yearmonthday(dt)
  let ny = yearwrap(y, m, value(z))
  let mm = monthwrap(m, value(z))
  let ld = daysinmonth(ny, mm)
  result = initDate(ny, mm, min(d, ld))

proc `-`*(dt: DateTime, z: TMonth): DateTime =
  let (y,m,d) = yearmonthday(dt)
  let ny = yearwrap(y, m, -value(z))
  let mm = monthwrap(m, -value(z))
  let ld = daysinmonth(ny, mm)
  result = initDateTime(ny, mm, min(d, ld), hour(dt), minute(dt), second(dt), millisecond(dt))

proc `-`*(dt: Date, z: TMonth): Date =
  let (y,m,d) = yearmonthday(dt)
  let ny = yearwrap(y, m, -value(z))
  let mm = monthwrap(m, -value(z))
  let ld = daysinmonth(ny, mm)
  result = initDate(ny, mm, min(d, ld))

proc `+`*(dt: Date, cp: TCompoundPeriod): Date =
  let (y, m, d) = yearmonthday(dt)
  let totalMonths = y * 12 + m - 1 + cp.years.value * 12 + cp.months.value
  let year = fld(totalMonths, 12)
  let month = modulo(totalMonths, 12) + 1
  let day = min(daysinmonth(year, month), d)
  var ordinal = (toOrdinalFromYMD(year, month, day)) + cp.weeks.value * 7 + cp.days.value
  result = Date(instant: UTD(ordinal))

template `+`*(cp: TCompoundPeriod, dt: Date) =
  dt + cp

proc `-`*(dt: Date, cp: TCompoundPeriod): Date =
  result = dt + (-cp)

proc `+`*(dt: DateTime, cp: TCompoundPeriod): DateTime =
  let (y, m, d) = yearmonthday(dt)
  let totalMonths = y * 12 + m - 1 + cp.years.value * 12 + cp.months.value
  let year = fld(totalMonths, 12)
  let month = modulo(totalMonths, 12) + 1
  let day = min(daysinmonth(year, month), d)
  var ordinal = (toOrdinalFromYMD(year, month, day)) + cp.weeks.value * 7 + cp.days.value

  var mseconds = ordinal * 86400000
  mseconds += (hour(dt) + cp.hours.value) * 3600000
  mseconds += (minute(dt) + cp.minutes.value) * 60000
  mseconds += (second(dt) + cp.seconds.value) * 1000
  mseconds += (millisecond(dt) + cp.milliseconds.value)
  result = DateTime(instant: UTM(mseconds))

template `+`*(cp: TCompoundPeriod, dt: DateTime): DateTime =
  dt + cp

proc `-`*(dt: DateTime, cp: TCompoundPeriod): DateTime =
  result = dt + (-cp)


proc toTimeInterval*(dt1, dt2: DateTime): TCompoundPeriod =
  ## calculate the `TimeInterval` between two `DateTime`
  ## a loopless implementation inspired in the date part
  ## by the until Method of the new java.time.LocalDate class
  ##

  var (dt1, dt2) = (dt1, dt2)
  var sign = 1
  if dt2 < dt1:
    when defined(js):
      # inplace swapping doesn't work on the js backend
      let tmp = dt1
      dt1 = dt2
      dt2 = tmp
    else:
      (dt1, dt2) = (dt2, dt1)
    sign = -1
  echo "dt1: ", dt1, " dt2: ", dt2
  #echo toTime(dt1), " ", toTime(dt2)
  let ts1 = value(toTime(dt1)) div 1_000_000
  let ts2 = value(toTime(dt2)) div 1_000_000
  #echo "ts1: ", ts1, " ts2: ", ts2, " dt1: ", dt1, " dt2: ", dt2

  let difftime = ts2 - ts1
  #echo "difftime: ", difftime

  let diffdays = fld(difftime, 86400000)
  echo "diffdays: ", diffdays
  var diffmseconds = difftime - 86400000 * diffdays
  let diffhours = fld(diffmseconds, 3600000)
  let diffminutes = fld(diffmseconds - 3600000 * diffhours, 60000)
  diffmseconds = diffmseconds - 3600000 * diffhours - 60000 * diffminutes
  let diffseconds = fld(diffmseconds, 1000)
  diffmseconds = diffmseconds - 1000 * diffseconds
  dt2.instant.periods.value = dt2.value + diffdays * 86400000

  let (y1, m1, d1) = yearmonthday(dt1)
  echo "y1: ", y1, " ", m1, " ", d1
  let (y2, m2, d2) = yearmonthday(dt2)
  echo "y2: ", y2, " ", m2, " ", d2
  var totalMonths = y2 * 12 - y1 * 12 + m2 - m1
  echo "totalMonths: ", totalMonths

  var days = d2 - d1
  echo "days: ", days
  if (totalMonths > 0 and days < 0):
    totalMonths.dec
    let tmpDate = dt1 + Month(totalMonths)
    days = int(toDate(dt2).value - toDate(tmpDate).value)
  elif (totalMonths < 0 and days > 0):
    totalMonths.inc
    days = days - daysinmonth(y2, m2) + 1
  let years = totalMonths div 12
  let months = totalMonths mod 12

  return CompoundPeriod(years = Year(sign * years),
                        months = Month(sign * months),
                        days = Day(sign * days),
                        hours = Hour(sign * diffhours),
                        minutes = Minute(sign * diffminutes),
                        seconds = Second(sign * diffseconds),
                        milliseconds = Millisecond(sign * diffmseconds))


# truncating conversions to milliseconds and days:
proc tons*(p: Period): int64 =
  case p.kind
  of pkYear:
    return int64(86400000.0 * 365.2425 * float64(p.value) * 1_000_000)
  of pkMonth:
    return int64(86400000.0 * 30.436875 * float64(p.value) * 1_000_000)
  of pkWeek:
    return 604800000 * p.value * 1_000_000
  of pkDay:
    return p.value * 86400 * 1000 * 1_000_000
  of pkHour:
    return p.value * 3600 * 1000 * 1_000_000
  of pkMinute:
    return p.value * 60 * 1000 * 1_000_000
  of pkSecond:
    return p.value * 1000 * 1_000_000
  of pkMillisecond:
    return p.value * 1_000_000
  of pkMicrosecond:
    return p.value * 1000
  of pkNanosecond:
    return p.value
  else:
    raise newException(ValueError, "conversion to millisecond from " & $p.kind & " not defined")

proc toms*(c: Time): int64 = `div`(value(c), 1_000_000)
proc toms*(c: TNanosecond): int64  = `div`(value(c), 1000000)
proc toms*(c: TMicrosecond): int64 = `div`(value(c), 1000)
proc toms*(c: TMillisecond): int64 = value(c)
proc toms*(c: TSecond): int64      = 1000 * value(c)
proc toms*(c: TMinute): int64      = 60000 * value(c)
proc toms*(c: THour): int64        = 3600000 * value(c)
proc toms*(c: TDay): int64         = 86400000 * value(c)
proc toms*(c: TWeek): int64        = 604800000 * value(c)
proc toms*(c: TMonth): float64     = 86400000.0 * 30.436875 * float64(value(c))
proc toms*(c: TYear): float64      = 86400000.0 * 365.2425 * float64(value(c))

proc tons*(c: TCompoundPeriod): float64 =
  result = 0.0
  result += tons(c.years).float64
  result += tons(c.months).float64
  result += tons(c.weeks).float64
  result += tons(c.days).float64
  result += tons(c.hours).float64
  result += tons(c.minutes).float64
  result += tons(c.seconds).float64
  result += tons(c.milliseconds).float64
  result += tons(c.microseconds).float64
  result += tons(c.nanoseconds). float64

proc tons*[T: TimePeriod](x: T): int64 = toms(x) * 1_000_000
proc tons*(x: TMicrosecond): int64 = value(x) * 1_000
proc tons*(x: TNanosecond): int64  = value(x)

proc days*(c: TMillisecond): int64 = `div`(value(c), 86_400_000)
proc days*(c: TSecond): int64      = `div`(value(c), 86_400)
proc days*(c: TMinute): int64      = `div`(value(c), 1_440)
proc days*(c: THour): int64        = `div`(value(c), 24)
proc days*(c: TDay): int64         = value(c)
proc days*(c: TWeek): int64        = 7 * value(c)
proc days*(c: TYear): float64      = 365.2425 * float64(value(c))
proc days*(c: TMonth): float64     = 30.436875 * float64(value(c))
proc days(c: TCompoundPeriod): float64 =
  result = 0.0
  result += days(c.years).float64
  result += days(c.months).float64
  result += days(c.weeks).float64
  result += days(c.days).float64
  result += days(c.hours).float64
  result += days(c.minutes).float64
  result += days(c.seconds).float64
  result += days(c.milliseconds).float64
#  result += days(c.microseconds).float64
#  result += days(c.nanoseconds). float64

proc `+`*(x: Date, y: TWeek): Date =
  result.instant.periods.value = x.instant.periods.value + 7 * y.value
proc `-`*(x: Date, y: TWeek): Date =
  result.instant.periods.value = x.instant.periods.value - 7 * y.value

when defined(js):
  proc `+`*[P](x: DateTime, y: P): DateTime =
    result = DateTime(instant: UTM(int64(value(x).float64 + float64(toms(y)))))
  proc `-`*[P](x: DateTime, y: P): DateTime =
    result = DateTime(instant: UTM(int64(value(x).float64 - float64(toms(y)))))
else:
  proc `+`*[P](x: DateTime, y: P): DateTime =
    result.instant.periods.value = x.instant.periods.value + int64(toms(y))

  proc `-`*[P](x: DateTime, y: P): DateTime =
    result.instant.periods.value = x.instant.periods.value - int64(toms(y))

proc `-`*(x, y: DateTime): TMillisecond =
  TMillisecond(value: x.instant.periods.value - y.instant.periods.value)

proc `-`*(x, y: Date): TDay =
  result.value = x.instant.periods.value - y.instant.periods.value

proc `+`*[P: TimePeriod](t: Time, dt: P): Time =
  result.instant.periods.value = t.instant.periods.value + tons(dt)

proc `-`*[P: TimePeriod](t: Time, dt: P): Time =
  result.instant.periods.value = t.instant.periods.value - tons(dt)

const UNIXEPOCH* = value(initDateTime(1970)) #Rata Die milliseconds for 1970-01-01T00:00:00

proc unix2datetime*(x: float64): DateTime =
  when defined(js):
    let rata = int64(UNIXEPOCH.float64 + round(1000 * x))
  else:
    let rata = UNIXEPOCH + int64(round(1000 * x))
  result = DateTime(instant: UTM(rata))

proc datetime2unix*(dt: DateTime): float64 = float64(value(dt) - UNIXEPOCH) / 1000.0

proc datetime2rata*(dt: DateTime|Date): int64 =
  result = days(dt)

proc rata2date*(days: int64): Date =
  let (y, m, d) = yearmonthday(days)
  result = initDate(y, m, d)

proc rata2datetime*(days: int64): DateTime =
  let (y, m, d) = yearmonthday(days)
  result = initDateTime(y, m, d)

const JULIANDAYEPOCH = value(initDateTime(-4713, 11, 24, 12))
const JULIANEPOCH = totaldays(0, 12, 30)

proc isjulianleapyear*(j_year: SomeNumber): bool =
  ## Return True if Julian year 'j_year' is a leap year in
  ## the Julian calendar.
  let j_year = int(j_year)
  result = modulo(j_year, 4) == (if j_year > 0: 0 else: 3)

proc julian2rata*(dt: DateTime|Date): int64 =
  let (yr, m, d) = yearmonthday(dt)
  let y = (if yr < 0: yr + 1 else: yr)
  result = (JULIANEPOCH - 1 +
            (365 * (y - 1)) +
            fld(y - 1, 4) +
            fld(367 * m - 362, 12) +
            (if m <= 2: 0 else: (if isjulianleapyear(yr): -1  else: -2)) + d)

proc rata2julian*(days: SomeNumber): Date =
  ## Return the Julian date corresponding to fixed date 'date'.
  ## see lines 1084-1111 in calendrica-3.0.cl
  let days = int64(days)
  let approx     = fld(((4 * (days - JULIANEPOCH))) + 1464, 1461)
  let year       = if approx <= 0: approx - 1 else: approx
  let prior_days = days - julian2rata(initDate(year, 1, 1))
  let correction = (if days < julian2rata(initDate(year, 3, 1)): 0 else:
                   (if isjulianleapyear(year): 1 else: 2))
  let month      = fld(12*(prior_days + correction) + 373, 367)
  let day        = 1 + (days - julian2rata(initDate(year, month, 1)))
  result = initDate(year, month, day)

proc julianday2datetime*(julian: float64): DateTime =
  let rata = JULIANDAYEPOCH + int64(round(86400000.0 * julian))
  result = DateTime(instant: UTM(rata))

proc datetime2julianday*(dt: DateTime): float64 =
  result = float64(value(dt) - JULIANDAYEPOCH) / 86400000.0

proc tonth*[T](start: T, n: int, dow: int, same = false): T {.gcsafe.}

proc iso2rata*(iwd: ISOWeekDate): int64 =
  days(tonth(initDate(iwd.year - 1, 12, 28), iwd.week.int, 7)) + iwd.weekday

proc iso2rata*(y, w, wd: SomeNumber): int64 =
  days(tonth(initDate(y - 1, 12, 28), w.int, 7)) + wd

proc rata2iso*(days: int64): ISOWeekDate =
  let ordinal = days
  let approx = year(ordinal - 3)
  var year = approx
  if ordinal >= iso2rata(approx + 1, 1, 1):
    year += 1
  let week = 1 + fld(ordinal - iso2rata(year, 1, 1), 7)
  let day = dayofweek(days)

  result.year = year
  result.week = week
  result.weekday = day

proc isoweekdate*(dt: DateTime|Date): ISOWeekDate =
  result = rata2iso(datetime2rata(dt))

proc now*(): DateTime =
  return unix2datetime(epochTime())

proc today*(): Date =
  return toDate(now())

proc `==`*[T, U: Period](x: T, y: U): bool =
  if x.kind == y.kind:
    result = x.value == y.value
  else:
    result = tons(x) == tons(y)

proc `!=`*[T, U: Period](x: T, y: U): bool =
  if x.kind == y.kind:
    result = x.value != y.value
  else:
    result = tons(x) != tons(y)

proc `<=`*[T, U: Period](x: T, y: U): bool =
  if x.kind == y.kind:
    result = x.value <= y.value
  else:
    result = tons(x) <= tons(y)

proc `>=`*[T, U: Period](x: T, y: U): bool =
  if x.kind == y.kind:
    result = x.value >= y.value
  else:
    result = tons(x) >= tons(y)

proc `<`*[T, U: Period](x: T, y: U): bool =
  if x.kind == y.kind:
    result = x.value < y.value
  else:
    result = tons(x) < tons(y)

proc `<`*[T: Period, U: TCompoundPeriod](x: T, y: U): bool =
  result = initCompoundPeriod(x) < y

proc `<`*[U: TCompoundPeriod, T: Period](x: U, y: T): bool =
  result = x < initCompoundPeriod(y)


proc `>`*[T, U: Period](x: T, y: U): bool =
  if x.kind == y.kind:
    result = x.value > y.value
  else:
    result = tons(x) > tons(y)

proc `==`*(cp1, cp2: TCompoundPeriod): bool =
  result = tons(cp1) == tons(cp2)
proc `<`*(cp1, cp2: TCompoundPeriod): bool =
  result = tons(cp1) < tons(cp2)

proc `-`*[T: Period](x: T, y: T): T = T(kind: x.kind, value: x.value - y.value)
proc `+`*[T: Period](x: T, y: T): T = T(kind: x.kind, value: x.value + y.value)
proc lcm*[T: Period](x: T, y: T): T = T(kind: x.kind, value: lcm(x.value, y.value))
proc gcd*[T: Period](x: T, y: T): T = T(kind: x.kind, value: gcd(x.value, y.value))
proc `/`*[T: Period](x: T, y: T): SomeNumber = `/`(x.value.int, y.value.int)
proc `/`*[T: Period](x: T, y: SomeNumber): T = T(kind: x.kind, value: `/`(x.value.int, y.int))
proc `div`*[T: Period](x: T, y: T): auto = `div`(x.value, y.value)
proc `div`*[T: Period](x: T, y: SomeInteger): T = T(kind: x.kind, value: `div`(x.value.int, y.int))
proc fld*[T: Period](x: T, y: T): auto = floor(`/`(x.value.int, y.value.int)).int
proc fld*[T: Period](x: T, y: SomeNumber): T = T(kind: x.kind, value: floor(`/`(x.value.int, y.value.int)).int)
proc `mod`*[T: Period](x: T, y: T): T = T(kind: x.kind, value: `mod`(x.value, y.value))
proc `mod`*[T: Period](x: T, y: SomeNumber): T = T(kind: x.kind, value: `mod`(x.value, y))
proc modulo*[T: Period](x: T, y: T): T = T(kind: x.kind, value: x.value - y.value * fld(x.value, y.value))
proc modulo*[T: Period](x: T, y: SomeNumber): T = T(kind: x.kind, value: x.value - y * fld(x.value, y))

proc `*`*[T: Period](x: T, m: int): T = T(kind: x.kind, value: x.value * m)
template `*`*[T: Period](m: int, x: T): T = x * m

proc abs*[T: Period](x: T): T = T(kind: x.kind, value: abs(x.value))

proc `+`*(x: Date, y: TDay): Date =
  result.instant.periods.value = x.value + y.value

proc `-`*(x: Date, y: TDay): Date =
  result.instant.periods.value = x.value - y.value

proc firstdayofweek*(dt: Date): Date = Date(instant: UTD(value(dt) - dayofweek(dt) + 1))
proc firstdayofweek*(dt: DateTime): DateTime = toDateTime(firstdayofweek(toDate(dt)))
proc lastdayofweek*(dt: Date): Date = Date(instant: UTD(value(dt) + (7 - dayofweek(dt))))
proc lastdayofweek*(dt: DateTime): DateTime = toDateTime(lastdayofweek(toDate(dt)))
proc firstdayofmonth*(dt: Date): Date = Date(instant: UTD(value(dt) - day(dt) + 1))
proc firstdayofmonth*(dt: DateTime): DateTime = toDateTime(firstdayofmonth(toDate(dt)))
proc lastdayofmonth*(dt: Date): Date =
  let (y, m, d) = yearmonthday(dt)
  result = Date(instant: UTD(value(dt) + daysinmonth(y, m) - d))
proc lastdayofmonth*(dt: DateTime): DateTime = toDateTime(lastdayofmonth(toDate(dt)))
proc firstdayofyear*(dt: Date): Date = Date(instant: UTD(value(dt) - dayofyear(dt) + 1))
proc firstdayofyear*(dt: DateTime): DateTime = toDateTime(firstdayofyear(toDate(dt)))
proc lastdayofyear*(dt: Date): Date =
  let (y, m, d) = yearmonthday(dt)
  result = Date(instant: UTD(value(dt) + daysinyear(y) - dayofyear(y, m, d)))
proc lastdayofyear*(dt: DateTime): DateTime = toDateTime(lastdayofyear(toDate(dt)))
proc firstdayofquarter*(dt: Date): Date =
  let (y, m) = yearmonth(dt)
  let mm = (if m < 4: 1 else: (if m < 7: 4 else: (if m < 10: 7 else: 10)))
  result = initDate(y, mm, 1)
proc firstdayofquarter*(dt: DateTime): DateTime = toDateTime(firstdayofquarter(toDate(dt)))
proc lastdayofquarter*(dt: Date): Date =
  let (y, m) = yearmonth(dt)
  let (mm, d) = (if m < 4: (3, 31) else: (if m < 7: (6, 30) else: (if m < 10: (9, 30) else: (12, 31))))
  result = initDate(y, mm, d)
proc lastdayofquarter*(dt: DateTime): DateTime = toDateTime(lastdayofquarter(toDate(dt)))

type DateFunction* = proc(dt: DateTime|Date): bool

proc adjust*[P](df: proc(dt: Date): bool, start: Date, step: P, limit: int = 10000): Date =
  var curr = start
  for i in 1..limit:
    if df(curr):
       return curr
    curr = curr + step
  raise newException(ValueError, "Adjustment limit reached: $1 iterations" % [$limit])

proc adjust*[P](df: proc(dt: DateTime): bool, start: DateTime, step: P, limit: int = 10000): DateTime =
  var curr = start
  for i in 1..limit:
    if df(curr):
       return curr
    curr = curr + step
  raise newException(ValueError, "Adjustment limit reached: $1 iterations" % [$limit])

proc adjust*[P](tf: proc(t: Time): bool, start: Time, step: P, limit: int = 10000): Time =
  var curr = start
  for i in 1..limit:
    if tf(curr):
       return curr
    curr = curr + step
  raise newException(ValueError, "Adjustment limit reached: $1 iterations" % [$limit])

proc getDate*[P](df: proc(dt: Date): bool, y: SomeNumber, m, d: SomeNumber = 1,
                 step: P = Day(1), limit = 10000): Date =
  result = adjust(df, initDate(int(y), int(m), int(d)), step, limit)

proc getDateTime*[P](df: proc(dt: DateTime): bool, y: SomeNumber, m, d: SomeNumber = 1,
                     h, mi, s, ms: SomeNUmber = 0,
                     step: P, limit = 10000): DateTime =
  result = adjust(df, initDateTime(int(y), int(m), int(d), int(h), int(mi), int(s), int(ms)), step, limit)

proc getTime*[P](tf: proc(t: Time): bool, h: SomeNumber, mi, s, ms, us, ns: SomeNumber = 0, step: P, limit=10000): Time =
  result = adjust(tf, initTime(int(h), int(mi), int(s), int(ms), int(us), int(ns)), step, limit)

proc weekdayonorbefore*[T: Date|DateTime](dow: int, dt: T): T =
  let d = days(dt)
  result = dt - Day(modulo(d - dow, 7))

proc weekdayonorafter*[T: Date|DateTime](dow: int, dt: T): T =
  result = weekdayonorbefore(dow, dt + Day(6))

proc weekdaynearest*[T: Date|DateTime](dow: int, dt: T): T =
  result = weekdayonorbefore(dow, dt + Day(3))

proc weekdayafter*[T: Date|DateTime](dow: int, dt: T): T =
  result = weekdayonorbefore(dow, dt + Day(7))

proc weekdaybefore*[T: Date|DateTime](dow: int, dt: T): T =
  result = weekdayonorbefore(dow, dt - Day(1))

proc nthweekday*[T: Date|DateTime](nth: int, dow: int, dt: T): T =
  if nth > 0:
    result = weekdaybefore(dow, dt) + Day(7 * nth)
  elif nth < 0:
    result = weekdayafter(dow, dt) + Day(7 * nth)
  else:
    raise newException(ValueError, "0 is not a valid argument for nth in nthweekday")

proc tonext*(start: Date, dow: int, same = false): Date =
  result = adjust(proc(x: Date):bool = dayofweek(x) == dow,
                  if same: start else: start + 1.Day, Day(1), 366)

proc tonext*(start: DateTime, dow: int, same = false): DateTime =
  result = adjust(proc(x: DateTime):bool = dayofweek(x) == dow,
                  if same: start else: start + 1.Day, Day(1), 366)

proc tonext*[P](df: proc(x: Date):bool, start: Date, step: P,
                same = false, limit = 10000): Date =
  result = adjust(df, if same: start else: start + step, step, limit)

proc tonext*[P](df: proc(x: DateTime):bool, start: DateTime, step: P = Day(1),
                same = false, limit = 10000): DateTime =
  result = adjust(df, if same: start else: start + step, step, limit)

proc toprev*(start: Date, dow: int, same = false): Date =
  result = adjust(proc(x: Date):bool = dayofweek(x) == dow,
                  if same: start else: start - 1.Day, Day(-1), 366)

proc toprev*(start: DateTime, dow: int, same = false): DateTime =
  result = adjust(proc(x: DateTime):bool = dayofweek(x) == dow,
                  if same: start else: start - 1.Day, Day(-1), 366)

proc toprev*[P](df: proc(x: Date):bool, start: Date, step: P = Day(1),
              same = false, limit = 10000): Date =
  result = adjust(df, if same: start else: start - step, -step, limit)

proc toprev*[P](df: proc(x: DateTime):bool, start: DateTime, step: P = Day(-1),
                same = false, limit = 10000): DateTime =
  result = adjust(df, if same: start else: start + step, step, limit)

proc tonth*[T](start: T, n: int, dow: int, same = false): T =
  if n > 0:
    result = toprev(start, dow, same = false) + Day(7 * n)
  elif n < 0:
    result = tonext(start, dow, same = false) + Day(7 * n)
  else:
    raise newException(ValueError, "0 is not a valid argument for tonth")

proc tofirst*(dt: Date, dow: int, period: typedesc[Period]): Date =
  var dt = (if period is TMonth: firstdayofmonth(dt) else: firstdayofyear(dt))
  result = adjust(proc(x: Date):bool = dayofweek(x) == dow, dt, Day(1), 366)

proc tofirst*(dt: DateTime, dow: int, period: typedesc[Period]): DateTime =
  var dt = (if period is TMonth: firstdayofmonth(dt) else: firstdayofyear(dt))
  result = adjust(proc(x: DateTime):bool = dayofweek(x) == dow, dt, Day(1), 366)

proc tolast*(dt: Date, dow: int, period: typedesc[Period]): Date =
  var dt = (if period is TMonth: lastdayofmonth(dt) else: lastdayofyear(dt))
  result = adjust(proc(x: Date):bool = dayofweek(x) == dow, dt, Day(-1), 366)

proc tolast*(dt: DateTime, dow: int, period: typedesc[Period]): DateTime =
  var dt = (if period is TMonth: lastdayofmonth(dt) else: lastdayofyear(dt))
  result = adjust(proc(x: DateTime):bool = dayofweek(x) == dow, dt, Day(-1), 366)

proc isisolongyear*(yr: int64): bool =
  week(initDate(yr, 12, 31)) == 53

proc isisolongyear*(dt: DateTime|Date): bool =
  week(lastdayofyear(dt)) == 53

proc trunc*(x: Date, t: typedesc[Period]): Date =
  if t is TYear:
    result = Date(instant: UTD(totaldays(year(x), 1, 1)))
  elif t is TMonth:
    result = firstdayofmonth(x)
  else:
    result = x

proc trunc*(x: DateTime, t: typedesc[Period]): DateTime =
  if t is TYear or t is TMonth or t is TDay:
    result = toDateTime(trunc(toDate(x), t))
  elif t is THour:
    result = x - Minute(x) - Second(x) - Millisecond(x)
  elif t is TMinute:
    result = x - Second(x) - Millisecond(x)
  elif t is TSecond:
    result = x - Millisecond(x)
  else:
    result = x

proc trunc*(x: Time, t: typedesc[Period]): Time =
  if t is THour:
    result = initTime(hour(x))
  elif t is TMinute:
    result = initTime(hour(x), minute(x))
  elif t is TSecond:
    result = initTime(hour(x), minute(x), second(x))
  elif t is TMillisecond:
    result = x - Microsecond(x) - Nanosecond(x)
  elif t is TMicrosecond:
    result = x - Nanosecond(x)
  else:
    result = x

# rounding
# The epochs used for date rounding are based ISO 8601's "year zero" notation
const DATEEPOCH* = value(initDate(0))
const DATETIMEEPOCH* = value(initDateTime(0))

# According to ISO 8601, the first day of the first week of year 0000 is 0000-01-03
const WEEKEPOCH* = value(initDate(0, 1, 3))

proc epochdays2date*(days: SomeNumber): Date = Date(instant: UTD(DATEEPOCH + int64(days)))
proc epochms2datetime*(ms: SomeNumber): DateTime = DateTime(instant: UTM(DATETIMEEPOCH + int64(ms)))
proc date2epochdays*(dt: Date): int64 = value(dt) - DATEEPOCH
proc datetime2epochms*(dt: DateTime): int64 = value(dt) - DATETIMEEPOCH

proc floor*(dt: Date, p: TYear): Date =
  if value(p) < 1:
    raise newException(ValueError, "invalid value")
  let years = year(dt)
  result = initDate(years - modulo(years, value(p)))

proc floor*(dt: Date, p: TMonth): Date =
  if value(p) < 1:
    raise newException(ValueError, "invalid value")

  let (y, m) = yearmonth(dt)
  let months_since_epoch = y * 12 + m - 1
  let month_offset = months_since_epoch - modulo(months_since_epoch, value(p))
  let target_month = modulo(month_offset, 12) + 1
  let target_year = `div`(month_offset, 12) - int(month_offset < 0 and target_month != 1)
  result = initDate(target_year, target_month)

proc Day(w: TWeek): TDay =
  result = TDay(value: w.value * 7)

proc floor*(dt: Date, p: TWeek): Date =
  if value(p) < 1:
    raise newException(ValueError, "invalid value")
  var days = value(dt) - WEEKEPOCH
  days = days - modulo(days, value(Day(p)))
  result = Date(instant: UTD(WEEKEPOCH + int64(days)))

proc floor*(dt: Date, p: TDay): Date =
  if value(p) < 1:
    raise newException(ValueError, "invalid value")
  let days = date2epochdays(dt)
  result = epochdays2date(days - modulo(days, value(p)))

proc floor*[P: TYear|TMonth|TWeek|TDay](dt: DateTime, p: P): DateTime =
  result = toDateTime(floor(toDate(dt), p))

proc Millisecond*[P: Period](p: P): TMillisecond =
  case p.kind
  of pkWeek:
    result = Millisecond(p.value * 7 * 86400 * 1000)
  of pkDay:
    result = Millisecond(p.value * 86400 * 1000)
  of pkHour:
    result = Millisecond(p.value * 3600 * 1000)
  of pkMinute:
    result = Millisecond(p.value * 60 * 1000)
  of pkSecond:
    result = Millisecond(p.value * 1000)
  of pkMillisecond:
    result = Millisecond(p.value)
  of pkMicrosecond:
    result = Millisecond(p.value div 1000)
  of pkNanosecond:
    result = Millisecond(p.value div 1_000_000)
  else:
    raise newException(ValueError, "period of kind: " & $p.kind & "can't be converted to milliseconds")

template Milliseconds*[P: Period](p: P):TMillisecond = Millisecond(P)

proc floor*[P: TimePeriod](dt: DateTime, p: P): DateTime =
  if value(p) < 1:
    raise newException(ValueError, "invalid value")
  let milliseconds = datetime2epochms(dt)
  result = epochms2datetime(milliseconds - modulo(milliseconds, value(Millisecond(p))))

proc floor*[P: TimePeriod](t: Time, p: P): Time =
  if value(p) < 1:
    raise newException(ValueError, "invalid value")
  let ns = value(t)
  result.instant.periods.value = ns - modulo(ns, tons(p))

proc ceil*[T: Date|DateTime|Time, P: DatePeriod|TimePeriod](dt: T, p: P): T =
  let f = floor(dt, p)
  if `==`(dt, f):
    result = f
  else:
    result = f + p

proc floorceil*[T: Date|DateTime|Time, P: DatePeriod|TimePeriod](dt: T, p: P): (T, T) =
  let f = floor(dt, p)
  result[0] = f
  if dt == f:
    result[1] = f
  else:
    result[1] = f + p

proc round*[T: Date|DateTime|Time, P: Period](dt: T, p: P): T =
  let (f, c) = floorceil(dt, p)
  if (dt - f) < (c - dt):
    result = f
  else:
    result = c

proc strptime*(value: string, fmtstr: string, locale = "english", twoDigitYearFlag=false): DateTime =
  var y, m, d, h, mi, s, ms = 0
  y = 1
  m = 1
  d = 1
  var hoff, moff, soff = 0

  var i = 0 # index into fmtstr
  var j = 0 # index into value
  var x = 0
  var numberstr = ""
  var namestr = ""
  let fmtLength = len(fmtstr)
  let vLength = len(value)
  var isISOWeekDate = false
  var week = 0
  var weekday = 0
  while i < fmtLength:
    if fmtstr[i] == '%':
      if i + 1 == fmtLength:
        break
      inc(i)
      case fmtstr[i]
      of 'a', 'A':
        inc(i)
        if value[j] notin {'a'..'z', 'A'..'Z'}:
          x = parseUntil(value, numberstr, {'a'..'z', 'A'..'Z'}, j)
          j += x
          if j >= vLength:
            raise newException(ValueError, "no valid string found to parse as dayname")
        x = parseWhile(value, namestr, {'a'..'z','A'..'Z'}, j)
        if x == 0:
          raise newException(ValueError, "no valid string found to parse as dayname")
        j += x
        namestr = toLowerAscii(namestr)
        x = dayabbr_to_value(namestr[0..2], LOCALES[locale])
        if x == 0:
          raise newException(ValueError, "unknown dayname: " & namestr)
      of 'b', 'B':
        inc(i)
        if value[j] notin {'a'..'z', 'A'..'Z'}:
          x = parseUntil(value, numberstr, {'a'..'z', 'A'..'Z'}, j)
          j += x
          if j >= vLength:
            raise newException(ValueError, "no valid string found to parse as month")
        x = parseUntil(value, namestr, Whitespace + {'0'..'9'} + {'.',',',';','-','/','#','%','#','@','+','&',':','[',']','{','}','?'}, j)
        if x == 0:
          raise newException(ValueError, "no valid string found to parse as month")
        namestr = toLowerAscii(namestr)
        m = monthabbr_to_value(namestr, LOCALES[locale])
        if m == 0:
          m = monthname_to_value(namestr, LOCALES[locale])
          if m == 0:
            raise newException(ValueError, "unknown month: " & namestr)
        j += x
      of 'y', 'Y', 'G':
        inc(i)
        if fmtstr[i] == 'G':
          isISOWeekDate = true
        var sign = 1
        if value[j] notin {'-', '0'..'9'}:
          x = parseUntil(value, numberstr, {'-', '0'..'9'}, j)
          j += x
          if j >= vLength:
            raise newException(ValueError, "no valid number found to parse as year")
        if value[j] == '-':
          if i > 3 and fmtstr[i - 3] != '-':
            sign = -1
          inc(j)
        x = parseWhile(value, numberstr, {'0'..'9'}, j)
        if x == 0:
          raise newException(ValueError, "no valid number found to parse as year")
        case len(numberstr)
        of 1,2,3,4:
          y = parseInt(numberstr) * sign
          j += x
        else:
          if fmtstr[i] == '%':
            dec(i)
            if len(numberstr) > 8:
              let tmpl = len(numberstr) - 5
              y = parseInt(numberstr[0..tmpl])
              j += tmpl
            else:
              y = parseInt(numberstr[0..3])
              j += 4
          else:
            y = parseInt(numberstr)
            j += x
        if twoDigitYearFlag and y < 100:
          let currentYear = year(today())
          y = int(currentYear - currentYear mod 100 + y)
          j += 2
      of 'm':
        inc(i)
        if value[j] notin {'0'..'9'}:
          x = parseUntil(value, numberstr, {'0'..'9'}, j)
          j += x
          if j >= vLength:
            raise newException(ValueError, "no valid number found to parse as month")
        x = parseWhile(value, numberstr, {'0'..'9'}, j)
        if x == 0:
          raise newException(ValueError, "no valid number found to parse as month")
        case x
        of 1,2:
          m = parseInt(numberstr)
          j += x
        else:
          if fmtstr[i] == '%':
            dec(i)
          m = parseInt(numberstr[0..1])
          j += 2
        if m < 1 or m > 12:
          raise newException(ValueError, "invalid month: " & numberstr)
      of 'd':
        inc(i)
        if value[j] notin {'0'..'9'}:
          x = parseUntil(value, numberstr, {'0'..'9'}, j)
          j += x
          if j >= vLength:
            raise newException(ValueError, "no valid number found to parse as day")
        x = parseWhile(value, numberstr, {'0'..'9'}, j)
        if x == 0:
          raise newException(ValueError, "no valid number found to parse as day")
        case len(numberstr)
        of 1,2:
          d = parseInt(numberstr)
          j += x
        else:
          if fmtstr[i] == '%':
            dec(i)
            d = parseInt(numberstr[0..1])
            j += 2
        if d < 1 or d > 31:
          raise newException(ValueError, "invalid day: " & numberstr)
        #j += x
      of 'V':
        inc(i)
        if value[j] notin {'0'..'9'}:
          x = parseUntil(value, numberstr, {'0'..'9'}, j)
          j += x
          if j >= vLength:
            raise newException(ValueError, "no valid number found to parse as ISO week")
        x = parseWhile(value, numberstr, {'0'..'9'}, j)
        if x == 0:
          raise newException(ValueError, "no valid number found to parse as ISO week")
        week = parseInt(numberstr)
        if week < 1 or week > 53:
          raise newException(ValueError, "invalid ISO week: " & numberstr)
        isISOWeekDate = true
        j += x
      of 'u':
        inc(i)
        if value[j] notin {'0'..'9'}:
          x = parseUntil(value, numberstr, {'0'..'9'}, j)
          j += x
          if j >= vLength:
            raise newException(ValueError, "no valid number found to parse as ISO weekday")
        x = parseWhile(value, numberstr, {'0'..'9'}, j)
        if x == 0:
          raise newException(ValueError, "no valid number found to parse as ISO weekday")
        weekday = parseInt(numberstr)
        if weekday < 1 or weekday > 7:
          raise newException(ValueError, "invalid ISO weekday: " & numberstr)
        isISOWeekDate = true
        j += x

      of 'h', 'H':
        inc(i)
        if value[j] notin {'0'..'9'}:
          x = parseUntil(value, numberstr, {'0'..'9'}, j)
          j += x
          if j >= vLength:
            raise newException(ValueError, "no valid number found to parse as hour")
        x = parseWhile(value, numberstr, {'0'..'9'}, j)
        if x == 0:
          raise newException(ValueError, "no valid number found to parse as hour")
        if x > 2:
          dec(i)
          h = parseInt(numberstr[0..1])
          j += 2
        else:
          h = parseInt(numberstr)
          j += x
        if h < 0 or h > 24:
          raise newException(ValueError, "invalid hour: " & numberstr)
      of 'M':
        inc(i)
        if value[j] notin {'0'..'9'}:
          x = parseUntil(value, numberstr, {'0'..'9'}, j)
          j += x
          if j >= vLength:
            raise newException(ValueError, "no valid number found to parse as minute")
        x = parseWhile(value, numberstr, {'0'..'9'}, j)
        if x == 0:
          raise newException(ValueError, "no valid number found to parse as minute")
        if x > 2:
          dec(i)
          mi = parseInt(numberstr[0..1])
          j += 2
        else:
          mi = parseInt(numberstr)
          j += x
        if mi < 0 or mi > 59:
          raise newException(ValueError, "invalid minute: " & numberstr)
      of 's', 'S':
        inc(i)
        if value[j] notin {'0'..'9'}:
          x = parseUntil(value, numberstr, {'0'..'9'}, j)
          j += x
          if j >= vLength:
            raise newException(ValueError, "no valid number found to parse as second")
        x = parseWhile(value, numberstr, {'0'..'9'}, j)
        if x == 0:
          raise newException(ValueError, "no valid number found to parse as second")
        s = parseInt(numberstr)
        if s < 0 or s > 61:
          raise newException(ValueError, "invalid second: " & numberstr)
        j += x
      of 'f':
        inc(i)
        if value[j] notin {'0'..'9'}:
          x = parseUntil(value, numberstr, {'0'..'9'}, j)
          j += x
          if j >= vLength:
            raise newException(ValueError, "no valid number found to parse as millisecond")
        x = parseWhile(value, numberstr, {'0'..'9'}, j)
        if x == 0:
          raise newException(ValueError, "no valid number found to parse as millisecond")
        ms = parseInt(numberstr)
        case len(numberstr)
        of 1:
          ms = ms * 100
        of 2:
          ms = ms * 10
        else:
          discard
        if ms < 0 or ms > 999:
          raise newException(ValueError, "invalid millisecond: " & numberstr)
        j += x
      of 'z', 'Z':
        inc(i)
        if value[j] notin {'+','-','0'..'9'}:
          x = parseUntil(value, numberstr, {'+','-','0'..'9'}, j)
          j += x
          if j >= vLength:
            raise newException(ValueError, "no valid number found to parse as utc offset")
        var sign = 1
        if value[j] in {'+','-'}:
          if value[j] == '-':
            sign = -1
          inc(j)
        x = parseWhile(value, numberstr, {'0'..'9'}, j)
        if x == 0:
          raise newException(ValueError, "no valid number found to parse as utc offset")
        j += x
        hoff = parseInt(numberstr[0..1]) * sign
        if len(numberstr) > 2:
          moff = parseInt(numberstr[2..3])
          if len(numberstr) > 4:
            soff = parseInt(numberstr[4..^1])
        elif value[j] == ':':
          inc(j)
          x = parseWhile(value, numberstr, {'0'..'9'}, j)
          if x == 0:
            raise newException(ValueError, "no valid number found to parse as utc minute offset")
          j += x
          moff = parseInt(numberstr)
          if value[j] == ':':
            inc(j)
            x = parseWhile(value, numberstr, {'0'..'9'}, j)
            if x == 0:
              raise newException(ValueError, "no valid number found to parse as utc second offset")
            j += x
            soff = parseInt(numberstr)
      else:
        discard
    elif fmtstr[i] == '$':
      inc(i)
      if len(fmtstr[i..^1]) >= 3 and fmtstr[i..i+2] == "iso":
        return strptime(value, "%Y-%m-%dT%H:%M:%S")
      elif len(fmtstr[i..^1]) >= 4 and fmtstr[i..i+3] == "wiso":
        return strptime(value, "%G-W%V-%u")
      elif len(fmtstr[i..^1]) >= 4 and fmtstr[i..i+3] == "http":
        return strptime(value, "%a, %d %b %Y %H:%M:%S")
      elif len(fmtstr[i..^1]) >=  5 and fmtstr[i..i+4] == "ctime":
        return strptime(value, "%a %b %d %H:%M:%S %Y")
      elif len(fmtstr[i..^1]) >= 6 and fmtstr[i..i+5] == "rfc850":
        return strptime(value, "%A, %d-%b-%y %H:%M:%S", twoDigitYearFlag=true)
      elif len(fmtstr[i..^1]) >= 7 and fmtstr[i..i+6] == "rfc1123":
        return strptime(value, "%a, %d %b %Y %H:%M:%S")
      elif len(fmtstr[i..^1]) >= 7 and fmtstr[i..i+6] == "rfc3339":
        return strptime(value, "%Y-%m-%dT%H:%M:%S")
      elif len(fmtstr[i..^1]) >= 7 and fmtstr[i..i+6] == "asctime":
        return strptime(value, "%a %b %d %T %Y")
      else:
        discard
    else:
      inc(i)
  if isISOWeekDate:
    result = rata2datetime(iso2rata(y, week, weekday))
  else:
    result = initDateTime(y, m, d, h, mi, s, ms)

proc strftime*(dt: Date, fmtstr: string, locale = "english"): string =
  result = ""
  let fmtLength = len(fmtstr)
  var i = 0
  while i < fmtLength:
    if fmtstr[i] == '%':
      if i + 1 == fmtLength:
        result.add(fmtstr[i])
        break
      inc(i)
      case fmtstr[i]
      of '%':
        result.add("%")
      of 'a':
        result.add(dayabbr(dayofweek(dt), LOCALES[locale]))
      of 'A':
        result.add(dayname(dayofweek(dt), LOCALES[locale]))
      of 'b':
        result.add(monthabbr(month(dt).int, LOCALES[locale]))
      of 'B':
        result.add(monthname(dt.month.int, LOCALES[locale]))
      of 'C':
        result.add($(dt.year div 100))
      of 'd':
        result.add(intToStr(dt.day.int, 2))
      of 'F':
        result.add(intToStr(dt.year.int, 4))
        result.add("-")
        result.add(intToStr(dt.month.int, 2))
        result.add("-")
        result.add(intToStr(dt.day.int, 2))
      of 'g':
        let iso = rata2iso(value(dt))
        result.add($(iso.year div 100))
      of 'G':
        let iso = rata2iso(value(dt))
        result.add($iso.year)
      of 'j':
        let daynr = dayofyear(dt).int
        result.add(intToStr(daynr, 3))
      of 'm':
        result.add(intToStr(dt.month.int, 2))
      of 'u':
        result.add($dayofweek(dt))
      of 'U':
        let first_sunday = tofirst(dt, 0, TYear)
        if dt < first_sunday:
          result.add("00")
        else:
          result.add(intToStr(((dt - first_sunday).value div 7 + 1).int, 2))
      of 'V':
        result.add($week(dt))
      of 'w':
        result.add($dayofweek(dt))
      of 'W':
        let first_monday = tofirst(dt, 1, TYear)
        if dt < first_monday:
          result.add("00")
        else:
          result.add(intToStr(((dt - first_monday).value div 7 + 1).int, 2))
      of 'y':
        result.add(intToStr(dt.year.int mod 100, 2))
      of 'Y':
        result.add(intToStr(dt.year.int, 4))
      else:
        discard
    elif fmtstr[i] == '$':
      if len(fmtstr[i..^1]) >= 3 and fmtstr[i..i+2] == "iso":
        result.add(dt.strftime("%Y-%m-%d"))
        inc(i, 2)
      elif len(fmtstr[i..^1]) >= 4 and fmtstr[i..i+3] == "wiso":
        result.add(dt.strftime("%G-W%V-%u"))
        inc(i, 3)
    else:
      result.add(fmtstr[i])
    inc(i)


proc strftime*(dt: Date|DateTime, fmtstr: string, locale = "english"): string =
  ## a limited reimplementation of strftime, mainly based
  ## on the version implemented in lua, with some influences
  ## from the python version and some convenience features,
  ## such as a shortcut to get a DateTime formatted according
  ## to the rules in RFC3339
  ##
  result = ""
  let fmtLength = len(fmtstr)
  var i = 0
  while i < fmtLength:
    if fmtstr[i] == '%':
      if i + 1 == fmtLength:
        result.add(fmtstr[i])
        break
      inc(i)
      case fmtstr[i]
      of '%':
        result.add("%")
      of 'a':
        result.add(dayabbr(dayofweek(dt), LOCALES[locale]))
      of 'A':
        result.add(dayname(dayofweek(dt), LOCALES[locale]))
      of 'b':
        result.add(monthabbr(month(dt).int, LOCALES[locale]))
      of 'B':
        result.add(monthname(dt.month.int, LOCALES[locale]))
      of 'C':
        result.add($(dt.year div 100))
      of 'd':
        result.add(intToStr(dt.day.int, 2))
      of 'f':
        result.add(align($dt.millisecond, 3, '0').strip(chars = {'0'}, leading=false))
      of 'F':
        result.add(intToStr(dt.year.int, 4))
        result.add("-")
        result.add(intToStr(dt.month.int, 2))
        result.add("-")
        result.add(intToStr(dt.day.int, 2))
      of 'g':
        let iso = rata2iso(datetime2rata(dt))
        result.add($(iso.year div 100))
      of 'G':
        let iso = rata2iso(datetime2rata(dt))
        result.add($iso.year)
      of 'H':
        result.add(intToStr(dt.hour.int, 2))
      of 'I':
        var hour: int
        if dt.hour == 0:
          hour = 12
        elif dt.hour > 12:
          hour = dt.hour.int - 12
        result.add(intToStr(hour, 2))
      of 'j':
        let daynr = dayofyear(dt).int
        result.add(intToStr(daynr, 3))
      of 'm':
        result.add(intToStr(dt.month.int, 2))
      of 'M':
        result.add(intToStr(dt.minute.int, 2))
      of 'p':
        if dt.hour < 12:
          result.add("AM")
        else:
          result.add("PM")
      of 'S':
        result.add(intToStr(dt.second.int, 2))
      of 'T':
        result.add(intToStr(dt.hour.int, 2))
        result.add(":")
        result.add(intToStr(dt.minute.int, 2))
        result.add(":")
        result.add(intToStr(dt.second.int, 2))
      of 'u':
        result.add($dayofweek(dt))
      of 'U':
        let first_sunday = tofirst(dt, 0, TYear)
        if dt < first_sunday:
          result.add("00")
        else:
          result.add(intToStr(((toDate(dt) - toDate(first_sunday)).value div 7 + 1).int, 2))
      of 'V':
        result.add($week(dt))
      of 'w':
        result.add($dayofweek(dt))
      of 'W':
        let first_monday = tofirst(dt, 1, TYear)
        if dt < first_monday:
          result.add("00")
        else:
          result.add(intToStr(((toDate(dt) - toDate(first_monday)).value div 7 + 1).int, 2))
      of 'y':
        result.add(intToStr(dt.year.int mod 100, 2))
      of 'Y':
        result.add(intToStr(dt.year.int, 4))
      of 'z':
        result.add("+00:00")
      else:
        discard

    elif fmtstr[i] == '$':
      inc(i)
      if len(fmtstr[i..^1]) >= 3 and fmtstr[i..i+2] == "iso":
        result.add(dt.strftime("%Y-%m-%dT%H:%M:%S"))
        inc(i, 2)
      elif len(fmtstr[i..^1]) >= 4 and fmtstr[i..i+3] == "wiso":
        result.add(dt.strftime("%G-W%V-%u"))
        inc(i, 3)
      elif len(fmtstr[i..^1]) >= 4 and fmtstr[i..i+3] == "http":
        result.add(dt.strftime("%a, %d %b %Y %T GMT"))
        inc(i, 3)
      elif len(fmtstr[i..^1]) >=  5 and fmtstr[i..i+4] == "ctime":
        result.add(dt.strftime("%a %b %d %T GMT %Y"))
        inc(i, 4)
      elif len(fmtstr[i..^1]) >= 6 and fmtstr[i..i+5] == "rfc850":
        result.add(dt.strftime("%A, %d-%b-%y %T GMT"))
        inc(i, 5)
      elif len(fmtstr[i..^1]) >= 7 and fmtstr[i..i+6] == "rfc1123":
        result.add(dt.strftime("%a, %d %b %Y %T GMT"))
        inc(i, 6)
      elif len(fmtstr[i..^1]) >= 7 and fmtstr[i..i+6] == "rfc3339":
        result.add(dt.strftime("%Y-%m-%dT%H:%M:%S"))
        if dt.millisecond > 0:
          result.add(".")
          result.add(align($dt.millisecond, 3, '0'))
        result.add("+00:00")
        inc(i, 6)
      elif len(fmtstr[i..^1]) >= 7 and fmtstr[i..i+6] == "asctime":
        result.add(dt.strftime("%a %b %d %T %Y"))
        inc(i, 6)
    else:
      result.add(fmtstr[i])
    inc(i)

proc initDate*(dstr: string): Date =
  result = toDate(strptime(dstr,"%y %m %d"))

proc initISOWeekDate*(isowd: string): Date =
  result = toDate(strptime(isowd, "$wiso"))

proc initDateTime*(dtstr: string): DateTime =
  try:
    result = strptime(dtstr, "%y %m %d %H %M %S %f")
  except:
    try:
      result = strptime(dtstr, "%y %m %d %H %M %S")
    except:
      try:
        result = strptime(dtstr, "%y %m %d")
      except:
        raise newException(ValueError, "unhandled datetime format")

#template strftime*(d: Date, fmtstr: string): string =
#  strftime(toDateTime(d), fmtstr)

proc initTime*(tstr: string): Time =
  try:
    result = toTime(strptime(tstr, "%H %M %S %f"))
  except:
    raise newException(ValueError, "unhandled time format")

iterator countUp*[P: DatePeriod](dtstart, dtend: Date, step: P): Date =
  var i = 1
  var curr = dtstart
  while curr <= dtend:
    yield curr
    curr = dtstart + (i * step)
    inc(i)

iterator countUp*[P: Period](dtstart, dtend: DateTime, step: P): DateTime =
  var i = 1
  var curr = dtstart
  while curr <= dtend:
    yield curr
    curr = dtstart + (i * step)
    inc(i)

iterator countUp*[P: TimePeriod](tstart, tend: Time, step: P): Time =
  var i = 1
  var curr = tstart
  while curr <= tend:
    yield curr
    curr = tstart + (i * step)
    inc(i)

iterator countDown*[P: DatePeriod](dtstart, dtend: Date, step: P): Date =
  var i = 1
  var curr = dtstart
  while curr >= dtend:
    yield curr
    curr = dtstart - (i * step)
    inc(i)

iterator countDown*[P: Period](dtstart, dtend: DateTime, step: P): DateTime =
  var i = 1
  var curr = dtstart
  while curr >= dtend:
    yield curr
    curr = dtstart - (i * step)
    inc(i)

iterator countDown*[P: TimePeriod](tstart, tend: Time, step: P): Time =
  var i = 1
  var curr = tstart
  while curr <= tend:
    yield curr
    curr = tstart - (i * step)
    inc(i)

iterator recur*[P: Dateperiod](dtstart, dtend: Date, step: P, df: proc(dt: Date): bool):Date =
  if step.value < 0:
    for d in countDown(dtstart, dtend, -step):
      if df(d):
        yield d
  elif step.value > 0:
    for d in countUp(dtstart, dtend, step):
      if df(d):
        yield d
  else:
    if df(dtstart):
      yield dtstart


proc recur*[P: Dateperiod](dtstart, dtend: Date, step: P, df: proc(dt: Date): bool):seq[Date] =
  result = @[]
  for d in recur(dtstart, dtend, step, df):
    result.add(d)

iterator recur*[P: Period](dtstart, dtend: DateTime, step: P, df: proc(dt: DateTime): bool):DateTime =
  if step.value < 0:
    for d in countDown(dtstart, dtend, -step):
      if df(d):
        yield d
  elif step.value > 0:
    for d in countUp(dtstart, dtend, step):
      if df(d):
        yield d
  else:
    if df(dtstart):
      yield dtstart

proc recur*[P: Period](dtstart, dtend: DateTime, step: P, df: proc(dt: DateTime): bool):seq[DateTime] =
  result = @[]
  for d in recur(dtstart, dtend, step, df):
    result.add(d)

iterator recur*[P: TimePeriod](tstart, tend: Time, step: P, df: proc(dt: Time): bool):Time =
  if step.value < 0:
    for d in countDown(tstart, tend, -step):
      if df(d):
        yield d
  elif step.value > 0:
    for d in countUp(tstart, tend, step):
      if df(d):
        yield d
  else:
    if df(tstart):
      yield tstart

proc recur*[P: TimePeriod](dtstart, dtend: Time, step: P, df: proc(dt: Time): bool):seq[Time] =
  result = @[]
  for d in recur(dtstart, dtend, step, df):
    result.add(d)


proc easter*(year: SomeNumber): Date =
  ##| Return Date of Easter in Gregorian year `year`.
  ##| adapted from CommonLisp calendrica-3.0
  ##
  let century = fld(year, 100) + 1
  let shifted_epact = modulo(14 + (11 * modulo(year, 19)) -
                             fld(3 * century, 4) +
                             fld(5 + (8 * century), 25), 30)
  var adjusted_epact = shifted_epact
  if (shifted_epact == 0) or (shifted_epact == 1 and
                                (10 < modulo(year, 19))):
      adjusted_epact = shifted_epact + 1
  else:
      adjusted_epact = shifted_epact
  let paschal_moon = (initDate(year, 4, 19)) - Day(adjusted_epact)
  result = weekdayafter(7, paschal_moon)

proc orthodox_easter*(year: SomeNumber): Date =
  ## Return fixed date of Orthodox Easter in Gregorian year `year`.
  ## see lines 1371-1385 in calendrica-3.0.cl
  let shifted_epact = modulo(14 + 11 * modulo(year, 19), 30)
  let j_year        = if year > 0: year else: year - 1
  let paschal_moon  = julian2rata(initDate(j_year, 4, 19)) - shifted_epact
  result = toDate(weekdayafter(7, rata2datetime(paschal_moon)))
