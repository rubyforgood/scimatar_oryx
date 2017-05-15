class Animal < ApplicationRecord
  include Searchable

  Animal.search_endpoint = ENV['CLOUDSEARCH_ANIMALS_SEARCH_URL']
  Animal.doc_endpoint = ENV['CLOUDSEARCH_ANIMALS_DOC_URL']

  belongs_to :facility
  belongs_to :species
  belongs_to :sex
  belongs_to :rearing
  belongs_to :reproductive_status

  has_many :pictures, :dependent => :destroy

  validates :name, presence: true
  validates :facility_id, presence: true
  validates :species_id, presence: true
  validates :date_of_birth, presence: true

  scope :searchable, -> { where(searchable: true) }

  VALID_INTERESTS = ["keep", "sell", "trade", "loan", "sell or trade in 1-2 years", "looking for mate"].freeze
  
  before_save { |animal| animal.interests = animal.interests.uniq.select{ |e| VALID_INTERESTS.include?(e) } }

  accepts_nested_attributes_for :pictures

  def age
    return unless date_of_birth.present?
    ((Time.now - date_of_birth.to_time) / 1.year).round
  end

  def gender
    sex.try :name
  end

  VALID_INTERESTS.each do |interest|
    define_method("interest_to_#{interest}?"){ interests.include?(interest) }
  end

  private

  def ngrams
    name.split(' ').tap do |ngrams|
      ngrams << date_of_birth.year if date_of_birth.present?
      ngrams << sex.name if sex.present?
      ngrams << rearing.name if rearing.present?
      ngrams << reproductive_status.name if reproductive_status.present?
      ngrams << studbook if studbook.present?
      ngrams << tag if tag.present?
      ngrams << transponder if transponder.present?
    end
  end

  def indexed_fields
    {
      date_of_birth: date_of_birth.present? ? date_of_birth.strftime('%FT%TZ') : nil,
      species: species.name.downcase,
      facility: facility.name.downcase,
      ngrams: ngrams
    }
  end

end
