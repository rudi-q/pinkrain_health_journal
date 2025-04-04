06:07 +0: Test TFLite symptom predictions on Android platform
Model size: 12806940 bytes
Interpreter initialized successfully.
Input shape: [1, 20]
Output shape: [1, 326]
Tokenizer loaded with 767 words.
MLB classes loaded with 326 classes.

=== Testing Symptom Predictions for Natural Language Inputs ===


Input: "Having frequent urination issues"
Predictions:
  - hypnic jerks: 66.0%
  - mental confusion: 2.6%
  - paroxysmal dyspnea: 2.2%
  - anosmia: 1.5%
  - fatigue: 1.4%
  - planning deficit: 1.4%
---

Input: "My legs are swollen and painful"
Predictions:
  - GI unease: 13.6%
  - bruxism: 8.6%
  - rhinorrhea: 8.2%
  - abdominal pain: 7.9%
  - cold extremities: 7.2%
  - dysarthria: 5.5%
---

Input: "Experiencing severe menstrual cramps"
Predictions:
  - hypnic jerks: 52.2%
  - mental confusion: 1.6%
  - paroxysmal dyspnea: 1.6%
  - planning deficit: 1.6%
  - anosmia: 1.4%
  - lethargy: 1.3%
---

Input: "Having chills and fever symptoms"
Predictions:
  - hypnic jerks: 19.8%
  - paroxysmal dyspnea: 2.3%
  - anosmia: 1.6%
  - planning deficit: 1.3%
  - lethargy: 1.2%
  - mental confusion: 1.1%
---

Input: "My neck is stiff and painful"
Predictions:
  - cervicalgia: 82.2%
  - insomnia: 11.3%
  - morning stiffness: 4.1%
  - restlessness: 3.6%
  - emotional detachment: 1.6%
  - sleep disturbance: 1.2%
---

Input: "Feeling very restless and agitated"
Predictions:
  - insomnia: 1.4%
  - fatigue: 0.6%
  - restlessness: 0.5%
  - restless legs: 0.2%
  - sleep disturbance: 0.2%
  - hematuria: 0.2%
---

Input: "Having breathing difficulties and wheezing"
Predictions:
  - constipation: 4.7%
  - anosmia: 3.7%
  - planning deficit: 3.6%
  - low motivation: 1.0%
  - olfactory hallucinations: 1.0%
  - urinary incontinence: 0.7%
---

Input: "My jaw hurts when chewing"
Predictions:
  - head pressure: 26.4%
  - chest heaviness: 16.3%
  - polyarthralgia: 9.3%
  - back stiffness: 6.1%
  - nasal congestion: 5.3%
  - abdominal pain: 3.9%
---
06:08 +1: All tests passed!