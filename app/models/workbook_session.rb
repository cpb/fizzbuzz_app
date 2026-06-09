class WorkbookSession < ApplicationRecord
  has_many :biased_thoughts, -> { order(:position, :id) }, dependent: :destroy
  belongs_to :primary_thought, class_name: "BiasedThought", optional: true,
             foreign_key: :primary_thought_id
  has_many :thinking_trap_evaluations, dependent: :destroy

  accepts_nested_attributes_for :biased_thoughts,
    reject_if: :all_blank, allow_destroy: true

  validates :current_step, presence: true

  STEPS = %w[suds_initial tipp describe_situation biased_thoughts
             select_primary select_trap evidence rational_response
             dear_give dear_plan give_plan summary].freeze

  def next_step
    case current_step
    when "dear_give"
      review_direction == "ask" ? "dear_plan" : "give_plan"
    when "dear_plan", "give_plan"
      "summary"
    else
      steps = conditional_steps
      idx = steps.index(current_step)
      steps[idx + 1] if idx
    end
  end

  def prev_step
    steps = conditional_steps
    effective = %w[dear_plan give_plan].include?(current_step) ? "dear_give" : current_step
    idx = steps.index(effective)
    idx&.positive? ? steps[idx - 1] : steps.first
  end

  private

  def conditional_steps
    STEPS.reject { |s| s == "tipp" && suds_initial.to_i < 7 }
  end
end
