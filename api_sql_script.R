library(httr)
library(jsonlite)
library(RSQLite)
library(openxlsx)

#The api keys
weatherstack_key <- "Text1"
api_ninjas_key <- "Text2"

cities <- c("London", "Paris", "Berlin", "Amsterdam", "Madrid", "Rome", "Athens", "Istanbul", "Lisbon", "Kyiv")


# Function to get weather data for a city using Weatherstack API
get_weather_data <- function(city) {
  base_url_weather <- "http://api.weatherstack.com/current"
  params <- list(
    access_key = weatherstack_key,
    query = city
  )
  
  # Make the GET request
  response <- GET(url = base_url_weather, query = params)
  
  #I used the two lines of code underneath to debug the function because I had some problems
  #print(paste("Weather API Response Code for", city, ":", status_code(response)))
  #print(paste("Response Content for", city, ":", content(response, as = "text")))
  
  # Check for successful response
  if (status_code(response) != 200) {
    stop("Failed to retrieve data for city: ", city, " - Status code: ", status_code(response))
  }
  
  # Parse the JSON content
  data <- fromJSON(content(response, as = "text", encoding = "UTF-8"))
  
  #I am creating a dataframe that stores all the details from the JSON file about weather
  weather_df <- data.frame(
    city_name = city, 
    observation_time = data$current$observation_time,
    temperature = data$current$temperature,
    weather_code = data$current$weather_code,
    weather_icons = paste(data$current$weather_icons, collapse = ", "),
    weather_descriptions = paste(data$current$weather_descriptions, collapse = ", "),
    wind_speed = data$current$wind_speed,
    wind_degree = data$current$wind_degree,
    wind_dir = data$current$wind_dir,
    pressure = data$current$pressure,
    precip = data$current$precip,
    humidity = data$current$humidity,
    cloudcover = data$current$cloudcover,
    feelslike = data$current$feelslike,
    uv_index = data$current$uv_index,
    visibility = data$current$visibility,
    is_day = data$current$is_day,
    localtime = data$location$localtime,            
    # Include localtime from location
    localtime_epoch = data$location$localtime_epoch,
    stringsAsFactors = FALSE
  )
  return(weather_df)
}


get_population_data <- function(city) {
  # Replace spaces in the city name with '%20' for proper URL encoding (I had problemswithout it)
  encoded_city <- URLencode(city)
  
  # Construct the URL with query parameters
  # paste0 is used to concatenate strings
  base_url <- paste0("https://api.api-ninjas.com/v1/city?name=", encoded_city)
  
  # Make the GET request with the API key in the headers
  #some APIs require authentication or authorization using API keys passed in the HTTP headers 
  #that's why I used the add_headers() function
  response <- GET(url = base_url, add_headers("X-Api-Key" = api_ninjas_key))
  
  #Code for debugging
  #print(paste("Population API Response Code for", city, ":", status_code(response)))
  #print(paste("Response Content for", city, ":", content(response, as = "text")))
  
  # Check for successful response
  if (status_code(response) != 200) {
    stop("Failed to retrieve data for city: ", city, " - Status code: ", status_code(response))
  }
  
  # Parse the JSON content
  data <- fromJSON(content(response, as = "text", encoding = "UTF-8"))
  
  # Handle cases where the city is not found or data is missing
  if (length(data) == 0) {
    stop("No data found for city: ", city)
  }
  
  #Create a data frame for the population data collected from the API
  population_df <- data.frame(
    city_name = city,
    latitude = data$latitude,
    longitude = data$longitude,
    country = data$country,
    population = data$population,
    is_capital = data$is_capital,
    stringsAsFactors = FALSE
  )
  
  return(population_df) # Return the structured data frame for the city
}


# Retrieve and combine weather data for all cities into a single data frame
weather_data <- map_df(cities, ~ {
  Sys.sleep(1)  # To respect rate limits
  get_weather_data(.x)
})

# Retrieve and combine population data for all cities into a single data frame
population_data <- map_df(cities, ~ {
  Sys.sleep(1)  # To respect rate limits
  get_population_data(.x)
})

weather_data
#I used glimpse to see the data type in order to correctly make the SQL tables
glimpse(weather_data)
population_data
glimpse(population_data)

#Opened the connection to a database named weather_population_data.db
conn <- dbConnect(SQLite(), dbname = "weather_population_data.db")

#I used this line of code because I reran it a couple of times and it was easier than using alter
dbExecute(conn, "DROP TABLE IF EXISTS population")
dbExecute(conn, "DROP TABLE IF EXISTS weather")

#Creating the population tables with all the fields that are in the population_data data frame
#city_name is the primary key

dbExecute(conn, "
CREATE TABLE IF NOT EXISTS population (
city_name TEXT PRIMARY KEY,
latitude DOUBLE,
longitude DOUBLE,
country TEXT,
population INTEGER,
is_capital BOOLEAN
)"
          )


# Create the weather table with the correct schema
#I used city_name as the foreign key in order to link the 2 tables by city
dbExecute(conn, "
CREATE TABLE IF NOT EXISTS weather(
  city_name TEXT PRIMARY KEY,
  observation_time TEXT,
  temperature INTEGER,
  weather_code INTEGER,
  weather_icons TEXT,
  weather_descriptions TEXT,
  wind_speed INTEGER,
  wind_degree INTEGER,
  wind_dir TEXT,
  pressure INTEGER,
  precip DOUBLE,
  humidity INTEGER,
  cloudcover INTEGER,
  feelslike INTEGER,
  uv_index INTEGER,
  visibility INTEGER,
  is_day TEXT,
  localtime TEXT,
  localtime_epoch INTEGER,
  FOREIGN KEY (city_name) REFERENCES population(city_name)
)"
)

