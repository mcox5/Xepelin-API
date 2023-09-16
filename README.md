# Blog Articles API

## API Functionality

The Blog Articles API is responsible for web scraping within the Xepelin website, specifically in the blogs section (https://xepelin.com/blog). The API's endpoint accepts a category parameter (with five available categories: entrepreneurs, SMEs, corporates, success stories, and financial education) along with a webhook. The webhook, in turn, receives the Google Sheets URL to be filled with scraping information and an email address for notification when the Google Sheets is updated.

In summary, by making a POST request to the `scrapping` endpoint of the API, the "webscrapping" sheet of the following Google Sheets will be populated with information from the respective category's blog articles:

- [Google Sheets Link](https://docs.google.com/spreadsheets/d/1_6TgW-8cP3B-QdbkE0F3UJ3v9hdDw4cWXzgBu0Qt2zw/)

## Endpoints with curl comands

- Emprendedores:`curl -X POST -H "Content-Type: application/json" -d '{"category":"emprendedores", "webhook":"https://hooks.zapier.com/hooks/catch/11217441/bfemddr"}' https://xepelin-api-7bb5dd1d86de.herokuapp.com/scrapping`
- Pymes: `curl -X POST -H "Content-Type: application/json" -d '{"category":"pymes", "webhook":"https://hooks.zapier.com/hooks/catch/11217441/bfemddr"}' https://xepelin-api-7bb5dd1d86de.herokuapp.com/scrapping`
- Corporativos: `curl -X POST -H "Content-Type: application/json" -d '{"category":"corporativos", "webhook":"https://hooks.zapier.com/hooks/catch/11217441/bfemddr"}' https://xepelin-api-7bb5dd1d86de.herokuapp.com/scrapping`
- Casos de éxito: `curl -X POST -H "Content-Type: application/json" -d '{"category":"empresarios-exitosos", "webhook":"https://hooks.zapier.com/hooks/catch/11217441/bfemddr"}' https://xepelin-api-7bb5dd1d86de.herokuapp.com/scrapping`
- Educación financiera: `curl -X POST -H "Content-Type: application/json" -d '{"category":"educacion-financiera", "webhook":"https://hooks.zapier.com/hooks/catch/11217441/bfemddr"}' https://xepelin-api-7bb5dd1d86de.herokuapp.com/scrapping`

## Scrapping Code

- The route of scrapping code is in the [app/jobs/scrapping_job.rb] (https://github.com/mcox5/Xepelin-API/blob/master/app/jobs/scrapping_job.rb) which is called in the API [articles#scrapping](https://github.com/mcox5/Xepelin-API/blob/master/app/controllers/articles_controller.rb) controller
## Stack

- The API was created using `rails new blog_articles --api`.
- Google Sheets access was facilitated using the `google-drive` gem, simplifying connection and requests to the Google API.
- Web scraping was implemented using the `selenium-webdriver` and `nokogiri` gems.
- To prevent a "request timeout" error in the production environment, web scraping processes were queued as jobs using the `sidekiq` gem.
- POST requests were handled using the `httparty` gem.

## Versions

- Ruby Version: 3.1.2
- Rails Version: 7.0.1
- Chrome Version & ChromeDriver Version: 116.x.x.x

## Development

To run the app locally, follow these steps:

1. Install dependencies: Run `bundle install`.
2. No need to run migrations: `bin/rails db:migrate` as the API operates without databases.
3. Start the server: Execute `bin/rails server` in the console to launch the server.

## Commit Convention

To maintain a clean commit history, we follow the convention of using `git commit -m "feat(context): description"` for commits:

- `feat` is used for new features.
- `fix` is used for bug fixes.

## Example Commit:

- `git commit -m "feat(scraper): Implement web scraping for blog articles"`


## Production

The app is deployed on Heroku, and the following changes should be made in the respective files before deploying:

- **Procfile**: This file specifies the commands Heroku should run during deployment. Add the following lines:

- bundle exec puma -C config/puma.rb
- bundle exec sidekiq -C config/sidekiq.yml


These commands are necessary for running Sidekiq and Puma with their respective configurations for background jobs.

- **Heroku Add-ons**: In production, use the `rediscloud` add-on, where Redis acts as a database for receiving and sending job responses from the queue.

- **Buildpacks**: These are scripts executed when the app is in production.
- heroku/ruby
- Additionally, you'll need buildpacks for Selenium: `https://github.com/heroku/heroku-buildpack-chromedriver`
- `https://github.com/heroku/heroku-buildpack-google-chrome`.

The API uses the basic plan of rediscloud and basic dynos, so its performance may be affected accordingly.

For any questions or contributions, please contact the admin: mcox5@uc.cl.
