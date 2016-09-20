class CountQuestionsForUser
  attr_accessor :authorized_submitter_id

  def initialize(authorization)
    self.authorized_submitter_id = authorization.id
  end

  def perform
    authorized_submitter = AuthorizedSubmitter.find(authorized_submitter_id)
    authorized_submitter.count_available_questions
  end
end
