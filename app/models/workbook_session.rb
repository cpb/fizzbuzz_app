class WorkbookSession < ApplicationRecord
  has_many :biased_thoughts, -> { order(:position, :id) }, dependent: :destroy
  belongs_to :primary_thought, class_name: "BiasedThought", optional: true,
             foreign_key: :primary_thought_id
  has_many :thinking_trap_evaluations, dependent: :destroy

  accepts_nested_attributes_for :biased_thoughts,
    reject_if: :all_blank, allow_destroy: true

  validates :current_step, presence: true

  FALLBACK_THOUGHT = "My code will be heavily criticized and my teammates will think less of me as an engineer."

  def self.auth_demo
    find_by("situation_description LIKE ?", "%auth%")
  end

  def self.seed_auth_demo
    session = create!(
      situation_description: "I need to add auth to the API and submit a PR for review.",
      current_step: "summary",
      suds_initial: 8,
      suds_post_tipp: 7,
      suds_post_restructuring: 4,
      tipp_strategy: "paced_breathing",
      rational_response: "My team wants me to succeed, and adding auth is complex work that deserves thoughtful review.",
      rational_believability: 65,
      review_direction: "ask",
      dear_plan: "I will ask Sarah to review my auth PR and explain my approach."
    )
    thought = session.biased_thoughts.create!(
      thought: "My auth implementation will be criticized as insecure.",
      pre_believability: 85,
      post_believability: 40,
      position: 1
    )
    session.update!(primary_thought_id: thought.id)
    session
  end

  STEPS = %w[suds_initial tipp describe_situation biased_thoughts
             select_primary select_trap evidence rational_response
             post_believability suds_final dear_give dear_plan give_plan summary].freeze

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
    return "dear_give" if %w[dear_plan give_plan].include?(current_step)
    steps = conditional_steps
    idx = steps.index(current_step)
    idx&.positive? ? steps[idx - 1] : steps.first
  end

  def first_step?
    current_step == conditional_steps.first
  end

  def primary_thought_text
    primary_thought&.thought.presence || FALLBACK_THOUGHT
  end

  private

  def conditional_steps
    if suds_initial.present? && suds_initial.to_i <= 2
      %w[suds_initial dear_give dear_plan give_plan summary]
    else
      STEPS.reject { |s| s == "tipp" && suds_initial.to_i < 7 }
    end
  end
end
