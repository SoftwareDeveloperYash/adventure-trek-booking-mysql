-- ============================================================
-- ADVENTURE TREK BOOKING SYSTEM - INDIA TOUR WITH DYNAMIC PRICING
-- By: B. Yashwanth
-- Database : Yashwanth_TrekDB
-- Scope    : India only (domestic routes, Country is locked to 'India')
-- Requires : MySQL 8.0.16 or later (CHECK constraints, generated columns)
-- Re-runnable: the script drops and recreates the database each time.
-- ============================================================

DROP DATABASE IF EXISTS Yashwanth_TrekDB;
CREATE DATABASE Yashwanth_TrekDB;
USE Yashwanth_TrekDB;

-- ============================================================
-- SECTION 1: TABLES
-- ============================================================

-- 1.1 Customers
CREATE TABLE CustomerDetails_Yashwanth (
    CustomerID     INT PRIMARY KEY,
    FullName       VARCHAR(50)  NOT NULL,
    Email          VARCHAR(50)  NOT NULL UNIQUE,
    Phone          VARCHAR(10)  NOT NULL,
    Identity_proof VARCHAR(100) NOT NULL,
    CONSTRAINT CK_Customer_Email_Yashwanth CHECK (Email REGEXP '^[^@]+@[^@]+\\.[a-zA-Z]{2,}$'),
    CONSTRAINT CK_Customer_Phone_Yashwanth CHECK (Phone REGEXP '^[6-9][0-9]{9}$')
);

-- 1.2 Employees
CREATE TABLE Employee_Yashwanth (
    EmployeeID   INT PRIMARY KEY,
    Emp_name     VARCHAR(50) NOT NULL,
    Department   VARCHAR(50) NOT NULL,
    Emp_salary   INT NOT NULL CHECK (Emp_salary > 0),
    Emp_Position VARCHAR(50) NOT NULL
);

-- 1.3 Destinations (India only: Country is locked to 'India')
-- Distance_From_Mumbai_KM = approximate straight-line distance from Mumbai
CREATE TABLE Destination_Yashwanth (
    DestinationID           INT PRIMARY KEY,
    DestinationName         VARCHAR(50) NOT NULL,
    State                   VARCHAR(50) NOT NULL,
    Country                 VARCHAR(50) NOT NULL DEFAULT 'India',
    Distance_From_Mumbai_KM INT NOT NULL CHECK (Distance_From_Mumbai_KM >= 0),
    CONSTRAINT CK_Destination_India_Yashwanth CHECK (Country = 'India')
);

-- 1.4 Trains (DATETIME so overnight journeys are stored correctly)
CREATE TABLE Trains_Yashwanth (
    TrainID         INT PRIMARY KEY,
    TrainName       VARCHAR(50) NOT NULL,
    T_DepartureTime DATETIME NOT NULL,
    T_ArrivalTime   DATETIME NOT NULL,
    T_Origin        VARCHAR(50) NOT NULL,
    T_Destination   VARCHAR(50) NOT NULL,
    DestinationID   INT NOT NULL,
    CHECK (T_ArrivalTime > T_DepartureTime),
    FOREIGN KEY (DestinationID) REFERENCES Destination_Yashwanth(DestinationID)
);

-- 1.5 Flights (domestic)
CREATE TABLE Flights_Yashwanth (
    FlightID         INT PRIMARY KEY,
    FlightNumber     VARCHAR(10) NOT NULL,
    Airline          VARCHAR(50) NOT NULL,
    FL_DepartureTime DATETIME NOT NULL,
    FL_ArrivalTime   DATETIME NOT NULL,
    FL_Origin        VARCHAR(50) NOT NULL,
    FL_Destination   VARCHAR(50) NOT NULL,
    DestinationID    INT NOT NULL,
    CHECK (FL_ArrivalTime > FL_DepartureTime),
    FOREIGN KEY (DestinationID) REFERENCES Destination_Yashwanth(DestinationID)
);

-- 1.6 Buses
CREATE TABLE Buses_Yashwanth (
    BusID           INT PRIMARY KEY,
    BusNumber       VARCHAR(10) NOT NULL,
    Operator        VARCHAR(50) NOT NULL,
    B_DepartureTime DATETIME NOT NULL,
    B_ArrivalTime   DATETIME NOT NULL,
    B_Origin        VARCHAR(50) NOT NULL,
    B_Destination   VARCHAR(50) NOT NULL,
    DestinationID   INT NOT NULL,
    CHECK (B_ArrivalTime > B_DepartureTime),
    FOREIGN KEY (DestinationID) REFERENCES Destination_Yashwanth(DestinationID)
);

-- 1.7 Cruises (Indian coastal routes)
CREATE TABLE Cruise_Yashwanth (
    CruiseID         INT PRIMARY KEY,
    CruiseName       VARCHAR(50) NOT NULL,
    CR_DepartureTime DATETIME NOT NULL,
    CR_ArrivalTime   DATETIME NOT NULL,
    CR_Origin        VARCHAR(50) NOT NULL,
    CR_Destination   VARCHAR(50) NOT NULL,
    DestinationID    INT NOT NULL,
    CHECK (CR_ArrivalTime > CR_DepartureTime),
    FOREIGN KEY (DestinationID) REFERENCES Destination_Yashwanth(DestinationID)
);

