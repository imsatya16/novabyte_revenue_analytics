# Problem Statement

## Background

NovaByte Solutions is a mid-sized IT services company headquartered in Bangalore, with regional offices in Delhi, Mumbai, Kolkata, and Chennai. Founded in 2015, it provides enterprise software licenses, cloud migration services, managed infrastructure, and analytics solutions to a client base of 300+ organizations across Banking, Healthcare, Retail, Telecom, Manufacturing, and other verticals.

The company runs on a lean, cross-functional structure — a Sales team driving pipeline and revenue, a Marketing team running digital and event-based campaigns, a Support/Operations team handling service delivery, and a Finance team managing budgets and cost control.

## The Problem

Through Q2-2024, NovaByte was on a steady growth trajectory. Starting Q3-2024, that changed:

- **Revenue growth flattened**, even though Sales continued reporting a healthy, steady pipeline
- **Marketing spend rose roughly 20% year-over-year**, but lead-to-close conversion didn't improve to match
- **Client satisfaction scores declined**, alongside a rise in Support ticket escalations and SLA breaches
- **Finance flagged budget overruns** in multiple departments, with unclear ROI on several vendor contracts

None of these symptoms, on their own, fully explains the slowdown. Pipeline volume looked fine. Marketing was spending more, not less. Nothing was obviously broken in any single department's own numbers.

## What Needed to Be Answered

The real question wasn't "which department is underperforming" — early indicators suggested none of them obviously were, in isolation. The actual question was:

> **Are these four symptoms connected? And if inefficiencies in one function are quietly cascading into another, where exactly is that happening — and what should be done about it?**

That required treating this as one cross-functional investigation rather than four separate department reviews: cleaning and reconciling five different datasets (Clients, Sales, Marketing, Support, Finance), testing whether the patterns that looked meaningful were actually statistically real, and building a single view that could show leadership the full picture at once rather than four disconnected ones.

## Why This Was Worth Doing Properly

A rushed diagnosis here would have been easy to get wrong in either direction — either forcing a tidy "one root cause" story the data doesn't actually support, or missing a real cross-functional link because each team's own dashboard looked fine on its own. The approach taken in this project was to test every assumption directly against the data — including the ones that turned out **not** to hold up (see the [statistical testing results](./04_Statistics/) for the honestly-reported null findings) — rather than assume a hypothesis was correct just because it sounded plausible.

The full diagnosis, methodology, and resulting recommendations are documented in [`README.md`](./README.md).
