ActiveRecord::FixtureSet.create_fixtures(
  Rails.root.join("evals"),
  %w[
    fizzbuzz/prompts fizzbuzz/samples fizzbuzz/runs fizzbuzz/executions
    workbook/prompts workbook/samples workbook/runs workbook/executions
  ]
)

ActiveRecord::FixtureSet.create_fixtures(
  Rails.root.join("db/seeds/fixtures"),
  %w[links gists]
)

auth_session = WorkbookSession.create!(
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

auth_thought = auth_session.biased_thoughts.create!(
  thought: "My auth implementation will be criticized as insecure.",
  pre_believability: 85,
  post_believability: 40,
  position: 1
)

auth_session.update!(primary_thought_id: auth_thought.id)
