class AddAgentReferenceInContacts < ActiveRecord::Migration
  def change
    add_reference :contacts, :agent, index: true
  end

end
