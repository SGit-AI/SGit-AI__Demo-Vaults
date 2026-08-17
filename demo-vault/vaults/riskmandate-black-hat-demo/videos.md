# Walkthrough videos — RiskMandate

Recorded walkthroughs of this vault's app, all MVP, 5 August. Summaries are written from
the project lead's narration, so they describe what each video actually demonstrates
rather than what the feature was intended to do.

Read in this order, they are one pipeline: **the graph browser captures the facts**, **the
risk chains connect the resulting risks upward**, and **the role risk map lands each risk
on an accountable person**.

| # | Video | What it adds |
|---|---|---|
| 1 | [Graph Browser](https://youtu.be/PP6zsrC0KEg) | Questions → facts → an evidence graph |
| 2 | [Risk Chains](https://youtu.be/kWip3QnuN1I) | Facts → risks that connect upward to the corporate register |
| 3 | [Role risk map](https://youtu.be/yqQgff4RWuE) | Risks → named owners, via the org chart |

---

## 1 · Graph Browser (MVP, 5 Aug)

**https://youtu.be/PP6zsrC0KEg**

The question set from the demo, rendered as a graph. It starts from one question — *do you
have an agent, and where does it run?* — and if the answer is no, there is exactly one
piece of information to hold. Everything after that is enrichment.

**The graph is the evidence layer.** Each answer is a fact, and the graph is the record of
facts and the decisions they inform. Edges are typed by relationship rather than uniform,
so the graph carries *how* things relate, not merely that they do.

The dimensions the walkthrough moves through:

| Dimension | Values shown |
|---|---|
| Where it runs | operational vs test environment — the risk is similar either way; the question is whether it is live |
| Data reached | personal data, accounts, contact details |
| What it may do with data | cannot see it · reads it · reads **and changes** |
| Change authority | read and report · change with a person's approval · changes on its own |
| Stop control | an action to stop · eventually can stop · don't know how; and how long — minutes, an hour, don't know |
| Stop *tested* | yes · only in test · never |
| Effects of stopping | mapped · partial · unknown — **depends on** stop control, one level down the flow |
| Stop authority | is there a named person |
| Blast radius | internal only · customer-facing · don't know |
| Outbound access | internet access vs no egress |
| Reversibility | fully reversible · some changes are forever |
| Written pull-the-plug procedure | tested · written · absent |
| Reconstruct what it did | fully · partially · not — with the caveat that backups often cannot restore *specific* things |
| Account ownership | service account · named person · team |

A worked instance from the video: a production system touching personal data, accounts and
contact details, informing decisions, reading **and changing** — "a typical agent".

**Why it matters:** the whole context is capturable in about a day, and what comes out the
other side is a roadmap of risks, the risk chains, and a register where each risk shows who
it is assigned to, what causes it, and what it leads to.

---

## 2 · Risk Chains (MVP, 5 Aug)

**https://youtu.be/kWip3QnuN1I**

The same estate seen as **connections between risks**, across the scenario set — typical,
non-exposed, governed, exposed.

**The chain, worked.** RISK-6, *"production can be changed by an agent"*, connects onward:
the organisation acts through a system that acts for a person, which creates a further risk
— *"organisation asks for tech to be changed"* — which arrives at the top, in the corporate
risk register.

**It navigates both ways, and that is the point.**

| Direction | Question it answers |
|---|---|
| **leads to** | Where does this end up? Navigate upward toward the corporate register |
| **led by** | Why does this exist? Navigate down to the facts underneath it |

Clicking a corporate risk shows its justification directly: *corporate-2* is assigned to the
CEO, reduced by particular choices, touches GDPR, and leads onward. Every risk should reach
the top; a chain that doesn't is visible as such.

As answers accumulate the register grows from nothing — no agent, no risk; *yes, there is an
agent*, and risks appear and begin to interconnect.

**The most valuable part of this video is the project lead disagreeing with the tool.** In
the governed scenario it asserts a *loss of control* risk, and he rejects it: given the
controls already recorded, he does not accept that risk as stated.

Two things follow, and both are the argument for the product rather than against it:

1. **This is what will happen when a risk is put forward for approval** — the stakeholder
   will challenge it hard. The difference here is that the evidence for the claim is
   attached to it, so the challenge is about the facts rather than about opinion.
2. **His counter-analysis is more precise than the generated risk.** The real exposure is
   that the agent touches the **EU AI Act**, putting the organisation in scope with an agent
   in the mix. And although the estate can stop the agent within a minute, *stopping it is
   itself disruptive to production* — an interruption that the register should capture in
   its own right.

The closing claim: this is now **fact-driven**, so a disagreement resolves against evidence
instead of authority.

---

## 3 · Role risk map — the risk org chart (MVP, 5 Aug)

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
