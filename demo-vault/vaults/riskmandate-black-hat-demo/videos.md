# Walkthrough videos — RiskMandate

Recorded walkthroughs of this vault's app. Summaries are written from the project lead's
narration, so they describe what the video actually demonstrates rather than what the
feature was intended to do.

---

## Role risk map — the risk org chart (MVP, 5 Aug)

**https://youtu.be/yqQgff4RWuE**

The graph explorer rendered as an **org chart**: board, CEO, three direct reports, and the
team beneath — platform owner, SRE, CPO with a customer service owner, DPO, CFO, CTO. The
reporting lines are the point: the chain from a customer service owner up through the CPO
to the CEO and the board is visible as a path, not asserted in prose.

**What it demonstrates.** As questions are answered and risks are added, risks *flow
upward* through that structure. The chart is not a static picture of who reports to whom —
it is the route risk travels to reach an accountable owner.

**The distinction the video singles out as important: two ways a risk arrives at a person.**

| Arrival | Meaning |
|---|---|
| **Directly assigned** | The role owns it outright — e.g. the CEO's three corporate register entries, assigned to them |
| **Via the risk chain** | It arrives *because the graph says so* — a senior holds it by consequence of who reports to them, not by anyone assigning it |

Worked example from the video: the SRE holds RISK-2, 6, 9, 21 and 31. Those same risks
then connect to the platform owner, who also carries some of their own; the CTO in turn
inherits everything below plus their own. The DPO and CFO show the same pattern, and the
CEO is where the lines converge.

**Scenario comparison.** Switching scenarios changes the shape of the map: no agent
deployed produces almost nothing; a typical agent deployment produces one shape; a
high-exposure estate produces a substantially larger set of responsibilities; a governed
estate produces a visibly cleaner flow.

**Why it matters, in the project lead's framing.** Two consequences:

1. **No risk is orphaned.** Every risk flows upward until it reaches someone accountable.
   A risk with nowhere to go is visible as such.
2. **It creates a challenge mechanism.** Once a risk lands on a named person, that person
   can push back on whether it belongs there — which is the useful argument to be having,
   and one a flat register never provokes.
