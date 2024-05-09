#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=salon"

# Check if tables already exist
TABLE_EXISTS=$($PSQL -tAc "SELECT EXISTS(SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='customers');")

if [ "$TABLE_EXISTS" = "f" ]; then
    $PSQL -c "CREATE TABLE customers (customer_id SERIAL PRIMARY KEY, name VARCHAR NOT NULL, phone VARCHAR UNIQUE);"
fi

TABLE_EXISTS=$($PSQL -tAc "SELECT EXISTS(SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='services');")

if [ "$TABLE_EXISTS" = "f" ]; then
    $PSQL -c "CREATE TABLE services (service_id SERIAL PRIMARY KEY, name VARCHAR NOT NULL);"
fi

TABLE_EXISTS=$($PSQL -tAc "SELECT EXISTS(SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='appointments');")

if [ "$TABLE_EXISTS" = "f" ]; then
    $PSQL -c "CREATE TABLE appointments (appointment_id SERIAL PRIMARY KEY, customer_id INT REFERENCES customers(customer_id), service_id INT REFERENCES services(service_id), time VARCHAR NOT NULL);"
fi

# Insert services if they don't exist
SERVICE_COUNT=$($PSQL -tAc "SELECT COUNT(*) FROM services;")
if [ "$SERVICE_COUNT" -lt 3 ]; then
    $PSQL -c "INSERT INTO services (name) VALUES ('cut'), ('color'), ('style');"
fi

while true; do
    echo -e "Services offered:"
    SERVICES=$($PSQL -tAc "SELECT service_id, name FROM services;")
    while read -r SERVICE; do
        SERVICE_ID=$(echo "$SERVICE" | cut -d '|' -f 1)
        SERVICE_NAME=$(echo "$SERVICE" | cut -d '|' -f 2)
        echo "$SERVICE_ID) $SERVICE_NAME"
    done <<< "$SERVICES"

    echo -e "\nEnter service ID: "
    read SERVICE_ID_SELECTED
    SERVICE_EXISTS=$($PSQL -tAc "SELECT EXISTS(SELECT 1 FROM services WHERE service_id=$SERVICE_ID_SELECTED);")
    if [ "$SERVICE_EXISTS" = "t" ]; then
        break
    else
        echo "Invalid service ID. Please try again."
    fi
done

while true; do
    echo -e "\nEnter phone number: "
    read CUSTOMER_PHONE
    CUSTOMER_EXISTS=$($PSQL -tAc "SELECT EXISTS(SELECT 1 FROM customers WHERE phone='$CUSTOMER_PHONE');")
    if [ "$CUSTOMER_EXISTS" = "t" ]; then
        CUSTOMER_NAME=$($PSQL -tAc "SELECT name FROM customers WHERE phone='$CUSTOMER_PHONE';")
        break
    else
        echo "The phone number does not exist in our records."
        echo -e "\nEnter your name: "
        read CUSTOMER_NAME
        $PSQL -c "INSERT INTO customers (name, phone) VALUES ('$CUSTOMER_NAME', '$CUSTOMER_PHONE');"
        break
    fi
done

echo -e "\nEnter time: "
read SERVICE_TIME

$PSQL -c "INSERT INTO appointments (customer_id, service_id, time) SELECT customer_id, $SERVICE_ID_SELECTED, '$SERVICE_TIME' FROM customers WHERE phone='$CUSTOMER_PHONE';"

echo "I have put you down for a $(echo "$SERVICES" | grep -w "$SERVICE_ID_SELECTED" | cut -d '|' -f 2) at $SERVICE_TIME, $CUSTOMER_NAME."
