# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

Rails.application.routes.draw do
  get 'hearts', :to => 'hearts#index'

  post 'hearts/heart', :to => 'hearts#heart', :as => 'heart'
  delete 'hearts/heart', :to => 'hearts#unheart'
  get 'hearts/hearted_users', :to => 'hearts#hearted_users'
end
