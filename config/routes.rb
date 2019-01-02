# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

Rails.application.routes.draw do
  get 'hearts', :to => 'hearts#index'
  get 'projects/:project_id/hearts', :to => 'hearts#index'
  get 'hearts/notifications', :to => 'hearts#notifications'
  get 'hearts/hearted_by/:user_id', :to => 'hearts#hearted_by'

  post 'hearts/heart', :to => 'hearts#heart', :as => 'heart'
  delete 'hearts/heart', :to => 'hearts#unheart'
  get 'hearts/hearted_users', :to => 'hearts#hearted_users'
end
