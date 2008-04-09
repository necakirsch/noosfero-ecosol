require 'digest/sha1'

# User models the system users, and is generated by the acts_as_authenticated
# Rails generator.
class User < ActiveRecord::Base

  N_('User|Password')
  N_('User|Password confirmation')

  def self.human_attribute_name(attrib)
    case attrib.to_sym
      when :login:  return _('Username')
      when :email:  return _('e-Mail')
      else self.superclass.human_attribute_name(attrib)
    end
  end

  before_create do |user|
    if user.environment.nil?
      user.environment = Environment.default
    end
  end

  after_create do |user|
    Person.create!(:identifier => user.login, :name => user.login, :user_id => user.id, :environment_id => user.environment_id)
  end
  
  has_one :person, :dependent => :destroy
  belongs_to :environment

  # Virtual attribute for the unencrypted password
  attr_accessor :password

  validates_presence_of     :login, :email
  validates_format_of       :login, :with => Profile::IDENTIFIER_FORMAT
  validates_presence_of     :password,                   :if => :password_required?
  validates_presence_of     :password_confirmation,      :if => :password_required?
  validates_length_of       :password, :within => 4..40, :if => :password_required?
  validates_confirmation_of :password,                   :if => :password_required?
  validates_length_of       :login,    :within => 2..40
  validates_length_of       :email,    :within => 3..100
  validates_uniqueness_of   :login, :email, :case_sensitive => false
  before_save :encrypt_password
  validates_format_of :email, :with => Noosfero::Constants::EMAIL_FORMAT

  validates_inclusion_of :terms_accepted, :in => [ '1' ], :if => lambda { |u| ! u.terms_of_use.blank? }, :message => N_('%{fn} must be checked in order to signup.')

  # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
  def self.authenticate(login, password)
    u = find_by_login(login) # need to get the salt
    u && u.authenticated?(password) ? u : nil
  end

  # Encrypts some data with the salt.
  def self.encrypt(password, salt)
    Digest::SHA1.hexdigest("--#{salt}--#{password}--")
  end

  # Encrypts the password with the user salt
  def encrypt(password)
    self.class.encrypt(password, salt)
  end

  def authenticated?(password)
    crypted_password == encrypt(password)
  end

  def remember_token?
    remember_token_expires_at && Time.now.utc < remember_token_expires_at 
  end

  # These create and unset the fields required for remembering users between browser closes
  def remember_me
    self.remember_token_expires_at = 2.weeks.from_now.utc
    self.remember_token            = encrypt("#{email}--#{remember_token_expires_at}")
    save(false)
  end

  def forget_me
    self.remember_token_expires_at = nil
    self.remember_token            = nil
    save(false)
  end

  # Exception thrown when #change_password! is called with a wrong current
  # password
  class IncorrectPassword < Exception; end

  # Changes the password of a user.
  #
  # * Raises IncorrectPassword if <tt>current</tt> is different from the user's
  #   current password.
  # * Saves the record unless it is a new one.
  def change_password!(current, new, confirmation)
    raise IncorrectPassword unless self.authenticated?(current)
    self.force_change_password!(new, confirmation)
  end
  
  # Changes the password of a user without asking for the old password. This
  # method is intended to be used by the "I forgot my password", and must be
  # used with care.
  def force_change_password!(new, confirmation)
    self.password = new
    self.password_confirmation = confirmation
    save! unless new_record?
  end

  protected
    # before filter 
    def encrypt_password
      return if password.blank?
      self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{login}--") if new_record?
      self.crypted_password = encrypt(password)
    end
    
    def password_required?
      crypted_password.blank? || !password.blank?
    end
end