-- 1.8 Cars
CREATE TABLE Car_Yashwanth (
    CarID         INT PRIMARY KEY,
    CarModel      VARCHAR(50) NOT NULL,
    PlateNumber   VARCHAR(20) NOT NULL UNIQUE,
    Capacity      INT NOT NULL CHECK (Capacity > 0),
    C_Origin      VARCHAR(50) NOT NULL,
    C_Destination VARCHAR(50) NOT NULL,
    DestinationID INT NOT NULL,
    FOREIGN KEY (DestinationID) REFERENCES Destination_Yashwanth(DestinationID)
);

-- 1.9 Payments
CREATE TABLE Payment_Yashwanth (
    PaymentID     INT PRIMARY KEY,
    PaymentMethod VARCHAR(50) NOT NULL,
    PaymentAmount DECIMAL(10,2) NOT NULL CHECK (PaymentAmount > 0),
    PaymentDate   DATE NOT NULL,
    CustomerID    INT NOT NULL,
    FOREIGN KEY (CustomerID) REFERENCES CustomerDetails_Yashwanth(CustomerID)
);

-- 1.10 Dynamic Pricing (all fares in INR)
-- FinalPrice = BaseFare * DemandMultiplier * SeasonalMultiplier
-- FinalPrice is a GENERATED column: it can never go out of date.
-- One row per destination per PricingDate keeps a price history.
CREATE TABLE DynamicPricing_Yashwanth (
    PricingID          INT AUTO_INCREMENT PRIMARY KEY,
    DestinationID      INT NOT NULL,
    BaseFare           DECIMAL(10,2) NOT NULL CHECK (BaseFare > 0),
    DemandMultiplier   DECIMAL(3,2)  NOT NULL DEFAULT 1.00 CHECK (DemandMultiplier   BETWEEN 0.50 AND 3.00),
    SeasonalMultiplier DECIMAL(3,2)  NOT NULL DEFAULT 1.00 CHECK (SeasonalMultiplier BETWEEN 0.50 AND 3.00),
    FinalPrice         DECIMAL(10,2) AS (ROUND(BaseFare * DemandMultiplier * SeasonalMultiplier, 2)) STORED,
    PricingDate        DATE NOT NULL,
    UNIQUE (DestinationID, PricingDate),
    FOREIGN KEY (DestinationID) REFERENCES Destination_Yashwanth(DestinationID)
);

-- 1.11 Bookings
-- TransportType + TransportID point to the row in the matching transport table
-- Origin/Destination are real foreign keys (no free text)
-- PricingID locks in the dynamic price that applied when the booking was made
CREATE TABLE Booking_Yashwanth (
    BookingID      INT PRIMARY KEY,
    CustomerID     INT NOT NULL,
    Booking_status VARCHAR(20) NOT NULL DEFAULT 'Pending',
    PaymentID      INT NOT NULL,
    Booking_time   DATETIME NOT NULL,
    TransportType  VARCHAR(10) NOT NULL,
    TransportID    INT NOT NULL,
    OriginID       INT NOT NULL,
    DestinationID  INT NOT NULL,
    PricingID      INT NULL,
    CONSTRAINT CK_Booking_Status_Yashwanth    CHECK (Booking_status IN ('Pending','Confirmed','Cancelled')),
    CONSTRAINT CK_Booking_Transport_Yashwanth CHECK (TransportType IN ('Bus','Car','Train','Flight','Cruise')),
    CONSTRAINT CK_Booking_Route_Yashwanth     CHECK (OriginID <> DestinationID),
    FOREIGN KEY (CustomerID)    REFERENCES CustomerDetails_Yashwanth(CustomerID),
    FOREIGN KEY (PaymentID)     REFERENCES Payment_Yashwanth(PaymentID),
    FOREIGN KEY (OriginID)      REFERENCES Destination_Yashwanth(DestinationID),
    FOREIGN KEY (DestinationID) REFERENCES Destination_Yashwanth(DestinationID),
    FOREIGN KEY (PricingID)     REFERENCES DynamicPricing_Yashwanth(PricingID)
);

CREATE INDEX idx_Booking_Time_Yashwanth ON Booking_Yashwanth(Booking_time);

-- ============================================================
-- SECTION 2: DATA
-- (order matters: parents first, children after)
-- ============================================================

