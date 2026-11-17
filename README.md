# CareLoop Clinics: No-Show Guard

**GitHub repository:** <paste your public repository link here>

Business question: which appointments are most likely to be missed, why do patients miss them, and what should CareLoop do first?

## Summary (one finding per Part)

1. **Part 1 (Python):** 1,020 raw bookings became 990 clean ones (20 duplicate rows and 10 rows with a missing date or status were removed); 26 `distance_km` and 3 `fee_inr` values were capped as outliers.
2. **Part 2 (SQL):** The overall no-show rate is 22.0% (218 of 990). Gomti Nagar Care Point has the highest clinic rate, 33.3% (30 of 90), and the rate rises from 16.2% for bookings made 1-7 days ahead to 60.5% for bookings made 31 or more days ahead.
3. **Part 3 (ML):** A logistic regression (test ROC-AUC 0.789) at a threshold of 0.35 flags 49 of 198 test bookings and catches 28 of the 49 no-shows (precision 0.571, recall 0.571).
4. **Part 4 (GenAI):** Of the 10 call notes, 9 were classified and validated and 1 blank note was skipped; 2 notes gave `forgot_or_no_reminder`, and both were for bookings with `reminder_sent` = No.

## Recommendation

CareLoop should act first on the bookings the model flags and on long lead times. About 1 booking in 5 is a no-show (22.0%), and the rate climbs from 16.2% for bookings made 1-7 days ahead to 30.0% for 15-30 days and 60.5% for 31 or more days, so a confirmation call or a second reminder for bookings made more than two weeks ahead is the cheapest first step. The front desk should also phone the bookings flagged by the model the evening before: at the 0.35 threshold it flags 49 of 198 test bookings and catches 28 of the 49 no-shows, which is a much better use of calls than phoning at random. In the model, holding the other features constant, a booking with a reminder sent has about 0.31 times the odds of a no-show compared with one without, and the two notes that mention a missing reminder both belong to bookings with no reminder sent (see the table below), so making sure every booking gets a reminder is worth doing alongside the calls. Gomti Nagar Care Point (33.3% on only 90 bookings) and Hadapsar Care Centre (27.3% on 143 bookings) are the clinics to pilot this in first.

Cross-tabulation of AI-extracted `root_cause` against `reminder_sent` (10 notes, all for no-shows):

| root_cause | reminder No | reminder Yes | All |
|---|---|---|---|
| cost_or_fee | 0 | 1 | 1 |
| distance_or_transport | 1 | 1 | 2 |
| forgot_or_no_reminder | 2 | 0 | 2 |
| illness_or_emergency | 0 | 1 | 1 |
| other | 1 | 1 | 2 |
| work_or_schedule | 1 | 1 | 2 |
| **All** | 5 | 5 | 10 |

## Model chosen and why

I chose **logistic regression**. On the training set it had the highest 5-fold cross-validated ROC-AUC: 0.774, against 0.767 for the tuned random forest (`max_depth` 3, 200 trees), 0.747 for the untuned random forest and 0.678 for the depth-3 decision tree. The test set was not used to choose the model or the threshold. Evaluated once on the test set it gives a ROC-AUC of 0.789.

The threshold is **0.35**. On out-of-fold training predictions it gave a higher F1 than 0.5 (0.489 against 0.347) and a recall of 0.467 against 0.249. Recall matters here because a missed warning costs an empty doctor slot, while an extra call costs about a minute. At 0.35 the test set gives precision 0.571, recall 0.571 and 49 of 198 bookings flagged. In practice the threshold should be set by how many follow-up calls the front desk can make in an evening, weighed against the cost of an empty slot.

## Limitations

1. The 10 call notes are an illustration and cannot show the real reasons for no-shows across the whole clinic chain.
2. The cleaning statistics (medians, quartiles and outlier fences in Task 1.3) were calculated on all 990 rows before the train/test split, so the test rows had a small indirect influence on the cleaning.
3. The same patient can appear in several bookings, so the random split can put one patient in both the training and the test set; the split is also random rather than past-to-future, and it is a single split.

The data are also observational, so the reminder result is an association and does not prove that reminders cause fewer no-shows.

## Files

- `rejected_rows.json`: rows that failed type conversion in Task 1.1
- `appointments_clean.csv`: cleaned bookings (990 rows, 16 columns)
- `clinics_enriched.csv`: clinics with a temperature from the Open-Meteo API
- `load_data.sql`: INSERT statements for the database
- `part2_queries.sql`: the SQL queries for Part 2, run in a MySQL database named `subbu_capstone_db` that I created for this project (the brief names it `noshowguard`)
- `test_risk_scores.csv`: risk scores and flags for the 198 test bookings
- `notes_analysed.csv`: the 10 call notes analysed with the Gemini API
- the Colab notebook (`.ipynb`) with the code for Parts 1, 3 and 4
