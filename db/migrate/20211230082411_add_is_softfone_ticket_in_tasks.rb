class AddIsSoftfoneTicketInTasks < ActiveRecord::Migration
  def change
    add_column :tasks, :is_softfone_ticket, :boolean, default: false
  end
end
