# Adventure Trek Booking System with Dynamic Pricing (India)

A MySQL database for an adventure and trek travel company operating across India. It manages customers, destinations, five transport types, payments and bookings, and includes a **Dynamic Pricing module** that changes fares automatically with demand and season.

> Originally a team DBMS course project. I extended it with the Dynamic Pricing module and reviewed, tested, fixed and redesigned the full script (see [My Contribution](#my-contribution)).

## Features

- 12 tables, 4 views and 1 stored procedure
- Domestic transport: trains, flights, buses, cars and coastal cruises
- Dynamic pricing: `FinalPrice = BaseFare x DemandMultiplier x SeasonalMultiplier`
- Price history per destination, with a view that returns the latest price
- Each booking stores the price that applied when it was made
- Data quality through primary and foreign keys, UNIQUE, NOT NULL and CHECK constraints
- Fully re-runnable: the script drops and recreates the database every time

## Tech Stack

- MySQL 8.0.16 or later (needed for CHECK constraints and generated columns)
- MySQL Workbench (any SQL client works)

## Database Overview

| Table | Purpose |
| --- | --- |
| `CustomerDetails_Yashwanth` | Customers, contact details and ID proof |
| `Employee_Yashwanth` | Staff: drivers, guides, supervisors, booking agents |
| `Destination_Yashwanth` | 15 Indian destinations with state and distance from Mumbai |
| `Trains_Yashwanth`, `Flights_Yashwanth`, `Buses_Yashwanth`, `Cruise_Yashwanth`, `Car_Yashwanth` | Transport options, each linked to a destination |
| `Payment_Yashwanth` | Payments made by customers |
| `Booking_Yashwanth` | Links customer, payment, origin, destination, transport and locked price |
| `DynamicPricing_Yashwanth` | Base fare, multipliers and generated final price, with history |
| `Customer_Documents_Yashwanth` | Copy of customer ID proof details |

Views: `Booking_Summary_Yashwanth`, `Destinations_Booked_Yashwanth`, `CurrentPricing_Yashwanth`, `DynamicPricing_Overview_Yashwanth`

Stored procedure: `sp_UpdateDemand_Yashwanth(destination_id)` sets the demand multiplier from the number of active bookings.

## How Dynamic Pricing Works

```
FinalPrice = BaseFare x DemandMultiplier x SeasonalMultiplier
```

Example (Mumbai, April): 2000 x 1.25 x 1.10 = **2750** INR.

- `FinalPrice` is a **generated column**, so it can never go out of date.
- A unique key on `(DestinationID, PricingDate)` keeps one price per destination per date.
- `CurrentPricing_Yashwanth` always returns the latest price.
- `Booking_Yashwanth.PricingID` locks in the price at booking time, so later changes do not rewrite history.

## How to Run

1. Open MySQL Workbench and connect to your local MySQL server.
2. Open `Adventure_Trek_Booking_India_Yashwanth.sql` (File, Open SQL Script).
3. Click in the editor and select everything (Cmd/Ctrl + A).
4. Click the first lightning bolt icon to run the whole script.
5. Refresh the Schemas panel to see the `Yashwanth_TrekDB` database.

Warning: the script starts with `DROP DATABASE IF EXISTS Yashwanth_TrekDB`. Do not use that name for a database you want to keep.

## Sample Queries Included

- Current dynamic price of every destination
- Destinations in peak season (seasonal multiplier above 1.10)
- Top 3 most expensive and cheapest destinations
- Markup percentage over the base fare
- Demand surge simulation for Goa, Kochi and Port Blair
- Locked booking price versus today's price
- Destinations with no pricing set up yet
- Joins, self join, GROUP BY with HAVING, EXISTS and NOT EXISTS, views

## My Contribution

- Built the **Dynamic Pricing** module (table, data, queries, view and stored procedure)
- Tested the whole script and fixed bugs, including a foreign key failure, a double-calculation error in the demand update and a wrong join
- Redesigned the schema: generated price column, price history, foreign keys for origin and destination, and a transport type with transport ID instead of free text
- Added CHECK constraints and made the script re-runnable
- Scoped the project to India with realistic data

## Future Improvements

- Trek, Batch and Guide tables for trek-specific bookings
- A Season table instead of typed-in multipliers
- Price by transport type and route
- Triggers to prevent overbooking
- A web front end (Python, Java or Node)
- International routes by relaxing the Country check

## Author
Yashwanth Bhukya
