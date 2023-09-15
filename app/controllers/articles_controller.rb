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
      clean_google_sheets # 1: Limpiamos la hoja de calculo
      articles_info = get_articles_info(category) # 2: Obtenemos los articulos
      write_google_sheets(articles_info) # 3: Escribimos en la hoja de calculo
      post_request(webhook) # 4: Hacemos Request a la webhook con el link del googlesheet y el mail como body
      render json: { message: 'Solicitud de scrapping recibida y hoja de calculo actualizada!' }, status: :ok
    else
      render json: { error: 'Argumentos incorrectos en el cuerpo de la solicitud' }, status: :bad_request
    end
  end

  private

  def get_articles_info(category)
    puts 'Starting web_scrapping_xepelin....'
    url = "https://xepelin.com/blog/#{category}"
    begin
      options = Selenium::WebDriver::Chrome::Options.new
      options.add_argument('--headless') # Ejecutar Chrome en modo headless (sin interfaz gráfica)
      driver = Selenium::WebDriver.for :chrome, options: options
      driver.get(url)
      sleep(2)
      doc = Nokogiri::HTML(driver.page_source)
      articles = doc.search('.BlogArticle_box__OYCvH .BlogArticle_content__rH5u2') # Para buscar los articulos
      articles_object = {}
      articles.each do |article|
        article_info = {}
        article_info[:title] = article.search('h3').children.text
        article_info[:author] = article.search('.BlogArticle_authorDescription__Bwi4T').children.text.split(' |').first
        article_info[:category] = category
        article_info[:time] = get_lecture_time(category, article_info[:title]) || 'No se pudo obtener el tiempo (url no encontrada)'
        articles_object[article_info[:title]] = article_info
      end
      return articles_object
    rescue StandardError => e
      p "Error: #{e.message}"
    ensure
      driver.quit if driver
    end
  end

  def get_lecture_time(category, article_name)
    format_article_name = format_article_name(article_name) # Formateamos el nombre para poder escrapear el articulo
    url = "https://xepelin.com/blog/#{category}/#{format_article_name}"
    begin
      options = Selenium::WebDriver::Chrome::Options.new
      options.add_argument('--headless')
      driver = Selenium::WebDriver.for :chrome, options: options
      driver.get(url)
      sleep(2)
      doc = Nokogiri::HTML(driver.page_source)
      time = doc.search('.iaKuDo .justify-center .sc-fe594033-0').children.text.split(' ').first
      return time
    rescue StandardError => e
      puts "Error: #{e.message}"
    ensure
      driver.quit if driver
    end
  end

  def format_article_name(article_name)
    formatted_name = article_name.downcase.tr('áéíóúü', 'aeiouu').tr(':', '').tr(';', '').tr(',', '').tr(' ', '-').tr('¿', '').tr('?', '').tr('¡', '').tr('!', '').tr('(', '').tr(')', '').tr('.', '')
    return formatted_name
  end

  def write_google_sheets(articles_info)
    p 'writing...'
    session = GoogleDrive::Session.from_service_account_key("client_secret.json")
    spreadsheet = session.spreadsheet_by_title("GoogleSheets app")
    worksheet = spreadsheet.worksheets[1]
    articles_info.each do |_key, value|
      worksheet.insert_rows(worksheet.num_rows + 1, [[value[:title], value[:author], value[:category], value[:time], '--']])
    end
    worksheet.save
  end

  def clean_google_sheets
    session = GoogleDrive::Session.from_service_account_key('client_secret.json')
    spreadsheet = session.spreadsheet_by_title('GoogleSheets app')
    worksheet = spreadsheet.worksheets[1]
    # Define el rango de celdas que deseas borrar (columnas A a E, desde la fila 2 hacia abajo)
    start_row = 2
    end_row = worksheet.num_rows  # Esto obtiene el número total de filas en la hoja
    start_column = 1  # Columna A
    end_column = 5    # Columna E
    # Itetación para borrar el contenido de las celdas en el rango especificado
    (start_row..end_row).each do |row_index|
      (start_column..end_column).each do |column_index|
        worksheet[row_index, column_index] = nil
      end
    end
    # Guarda los cambios en la hoja de cálculo
    worksheet.save
  end

  def post_request(webhook_url)
    body = {
      link: 'https://docs.google.com/spreadsheets/d/1_6TgW-8cP3B-QdbkE0F3UJ3v9hdDw4cWXzgBu0Qt2zw',
      email: 'mcox5@uc.cl'
    }
    response = HTTParty.post(webhook_url, body: body.to_json, headers: { 'Content-Type' => 'application/json' })
    p response
    if response.success?
      puts "Solicitud exitosa. Respuesta del servidor: #{response.body}"
    else
      puts "Error en la solicitud. Código de estado: #{response.code}, Mensaje: #{response.message}"
    end
  end
end
