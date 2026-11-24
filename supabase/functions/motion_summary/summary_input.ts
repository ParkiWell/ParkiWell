type Metrics = Record<string, number>;
type SummaryInput = {
  session: {
    overall_score?: number;
    assessed_steps?: number;
    total_steps?: number;
    steps: Metrics[];
  };
  recent_scores: number[];
};

const COUNT_KEYS = ["assessed_steps", "total_steps"];
const REP_KEYS = ["completed_repetitions", "target_repetitions"];
const SCORE_KEYS = [
  "overall_score",
  "range_score",
  "tempo_score",
  "smoothness_score",
  "symmetry_score",
];

function object(value: unknown): Record<string, unknown> {
  return value && typeof value === "object" && !Array.isArray(value)
    ? value as Record<string, unknown>
    : {};
}

function score(value: unknown): number | null {
  return typeof value === "number" && Number.isFinite(value) && value >= 0 &&
      value <= 100
    ? Math.round(value * 10) / 10
    : null;
}

function selectMetrics(
  source: Record<string, unknown>,
  countKeys: string[],
  scoreKeys: string[],
): Metrics {
  const metrics: Metrics = {};
  for (const key of countKeys) {
    const value = source[key];
    if (
      typeof value === "number" && Number.isInteger(value) && value >= 0 &&
      value <= 100
    ) {
      metrics[key] = value;
    }
  }
  for (const key of scoreKeys) {
    const value = score(source[key]);
    if (value !== null) metrics[key] = value;
  }
  return metrics;
}

/// Construct the exact provider payload from bounded numeric metrics. Record
/// fields such as identifiers, timestamps and summary sentences stay in ParkiWell.
export function buildSummaryInput(
  record: unknown,
  overallScore: unknown,
  recentScores: unknown[],
): SummaryInput {
  const session = object(record);
  return {
    session: {
      ...selectMetrics(
        { ...session, overall_score: overallScore },
        COUNT_KEYS,
        ["overall_score"],
      ),
      steps: Array.isArray(session.steps)
        ? session.steps.slice(0, 10).map((step) =>
          selectMetrics(object(step), REP_KEYS, SCORE_KEYS)
        )
        : [],
    },
    recent_scores: recentScores.slice(0, 10).map(score).filter((value) =>
      value !== null
    ),
  };
}
