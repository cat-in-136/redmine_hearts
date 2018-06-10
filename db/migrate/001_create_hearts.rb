class CreateHearts < ((Rails.version > "5")? ActiveRecord::Migration[4.2] : ActiveRecord::Migration)
  def change
    create_table :hearts do |t|
      t.references :heartable, :polymorphic => true, :index => true
      t.references :user, :null => false
      t.timestamps :null => false
    end
    add_index :hearts, [:heartable_id, :heartable_type]
    add_index :hearts, :user_id
  end
end