# Insert the weather_data into the weather table
dbWriteTable(conn,
             name = "weather",
             value = weather_data,
             append = TRUE, 
             row.names = FALSE)

# Insert the weather_data into the population table
dbWriteTable(conn, 
             name = "population",
             value = population_data, 
             append = TRUE, 
             row.names = FALSE)

#Check that the data is properly stored in the database
dbGetQuery(conn, "SELECT * FROM weather")
dbGetQuery(conn, "SELECT * FROM population")

#3. Writing SQL Queries

#I have selected the necessary fields from the weather table and order them by temperature in ascending order (low to high)
query1 <- dbGetQuery(conn, "SELECT city_name, temperature, localtime,localtime_epoch
                     FROM weather
                     ORDER BY temperature ASC")
query1

#I have selected the necessary fields from the 2 tables: weather (w) and population(p). 
#I did an inner join between the two tables by city and ordered the resulting records by population(ascending)
query2 <- dbGetQuery(conn, "SELECT w.city_name, p.population,
                                        w.temperature, w.localtime, w.localtime_epoch
                                        FROM weather w
                                        INNER JOIN population p ON w.city_name = p.city_name
                                        ORDER BY population ASC") 
query2


#I calculated the dew point tempreture by using the formula provided in the document
#Used AS to name the column as I wanted
query3 <- dbGetQuery(conn, "SELECT city_name, temperature, humidity,temperature - ((100 - humidity)/5) AS dew_point_temperature ,localtime, localtime_epoch
                     FROM weather")
query3

#In order to calculate the absolute temperature difference between each pair of cities
#I needed to join the same table, selecting the same fields from the 2 identical tables 
#The join condition is that the 2 cities are different, so I don't have for e.g Lisbon-Lisbon
#To calculate the absolute difference I used the ABS function from SQL and ordered the output alphabetically

query4 <- dbGetQuery(conn, "SELECT w1.city_name AS city_name1 , w2.city_name AS city_name2 , 
                                        w1.temperature AS temperature1 ,
                                        w2.temperature AS temperature2, 
                                        ABS(w1.temperature - w2.temperature) AS absolute_temperature_difference , 
                                        w1.localtime AS localtime1, 
                                        w1.localtime_epoch AS localtime_epoch1, 
                                        w2.localtime AS localtime2, 
                                        w2.localtime_epoch AS localtime_epoch2 
                                        FROM weather w1 JOIN  weather w2 ON w1.city_name != w2.city_name
                                        ORDER BY city_name1, city_name2")
query4

#In the code above each pair appears twice (Amsterdam - Lisbon and Lisbon - Amsterdam) because in the ON clause we just check that the 2 cities are different
#(so we don't have Lisbon - Lisbon for e.g.)
#If we want to have the pairs appear only once we can use w1.city_name < w2.city_name as shown below:
query4_v2 <- dbGetQuery(conn, "SELECT w1.city_name AS city_name1 , w2.city_name AS city_name2 , 
                                        w1.temperature AS temperature1 ,
                                        w2.temperature AS temperature2, 
                                        ABS(w1.temperature - w2.temperature) AS absolute_temperature_difference , 
                                        w1.localtime AS localtime1, 
                                        w1.localtime_epoch AS localtime_epoch1, 
                                        w2.localtime AS localtime2, 
                                        w2.localtime_epoch AS localtime_epoch2 
                                        FROM weather w1 JOIN  weather w2 ON w1.city_name < w2.city_name
                                        ORDER BY city_name1, city_name2")
query4_v2


#4. Exporting Data
#4.1. Export Full Data and Query Results to CSV

#I used row.names = FALSE so the csv file won't contain the row number
write.csv(weather_data, "weather_data.csv", row.names = FALSE)
write.csv(population_data, "population_data", row.names = FALSE)

write.csv(query1, "query1.csv", row.names = FALSE)
write.csv(query2, "query2.csv", row.names = FALSE)
write.csv(query3, "query3.csv", row.names = FALSE)
write.csv(query4, "query4.csv", row.names = FALSE)
write.csv(query4_v2, "query4_v2.csv", row.names = FALSE)

#4.2. Combine the CSVs into a Single XLS File

#To create the excel workbooks I used the openxlsx library

#I first need to create the workbook
wb <- createWorkbook()
#After, I added each sheet loading the proper data into each one
addWorksheet(wb, "A")
writeData(wb, "A", weather_data)
addWorksheet(wb, "B")
writeData(wb, "B", population_data)
addWorksheet(wb, "C")
writeData(wb, "C", query1)
addWorksheet(wb, "D")
writeData(wb, "D", query2)
addWorksheet(wb, "E")
writeData(wb, "E", query3)
addWorksheet(wb, "F")
writeData(wb, "F", query4)

# Save the Excel workbook
saveWorkbook(wb, "Andreea_Iordache_assignment1_data.xlsx", overwrite = TRUE)

# 5. Close the database connection
dbDisconnect(conn)
