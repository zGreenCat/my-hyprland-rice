export const MONTHS = [
  "Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio",
  "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre",
]
export const WEEKDAYS = ["L", "M", "X", "J", "V", "S", "D"]

export interface DayCell {
  day: number
  inMonth: boolean
  weekend: boolean
  today: boolean
}

export interface YearMonth {
  year: number
  month: number // 0 = enero
}

export function shiftMonth({ year, month }: YearMonth, step: number): YearMonth {
  const total = year * 12 + month + step
  return { year: Math.floor(total / 12), month: ((total % 12) + 12) % 12 }
}

function daysIn(year: number, month: number): number {
  return new Date(year, month + 1, 0).getDate()
}

/** Semanas completas (lunes a domingo) que cubren el mes, con los días de relleno de los meses vecinos. */
export function monthGrid({ year, month }: YearMonth, today: Date): DayCell[] {
  const lead = (new Date(year, month, 1).getDay() + 6) % 7
  const days = daysIn(year, month)
  const prev = shiftMonth({ year, month }, -1)
  const prevDays = daysIn(prev.year, prev.month)
  const total = Math.ceil((lead + days) / 7) * 7
  const cells: DayCell[] = []

  for (let i = 0; i < total; i++) {
    const n = i - lead + 1
    const weekend = i % 7 >= 5
    if (n < 1) cells.push({ day: prevDays + n, inMonth: false, weekend, today: false })
    else if (n > days) cells.push({ day: n - days, inMonth: false, weekend, today: false })
    else {
      const isToday = today.getFullYear() === year && today.getMonth() === month && today.getDate() === n
      cells.push({ day: n, inMonth: true, weekend, today: isToday })
    }
  }
  return cells
}

export function monthTitle({ year, month }: YearMonth): string {
  return `${MONTHS[month]} ${year}`
}
