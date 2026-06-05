# FSRS-4.5 scheduler (Free Spaced Repetition Scheduler) — the algorithm Anki adopted.
# Pure functions over a card's DSR state (difficulty, stability, retrievability). See
# docs/decisions/0004 and https://github.com/open-spaced-repetition. Grades: 1=again,
# 2=hard, 3=good, 4=easy.
module Fsrs
  W = [
    0.4072, 1.1829, 3.1262, 15.4722, 7.2102, 0.5316, 1.0651, 0.0234, 1.616, 0.1544,
    1.0824, 1.9813, 0.0953, 0.2975, 2.2042, 0.2407, 2.9466, 0.5034, 0.6567
  ].freeze
  REQUEST_RETENTION = 0.9
  DECAY = -0.5
  FACTOR = 19.0 / 81 # 0.9 ** (1 / DECAY) - 1

  module_function

  # Returns the attributes to persist after grading `card` with `grade` at time `now`.
  def schedule(card, grade, now: Time.current)
    if card.reps.zero?
      difficulty = init_difficulty(grade)
      stability  = init_stability(grade)
    else
      elapsed   = [ (now - (card.last_reviewed_at || now)) / 86_400.0, 0.0 ].max
      r         = retrievability(elapsed, card.stability)
      difficulty = next_difficulty(card.difficulty, grade)
      stability  = grade == 1 ? forget_stability(difficulty, card.stability, r) : recall_stability(difficulty, card.stability, r, grade)
    end

    days = interval(stability)
    {
      stability: stability, difficulty: difficulty, interval_days: days,
      due_at: now + days * 86_400, last_reviewed_at: now,
      reps: card.reps + 1, lapses: card.lapses + (grade == 1 ? 1 : 0),
      state: grade == 1 ? :relearning : :review
    }
  end

  def retrievability(elapsed_days, stability)
    (1 + FACTOR * elapsed_days / stability)**DECAY
  end

  def interval(stability)
    days = (stability / FACTOR) * (REQUEST_RETENTION**(1 / DECAY) - 1)
    [ days.round, 1 ].max
  end

  def init_difficulty(grade)
    (W[4] - Math.exp(W[5] * (grade - 1)) + 1).clamp(1.0, 10.0)
  end

  def init_stability(grade)
    [ W[grade - 1], 0.1 ].max
  end

  def next_difficulty(difficulty, grade)
    delta = difficulty - W[6] * (grade - 3)
    mean_reversion(init_difficulty(4), delta).clamp(1.0, 10.0)
  end

  def mean_reversion(init, current)
    W[7] * init + (1 - W[7]) * current
  end

  def recall_stability(difficulty, stability, retrievability, grade)
    hard = grade == 2 ? W[15] : 1
    easy = grade == 4 ? W[16] : 1
    stability * (1 + Math.exp(W[8]) * (11 - difficulty) * (stability**-W[9]) *
      (Math.exp((1 - retrievability) * W[10]) - 1) * hard * easy)
  end

  def forget_stability(difficulty, stability, retrievability)
    W[11] * (difficulty**-W[12]) * (((stability + 1)**W[13]) - 1) * Math.exp((1 - retrievability) * W[14])
  end
end