INSERT INTO CustomerDetails_Yashwanth (CustomerID, FullName, Email, Phone, Identity_proof) VALUES
    (1,  'Amishi Desai',     'desai014@gmail.com',   '9345698768', 'Aadhar'),
    (2,  'Chahel Gupta',     'chx2904@gmail.com',    '9876543210', 'Passport'),
    (3,  'Aneri Patel',      'ap2404@gmail.com',     '7890123456', 'Driver License'),
    (4,  'Demira Ramnani',   'demram23@gmail.com',   '9234567801', 'Aadhar'),
    (5,  'Shloka Arya',      'shloksrain@gmail.com', '8901234567', 'Passport'),
    (6,  'Vansh Mehta',      'vm567@gmail.com',      '8456789012', 'Driver License'),
    (7,  'Shital Nagvenkar', 'shtlnad@gmail.com',    '9012345678', 'Aadhar'),
    (8,  'Vikram Nadkarni',  'viks01@gmail.com',     '7567890123', 'Passport'),
    (9,  'Aryan Shah',       'arshah56@gmail.com',   '9123456789', 'Driver License'),
    (10, 'Veer Patil',       'vp3til@gmail.com',     '9398631146', 'Aadhar');

INSERT INTO Employee_Yashwanth (EmployeeID, Emp_name, Department, Emp_salary, Emp_Position) VALUES
    (1,  'Vivean Arya',        'Bus',    54000, 'Driver'),
    (2,  'Sonia Mascerehnas',  'Car',    55000, 'Guide'),
    (3,  'Vansh Dhoka',        'Train',  60000, 'Supervisor'),
    (4,  'Pratham Vasa',       'Flight', 65000, 'Booking Agent'),
    (5,  'Amit Singh',         'Cruise', 70000, 'Guide'),
    (6,  'Sunita Reddy',       'Bus',    50000, 'Driver'),
    (7,  'Rahul Verma',        'Car',    60000, 'Supervisor'),
    (8,  'Vivek Mishra',       'Flight', 70000, 'Guide'),
    (9,  'Anjali Shah',        'Train',  65000, 'Booking Agent'),
    (10, 'Pooja Gupta',        'Cruise', 75000, 'Supervisor');

-- 15 Indian destinations (Country defaults to 'India')
INSERT INTO Destination_Yashwanth (DestinationID, DestinationName, State, Distance_From_Mumbai_KM) VALUES
    (101, 'Ahmedabad',     'Gujarat',                     440),
    (102, 'Jaipur',        'Rajasthan',                   920),
    (103, 'Indore',        'Madhya Pradesh',              510),
    (104, 'Lucknow',       'Uttar Pradesh',               1150),
    (201, 'Mumbai',        'Maharashtra',                 0),
    (202, 'Pune',          'Maharashtra',                 120),
    (203, 'Chennai',       'Tamil Nadu',                  1030),
    (204, 'Bangalore',     'Karnataka',                   845),
    (205, 'Hyderabad',     'Telangana',                   620),
    (206, 'Delhi',         'Delhi',                       1150),
    (207, 'Kolkata',       'West Bengal',                 1660),
    (208, 'Goa',           'Goa',                         440),
    (209, 'Kochi',         'Kerala',                      1050),
    (210, 'Visakhapatnam', 'Andhra Pradesh',              1200),
    (211, 'Port Blair',    'Andaman and Nicobar Islands', 2500);

INSERT INTO Trains_Yashwanth (TrainID, TrainName, T_DepartureTime, T_ArrivalTime, T_Origin, T_Destination, DestinationID) VALUES
    (1,  'Rajdhani Express',   '2024-03-18 16:00:00', '2024-03-19 08:30:00', 'Delhi',     'Mumbai',    201),
    (2,  'Shatabdi Express',   '2024-03-18 09:00:00', '2024-03-18 12:30:00', 'Mumbai',    'Pune',      202),
    (3,  'Duronto Express',    '2024-03-18 10:00:00', '2024-03-19 22:00:00', 'Delhi',     'Chennai',   203),
    (4,  'Garib Rath Express', '2024-03-18 11:00:00', '2024-03-20 00:00:00', 'Kolkata',   'Bangalore', 204),
    (5,  'Shatabdi Express',   '2024-03-18 12:00:00', '2024-03-18 22:00:00', 'Chennai',   'Hyderabad', 205),
    (6,  'Rajdhani Express',   '2024-03-18 13:00:00', '2024-03-19 23:00:00', 'Bangalore', 'Delhi',     206),
    (7,  'Duronto Express',    '2024-03-18 14:00:00', '2024-03-19 20:00:00', 'Mumbai',    'Kolkata',   207),
    (8,  'Garib Rath Express', '2024-03-18 15:00:00', '2024-03-19 11:00:00', 'Pune',      'Chennai',   203),
    (9,  'Shatabdi Express',   '2024-03-18 16:00:00', '2024-03-19 18:00:00', 'Delhi',     'Hyderabad', 205),
    (10, 'Rajdhani Express',   '2024-03-18 17:00:00', '2024-03-20 01:00:00', 'Kolkata',   'Mumbai',    201);

