# FizzBuzz Basic — prompt hill climb

Starting from a poor-performing prompt, iteratively improving it by watching
what the model gets wrong and tightening the instruction.

**Model:** ollama/llama3.2  
**Samples:** 1, 3, 5, 15, and an invalid input ("hello")  
**Grid columns:** 0 = invalid input ("hello".to_i → 0), then 1, 3, 5, 15

---

## Baseline: FizzBuzz Basic (0%)

```
Is {{number}} a FizzBuzz number? Answer FizzBuzz, Fizz, Buzz, or the number.
```

Run on 16 samples (1–15 plus invalid). The question framing ("Is X a FizzBuzz
number?") biases the model toward always answering "FizzBuzz". Most responses
are empty strings or wrong — 0 out of 16 pass.

![FizzBuzz Basic baseline grid](hill_base_grid.png)

**What went wrong:** The model treats "Is N a FizzBuzz number?" as a yes/no
question and answers accordingly, or returns verbose explanations that fail the
regex. There are no rules — the model has to recall FizzBuzz from training data
and apply them under a confusing framing.

---

## v2: Inline rules, message-only (20%)

```
FizzBuzz for {{number}}: answer FizzBuzz if divisible by 3 and 5,
Fizz if by 3 only, Buzz if by 5 only, or the number itself. One word.
```

Rules are now embedded directly in the message. No system prompt.
1 out of 5 pass — only 15 (FizzBuzz) succeeds. The model still responds
"FizzBuzz" for most inputs.

![FizzBuzz Basic v2 grid](hill_v2_grid.png)

**What went wrong:** Packing rules into the user message isn't enough.
Without a system prompt establishing the model's role, it doesn't reliably
follow the one-word constraint or apply the divisibility logic.

---

## v3: System instructions with explicit rules (60%)

```
instructions: "Play FizzBuzz. For multiples of 3 say Fizz, multiples of 5
say Buzz, multiples of both say FizzBuzz, otherwise say the number.
One word only."

message: "{{number}}"
```

Key change: the rules move to a system instruction and the message becomes
just the number. 3 out of 5 pass — 3 (Fizz), 5 (Buzz), and 15 (FizzBuzz)
are correct. 1 returned "One" (a written-out number), and the invalid input
"hello" returned "Fizz".

![FizzBuzz Basic v3 grid](hill_v3_grid.png)

**What changed:** Moving rules to the system prompt is the biggest single
improvement in the series. The model now reliably handles Fizz/Buzz/FizzBuzz
but still stumbles on plain numbers and non-numeric inputs.

---

## v4: Oracle-style system prompt (80%)

```
instructions: "You are a FizzBuzz oracle. Given a number respond with
exactly one word: 'FizzBuzz' if divisible by both 3 and 5, 'Fizz' if
divisible by 3 only, 'Buzz' if divisible by 5 only, or the number as
digits if neither. No explanation or extra text."

message: "{{number}}"
```

Adds explicit digit-form requirement ("the number as digits") and oracle
persona. 4 out of 5 pass — 1, 3, 5, and 15 all correct. Only the invalid
input "hello" fails, returning "Error".

![FizzBuzz Basic v4 grid](hill_v4_grid.png)

**What changed:** The "as digits" clause fixed the "One" / written-number
failure from v3. The invalid input is still an open problem — the model errors
rather than echoing the input back.

---

## Summary

| Version | Prompt change | Pass rate |
|---------|--------------|-----------|
| Base | Question framing, no rules | 0% (0/16) |
| v2 | Inline rules in message | 20% (1/5) |
| v3 | Rules → system instructions | 60% (3/5) |
| v4 | Oracle persona + "as digits" | 80% (4/5) |

**Key takeaways:**

1. **Framing matters as much as content.** The base prompt asked a question
   instead of giving a command — the model answered the question rather than
   playing FizzBuzz.

2. **System instructions beat message-embedded rules.** Moving the rules from
   the user message to a system prompt (v2 → v3) was the single largest jump.

3. **Small additions close specific failure modes.** "As digits" (v3 → v4)
   fixed exactly the written-number case.

4. **Invalid inputs need explicit handling.** None of the prompts reliably
   echo back a non-numeric input. Addressing that would be the next step.

These prompts and their VCR-recorded sample runs are all seeded into the
database — explore them at `/evals/prompts` in the ruby_llm-evals UI.
