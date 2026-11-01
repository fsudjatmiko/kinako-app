# Kinako Feature Specifications & Calculation Engines

## 1. Feature Index
Kinako differentiates itself from rear-view accounting ledgers through four forward-looking mechanisms:
1. **Dynamic Safe-to-Spend (Buffer Pacing Engine)**
2. **Asymmetric Ghost Splitting (Group Reimbursement Asset Ledger)**
3. **Time-Cost Equivalency Calculator**
4. **Post-Purchase Regret Audit & Impulse ROI Engine**

---

## 2. Dynamic Safe-to-Spend (Buffer Pacing Engine)

### Core Objective
Eliminate tracking guilt by replacing rigid monthly spending limits with an adaptive daily burn rate that self-corrects based on real-time activity.

### Calculation Logic
- Let $M$ be the user's monthly discretionary budget cap.
- Let $E_{spent}$ be the sum of all personal expenses logged in the current billing cycle.
- Let $D_{total}$ be the total number of days in the current billing month.
- Let $D_{passed}$ be the elapsed days (including today).
- Let $D_{remaining} = \max(1, D_{total} - D_{passed} + 1)$.

$$\text{Remaining Budget } (B_{rem}) = M - E_{spent}$$
$$\text{Safe Daily Allowance } (S_{daily}) = \frac{B_{rem}}{D_{remaining}}$$

### State Machine & Visual Thresholds
The pacing engine drives the ambient glow and status pill on the Home Screen:

| Budget State | Condition | Ambient Accent Color | Status Pill Copy |
| :--- | :--- | :--- | :--- |
| **Stable** | Today's Spend $\le S_{daily}$ AND $B_{rem} > 0.20 \times M$ | `KinakoColor.accentLavender` (`#B784F8`) | `STABLE` |
| **High Tension** | Today's Spend $> S_{daily}$ OR $B_{rem} \le 0.20 \times M$ | `KinakoColor.statusWarning` (`#F59E0B`) | `PRESSURE RISING` |
| **Inversion (Deficit)** | $B_{rem} < 0$ (Over Budget) | `KinakoColor.statusInverse` (`#E11D48`) | `INVERSION // DEFICIT` |

```swift
public struct PacingEngine {
    public static func calculateSafeDaily(
        monthlyCap: Decimal,
        totalSpentThisMonth: Decimal,
        daysRemainingInMonth: Int
    ) -> (safeDaily: Decimal, remainingBudget: Decimal) {
        let remaining = monthlyCap - totalSpentThisMonth
        let days = max(1, Decimal(daysRemainingInMonth))
        let safeDaily = max(0, remaining / days)
        return (safeDaily, remaining)
    }
}


3. Asymmetric Ghost Splitting (Group Outing Ledger)

The Problem

When a user pays for a group bill (e.g., $120 total dining bill where their personal share is $30, and 3 friends owe $30 each), conventional trackers count the full $120 against the user's dining category. When friends reimburse via bank transfer days later, it is registered as artificial income.

The Kinako Solution

1. Transaction Entry:
  ⚬ User inputs the full amount charged to card: originalAmount = 120.
  ⚬ User toggles "Split Outing".
  ⚬ User enters personal share: myShareAmount = 30.
  ⚬ Engine automatically assigns pendingReimbursement = 90 and sets isSplitExpense = true.
2. Ledger Impact:
  ⚬ Only myShareAmount ($30) is deducted from the user's category budget and Safe-to-Spend pacing engine.
  ⚬ The remaining $90 is logged as an Asset Receivable (pendingReimbursement).
3. Reimbursement Resolution:
  ⚬ Inside the Receivables Tray, tapping "Settled" flags isReimbursed = true.
  ⚬ Settling a ghost split does not register as income, preserving financial reporting accuracy.

4. Time-Cost Equivalency Calculator

Core Objective

Convert abstract monetary amounts into concrete working hours to curb impulse spending.

Calculation Logic

⚬ Let W_{hourly} be the user's effective net hourly wage configured in UserSettings.
⚬ When an expense A is viewed or entered:

$$\text{Equivalent Hours} = \frac{A}{W_{hourly}}$$

Formatting Rules

⚬ If duration < 1.0 \text{ hour}: format as minutes (e.g., ≈ 45m of work).
⚬ If duration \ge 1.0 \text{ hour} and < 8.0 \text{ hours}: format as hours and minutes (e.g., ≈ 3h 20m of work).
⚬ If duration \ge 8.0 \text{ hours}: format as working days (assuming 8h standard workday, e.g., ≈ 2.5 work days).

public struct TimeCostCalculator {
    public static func formatEquivalentTime(amount: Decimal, hourlyWage: Decimal?) -> String? {
        guard let wage = hourlyWage, wage > 0, amount > 0 else { return nil }

        let totalHours = (amount as NSDecimalNumber).doubleValue / (wage as NSDecimalNumber).doubleValue

        if totalHours < 1.0 {
            let minutes = Int(round(totalHours * 60))
            return "≈ \(minutes)m of work"
        } else if totalHours < 8.0 {
            let hours = Int(totalHours)
            let minutes = Int(round((totalHours - Double(hours)) * 60))
            return minutes > 0 ? "≈ \(hours)h \(minutes)m of work" : "≈ \(hours)h of work"
        } else {
            let days = totalHours / 8.0
            return String(format: "≈ %.1f work days", days)
        }
    }
}


5. Post-Purchase Regret Audit & Impulse ROI

Core Objective

Track psychological satisfaction alongside monetary transactions to highlight low-value spending habits.

Workflow & Scheduling

1. Eligible Categories: Non-essential discretionary spending (e.g., Dining, Entertainment, Gadgets, Hobbies).
2. Notification Scheduling:
  ⚬ Upon transaction creation, an audit task is scheduled for timestamp + 14 days or timestamp + 30 days.
  ⚬ Uses native UserNotifications framework with an actionable notification category.
3. User Audit Rating Scale (1 to 5):
  ⚬ 5 — Essential / High Joy (100% worth it)
  ⚬ 4 — Good Value
  ⚬ 3 — Neutral (Meh)
  ⚬ 2 — Low Value (Could have skipped)
  ⚬ 1 — Total Regret (Impulse waste)
4. Impulse ROI Analytics:
  ⚬ Displays percentage of audited spending that scored \le 2 (Regret).
  ⚬ Generates category breakdown: e.g., "68% of late-night food deliveries were rated Regret, while 92% of coffee with friends was rated High Joy."
