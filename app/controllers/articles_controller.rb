require 'nokogiri'
require 'selenium-webdriver'

class ArticlesController < ApplicationController
  def index
    head :ok
  end

  def scrapping
    result = get_articles_info('emprendedores')
    render json: { articles: result }
  end

  private

  def get_articles_info(category)
    puts 'Starting web_scrapping_xepelin....'
    url = "https://xepelin.com/blog/#{category}"
    begin
      # Configurar el controlador de Selenium
      options = Selenium::WebDriver::Chrome::Options.new
      options.add_argument('--headless') # Ejecutar Chrome en modo headless (sin interfaz gráfica)
      driver = Selenium::WebDriver.for :chrome, options: options

      # Abrir la página en el navegador
      driver.get(url)

      # Esperar un momento para que la página cargue completamente (puedes ajustar el tiempo según sea necesario)
      sleep(2)

      # Obtener el HTML de la página después de que se haya cargado
      doc = Nokogiri::HTML(driver.page_source)
      # p 'obteniendo el doc', doc

      articles = doc.search('.BlogArticle_box__OYCvH .BlogArticle_content__rH5u2') # Para buscar los articulos
      p 'obteniendo los articulos', articles
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
    p 'esta es la url que estoy scrapeando', format_article_name
    url = "https://xepelin.com/blog/#{category}/#{format_article_name}"
    begin
      # Configurar el controlador de Selenium
      options = Selenium::WebDriver::Chrome::Options.new
      options.add_argument('--headless') # Ejecutar Chrome en modo headless (sin interfaz gráfica)
      driver = Selenium::WebDriver.for :chrome, options: options
      # Abrir la página en el navegador
      driver.get(url)
      # Esperar un momento para que la página cargue completamente (puedes ajustar el tiempo según sea necesario)
      sleep(2)
      # Obtener el HTML de la página después de que se haya cargado
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

  def google_sheets
    session = GoogleDrive::Session.from_service_account_key("client_secret.json")
    p 'this is the session', session
    spreadsheet = session.spreadsheet_by_title("GoogleSheets app")
    p 'this is the spreadsheet', spreadsheet
    worksheet = spreadsheet.worksheets.first
    p 'this is the worksheet', worksheet
    p 'LINEASSSS', worksheet.rows.first(5)
  end
end
