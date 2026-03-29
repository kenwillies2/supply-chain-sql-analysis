USE SupplyChainProjects
GO
USE SupplyChainProjects;
GO

-- 1. Create the Shipments Table (Financial & Logistics)
SELECT 
    timestamp,
    shipping_costs,
    delivery_time_deviation,
    order_fulfillment_status,
    lead_time_days,
    delay_probability
INTO Shipments
FROM RawLogisticsData;

-- 2. Create the Vehicle_Metrics Table (Operational)
SELECT 
    timestamp,
    vehicle_gps_latitude,
    vehicle_gps_longitude,
    fuel_consumption_rate,
    driver_behavior_score,
    fatigue_monitoring_score
INTO Vehicle_Metrics
FROM RawLogisticsData;

-- 3. Create the Environment_Risk Table (External Factors)
SELECT 
    timestamp,
    traffic_congestion_level,
    weather_condition_severity,
    port_congestion_level,
    risk_classification,
    disruption_likelihood_score
INTO Environment_Risk
FROM RawLogisticsData;

-- 4. Verify the tables were created
SELECT 'Shipments' as TableName, COUNT(*) as Rows FROM Shipments
UNION ALL
SELECT 'Vehicle_Metrics', COUNT(*) FROM Vehicle_Metrics
UNION ALL
SELECT 'Environment_Risk', COUNT(*) FROM Environment_Risk;

--1. Risk Impact on Operations
SELECT 
    E.risk_classification,
    AVG(S.shipping_costs) AS Avg_Cost,
    AVG(S.delay_probability) AS Avg_Delay
FROM Environment_Risk E
JOIN Shipments S ON E.timestamp = S.timestamp
GROUP BY E.risk_classification
ORDER BY Avg_Cost DESC;

--2. Stored Procedure: Risk Report
IF OBJECT_ID('GetRiskImpactReport', 'P') IS NOT NULL
    DROP PROCEDURE GetRiskImpactReport;
GO
CREATE PROCEDURE GetRiskImpactReport
    @RiskLevel NVARCHAR(50)
AS
BEGIN
    SELECT 
        E.risk_classification,
        COUNT(S.timestamp) AS Total_Shipments,
        ROUND(AVG(S.shipping_costs), 2) AS Avg_Cost,
        ROUND(AVG(V.fuel_consumption_rate), 2) AS Avg_Fuel_Burn,
        ROUND(AVG(S.delay_probability), 4) AS Avg_Delay_Chance
    FROM Environment_Risk E
    JOIN Shipments S ON E.timestamp = S.timestamp
    JOIN Vehicle_Metrics V ON E.timestamp = V.timestamp
    WHERE (@RiskLevel IS NULL OR E.risk_classification = @RiskLevel)
    GROUP BY E.risk_classification;
END;

--3. Driver Performance Classification
SELECT 
    timestamp,
    driver_behavior_score,
    fuel_consumption_rate,
    CASE 
        WHEN driver_behavior_score < 0.3 THEN 'Immediate Training Required'
        WHEN driver_behavior_score < 0.6 THEN 'Monitor Closely'
        ELSE 'Standard Performance'
    END AS Performance_Status
FROM Vehicle_Metrics;

--4. Driver Risk Ranking (Window Function)
SELECT 
    timestamp,
    driver_behavior_score,
    RANK() OVER (ORDER BY driver_behavior_score ASC) AS Risk_Rank
FROM Vehicle_Metrics;

--5. Monthly Trends (Time Analysis)
SELECT 
    FORMAT(timestamp, 'yyyy-MM') AS Month,
    COUNT(*) AS Shipments,
    AVG(shipping_costs) AS Avg_Cost
FROM Shipments
GROUP BY FORMAT(timestamp, 'yyyy-MM')
ORDER BY Month;

--6. High-Risk Driver Detection 
SELECT 
    timestamp,
    driver_behavior_score,
    fuel_consumption_rate,
    CASE 
        WHEN driver_behavior_score < 0.4 AND fuel_consumption_rate > 10 THEN 'High Risk'
        ELSE 'Normal'
    END AS Risk_Flag
FROM Vehicle_Metrics;

