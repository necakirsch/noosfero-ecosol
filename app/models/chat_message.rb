class ChatMessage < ActiveRecord::Base
  attr_accessible :from, :to, :message
  validates_presence_of :from, :to, :message
end
