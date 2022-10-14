class Customer::TaskNote < ActiveRecord::Base
  enum state: [:unsolved, :ready]
  belongs_to :customer
end