-- Domestic flights only
INSERT INTO Flights_Yashwanth (FlightID, FlightNumber, Airline, FL_DepartureTime, FL_ArrivalTime, FL_Origin, FL_Destination, DestinationID) VALUES
    (1,  'AI101', 'Air India', '2024-03-18 08:00:00', '2024-03-18 10:15:00', 'Delhi',  'Mumbai',    201),
    (2,  'AI102', 'Air India', '2024-03-18 10:00:00', '2024-03-18 11:05:00', 'Mumbai', 'Goa',       208),
    (3,  'AI103', 'Air India', '2024-03-18 12:00:00', '2024-03-18 14:45:00', 'Delhi',  'Chennai',   203),
    (4,  'AI104', 'Air India', '2024-03-18 14:00:00', '2024-03-18 15:40:00', 'Mumbai', 'Bangalore', 204),
    (5,  '6E101', 'IndiGo',    '2024-03-18 16:00:00', '2024-03-18 18:15:00', 'Delhi',  'Kolkata',   207),
    (6,  '6E102', 'IndiGo',    '2024-03-18 18:00:00', '2024-03-18 19:30:00', 'Mumbai', 'Hyderabad', 205),
    (7,  'SG101', 'SpiceJet',  '2024-03-18 20:00:00', '2024-03-18 21:00:00', 'Delhi',  'Jaipur',    102),
    (8,  'SG102', 'SpiceJet',  '2024-03-18 22:00:00', '2024-03-18 23:10:00', 'Mumbai', 'Ahmedabad', 101),
    (9,  'QP101', 'Akasa Air', '2024-03-19 01:00:00', '2024-03-19 02:15:00', 'Delhi',  'Lucknow',   104),
    (10, '6E104', 'IndiGo',    '2024-03-19 03:00:00', '2024-03-19 05:00:00', 'Mumbai', 'Kochi',     209);

-- Bus 6 (Mumbai -> Kolkata) correctly uses DestinationID 207
INSERT INTO Buses_Yashwanth (BusID, BusNumber, Operator, B_DepartureTime, B_ArrivalTime, B_Origin, B_Destination, DestinationID) VALUES
    (1,  'B001', 'ABC Bus Services', '2024-03-18 08:00:00', '2024-03-19 08:00:00', 'Delhi',  'Mumbai',    201),
    (2,  'B002', 'XYZ Travels',      '2024-03-18 10:00:00', '2024-03-18 14:00:00', 'Mumbai', 'Pune',      202),
    (3,  'B003', 'RST Tours',        '2024-03-18 12:00:00', '2024-03-20 12:00:00', 'Delhi',  'Chennai',   203),
    (4,  'B004', 'PQR Roadways',     '2024-03-18 14:00:00', '2024-03-19 10:00:00', 'Mumbai', 'Bangalore', 204),
    (5,  'B005', 'LMN Travels',      '2024-03-18 16:00:00', '2024-03-19 22:00:00', 'Delhi',  'Hyderabad', 205),
    (6,  'B006', 'DEF Bus Lines',    '2024-03-18 18:00:00', '2024-03-20 18:00:00', 'Mumbai', 'Kolkata',   207),
    (7,  'B007', 'GHI Tours',        '2024-03-18 20:00:00', '2024-03-19 05:00:00', 'Delhi',  'Lucknow',   104),
    (8,  'B008', 'JKL Bus Services', '2024-03-18 22:00:00', '2024-03-19 07:00:00', 'Mumbai', 'Ahmedabad', 101),
    (9,  'B009', 'MNO Roadways',     '2024-03-19 01:00:00', '2024-03-19 06:00:00', 'Delhi',  'Jaipur',    102),
    (10, 'B010', 'PQR Travels',      '2024-03-19 03:00:00', '2024-03-19 15:00:00', 'Mumbai', 'Indore',    103);

-- Indian coastal cruises (west coast, east coast and Andaman)
INSERT INTO Cruise_Yashwanth (CruiseID, CruiseName, CR_DepartureTime, CR_ArrivalTime, CR_Origin, CR_Destination, DestinationID) VALUES
    (1,  'Mumbai to Goa Cruise',            '2024-03-18 17:00:00', '2024-03-19 09:00:00', 'Mumbai',        'Goa',           208),
    (2,  'Goa to Mumbai Cruise',            '2024-03-18 18:00:00', '2024-03-19 10:00:00', 'Goa',           'Mumbai',        201),
    (3,  'Mumbai to Kochi Cruise',          '2024-03-18 16:00:00', '2024-03-20 10:00:00', 'Mumbai',        'Kochi',         209),
    (4,  'Kochi to Mumbai Cruise',          '2024-03-18 17:00:00', '2024-03-20 11:00:00', 'Kochi',         'Mumbai',        201),
    (5,  'Goa to Kochi Cruise',             '2024-03-18 20:00:00', '2024-03-19 14:00:00', 'Goa',           'Kochi',         209),
    (6,  'Kochi to Goa Cruise',             '2024-03-18 21:00:00', '2024-03-19 15:00:00', 'Kochi',         'Goa',           208),
    (7,  'Chennai to Visakhapatnam Cruise', '2024-03-18 18:00:00', '2024-03-19 14:00:00', 'Chennai',       'Visakhapatnam', 210),
    (8,  'Visakhapatnam to Chennai Cruise', '2024-03-18 19:00:00', '2024-03-19 15:00:00', 'Visakhapatnam', 'Chennai',       203),
    (9,  'Chennai to Port Blair Cruise',    '2024-03-19 08:00:00', '2024-03-21 08:00:00', 'Chennai',       'Port Blair',    211),
    (10, 'Port Blair to Chennai Cruise',    '2024-03-19 09:00:00', '2024-03-21 09:00:00', 'Port Blair',    'Chennai',       203);

