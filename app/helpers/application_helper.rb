module ApplicationHelper
  AVATAR_PALETTE = %w[
    #3b82f6 #8b5cf6 #ec4899 #f97316
    #14b8a6 #6366f1 #10b981 #f59e0b
  ].freeze

  def avatar_monogram(nickname)
    return "?" if nickname.blank? || nickname.strip == "Anônimo"
    nickname.strip.chars.first.upcase
  rescue
    "?"
  end

  def avatar_color(seed)
    return AVATAR_PALETTE[0] if seed.blank?
    AVATAR_PALETTE[seed.to_s.sum % AVATAR_PALETTE.size]
  end
end
