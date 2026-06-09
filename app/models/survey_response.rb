class SurveyResponse < ApplicationRecord
  serialize :ai_tools, coder: JSON

  before_validation { ai_tools.reject!(&:blank?) }


  enum :role, { developer: "developer", engineering_manager: "engineering_manager",
                student: "student", other: "other" }, validate: true, prefix: :role

  enum :paid_to_write_ruby, { yes: "yes", no: "no", sometimes: "sometimes" }, validate: true, prefix: :paid_to_write_ruby

  enum :years_of_experience, { none: "none", lt_1: "lt_1", one_to_3: "1_3",
                                four_to_6: "4_6", seven_to_9: "7_9",
                                ten_to_13: "10_13", fourteen_plus: "14_plus" }, validate: true, prefix: :years_of_experience

  enum :prior_experience, { none: "none", lt_2: "lt_2",
                             two_to_5: "2_5", five_plus: "5_plus" }, validate: true, prefix: :prior_experience

  enum :team_ai_adoption, {
    regularly_integrated: "regularly_integrated",
    actively_experimenting: "actively_experimenting",
    tried_no_routine: "tried_no_routine",
    aware_not_started: "aware_not_started",
    evaluated_decided_not_to_use: "evaluated_decided_not_to_use"
  }, validate: true, prefix: :team_ai_adoption

  validates :role, :paid_to_write_ruby, :years_of_experience,
            :prior_experience, :team_ai_adoption, :submitted_at, :location, presence: true
  validates :writes_ruby, inclusion: { in: [ true, false ], message: "must be selected" }

  validates :likert_overhyped, :likert_frustrated, :likert_limit_to_boilerplate,
            :likert_anxious, :likert_made_peace, :likert_more_capable,
            numericality: { only_integer: true, in: 1..5 }, allow_nil: true

  LIKERT_COLUMNS = %i[
    likert_overhyped likert_frustrated likert_limit_to_boilerplate
    likert_anxious likert_made_peace likert_more_capable
  ].freeze

  AI_TOOL_OPTIONS = %w[
    claude_code_cli cursor copilot chatgpt claude_web gemini aider other none
  ].freeze

  def self.aggregate_stats
    total = count.to_f
    role_counts        = group(:role).count
    writes_ruby_counts = group(:writes_ruby).count
    paid_counts        = group(:paid_to_write_ruby).count
    exp_counts         = group(:years_of_experience).count
    prior_exp_counts   = group(:prior_experience).count
    adopt_counts       = group(:team_ai_adoption).count
    likert_avgs        = LIKERT_COLUMNS.index_with { |col| average(col)&.round(2) }
    tool_counts        = Hash.new(0).tap do |h|
      pluck(:ai_tools).each { |tools| tools.each { |t| h[t] += 1 unless t.blank? } }
    end
    { total: total.to_i, role: role_counts, writes_ruby: writes_ruby_counts,
      paid_to_write_ruby: paid_counts, years_of_experience: exp_counts,
      prior_experience: prior_exp_counts, team_ai_adoption: adopt_counts,
      likert: likert_avgs, ai_tools: tool_counts.sort_by { |_, v| -v }.to_h }
  end
end
