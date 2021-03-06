class Survey::Attempt < ActiveRecord::Base
  self.table_name = "survey_attempts"

  belongs_to :survey
  belongs_to :participant, polymorphic: true
  has_many :answers, dependent: :destroy

  accepts_nested_attributes_for :answers

  validates :participant_id, :participant_type, presence: true
  validate :check_number_of_attempts_by_survey

  scope :wins,   -> { where(winner: true) }
  scope :looses, -> { where(winner: false) }
  scope :scores, -> { order("score DESC") }
  scope :for_survey, ->(survey) { where(survey_id: survey.id) }
  scope :exclude_survey,  ->(survey) { where("NOT survey_id = #{survey.id}") }
  scope :for_participant, ->(participant) {
    where(participant_id: participant.try(:id),
          participant_type: participant.class.base_class.name)
  }

  before_create :collect_scores

  def correct_answers
    return self.answers.where(correct: true)
  end

  def incorrect_answers
    return self.answers.where(correct: false)
  end

  def self.high_score
    return scores.first.score
  end

  private

  def check_number_of_attempts_by_survey
    attempts = self.class.for_survey(survey).for_participant(participant)
    upper_bound = self.survey.attempts_number

    if attempts.size >= upper_bound && upper_bound != 0
      errors.add(:survey_id, "Number of attempts exceeded")
    end
  end

  def collect_scores
    self.score = self.answers.map(&:value).reduce(:+) || 0
  end
end
