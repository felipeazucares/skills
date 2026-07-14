# Skill Benchmark: log-issue

**Model**: claude-sonnet-5
**Date**: 2026-07-14T10:35:14Z
**Evals**: 0, 1, 2 (1 runs each per configuration)

## Summary

| Metric | With Skill | Without Skill | Delta |
|--------|------------|---------------|-------|
| Pass Rate | 100% ± 0% | 50% ± 17% | +0.50 |
| Time | 236.5s ± 7.2s | 203.9s ± 126.8s | +32.6s |
| Tokens | 59822 ± 2754 | 58528 ± 17908 | +1293 |

## Notes

- Eval 1 (clear-bug-duplicate-node) without_skill's 33% pass rate is largely a test-design artifact, not a fair skill-vs-no-skill signal: both configurations filed against the same real repo, and without_skill ran slightly later, walked into with_skill's just-created issue #106, and correctly avoided duplicating it by commenting instead. Most of the ticket-quality assertions don't apply to a comment. Future iterations should stagger or isolate with_skill/without_skill runs against the same real repo to avoid this collision, or accept it and read this eval's baseline number with that caveat.
- That same without_skill run, unprompted, stood up the live Docker stack and attempted a real repro of the reported bug (46 tool calls, ~5.8 min, ~79k tokens -- the most expensive run of the six) and found it does NOT currently reproduce on main. None of the current assertions credit or even notice this -- it's arguably the single most substantively important finding across all 6 runs, and a 'did the agent attempt verification' dimension is missing from this eval set.
- The 'no source files modified' assertion passed 6/6 across both configurations on every eval -- it never discriminated in this run. That's not a reason to drop it (guarding against scope creep into implementation is the skill's core promise), but it means the current prompts never actually tempted an agent to start fixing code. A future eval should phrase the request in a way that invites 'just fix it while you're at it' (e.g. 'this is annoying me, can you sort it') to see if the skill's scope boundary holds under real pressure.
- Area-labeling was inconsistent across the two with_skill runs on the same axis: eval 1 (bug, no area field in bug_report.yml) created and applied a new 'api' GitHub label; eval 2 (feature, enhancement.yml already has a 'Related feature / area' text field) filled that text field with 'API' but did not also create/apply an 'api' label. Both are defensible reads of the skill's Step 3 vs. Step 6 instructions, but the inconsistency itself is worth resolving explicitly rather than leaving it to per-run judgment.
- with_skill's own self-reported summary for eval 2 incorrectly claimed it had skipped area classification entirely -- it actually filled the template's native area field correctly. Grading against the live GitHub issue content (not the transcript's self-report) caught this; a grader relying solely on the executor's own summary would have under-scored a passing run.
- with_skill pass rate was a clean 100% across all 3 evals with zero variance, while without_skill ranged from 33% (confounded, see above) to 67% -- even setting aside the confounded eval, without_skill was inconsistent (50%, 67%) where with_skill was uniformly complete. The skill's main value in this run looks less like 'baseline fails outright' and more like 'baseline does good instinctive work but is missing structural discipline (acceptance criteria, explicit assumptions, area classification) that the skill enforces every time.'
- with_skill costs modest overhead: +32.6s and +1293 tokens on average versus without_skill. Given the consistency gain, that looks like a reasonable trade, though the token delta is noisy (without_skill's stddev is 17908 due to the eval-1 live-repro outlier) and would benefit from more runs per configuration before treating the exact magnitude as reliable.