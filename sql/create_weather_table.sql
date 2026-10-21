-- Target table for the transform_load_weather_data task
CREATE TABLE IF NOT EXISTS weather_data (
    id SERIAL PRIMARY KEY,
    city VARCHAR(50),
    description VARCHAR(100),
    temperature_f FLOAT,
    feels_like_f FLOAT,
    min_temp_f FLOAT,
    max_temp_f FLOAT,
    pressure INTEGER,
    humidity INTEGER,
    wind_speed FLOAT,
    time_of_record TIMESTAMP,
    sunrise TIMESTAMP,
    sunset TIMESTAMP
);
