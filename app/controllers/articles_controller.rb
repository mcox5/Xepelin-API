require 'nokogiri'
require 'selenium-webdriver'
require 'google_drive'
require 'httparty'

class ArticlesController < ApplicationController
  def index
    head :ok
  end

  def scrapping
    puts 'SCRAPPING!'
    categories = ['emprendedores', 'pymes', 'corporativos', 'empresarios-exitosos', 'educacion-financiera', 'noticias']
    request_data = JSON.parse(request.body.read)
    if categories.include?(request_data['category']) && request_data["webhook"].is_a?(String)
      category = request_data['category']
      webhook = request_data['webhook']
      ScrappingJob.perform_later(category, webhook)
      render json: { message: 'Solicitud exitosa, se está ejecutando el scrapping, por favor espere...' }, status: :ok
    else
      render json: { message: 'Error en la solicitud, entregaste mal los parámetros del body' }, status: :bad_request
    end
  end
end