INSERT INTO Car_Yashwanth (CarID, CarModel, PlateNumber, Capacity, C_Origin, C_Destination, DestinationID) VALUES
    (101, 'Toyota Innova',    'MH01AB1234', 7, 'Mumbai',    'Pune',      202),
    (102, 'Maruti Swift',     'MH02CD5678', 5, 'Pune',      'Mumbai',    201),
    (103, 'Honda City',       'MH03EF9012', 5, 'Chennai',   'Bangalore', 204),
    (104, 'Hyundai i20',      'MH04GH3456', 5, 'Bangalore', 'Hyderabad', 205),
    (105, 'Ford EcoSport',    'MH05IJ6789', 5, 'Hyderabad', 'Chennai',   203),
    (106, 'Volkswagen Polo',  'MH06KL0123', 5, 'Delhi',     'Kolkata',   207),
    (107, 'Toyota Corolla',   'MH07MN3456', 5, 'Kolkata',   'Delhi',     206),
    (108, 'Renault Kwid',     'MH08OP6789', 5, 'Ahmedabad', 'Jaipur',    102),
    (109, 'Honda Civic',      'MH09QR0123', 5, 'Jaipur',    'Indore',    103),
    (110, 'Mahindra Scorpio', 'MH10ST3456', 7, 'Indore',    'Ahmedabad', 101);

INSERT INTO Payment_Yashwanth (PaymentID, PaymentMethod, PaymentAmount, PaymentDate, CustomerID) VALUES
    (101, 'Credit Card', 5000.00, '2024-03-10', 1),
    (102, 'Debit Card',  3000.00, '2024-03-10', 2),
    (103, 'Net Banking', 2000.00, '2024-03-10', 3),
    (104, 'UPI',         4000.00, '2024-03-10', 4),
    (105, 'Cash',        2500.00, '2024-03-10', 5),
    (106, 'Credit Card', 3500.00, '2024-03-10', 6),
    (107, 'Debit Card',  2800.00, '2024-03-10', 7),
    (108, 'Net Banking', 1800.00, '2024-03-10', 8),
    (109, 'UPI',         4200.00, '2024-03-11', 9),
    (110, 'Cash',        2300.00, '2024-03-11', 10),
    (111, 'UPI',         2200.00, '2024-03-11', 7);   -- payment for Booking 11

-- FinalPrice is NOT inserted: MySQL calculates it automatically.
-- Rows 11 and 12 are a later-date price for the same destination (price history).
INSERT INTO DynamicPricing_Yashwanth (PricingID, DestinationID, BaseFare, DemandMultiplier, SeasonalMultiplier, PricingDate) VALUES
    (1,  201, 2000.00, 1.10, 1.00, '2024-03-01'),   -- Mumbai
    (2,  202, 1500.00, 1.05, 1.00, '2024-03-01'),   -- Pune
    (3,  203, 2500.00, 1.20, 1.10, '2024-03-01'),   -- Chennai
    (4,  204, 3000.00, 1.15, 1.05, '2024-03-01'),   -- Bangalore
    (5,  205, 2800.00, 1.10, 1.00, '2024-03-01'),   -- Hyderabad
    (6,  208, 4000.00, 1.30, 1.20, '2024-03-01'),   -- Goa (peak)
    (7,  209, 3500.00, 1.20, 1.10, '2024-03-01'),   -- Kochi
    (8,  211, 9000.00, 1.35, 1.25, '2024-03-01'),   -- Port Blair (peak)
    (9,  206, 3200.00, 1.15, 1.05, '2024-03-01'),   -- Delhi
    (10, 102, 2600.00, 1.20, 1.15, '2024-03-01'),   -- Jaipur
    (11, 201, 2000.00, 1.25, 1.10, '2024-04-01'),   -- Mumbai (later price)
    (12, 203, 2500.00, 1.30, 1.15, '2024-04-01');   -- Chennai (later price)

-- Bookings use literal IDs (no fragile subqueries).
-- PricingID = the price that applied on 2024-03-10 (NULL = destination had no pricing yet).
INSERT INTO Booking_Yashwanth (BookingID, CustomerID, Booking_status, PaymentID, Booking_time, TransportType, TransportID, OriginID, DestinationID, PricingID) VALUES
    (1,  1,  'Confirmed', 101, '2024-03-10 08:00:00', 'Bus',    1,   206, 201, 1),
    (2,  2,  'Confirmed', 102, '2024-03-10 10:00:00', 'Car',    101, 201, 202, 2),
    (3,  3,  'Confirmed', 103, '2024-03-10 12:00:00', 'Flight', 3,   206, 203, 3),
    (4,  4,  'Confirmed', 104, '2024-03-10 14:00:00', 'Flight', 4,   201, 204, 4),
    (5,  5,  'Confirmed', 105, '2024-03-10 16:00:00', 'Cruise', 1,   201, 208, 6),
    (6,  6,  'Confirmed', 106, '2024-03-10 18:00:00', 'Bus',    6,   201, 207, NULL),
    (7,  7,  'Confirmed', 107, '2024-03-10 20:00:00', 'Car',    109, 102, 103, NULL),
    (8,  8,  'Confirmed', 108, '2024-03-10 22:00:00', 'Train',  4,   207, 204, 4),
    (9,  9,  'Confirmed', 109, '2024-03-11 01:00:00', 'Flight', 3,   206, 203, 3),
    (10, 10, 'Confirmed', 110, '2024-03-11 03:00:00', 'Cruise', 9,   203, 211, 8);

