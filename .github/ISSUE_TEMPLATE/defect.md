---
name: Defect
about: Something behaves differently than documented
title: ''
labels: defect
---

**What happened.**

The concrete failure: what you did, and what came out wrong.

**What the documentation says should happen.**

Quote the instruction, skill, or gate you were relying on, with its file path if
you know it. A defect in a prose framework is usually a gap between what a file
says and what a model does with it.

**How to reproduce.**

The steps, and whether it happens every time or intermittently. Intermittent is
still worth reporting — this project is instructions to a model, so "sometimes"
is a real failure mode and not a reason to stay quiet.

**Scale level and phase**, if the project is initialized.

**Version.**

Plugin version, and `claude --version`.
