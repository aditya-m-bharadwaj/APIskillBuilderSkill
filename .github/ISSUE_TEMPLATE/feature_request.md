---
name: Feature request
about: Suggest a new step, recipe, or anti-pattern entry for the skill
title: "feat: <short summary>"
labels: ["enhancement"]
assignees: []
---

## Problem

What's the gap in the current build process? Describe the *scenario* you ran into — e.g. "I tried to use the skill to wrap an API that uses HMAC-signed requests and couldn't, because…"

## Proposed addition

What would you add to the skill to close the gap? If it's:

- a new step → describe what the step does and where in the 14-step sequence it fits
- a new recipe → which `<vendor>-api-skill` workflow does it support
- a new anti-pattern → what's the mistake, why is it dangerous, what's the right pattern

## Safety considerations

Does the proposed change touch the safety contract (the ten "Hard rules" in `SKILL.md`)? If yes, what's the new invariant and how is it enforced?

## Alternatives considered

What did you try / rule out?

## Additional context

Links, prior art, related ADRs.