-- Booking 11 relies on the DEFAULT status ('Pending')
INSERT INTO Booking_Yashwanth (BookingID, CustomerID, PaymentID, Booking_time, TransportType, TransportID, OriginID, DestinationID, PricingID)
VALUES (11, 7, 111, '2024-03-11 01:00:00', 'Flight', 3, 206, 203, 3);

-- ============================================================
-- SECTION 3: GENERAL QUERIES
-- ============================================================

SELECT * FROM Employee_Yashwanth;

-- Position fix (Car department guide is actually a driver)
UPDATE Employee_Yashwanth SET Emp_Position = 'Driver' WHERE EmployeeID = 2;
SELECT * FROM Employee_Yashwanth;

-- Copy table, then rename it
CREATE TABLE CustomerTravelDoc_Yashwanth AS
SELECT CustomerID, FullName, Identity_proof FROM CustomerDetails_Yashwanth;
ALTER TABLE CustomerTravelDoc_Yashwanth RENAME TO Customer_Documents_Yashwanth;
SELECT * FROM Customer_Documents_Yashwanth;

SELECT * FROM Booking_Yashwanth;

-- 10% surcharge on ALL credit card payments
SET SQL_SAFE_UPDATES = 0;
UPDATE Payment_Yashwanth
SET PaymentAmount = ROUND(PaymentAmount * 1.1, 2)
WHERE PaymentMethod = 'Credit Card';
SET SQL_SAFE_UPDATES = 1;
SELECT * FROM Payment_Yashwanth;

-- Airlines starting and ending with 'A' (Air India, Akasa Air)
SELECT * FROM Flights_Yashwanth WHERE Airline LIKE 'A%a' OR Airline LIKE 'A%r';

-- Destinations 500-1500 km from Mumbai
SELECT * FROM Destination_Yashwanth
WHERE Distance_From_Mumbai_KM BETWEEN 500 AND 1500;

-- States covered by the tour
SELECT DISTINCT State FROM Destination_Yashwanth ORDER BY State;

DESC Booking_Yashwanth;

-- Self join: bookings that start where another booking ended
SELECT b1.BookingID AS BookingID1, b1.CustomerID AS CustomerID1, b1.Booking_status AS BookingStatus1,
       b2.BookingID AS BookingID2, b2.CustomerID AS CustomerID2, b2.Booking_status AS BookingStatus2
FROM Booking_Yashwanth b1
JOIN Booking_Yashwanth b2 ON b1.OriginID = b2.DestinationID AND b1.BookingID <> b2.BookingID;

-- All transport options available for Goa
SELECT d.DestinationName,
       GROUP_CONCAT(DISTINCT t.TrainName)    AS Train,
       GROUP_CONCAT(DISTINCT f.FlightNumber) AS Flight,
       GROUP_CONCAT(DISTINCT b.BusNumber)    AS Bus,
       GROUP_CONCAT(DISTINCT c.CruiseName)   AS Cruise
FROM Destination_Yashwanth d
LEFT JOIN Trains_Yashwanth  t ON d.DestinationID = t.DestinationID
LEFT JOIN Flights_Yashwanth f ON d.DestinationID = f.DestinationID
LEFT JOIN Buses_Yashwanth   b ON d.DestinationID = b.DestinationID
LEFT JOIN Cruise_Yashwanth  c ON d.DestinationID = c.DestinationID
WHERE d.DestinationName = 'Goa'
GROUP BY d.DestinationName;

-- Bookings paid by credit card, with customer details
SELECT B.BookingID, B.CustomerID, B.Booking_status, B.PaymentID, B.Booking_time,
       B.TransportType, B.TransportID, C.FullName, C.Email, C.Phone, C.Identity_proof
FROM Booking_Yashwanth AS B
JOIN CustomerDetails_Yashwanth AS C ON B.CustomerID = C.CustomerID
JOIN Payment_Yashwanth AS P ON B.PaymentID = P.PaymentID
WHERE P.PaymentMethod = 'Credit Card';

-- Customers by payment amount (highest first)
SELECT C.CustomerID, C.FullName, C.Email, C.Phone, C.Identity_proof, P.PaymentAmount
FROM Payment_Yashwanth AS P
JOIN CustomerDetails_Yashwanth AS C ON P.CustomerID = C.CustomerID
ORDER BY P.PaymentAmount DESC;

