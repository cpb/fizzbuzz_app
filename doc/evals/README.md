# FizzBuzz eval run grids

Each grid shows how a model performed across the FizzBuzz test cases for one
eval run. Columns are the input numbers tested; rows are the four output
classes. A perfect run looks like this:

![Perfect FizzBuzz (ruby/FizzBuzz, 100%)](grid_perfect.png)

A dark cell on the diagonal means the model predicted the right class for
that number. Red means the expected class was wrong; light blue marks what the
model predicted instead.

---

## FizzBuzz Basic

<details>
<summary>Prompt &amp; samples</summary>

**Message** (no system instructions)
```
Divisible by 3 -> Fizz, by 5 -> Buzz, by both -> FizzBuzz, otherwise the
number. What is the FizzBuzz output for {{number}}? Answer with one word only.
```

| number | expected |
|--------|----------|
| 3 | `/fizz(?!buzz)/i` |
| 5 | `/(?<!fizz)buzz/i` |
| 15 | `/fizz\s*buzz/i` |

</details>

![FizzBuzz Basic (ollama/llama3.2, 100%)](grid_fizzbuzz_basic.png)

---

## FizzBuzz Eval

<details>
<summary>Prompt &amp; samples</summary>

**System instructions**
```
Evaluate FizzBuzz for the given number. Return exactly one word: 'FizzBuzz'
if divisible by both 3 and 5, 'Fizz' if divisible by 3 only, 'Buzz' if
divisible by 5 only, or the number itself otherwise.
```

**Message**
```
{{number}}
```

| number | expected |
|--------|----------|
| 3 | `Fizz` |
| 5 | `Buzz` |
| 15 | `FizzBuzz` |

</details>

![FizzBuzz Eval (ollama/llama3.2, 66.67%)](grid_fizzbuzz_eval.png)

---

## FizzBuzz Clean

<details>
<summary>Prompt &amp; samples</summary>

**System instructions**
```
Return ONLY valid JSON with a single key: {"result": "Fizz"}. Rules:
divisible by 3 -> Fizz, by 5 -> Buzz, by both -> FizzBuzz, otherwise the
number as a string.
```

**Message**
```
{{number}}
```

| number | expected |
|--------|----------|
| 3 | `"result": "Fizz"` |
| 5 | `"result": "Buzz"` |
| 15 | `"result": "FizzBuzz"` |

</details>

![FizzBuzz Clean (ollama/llama3.2, 66.67%)](grid_fizzbuzz_clean.png)

---

## Yoda FizzBuzz

<details>
<summary>Prompt &amp; samples</summary>

**System instructions**
```
Speak like Yoda, you must. Play FizzBuzz you must: for a number divisible
by 3 but not 5, say Fizz; by 5 but not 3, say Buzz; by both 3 and 5, say
FizzBuzz; otherwise say the number. One word only, your answer must be.
```

**Message**
```
{{number}}
```

| number | expected |
|--------|----------|
| 1 | `/(\bone\b\|\b1\b)/i` |
| 3 | `/fizz(?!buzz)/i` |
| 5 | `/(?<!fizz)buzz/i` |
| 15 | `/fizzbuzz/i` |

</details>

![Yoda FizzBuzz (ollama/llama3.2, 75%)](grid_yoda_fizzbuzz.png)
