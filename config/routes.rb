# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

Rails.application.routes.draw do
  post 'hearts/heart', :to => 'hearts#heart', :as => 'heart'
  delete 'hearts/heart', :to => 'hearts#unheart'
end