SELECT COUNT(*) AS Total_Mumbai_Flights
FROM Flights_Yashwanth
WHERE FL_Origin = 'Mumbai' OR FL_Destination = 'Mumbai';

-- Grouping
SELECT Department, MAX(Emp_salary) AS Max_EmpSalary, MIN(Emp_salary) AS Min_EmpSalary
FROM Employee_Yashwanth GROUP BY Department;

-- Destinations reachable by BOTH train and flight (portable replacement for INTERSECT)
SELECT DISTINCT t.T_Destination AS Destination
FROM Trains_Yashwanth t
WHERE EXISTS (SELECT 1 FROM Flights_Yashwanth f WHERE f.FL_Destination = t.T_Destination);

-- Bus destinations with NO car service (NOT EXISTS is safe with NULLs, unlike NOT IN)
SELECT DISTINCT b.B_Destination
FROM Buses_Yashwanth b
WHERE NOT EXISTS (SELECT 1 FROM Car_Yashwanth c WHERE c.C_Destination = b.B_Destination);

SELECT CustomerID, COUNT(*) AS CustomerBookings
FROM Booking_Yashwanth GROUP BY CustomerID HAVING COUNT(*) >= 2;

SELECT SUM(PaymentAmount) AS Total_Income FROM Payment_Yashwanth;

-- Views
CREATE OR REPLACE VIEW Booking_Summary_Yashwanth AS
SELECT COUNT(*) AS TotalBookings, SUM(p.PaymentAmount) AS TotalAmountPaid, AVG(p.PaymentAmount) AS AverageAmount
FROM Booking_Yashwanth b JOIN Payment_Yashwanth p ON b.PaymentID = p.PaymentID;
SELECT * FROM Booking_Summary_Yashwanth;

CREATE OR REPLACE VIEW Destinations_Booked_Yashwanth AS
SELECT d.DestinationName, COUNT(*) AS BookingCount
FROM Booking_Yashwanth b
JOIN Destination_Yashwanth d ON b.DestinationID = d.DestinationID
GROUP BY d.DestinationName;
SELECT * FROM Destinations_Booked_Yashwanth;

-- Destinations that have never been booked
SELECT d.DestinationID, d.DestinationName
FROM Destination_Yashwanth d
LEFT JOIN Booking_Yashwanth b ON d.DestinationID = b.DestinationID
WHERE b.BookingID IS NULL;

-- Cancel train bookings (soft cancel: the record is kept, not deleted)
SET SQL_SAFE_UPDATES = 0;
UPDATE Booking_Yashwanth SET Booking_status = 'Cancelled' WHERE TransportType = 'Train';
SET SQL_SAFE_UPDATES = 1;
SELECT * FROM Booking_Yashwanth;

-- Most booked transport (active bookings only)
SELECT TransportType, TransportID, COUNT(*) AS BookingCount
FROM Booking_Yashwanth
WHERE Booking_status <> 'Cancelled'
GROUP BY TransportType, TransportID
ORDER BY BookingCount DESC
LIMIT 1;

SELECT * FROM Destination_Yashwanth;

-- ============================================================
-- SECTION 4: DYNAMIC PRICING MODULE (fares in INR)
-- ============================================================

-- Latest price per destination (use this instead of the raw table in reports)
CREATE OR REPLACE VIEW CurrentPricing_Yashwanth AS
SELECT dp.PricingID, dp.DestinationID, dp.BaseFare, dp.DemandMultiplier,
       dp.SeasonalMultiplier, dp.FinalPrice, dp.PricingDate
FROM DynamicPricing_Yashwanth dp
WHERE dp.PricingDate = (SELECT MAX(x.PricingDate)
                        FROM DynamicPricing_Yashwanth x
                        WHERE x.DestinationID = dp.DestinationID);

-- Q1. Every destination's current dynamic price
SELECT d.DestinationName, d.State, cp.BaseFare, cp.DemandMultiplier,
       cp.SeasonalMultiplier, cp.FinalPrice, cp.PricingDate
FROM CurrentPricing_Yashwanth cp
JOIN Destination_Yashwanth d ON cp.DestinationID = d.DestinationID;

-- Q2. Destinations in peak season (SeasonalMultiplier > 1.10)
SELECT d.DestinationName, cp.SeasonalMultiplier, cp.FinalPrice
FROM CurrentPricing_Yashwanth cp
JOIN Destination_Yashwanth d ON cp.DestinationID = d.DestinationID
WHERE cp.SeasonalMultiplier > 1.10;

-- Q3. Top 3 most expensive destinations
SELECT d.DestinationName, cp.FinalPrice
FROM CurrentPricing_Yashwanth cp
JOIN Destination_Yashwanth d ON cp.DestinationID = d.DestinationID
ORDER BY cp.FinalPrice DESC
LIMIT 3;

-- Q4. Cheapest 3 destinations
SELECT d.DestinationName, cp.FinalPrice
FROM CurrentPricing_Yashwanth cp
JOIN Destination_Yashwanth d ON cp.DestinationID = d.DestinationID
ORDER BY cp.FinalPrice ASC
LIMIT 3;

-- Q5. Markup over base fare (%)
SELECT d.DestinationName, cp.BaseFare, cp.FinalPrice,
       ROUND(((cp.FinalPrice - cp.BaseFare) / cp.BaseFare) * 100, 2) AS Markup_Percent
FROM CurrentPricing_Yashwanth cp
JOIN Destination_Yashwanth d ON cp.DestinationID = d.DestinationID
ORDER BY Markup_Percent DESC;

-- Q6. Demand surge: +5% demand for Goa, Kochi and Port Blair (holiday rush).
--     FinalPrice recalculates by itself (generated column).
SET SQL_SAFE_UPDATES = 0;
UPDATE DynamicPricing_Yashwanth
SET DemandMultiplier = ROUND(DemandMultiplier * 1.05, 2)
WHERE DestinationID IN (208, 209, 211);
SET SQL_SAFE_UPDATES = 1;

SELECT d.DestinationName, dp.DemandMultiplier, dp.FinalPrice
FROM DynamicPricing_Yashwanth dp
JOIN Destination_Yashwanth d ON dp.DestinationID = d.DestinationID
WHERE dp.DestinationID IN (208, 209, 211);

-- Q7. Average current price by state
SELECT d.State, ROUND(AVG(cp.FinalPrice), 2) AS Avg_FinalPrice
FROM CurrentPricing_Yashwanth cp
JOIN Destination_Yashwanth d ON cp.DestinationID = d.DestinationID
GROUP BY d.State
ORDER BY Avg_FinalPrice DESC;

-- Q8. Locked-in price at booking time vs today's price
SELECT b.BookingID, c.FullName, d.DestinationName,
       p.PaymentAmount     AS AmountPaid,
       lp.FinalPrice       AS PriceWhenBooked,
       cp.FinalPrice       AS CurrentDynamicPrice
FROM Booking_Yashwanth b
JOIN CustomerDetails_Yashwanth c ON b.CustomerID = c.CustomerID
JOIN Payment_Yashwanth p         ON b.PaymentID = p.PaymentID
JOIN Destination_Yashwanth d     ON b.DestinationID = d.DestinationID
LEFT JOIN DynamicPricing_Yashwanth lp ON b.PricingID = lp.PricingID
LEFT JOIN CurrentPricing_Yashwanth cp ON b.DestinationID = cp.DestinationID;

-- Q9. View: dynamic pricing overview (current prices only)
CREATE OR REPLACE VIEW DynamicPricing_Overview_Yashwanth AS
SELECT d.DestinationName, d.State, cp.BaseFare, cp.DemandMultiplier,
       cp.SeasonalMultiplier, cp.FinalPrice
FROM CurrentPricing_Yashwanth cp
JOIN Destination_Yashwanth d ON cp.DestinationID = d.DestinationID;

SELECT * FROM DynamicPricing_Overview_Yashwanth;

-- Q10. Destinations with no dynamic pricing yet
SELECT d.DestinationID, d.DestinationName
FROM Destination_Yashwanth d
LEFT JOIN DynamicPricing_Yashwanth dp ON d.DestinationID = dp.DestinationID
WHERE dp.PricingID IS NULL;

-- Q11. Price history for one destination
SELECT d.DestinationName, dp.PricingDate, dp.DemandMultiplier, dp.SeasonalMultiplier, dp.FinalPrice
FROM DynamicPricing_Yashwanth dp
JOIN Destination_Yashwanth d ON dp.DestinationID = d.DestinationID
WHERE d.DestinationName = 'Mumbai'
ORDER BY dp.PricingDate;

-- ------------------------------------------------------------
-- Stored procedure: set the demand multiplier from real bookings
--   0-1 active bookings -> 1.00
--   2-3 active bookings -> 1.10
--   4+  active bookings -> 1.25
-- Usage:  CALL sp_UpdateDemand_Yashwanth(203);
-- ------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_UpdateDemand_Yashwanth;

DELIMITER $$
CREATE PROCEDURE sp_UpdateDemand_Yashwanth(IN p_DestinationID INT)
BEGIN
    DECLARE v_count INT;
    DECLARE v_mult  DECIMAL(3,2);
    DECLARE v_date  DATE;

    SELECT COUNT(*) INTO v_count
    FROM Booking_Yashwanth
    WHERE DestinationID = p_DestinationID AND Booking_status <> 'Cancelled';

    SET v_mult = CASE
                    WHEN v_count >= 4 THEN 1.25
                    WHEN v_count >= 2 THEN 1.10
                    ELSE 1.00
                 END;

    SELECT MAX(PricingDate) INTO v_date
    FROM DynamicPricing_Yashwanth
    WHERE DestinationID = p_DestinationID;

    UPDATE DynamicPricing_Yashwanth
    SET DemandMultiplier = v_mult
    WHERE DestinationID = p_DestinationID AND PricingDate = v_date;
END$$
DELIMITER ;

-- Example (uncomment to try):
-- CALL sp_UpdateDemand_Yashwanth(203);
-- SELECT * FROM CurrentPricing_Yashwanth WHERE DestinationID = 203;

-- ============================ END ============================
